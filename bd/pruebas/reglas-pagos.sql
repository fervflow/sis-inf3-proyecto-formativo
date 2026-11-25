-- =====================================================================
--  Pruebas de las reglas de pagos (HU-14) y del anticipo de la
--  confirmación (HU-17, RN-RES-18). Con RN-PAG-02 y RN-PAG-05, puede
--  haber varios pagos por tipo y el saldo se paga por partes.
--
--  Uso:
--    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f bd/pruebas/reglas-pagos.sql
--
--  Corre dentro de una transacción y termina con ROLLBACK: no deja datos.
--  Si una regla no se cumple, la prueba falla con una excepción.
-- =====================================================================

BEGIN;
SET search_path TO turismo, public;

INSERT INTO turismo.usuario (id, name, email, id_rol, nombres, apellidos)
VALUES ('u-prueba', 'Prueba', 'prueba@vizcacha.tours', 1, 'Prueba', 'Prueba')
ON CONFLICT (id) DO NOTHING;

-- Dispositivo: un paquete activo con una salida de 20 cupos y clientes.
INSERT INTO turismo.paquete (codigo, nombre, duracion_dias, precio_base, estado)
VALUES ('PRP', 'Paquete de prueba de pagos', 2, 100, 'activo');

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
WHERE codigo = 'PRP';

INSERT INTO turismo.cliente (tipo_documento, numero_documento, nombres, apellidos, correo)
VALUES ('CI', 'PRP-0001', 'Prueba', 'Uno',   'prp1@prueba.bo'),
       ('CI', 'PRP-0002', 'Prueba', 'Dos',   'prp2@prueba.bo'),
       ('CI', 'PRP-0003', 'Prueba', 'Tres',  'prp3@prueba.bo'),
       ('CI', 'PRP-0005', 'Prueba', 'Cinco', 'prp5@prueba.bo'),
       ('CI', 'PRP-0006', 'Prueba', 'Seis',  'prp6@prueba.bo');

-- 1. El anticipo menor al 30% se rechaza; el exacto se acepta y nace
--    'registrado' (RN-PAG-01 y RN-PAG-04).
DO $$
DECLARE
    v_salida   BIGINT;
    v_cliente  BIGINT;
    v_reserva  BIGINT;
    v_id_pago  BIGINT;
    v_estado   VARCHAR(15);
    v_validada TEXT;
BEGIN
    SELECT id_salida INTO v_salida FROM salida
    WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRP');
    SELECT id_cliente INTO v_cliente FROM cliente
    WHERE numero_documento = 'PRP-0001';

    v_reserva := fn_crear_reserva(v_cliente, v_salida, 5, 'personal', 'u-prueba');

    BEGIN
        PERFORM fn_registrar_pago(
            v_reserva, 'anticipo', 149.99, 'qr', 'u-prueba',
            'MOCK-QR-01', NULL, false
        );
        RAISE EXCEPTION 'FALLO: se aceptó un anticipo menor al 30%% del total';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: el anticipo menor al 30%% del total se rechaza';
    END;

    v_id_pago := fn_registrar_pago(
        v_reserva, 'anticipo', 150, 'qr', 'u-prueba',
        'MOCK-QR-02', 'Pago simulado por QR.', false
    );

    SELECT estado, id_usuario_validacion::text INTO v_estado, v_validada
    FROM pago WHERE id_pago = v_id_pago;

    IF v_estado <> 'registrado' OR v_validada IS NOT NULL THEN
        RAISE EXCEPTION 'FALLO: el pago del cliente nació % (% validación)',
            v_estado, coalesce(v_validada, 'sin');
    END IF;

    RAISE NOTICE 'OK: el anticipo del cliente nace registrado, sin validación';
END;
$$;

-- 2. Un segundo pago del mismo tipo se admite dentro del saldo
--    pendiente; el que lo supera se rechaza (RN-PAG-02 y RN-PAG-05).
DO $$
DECLARE
    v_reserva BIGINT;
BEGIN
    SELECT id_reserva INTO v_reserva
    FROM reserva
    WHERE id_salida = (SELECT id_salida FROM salida
        WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRP'))
      AND cantidad_pasajeros = 5;

    -- La reserva tiene un anticipo de 150 sobre un total de 500: queda
    -- pendiente 350 y un segundo pago cabe dentro de él.
    PERFORM fn_registrar_pago(
        v_reserva, 'anticipo', 200, 'qr', 'u-prueba', 'MOCK-QR-03', NULL, false
    );
    RAISE NOTICE 'OK: el segundo pago del mismo tipo se admite (RN-PAG-02)';

    BEGIN
        PERFORM fn_registrar_pago(
            v_reserva, 'saldo', 200, 'efectivo', 'u-prueba', NULL, NULL, true
        );
        RAISE EXCEPTION 'FALLO: se aceptó un pago que supera el saldo pendiente';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: el pago que supera el saldo pendiente se rechaza';
    END;
END;
$$;

-- 3. El pago que registra el personal nace validado, con su usuario y
--    fecha (RN-PAG-04).
DO $$
DECLARE
    v_salida  BIGINT;
    v_cliente BIGINT;
    v_reserva BIGINT;
    v_id_pago BIGINT;
    v_estado  VARCHAR(15);
    v_usuario TEXT;
    v_fecha   TIMESTAMPTZ;
BEGIN
    SELECT id_salida INTO v_salida FROM salida
    WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRP');
    SELECT id_cliente INTO v_cliente FROM cliente
    WHERE numero_documento = 'PRP-0002';

    v_reserva := fn_crear_reserva(v_cliente, v_salida, 1, 'personal', 'u-prueba');

    v_id_pago := fn_registrar_pago(
        v_reserva, 'anticipo', 100, 'efectivo', 'u-prueba',
        NULL, 'Pago completo en la oficina.', true
    );

    SELECT estado, id_usuario_validacion::text, fecha_validacion
    INTO v_estado, v_usuario, v_fecha
    FROM pago WHERE id_pago = v_id_pago;

    IF v_estado <> 'validado' OR v_usuario IS DISTINCT FROM 'u-prueba' OR v_fecha IS NULL THEN
        RAISE EXCEPTION 'FALLO: el pago del personal no nació validado (% / % / %)',
            v_estado, coalesce(v_usuario, 'nulo'), coalesce(v_fecha::text, 'nulo');
    END IF;

    RAISE NOTICE 'OK: el pago del personal nace validado con usuario y fecha';
END;
$$;

-- 4. El saldo exige anticipo previo y paga el resto exacto (RN-PAG-05).
DO $$
DECLARE
    v_salida  BIGINT;
    v_cliente BIGINT;
    v_reserva BIGINT;
BEGIN
    SELECT id_salida INTO v_salida FROM salida
    WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRP');
    SELECT id_cliente INTO v_cliente FROM cliente
    WHERE numero_documento = 'PRP-0003';

    v_reserva := fn_crear_reserva(v_cliente, v_salida, 5, 'personal', 'u-prueba');

    BEGIN
        PERFORM fn_registrar_pago(
            v_reserva, 'saldo', 500, 'efectivo', 'u-prueba', NULL, NULL, true
        );
        RAISE EXCEPTION 'FALLO: se aceptó un saldo sin anticipo previo';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: el saldo sin anticipo previo se rechaza';
    END;

    PERFORM fn_registrar_pago(
        v_reserva, 'anticipo', 200, 'qr', 'u-prueba', 'MOCK-QR-04', NULL, false
    );

    BEGIN
        PERFORM fn_registrar_pago(
            v_reserva, 'saldo', 400, 'efectivo', 'u-prueba', NULL, NULL, true
        );
        RAISE EXCEPTION 'FALLO: se aceptó un saldo mayor al pendiente';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: el saldo mayor al pendiente se rechaza';
    END;

    -- El saldo puede pagarse por partes (RN-PAG-05): cada pago reduce
    -- el pendiente y pueden sumarse varios hasta cubrirlo.
    PERFORM fn_registrar_pago(
        v_reserva, 'saldo', 100, 'efectivo', 'u-prueba', NULL, NULL, true
    );
    RAISE NOTICE 'OK: el saldo parcial se admite (RN-PAG-05)';

    PERFORM fn_registrar_pago(
        v_reserva, 'saldo', 200, 'transferencia', 'u-prueba', NULL, NULL, true
    );
    RAISE NOTICE 'OK: otro pago parcial cubre el resto del saldo';

    BEGIN
        PERFORM fn_registrar_pago(
            v_reserva, 'saldo', 1, 'efectivo', 'u-prueba', NULL, NULL, true
        );
        RAISE EXCEPTION 'FALLO: se aceptó un pago sobre el saldo ya cubierto';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: pagar de más del saldo pendiente se rechaza';
    END;
END;
$$;

-- 5. Una reserva vencida no admite pagos (RN-PAG-06).
DO $$
DECLARE
    v_salida  BIGINT;
    v_cliente BIGINT;
    v_reserva BIGINT;
BEGIN
    SELECT id_salida INTO v_salida FROM salida
    WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRP');
    SELECT id_cliente INTO v_cliente FROM cliente
    WHERE numero_documento = 'PRP-0001';

    INSERT INTO reserva (
        codigo, id_cliente, id_salida, id_usuario, origen,
        cantidad_pasajeros, monto_total, estado, fecha_expiracion
    ) VALUES (
        'PRP-RES-01', v_cliente, v_salida, 'u-prueba', 'web',
        2, 200, 'vencida', now() - INTERVAL '1 hour'
    ) RETURNING id_reserva INTO v_reserva;

    BEGIN
        PERFORM fn_registrar_pago(
            v_reserva, 'anticipo', 60, 'qr', 'u-prueba', 'MOCK-QR-05', NULL, false
        );
        RAISE EXCEPTION 'FALLO: se aceptó un pago sobre una reserva vencida';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: la reserva vencida no admite pagos';
    END;
END;
$$;

-- 6. Confirmar sin anticipo validado se rechaza; validado el pago, la
--    confirmación procede (RN-RES-18).
DO $$
DECLARE
    v_salida  BIGINT;
    v_cliente BIGINT;
    v_reserva BIGINT;
    v_id_pago BIGINT;
BEGIN
    SELECT id_salida INTO v_salida FROM salida
    WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRP');
    SELECT id_cliente INTO v_cliente FROM cliente
    WHERE numero_documento = 'PRP-0005';

    v_reserva := fn_crear_reserva(v_cliente, v_salida, 3, 'personal', 'u-prueba');

    -- El manifiesto completo también condiciona la confirmación
    -- (RN-RES-19): se registran los tres pasajeros.
    PERFORM fn_guardar_manifiesto(
        v_reserva,
        jsonb_build_array(
            jsonb_build_object('tipo_documento', 'CI', 'numero_documento',
                               'PAS-001', 'nombres', 'Prueba', 'apellidos', 'Uno'),
            jsonb_build_object('tipo_documento', 'CI', 'numero_documento',
                               'PAS-002', 'nombres', 'Prueba', 'apellidos', 'Dos'),
            jsonb_build_object('tipo_documento', 'CI', 'numero_documento',
                               'PAS-003', 'nombres', 'Prueba', 'apellidos', 'Tres')
        ),
        'u-prueba'
    );

    v_id_pago := fn_registrar_pago(
        v_reserva, 'anticipo', 90, 'qr', 'u-prueba', 'MOCK-QR-06', NULL, false
    );

    BEGIN
        PERFORM fn_confirmar_reserva(v_reserva, 'u-prueba');
        RAISE EXCEPTION 'FALLO: se confirmó sin anticipo validado';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: la confirmación sin anticipo validado se rechaza';
    END;

    PERFORM fn_validar_pago(v_id_pago, 'u-prueba');
    PERFORM fn_confirmar_reserva(v_reserva, 'u-prueba');

    IF (SELECT estado FROM reserva WHERE id_reserva = v_reserva) <> 'confirmada' THEN
        RAISE EXCEPTION 'FALLO: la confirmación con anticipo validado no ocurrió';
    END IF;

    RAISE NOTICE 'OK: con el anticipo validado, la confirmación procede';
END;
$$;

-- 7. La confirmación suma los anticipos validados (RN-RES-18): si el
--    manifiesto crece y el total sube, un anticipo adicional restablece
--    el respaldo y la confirmación procede.
DO $$
DECLARE
    v_salida  BIGINT;
    v_cliente BIGINT;
    v_reserva BIGINT;
    v_id_pago BIGINT;
    v_id_pago2 BIGINT;
BEGIN
    SELECT id_salida INTO v_salida FROM salida
    WHERE id_paquete = (SELECT id_paquete FROM paquete WHERE codigo = 'PRP');
    SELECT id_cliente INTO v_cliente FROM cliente
    WHERE numero_documento = 'PRP-0006';

    -- Una reserva de 1 pasajero: total 100 y anticipo mínimo 30.
    v_reserva := fn_crear_reserva(v_cliente, v_salida, 1, 'personal', 'u-prueba');

    v_id_pago := fn_registrar_pago(
        v_reserva, 'anticipo', 30, 'qr', 'u-prueba', 'MOCK-QR-07', NULL, false
    );
    PERFORM fn_validar_pago(v_id_pago, 'u-prueba');

    -- El manifiesto del personal amplía el grupo a 2: el total pasa a
    -- 200 y el mínimo a 60 (RN-RES-21).
    PERFORM fn_guardar_manifiesto(
        v_reserva,
        jsonb_build_array(
            jsonb_build_object('tipo_documento', 'CI', 'numero_documento',
                               'PAS-101', 'nombres', 'Prueba', 'apellidos', 'Dos'),
            jsonb_build_object('tipo_documento', 'CI', 'numero_documento',
                               'PAS-102', 'nombres', 'Prueba', 'apellidos', 'Tres')
        ),
        'u-prueba'
    );

    BEGIN
        PERFORM fn_confirmar_reserva(v_reserva, 'u-prueba');
        RAISE EXCEPTION 'FALLO: se confirmó con el anticipo por debajo del nuevo mínimo';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: tras crecer el total, el anticipo previo ya no alcanza';
    END;

    -- Un segundo anticipo restablece el respaldo: 30 + 30 = 60 (RN-PAG-02).
    v_id_pago2 := fn_registrar_pago(
        v_reserva, 'anticipo', 30, 'efectivo', 'u-prueba', NULL, NULL, true
    );

    PERFORM fn_confirmar_reserva(v_reserva, 'u-prueba');

    IF (SELECT estado FROM reserva WHERE id_reserva = v_reserva) <> 'confirmada' THEN
        RAISE EXCEPTION 'FALLO: la confirmación con anticipos sumados no ocurrió';
    END IF;

    RAISE NOTICE 'OK: la suma de anticipos validados respalda la confirmación';
END;
$$;

ROLLBACK;
