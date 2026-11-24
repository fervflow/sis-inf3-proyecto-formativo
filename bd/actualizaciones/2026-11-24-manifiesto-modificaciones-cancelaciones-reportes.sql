-- =====================================================================
--  2026-11-24-manifiesto-modificaciones-cancelaciones-reportes.sql
--  Manifiesto de pasajeros, modificación de reservas y reportes.
--
--  Cambios del catálogo de reglas:
--  - RN-RES-19: confirmar exige el manifiesto completo (fn_confirmar_
--    reserva lo comprueba junto con el anticipo validado).
--  - RN-RES-20 y RN-RES-21: modificar la salida o el manifiesto
--    revalida cupos, recalcula el monto y respeta los pagos
--    comprometidos (fn_actualizar_reserva y fn_guardar_manifiesto).
--  - RN-REP-02 y RN-REP-03: la vista de reportes informa canceladas y
--    distingue el canal web del personal.
-- =====================================================================
SET search_path TO turismo, public;

-- Confirmación con anticipo validado (RN-RES-18) y manifiesto completo
-- (RN-RES-19).
-- Confirmación de una solicitud pendiente (HU-17).
-- Limpia la fecha de vencimiento y deja el cambio auditado. Una
-- solicitud vencida no puede confirmarse: el cliente debe registrar una
-- nueva si la salida sigue disponible. La confirmación exige además el
-- anticipo validado (RN-RES-18) y el manifiesto completo de pasajeros
-- (RN-RES-19): sin pago ni pasajeros la reserva no se vuelve
-- definitiva.
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
    v_cantidad    SMALLINT;
    v_pasajeros   INT;
BEGIN
    SELECT r.estado, r.fecha_expiracion, round(r.monto_total * 0.30, 2),
           r.cantidad_pasajeros
    INTO v_estado, v_expiracion, v_minimo, v_cantidad
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

    -- Manifiesto completo (RN-RES-19): los pasajeros registrados igualan
    -- la cantidad declarada. El manifiesto se llena antes de confirmar.
    SELECT count(*) INTO v_pasajeros
    FROM reserva_pasajero rp
    WHERE rp.id_reserva = p_id_reserva;

    IF v_pasajeros <> v_cantidad THEN
        RAISE EXCEPTION 'La reserva % tiene el manifiesto incompleto: % de % pasajeros registrados',
            p_id_reserva, v_pasajeros, v_cantidad
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

CREATE OR REPLACE FUNCTION fn_revalidar_reserva(
    p_id_reserva BIGINT,
    p_salida     BIGINT,
    p_cantidad   INTEGER,
    p_id_usuario TEXT
) RETURNS NUMERIC
SET search_path = turismo, public
AS $$
DECLARE
    v_estado            VARCHAR(15);
    v_origen            VARCHAR(15);
    v_id_cliente        BIGINT;
    v_salida_anterior   BIGINT;
    v_cantidad_anterior SMALLINT;
    v_monto_anterior    NUMERIC(12, 2);
    v_cupo              INT;
    v_precio            NUMERIC(12, 2);
    v_ocupados_otros    INT;
    v_nuevo_monto       NUMERIC(12, 2);
    v_comprometido      NUMERIC(12, 2);
BEGIN
    SELECT r.estado, r.origen, r.id_cliente, r.id_salida,
           r.cantidad_pasajeros, r.monto_total
    INTO v_estado, v_origen, v_id_cliente, v_salida_anterior,
         v_cantidad_anterior, v_monto_anterior
    FROM reserva r
    WHERE r.id_reserva = p_id_reserva
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La reserva % no existe', p_id_reserva
            USING ERRCODE = 'no_data_found';
    END IF;

    IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
        RAISE EXCEPTION 'La cantidad de pasajeros debe ser mayor que cero'
            USING ERRCODE = 'check_violation';
    END IF;

    -- La salida destino debe ser reservable: paquete activo, salida
    -- programada o confirmada, con fecha desde hoy.
    SELECT s.cupo_maximo, s.precio INTO v_cupo, v_precio
    FROM salida s
    JOIN paquete p ON p.id_paquete = s.id_paquete AND p.estado = 'activo'
    WHERE s.id_salida = p_salida
      AND s.estado IN ('programada', 'confirmada')
      AND s.fecha_salida >= CURRENT_DATE
    FOR UPDATE OF s;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La salida % no existe o no admite reservas', p_salida
            USING ERRCODE = 'no_data_found';
    END IF;

    -- Tope del canal web (RN-RES-15), igual que al crear.
    IF v_origen = 'web' AND p_cantidad > 4 THEN
        RAISE EXCEPTION 'Una solicitud del canal web admite hasta 4 pasajeros; los grupos mayores se atienden en la agencia'
            USING ERRCODE = 'check_violation';
    END IF;

    -- Ocupación de las demás reservas en la salida destino: la propia
    -- reserva no se cuenta, porque se mueve o se ajusta.
    SELECT COALESCE(SUM(r.cantidad_pasajeros), 0)::INT INTO v_ocupados_otros
    FROM reserva r
    WHERE r.id_salida = p_salida
      AND r.id_reserva <> p_id_reserva
      AND r.estado IN ('pendiente', 'confirmada')
      AND (r.estado <> 'pendiente'
           OR r.fecha_expiracion IS NULL
           OR r.fecha_expiracion > now());

    IF v_cupo - v_ocupados_otros < p_cantidad THEN
        RAISE EXCEPTION 'No hay cupo suficiente: quedan % lugares y se piden %',
            v_cupo - v_ocupados_otros, p_cantidad
            USING ERRCODE = 'check_violation';
    END IF;

    -- Una sola solicitud pendiente por cliente y salida (RN-RES-04).
    IF EXISTS (
        SELECT 1 FROM reserva r2
        WHERE r2.id_cliente = v_id_cliente
          AND r2.id_salida = p_salida
          AND r2.estado = 'pendiente'
          AND r2.id_reserva <> p_id_reserva
    ) THEN
        RAISE EXCEPTION 'El cliente ya tiene una solicitud pendiente para esa salida'
            USING ERRCODE = 'unique_violation';
    END IF;

    -- El monto se recalcula con el precio vigente de la salida por la
    -- cantidad nueva (RN-RES-20).
    v_nuevo_monto := v_precio * p_cantidad;

    SELECT COALESCE(SUM(pg.monto), 0) INTO v_comprometido
    FROM pago pg
    WHERE pg.id_reserva = p_id_reserva
      AND pg.estado <> 'anulado';

    IF v_comprometido > v_nuevo_monto THEN
        RAISE EXCEPTION 'Los pagos comprometidos superan el nuevo monto de la reserva: anula pagos antes de reducirla'
            USING ERRCODE = 'check_violation';
    END IF;

    UPDATE reserva
    SET id_salida = p_salida,
        cantidad_pasajeros = p_cantidad,
        monto_total = v_nuevo_monto
    WHERE id_reserva = p_id_reserva;

    IF p_salida <> v_salida_anterior
       OR p_cantidad <> v_cantidad_anterior
       OR v_nuevo_monto <> v_monto_anterior THEN
        INSERT INTO historial_reserva (
            id_reserva, estado_anterior, estado_nuevo, id_usuario, observacion
        ) VALUES (
            p_id_reserva, v_estado, v_estado, p_id_usuario,
            'Salida ' || v_salida_anterior || ' -> ' || p_salida
            || '; cantidad ' || v_cantidad_anterior || ' -> ' || p_cantidad
            || '; monto ' || v_monto_anterior || ' -> ' || v_nuevo_monto || '.'
        );
    END IF;

    RETURN v_nuevo_monto;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_actualizar_reserva(
    p_id_reserva   BIGINT,
    p_salida_nueva BIGINT,
    p_id_usuario   TEXT
) RETURNS NUMERIC
SET search_path = turismo, public
AS $$
DECLARE
    v_estado VARCHAR(15);
    v_salida BIGINT;
BEGIN
    SELECT r.estado, r.id_salida INTO v_estado, v_salida
    FROM reserva r
    WHERE r.id_reserva = p_id_reserva
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La reserva % no existe', p_id_reserva
            USING ERRCODE = 'no_data_found';
    END IF;

    IF v_estado NOT IN ('pendiente', 'confirmada') THEN
        RAISE EXCEPTION 'Solo una reserva pendiente o confirmada se modifica; el estado actual es «%»',
            v_estado USING ERRCODE = 'check_violation';
    END IF;

    RETURN fn_revalidar_reserva(
        p_id_reserva,
        COALESCE(p_salida_nueva, v_salida),
        (SELECT r.cantidad_pasajeros FROM reserva r WHERE r.id_reserva = p_id_reserva),
        p_id_usuario
    );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_guardar_manifiesto(
    p_id_reserva BIGINT,
    p_pasajeros  JSONB,
    p_id_usuario TEXT
) RETURNS INT
SET search_path = turismo, public
AS $$
DECLARE
    v_estado      VARCHAR(15);
    v_id_cliente  BIGINT;
    v_salida      BIGINT;
    v_pasajero    JSONB;
    v_id_pasajero BIGINT;
    v_cantidad    INT;
BEGIN
    SELECT r.estado, r.id_cliente, r.id_salida
    INTO v_estado, v_id_cliente, v_salida
    FROM reserva r
    WHERE r.id_reserva = p_id_reserva
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La reserva % no existe', p_id_reserva
            USING ERRCODE = 'no_data_found';
    END IF;

    IF v_estado NOT IN ('pendiente', 'confirmada') THEN
        RAISE EXCEPTION 'Solo una reserva pendiente o confirmada admite su manifiesto; el estado actual es «%»',
            v_estado USING ERRCODE = 'check_violation';
    END IF;

    IF jsonb_array_length(p_pasajeros) = 0 THEN
        RAISE EXCEPTION 'El manifiesto necesita al menos un pasajero'
            USING ERRCODE = 'check_violation';
    END IF;

    DELETE FROM reserva_pasajero WHERE id_reserva = p_id_reserva;

    FOR v_pasajero IN SELECT * FROM jsonb_array_elements(p_pasajeros) LOOP
        SELECT id_pasajero INTO v_id_pasajero
        FROM pasajero
        WHERE tipo_documento = v_pasajero->>'tipo_documento'
          AND upper(numero_documento) = upper(v_pasajero->>'numero_documento');

        IF FOUND AND v_id_pasajero IS NOT NULL THEN
            IF (SELECT id_cliente FROM pasajero WHERE id_pasajero = v_id_pasajero)
               <> v_id_cliente THEN
                RAISE EXCEPTION 'El pasajero % ya está registrado en la ficha de otro cliente',
                    v_pasajero->>'nombres'
                    USING ERRCODE = 'check_violation';
            END IF;
        ELSE
            INSERT INTO pasajero (
                id_cliente, tipo_documento, numero_documento,
                nombres, apellidos, fecha_nacimiento
            ) VALUES (
                v_id_cliente,
                v_pasajero->>'tipo_documento',
                upper(v_pasajero->>'numero_documento'),
                v_pasajero->>'nombres',
                v_pasajero->>'apellidos',
                NULLIF(v_pasajero->>'fecha_nacimiento', '')::DATE
            )
            RETURNING id_pasajero INTO v_id_pasajero;
        END IF;

        INSERT INTO reserva_pasajero (id_reserva, id_pasajero)
        VALUES (p_id_reserva, v_id_pasajero);
    END LOOP;

    SELECT count(*) INTO v_cantidad
    FROM reserva_pasajero WHERE id_reserva = p_id_reserva;

    PERFORM fn_revalidar_reserva(p_id_reserva, v_salida, v_cantidad, p_id_usuario);

    RETURN v_cantidad;
END;
$$ LANGUAGE plpgsql;


-- Vista de reportes con canceladas y conteos por canal. CREATE OR
-- REPLACE no puede añadir columnas: se recrea completa.
DROP VIEW IF EXISTS vista_reservas_por_fecha;
CREATE VIEW vista_reservas_por_fecha AS
SELECT
    s.fecha_salida,
    s.id_salida,
    s.id_paquete,
    p.codigo AS codigo_paquete,
    p.nombre AS paquete,
    COUNT(r.id_reserva)
        FILTER (WHERE r.estado = 'pendiente'
                  AND (r.fecha_expiracion IS NULL OR r.fecha_expiracion > now())) AS reservas_pendientes,
    COUNT(r.id_reserva)
        FILTER (WHERE r.estado = 'confirmada') AS reservas_confirmadas,
    COUNT(r.id_reserva)
        FILTER (WHERE r.estado IN ('pendiente', 'confirmada')
                  AND (r.estado <> 'pendiente'
                       OR r.fecha_expiracion IS NULL
                       OR r.fecha_expiracion > now())) AS reservas_activas,
    COUNT(r.id_reserva)
        FILTER (WHERE r.estado = 'vencida') AS reservas_vencidas,
    COUNT(r.id_reserva)
        FILTER (WHERE r.estado = 'cancelada') AS reservas_canceladas,
    COUNT(r.id_reserva)
        FILTER (WHERE r.estado IN ('pendiente', 'confirmada')
                  AND (r.estado <> 'pendiente'
                       OR r.fecha_expiracion IS NULL
                       OR r.fecha_expiracion > now())
                  AND r.origen = 'web') AS reservas_web,
    COUNT(r.id_reserva)
        FILTER (WHERE r.estado IN ('pendiente', 'confirmada')
                  AND (r.estado <> 'pendiente'
                       OR r.fecha_expiracion IS NULL
                       OR r.fecha_expiracion > now())
                  AND r.origen = 'personal') AS reservas_personal,
    COALESCE(SUM(r.cantidad_pasajeros)
        FILTER (WHERE r.estado = 'pendiente'
                  AND (r.fecha_expiracion IS NULL OR r.fecha_expiracion > now())), 0)::INT AS pasajeros_pendientes,
    COALESCE(SUM(r.cantidad_pasajeros)
        FILTER (WHERE r.estado = 'confirmada'), 0)::INT AS pasajeros_confirmados,
    COALESCE(SUM(r.cantidad_pasajeros)
        FILTER (WHERE r.estado IN ('pendiente', 'confirmada')
                  AND (r.estado <> 'pendiente'
                       OR r.fecha_expiracion IS NULL
                       OR r.fecha_expiracion > now())), 0)::INT AS pasajeros,
    s.cupo_maximo,
    (s.cupo_maximo - COALESCE(SUM(r.cantidad_pasajeros)
        FILTER (WHERE r.estado IN ('pendiente', 'confirmada')
                  AND (r.estado <> 'pendiente'
                       OR r.fecha_expiracion IS NULL
                       OR r.fecha_expiracion > now())), 0))::INT AS cupo_disponible
FROM salida s
JOIN paquete p ON p.id_paquete = s.id_paquete
LEFT JOIN reserva r ON r.id_salida = s.id_salida
GROUP BY s.fecha_salida, s.id_salida, s.id_paquete, p.codigo, p.nombre, s.cupo_maximo
ORDER BY s.fecha_salida;
