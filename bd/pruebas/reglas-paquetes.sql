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

INSERT INTO turismo.usuario (id, name, email, id_rol, nombres, apellidos)
VALUES ('u-prueba', 'Prueba', 'prueba@vizcacha.tours', 1, 'Prueba', 'Prueba')
ON CONFLICT (id) DO NOTHING;

-- 1. Un paquete activo sin destino, descripción, itinerario o servicios
--    no se puede guardar.
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

-- 4. Un paquete completo sí se guarda.
INSERT INTO turismo.paquete (
    codigo, nombre, destino, descripcion, duracion_dias, precio_base,
    itinerario, servicios_incluidos, estado
) VALUES (
    'PRB-04', 'Completo', 'Potosí', 'Descripción', 3, 100,
    'Día 1, día 2 y día 3', 'Transporte y guía', 'activo'
);

-- 5. Una salida válida se crea.
SELECT turismo.fn_crear_salida(
    (SELECT id_paquete FROM turismo.paquete WHERE codigo = 'PRB-04'),
    CURRENT_DATE + 10,
    CURRENT_DATE + 12,
    10, 150::numeric, 'u-prueba', 'Plaza principal', 'Prueba'
);

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
            (SELECT id_salida FROM turismo.salida WHERE fecha_salida = CURRENT_DATE + 10),
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
    (SELECT id_salida FROM turismo.salida WHERE fecha_salida = CURRENT_DATE + 10),
    'u-prueba', NULL, NULL, NULL, NULL, NULL, NULL, 'confirmada'
);

-- 11. Una salida realizada no se modifica.
SELECT turismo.fn_actualizar_salida(
    (SELECT id_salida FROM turismo.salida WHERE fecha_salida = CURRENT_DATE + 10),
    'u-prueba', NULL, NULL, NULL, NULL, NULL, NULL, 'realizada'
);

DO $$
BEGIN
    BEGIN
        PERFORM turismo.fn_actualizar_salida(
            (SELECT id_salida FROM turismo.salida WHERE fecha_salida = CURRENT_DATE + 10),
            'u-prueba', NULL, NULL, 20, NULL, 'Cambio tardío', NULL, NULL
        );
        RAISE EXCEPTION 'FALLO: se modificó una salida realizada';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: salida realizada no modificable';
    END;
END;
$$;

ROLLBACK;
