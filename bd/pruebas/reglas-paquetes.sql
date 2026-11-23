-- =====================================================================
--  Pruebas de las reglas de paquetes y salidas
--
--  Uso:
--    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f bd/pruebas/reglas-paquetes.sql
--
--  Corre dentro de una transacción y termina con ROLLBACK: no deja datos.
--  Si una regla no se cumple, la prueba falla con una excepción.
-- =====================================================================

BEGIN;
SET search_path TO turismo, public;

INSERT INTO turismo.usuario (id, name, email, id_rol, nombres, apellidos)
VALUES ('u-prueba', 'Prueba', 'prueba@vizcacha.tours', 1, 'Prueba', 'Prueba')
ON CONFLICT (id) DO NOTHING;

-- 1. Un paquete activo sin destino, descripción, itinerario o servicios
--    no se puede guardar. El disparador de publicación es diferido: para
--    probarlo en la transacción se vuelve inmediato.
SET CONSTRAINTS tr_paquete_publicado IMMEDIATE;

DO $$
BEGIN
    BEGIN
        INSERT INTO turismo.paquete (
            codigo, nombre, duracion_dias, precio_base, estado
        ) VALUES ('PRB-01', 'Incompleto', 3, 100, 'activo');
        RAISE EXCEPTION 'FALLO: se guardó un paquete activo incompleto';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: paquete activo incompleto rechazado';
    END;
END;
$$;

-- 2. El código debe estar en mayúsculas.
DO $$
BEGIN
    BEGIN
        INSERT INTO turismo.paquete (
            codigo, nombre, duracion_dias, precio_base, estado
        ) VALUES ('prb-02', 'Minúsculas', 1, 100, 'borrador');
        RAISE EXCEPTION 'FALLO: se guardó un código en minúsculas';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: código en minúsculas rechazado';
    END;
END;
$$;

-- 3. El precio debe ser mayor que cero.
DO $$
BEGIN
    BEGIN
        INSERT INTO turismo.paquete (
            codigo, nombre, duracion_dias, precio_base, estado
        ) VALUES ('PRB-03', 'Precio cero', 1, 0, 'borrador');
        RAISE EXCEPTION 'FALLO: se guardó un paquete con precio cero';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: precio cero rechazado';
    END;
END;
$$;

-- 4. Un paquete completo sí se guarda: destino, contenido y servicios.
INSERT INTO turismo.lugar (codigo, nombre, tipo)
VALUES ('POT', 'Potosí', 'ciudad')
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO turismo.paquete (
    codigo, nombre, id_lugar_destino, descripcion, duracion_dias, precio_base,
    itinerario, estado
)
SELECT 'PRB-04', 'Completo', id_lugar, 'Descripción', 3, 100,
       'Día 1, día 2 y día 3', 'borrador'
FROM turismo.lugar
WHERE codigo = 'POT';

INSERT INTO turismo.paquete_servicio (id_paquete, id_servicio)
SELECT p.id_paquete, s.id_servicio
FROM turismo.paquete p, turismo.servicio s
WHERE p.codigo = 'PRB-04'
  AND s.codigo IN ('transporte', 'guia');

UPDATE turismo.paquete
SET estado = 'activo'
WHERE codigo = 'PRB-04';

-- 4b. Un circuito necesita un origen.
DO $$
BEGIN
    BEGIN
        INSERT INTO turismo.paquete (
            codigo, nombre, tipo_recorrido, duracion_dias, precio_base, estado
        ) VALUES ('PRB-06', 'Circuito sin origen', 'circuito', 3, 100, 'borrador');
        RAISE EXCEPTION 'FALLO: se guardó un circuito sin origen';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: circuito sin origen rechazado';
    END;
END;
$$;

-- 4c. Una parada no se repite en el mismo paquete.
DO $$
BEGIN
    BEGIN
        INSERT INTO turismo.paquete_parada (id_paquete, id_lugar, orden)
        SELECT p.id_paquete, l.id_lugar, 1
        FROM turismo.paquete p, turismo.lugar l
        WHERE p.codigo = 'PRB-04' AND l.codigo = 'POT';

        INSERT INTO turismo.paquete_parada (id_paquete, id_lugar, orden)
        SELECT p.id_paquete, l.id_lugar, 2
        FROM turismo.paquete p, turismo.lugar l
        WHERE p.codigo = 'PRB-04' AND l.codigo = 'POT';

        RAISE EXCEPTION 'FALLO: se repitió una parada';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'OK: parada repetida rechazada';
    END;
END;
$$;

-- 5. Una salida válida se crea.
SELECT turismo.fn_crear_salida(
    (SELECT id_paquete FROM turismo.paquete WHERE codigo = 'PRB-04'),
    CURRENT_DATE + 10,
    CURRENT_DATE + 12,
    10, 150::numeric, 'u-prueba', 'Plaza principal', 'Prueba'
);

-- 5b. La capacidad no baja de los pasajeros reservados y el cambio de
--     precio queda auditado.
INSERT INTO turismo.cliente (tipo_documento, numero_documento, nombres, apellidos)
VALUES ('CI', '99999999', 'Cliente', 'Prueba');

SELECT turismo.fn_crear_reserva(
    (SELECT id_cliente FROM turismo.cliente WHERE numero_documento = '99999999'),
    (SELECT s.id_salida
       FROM turismo.salida s
       JOIN turismo.paquete p ON p.id_paquete = s.id_paquete
      WHERE p.codigo = 'PRB-04'
        AND s.fecha_salida = CURRENT_DATE + 10),
    5, 'personal', 'u-prueba'
);

DO $$
BEGIN
    BEGIN
        PERFORM turismo.fn_actualizar_salida(
            (SELECT s.id_salida
               FROM turismo.salida s
               JOIN turismo.paquete p ON p.id_paquete = s.id_paquete
              WHERE p.codigo = 'PRB-04'
                AND s.fecha_salida = CURRENT_DATE + 10),
            'u-prueba', NULL, NULL, 4, NULL, 'Bajar capacidad', NULL, NULL
        );
        RAISE EXCEPTION 'FALLO: se bajó la capacidad por debajo de los reservados';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: capacidad menor que los reservados rechazada';
    END;
END;
$$;

SELECT turismo.fn_actualizar_salida(
    (SELECT s.id_salida
       FROM turismo.salida s
       JOIN turismo.paquete p ON p.id_paquete = s.id_paquete
      WHERE p.codigo = 'PRB-04'
        AND s.fecha_salida = CURRENT_DATE + 10),
    'u-prueba', NULL, NULL, NULL, 180::numeric, 'Ajuste de precio', NULL, NULL
);

DO $$
DECLARE
    v_auditoria INT;
BEGIN
    SELECT count(*) INTO v_auditoria
    FROM turismo.historial_salida h
    JOIN turismo.salida s ON s.id_salida = h.id_salida
    JOIN turismo.paquete p ON p.id_paquete = s.id_paquete
    WHERE p.codigo = 'PRB-04'
      AND s.fecha_salida = CURRENT_DATE + 10
      AND h.campo_modificado = 'precio';

    IF v_auditoria = 0 THEN
        RAISE EXCEPTION 'FALLO: no se auditó el cambio de precio';
    END IF;

    RAISE NOTICE 'OK: cambio de precio auditado';
END;
$$;

-- 6. No se repite la salida del mismo paquete el mismo día.
DO $$
BEGIN
    BEGIN
        PERFORM turismo.fn_crear_salida(
            (SELECT id_paquete FROM turismo.paquete WHERE codigo = 'PRB-04'),
            CURRENT_DATE + 10,
            CURRENT_DATE + 12,
            10, 150::numeric, 'u-prueba', NULL, NULL
        );
        RAISE EXCEPTION 'FALLO: se creó una salida duplicada';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'OK: salida duplicada rechazada';
    END;
END;
$$;

-- 7. La duración de la salida debe coincidir con la del paquete.
DO $$
BEGIN
    BEGIN
        PERFORM turismo.fn_crear_salida(
            (SELECT id_paquete FROM turismo.paquete WHERE codigo = 'PRB-04'),
            CURRENT_DATE + 20,
            CURRENT_DATE + 21,
            10, 150::numeric, 'u-prueba', NULL, NULL
        );
        RAISE EXCEPTION 'FALLO: se aceptó una duración incoherente';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: duración incoherente rechazada';
    END;
END;
$$;

-- 8. Un paquete inactivo no admite salidas.
INSERT INTO turismo.paquete (
    codigo, nombre, duracion_dias, precio_base, estado
) VALUES ('PRB-05', 'Inactivo', 2, 100, 'inactivo');

DO $$
BEGIN
    BEGIN
        PERFORM turismo.fn_crear_salida(
            (SELECT id_paquete FROM turismo.paquete WHERE codigo = 'PRB-05'),
            CURRENT_DATE + 30,
            CURRENT_DATE + 31,
            10, 150::numeric, 'u-prueba', NULL, NULL
        );
        RAISE EXCEPTION 'FALLO: se creó una salida de un paquete inactivo';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: salida de paquete inactivo rechazada';
    END;
END;
$$;

-- 9. La cancelación exige motivo.
DO $$
BEGIN
    BEGIN
        PERFORM turismo.fn_actualizar_salida(
            (SELECT s.id_salida
         FROM turismo.salida s
         JOIN turismo.paquete p ON p.id_paquete = s.id_paquete
        WHERE s.fecha_salida = CURRENT_DATE + 10
          AND p.codigo = 'PRB-04'),
            'u-prueba', NULL, NULL, NULL, NULL, NULL, NULL, 'cancelada'
        );
        RAISE EXCEPTION 'FALLO: se canceló sin motivo';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: cancelación sin motivo rechazada';
    END;
END;
$$;

-- 10. La transición programada → confirmada es válida.
SELECT turismo.fn_actualizar_salida(
    (SELECT s.id_salida
         FROM turismo.salida s
         JOIN turismo.paquete p ON p.id_paquete = s.id_paquete
        WHERE s.fecha_salida = CURRENT_DATE + 10
          AND p.codigo = 'PRB-04'),
    'u-prueba', NULL, NULL, NULL, NULL, NULL, NULL, 'confirmada'
);

-- 11. Una salida realizada no se modifica.
SELECT turismo.fn_actualizar_salida(
    (SELECT s.id_salida
         FROM turismo.salida s
         JOIN turismo.paquete p ON p.id_paquete = s.id_paquete
        WHERE s.fecha_salida = CURRENT_DATE + 10
          AND p.codigo = 'PRB-04'),
    'u-prueba', NULL, NULL, NULL, NULL, NULL, NULL, 'realizada'
);

DO $$
BEGIN
    BEGIN
        PERFORM turismo.fn_actualizar_salida(
            (SELECT s.id_salida
         FROM turismo.salida s
         JOIN turismo.paquete p ON p.id_paquete = s.id_paquete
        WHERE s.fecha_salida = CURRENT_DATE + 10
          AND p.codigo = 'PRB-04'),
            'u-prueba', NULL, NULL, 20, NULL, 'Cambio tardío', NULL, NULL
        );
        RAISE EXCEPTION 'FALLO: se modificó una salida realizada';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: salida realizada no modificable';
    END;
END;
$$;

-- 12. Un proveedor declara sus tipos y el vínculo solo usa uno de ellos.
INSERT INTO turismo.proveedor (nombre) VALUES ('PRB Transportes');
INSERT INTO turismo.proveedor_tipo (id_proveedor, tipo)
SELECT id_proveedor, 'transporte'
FROM turismo.proveedor WHERE nombre = 'PRB Transportes';

INSERT INTO turismo.paquete (codigo, nombre, duracion_dias, precio_base, estado)
VALUES ('PRB-PP', 'Paquete de proveedores', 1, 100, 'borrador');

-- 12a. Vínculo con un tipo declarado: se guarda con su detalle.
DO $$
BEGIN
    INSERT INTO turismo.paquete_proveedor (id_paquete, id_proveedor, servicio, detalle, costo)
    SELECT p.id_paquete, pr.id_proveedor, 'transporte', 'Bus de prueba', 50
    FROM turismo.paquete p, turismo.proveedor pr
    WHERE p.codigo = 'PRB-PP' AND pr.nombre = 'PRB Transportes';

    RAISE NOTICE 'OK: vínculo con un tipo declarado se guarda';
END;
$$;

-- 12b. Vínculo con un tipo que el proveedor no declaró: la FK compuesta
--      lo rechaza.
INSERT INTO turismo.proveedor (nombre) VALUES ('PRB Hospedajes');
INSERT INTO turismo.proveedor_tipo (id_proveedor, tipo)
SELECT id_proveedor, 'hospedaje'
FROM turismo.proveedor WHERE nombre = 'PRB Hospedajes';

DO $$
BEGIN
    BEGIN
        INSERT INTO turismo.paquete_proveedor (id_paquete, id_proveedor, servicio, costo)
        SELECT p.id_paquete, pr.id_proveedor, 'transporte', 10
        FROM turismo.paquete p, turismo.proveedor pr
        WHERE p.codigo = 'PRB-PP' AND pr.nombre = 'PRB Hospedajes';
        RAISE EXCEPTION 'FALLO: se vinculó un servicio no declarado';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'OK: vínculo con un servicio no declarado rechazado';
    END;
END;
$$;

-- 12c. Un proveedor sin tipos declarados no puede vincularse a nada.
INSERT INTO turismo.proveedor (nombre) VALUES ('PRB Sin Tipos');
DO $$
BEGIN
    BEGIN
        INSERT INTO turismo.paquete_proveedor (id_paquete, id_proveedor, servicio, costo)
        SELECT p.id_paquete, pr.id_proveedor, 'transporte', 10
        FROM turismo.paquete p, turismo.proveedor pr
        WHERE p.codigo = 'PRB-PP' AND pr.nombre = 'PRB Sin Tipos';
        RAISE EXCEPTION 'FALLO: se vinculó un proveedor sin tipos declarados';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'OK: proveedor sin tipos declarados no puede vincularse';
    END;
END;
$$;

ROLLBACK;
