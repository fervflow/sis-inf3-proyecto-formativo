-- =====================================================================
--  Pruebas de las reglas de reservas y solicitudes (HU-06, HU-17)
--
--  Uso:
--    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f bd/pruebas/reglas-reservas.sql
--
--  Corre dentro de una transacción y termina con ROLLBACK: no deja datos.
--  Si una regla no se cumple, la prueba falla con una excepción.
-- =====================================================================

BEGIN;
SET search_path TO turismo, public;

INSERT INTO turismo.usuario (id, name, email, id_rol, nombres, apellidos)
VALUES ('u-prueba', 'Prueba', 'prueba@vizcacha.tours', 1, 'Prueba', 'Prueba')
ON CONFLICT (id) DO NOTHING;

-- Dispositivo: un paquete activo con una salida de 20 cupos y dos clientes.
INSERT INTO turismo.paquete (codigo, nombre, duracion_dias, precio_base, estado)
VALUES ('PRB', 'Paquete de prueba', 2, 100, 'activo');

INSERT INTO turismo.salida (
    id_paquete, fecha_salida, fecha_retorno, cupo_maximo, precio, estado
)
SELECT id_paquete,
       CURRENT_DATE + 10,
       CURRENT_DATE + 11,
       20,
       100,
       'programada'
FROM turismo.paquete
WHERE codigo = 'PRB';

INSERT INTO turismo.cliente (tipo_documento, numero_documento, nombres, apellidos)
VALUES ('CI', 'PRB-0001', 'Prueba', 'Uno'),
       ('CI', 'PRB-0002', 'Prueba', 'Dos');

-- 1. Crear una reserva: nace pendiente, con vencimiento a 48 horas,
--    monto congelado y el cambio auditado.
DO $$
DECLARE
    v_id_reserva BIGINT;
    v_estado     VARCHAR(15);
    v_expira     TIMESTAMPTZ;
    v_monto      NUMERIC(12, 2);
    v_audita     INT;
BEGIN
    SELECT fn_crear_reserva(
        (SELECT id_cliente FROM cliente WHERE numero_documento = 'PRB-0001'),
        (SELECT id_salida FROM salida
            WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRB')),
        5,
        'personal',
        'u-prueba'
    ) INTO v_id_reserva;

    SELECT estado, fecha_expiracion, monto_total
    INTO v_estado, v_expira, v_monto
    FROM reserva WHERE id_reserva = v_id_reserva;

    IF v_estado <> 'pendiente' THEN
        RAISE EXCEPTION 'FALLO: la reserva nació en estado %', v_estado;
    END IF;
    IF v_monto <> 500 THEN
        RAISE EXCEPTION 'FALLO: el monto congelado es %', v_monto;
    END IF;
    IF v_expira IS NULL
       OR v_expira < now() + INTERVAL '47 hours'
       OR v_expira > now() + INTERVAL '48 hours' THEN
        RAISE EXCEPTION 'FALLO: el vencimiento no es a 48 horas';
    END IF;

    SELECT count(*) INTO v_audita
    FROM historial_reserva
    WHERE id_reserva = v_id_reserva
      AND estado_anterior IS NULL
      AND estado_nuevo = 'pendiente';

    IF v_audita <> 1 THEN
        RAISE EXCEPTION 'FALLO: la creación no quedó auditada';
    END IF;

    RAISE NOTICE 'OK: la reserva nace pendiente, a 48 horas y auditada';
END;
$$;

-- 2. El exceso de cupo se rechaza: la salida tiene 20 lugares y ya hay 5
--    ocupados; pedir 16 debe fallar.
DO $$
DECLARE
    v_salida BIGINT;
    v_cliente BIGINT;
BEGIN
    SELECT id_salida INTO v_salida FROM salida
    WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRB');

    SELECT id_cliente INTO v_cliente FROM cliente
    WHERE numero_documento = 'PRB-0002';

    BEGIN
        PERFORM fn_crear_reserva(v_cliente, v_salida, 16, 'personal', 'u-prueba');
        RAISE EXCEPTION 'FALLO: se aceptó una reserva que excede la capacidad';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: la reserva que excede el cupo se rechaza';
    END;
END;
$$;

-- 3. El cliente ya tiene una solicitud pendiente para esa salida: otra
--    solicitud del mismo cliente y salida no se crea.
DO $$
DECLARE
    v_salida BIGINT;
    v_cliente BIGINT;
BEGIN
    SELECT id_salida INTO v_salida FROM salida
    WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRB');

    SELECT id_cliente INTO v_cliente FROM cliente
    WHERE numero_documento = 'PRB-0001';

    BEGIN
        PERFORM fn_crear_reserva(v_cliente, v_salida, 2, 'web', 'sistema');
        RAISE EXCEPTION 'FALLO: se creó una segunda solicitud pendiente';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'OK: la segunda solicitud pendiente del cliente se rechaza';
    END;
END;
$$;

-- 4. Una reserva con canal inválido se rechaza.
DO $$
DECLARE
    v_salida BIGINT;
    v_cliente BIGINT;
BEGIN
    SELECT id_salida INTO v_salida FROM salida
    WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRB');

    SELECT id_cliente INTO v_cliente FROM cliente
    WHERE numero_documento = 'PRB-0002';

    BEGIN
        PERFORM fn_crear_reserva(v_cliente, v_salida, 1, 'telefono', 'u-prueba');
        RAISE EXCEPTION 'FALLO: se aceptó un canal de ingreso inválido';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: el canal de ingreso inválido se rechaza';
    END;
END;
$$;

-- 5. Confirmar una solicitud pendiente: pasa a confirmada, limpia el
--    vencimiento y queda auditada.
DO $$
DECLARE
    v_id_reserva BIGINT;
    v_estado     VARCHAR(15);
    v_expira     TIMESTAMPTZ;
    v_audita     INT;
BEGIN
    SELECT id_reserva INTO v_id_reserva
    FROM reserva WHERE estado = 'pendiente' LIMIT 1;

    PERFORM fn_confirmar_reserva(v_id_reserva, 'u-prueba');

    SELECT estado, fecha_expiracion INTO v_estado, v_expira
    FROM reserva WHERE id_reserva = v_id_reserva;

    IF v_estado <> 'confirmada' OR v_expira IS NOT NULL THEN
        RAISE EXCEPTION 'FALLO: la confirmación no limpió el vencimiento (% / %)',
            v_estado, coalesce(v_expira::text, 'nulo');
    END IF;

    SELECT count(*) INTO v_audita
    FROM historial_reserva
    WHERE id_reserva = v_id_reserva
      AND estado_anterior = 'pendiente'
      AND estado_nuevo = 'confirmada'
      AND id_usuario = 'u-prueba';

    IF v_audita <> 1 THEN
        RAISE EXCEPTION 'FALLO: la confirmación no quedó auditada';
    END IF;

    RAISE NOTICE 'OK: la confirmación pasa a confirmada, limpia el vencimiento y audita';
END;
$$;

-- 6. Una solicitud vencida deja de ocupar cupo en la vista y no puede
--    confirmarse después.
DO $$
DECLARE
    v_salida  BIGINT;
    v_cliente BIGINT;
    v_id_reserva BIGINT;
    v_libres     INT;
    v_estado     VARCHAR(15);
BEGIN
    SELECT id_salida INTO v_salida FROM salida
    WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRB');

    SELECT id_cliente INTO v_cliente FROM cliente
    WHERE numero_documento = 'PRB-0002';

    INSERT INTO reserva (
        codigo, id_cliente, id_salida, id_usuario, origen,
        cantidad_pasajeros, monto_total, estado, fecha_expiracion
    ) VALUES (
        'PRB-RES-01', v_cliente, v_salida, 'sistema', 'web',
        4, 400, 'pendiente', now() - INTERVAL '1 hour'
    ) RETURNING id_reserva INTO v_id_reserva;

    -- Antes del barrido: la vista ya no la cuenta.
    SELECT cupo_disponible INTO v_libres
    FROM vista_disponibilidad_salida WHERE id_salida = v_salida;
    IF v_libres <> 15 THEN
        RAISE EXCEPTION 'FALLO: la pendiente vencida sigue ocupando cupo (% libres)',
            v_libres;
    END IF;

    -- El barrido diario la pasa a vencida.
    PERFORM fn_vencer_solicitudes_pendientes();

    SELECT estado INTO v_estado FROM reserva WHERE id_reserva = v_id_reserva;
    IF v_estado <> 'vencida' THEN
        RAISE EXCEPTION 'FALLO: el barrido no la pasó a vencida (%)', v_estado;
    END IF;

    -- Intentar confirmarla después del vencimiento falla.
    BEGIN
        PERFORM fn_confirmar_reserva(v_id_reserva, 'u-prueba');
        RAISE EXCEPTION 'FALLO: se confirmó una solicitud vencida';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: la solicitud vencida no puede confirmarse';
    END;

    RAISE NOTICE 'OK: la pendiente vencida libera el cupo y no se confirma';
END;
$$;

-- 7. Una salida ya realizada no admite reservas.
DO $$
DECLARE
    v_salida  BIGINT;
    v_cliente BIGINT;
BEGIN
    UPDATE salida
    SET estado = 'realizada'
    WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRB');

    SELECT id_salida INTO v_salida FROM salida
    WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRB');

    SELECT id_cliente INTO v_cliente FROM cliente
    WHERE numero_documento = 'PRB-0002';

    BEGIN
        PERFORM fn_crear_reserva(v_cliente, v_salida, 1, 'personal', 'u-prueba');
        RAISE EXCEPTION 'FALLO: se reservó sobre una salida realizada';
    EXCEPTION
        WHEN no_data_found THEN
            RAISE NOTICE 'OK: la salida realizada no admite reservas';
    END;
END;
$$;

ROLLBACK;
