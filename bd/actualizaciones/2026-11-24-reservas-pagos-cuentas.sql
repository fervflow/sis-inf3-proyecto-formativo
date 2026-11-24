-- =====================================================================
--  2026-11-24-reservas-pagos-cuentas.sql
--  Cuentas de cliente, pagos y vencimiento de 24 horas.
--
--  Cambios del catálogo de reglas:
--  - RN-USU-02 a RN-USU-05: el correo es obligatorio y único en la ficha.
--  - RN-RES-05: el vencimiento de una solicitud pendiente baja de 48 a 24
--    horas.
--  - RN-PAG-01 a RN-PAG-08: anticipo mínimo del 30%, saldo exacto,
--    métodos de banca móvil y QR, pagos del personal nacen validados y
--    la confirmación exige anticipo validado.
--
--  Nota: si la base tiene fichas sin correo, esta actualización falla a
--  propósito. Se pide completarlas antes de aplicar:
--    SELECT id_cliente, nombres, apellidos FROM turismo.cliente
--    WHERE correo IS NULL;
-- =====================================================================
SET search_path TO turismo, public;

-- 1. Correo obligatorio y único (RN-USU-05).
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM cliente WHERE correo IS NULL) THEN
        RAISE EXCEPTION 'Hay fichas de cliente sin correo: complétalas antes de aplicar esta actualización';
    END IF;
END;
$$;

ALTER TABLE cliente ALTER COLUMN correo SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_cliente_correo
    ON cliente (lower(btrim(correo)));

-- 2. Métodos de pago web (RN-PAG-03): banca móvil y QR.
ALTER TABLE pago DROP CONSTRAINT IF EXISTS ck_pago_metodo;

ALTER TABLE pago ADD CONSTRAINT ck_pago_metodo
    CHECK (metodo IN ('efectivo', 'transferencia', 'tarjeta',
                      'banca_movil', 'qr', 'otro'));

-- 3. Vencimiento de las solicitudes a 24 horas (RN-RES-05). Los valores
--    guardados no se tocan: solo cambian los futuros.
ALTER TABLE reserva
    ALTER COLUMN fecha_expiracion SET DEFAULT (now() + INTERVAL '24 hours');

-- 4. Registro de pagos con sus validaciones (RN-PAG-01, RN-PAG-04 a
--    RN-PAG-06).
CREATE OR REPLACE FUNCTION fn_registrar_pago(
    p_id_reserva  BIGINT,
    p_tipo        VARCHAR,
    p_monto       NUMERIC,
    p_metodo      VARCHAR,
    p_id_usuario  TEXT,
    p_referencia  VARCHAR DEFAULT NULL,
    p_observacion VARCHAR DEFAULT NULL,
    p_validado    BOOLEAN DEFAULT false
) RETURNS BIGINT
SET search_path = turismo, public
AS $$
DECLARE
    v_id_pago      BIGINT;
    v_estado_reserva VARCHAR(15);
    v_monto_total  NUMERIC(12, 2);
    v_comprometido NUMERIC(12, 2);
    v_pendiente    NUMERIC(12, 2);
    v_minimo       NUMERIC(12, 2);
BEGIN
    SELECT r.estado, r.monto_total INTO v_estado_reserva, v_monto_total
    FROM reserva r
    WHERE r.id_reserva = p_id_reserva
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La reserva % no existe', p_id_reserva
            USING ERRCODE = 'no_data_found';
    END IF;

    IF v_estado_reserva NOT IN ('pendiente', 'confirmada') THEN
        RAISE EXCEPTION 'Solo una reserva pendiente o confirmada admite pagos; el estado actual es «%»',
            v_estado_reserva USING ERRCODE = 'check_violation';
    END IF;

    IF p_tipo NOT IN ('anticipo', 'saldo') THEN
        RAISE EXCEPTION 'El tipo de pago debe ser «anticipo» o «saldo»'
            USING ERRCODE = 'check_violation';
    END IF;

    IF p_monto IS NULL OR p_monto <= 0 THEN
        RAISE EXCEPTION 'El monto del pago debe ser mayor que cero'
            USING ERRCODE = 'check_violation';
    END IF;

    -- Lo comprometido: todo pago no anulado, validado o no. Un pago
    -- registrado por el cliente también reserva su parte del total,
    -- aunque el saldo mostrado solo baje cuando se valide.
    SELECT COALESCE(SUM(pg.monto), 0) INTO v_comprometido
    FROM pago pg
    WHERE pg.id_reserva = p_id_reserva
      AND pg.estado <> 'anulado';

    v_pendiente := v_monto_total - v_comprometido;
    v_minimo := round(v_monto_total * 0.30, 2);

    IF p_tipo = 'anticipo' THEN
        IF p_monto < v_minimo THEN
            RAISE EXCEPTION 'El anticipo no puede ser menor al 30%% del total (mínimo %, recibido %)',
                v_minimo, p_monto USING ERRCODE = 'check_violation';
        END IF;
    ELSE
        IF NOT EXISTS (
            SELECT 1 FROM pago pg
            WHERE pg.id_reserva = p_id_reserva
              AND pg.tipo = 'anticipo'
              AND pg.estado <> 'anulado'
        ) THEN
            RAISE EXCEPTION 'El saldo exige un anticipo previo de la reserva'
                USING ERRCODE = 'check_violation';
        END IF;

        IF p_monto <> v_pendiente THEN
            RAISE EXCEPTION 'El saldo debe pagar el resto completo de la reserva (% pendiente)',
                v_pendiente USING ERRCODE = 'check_violation';
        END IF;
    END IF;

    IF p_monto > v_pendiente THEN
        RAISE EXCEPTION 'El pago supera el saldo pendiente de la reserva (%)',
            v_pendiente USING ERRCODE = 'check_violation';
    END IF;

    INSERT INTO pago (
        id_reserva, tipo, monto, metodo, referencia, observacion,
        id_usuario, estado, id_usuario_validacion, fecha_validacion
    ) VALUES (
        p_id_reserva, p_tipo, p_monto, p_metodo, p_referencia, p_observacion,
        p_id_usuario,
        CASE WHEN p_validado THEN 'validado' ELSE 'registrado' END,
        CASE WHEN p_validado THEN p_id_usuario END,
        CASE WHEN p_validado THEN now() END
    ) RETURNING id_pago INTO v_id_pago;

    RETURN v_id_pago;
END;
$$ LANGUAGE plpgsql;

-- 5. Confirmación con anticipo validado (RN-RES-18).
CREATE OR REPLACE FUNCTION fn_confirmar_reserva(
    p_id_reserva BIGINT,
    p_id_usuario TEXT
) RETURNS BOOLEAN
SET search_path = turismo, public
AS $$
DECLARE
    v_estado      VARCHAR(15);
    v_expiracion  TIMESTAMPTZ;
    v_minimo      NUMERIC(12, 2);
BEGIN
    SELECT r.estado, r.fecha_expiracion, round(r.monto_total * 0.30, 2)
    INTO v_estado, v_expiracion, v_minimo
    FROM reserva r
    WHERE r.id_reserva = p_id_reserva
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La reserva % no existe', p_id_reserva
            USING ERRCODE = 'no_data_found';
    END IF;

    IF v_estado <> 'pendiente' THEN
        RAISE EXCEPTION 'Solo una solicitud pendiente puede confirmarse; el estado actual es «%»',
            v_estado USING ERRCODE = 'check_violation';
    END IF;

    IF v_expiracion IS NOT NULL AND v_expiracion <= now() THEN
        UPDATE reserva r
        SET estado = 'vencida',
            observaciones = COALESCE(r.observaciones || ' | ', '')
                          || 'Vencida por falta de confirmación dentro del plazo previsto.'
        WHERE r.id_reserva = p_id_reserva;

        INSERT INTO historial_reserva (
            id_reserva, estado_anterior, estado_nuevo, id_usuario, observacion
        ) VALUES (
            p_id_reserva, 'pendiente', 'vencida', p_id_usuario,
            'Vencimiento al intentar confirmar fuera de plazo.'
        );

        RAISE EXCEPTION 'La solicitud % venció sin confirmarse', p_id_reserva
            USING ERRCODE = 'check_violation';
    END IF;

    -- Anticipo validado (RN-RES-18): la reserva nace de una solicitud
    -- respaldada. El mínimo lo comprobó fn_registrar_pago al registrar el
    -- anticipo; aquí basta con exigir que exista y esté validado.
    IF NOT EXISTS (
        SELECT 1 FROM pago pg
        WHERE pg.id_reserva = p_id_reserva
          AND pg.tipo = 'anticipo'
          AND pg.estado = 'validado'
          AND pg.monto >= v_minimo
    ) THEN
        RAISE EXCEPTION 'La reserva % no tiene el anticipo mínimo validado (30%%)', p_id_reserva
            USING ERRCODE = 'check_violation';
    END IF;

    UPDATE reserva
    SET estado = 'confirmada',
        fecha_expiracion = NULL
    WHERE id_reserva = p_id_reserva;

    INSERT INTO historial_reserva (
        id_reserva, estado_anterior, estado_nuevo, id_usuario, observacion
    ) VALUES (
        p_id_reserva, 'pendiente', 'confirmada', p_id_usuario,
        'Solicitud confirmada dentro del plazo previsto.'
    );

    RETURN true;
END;
$$ LANGUAGE plpgsql;
