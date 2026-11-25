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
    estado
)
SELECT 'PRB-04', 'Completo', id_lugar, 'Descripción', 3, 100, 'borrador'
FROM turismo.lugar
WHERE codigo = 'POT';

INSERT INTO turismo.paquete_itinerario (id_paquete, dia, titulo, detalle)
SELECT p.id_paquete, v.dia, v.titulo, v.detalle
FROM turismo.paquete p
JOIN (VALUES
    (1, 'Día uno de prueba', 'Salida temprana.'),
    (2, 'Día dos de prueba', 'Visita al atractivo.'),
    (3, 'Día tres de prueba', 'Retorno.')
) AS v(dia, titulo, detalle) ON true
WHERE p.codigo = 'PRB-04'
ON CONFLICT (id_paquete, dia) DO NOTHING;

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
INSERT INTO turismo.cliente (tipo_documento, numero_documento, nombres, apellidos, correo)
VALUES ('CI', '99999999', 'Cliente', 'Prueba', 'prueba999@prueba.bo');

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

-- 13. Código de la salida (RN-SAL-22): se deriva del código del paquete
--     con un ordinal por paquete, distingue las salidas de un mismo
--     paquete y no se edita después.
DO $$
DECLARE
    v_paquete  BIGINT;
    v_primera  BIGINT;
    v_segunda  BIGINT;
    v_codigo_a VARCHAR(30);
    v_codigo_b VARCHAR(30);
    v_ordinal  INT;
BEGIN
    -- El paquete de pruebas ya trae una salida del test 5; es la
    -- primera en el tiempo y lleva el ordinal 001.
    SELECT id_paquete INTO v_paquete
    FROM paquete WHERE codigo = 'PRB-04';

    SELECT id_salida, codigo INTO v_primera, v_codigo_a
    FROM salida
    WHERE id_paquete = v_paquete
    ORDER BY fecha_salida, id_salida
    LIMIT 1;

    IF right(v_codigo_a, 3) <> '001' THEN
        RAISE EXCEPTION 'FALLO: la primera salida no terminó en 001 (%)', v_codigo_a;
    END IF;

    -- La salida nueva lleva el ordinal siguiente del paquete.
    SELECT count(*) INTO v_ordinal
    FROM salida WHERE id_paquete = v_paquete;

    v_segunda := fn_crear_salida(
        v_paquete,
        CURRENT_DATE + 60,
        CURRENT_DATE + 62,
        10,
        100,
        'u-prueba'
    );

    SELECT codigo INTO v_codigo_b FROM salida WHERE id_salida = v_segunda;

    IF right(v_codigo_b, 3) <> lpad((v_ordinal + 1)::TEXT, 3, '0')
       OR v_codigo_b = v_codigo_a THEN
        RAISE EXCEPTION 'FALLO: la salida nueva no llevó el ordinal siguiente (% / %)',
            v_codigo_a, v_codigo_b;
    END IF;

    -- El código no se edita: cambiar la salida no la renombra.
    PERFORM fn_actualizar_salida(
        v_segunda, 'u-prueba',
        p_capacidad => 12,
        p_motivo => 'Ajuste de cupo.'
    );

    SELECT codigo INTO v_codigo_b FROM salida WHERE id_salida = v_segunda;
    IF right(v_codigo_b, 3) <> lpad((v_ordinal + 1)::TEXT, 3, '0') THEN
        RAISE EXCEPTION 'FALLO: la edición cambió el código de la salida (%)', v_codigo_b;
    END IF;

    RAISE NOTICE 'OK: las salidas llevan código propio con ordinal por paquete';
END;
$$;

-- 14. Itinerario por días (RN-PAQ-18): un paquete activo necesita al
--     menos un día, y los días se renumeran al reemplazar la lista.
DO $$
DECLARE
    v_paquete   BIGINT;
    v_salida    BIGINT;
    v_dias      INT;
BEGIN
    INSERT INTO paquete (codigo, nombre, id_lugar_destino, descripcion,
                         duracion_dias, precio_base, estado)
    VALUES ('FIT', 'Paquete de prueba de itinerario',
            (SELECT id_lugar FROM lugar WHERE codigo = 'POT'),
            'Dos días de prueba.', 2, 100, 'borrador')
    RETURNING id_paquete INTO v_paquete;

    INSERT INTO paquete_servicio (id_paquete, id_servicio)
    SELECT v_paquete, id_servicio FROM servicio LIMIT 1;

    -- Publicar sin itinerario se rechaza (disparador diferido).
    BEGIN
        UPDATE paquete SET estado = 'activo' WHERE id_paquete = v_paquete;
        RAISE EXCEPTION 'FALLO: se publicó un paquete sin itinerario';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: publicar sin itinerario se rechaza';
    END;

    -- Con al menos un día, la publicación procede.
    INSERT INTO paquete_itinerario (id_paquete, dia, titulo, detalle)
    VALUES (v_paquete, 1, 'Día de prueba', 'Caminata por la ciudad.'),
           (v_paquete, 2, 'Día de museos', 'Casa de la Moneda.');
    UPDATE paquete SET estado = 'activo' WHERE id_paquete = v_paquete;

    SELECT count(*) INTO v_dias FROM paquete_itinerario
    WHERE id_paquete = v_paquete;
    IF v_dias <> 2 THEN
        RAISE EXCEPTION 'FALLO: el itinerario quedó incompleto (%)', v_dias;
    END IF;

    -- Una salida del paquete publicado se crea sin problema.
    v_salida := fn_crear_salida(
        v_paquete, CURRENT_DATE + 20, CURRENT_DATE + 21, 10, 100, 'u-prueba',
        'Punto de prueba'
    );
    IF v_salida IS NULL THEN
        RAISE EXCEPTION 'FALLO: la salida del paquete con itinerario no se creó';
    END IF;

    RAISE NOTICE 'OK: el itinerario por días respalda la publicación (RN-PAQ-18)';
END;
$$;

-- 15. Detalles por servicio del proveedor (RN-PRV-08): la FK compuesta
--     solo acepta tipos declarados, y retirar el tipo los lleva.
DO $$
DECLARE
    v_proveedor BIGINT;
    v_detalles  INT;
BEGIN
    INSERT INTO proveedor (nombre, telefono)
    VALUES ('Proveedores de Prueba S.R.L.', '+591 70000099')
    RETURNING id_proveedor INTO v_proveedor;

    INSERT INTO proveedor_tipo (id_proveedor, tipo)
    VALUES (v_proveedor, 'guia');

    BEGIN
        INSERT INTO proveedor_servicio (id_proveedor, tipo, titulo, detalle, orden)
        VALUES (v_proveedor, 'transporte', 'Detalle sin tipo declarado', NULL, 10);
        RAISE EXCEPTION 'FALLO: se aceptó un detalle de un tipo no declarado';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'OK: el detalle exige un tipo declarado (RN-PRV-08)';
    END;

    INSERT INTO proveedor_servicio (id_proveedor, tipo, titulo, detalle, orden)
    VALUES (v_proveedor, 'guia', 'Guía de prueba', 'Idiomas y certificación.', 10);

    BEGIN
        INSERT INTO proveedor_servicio (id_proveedor, tipo, titulo)
        VALUES (v_proveedor, 'guia', '   ');
        RAISE EXCEPTION 'FALLO: se aceptó un detalle sin título';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: el detalle necesita título';
    END;

    DELETE FROM proveedor_tipo WHERE id_proveedor = v_proveedor AND tipo = 'guia';

    SELECT count(*) INTO v_detalles
    FROM proveedor_servicio WHERE id_proveedor = v_proveedor;
    IF v_detalles <> 0 THEN
        RAISE EXCEPTION 'FALLO: retirar el tipo dejó detalles huérfanos (%)', v_detalles;
    END IF;

    RAISE NOTICE 'OK: los detalles siguen al tipo declarado que los respalda';
END;
$$;

-- 16. Asignaciones operativas de la salida (RN-SAL-23): solo proveedores
--     activos con el tipo declarado, y siguen a la salida que las guarda.
DO $$
DECLARE
    v_proveedor BIGINT;
    v_paquete   BIGINT;
    v_salida    BIGINT;
    v_asignadas INT;
BEGIN
    INSERT INTO proveedor (nombre, telefono)
    VALUES ('Guías de Prueba del Salar', '+591 70000098')
    RETURNING id_proveedor INTO v_proveedor;

    INSERT INTO proveedor_tipo (id_proveedor, tipo)
    VALUES (v_proveedor, 'guia');

    INSERT INTO paquete (codigo, nombre, id_lugar_destino, descripcion,
                         duracion_dias, precio_base, estado)
    VALUES ('FIS', 'Salidas de prueba con asignaciones',
            (SELECT id_lugar FROM lugar WHERE codigo = 'POT'),
            'Un día de prueba.', 1, 100, 'borrador')
    RETURNING id_paquete INTO v_paquete;

    INSERT INTO paquete_itinerario (id_paquete, dia, titulo)
    VALUES (v_paquete, 1, 'Día único de prueba');
    INSERT INTO paquete_servicio (id_paquete, id_servicio)
    SELECT v_paquete, id_servicio FROM servicio LIMIT 1;

    UPDATE paquete SET estado = 'activo' WHERE id_paquete = v_paquete;

    v_salida := fn_crear_salida(
        v_paquete, CURRENT_DATE + 30, CURRENT_DATE + 30, 10, 100, 'u-prueba',
        'Punto de prueba'
    );

    BEGIN
        INSERT INTO salida_proveedor (id_salida, id_proveedor, servicio)
        VALUES (v_salida, v_proveedor, 'transporte');
        RAISE EXCEPTION 'FALLO: se aceptó una asignación de un tipo no declarado';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'OK: la asignación exige un tipo declarado (RN-SAL-23)';
    END;

    INSERT INTO salida_proveedor (id_salida, id_proveedor, servicio, detalle)
    VALUES (v_salida, v_proveedor, 'guia', 'Guía titular de la salida de prueba');

    SELECT count(*) INTO v_asignadas
    FROM salida_proveedor WHERE id_salida = v_salida;
    IF v_asignadas <> 1 THEN
        RAISE EXCEPTION 'FALLO: la asignación no quedó guardada';
    END IF;

    RAISE NOTICE 'OK: la salida guarda sus asignaciones operativas';
END;
$$;

ROLLBACK;
