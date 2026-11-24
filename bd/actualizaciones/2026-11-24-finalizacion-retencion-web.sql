-- =====================================================================
--  2026-11-24-finalizacion-retencion-web.sql
--  Finalización de reservas, retención web revalidada y barrido manual.
--
--  Cambios del catálogo de reglas:
--  - RN-RES-20: modificar una reserva del canal web revalida también la
--    retención del 50% del cupo (RN-RES-16), que antes solo se comprobaba
--    al crear (T-HU-06.4). Lo aplica fn_revalidar_reserva, que usan la
--    modificación de salida y el manifiesto.
--  - HU-07 (T-HU-07.4): las reservas confirmadas de una salida que pasa
--    a 'realizada' pasan a 'finalizada', con su auditoría. Lo aplica
--    fn_actualizar_salida.
--  - RN-RES-09 (T-HU-17.4): el barrido de solicitudes vencidas admite la
--    cuenta del personal que lo ejecuta desde la bandeja, sin esperar al
--    cron diario. El parámetro es opcional: el cron sigue llamándola sin
--    argumentos.
--  - RN-REP-02: el reporte informa también las reservas finalizadas.
-- =====================================================================
SET search_path TO turismo, public;

-- La función del barrido cambió de firma: sin esta baja queda la versión
-- antigua de cero argumentos y la llamada sin parámetros es ambigua.
DROP FUNCTION IF EXISTS turismo.fn_vencer_solicitudes_pendientes();

-- Revalidación de una reserva existente (HU-07, RN-RES-20).
-- La usan la modificación de salida y el manifiesto: bloquea la salida
-- destino, vuelve a verificar los cupos y la retención del canal web
-- (RN-RES-15 y RN-RES-16) sin contar la propia reserva, recalcula el
-- monto con el precio vigente y rechaza que los pagos comprometidos
-- queden por encima del nuevo total. Todo queda auditado en el
-- historial con los valores anterior y nuevo.
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
    -- salida no retienen en conjunto más de la mitad del cupo. La propia
    -- reserva no se cuenta, porque su cantidad nueva entra en el cálculo;
    -- las pendientes del canal personal no cuentan para el tope.
    IF v_origen = 'web' AND v_estado = 'pendiente' THEN
        SELECT COALESCE(SUM(r.cantidad_pasajeros), 0)::INT INTO v_retenidos
        FROM reserva r
        WHERE r.id_salida = p_salida
          AND r.id_reserva <> p_id_reserva
          AND r.origen = 'web'
          AND r.estado = 'pendiente'
          AND (r.fecha_expiracion IS NULL OR r.fecha_expiracion > now());

        IF v_retenidos + p_cantidad > (v_cupo + 1) / 2 THEN
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

-- Cambio de fecha, capacidad, precio, punto de encuentro o estado de una
-- salida (HU-09). Bloquea la salida, impide bajar la capacidad por debajo
-- de los pasajeros ya reservados y audita cada campo modificado. Al pasar
-- a 'realizada', las reservas confirmadas de la salida pasan a
-- 'finalizada' (HU-07, T-HU-07.4).
CREATE OR REPLACE FUNCTION fn_actualizar_salida(
    p_id_salida       BIGINT,
    p_id_usuario      TEXT,
    p_fecha_salida    DATE DEFAULT NULL,
    p_fecha_retorno   DATE DEFAULT NULL,
    p_capacidad       INTEGER DEFAULT NULL,
    p_precio          NUMERIC DEFAULT NULL,
    p_motivo          VARCHAR DEFAULT NULL,
    p_punto_encuentro VARCHAR DEFAULT NULL,
    p_estado          VARCHAR DEFAULT NULL
) RETURNS BOOLEAN
SET search_path = turismo, public
AS $$
DECLARE
    v_ocupados       INT;
    v_duracion       SMALLINT;
    v_anterior       RECORD;
    v_fecha_salida   DATE;
    v_fecha_retorno  DATE;
    v_capacidad      INTEGER;
BEGIN
    SELECT s.fecha_salida, s.fecha_retorno, s.cupo_maximo, s.precio,
           s.punto_encuentro, s.estado, s.id_paquete
    INTO v_anterior
    FROM salida s
    WHERE s.id_salida = p_id_salida
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La salida % no existe', p_id_salida
            USING ERRCODE = 'no_data_found';
    END IF;

    IF v_anterior.estado IN ('realizada', 'cancelada') THEN
        RAISE EXCEPTION 'Una salida en estado «%» no admite cambios',
            v_anterior.estado USING ERRCODE = 'check_violation';
    END IF;

    IF p_estado IS NOT NULL AND p_estado <> v_anterior.estado THEN
        IF v_anterior.estado = 'programada'
           AND p_estado NOT IN ('confirmada', 'cancelada') THEN
            RAISE EXCEPTION 'La salida no puede pasar de «programada» a «%»',
                p_estado USING ERRCODE = 'check_violation';
        END IF;

        IF v_anterior.estado = 'confirmada'
           AND p_estado NOT IN ('realizada', 'cancelada') THEN
            RAISE EXCEPTION 'La salida no puede pasar de «confirmada» a «%»',
                p_estado USING ERRCODE = 'check_violation';
        END IF;

        IF p_estado = 'cancelada'
           AND (p_motivo IS NULL OR btrim(p_motivo) = '') THEN
            RAISE EXCEPTION 'La cancelación de una salida exige un motivo'
                USING ERRCODE = 'check_violation';
        END IF;
    END IF;

    v_fecha_salida  := COALESCE(p_fecha_salida, v_anterior.fecha_salida);
    v_fecha_retorno := COALESCE(p_fecha_retorno, v_anterior.fecha_retorno);
    v_capacidad     := COALESCE(p_capacidad, v_anterior.cupo_maximo);

    IF v_fecha_retorno < v_fecha_salida THEN
        RAISE EXCEPTION 'La fecha de retorno no puede ser anterior a la de salida'
            USING ERRCODE = 'check_violation';
    END IF;

    IF p_fecha_salida IS NOT NULL OR p_fecha_retorno IS NOT NULL THEN
        IF v_fecha_salida < CURRENT_DATE THEN
            RAISE EXCEPTION 'La nueva fecha de salida no puede ser anterior a hoy'
                USING ERRCODE = 'check_violation';
        END IF;

        SELECT p.duracion_dias INTO v_duracion
        FROM paquete p
        WHERE p.id_paquete = v_anterior.id_paquete;

        IF (v_fecha_retorno - v_fecha_salida + 1) <> v_duracion THEN
            RAISE EXCEPTION 'La salida dura % días, pero el paquete declara %',
                (v_fecha_retorno - v_fecha_salida + 1), v_duracion
                USING ERRCODE = 'check_violation';
        END IF;
    END IF;

    IF p_capacidad IS NOT NULL THEN
        SELECT COALESCE(SUM(r.cantidad_pasajeros), 0)::INT INTO v_ocupados
        FROM reserva r
        WHERE r.id_salida = p_id_salida
          AND r.estado IN ('pendiente', 'confirmada')
          AND (r.estado <> 'pendiente'
               OR r.fecha_expiracion IS NULL
               OR r.fecha_expiracion > now());

        IF v_capacidad < v_ocupados THEN
            RAISE EXCEPTION 'La capacidad no puede ser menor que los % pasajeros ya reservados',
                v_ocupados USING ERRCODE = 'check_violation';
        END IF;
    END IF;

    IF p_precio IS NOT NULL AND p_precio <= 0 THEN
        RAISE EXCEPTION 'El precio debe ser mayor que cero'
            USING ERRCODE = 'check_violation';
    END IF;

    UPDATE salida s
    SET fecha_salida    = v_fecha_salida,
        fecha_retorno   = v_fecha_retorno,
        cupo_maximo     = v_capacidad,
        precio          = COALESCE(p_precio, s.precio),
        punto_encuentro = CASE
            WHEN p_punto_encuentro IS NULL THEN s.punto_encuentro
            WHEN btrim(p_punto_encuentro) = '' THEN NULL
            ELSE btrim(p_punto_encuentro)
        END,
        estado          = COALESCE(p_estado, s.estado)
    WHERE s.id_salida = p_id_salida;

    IF v_fecha_salida <> v_anterior.fecha_salida THEN
        INSERT INTO historial_salida (
            id_salida, campo_modificado, valor_anterior, valor_nuevo, motivo, id_usuario
        ) VALUES (
            p_id_salida, 'fecha_salida', v_anterior.fecha_salida::TEXT,
            v_fecha_salida::TEXT, p_motivo, p_id_usuario
        );
    END IF;

    IF v_fecha_retorno <> v_anterior.fecha_retorno THEN
        INSERT INTO historial_salida (
            id_salida, campo_modificado, valor_anterior, valor_nuevo, motivo, id_usuario
        ) VALUES (
            p_id_salida, 'fecha_retorno', v_anterior.fecha_retorno::TEXT,
            v_fecha_retorno::TEXT, p_motivo, p_id_usuario
        );
    END IF;

    IF v_capacidad <> v_anterior.cupo_maximo THEN
        INSERT INTO historial_salida (
            id_salida, campo_modificado, valor_anterior, valor_nuevo, motivo, id_usuario
        ) VALUES (
            p_id_salida, 'cupo_maximo', v_anterior.cupo_maximo::TEXT,
            v_capacidad::TEXT, p_motivo, p_id_usuario
        );
    END IF;

    IF p_precio IS NOT NULL AND p_precio <> v_anterior.precio THEN
        INSERT INTO historial_salida (
            id_salida, campo_modificado, valor_anterior, valor_nuevo, motivo, id_usuario
        ) VALUES (
            p_id_salida, 'precio', v_anterior.precio::TEXT,
            p_precio::TEXT, p_motivo, p_id_usuario
        );
    END IF;

    IF p_punto_encuentro IS NOT NULL
       AND NULLIF(btrim(p_punto_encuentro), '')
           IS DISTINCT FROM v_anterior.punto_encuentro THEN
        INSERT INTO historial_salida (
            id_salida, campo_modificado, valor_anterior, valor_nuevo, motivo, id_usuario
        ) VALUES (
            p_id_salida, 'punto_encuentro', v_anterior.punto_encuentro,
            NULLIF(btrim(p_punto_encuentro), ''), p_motivo, p_id_usuario
        );
    END IF;

    IF p_estado IS NOT NULL AND p_estado <> v_anterior.estado THEN
        INSERT INTO historial_salida (
            id_salida, campo_modificado, valor_anterior, valor_nuevo, motivo, id_usuario
        ) VALUES (
            p_id_salida, 'estado', v_anterior.estado,
            p_estado, p_motivo, p_id_usuario
        );
    END IF;

    -- Las reservas confirmadas de una salida que se realizó pasan a
    -- finalizada (HU-07, T-HU-07.4): el viaje se concretó y la reserva
    -- conserva su historial. Las pendientes no cambian: vencen por su
    -- propio plazo con el barrido de solicitudes.
    IF p_estado = 'realizada' AND p_estado <> v_anterior.estado THEN
        WITH finalizadas AS (
            UPDATE reserva
            SET estado = 'finalizada'
            WHERE id_salida = p_id_salida
              AND estado = 'confirmada'
            RETURNING id_reserva
        )
        INSERT INTO historial_reserva (
            id_reserva, estado_anterior, estado_nuevo, id_usuario, observacion
        )
        SELECT id_reserva, 'confirmada', 'finalizada', p_id_usuario,
               'La salida se realizó; la reserva pasó a finalizada.'
        FROM finalizadas;
    END IF;

    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Barrido de solicitudes pendientes vencidas (RN-RES-09). La invoca el
-- cron diario y también el personal desde la bandeja de solicitudes
-- (T-HU-17.4); en ese caso deja en la auditoría la cuenta que lo corrió.
CREATE OR REPLACE FUNCTION fn_vencer_solicitudes_pendientes(
    p_id_usuario TEXT DEFAULT NULL
)
RETURNS INT
SET search_path = turismo, public
AS $$
DECLARE
    v_vencidas INT := 0;
    r RECORD;
BEGIN
    FOR r IN
        SELECT id_reserva, id_usuario
        FROM reserva
        WHERE estado = 'pendiente'
          AND fecha_expiracion IS NOT NULL
          AND fecha_expiracion <= now()
        FOR UPDATE
    LOOP
        UPDATE reserva
        SET estado = 'vencida',
            observaciones = COALESCE(observaciones || ' | ', '')
                          || 'Vencida por falta de confirmación dentro del plazo previsto.'
        WHERE id_reserva = r.id_reserva;

        INSERT INTO historial_reserva (
            id_reserva, estado_anterior, estado_nuevo, id_usuario, observacion
        ) VALUES (
            r.id_reserva, 'pendiente', 'vencida',
            COALESCE(p_id_usuario, r.id_usuario),
            CASE
                WHEN p_id_usuario IS NOT NULL THEN
                    'Vencimiento ejecutado por el personal desde la bandeja.'
                ELSE
                    'Vencimiento automático de la solicitud pendiente.'
            END
        );

        v_vencidas := v_vencidas + 1;
    END LOOP;

    RETURN v_vencidas;
END;
$$ LANGUAGE plpgsql;

-- El reporte ahora informa las reservas finalizadas (T-HU-07.4): la
-- columna completa la cantidad de reservas por estado de RN-REP-02.
CREATE OR REPLACE VIEW vista_reservas_por_fecha AS
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
                       OR r.fecha_expiracion > now())), 0))::INT AS cupo_disponible,
    COUNT(r.id_reserva)
        FILTER (WHERE r.estado = 'finalizada') AS reservas_finalizadas
FROM salida s
JOIN paquete p ON p.id_paquete = s.id_paquete
LEFT JOIN reserva r ON r.id_salida = s.id_salida
GROUP BY s.fecha_salida, s.id_salida, s.id_paquete, p.codigo, p.nombre, s.cupo_maximo
ORDER BY s.fecha_salida;
