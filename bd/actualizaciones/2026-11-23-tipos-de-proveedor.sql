-- =====================================================================
--  Migración: un proveedor declara uno o varios tipos de servicio
--  (RN-PRV-02) y el vínculo con el paquete usa uno de los declarados
--  (RN-PRV-06), con detalle opcional.
--
--  Idempotente: puede repetirse sin dañar los datos.
--  Ejecutar con la conexión directa (DATABASE_URL_UNPOOLED).
-- =====================================================================

SET search_path TO turismo, public;

-- 1. La tabla de tipos declarados.
CREATE TABLE IF NOT EXISTS proveedor_tipo (
    id_proveedor BIGINT NOT NULL REFERENCES proveedor(id_proveedor) ON DELETE CASCADE,
    tipo         VARCHAR(20) NOT NULL,
    PRIMARY KEY (id_proveedor, tipo),
    CONSTRAINT ck_proveedor_tipo CHECK (tipo IN ('transporte', 'hospedaje', 'guia', 'alimentacion', 'otro'))
);

-- 2. El detalle opcional del vínculo, antes de mapear los servicios.
ALTER TABLE paquete_proveedor ADD COLUMN IF NOT EXISTS detalle VARCHAR(200);

-- 3. Si aún existe la columna `proveedor.tipo`, se copia cada proveedor a
--    la tabla nueva, se mapean los servicios libres de los vínculos al
--    tipo del proveedor (el texto libre queda en `detalle`) y se elimina
--    la columna.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'turismo' AND table_name = 'proveedor'
          AND column_name = 'tipo'
    ) THEN
        INSERT INTO proveedor_tipo (id_proveedor, tipo)
        SELECT id_proveedor, tipo FROM proveedor
        ON CONFLICT DO NOTHING;

        UPDATE paquete_proveedor pp
        SET servicio = pt.tipo,
            detalle = pp.servicio
        FROM proveedor_tipo pt
        WHERE pt.id_proveedor = pp.id_proveedor
          AND pp.servicio NOT IN (
              SELECT pt2.tipo FROM proveedor_tipo pt2 WHERE pt2.id_proveedor = pp.id_proveedor
          );

        ALTER TABLE proveedor DROP CONSTRAINT IF EXISTS ck_proveedor_tipo;
        ALTER TABLE proveedor DROP COLUMN tipo;
    END IF;
END;
$$;

-- 4. El servicio pasa a guardar el tipo declarado y la FK compuesta lo
--    exige: el vínculo solo puede usar un tipo declarado del proveedor.
ALTER TABLE paquete_proveedor ALTER COLUMN servicio TYPE VARCHAR(20);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint c
        JOIN pg_class t ON t.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE c.conname = 'fk_paquete_proveedor_servicio'
          AND n.nspname = 'turismo'
    ) THEN
        ALTER TABLE paquete_proveedor
            ADD CONSTRAINT fk_paquete_proveedor_servicio
            FOREIGN KEY (id_proveedor, servicio)
            REFERENCES proveedor_tipo (id_proveedor, tipo);
    END IF;
END;
$$;
