-- =====================================================================
--  2026-11-20 · Lugares, recorrido y servicios del paquete
--
--  Aplica sobre una base creada con `bd/esquema.sql` el modelo que
--  separa el destino (un lugar) del recorrido y los servicios incluidos
--  del texto del itinerario:
--
--  1. Catálogo `lugar`, con coordenadas opcionales.
--  2. `paquete.id_lugar_destino`, `id_lugar_origen` y `tipo_recorrido`.
--  3. `paquete_parada`, ordenada y sin lugares repetidos.
--  4. `servicio` y `paquete_servicio` en lugar de `actividad` y
--     `paquete_actividad`.
--  5. `servicios_detalle` y `servicios_excluidos` en lugar de
--     `servicios_incluidos`.
--  6. Código de paquete generado con una secuencia.
--  7. Publicación validada por un disparador diferido.
--
--  Uso:
--    psql "$DATABASE_URL_UNPOOLED" -f bd/actualizaciones/2026-11-20-lugares-servicios.sql
--
--  Es idempotente: se puede ejecutar más de una vez. Conserva los datos:
--  el destino de cada paquete se convierte en un lugar, los servicios
--  marcados se mantienen y el texto de `servicios_incluidos` pasa a
--  `servicios_detalle`.
-- =====================================================================

SET search_path TO turismo, public;

-- ---------------------------------------------------------------------
-- 1. Catálogo de lugares
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS lugar (
    id_lugar            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo              VARCHAR(6) NOT NULL UNIQUE,
    nombre              VARCHAR(150) NOT NULL,
    tipo                VARCHAR(20) NOT NULL DEFAULT 'otro',
    direccion           VARCHAR(200),
    latitud             NUMERIC(9, 6),
    longitud            NUMERIC(9, 6),
    osm_tipo            VARCHAR(2),
    osm_id              BIGINT,
    activo              BOOLEAN NOT NULL DEFAULT true,
    CONSTRAINT ck_lugar_codigo CHECK (codigo = upper(codigo)),
    CONSTRAINT ck_lugar_tipo CHECK (tipo IN ('ciudad', 'atractivo', 'terminal', 'hospedaje', 'otro')),
    CONSTRAINT ck_lugar_coordenadas CHECK (
        (latitud IS NULL AND longitud IS NULL)
        OR (latitud BETWEEN -90 AND 90 AND longitud BETWEEN -180 AND 180)
    )
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_lugar_nombre
    ON lugar (lower(btrim(nombre)));

CREATE UNIQUE INDEX IF NOT EXISTS ux_lugar_osm
    ON lugar (osm_tipo, osm_id)
    WHERE osm_id IS NOT NULL;

-- ---------------------------------------------------------------------
-- 2. Columnas nuevas del paquete
-- ---------------------------------------------------------------------

ALTER TABLE paquete
    ADD COLUMN IF NOT EXISTS id_lugar_destino BIGINT
        REFERENCES lugar(id_lugar) ON DELETE RESTRICT;

ALTER TABLE paquete
    ADD COLUMN IF NOT EXISTS id_lugar_origen BIGINT
        REFERENCES lugar(id_lugar) ON DELETE RESTRICT;

ALTER TABLE paquete
    ADD COLUMN IF NOT EXISTS tipo_recorrido VARCHAR(15) NOT NULL DEFAULT 'sencillo';

ALTER TABLE paquete
    ADD COLUMN IF NOT EXISTS servicios_detalle TEXT;

ALTER TABLE paquete
    ADD COLUMN IF NOT EXISTS servicios_excluidos TEXT;

-- La restricción anterior exige columnas que van a desaparecer.
ALTER TABLE paquete
    DROP CONSTRAINT IF EXISTS ck_paquete_publicado;

ALTER TABLE paquete
    DROP CONSTRAINT IF EXISTS ck_paquete_tipo_recorrido;

ALTER TABLE paquete
    ADD CONSTRAINT ck_paquete_tipo_recorrido
        CHECK (tipo_recorrido IN ('sencillo', 'circuito'));

ALTER TABLE paquete
    DROP CONSTRAINT IF EXISTS ck_paquete_circuito;

ALTER TABLE paquete
    ADD CONSTRAINT ck_paquete_circuito
        CHECK (tipo_recorrido <> 'circuito' OR id_lugar_origen IS NOT NULL);

ALTER TABLE paquete
    DROP CONSTRAINT IF EXISTS ck_paquete_duracion;

ALTER TABLE paquete
    ADD CONSTRAINT ck_paquete_duracion
        CHECK (duracion_dias > 0 AND duracion_dias <= 365);

-- ---------------------------------------------------------------------
-- 3. El destino de texto se convierte en un lugar
-- ---------------------------------------------------------------------

DO $$
DECLARE
    r        RECORD;
    v_id     BIGINT;
    v_base   TEXT;
    v_codigo TEXT;
    v_n      INTEGER;
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'turismo'
          AND table_name = 'paquete'
          AND column_name = 'destino'
    ) THEN
        FOR r IN
            SELECT DISTINCT btrim(destino) AS nombre
            FROM paquete
            WHERE destino IS NOT NULL AND btrim(destino) <> ''
            ORDER BY 1
        LOOP
        SELECT id_lugar INTO v_id
        FROM lugar
        WHERE lower(btrim(nombre)) = lower(r.nombre)
        LIMIT 1;

        IF v_id IS NULL THEN
            v_base := upper(substr(
                regexp_replace(
                    translate(r.nombre,
                        'áéíóúüñÁÉÍÓÚÜÑ',
                        'aeiouunAEIOUUN'),
                    '[^A-Za-z0-9]', '', 'g'),
                1, 3));

            IF length(v_base) < 3 THEN
                v_base := rpad(v_base, 3, 'X');
            END IF;

            v_codigo := v_base;
            v_n := 1;
            WHILE EXISTS (SELECT 1 FROM lugar WHERE codigo = v_codigo) LOOP
                v_n := v_n + 1;
                v_codigo := v_base || v_n::TEXT;
            END LOOP;

            INSERT INTO lugar (codigo, nombre, tipo)
            VALUES (v_codigo, r.nombre, 'otro')
            RETURNING id_lugar INTO v_id;
        END IF;

            UPDATE paquete p
            SET id_lugar_destino = v_id
            WHERE lower(btrim(p.destino)) = lower(r.nombre)
              AND p.id_lugar_destino IS NULL;
        END LOOP;
    END IF;
END $$;

-- ---------------------------------------------------------------------
-- 4. El texto de servicios incluidos pasa a ser detalle
-- ---------------------------------------------------------------------

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'turismo'
          AND table_name = 'paquete'
          AND column_name = 'servicios_incluidos'
    ) THEN
        UPDATE paquete
        SET servicios_detalle = servicios_incluidos
        WHERE servicios_detalle IS NULL;

        ALTER TABLE paquete DROP COLUMN servicios_incluidos;
    END IF;
END $$;

ALTER TABLE paquete DROP COLUMN IF EXISTS destino;

-- ---------------------------------------------------------------------
-- 5. De actividades a servicios
-- ---------------------------------------------------------------------

DO $$
BEGIN
    IF to_regclass('turismo.actividad') IS NOT NULL
       AND to_regclass('turismo.servicio') IS NULL THEN
        ALTER TABLE actividad RENAME TO servicio;
        ALTER TABLE servicio RENAME COLUMN id_actividad TO id_servicio;
        ALTER TABLE servicio RENAME CONSTRAINT actividad_pkey TO servicio_pkey;
        ALTER TABLE servicio RENAME CONSTRAINT ck_actividad_codigo TO ck_servicio_codigo;

        IF to_regclass('turismo.actividad_id_actividad_seq') IS NOT NULL THEN
            ALTER SEQUENCE actividad_id_actividad_seq
                RENAME TO servicio_id_servicio_seq;
        END IF;
    END IF;

    IF to_regclass('turismo.paquete_actividad') IS NOT NULL
       AND to_regclass('turismo.paquete_servicio') IS NULL THEN
        ALTER TABLE paquete_actividad RENAME TO paquete_servicio;
        ALTER TABLE paquete_servicio RENAME COLUMN id_actividad TO id_servicio;
        ALTER TABLE paquete_servicio
            RENAME CONSTRAINT paquete_actividad_pkey TO paquete_servicio_pkey;
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS servicio (
    id_servicio         SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo              VARCHAR(30) NOT NULL UNIQUE,
    nombre              VARCHAR(80) NOT NULL,
    orden               SMALLINT NOT NULL DEFAULT 0,
    activo              BOOLEAN NOT NULL DEFAULT true,
    CONSTRAINT ck_servicio_codigo CHECK (codigo = lower(codigo))
);

CREATE TABLE IF NOT EXISTS paquete_servicio (
    id_paquete          BIGINT NOT NULL REFERENCES paquete(id_paquete) ON DELETE CASCADE,
    id_servicio         SMALLINT NOT NULL REFERENCES servicio(id_servicio) ON DELETE RESTRICT,
    PRIMARY KEY (id_paquete, id_servicio)
);

-- Los nombres de las restricciones acompañan al renombre de la tabla.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'actividad_codigo_key'
          AND conrelid = 'turismo.servicio'::regclass
    ) THEN
        ALTER TABLE turismo.servicio
            RENAME CONSTRAINT actividad_codigo_key TO servicio_codigo_key;
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'paquete_actividad_id_paquete_fkey'
          AND conrelid = 'turismo.paquete_servicio'::regclass
    ) THEN
        ALTER TABLE turismo.paquete_servicio
            RENAME CONSTRAINT paquete_actividad_id_paquete_fkey
            TO paquete_servicio_id_paquete_fkey;
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'paquete_actividad_id_actividad_fkey'
          AND conrelid = 'turismo.paquete_servicio'::regclass
    ) THEN
        ALTER TABLE turismo.paquete_servicio
            RENAME CONSTRAINT paquete_actividad_id_actividad_fkey
            TO paquete_servicio_id_servicio_fkey;
    END IF;
END $$;

-- ---------------------------------------------------------------------
-- 6. Paradas del recorrido
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS paquete_parada (
    id_paquete          BIGINT NOT NULL REFERENCES paquete(id_paquete) ON DELETE CASCADE,
    id_lugar            BIGINT NOT NULL REFERENCES lugar(id_lugar) ON DELETE RESTRICT,
    orden               SMALLINT NOT NULL,
    PRIMARY KEY (id_paquete, orden),
    CONSTRAINT ck_paquete_parada_orden CHECK (orden > 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_paquete_parada_lugar
    ON paquete_parada (id_paquete, id_lugar);

-- ---------------------------------------------------------------------
-- 7. Código del paquete y publicación
-- ---------------------------------------------------------------------

CREATE SEQUENCE IF NOT EXISTS seq_paquete_codigo;

CREATE OR REPLACE FUNCTION fn_generar_codigo_paquete(p_prefijo TEXT)
RETURNS TEXT
SET search_path = turismo, public
AS $$
    SELECT upper(coalesce(nullif(btrim(p_prefijo), ''), 'PKG'))
        || '-' || to_char(current_date, 'YYYY')
        || '-' || lpad(nextval('seq_paquete_codigo')::TEXT, 3, '0');
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION fn_validar_paquete_publicado()
RETURNS TRIGGER
SET search_path = turismo, public
AS $$
DECLARE
    v_servicios INTEGER;
BEGIN
    IF NEW.estado <> 'activo' THEN
        RETURN NEW;
    END IF;

    IF NEW.id_lugar_destino IS NULL
       OR NEW.descripcion IS NULL OR btrim(NEW.descripcion) = ''
       OR NEW.itinerario IS NULL OR btrim(NEW.itinerario) = '' THEN
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

CREATE OR REPLACE FUNCTION fn_validar_servicios_paquete()
RETURNS TRIGGER
SET search_path = turismo, public
AS $$
DECLARE
    v_id_paquete BIGINT;
    v_estado     VARCHAR(15);
    v_servicios  INTEGER;
BEGIN
    v_id_paquete := COALESCE(NEW.id_paquete, OLD.id_paquete);

    SELECT estado INTO v_estado
    FROM paquete
    WHERE id_paquete = v_id_paquete;

    IF v_estado = 'activo' THEN
        SELECT count(*) INTO v_servicios
        FROM paquete_servicio
        WHERE id_paquete = v_id_paquete;

        IF v_servicios = 0 THEN
            RAISE EXCEPTION 'paquete_incompleto'
                USING ERRCODE = 'check_violation';
        END IF;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_paquete_publicado ON paquete;
CREATE CONSTRAINT TRIGGER tr_paquete_publicado
    AFTER INSERT OR UPDATE ON paquete
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION fn_validar_paquete_publicado();

DROP TRIGGER IF EXISTS tr_paquete_servicio_publicado ON paquete_servicio;
CREATE CONSTRAINT TRIGGER tr_paquete_servicio_publicado
    AFTER INSERT OR DELETE OR UPDATE ON paquete_servicio
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION fn_validar_servicios_paquete();

-- ---------------------------------------------------------------------
-- 8. Paquetes activos que ya no cumplen la regla
--
--    La columna `itinerario` desapareció con la actualización del
--    25/11/2026 (el itinerario pasó a la tabla `paquete_itinerario`):
--    la comprobación por texto solo se aplica si la columna existe.
-- ---------------------------------------------------------------------

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'turismo' AND table_name = 'paquete'
          AND column_name = 'itinerario'
    ) THEN
        UPDATE paquete p
        SET estado = 'borrador'
        WHERE p.estado = 'activo'
          AND (
              p.id_lugar_destino IS NULL
              OR p.descripcion IS NULL OR btrim(p.descripcion) = ''
              OR p.itinerario IS NULL OR btrim(p.itinerario) = ''
              OR NOT EXISTS (
                  SELECT 1
                  FROM paquete_servicio ps
                  WHERE ps.id_paquete = p.id_paquete
              )
          );
    ELSE
        UPDATE paquete p
        SET estado = 'borrador'
        WHERE p.estado = 'activo'
          AND (
              p.id_lugar_destino IS NULL
              OR p.descripcion IS NULL OR btrim(p.descripcion) = ''
              OR NOT EXISTS (
                  SELECT 1 FROM paquete_itinerario pi
                  WHERE pi.id_paquete = p.id_paquete
              )
              OR NOT EXISTS (
                  SELECT 1
                  FROM paquete_servicio ps
                  WHERE ps.id_paquete = p.id_paquete
              )
          );
    END IF;
END;
$$;

-- ---------------------------------------------------------------------
-- 9. Semilla de servicios
-- ---------------------------------------------------------------------

INSERT INTO servicio (codigo, nombre, orden) VALUES
    ('desayuno',                'Desayuno',                          10),
    ('almuerzo',                'Almuerzo',                          20),
    ('cena',                    'Cena',                              30),
    ('transporte',              'Transporte',                        40),
    ('alojamiento',             'Alojamiento',                       50),
    ('guia',                    'Guía',                              60),
    ('entradas',                'Entradas a sitios',                 70),
    ('traslado',                'Traslado a terminal o aeropuerto',  80),
    ('seguro',                  'Seguro de viaje',                   90),
    ('bebidas',                 'Bebidas',                          100),
    ('actividades_recreativas', 'Actividades recreativas',          110)
ON CONFLICT (codigo) DO NOTHING;

-- ---------------------------------------------------------------------
-- 10. Semilla de lugares conocidos
-- ---------------------------------------------------------------------

WITH semilla (codigo, nombre, tipo, direccion, latitud, longitud) AS (
    VALUES
        ('POT', 'Potosí',          'ciudad',    'Potosí, Bolivia',         -19.583611, -65.753056),
        ('CER', 'Cerro Rico',      'atractivo', 'Potosí, Bolivia',         -19.618000, -65.749000),
        ('UYU', 'Uyuni',           'ciudad',    'Uyuni, Bolivia',          -20.462000, -66.825000),
        ('SAL', 'Salar de Uyuni',  'atractivo', 'Potosí, Bolivia',         -20.133000, -67.489000),
        ('INC', 'Isla Incahuasi',  'atractivo', 'Salar de Uyuni, Bolivia', -20.242000, -67.625000),
        ('LCO', 'Laguna Colorada', 'atractivo', 'Potosí, Bolivia',         -22.198000, -67.780000),
        ('TUP', 'Tupiza',          'ciudad',    'Tupiza, Bolivia',         -21.443000, -65.718000),
        ('SUC', 'Sucre',           'ciudad',    'Sucre, Bolivia',          -19.033000, -65.263000),
        ('LPZ', 'La Paz',          'ciudad',    'La Paz, Bolivia',         -16.500000, -68.150000)
)
INSERT INTO lugar (codigo, nombre, tipo, direccion, latitud, longitud)
SELECT codigo, nombre, tipo, direccion, latitud, longitud
FROM semilla
ON CONFLICT DO NOTHING;

-- Completa las coordenadas de un lugar que ya existía sin ellas, como el
-- destino que la migración convirtió desde texto.
WITH semilla (codigo, nombre, tipo, direccion, latitud, longitud) AS (
    VALUES
        ('POT', 'Potosí',          'ciudad',    'Potosí, Bolivia',         -19.583611, -65.753056),
        ('CER', 'Cerro Rico',      'atractivo', 'Potosí, Bolivia',         -19.618000, -65.749000),
        ('UYU', 'Uyuni',           'ciudad',    'Uyuni, Bolivia',          -20.462000, -66.825000),
        ('SAL', 'Salar de Uyuni',  'atractivo', 'Potosí, Bolivia',         -20.133000, -67.489000),
        ('INC', 'Isla Incahuasi',  'atractivo', 'Salar de Uyuni, Bolivia', -20.242000, -67.625000),
        ('LCO', 'Laguna Colorada', 'atractivo', 'Potosí, Bolivia',         -22.198000, -67.780000),
        ('TUP', 'Tupiza',          'ciudad',    'Tupiza, Bolivia',         -21.443000, -65.718000),
        ('SUC', 'Sucre',           'ciudad',    'Sucre, Bolivia',          -19.033000, -65.263000),
        ('LPZ', 'La Paz',          'ciudad',    'La Paz, Bolivia',         -16.500000, -68.150000)
)
UPDATE lugar l
SET tipo = s.tipo,
    direccion = COALESCE(l.direccion, s.direccion),
    latitud = s.latitud,
    longitud = s.longitud
FROM semilla s
WHERE lower(btrim(l.nombre)) = lower(btrim(s.nombre))
  AND l.latitud IS NULL;
