-- =====================================================================
--  2026-11-25-pagos-parciales-retencion-70.sql
--  Pagos por partes, anticipo sumado y retención web del 70%.
--
--  Cambios del catálogo de reglas:
--  - RN-PAG-02 y RN-PAG-05: admite varios pagos por tipo (cae la
--    restricción UNIQUE (id_reserva, tipo)); el saldo puede pagarse en
--    montos parciales y ningún pago supera el saldo pendiente.
--  - RN-RES-18: la confirmación exige que la suma de los anticipos
--    validados cubra el mínimo del 30% del total vigente.
--  - RN-RES-16: la retención de las solicitudes web pendientes pasa del
--    50% al 70% de los cupos disponibles.
--  - RN-RES-21: en el canal web el manifiesto no declara más pasajeros
--    que los solicitados.
--
--  Nota: no hay cambios de datos. Solo se sueltan funciones, una vista
--  y una restricción de tabla.
-- =====================================================================
SET search_path TO turismo, public;

-- 1. Varios pagos por tipo (RN-PAG-02): el tope real lo aplica
--    fn_registrar_pago, que no deja superar el saldo pendiente.
ALTER TABLE pago DROP CONSTRAINT IF EXISTS uq_pago_reserva_tipo;

-- 2. Registro de pagos con saldo parcial (RN-PAG-02 y RN-PAG-05).
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

    -- El mínimo del 30% (RN-PAG-01) aplica al primer anticipo de la
    -- reserva; los anticipos adicionales solo respetan el saldo
    -- pendiente (RN-PAG-05), de modo que se pueda respaldar de nuevo
    -- una reserva cuyo total creció con el manifiesto.
    IF p_tipo = 'anticipo' THEN
        IF NOT EXISTS (
            SELECT 1 FROM pago pg
            WHERE pg.id_reserva = p_id_reserva
              AND pg.tipo = 'anticipo'
              AND pg.estado <> 'anulado'
        ) AND p_monto < v_minimo THEN
            RAISE EXCEPTION 'El anticipo no puede ser menor al 30%% del total (mínimo %, recibido %)',
                v_minimo, p_monto USING ERRCODE = 'check_violation';
        END IF;
    ELSE
        -- El saldo puede ser parcial (RN-PAG-05): cada pago reduce el
        -- pendiente y puede haber varios hasta cubrirlo. Solo exige que
        -- exista un anticipo previo no anulado (RN-PAG-05).
        IF NOT EXISTS (
            SELECT 1 FROM pago pg
            WHERE pg.id_reserva = p_id_reserva
              AND pg.tipo = 'anticipo'
              AND pg.estado <> 'anulado'
        ) THEN
            RAISE EXCEPTION 'El saldo exige un anticipo previo de la reserva'
                USING ERRCODE = 'check_violation';
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

-- 3. Confirmación con la suma de anticipos validados (RN-RES-18).
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
    v_anticipo_validado NUMERIC(12, 2);
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
    -- respaldada. El mínimo lo comprobó fn_registrar_pago al registrar
    -- cada anticipo; aquí se exige que la suma de los anticipos
    -- validados cubra el mínimo del total vigente, de modo que un
    -- manifiesto que creció se respalde con un anticipo adicional.
    SELECT COALESCE(SUM(pg.monto), 0) INTO v_anticipo_validado
    FROM pago pg
    WHERE pg.id_reserva = p_id_reserva
      AND pg.tipo = 'anticipo'
      AND pg.estado = 'validado';

    IF v_anticipo_validado < v_minimo THEN
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


-- 4. Retención web del 70% de los cupos disponibles (RN-RES-16).
--    Alta de reserva:
CREATE OR REPLACE FUNCTION fn_crear_reserva(
    p_id_cliente      BIGINT,
    p_id_salida       BIGINT,
    p_cantidad        INTEGER,
    p_origen          VARCHAR,
    p_id_usuario      TEXT,
    p_id_cotizacion   BIGINT DEFAULT NULL
) RETURNS BIGINT
SET search_path = turismo, public
AS $$
DECLARE
    v_cupo_maximo SMALLINT;
    v_ocupados    INT;
    v_retenidos   INT;
    v_confirmados INT;
    v_retenidos_personal INT;
    v_disponible  INT;
    v_id_reserva  BIGINT;
BEGIN
    IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
        RAISE EXCEPTION 'La cantidad de pasajeros debe ser mayor que cero'
            USING ERRCODE = 'check_violation';
    END IF;

    IF p_origen IS NULL OR p_origen NOT IN ('personal', 'web') THEN
        RAISE EXCEPTION 'El canal de ingreso debe ser «personal» o «web»'
            USING ERRCODE = 'check_violation';
    END IF;

    SELECT s.cupo_maximo INTO v_cupo_maximo
    FROM salida s
    WHERE s.id_salida = p_id_salida
      AND s.estado IN ('programada', 'confirmada')
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La salida % no existe o no admite reservas', p_id_salida
            USING ERRCODE = 'no_data_found';
    END IF;

    -- Tope de la solicitud web (RN-RES-15): la solicitud del cliente no
    -- retiene todo el cupo en una sola reserva; los grupos mayores se
    -- atienden por la oficina, en el canal personal.
    IF p_origen = 'web' AND p_cantidad > 4 THEN
        RAISE EXCEPTION 'Una solicitud del canal web admite hasta 4 pasajeros; los grupos mayores se atienden en la agencia'
            USING ERRCODE = 'check_violation';
    END IF;

    -- Tope global de retención (RN-RES-16): las solicitudes web pendientes
    -- vigentes no retienen en conjunto más del 70% de los cupos
    -- disponibles, para que una avalancha de formularios no bloquee la
    -- venta. La base del porcentaje son los cupos aún no confirmados ni
    -- retenidos por el canal personal; los pendientes web no suman a esa
    -- base porque son justamente lo que se limita. Mientras haya cupo
    -- real, queda siempre un cupo solicitable por web (mínimo 1). Las
    -- pendientes del canal personal no cuentan para el tope: hay una
    -- persona atendida detrás. Confirmar libera espacio.
    IF p_origen = 'web' THEN
        SELECT COALESCE(SUM(r.cantidad_pasajeros), 0)::INT INTO v_retenidos
        FROM reserva r
        WHERE r.id_salida = p_id_salida
          AND r.origen = 'web'
          AND r.estado = 'pendiente'
          AND (r.fecha_expiracion IS NULL OR r.fecha_expiracion > now());

        SELECT COALESCE(SUM(r.cantidad_pasajeros)
                    FILTER (WHERE r.estado = 'confirmada'), 0)::INT,
               COALESCE(SUM(r.cantidad_pasajeros)
                    FILTER (WHERE r.estado = 'pendiente'
                              AND r.origen = 'personal'
                              AND (r.fecha_expiracion IS NULL
                                   OR r.fecha_expiracion > now())), 0)::INT
        INTO v_confirmados, v_retenidos_personal
        FROM reserva r
        WHERE r.id_salida = p_id_salida;

        v_disponible := v_cupo_maximo - v_confirmados - v_retenidos_personal;
        IF v_disponible < 0 THEN
            v_disponible := 0;
        END IF;

        IF v_retenidos + p_cantidad
           > GREATEST(1, FLOOR(v_disponible::NUMERIC * 0.7)::INT) THEN
            RAISE EXCEPTION 'La salida tiene demasiadas solicitudes pendientes de confirmación; consulta con la agencia'
                USING ERRCODE = 'check_violation';
        END IF;
    END IF;

    -- Ocupación efectiva: una solicitud pendiente cuyo plazo ya venció
    -- deja de ocupar cupo, aunque su estado guardado siga siendo
    -- 'pendiente' hasta el barrido diario.
    SELECT COALESCE(SUM(r.cantidad_pasajeros), 0)::INT INTO v_ocupados
    FROM reserva r
    WHERE r.id_salida = p_id_salida
      AND r.estado IN ('pendiente', 'confirmada')
      AND (r.estado <> 'pendiente'
           OR r.fecha_expiracion IS NULL
           OR r.fecha_expiracion > now());

    IF v_cupo_maximo - v_ocupados < p_cantidad THEN
        RAISE EXCEPTION 'No hay cupo suficiente: quedan % lugares y se piden %',
            v_cupo_maximo - v_ocupados, p_cantidad
            USING ERRCODE = 'check_violation';
    END IF;

    IF EXISTS (
        SELECT 1 FROM reserva r
        WHERE r.id_cliente = p_id_cliente
          AND r.id_salida = p_id_salida
          AND r.estado = 'pendiente'
    ) THEN
        RAISE EXCEPTION 'El cliente ya tiene una solicitud pendiente para esa salida'
            USING ERRCODE = 'unique_violation';
    END IF;

    INSERT INTO reserva (
        id_cliente, id_salida, id_cotizacion, id_usuario, origen,
        cantidad_pasajeros, monto_total, estado, fecha_expiracion
    )
    SELECT p_id_cliente, p_id_salida, p_id_cotizacion, p_id_usuario, p_origen,
           p_cantidad, s.precio * p_cantidad, 'pendiente',
           now() + INTERVAL '24 hours'
    FROM salida s
    WHERE s.id_salida = p_id_salida
    RETURNING id_reserva INTO v_id_reserva;

    INSERT INTO historial_reserva (
        id_reserva, estado_anterior, estado_nuevo, id_usuario, observacion
    ) VALUES (
        v_id_reserva, NULL, 'pendiente', p_id_usuario,
        'Reserva creada por el canal ' || p_origen || '.'
    );

    RETURN v_id_reserva;
END;
$$ LANGUAGE plpgsql;
--    Revalidación al modificar y al guardar el manifiesto:
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
    v_retenidos         INT;
    v_confirmados       INT;
    v_retenidos_personal INT;
    v_disponible        INT;
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

    -- Retención del canal web (RN-RES-16), revalidada al modificar la
    -- reserva (T-HU-06.4): las solicitudes web pendientes vigentes de la
    -- salida no retienen en conjunto más del 70% de los cupos
    -- disponibles. La base del porcentaje son los cupos aún no
    -- confirmados ni retenidos por el canal personal; los pendientes web
    -- no suman a esa base porque son lo que se limita, y la propia
    -- reserva no se cuenta, porque su cantidad nueva entra en el
    -- cálculo. Las pendientes del canal personal no cuentan para el
    -- tope.
    IF v_origen = 'web' AND v_estado = 'pendiente' THEN
        SELECT COALESCE(SUM(r.cantidad_pasajeros), 0)::INT INTO v_retenidos
        FROM reserva r
        WHERE r.id_salida = p_salida
          AND r.id_reserva <> p_id_reserva
          AND r.origen = 'web'
          AND r.estado = 'pendiente'
          AND (r.fecha_expiracion IS NULL OR r.fecha_expiracion > now());

        SELECT COALESCE(SUM(r.cantidad_pasajeros)
                    FILTER (WHERE r.estado = 'confirmada'), 0)::INT,
               COALESCE(SUM(r.cantidad_pasajeros)
                    FILTER (WHERE r.estado = 'pendiente'
                              AND r.origen = 'personal'
                              AND (r.fecha_expiracion IS NULL
                                   OR r.fecha_expiracion > now())), 0)::INT
        INTO v_confirmados, v_retenidos_personal
        FROM reserva r
        WHERE r.id_salida = p_salida;

        v_disponible := v_cupo - v_confirmados - v_retenidos_personal;
        IF v_disponible < 0 THEN
            v_disponible := 0;
        END IF;

        IF v_retenidos + p_cantidad
           > GREATEST(1, FLOOR(v_disponible::NUMERIC * 0.7)::INT) THEN
            RAISE EXCEPTION 'La salida tiene demasiadas solicitudes pendientes de confirmación; consulta con la agencia'
                USING ERRCODE = 'check_violation';
        END IF;
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

-- 5. Manifiesto web sin superar lo solicitado (RN-RES-21).
CREATE OR REPLACE FUNCTION fn_guardar_manifiesto(
    p_id_reserva BIGINT,
    p_pasajeros  JSONB,
    p_id_usuario TEXT
) RETURNS INT
SET search_path = turismo, public
AS $$
DECLARE
    v_estado      VARCHAR(15);
    v_origen      VARCHAR(15);
    v_id_cliente  BIGINT;
    v_salida      BIGINT;
    v_cantidad_actual INT;
    v_pasajero    JSONB;
    v_id_pasajero BIGINT;
    v_cantidad    INT;
BEGIN
    SELECT r.estado, r.origen, r.id_cliente, r.id_salida, r.cantidad_pasajeros
    INTO v_estado, v_origen, v_id_cliente, v_salida, v_cantidad_actual
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

    -- En el canal web el manifiesto no declara más pasajeros que los
    -- solicitados (RN-RES-21): el cliente puede reducir su grupo, no
    -- ampliarlo; el canal personal sí puede ampliarlo y la base
    -- revalida cupos y monto.
    IF v_origen = 'web'
       AND jsonb_array_length(p_pasajeros) > v_cantidad_actual THEN
        RAISE EXCEPTION 'El manifiesto no puede declarar más pasajeros que los solicitados (%)',
            v_cantidad_actual USING ERRCODE = 'check_violation';
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

-- 6. Vista de saldo con la suma por tipo (RN-PAG-02).
CREATE OR REPLACE VIEW vista_saldo_reserva AS
SELECT
    r.id_reserva,
    r.codigo,
    r.id_cliente,
    r.id_salida,
    r.monto_total,
    COALESCE(SUM(pg.monto) FILTER (WHERE pg.tipo = 'anticipo' AND pg.estado <> 'anulado'), 0) AS anticipo,
    COALESCE(SUM(pg.monto) FILTER (WHERE pg.tipo = 'saldo' AND pg.estado <> 'anulado'), 0) AS saldo_pagado,
    COALESCE(SUM(pg.monto) FILTER (WHERE pg.estado <> 'anulado'), 0) AS total_pagado,
    COALESCE(SUM(pg.monto) FILTER (WHERE pg.estado = 'validado'), 0) AS total_validado,
    r.monto_total - COALESCE(SUM(pg.monto) FILTER (WHERE pg.estado = 'validado'), 0) AS saldo_pendiente,
    r.estado
FROM reserva r
LEFT JOIN pago pg ON pg.id_reserva = r.id_reserva
GROUP BY r.id_reserva, r.codigo, r.id_cliente, r.id_salida,
         r.monto_total, r.estado;
