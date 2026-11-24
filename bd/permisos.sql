-- =====================================================================
--  permisos.sql
--  Permisos del rol de la aplicación sobre el esquema `turismo`.
--
--  Uso:
--    psql "$DATABASE_URL_UNPOOLED" -f bd/permisos.sql
--
--  El esquema se crea con el dueño de la base (neondb_owner); la
--  aplicación se conecta con un rol de menos privilegios (`vizcacha_app`,
--  lector y escritor). Este script se ejecuta después de crear o
--  actualizar el esquema. Es idempotente y no hace nada si el rol no
--  existe (por ejemplo, en una base local sin ese rol).
-- =====================================================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'vizcacha_app') THEN
        GRANT USAGE ON SCHEMA turismo TO vizcacha_app;

        GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA turismo
            TO vizcacha_app;

        GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA turismo
            TO vizcacha_app;

        -- Las tablas y secuencias que se creen después heredan los
        -- permisos, siempre que los cree el dueño de la base.
        ALTER DEFAULT PRIVILEGES IN SCHEMA turismo
            GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO vizcacha_app;
        ALTER DEFAULT PRIVILEGES IN SCHEMA turismo
            GRANT USAGE, SELECT ON SEQUENCES TO vizcacha_app;

        RAISE NOTICE 'Permisos concedidos a vizcacha_app';
    ELSE
        RAISE NOTICE 'No existe el rol vizcacha_app: sin permisos que conceder';
    END IF;
END;
$$;
