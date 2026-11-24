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

INSERT INTO turismo.cliente (tipo_documento, numero_documento, nombres, apellidos, correo)
VALUES ('CI', 'PRB-0001', 'Prueba', 'Uno',   'prb1@prueba.bo'),
       ('CI', 'PRB-0002', 'Prueba', 'Dos',   'prb2@prueba.bo'),
       ('CI', 'PRB-0003', 'Prueba', 'Tres',  'prb3@prueba.bo'),
       ('CI', 'PRB-0004', 'Prueba', 'Cuatro','prb4@prueba.bo'),
       ('CI', 'PRB-0005', 'Prueba', 'Cinco', 'prb5@prueba.bo');

-- 1. Crear una reserva: nace pendiente, con vencimiento a 24 horas,
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
       OR v_expira < now() + INTERVAL '23 hours'
       OR v_expira > now() + INTERVAL '24 hours' THEN
        RAISE EXCEPTION 'FALLO: el vencimiento no es a 24 horas';
    END IF;

    SELECT count(*) INTO v_audita
    FROM historial_reserva
    WHERE id_reserva = v_id_reserva
      AND estado_anterior IS NULL
      AND estado_nuevo = 'pendiente';

    IF v_audita <> 1 THEN
        RAISE EXCEPTION 'FALLO: la creación no quedó auditada';
    END IF;

    RAISE NOTICE 'OK: la reserva nace pendiente, a 24 horas y auditada';
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
        PERFORM fn_crear_reserva(v_cliente, v_salida, 2, 'web', 'u-prueba');
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
    FROM reserva
    WHERE estado = 'pendiente'
      AND id_salida = (SELECT id_salida FROM salida
          WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRB'))
    ORDER BY id_reserva
    LIMIT 1;

    -- La confirmación exige el anticipo validado (RN-RES-18) y el
    -- manifiesto completo (RN-RES-19): la prueba llena ambos como lo
    -- haría la oficina.
    PERFORM fn_registrar_pago(
        v_id_reserva, 'anticipo', 150, 'efectivo', 'u-prueba',
        NULL, 'Pago completo en la oficina.', true
    );

    PERFORM fn_guardar_manifiesto(
        v_id_reserva,
        jsonb_build_array(
            jsonb_build_object('tipo_documento', 'CI', 'numero_documento',
                               'RES-001', 'nombres', 'Prueba', 'apellidos', 'Uno'),
            jsonb_build_object('tipo_documento', 'CI', 'numero_documento',
                               'RES-002', 'nombres', 'Prueba', 'apellidos', 'Dos'),
            jsonb_build_object('tipo_documento', 'CI', 'numero_documento',
                               'RES-003', 'nombres', 'Prueba', 'apellidos', 'Tres'),
            jsonb_build_object('tipo_documento', 'CI', 'numero_documento',
                               'RES-004', 'nombres', 'Prueba', 'apellidos', 'Cuatro'),
            jsonb_build_object('tipo_documento', 'CI', 'numero_documento',
                               'RES-005', 'nombres', 'Prueba', 'apellidos', 'Cinco')
        ),
        'u-prueba'
    );

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
        'PRB-RES-01', v_cliente, v_salida, 'u-prueba', 'web',
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

-- 7. Tope de la solicitud web: una solicitud del canal web no admite más
--    de 4 pasajeros (RN-RES-15), aunque el cupo alcanza.
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
        PERFORM fn_crear_reserva(v_cliente, v_salida, 5, 'web', 'u-prueba');
        RAISE EXCEPTION 'FALLO: se aceptó una solicitud web de 5 pasajeros';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: la solicitud web de 5 pasajeros se rechaza por el tope del canal';
    END;

    -- El canal personal no tiene ese tope.
    PERFORM fn_crear_reserva(v_cliente, v_salida, 5, 'personal', 'u-prueba');
    RAISE NOTICE 'OK: el canal personal admite más de 4 pasajeros';
END;
$$;

-- 8. Tope global de retención: las solicitudes web pendientes vigentes de
--    una salida no retienen más de la mitad del cupo (RN-RES-16). La
--    salida de prueba tiene 20 lugares; el tope web es 10. Al llegar aquí
--    hay 5 confirmadas y 5 pendientes del canal personal, que no cuentan
--    para la retención web.
DO $$
DECLARE
    v_salida BIGINT;
BEGIN
    SELECT id_salida INTO v_salida FROM salida
    WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRB');

    -- Tres solicitudes web de 3 pasajeros: 9 de los 10 lugares retenibles.
    PERFORM fn_crear_reserva(
        (SELECT id_cliente FROM cliente WHERE numero_documento = 'PRB-0001'),
        v_salida, 3, 'web', 'u-prueba');

    PERFORM fn_crear_reserva(
        (SELECT id_cliente FROM cliente WHERE numero_documento = 'PRB-0003'),
        v_salida, 3, 'web', 'u-prueba');

    PERFORM fn_crear_reserva(
        (SELECT id_cliente FROM cliente WHERE numero_documento = 'PRB-0004'),
        v_salida, 3, 'web', 'u-prueba');
    RAISE NOTICE 'OK: la avalancha retiene 9 de los 10 lugares web';

    -- Un quinto cliente no puede retener 2 más: 9 + 2 superan el tope.
    BEGIN
        PERFORM fn_crear_reserva(
            (SELECT id_cliente FROM cliente WHERE numero_documento = 'PRB-0005'),
            v_salida, 2, 'web', 'u-prueba');
        RAISE EXCEPTION 'FALLO: la retención web superó la mitad del cupo';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: la avalancha de solicitudes web no retiene más de la mitad del cupo';
    END;

    -- El personal sigue vendiendo aunque la retención web esté al tope.
    PERFORM fn_crear_reserva(
        (SELECT id_cliente FROM cliente WHERE numero_documento = 'PRB-0005'),
        v_salida, 1, 'personal', 'u-prueba');
    RAISE NOTICE 'OK: el personal vende aunque la retención web esté al tope';
END;
$$;

-- 9. Una salida ya realizada no admite reservas.
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


-- 10. Manifiesto (HU-12, RN-RES-19 y RN-RES-21): confirmar sin manifiesto
--     se rechaza; al guardarlo, la cantidad declarada se ajusta a los
--     pasajeros registrados y el monto se recalcula. El test usa su
--     propia salida, porque las anteriores quedan ya realizadas.
DO $$
DECLARE
    v_salida  BIGINT;
    v_cliente BIGINT;
    v_reserva BIGINT;
    v_cantidad SMALLINT;
    v_monto   NUMERIC(12, 2);
BEGIN
    INSERT INTO salida (
        id_paquete, fecha_salida, fecha_retorno, cupo_maximo, precio, estado
    )
    SELECT id_paquete, CURRENT_DATE + 15, CURRENT_DATE + 16, 20, 100, 'programada'
    FROM paquete WHERE codigo = 'PRB';

    SELECT id_salida INTO v_salida FROM salida
    WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRB')
      AND fecha_salida = CURRENT_DATE + 15;
    SELECT id_cliente INTO v_cliente FROM cliente
    WHERE numero_documento = 'PRB-0002';

    v_reserva := fn_crear_reserva(v_cliente, v_salida, 3, 'personal', 'u-prueba');

    -- El anticipo se valida primero, para que el intento de confirmación
    -- quede bloqueado solo por el manifiesto (RN-RES-19).
    PERFORM fn_registrar_pago(
        v_reserva, 'anticipo', 90, 'efectivo', 'u-prueba', NULL, NULL, true
    );

    BEGIN
        PERFORM fn_confirmar_reserva(v_reserva, 'u-prueba');
        RAISE EXCEPTION 'FALLO: se confirmó sin manifiesto';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: la confirmación sin manifiesto se rechaza';
    END;

    -- Dos pasajeros: la cantidad declarada pasa de 3 a 2 y el monto a 200.
    PERFORM fn_guardar_manifiesto(
        v_reserva,
        jsonb_build_array(
            jsonb_build_object('tipo_documento', 'CI', 'numero_documento',
                               'MAN-001', 'nombres', 'Prueba', 'apellidos', 'Uno'),
            jsonb_build_object('tipo_documento', 'CI', 'numero_documento',
                               'MAN-002', 'nombres', 'Prueba', 'apellidos', 'Dos')
        ),
        'u-prueba'
    );

    SELECT cantidad_pasajeros, monto_total INTO v_cantidad, v_monto
    FROM reserva WHERE id_reserva = v_reserva;

    IF v_cantidad <> 2 OR v_monto <> 200 THEN
        RAISE EXCEPTION 'FALLO: el manifiesto no ajustó cantidad y monto (% / %)',
            v_cantidad, v_monto;
    END IF;

    -- El pasajero repetido se rechaza (documento único en el manifiesto).
    BEGIN
        PERFORM fn_guardar_manifiesto(
            v_reserva,
            jsonb_build_array(
                jsonb_build_object('tipo_documento', 'CI', 'numero_documento',
                                   'MAN-001', 'nombres', 'Prueba', 'apellidos', 'Uno'),
                jsonb_build_object('tipo_documento', 'CI', 'numero_documento',
                                   'MAN-001', 'nombres', 'Prueba', 'apellidos', 'Uno Repetido')
            ),
            'u-prueba'
        );
        RAISE EXCEPTION 'FALLO: se aceptó un pasajero repetido';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'OK: el pasajero repetido en el manifiesto se rechaza';
    END;

    RAISE NOTICE 'OK: el manifiesto ajusta la cantidad declarada y recalcula el monto';
END;
$$;

-- 11. Modificar la salida de una reserva (HU-07, RN-RES-20): revalida el
--     cupo, recalcula el monto con el precio vigente y audita.
DO $$
DECLARE
    v_origen  BIGINT;
    v_destino BIGINT;
    v_cliente BIGINT;
    v_reserva BIGINT;
    v_salida  BIGINT;
    v_monto   NUMERIC(12, 2);
    v_libres  INT;
BEGIN
    INSERT INTO salida (
        id_paquete, fecha_salida, fecha_retorno, cupo_maximo, precio, estado
    )
    SELECT id_paquete, CURRENT_DATE + 25, CURRENT_DATE + 26, 20, 100, 'programada'
    FROM paquete WHERE codigo = 'PRB';
    INSERT INTO salida (
        id_paquete, fecha_salida, fecha_retorno, cupo_maximo, precio, estado
    )
    SELECT id_paquete, CURRENT_DATE + 20, CURRENT_DATE + 21, 4, 200, 'programada'
    FROM paquete WHERE codigo = 'PRB';

    SELECT id_salida INTO v_origen FROM salida
    WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRB')
      AND fecha_salida = CURRENT_DATE + 25;
    SELECT id_salida INTO v_destino FROM salida
    WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRB')
      AND fecha_salida = CURRENT_DATE + 20;

    SELECT id_cliente INTO v_cliente FROM cliente
    WHERE numero_documento = 'PRB-0003';

    v_reserva := fn_crear_reserva(v_cliente, v_origen, 2, 'personal', 'u-prueba');

    PERFORM fn_actualizar_reserva(v_reserva, v_destino, 'u-prueba');

    SELECT id_salida, monto_total INTO v_salida, v_monto
    FROM reserva WHERE id_reserva = v_reserva;

    IF v_salida <> v_destino OR v_monto <> 400 THEN
        RAISE EXCEPTION 'FALLO: la modificación no movió la reserva ni recalculó (% / %)',
            v_salida, v_monto;
    END IF;

    -- En la salida original quedan 20 cupos libres: la movida liberó.
    SELECT cupo_disponible INTO v_libres
    FROM vista_disponibilidad_salida WHERE id_salida = v_origen;
    IF v_libres <> 20 THEN
        RAISE EXCEPTION 'FALLO: la salida original no liberó su cupo (%)', v_libres;
    END IF;

    -- El cupo de la salida destino no alcanza: pedir más que sus 4.
    BEGIN
        PERFORM fn_guardar_manifiesto(
            v_reserva,
            jsonb_build_array(
                jsonb_build_object('tipo_documento', 'CI', 'numero_documento', 'MOV-001',
                                   'nombres', 'Movimiento', 'apellidos', 'Uno'),
                jsonb_build_object('tipo_documento', 'CI', 'numero_documento', 'MOV-002',
                                   'nombres', 'Movimiento', 'apellidos', 'Dos'),
                jsonb_build_object('tipo_documento', 'CI', 'numero_documento', 'MOV-003',
                                   'nombres', 'Movimiento', 'apellidos', 'Tres'),
                jsonb_build_object('tipo_documento', 'CI', 'numero_documento', 'MOV-004',
                                   'nombres', 'Movimiento', 'apellidos', 'Cuatro'),
                jsonb_build_object('tipo_documento', 'CI', 'numero_documento', 'MOV-005',
                                   'nombres', 'Movimiento', 'apellidos', 'Cinco')
            ),
            'u-prueba'
        );
        RAISE EXCEPTION 'FALLO: se aceptó un manifiesto que excede el cupo';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ajustar la reserva más allá del cupo se rechaza';
    END;

    SELECT count(*) INTO v_libres
    FROM historial_reserva
    WHERE id_reserva = v_reserva
      AND observacion LIKE 'Salida %';
    IF v_libres < 1 THEN
        RAISE EXCEPTION 'FALLO: la modificación no quedó auditada';
    END IF;

    RAISE NOTICE 'OK: la modificación de salida revalida, recalcula y audita';
END;
$$;

-- 12. Los pagos comprometidos no pueden quedar por encima del nuevo
--     monto al reducir la reserva (RN-RES-20).
DO $$
DECLARE
    v_salida  BIGINT;
    v_cliente BIGINT;
    v_reserva BIGINT;
BEGIN
    INSERT INTO salida (
        id_paquete, fecha_salida, fecha_retorno, cupo_maximo, precio, estado
    )
    SELECT id_paquete, CURRENT_DATE + 30, CURRENT_DATE + 31, 20, 100, 'programada'
    FROM paquete WHERE codigo = 'PRB';

    SELECT id_salida INTO v_salida FROM salida
    WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRB')
      AND fecha_salida = CURRENT_DATE + 30;
    SELECT id_cliente INTO v_cliente FROM cliente
    WHERE numero_documento = 'PRB-0004';

    v_reserva := fn_crear_reserva(v_cliente, v_salida, 5, 'personal', 'u-prueba');

    PERFORM fn_registrar_pago(
        v_reserva, 'anticipo', 150, 'efectivo', 'u-prueba', NULL, NULL, true
    );

    BEGIN
        PERFORM fn_guardar_manifiesto(
            v_reserva,
            jsonb_build_array(
                jsonb_build_object('tipo_documento', 'CI', 'numero_documento', 'PAG-001',
                                   'nombres', 'Pago', 'apellidos', 'Uno')
            ),
            'u-prueba'
        );
        RAISE EXCEPTION 'FALLO: se redujo la reserva por debajo de sus pagos';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: reducir por debajo de los pagos comprometidos se rechaza';
    END;
END;
$$;

-- 13. Cancelaciones (HU-13, RN-RES-14): el cliente solicita y el
--     personal ejecuta con motivo; el cupo se libera por cálculo.
DO $$
DECLARE
    v_salida  BIGINT;
    v_cliente BIGINT;
    v_reserva BIGINT;
    v_estado  VARCHAR(15);
    v_marcada BOOLEAN;
    v_libres  INT;
BEGIN
    INSERT INTO salida (
        id_paquete, fecha_salida, fecha_retorno, cupo_maximo, precio, estado
    )
    SELECT id_paquete, CURRENT_DATE + 35, CURRENT_DATE + 36, 20, 100, 'programada'
    FROM paquete WHERE codigo = 'PRB';

    SELECT id_salida INTO v_salida FROM salida
    WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRB')
      AND fecha_salida = CURRENT_DATE + 35;
    SELECT id_cliente INTO v_cliente FROM cliente
    WHERE numero_documento = 'PRB-0005';

    v_reserva := fn_crear_reserva(v_cliente, v_salida, 1, 'personal', 'u-prueba');

    PERFORM fn_solicitar_cancelacion(v_reserva, 'u-prueba');

    SELECT (fecha_solicitud_cancelacion IS NOT NULL) INTO v_marcada
    FROM reserva WHERE id_reserva = v_reserva;
    IF NOT v_marcada THEN
        RAISE EXCEPTION 'FALLO: la solicitud de cancelación no quedó marcada';
    END IF;

    PERFORM fn_ejecutar_cancelacion(v_reserva, 'El cliente ya no viaja', 'u-prueba');

    SELECT estado INTO v_estado FROM reserva WHERE id_reserva = v_reserva;
    IF v_estado <> 'cancelada' THEN
        RAISE EXCEPTION 'FALLO: la cancelación no dejó el estado cancelada (%)', v_estado;
    END IF;

    -- La cancelada ya no ocupa cupo en la vista.
    SELECT cupo_disponible INTO v_libres
    FROM vista_disponibilidad_salida WHERE id_salida = v_salida;
    IF v_libres <> 20 THEN
        RAISE EXCEPTION 'FALLO: la reserva cancelada sigue ocupando cupo (%)', v_libres;
    END IF;

    BEGIN
        PERFORM fn_solicitar_cancelacion(v_reserva, 'u-prueba');
        RAISE EXCEPTION 'FALLO: se solicitó la cancelación de una cancelada';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: una reserva cancelada no admite nueva cancelación';
    END;

    RAISE NOTICE 'OK: la cancelación se solicita, se ejecuta y libera el cupo';
END;
$$;


-- 14. La retención web (RN-RES-16) se revalida al modificar una reserva
--     del canal web (T-HU-06.4): crecer el manifiesto no puede llevar la
--     retención pendiente web más allá de la mitad del cupo. La salida
--     tiene 10 lugares; el tope web es 5.
DO $$
DECLARE
    v_salida  BIGINT;
    v_a       BIGINT;
    v_b       BIGINT;
    v_cantidad SMALLINT;
    v_estado  VARCHAR(15);
    v_monto   NUMERIC(12, 2);
BEGIN
    INSERT INTO salida (
        id_paquete, fecha_salida, fecha_retorno, cupo_maximo, precio, estado
    )
    SELECT id_paquete, CURRENT_DATE + 40, CURRENT_DATE + 41, 10, 100, 'programada'
    FROM paquete WHERE codigo = 'PRB';

    SELECT id_salida INTO v_salida FROM salida
    WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRB')
      AND fecha_salida = CURRENT_DATE + 40;

    v_a := fn_crear_reserva(
        (SELECT id_cliente FROM cliente WHERE numero_documento = 'PRB-0001'),
        v_salida, 2, 'web', 'u-prueba');
    v_b := fn_crear_reserva(
        (SELECT id_cliente FROM cliente WHERE numero_documento = 'PRB-0002'),
        v_salida, 2, 'web', 'u-prueba');

    -- Retenidos: 4 de los 5 lugares web. Hacer crecer el manifiesto de A
    -- a 4 pasajeros dejaría la retención en 2 + 4 = 6: se rechaza.
    BEGIN
        PERFORM fn_guardar_manifiesto(
            v_a,
            jsonb_build_array(
                jsonb_build_object('tipo_documento', 'CI', 'numero_documento', 'RET-001',
                                   'nombres', 'Retención', 'apellidos', 'Uno'),
                jsonb_build_object('tipo_documento', 'CI', 'numero_documento', 'RET-002',
                                   'nombres', 'Retención', 'apellidos', 'Dos'),
                jsonb_build_object('tipo_documento', 'CI', 'numero_documento', 'RET-003',
                                   'nombres', 'Retención', 'apellidos', 'Tres'),
                jsonb_build_object('tipo_documento', 'CI', 'numero_documento', 'RET-004',
                                   'nombres', 'Retención', 'apellidos', 'Cuatro')
            ),
            'u-prueba'
        );
        RAISE EXCEPTION 'FALLO: la modificación web superó la retención del cupo';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: la retención web se revalida al modificar la solicitud';
    END;

    -- Reducir el manifiesto de A a 1 deja la retención en 2 + 1 = 3: pasa.
    PERFORM fn_guardar_manifiesto(
        v_a,
        jsonb_build_array(
            jsonb_build_object('tipo_documento', 'CI', 'numero_documento', 'RET-001',
                               'nombres', 'Retención', 'apellidos', 'Uno')
        ),
        'u-prueba'
    );

    SELECT cantidad_pasajeros, monto_total INTO v_cantidad, v_monto
    FROM reserva WHERE id_reserva = v_a;

    IF v_cantidad <> 1 OR v_monto <> 100 THEN
        RAISE EXCEPTION 'FALLO: la modificación web no ajustó cantidad y monto (% / %)',
            v_cantidad, v_monto;
    END IF;

    -- La reserva B sigue pendiente: la retención de B sola es 2 de 5.
    SELECT estado INTO v_estado FROM reserva WHERE id_reserva = v_b;
    IF v_estado <> 'pendiente' THEN
        RAISE EXCEPTION 'FALLO: la otra solicitud web cambió de estado (%)', v_estado;
    END IF;

    RAISE NOTICE 'OK: la retención web del 50%% se respeta al modificar';
END;
$$;

-- 15. Las reservas confirmadas de una salida que se realiza pasan a
--     finalizada (HU-07, T-HU-07.4), con su auditoría; las pendientes
--     siguen con su propio plazo de vencimiento.
DO $$
DECLARE
    v_salida  BIGINT;
    v_reserva BIGINT;
    v_pend    BIGINT;
    v_estado  VARCHAR(15);
    v_audita  INT;
BEGIN
    INSERT INTO salida (
        id_paquete, fecha_salida, fecha_retorno, cupo_maximo, precio, estado
    )
    SELECT id_paquete, CURRENT_DATE + 45, CURRENT_DATE + 46, 10, 100, 'programada'
    FROM paquete WHERE codigo = 'PRB';

    SELECT id_salida INTO v_salida FROM salida
    WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRB')
      AND fecha_salida = CURRENT_DATE + 45;

    v_reserva := fn_crear_reserva(
        (SELECT id_cliente FROM cliente WHERE numero_documento = 'PRB-0001'),
        v_salida, 2, 'personal', 'u-prueba');
    v_pend := fn_crear_reserva(
        (SELECT id_cliente FROM cliente WHERE numero_documento = 'PRB-0002'),
        v_salida, 1, 'web', 'u-prueba');

    -- La confirmación exige anticipo validado y manifiesto completo.
    PERFORM fn_registrar_pago(
        v_reserva, 'anticipo', 60, 'efectivo', 'u-prueba', NULL, NULL, true
    );
    PERFORM fn_guardar_manifiesto(
        v_reserva,
        jsonb_build_array(
            jsonb_build_object('tipo_documento', 'CI', 'numero_documento', 'FIN-001',
                               'nombres', 'Final', 'apellidos', 'Uno'),
            jsonb_build_object('tipo_documento', 'CI', 'numero_documento', 'FIN-002',
                               'nombres', 'Final', 'apellidos', 'Dos')
        ),
        'u-prueba'
    );
    PERFORM fn_confirmar_reserva(v_reserva, 'u-prueba');

    -- La salida se confirma y se realiza: la reserva confirmada pasa a
    -- finalizada (programada → confirmada → realizada, RN-SAL-11).
    PERFORM fn_actualizar_salida(v_salida, 'u-prueba', p_estado => 'confirmada');
    PERFORM fn_actualizar_salida(
        v_salida, 'u-prueba',
        p_estado => 'realizada',
        p_motivo => 'La salida se realizó según el programa.'
    );

    SELECT estado INTO v_estado FROM reserva WHERE id_reserva = v_reserva;
    IF v_estado <> 'finalizada' THEN
        RAISE EXCEPTION 'FALLO: la reserva confirmada no quedó finalizada (%)', v_estado;
    END IF;

    SELECT count(*) INTO v_audita
    FROM historial_reserva
    WHERE id_reserva = v_reserva
      AND estado_anterior = 'confirmada'
      AND estado_nuevo = 'finalizada'
      AND id_usuario = 'u-prueba';

    IF v_audita <> 1 THEN
        RAISE EXCEPTION 'FALLO: la finalización no quedó auditada';
    END IF;

    -- La pendiente no cambia: vence por su propio plazo.
    SELECT estado INTO v_estado FROM reserva WHERE id_reserva = v_pend;
    IF v_estado <> 'pendiente' THEN
        RAISE EXCEPTION 'FALLO: la pendiente cambió con la salida realizada (%)', v_estado;
    END IF;

    -- Una reserva finalizada no se modifica (RN-RES-14).
    BEGIN
        PERFORM fn_actualizar_reserva(v_reserva, v_salida, 'u-prueba');
        RAISE EXCEPTION 'FALLO: se modificó una reserva finalizada';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: la reserva finalizada no se modifica';
    END;

    RAISE NOTICE 'OK: la salida realizada finaliza sus reservas confirmadas';
END;
$$;


ROLLBACK;
