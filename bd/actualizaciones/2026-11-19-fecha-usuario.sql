-- =====================================================================
--  2026-11-19 · Fecha de modificación de la cuenta
--
--  La tabla `usuario` es de Better Auth y usa `updated_at`; el disparador
--  que comparte con `paquete`, `salida` y `reserva` escribía en
--  `fecha_actualizacion`, que en `usuario` no existe. Cualquier `UPDATE`
--  sobre una cuenta fallaba.
--
--  Uso:
--    psql "$DATABASE_URL_UNPOOLED" -f bd/actualizaciones/2026-11-19-fecha-usuario.sql
--
--  Es idempotente: se puede ejecutar más de una vez.
-- =====================================================================

CREATE OR REPLACE FUNCTION turismo.fn_actualizar_fecha_usuario()
RETURNS TRIGGER
SET search_path = turismo, public
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_user_actualizacion ON turismo.usuario;

CREATE TRIGGER tr_user_actualizacion
    BEFORE UPDATE ON turismo.usuario
    FOR EACH ROW EXECUTE FUNCTION turismo.fn_actualizar_fecha_usuario();
