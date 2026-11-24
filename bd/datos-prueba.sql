-- =====================================================================
--  datos-prueba.sql
--  Datos de demostración y prueba para la base de Vizcacha Tours.
--
--  Uso:
--    psql "$DATABASE_URL_UNPOOLED" -f bd/datos-prueba.sql
--
--  Son datos de trabajo, no parte del esquema: el esquema se crea con
--  `make db-crear` (bd/esquema.sql) y estos registros se cargan aparte.
--  Son idempotentes: se pueden volver a cargar sin duplicar nada.
--
--  No contiene datos reales. Clientes, paquetes y proveedores ficticios,
--  coherentes con la operación de Potosí y su región.
-- =====================================================================
SET search_path TO turismo, public;

-- ---------------------------------------------------------------------
-- 1. Proveedores de la operación
-- ---------------------------------------------------------------------

INSERT INTO proveedor (nombre, nit, telefono, correo, direccion) VALUES
    ('Transporte Andes S.R.L.', '3025561008',  '+591 71234501', 'contacto@transporteandes.bo', 'Calle Ayacucho 145, Potosí'),
    ('Hostal Potosí',           NULL,          '+591 71234502', 'reservas@hostalpotosi.bo',    'Plaza 10 de Noviembre, Potosí'),
    ('Guías del Salar',         NULL,          '+591 71234503', 'guias@salar.bo',              'Av. Ferroviaria 20, Uyuni'),
    ('Hotel Jardines de Uyuni', '2055667012',  '+591 71234504', 'hotel@jardinesdeuyuni.bo',    'Calle Potosí 45, Uyuni'),
    ('Guías de Cerro Rico',     NULL,          '+591 71234505', 'guias@cerrorico.bo',         'Barrio La Merced, Potosí'),
    ('4x4 Altiplano Tours',     '3067890123',  '+591 71234506', 'flota@altiplano4x4.bo',       'Av. Circunvalación, Uyuni')
ON CONFLICT (lower(btrim(nombre))) DO NOTHING;

INSERT INTO proveedor_tipo (id_proveedor, tipo)
SELECT pr.id_proveedor, v.tipo
FROM proveedor pr
JOIN (VALUES
    ('Transporte Andes S.R.L.', 'transporte'),
    ('Hostal Potosí',           'hospedaje'),
    ('Hostal Potosí',           'alimentacion'),
    ('Guías del Salar',         'guia'),
    ('Hotel Jardines de Uyuni', 'hospedaje'),
    ('Hotel Jardines de Uyuni', 'alimentacion'),
    ('Guías de Cerro Rico',     'guia'),
    ('4x4 Altiplano Tours',     'transporte')
) AS v(nombre, tipo) ON lower(btrim(pr.nombre)) = lower(btrim(v.nombre))
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
-- 2. Cuentas de cliente de prueba
-- ---------------------------------------------------------------------
--  Cuentas de prueba con la contraseña «prueba1234»: dos clientes con
--  ficha vinculada (para el flujo web) y un asesor de personal (para la
--  bandeja de solicitudes y la validación de pagos). La cuarta ficha no
--  tiene cuenta: el personal la atiende por la oficina.

INSERT INTO usuario (id, name, email, id_rol, nombres, apellidos, telefono, estado, debe_cambiar_password)
SELECT v.id, v.nombre_completo, v.correo,
       (SELECT id_rol FROM rol WHERE codigo = v.rol),
       v.nombres, v.apellidos, v.telefono, 'activo', false
FROM (VALUES
    ('cli-maria-rojas-01', 'María Elena Rojas', 'maria.rojas@gmail.com', 'CLIENTE',
     'María Elena', 'Rojas Condori', '+591 72412345'),
    ('cli-juan-flores-02', 'Juan Carlos Flores', 'juan.flores@hotmail.com', 'CLIENTE',
     'Juan Carlos', 'Flores Mendoza', '+591 73398765'),
    ('per-asesor-web-03', 'Asesor de Ventas', 'asesor@vizcacha.tours', 'PERSONAL',
     'Asesor', 'de Ventas', '+591 71234509')
) AS v(id, nombre_completo, correo, rol, nombres, apellidos, telefono)
ON CONFLICT (email) DO NOTHING;

-- La contraseña «prueba1234» sirve en las tres cuentas.
INSERT INTO account (id, user_id, account_id, provider_id, password)
SELECT gen_random_uuid()::text, u.id, u.id, 'credential',
       'cc7f991018d85d92aec0df49c953d0d0:bfe56762932e3ff7f2e7e93b2cbd77b46ad8cdfb850c4f662cd6d57022b443e6bd7cb50f039fb9c24c954014271d5738678086f8cab1589c79c47e40e4031c4e'
FROM usuario u
WHERE u.email IN ('maria.rojas@gmail.com', 'juan.flores@hotmail.com', 'asesor@vizcacha.tours')
  AND NOT EXISTS (
      SELECT 1 FROM account a
      WHERE a.user_id = u.id AND a.provider_id = 'credential'
  );

INSERT INTO cliente (
    id_usuario, tipo_documento, numero_documento, nombres, apellidos,
    correo, telefono, direccion, fecha_nacimiento
)
SELECT u.id, 'CI', v.documento, v.nombres, v.apellidos,
       v.correo, v.telefono, v.direccion, v.nacimiento
FROM (VALUES
    ('4455667 PBO', 'María Elena', 'Rojas Condori', 'maria.rojas@gmail.com',
     '+591 72412345', 'Calle Chuquisaca 38, Potosí', DATE '1992-03-14'),
    ('6677889 PBO', 'Juan Carlos', 'Flores Mendoza', 'juan.flores@hotmail.com',
     '+591 73398765', 'Av. Villazo 950, Potosí', DATE '1986-09-02')
) AS v(documento, nombres, apellidos, correo, telefono, direccion, nacimiento)
JOIN usuario u ON u.email = v.correo
ON CONFLICT (tipo_documento, numero_documento) DO NOTHING;

-- Ficha sin cuenta, atendida por la oficina.
INSERT INTO cliente (
    tipo_documento, numero_documento, nombres, apellidos,
    correo, telefono, direccion
) VALUES
    ('NIT', '102345678', 'Colegio Don Bosco', 'Potosí',
     'colegio.donbosco@gmail.com', '+591 72244556', 'Calle Oruro 210, Potosí')
ON CONFLICT (tipo_documento, numero_documento) DO NOTHING;

-- ---------------------------------------------------------------------
-- 3. Paquetes turísticos
-- ---------------------------------------------------------------------

INSERT INTO paquete (
    codigo, nombre, id_lugar_destino, id_lugar_origen, tipo_recorrido,
    descripcion, duracion_dias, precio_base, itinerario,
    servicios_detalle, servicios_excluidos, estado,
    id_usuario_creador
)
SELECT
    v.codigo, v.nombre,
    (SELECT id_lugar FROM lugar WHERE codigo = v.destino),
    (SELECT id_lugar FROM lugar WHERE codigo = v.origen),
    v.tipo_recorrido, v.descripcion, v.duracion, v.precio, v.itinerario,
    v.detalle, v.excluidos, 'borrador',
    (SELECT id FROM usuario WHERE email = 'erick.vel@vizcacha.tours')
FROM (VALUES
    (
        'SAL-2026-001', 'Salar de Uyuni e Isla Incahuasi',
        'SAL', 'POT', 'sencillo',
        E'Tres días de altiplano: viaje Potosí–Uyuni, el salar más grande '
        || 'del mundo y la isla de cactus gigantes. Incluye noche en Uyuni '
        || 'y guía especializado.',
        3, 1250.00,
        E'Día 1: salida de Potosí, llegada a Uyuni y paseo por el cementerio '
        || 'de trenes.\nDía 2: Salar de Uyuni e Isla Incahuasi.\n'
        || 'Día 3: mercado artesanal de Uyuni y regreso a Potosí.',
        'El transporte en bus turístico, una noche de hotel en Uyuni, '
        || 'almuerzo en la isla, guía y entradas.',
        'Cena del primer día y gastos personales.'
    ),
    (
        'CER-2026-001', 'Potosí histórico y Cerro Rico',
        'CER', 'POT', 'sencillo',
        E'Dos días por la ciudad imperial: Casa de la Moneda, torres de la '
        || 'Compañía de Jesús y visita a una mina cooperativista del '
        || 'Cerro Rico con guía especializado.',
        2, 480.00,
        E'Día 1: centro histórico, Casa de la Moneda y mirador.\n'
        || 'Día 2: visita a la mina del Cerro Rico y mercado de los mineros.',
        'Almuerzo de ambos días, guía y entradas a museos y mina.',
        'Transporte fuera de la ciudad y equipo personal de la mina.'
    ),
    (
        'LCO-2026-001', 'Circuito Uyuni y lagunas de colores',
        'LCO', 'UYU', 'circuito',
        E'Cuatro días en 4x4 desde Uyuni: salar, isla Incahuasi, lagunas '
        || 'Colorada y Verde, geyseres y termas. El circuito vuelve a Uyuni.',
        4, 1950.00,
        E'Día 1: salar e Isla Incahuasi, noche en refugio.\n'
        || 'Día 2: lagunas y desierto de Siloli.\n'
        || 'Día 3: geyseres, termas y Laguna Verde.\n'
        || 'Día 4: valle de las Rocas y regreso a Uyuni.',
        'Transporte en 4x4, alojamiento en refugios, pensión completa, '
        || 'guía conductor y entradas.',
        'Bolsas de dormir y propinas.'
    )
) AS v(codigo, nombre, destino, origen, tipo_recorrido, descripcion,
       duracion, precio, itinerario, detalle, excluidos)
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO paquete_servicio (id_paquete, id_servicio)
SELECT p.id_paquete, s.id_servicio
FROM (VALUES
    ('SAL-2026-001', 'transporte'),
    ('SAL-2026-001', 'alojamiento'),
    ('SAL-2026-001', 'almuerzo'),
    ('SAL-2026-001', 'guia'),
    ('SAL-2026-001', 'entradas'),
    ('CER-2026-001', 'transporte'),
    ('CER-2026-001', 'almuerzo'),
    ('CER-2026-001', 'guia'),
    ('CER-2026-001', 'entradas'),
    ('LCO-2026-001', 'transporte'),
    ('LCO-2026-001', 'alojamiento'),
    ('LCO-2026-001', 'desayuno'),
    ('LCO-2026-001', 'almuerzo'),
    ('LCO-2026-001', 'cena'),
    ('LCO-2026-001', 'guia'),
    ('LCO-2026-001', 'entradas')
) AS v(codigo, servicio)
JOIN paquete p ON p.codigo = v.codigo
JOIN servicio s ON s.codigo = v.servicio
ON CONFLICT DO NOTHING;

-- Con los servicios vinculados, los paquetes se publican: el disparador
-- de publicación vuelve a validar el contenido mínimo.
UPDATE paquete SET estado = 'activo'
WHERE codigo IN ('SAL-2026-001', 'CER-2026-001', 'LCO-2026-001');

INSERT INTO paquete_proveedor (id_paquete, id_proveedor, servicio, detalle, costo)
SELECT p.id_paquete, pr.id_proveedor, v.servicio, v.detalle, v.costo
FROM (VALUES
    ('SAL-2026-001', 'Transporte Andes S.R.L.',  'transporte', 'Bus turístico Potosí–Uyuni',   180.00),
    ('SAL-2026-001', 'Hotel Jardines de Uyuni',  'hospedaje',  'Una noche con desayuno',       220.00),
    ('SAL-2026-001', 'Guías del Salar',          'guia',       'Guía de salar, dos jornadas',  260.00),
    ('CER-2026-001', 'Guías de Cerro Rico',      'guia',       'Visita guiada a la mina',       90.00),
    ('CER-2026-001', 'Hostal Potosí',            'alimentacion', 'Almuerzos del recorrido',     60.00),
    ('LCO-2026-001', '4x4 Altiplano Tours',      'transporte', 'Vehículo 4x4 con conductor',   900.00),
    ('LCO-2026-001', 'Guías del Salar',          'guia',       'Guía conductor del circuito',  350.00)
) AS v(codigo, proveedor, servicio, detalle, costo)
JOIN paquete p ON p.codigo = v.codigo
JOIN proveedor pr ON lower(btrim(pr.nombre)) = lower(btrim(v.proveedor))
ON CONFLICT (id_paquete, id_proveedor) DO NOTHING;

-- ---------------------------------------------------------------------
-- 4. Salidas programadas
-- ---------------------------------------------------------------------
--  Se crean con `fn_crear_salida` para que queden auditadas y con su
--  retorno derivado de la duración del paquete.

SELECT fn_crear_salida(
    p.id_paquete, v.desde, v.hasta, v.cupo, v.precio,
    (SELECT id FROM usuario WHERE email = 'erick.vel@vizcacha.tours'),
    v.punto
)
FROM (VALUES
    ('SAL-2026-001', DATE '2026-12-04', DATE '2026-12-06', 16, 1250.00,
     'Oficina Vizcacha Tours, calle Ayacucho 145, Potosí'),
    ('SAL-2026-001', DATE '2026-12-18', DATE '2026-12-20', 14, 1250.00,
     'Oficina Vizcacha Tours, calle Ayacucho 145, Potosí'),
    ('CER-2026-001', DATE '2026-11-28', DATE '2026-11-29', 12, 480.00,
     'Plaza 10 de Noviembre, frente a la Casa de la Moneda'),
    ('LCO-2026-001', DATE '2027-01-08', DATE '2027-01-11', 10, 1950.00,
     'Terminal de buses de Uyuni')
) AS v(codigo, desde, hasta, cupo, precio, punto)
JOIN paquete p ON p.codigo = v.codigo
WHERE NOT EXISTS (
    SELECT 1 FROM salida s
    WHERE s.id_paquete = p.id_paquete AND s.fecha_salida = v.desde
);

-- ---------------------------------------------------------------------
-- 5. Reservas y pagos de demostración
-- ---------------------------------------------------------------------
--  Tres reservas: una solicitud web con anticipo registrado (para probar
--  la validación del personal), una confirmada con pago completo y una
--  solicitud de oficina sin pagos. Todas quedan auditadas.

DO $$
DECLARE
    v_maria      BIGINT;
    v_juan       BIGINT;
    v_colegio    BIGINT;
    v_usuario    TEXT;
    v_salada1    BIGINT;
    v_salada2    BIGINT;
    v_cerro      BIGINT;
    v_id_reserva BIGINT;
BEGIN
    -- La carga es idempotente: si la primera reserva ya existe, el resto
    -- de este bloque ya se ejecutó.
    IF EXISTS (
        SELECT 1 FROM reserva r
        JOIN cliente c ON c.id_cliente = r.id_cliente
        WHERE c.numero_documento = '4455667 PBO'
    ) THEN
        RETURN;
    END IF;

    SELECT id_cliente INTO v_maria FROM cliente
    WHERE numero_documento = '4455667 PBO';
    SELECT id_cliente INTO v_juan FROM cliente
    WHERE numero_documento = '6677889 PBO';
    SELECT id_cliente INTO v_colegio FROM cliente
    WHERE numero_documento = '102345678';
    SELECT id INTO v_usuario FROM usuario
    WHERE email = 'erick.vel@vizcacha.tours';

    SELECT id_salida INTO v_salada1 FROM salida s
    JOIN paquete p ON p.id_paquete = s.id_paquete
    WHERE p.codigo = 'SAL-2026-001' AND s.fecha_salida = DATE '2026-12-04';
    SELECT id_salida INTO v_salada2 FROM salida s
    JOIN paquete p ON p.id_paquete = s.id_paquete
    WHERE p.codigo = 'SAL-2026-001' AND s.fecha_salida = DATE '2026-12-18';
    SELECT id_salida INTO v_cerro FROM salida s
    JOIN paquete p ON p.id_paquete = s.id_paquete
    WHERE p.codigo = 'CER-2026-001' AND s.fecha_salida = DATE '2026-11-28';

    -- A) Solicitud web de María: 2 pasajeros, anticipo registrado por QR.
    v_id_reserva := fn_crear_reserva(
        v_maria, v_salada1, 2, 'web', 'cli-maria-rojas-01'
    );
    PERFORM fn_registrar_pago(
        v_id_reserva, 'anticipo', 750.00, 'qr', 'cli-maria-rojas-01',
        'MOCK-QR-8F3K2L', 'Pago simulado por banca móvil (QR).', false
    );

    -- B) Reserva de oficina de Juan: un pasajero (él mismo), paga el
    --    total en efectivo (anticipo por el monto completo) y queda
    --    confirmada. El manifiesto se llena antes de confirmar
    --    (RN-RES-19).
    v_id_reserva := fn_crear_reserva(
        v_juan, v_cerro, 1, 'personal', v_usuario
    );
    PERFORM fn_registrar_pago(
        v_id_reserva, 'anticipo', 480.00, 'efectivo', v_usuario,
        NULL, 'Pago completo en la oficina.', true
    );
    PERFORM fn_guardar_manifiesto(
        v_id_reserva,
        jsonb_build_array(jsonb_build_object(
            'tipo_documento', 'CI',
            'numero_documento', '6677889 PBO',
            'nombres', 'Juan Carlos',
            'apellidos', 'Flores Mendoza'
        )),
        v_usuario
    );
    PERFORM fn_confirmar_reserva(v_id_reserva, v_usuario);

    -- C) Solicitud de oficina del colegio: 8 pasajeros, sin pagos aún.
    v_id_reserva := fn_crear_reserva(
        v_colegio, v_salada2, 8, 'personal', v_usuario
    );
END;
$$;

-- ---------------------------------------------------------------------
-- 6. Una cotización enviada
-- ---------------------------------------------------------------------

INSERT INTO cotizacion (
    numero, id_cliente, id_salida, id_usuario,
    cantidad_pasajeros, precio_unitario, descuento, estado,
    fecha_emision, fecha_validez, condiciones, observaciones
)
SELECT
    'COT-2026-001',
    (SELECT id_cliente FROM cliente WHERE numero_documento = '102345678'),
    s.id_salida,
    (SELECT id FROM usuario WHERE email = 'erick.vel@vizcacha.tours'),
    10, 1950.00, 1950.00, 'enviada',
    CURRENT_DATE, CURRENT_DATE + 14,
    'Descuento por grupo del 10%. El precio incluye el pensión completa '
    || 'y el transporte en 4x4 desde Uyuni.',
    'Cotización preparada para el viaje de estudios.'
FROM salida s
JOIN paquete p ON p.id_paquete = s.id_paquete
WHERE p.codigo = 'LCO-2026-001' AND s.fecha_salida = DATE '2027-01-08'
ON CONFLICT (numero) DO NOTHING;
