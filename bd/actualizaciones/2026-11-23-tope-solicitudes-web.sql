-- Actualización de la función de creación de reservas: topes del canal web
-- (RN-RES-15 y RN-RES-16). Es idempotente: reemplaza la función.
SET search_path TO turismo, public;
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

    -- Tope de la solicitud web (RN-RES-15): el formulario anónimo no
    -- retiene todo el cupo en una sola solicitud; los grupos mayores se
    -- atienden por la oficina, en el canal personal.
    IF p_origen = 'web' AND p_cantidad > 4 THEN
        RAISE EXCEPTION 'Una solicitud del canal web admite hasta 4 pasajeros; los grupos mayores se atienden en la agencia'
            USING ERRCODE = 'check_violation';
    END IF;

    -- Tope global de retención (RN-RES-16): las solicitudes web pendientes
    -- vigentes no retienen más de la mitad del cupo, para que una avalancha
    -- de formularios no bloquee la venta. Las pendientes del canal personal
    -- no cuentan: hay una persona atendida detrás. Confirmar libera espacio.
    IF p_origen = 'web' THEN
        SELECT COALESCE(SUM(r.cantidad_pasajeros), 0)::INT INTO v_retenidos
        FROM reserva r
        WHERE r.id_salida = p_id_salida
          AND r.origen = 'web'
          AND r.estado = 'pendiente'
          AND (r.fecha_expiracion IS NULL OR r.fecha_expiracion > now());

        IF v_retenidos + p_cantidad > (v_cupo_maximo + 1) / 2 THEN
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
           now() + INTERVAL '48 hours'
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
