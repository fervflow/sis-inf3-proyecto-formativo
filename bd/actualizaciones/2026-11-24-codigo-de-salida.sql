-- =====================================================================
--  2026-11-24-codigo-de-salida.sql
--  Código propio de las salidas (RN-SAL-22).
--
--  Las salidas de un mismo paquete compartían el código del paquete en
--  la consulta de disponibilidad. Cada salida recibe ahora su código
--  único e inmutable, derivado del código del paquete con un ordinal
--  por paquete: PAQUETE-NNN (por ejemplo, SAL-2026-001-001 y
--  SAL-2026-001-002).
--
--  Cambios del catálogo de reglas:
--  - RN-SAL-22: el código de la salida es único, se genera al crear con
--    el código del paquete y un ordinal por paquete, y no se edita.
--    Lo asigna el disparador tr_salida_codigo y lo refleja la vista de
--    disponibilidad como codigo_salida.
-- =====================================================================
SET search_path TO turismo, public;

ALTER TABLE salida ADD COLUMN codigo VARCHAR(30);

-- Relleno de las salidas existentes: ordinal por paquete, en orden de
-- fecha de salida e identificador.
DO $$
DECLARE
    p RECORD;
    s RECORD;
    v_ordinal INT;
BEGIN
    FOR p IN SELECT id_paquete, codigo FROM paquete ORDER BY id_paquete LOOP
        v_ordinal := 0;
        FOR s IN
            SELECT id_salida FROM salida
            WHERE id_paquete = p.id_paquete
            ORDER BY fecha_salida, id_salida
        LOOP
            v_ordinal := v_ordinal + 1;
            UPDATE salida
            SET codigo = p.codigo || '-' || lpad(v_ordinal::TEXT, 3, '0')
            WHERE id_salida = s.id_salida;
        END LOOP;
    END LOOP;
END;
$$;

ALTER TABLE salida ALTER COLUMN codigo SET NOT NULL;
ALTER TABLE salida ADD CONSTRAINT uq_salida_codigo UNIQUE (codigo);

-- Asignación del código al insertar (RN-SAL-22). El bloqueo del
-- paquete serializa la asignación entre inserciones simultáneas del
-- mismo paquete.
CREATE OR REPLACE FUNCTION fn_asignar_codigo_salida()
RETURNS TRIGGER
SET search_path = turismo, public
AS $$
DECLARE
    v_codigo_paquete VARCHAR(20);
    v_ordinal        INT;
BEGIN
    IF NEW.codigo IS NULL OR NEW.codigo = '' THEN
        SELECT p.codigo INTO v_codigo_paquete
        FROM paquete p
        WHERE p.id_paquete = NEW.id_paquete
        FOR UPDATE;

        SELECT COALESCE(MAX(substring(s.codigo FROM '-(\d+)$')::INT), 0) + 1
        INTO v_ordinal
        FROM salida s
        WHERE s.id_paquete = NEW.id_paquete;

        NEW.codigo := v_codigo_paquete || '-' || lpad(v_ordinal::TEXT, 3, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_salida_codigo
    BEFORE INSERT ON salida
    FOR EACH ROW EXECUTE FUNCTION fn_asignar_codigo_salida();

-- La vista de disponibilidad expone el código de la salida; la columna
-- se añade al final porque CREATE OR REPLACE VIEW no reordena.
CREATE OR REPLACE VIEW vista_disponibilidad_salida AS
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
    p.estado AS estado_paquete,
    s.codigo AS codigo_salida
FROM salida s
JOIN paquete p ON p.id_paquete = s.id_paquete
LEFT JOIN reserva r ON r.id_salida = s.id_salida
GROUP BY s.id_salida, s.id_paquete, p.codigo, p.nombre, p.estado,
         s.fecha_salida, s.fecha_retorno, s.cupo_maximo, s.precio, s.estado;
