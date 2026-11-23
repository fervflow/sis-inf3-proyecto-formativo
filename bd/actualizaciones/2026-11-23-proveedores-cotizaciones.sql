-- =====================================================================
--  2026-11-23 · Proveedores, cotizaciones y datos de ejemplo
--
--  Aplica sobre una base creada con `bd/esquema.sql`:
--
--  1. Nombre único del proveedor y semilla de proveedores, clientes y
--     vínculos de ejemplo.
--  2. Columna `condiciones` de la cotización.
--  3. Número automático de cotización y barrido de vencidas.
--  4. Una cotización de ejemplo si ya hay una salida disponible.
--
--  Uso:
--    psql "$DATABASE_URL_UNPOOLED" -f bd/actualizaciones/2026-11-23-proveedores-cotizaciones.sql
--
--  Es idempotente: se puede ejecutar más de una vez.
-- =====================================================================

SET search_path TO turismo, public;

-- ---------------------------------------------------------------------
-- 1. Proveedores
-- ---------------------------------------------------------------------

CREATE UNIQUE INDEX IF NOT EXISTS ux_proveedor_nombre
    ON proveedor (lower(btrim(nombre)));

INSERT INTO cliente (
    tipo_documento, numero_documento, nombres, apellidos, correo, telefono
) VALUES
    ('CI', '12345678', 'Ana',  'Quispe', 'ana.quispe@example.com',  '+591 70000011'),
    ('CI', '87654321', 'Luis', 'Mamani', 'luis.mamani@example.com', '+591 70000012')
ON CONFLICT (tipo_documento, numero_documento) DO NOTHING;

INSERT INTO proveedor (nombre, tipo, nit, telefono, correo, direccion) VALUES
    ('Transporte Andes S.R.L.', 'transporte', '3025561008', '+591 70000001', 'contacto@transporteandes.bo', 'Potosí, Bolivia'),
    ('Hostal Potosí',           'hospedaje',  NULL,         '+591 70000002', 'reservas@hostalpotosi.bo',   'Potosí, Bolivia'),
    ('Guías del Salar',         'guia',       NULL,         '+591 70000003', 'guias@salar.bo',             'Uyuni, Bolivia')
ON CONFLICT (lower(btrim(nombre))) DO NOTHING;

INSERT INTO paquete_proveedor (id_paquete, id_proveedor, servicio, costo)
SELECT p.id_paquete, pr.id_proveedor, v.servicio, v.costo
FROM (
    VALUES
        ('POT-001',      'Transporte Andes S.R.L.', 'Traslado ida y vuelta',      140.00),
        ('POT-001',      'Hostal Potosí',           'Alojamiento 4 noches',       300.00),
        ('POT-001',      'Guías del Salar',         'Guía local',                 100.00),
        ('SAL-2026-002', 'Transporte Andes S.R.L.', 'Bus Potosí–Uyuni',           200.00),
        ('SAL-2026-002', 'Hostal Potosí',           'Alojamiento 3 noches',       250.00),
        ('SUC-2026-001', 'Transporte Andes S.R.L.', 'Traslado Potosí–Sucre',      120.00)
) AS v(codigo, proveedor, servicio, costo)
JOIN paquete p ON p.codigo = v.codigo
JOIN proveedor pr ON lower(btrim(pr.nombre)) = lower(btrim(v.proveedor))
ON CONFLICT (id_paquete, id_proveedor) DO NOTHING;

-- ---------------------------------------------------------------------
-- 2. Cotizaciones
-- ---------------------------------------------------------------------

ALTER TABLE cotizacion
    ADD COLUMN IF NOT EXISTS condiciones TEXT;

CREATE SEQUENCE IF NOT EXISTS seq_cotizacion_codigo;

CREATE OR REPLACE FUNCTION fn_generar_codigo_cotizacion()
RETURNS TEXT
SET search_path = turismo, public
AS $$
    SELECT 'COT-' || to_char(current_date, 'YYYY')
        || '-' || lpad(nextval('seq_cotizacion_codigo')::TEXT, 3, '0');
$$ LANGUAGE sql;

-- Marca como vencidas las cotizaciones cuyo plazo ya pasó. Se llama al
-- consultar la lista; no reserva cupos ni crea reservas.
CREATE OR REPLACE FUNCTION fn_vencer_cotizaciones()
RETURNS INTEGER
SET search_path = turismo, public
AS $$
DECLARE
    v_vencidas INTEGER;
BEGIN
    UPDATE cotizacion
    SET estado = 'vencida'
    WHERE estado IN ('borrador', 'enviada')
      AND fecha_validez < CURRENT_DATE;

    GET DIAGNOSTICS v_vencidas = ROW_COUNT;
    RETURN v_vencidas;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 3. Cotización de ejemplo
-- ---------------------------------------------------------------------

DO $$
DECLARE
    v_id_cliente BIGINT;
    v_id_salida  BIGINT;
    v_id_usuario TEXT;
    v_precio     NUMERIC;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM cotizacion) THEN
        SELECT id_cliente INTO v_id_cliente
        FROM cliente
        WHERE tipo_documento = 'CI' AND numero_documento = '12345678';

        SELECT s.id_salida, s.precio
        INTO v_id_salida, v_precio
        FROM salida s
        JOIN paquete p ON p.id_paquete = s.id_paquete
        WHERE p.estado = 'activo'
          AND s.estado IN ('programada', 'confirmada')
          AND s.fecha_salida >= CURRENT_DATE
        ORDER BY s.precio DESC, s.fecha_salida
        LIMIT 1;

        SELECT u.id INTO v_id_usuario
        FROM usuario u
        JOIN rol r ON r.id_rol = u.id_rol
        WHERE r.codigo = 'ADMIN' AND u.estado = 'activo'
        ORDER BY u.created_at
        LIMIT 1;

        IF v_id_cliente IS NOT NULL
           AND v_id_salida IS NOT NULL
           AND v_id_usuario IS NOT NULL THEN
            INSERT INTO cotizacion (
                numero, id_cliente, id_salida, id_usuario, cantidad_pasajeros,
                precio_unitario, descuento, estado, fecha_emision, fecha_validez,
                condiciones, observaciones
            ) VALUES (
                fn_generar_codigo_cotizacion(), v_id_cliente, v_id_salida,
                v_id_usuario, 2, v_precio, 0, 'borrador', CURRENT_DATE,
                CURRENT_DATE + 15,
                'Incluye transporte, alojamiento y guía. No incluye bebidas ni propinas.',
                'Cotización de ejemplo.'
            );
        END IF;
    END IF;
END $$;
