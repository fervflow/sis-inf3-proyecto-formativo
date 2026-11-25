-- =====================================================================
--  2026-11-25-ficha-salida-detalles-proveedores.sql
--  Ficha de la salida y detalles de servicios de proveedores
--  (HU-18 y HU-19).
--
--  Cambios del catálogo de reglas:
--  - RN-PAQ-18: el itinerario pasa a la tabla `paquete_itinerario`, día
--    por día, y un paquete activo necesita al menos un día. La columna
--    de texto `paquete.itinerario` desaparece.
--  - RN-PRV-08: cada proveedor registra detalles por cada tipo de
--    servicio declarado, con título, descripción y orden.
--  - RN-SAL-23: cada salida puede tener asignaciones operativas de
--    proveedores, sin costos y sin cambiar cupo ni precio.
--
--  Nota: no hay migración de datos. El itinerario viejo era texto libre
--  y los datos de demostración se vuelven a cargar con
--  `bd/datos-prueba.sql`.
-- =====================================================================
SET search_path TO turismo, public;

-- 1. Itinerario por días (RN-PAQ-18).
CREATE TABLE IF NOT EXISTS paquete_itinerario (
    id_paquete          BIGINT NOT NULL REFERENCES paquete(id_paquete) ON DELETE CASCADE,
    dia                 SMALLINT NOT NULL,
    titulo              VARCHAR(150) NOT NULL,
    detalle             TEXT,
    PRIMARY KEY (id_paquete, dia),
    CONSTRAINT ck_paquete_itinerario_dia CHECK (dia > 0),
    CONSTRAINT ck_paquete_itinerario_titulo CHECK (btrim(titulo) <> '')
);

CREATE INDEX IF NOT EXISTS ix_paquete_itinerario
    ON paquete_itinerario (id_paquete, dia);

-- 2. Detalles por servicio del proveedor (RN-PRV-08).
CREATE TABLE IF NOT EXISTS proveedor_servicio (
    id_proveedor_servicio BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_proveedor        BIGINT NOT NULL REFERENCES proveedor(id_proveedor) ON DELETE CASCADE,
    tipo                VARCHAR(20) NOT NULL,
    titulo              VARCHAR(150) NOT NULL,
    detalle             TEXT,
    orden               SMALLINT NOT NULL DEFAULT 0,
    CONSTRAINT fk_proveedor_servicio_tipo FOREIGN KEY (id_proveedor, tipo)
        REFERENCES proveedor_tipo (id_proveedor, tipo) ON DELETE CASCADE,
    CONSTRAINT ck_proveedor_servicio_titulo CHECK (btrim(titulo) <> '')
);

CREATE INDEX IF NOT EXISTS ix_proveedor_servicio
    ON proveedor_servicio (id_proveedor, tipo, orden);

-- 3. Asignaciones operativas de la salida (RN-SAL-23).
CREATE TABLE IF NOT EXISTS salida_proveedor (
    id_salida           BIGINT NOT NULL REFERENCES salida(id_salida) ON DELETE CASCADE,
    id_proveedor        BIGINT NOT NULL REFERENCES proveedor(id_proveedor) ON DELETE RESTRICT,
    servicio            VARCHAR(20) NOT NULL,
    detalle             VARCHAR(200),
    PRIMARY KEY (id_salida, id_proveedor),
    CONSTRAINT fk_salida_proveedor_servicio FOREIGN KEY (id_proveedor, servicio)
        REFERENCES proveedor_tipo (id_proveedor, tipo)
);

-- 4. La columna de texto libre da paso a la tabla por días.
ALTER TABLE paquete DROP COLUMN IF EXISTS itinerario;

-- 5. La publicación exige al menos un día de itinerario.
CREATE OR REPLACE FUNCTION fn_validar_paquete_publicado()
RETURNS TRIGGER
SET search_path = turismo, public
AS $$
DECLARE
    v_servicios INTEGER;
    v_dias      INTEGER;
BEGIN
    IF NEW.estado <> 'activo' THEN
        RETURN NEW;
    END IF;

    IF NEW.id_lugar_destino IS NULL
       OR NEW.descripcion IS NULL OR btrim(NEW.descripcion) = '' THEN
        RAISE EXCEPTION 'paquete_incompleto'
            USING ERRCODE = 'check_violation';
    END IF;

    SELECT count(*) INTO v_dias
    FROM paquete_itinerario
    WHERE id_paquete = NEW.id_paquete;

    IF v_dias = 0 THEN
        RAISE EXCEPTION 'paquete_incompleto'
            USING ERRCODE = 'check_violation';
    END IF;

    SELECT count(*) INTO v_servicios
    FROM paquete_servicio
    WHERE id_paquete = NEW.id_paquete;

    IF v_servicios = 0 THEN
        RAISE EXCEPTION 'paquete_incompleto'
            USING ERRCODE = 'check_violation';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6. Lugares nuevos de la operación para las fichas y el mapa.
INSERT INTO lugar (codigo, nombre, tipo, direccion, latitud, longitud) VALUES
    ('MOC', 'Casa de la Moneda',         'atractivo', 'Potosí, Bolivia', -19.586200, -65.756100),
    ('TCI', 'Torre de la Compañía',      'atractivo', 'Potosí, Bolivia', -19.587500, -65.754500),
    ('SFR', 'Convento de San Francisco', 'atractivo', 'Potosí, Bolivia', -19.582100, -65.756900),
    ('TRE', 'Cementerio de trenes',      'atractivo', 'Uyuni, Bolivia',  -20.470600, -66.835300),
    ('MER', 'Mercado artesanal de Uyuni','atractivo', 'Uyuni, Bolivia',  -20.462000, -66.826000),
    ('SMN', 'Géiseres Sol de Mañana',    'atractivo', 'Potosí, Bolivia', -22.569000, -67.764000),
    ('POL', 'Termas de Polques',         'atractivo', 'Potosí, Bolivia', -22.535000, -67.723000),
    ('LGV', 'Laguna Verde',              'atractivo', 'Potosí, Bolivia', -22.816700, -67.783300),
    ('SIL', 'Desierto de Siloli',        'atractivo', 'Potosí, Bolivia', -22.380000, -67.530000),
    ('ROC', 'Valle de las Rocas',        'atractivo', 'Potosí, Bolivia', -22.299000, -67.617000)
ON CONFLICT DO NOTHING;
