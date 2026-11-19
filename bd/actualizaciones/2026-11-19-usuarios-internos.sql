-- =====================================================================
--  2026-11-19 · Usuarios internos con cambio obligatorio de contraseña
--
--  La base de producción ya existía cuando se agregó la gestión de
--  usuarios internos. `bd/esquema.sql` es la fuente canónica para una
--  base nueva; este archivo aplica el mismo cambio sobre una base creada.
--
--  Uso:
--    psql "$DATABASE_URL_UNPOOLED" -f bd/actualizaciones/2026-11-19-usuarios-internos.sql
--
--  Es idempotente: se puede ejecutar más de una vez.
-- =====================================================================

ALTER TABLE turismo.usuario
    ADD COLUMN IF NOT EXISTS debe_cambiar_password BOOLEAN NOT NULL DEFAULT false;
