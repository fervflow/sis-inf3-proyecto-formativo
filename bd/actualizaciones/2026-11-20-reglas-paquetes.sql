-- =====================================================================
--  2026-11-20 · Reglas de paquetes, actividades y salidas
--
--  Aplica sobre una base creada con `bd/esquema.sql` las reglas del
--  catálogo `sistema/reglas-negocio.md`:
--
--  1. Destino del paquete y contenido mínimo para publicar.
--  2. Catálogo de actividades del itinerario y su vínculo con el paquete.
--  3. Código del paquete en mayúsculas y precio mayor que cero.
--  4. Precio de salida mayor que cero y una salida por paquete y fecha.
--  5. Rol `CLIENTE` en lugar de `TURISTA`.
--  6. Funciones `fn_crear_salida` y `fn_actualizar_salida`.
--
--  Uso:
--    psql "$DATABASE_URL_UNPOOLED" -f bd/actualizaciones/2026-11-20-reglas-paquetes.sql
--
--  Es idempotente: se puede ejecutar más de una vez. Las restricciones
--  nuevas sobre datos existentes se agregan como NOT VALID para no romper
--  una base con filas antiguas; las filas nuevas y las modificadas sí se
--  validan. Revisar los avisos al final.
--
--  Si el modelo de lugares (`2026-11-20-lugares-servicios.sql`) ya está
--  aplicado, las secciones 1 a 3 se omiten: el destino es una referencia
--  y los servicios reemplazaron a las actividades.
-- =====================================================================

SET search_path TO turismo, public;

-- ---------------------------------------------------------------------
-- 1. Destino del paquete
-- ---------------------------------------------------------------------

-- Si el modelo de lugares ya está aplicado, el destino es una referencia
-- y esta columna no debe volver a crearse.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'turismo'
          AND table_name = 'paquete'
          AND column_name = 'id_lugar_destino'
    ) THEN
        ALTER TABLE turismo.paquete
            ADD COLUMN IF NOT EXISTS destino VARCHAR(150);
    END IF;
END $$;

ALTER TABLE turismo.paquete
    ADD COLUMN IF NOT EXISTS id_usuario_actualizacion TEXT
        REFERENCES turismo.usuario(id) ON DELETE SET NULL;

-- ---------------------------------------------------------------------
-- 2. Catálogo de actividades del itinerario
-- ---------------------------------------------------------------------

DO $$
BEGIN
    IF to_regclass('turismo.servicio') IS NULL THEN
        CREATE TABLE IF NOT EXISTS turismo.actividad (
            id_actividad        SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            codigo              VARCHAR(30) NOT NULL UNIQUE,
            nombre              VARCHAR(80) NOT NULL,
            orden               SMALLINT NOT NULL DEFAULT 0,
            activo              BOOLEAN NOT NULL DEFAULT true,
            CONSTRAINT ck_actividad_codigo CHECK (codigo = lower(codigo))
        );

        CREATE TABLE IF NOT EXISTS turismo.paquete_actividad (
            id_paquete          BIGINT NOT NULL
                REFERENCES turismo.paquete(id_paquete) ON DELETE CASCADE,
            id_actividad        SMALLINT NOT NULL
                REFERENCES turismo.actividad(id_actividad) ON DELETE RESTRICT,
            PRIMARY KEY (id_paquete, id_actividad)
        );

        INSERT INTO turismo.actividad (codigo, nombre, orden) VALUES
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
    END IF;
END $$;

-- ---------------------------------------------------------------------
-- 3. Restricciones del paquete
-- ---------------------------------------------------------------------

ALTER TABLE turismo.paquete
    DROP CONSTRAINT IF EXISTS ck_paquete_codigo;
ALTER TABLE turismo.paquete
    ADD CONSTRAINT ck_paquete_codigo
    CHECK (codigo = upper(codigo)) NOT VALID;

ALTER TABLE turismo.paquete
    DROP CONSTRAINT IF EXISTS ck_paquete_precio;
ALTER TABLE turismo.paquete
    ADD CONSTRAINT ck_paquete_precio
    CHECK (precio_base > 0) NOT VALID;

-- El modelo de lugares reemplaza esta restricción por el disparador
-- diferido `tr_paquete_publicado`. Solo se aplica sobre el modelo viejo.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'turismo'
          AND table_name = 'paquete'
          AND column_name = 'servicios_incluidos'
    ) THEN
        ALTER TABLE turismo.paquete
            DROP CONSTRAINT IF EXISTS ck_paquete_publicado;
        ALTER TABLE turismo.paquete
            ADD CONSTRAINT ck_paquete_publicado CHECK (
                estado <> 'activo'
                OR (
                    destino IS NOT NULL AND btrim(destino) <> ''
                    AND descripcion IS NOT NULL AND btrim(descripcion) <> ''
                    AND itinerario IS NOT NULL AND btrim(itinerario) <> ''
                    AND servicios_incluidos IS NOT NULL AND btrim(servicios_incluidos) <> ''
                )
            ) NOT VALID;

        -- Un paquete activo que no cumple el contenido mínimo deja de
        -- ofrecerse: pasa a borrador para que se complete.
        UPDATE turismo.paquete
        SET estado = 'borrador'
        WHERE estado = 'activo'
          AND (
              destino IS NULL OR btrim(destino) = ''
              OR descripcion IS NULL OR btrim(descripcion) = ''
              OR itinerario IS NULL OR btrim(itinerario) = ''
              OR servicios_incluidos IS NULL OR btrim(servicios_incluidos) = ''
          );
    END IF;
END $$;

-- ---------------------------------------------------------------------
-- 4. Restricciones de la salida
-- ---------------------------------------------------------------------

ALTER TABLE turismo.salida
    DROP CONSTRAINT IF EXISTS ck_salida_precio;
ALTER TABLE turismo.salida
    ADD CONSTRAINT ck_salida_precio
    CHECK (precio > 0) NOT VALID;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM turismo.salida
        GROUP BY id_paquete, fecha_salida
        HAVING count(*) > 1
    ) THEN
        RAISE NOTICE 'Hay salidas duplicadas por paquete y fecha: no se creó ux_salida_paquete_fecha. Límpielas y vuelva a ejecutar.';
    ELSE
        CREATE UNIQUE INDEX IF NOT EXISTS ux_salida_paquete_fecha
            ON turismo.salida (id_paquete, fecha_salida);
    END IF;
END;
$$;

-- ---------------------------------------------------------------------
-- 5. Rol CLIENTE
-- ---------------------------------------------------------------------

DO $$
DECLARE
    v_turista SMALLINT;
    v_cliente SMALLINT;
BEGIN
    SELECT id_rol INTO v_turista FROM turismo.rol WHERE codigo = 'TURISTA';
    SELECT id_rol INTO v_cliente FROM turismo.rol WHERE codigo = 'CLIENTE';

    ALTER TABLE turismo.rol DROP CONSTRAINT IF EXISTS ck_rol_codigo;

    IF v_turista IS NOT NULL AND v_cliente IS NOT NULL THEN
        -- Caso raro: ya existen los dos roles. Se conserva CLIENTE y se
        -- reasignan las cuentas antes de retirar TURISTA.
        UPDATE turismo.usuario
        SET id_rol = v_cliente
        WHERE id_rol = v_turista;
        DELETE FROM turismo.rol WHERE id_rol = v_turista;
    ELSIF v_turista IS NOT NULL THEN
        UPDATE turismo.rol
        SET codigo = 'CLIENTE',
            nombre = 'Cliente',
            descripcion = 'Consulta la disponibilidad, solicita reservas, registra pagos y sigue sus reservas.'
        WHERE id_rol = v_turista;
    END IF;

    ALTER TABLE turismo.rol
        ADD CONSTRAINT ck_rol_codigo
        CHECK (codigo IN ('ADMIN', 'PERSONAL', 'CLIENTE'));
END;
$$;

-- ---------------------------------------------------------------------
-- 6. Informe de filas existentes que no cumplen las reglas nuevas
-- ---------------------------------------------------------------------

DO $$
DECLARE
    v_paquetes INT;
    v_precios INT;
    v_codigos INT;
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'turismo'
          AND table_name = 'paquete'
          AND column_name = 'servicios_incluidos'
    ) THEN
        SELECT count(*) INTO v_paquetes
        FROM turismo.paquete
        WHERE estado = 'activo'
          AND (
              destino IS NULL OR btrim(destino) = ''
              OR descripcion IS NULL OR btrim(descripcion) = ''
              OR itinerario IS NULL OR btrim(itinerario) = ''
              OR servicios_incluidos IS NULL OR btrim(servicios_incluidos) = ''
          );
    ELSE
        v_paquetes := 0;
    END IF;

    SELECT count(*) INTO v_precios
    FROM turismo.paquete
    WHERE precio_base <= 0;

    SELECT count(*) INTO v_codigos
    FROM turismo.paquete
    WHERE codigo <> upper(codigo);

    IF v_paquetes > 0 THEN
        RAISE NOTICE 'Paquetes activos sin contenido mínimo: %. Edítelos o páselos a borrador antes de volver a publicarlos.', v_paquetes;
    END IF;
    IF v_precios > 0 THEN
        RAISE NOTICE 'Paquetes con precio menor o igual a cero: %. Corríjalos antes de modificarlos.', v_precios;
    END IF;
    IF v_codigos > 0 THEN
        RAISE NOTICE 'Paquetes con código en minúsculas: %. Corríjalos antes de modificarlos.', v_codigos;
    END IF;
END;
$$;

-- ---------------------------------------------------------------------
-- 7. Funciones de salidas
-- ---------------------------------------------------------------------

-- La versión anterior tenía siete argumentos y no auditaba punto de
-- encuentro ni estado. Se retira para no dejar dos sobrecargas ambiguas.
DROP FUNCTION IF EXISTS turismo.fn_actualizar_salida(
    BIGINT, TEXT, DATE, DATE, INTEGER, NUMERIC, VARCHAR
);

CREATE OR REPLACE FUNCTION fn_crear_salida(
    p_id_paquete       BIGINT,
    p_fecha_salida     DATE,
    p_fecha_retorno    DATE,
    p_cupo_maximo      INTEGER,
    p_precio           NUMERIC,
    p_id_usuario       TEXT,
    p_punto_encuentro  VARCHAR DEFAULT NULL,
    p_observaciones    TEXT DEFAULT NULL
) RETURNS BIGINT
SET search_path = turismo, public
AS $$
DECLARE
    v_estado_paquete VARCHAR(15);
    v_duracion       SMALLINT;
    v_id_salida      BIGINT;
BEGIN
    SELECT p.estado, p.duracion_dias
    INTO v_estado_paquete, v_duracion
    FROM paquete p
    WHERE p.id_paquete = p_id_paquete;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El paquete % no existe', p_id_paquete
            USING ERRCODE = 'no_data_found';
    END IF;

    IF v_estado_paquete <> 'activo' THEN
        RAISE EXCEPTION 'Solo un paquete activo admite salidas; el estado actual es «%»',
            v_estado_paquete USING ERRCODE = 'check_violation';
    END IF;

    IF p_fecha_salida IS NULL OR p_fecha_retorno IS NULL THEN
        RAISE EXCEPTION 'La salida y el retorno son obligatorios'
            USING ERRCODE = 'check_violation';
    END IF;

    IF p_fecha_salida < CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha de salida no puede ser anterior a hoy'
            USING ERRCODE = 'check_violation';
    END IF;

    IF p_fecha_retorno < p_fecha_salida THEN
        RAISE EXCEPTION 'La fecha de retorno no puede ser anterior a la de salida'
            USING ERRCODE = 'check_violation';
    END IF;

    IF (p_fecha_retorno - p_fecha_salida + 1) <> v_duracion THEN
        RAISE EXCEPTION 'La salida dura % días, pero el paquete declara %',
            (p_fecha_retorno - p_fecha_salida + 1), v_duracion
            USING ERRCODE = 'check_violation';
    END IF;

    IF p_cupo_maximo IS NULL OR p_cupo_maximo <= 0 THEN
        RAISE EXCEPTION 'La capacidad debe ser mayor que cero'
            USING ERRCODE = 'check_violation';
    END IF;

    IF p_precio IS NULL OR p_precio <= 0 THEN
        RAISE EXCEPTION 'El precio debe ser mayor que cero'
            USING ERRCODE = 'check_violation';
    END IF;

    IF EXISTS (
        SELECT 1 FROM salida s
        WHERE s.id_paquete = p_id_paquete
          AND s.fecha_salida = p_fecha_salida
    ) THEN
        RAISE EXCEPTION 'El paquete ya tiene una salida el %', p_fecha_salida
            USING ERRCODE = 'unique_violation';
    END IF;

    INSERT INTO salida (
        id_paquete, fecha_salida, fecha_retorno, cupo_maximo, precio,
        punto_encuentro, estado, observaciones, id_usuario
    ) VALUES (
        p_id_paquete, p_fecha_salida, p_fecha_retorno, p_cupo_maximo, p_precio,
        NULLIF(btrim(p_punto_encuentro), ''), 'programada',
        NULLIF(btrim(p_observaciones), ''), p_id_usuario
    )
    RETURNING id_salida INTO v_id_salida;

    INSERT INTO historial_salida (
        id_salida, campo_modificado, valor_anterior, valor_nuevo, motivo, id_usuario
    ) VALUES (
        v_id_salida, 'estado', NULL, 'programada', 'Salida creada.', p_id_usuario
    );

    RETURN v_id_salida;
END;
$$ LANGUAGE plpgsql;

-- Cambio de fecha, capacidad, precio, punto de encuentro o estado de una
-- salida (HU-09). Bloquea la salida, impide bajar la capacidad por debajo
-- de los pasajeros ya reservados y audita cada campo modificado.
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

    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- ---------------------------------------------------------------------
-- 8. Vista de disponibilidad con el estado del paquete
--
--    La recreación es condicional: si la base ya tiene una versión más
--    nueva de la vista (con más columnas), Postgres rechazaría una
--    recreación que baste columnas («cannot drop columns from view»).
-- ---------------------------------------------------------------------

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.views
        WHERE table_schema = 'turismo'
          AND table_name = 'vista_disponibilidad_salida'
    )
    AND NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'turismo'
          AND table_name = 'vista_disponibilidad_salida'
          AND column_name = 'cupo_disponible_sin_pendientes'
    ) THEN
        DROP VIEW vista_disponibilidad_salida;
        CREATE VIEW vista_disponibilidad_salida AS
        SELECT
            s.id_salida,
            s.id_paquete,
            p.codigo AS codigo_paquete,
            p.nombre AS paquete,
            s.fecha_salida,
            s.fecha_retorno,
            s.cupo_maximo,
            COALESCE(SUM(r.cantidad_pasajeros)
                FILTER (WHERE r.estado IN ('pendiente', 'confirmada')
                          AND (r.estado <> 'pendiente'
                               OR r.fecha_expiracion IS NULL
                               OR r.fecha_expiracion > now())), 0)::INT AS pasajeros_ocupados,
            COALESCE(SUM(r.cantidad_pasajeros)
                FILTER (WHERE r.estado = 'pendiente'
                          AND (r.fecha_expiracion IS NULL OR r.fecha_expiracion > now())), 0)::INT AS pasajeros_pendientes,
            COALESCE(SUM(r.cantidad_pasajeros)
                FILTER (WHERE r.estado = 'confirmada'), 0)::INT AS pasajeros_confirmados,
            (s.cupo_maximo - COALESCE(SUM(r.cantidad_pasajeros)
                FILTER (WHERE r.estado IN ('pendiente', 'confirmada')
                          AND (r.estado <> 'pendiente'
                               OR r.fecha_expiracion IS NULL
                               OR r.fecha_expiracion > now())), 0))::INT AS cupo_disponible,
            (s.cupo_maximo - COALESCE(SUM(r.cantidad_pasajeros)
                FILTER (WHERE r.estado = 'confirmada'), 0))::INT AS cupo_disponible_sin_pendientes,
            s.precio,
            s.estado,
            p.estado AS estado_paquete
        FROM salida s
        JOIN paquete p ON p.id_paquete = s.id_paquete
        LEFT JOIN reserva r ON r.id_salida = s.id_salida
        GROUP BY s.id_salida, s.id_paquete, p.codigo, p.nombre, p.estado,
                 s.fecha_salida, s.fecha_retorno, s.cupo_maximo, s.precio, s.estado;
    END IF;
END
$$;
