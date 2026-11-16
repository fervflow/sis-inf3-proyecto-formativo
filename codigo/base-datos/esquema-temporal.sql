-- =====================================================================
--  esquema-temporal.sql
--  Sistema web de gestión de paquetes turísticos y reservas
--  UPDS · Ingeniería de Sistemas · Sistemas de Información III
--
--  Motor: PostgreSQL 14 o superior
--  Uso:
--    psql -U postgres -f esquema-temporal.sql
--
--  Esta es una primera versión de trabajo. No contiene datos reales,
--  no implementa pasarelas de pago y puede ajustarse cuando el
--  proyecto avance.
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS turismo;
SET search_path TO turismo, public;

-- Para reiniciar el esquema desde cero, descomentar y ejecutar:
-- DROP SCHEMA IF EXISTS turismo CASCADE;
-- CREATE SCHEMA turismo;

-- ---------------------------------------------------------------------
-- 1. Acceso y roles
-- ---------------------------------------------------------------------

CREATE TABLE rol (
    id_rol              SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo              VARCHAR(20) NOT NULL UNIQUE,
    nombre              VARCHAR(60) NOT NULL,
    descripcion         VARCHAR(200),
    CONSTRAINT ck_rol_codigo CHECK (codigo IN ('ADMIN', 'PERSONAL', 'TURISTA'))
);

CREATE TABLE usuario (
    id_usuario          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_rol              SMALLINT NOT NULL REFERENCES rol(id_rol) ON DELETE RESTRICT,
    nombres             VARCHAR(100) NOT NULL,
    apellidos           VARCHAR(100) NOT NULL,
    correo              VARCHAR(150) NOT NULL UNIQUE,
    contrasena_hash     TEXT NOT NULL,
    telefono            VARCHAR(30),
    estado              VARCHAR(15) NOT NULL DEFAULT 'activo',
    fecha_creacion      TIMESTAMPTZ NOT NULL DEFAULT now(),
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_usuario_estado CHECK (estado IN ('activo', 'inactivo', 'bloqueado')),
    CONSTRAINT ck_usuario_correo CHECK (correo = lower(correo))
);

-- ---------------------------------------------------------------------
-- 2. Clientes y pasajeros
-- ---------------------------------------------------------------------

CREATE TABLE cliente (
    id_cliente          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- Cuenta de turista vinculada, opcional. Un cliente puede no tener cuenta.
    id_usuario          BIGINT UNIQUE REFERENCES usuario(id_usuario) ON DELETE SET NULL,
    tipo_documento      VARCHAR(15) NOT NULL,
    numero_documento    VARCHAR(30) NOT NULL,
    nombres             VARCHAR(100) NOT NULL,
    apellidos           VARCHAR(100) NOT NULL,
    correo              VARCHAR(150),
    telefono            VARCHAR(30),
    direccion           VARCHAR(200),
    fecha_nacimiento    DATE,
    fecha_registro      TIMESTAMPTZ NOT NULL DEFAULT now(),
    estado              VARCHAR(15) NOT NULL DEFAULT 'activo',
    CONSTRAINT uq_cliente_documento UNIQUE (tipo_documento, numero_documento),
    CONSTRAINT ck_cliente_documento CHECK (tipo_documento IN ('CI', 'NIT', 'PASAPORTE', 'OTRO')),
    CONSTRAINT ck_cliente_estado CHECK (estado IN ('activo', 'inactivo')),
    CONSTRAINT ck_cliente_nacimiento CHECK (fecha_nacimiento IS NULL OR fecha_nacimiento <= CURRENT_DATE)
);

CREATE TABLE pasajero (
    id_pasajero         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cliente          BIGINT NOT NULL REFERENCES cliente(id_cliente) ON DELETE RESTRICT,
    tipo_documento      VARCHAR(15) NOT NULL,
    numero_documento    VARCHAR(30) NOT NULL,
    nombres             VARCHAR(100) NOT NULL,
    apellidos           VARCHAR(100) NOT NULL,
    fecha_nacimiento    DATE,
    nacionalidad        VARCHAR(60),
    telefono            VARCHAR(30),
    CONSTRAINT uq_pasajero_documento UNIQUE (tipo_documento, numero_documento),
    CONSTRAINT ck_pasajero_documento CHECK (tipo_documento IN ('CI', 'NIT', 'PASAPORTE', 'OTRO')),
    CONSTRAINT ck_pasajero_nacimiento CHECK (fecha_nacimiento IS NULL OR fecha_nacimiento <= CURRENT_DATE)
);

CREATE INDEX ix_pasajero_cliente ON pasajero (id_cliente);

-- ---------------------------------------------------------------------
-- 3. Proveedores y paquetes
-- ---------------------------------------------------------------------

CREATE TABLE proveedor (
    id_proveedor        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre              VARCHAR(150) NOT NULL,
    tipo                VARCHAR(20) NOT NULL,
    nit                 VARCHAR(30),
    telefono            VARCHAR(30),
    correo              VARCHAR(150),
    direccion           VARCHAR(200),
    estado              VARCHAR(15) NOT NULL DEFAULT 'activo',
    CONSTRAINT ck_proveedor_tipo CHECK (tipo IN ('transporte', 'hospedaje', 'guia', 'alimentacion', 'otro')),
    CONSTRAINT ck_proveedor_estado CHECK (estado IN ('activo', 'inactivo'))
);

CREATE TABLE paquete (
    id_paquete          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo              VARCHAR(20) NOT NULL UNIQUE,
    nombre              VARCHAR(150) NOT NULL,
    descripcion         TEXT,
    duracion_dias       SMALLINT NOT NULL,
    precio_base         NUMERIC(12, 2) NOT NULL,
    itinerario          TEXT,
    servicios_incluidos TEXT,
    estado              VARCHAR(15) NOT NULL DEFAULT 'borrador',
    id_usuario_creador  BIGINT REFERENCES usuario(id_usuario) ON DELETE SET NULL,
    fecha_creacion      TIMESTAMPTZ NOT NULL DEFAULT now(),
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_paquete_duracion CHECK (duracion_dias > 0),
    CONSTRAINT ck_paquete_precio CHECK (precio_base >= 0),
    CONSTRAINT ck_paquete_estado CHECK (estado IN ('borrador', 'activo', 'inactivo'))
);

CREATE TABLE paquete_proveedor (
    id_paquete          BIGINT NOT NULL REFERENCES paquete(id_paquete) ON DELETE CASCADE,
    id_proveedor        BIGINT NOT NULL REFERENCES proveedor(id_proveedor) ON DELETE RESTRICT,
    servicio            VARCHAR(150) NOT NULL,
    costo               NUMERIC(12, 2) NOT NULL DEFAULT 0,
    PRIMARY KEY (id_paquete, id_proveedor),
    CONSTRAINT ck_paquete_proveedor_costo CHECK (costo >= 0)
);

-- ---------------------------------------------------------------------
-- 4. Salidas programadas
-- ---------------------------------------------------------------------

CREATE TABLE salida (
    id_salida           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_paquete          BIGINT NOT NULL REFERENCES paquete(id_paquete) ON DELETE RESTRICT,
    fecha_salida        DATE NOT NULL,
    fecha_retorno       DATE NOT NULL,
    cupo_maximo         SMALLINT NOT NULL,
    precio              NUMERIC(12, 2) NOT NULL,
    punto_encuentro     VARCHAR(200),
    estado              VARCHAR(15) NOT NULL DEFAULT 'programada',
    observaciones       TEXT,
    id_usuario          BIGINT REFERENCES usuario(id_usuario) ON DELETE SET NULL,
    fecha_creacion      TIMESTAMPTZ NOT NULL DEFAULT now(),
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_salida_fechas CHECK (fecha_retorno >= fecha_salida),
    CONSTRAINT ck_salida_cupo CHECK (cupo_maximo > 0),
    CONSTRAINT ck_salida_precio CHECK (precio >= 0),
    CONSTRAINT ck_salida_estado CHECK (estado IN ('programada', 'confirmada', 'realizada', 'cancelada'))
);

CREATE INDEX ix_salida_paquete_fecha ON salida (id_paquete, fecha_salida);
CREATE INDEX ix_salida_fecha ON salida (fecha_salida);

-- ---------------------------------------------------------------------
-- 5. Cotizaciones
-- ---------------------------------------------------------------------

CREATE TABLE cotizacion (
    id_cotizacion       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    numero              VARCHAR(20) NOT NULL UNIQUE,
    id_cliente          BIGINT NOT NULL REFERENCES cliente(id_cliente) ON DELETE RESTRICT,
    id_salida           BIGINT NOT NULL REFERENCES salida(id_salida) ON DELETE RESTRICT,
    id_usuario          BIGINT NOT NULL REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
    cantidad_pasajeros  SMALLINT NOT NULL,
    precio_unitario     NUMERIC(12, 2) NOT NULL,
    subtotal            NUMERIC(12, 2) GENERATED ALWAYS AS (cantidad_pasajeros * precio_unitario) STORED,
    descuento            NUMERIC(12, 2) NOT NULL DEFAULT 0,
    total                NUMERIC(12, 2) GENERATED ALWAYS AS
                         (cantidad_pasajeros * precio_unitario - descuento) STORED,
    estado              VARCHAR(15) NOT NULL DEFAULT 'borrador',
    fecha_emision       DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_validez       DATE NOT NULL,
    observaciones       TEXT,
    fecha_creacion      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_cotizacion_cantidad CHECK (cantidad_pasajeros > 0),
    CONSTRAINT ck_cotizacion_precio CHECK (precio_unitario >= 0),
    CONSTRAINT ck_cotizacion_descuento CHECK
        (descuento >= 0 AND descuento <= cantidad_pasajeros * precio_unitario),
    CONSTRAINT ck_cotizacion_validez CHECK (fecha_validez >= fecha_emision),
    CONSTRAINT ck_cotizacion_estado CHECK
        (estado IN ('borrador', 'enviada', 'aceptada', 'rechazada', 'vencida'))
);

CREATE INDEX ix_cotizacion_cliente ON cotizacion (id_cliente);
CREATE INDEX ix_cotizacion_salida ON cotizacion (id_salida);

-- ---------------------------------------------------------------------
-- 6. Reservas
-- ---------------------------------------------------------------------

CREATE TABLE reserva (
    id_reserva          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo              VARCHAR(20) NOT NULL UNIQUE,
    id_cliente          BIGINT NOT NULL REFERENCES cliente(id_cliente) ON DELETE RESTRICT,
    id_salida           BIGINT NOT NULL REFERENCES salida(id_salida) ON DELETE RESTRICT,
    -- Vínculo opcional con una cotización aceptada.
    id_cotizacion       BIGINT UNIQUE REFERENCES cotizacion(id_cotizacion) ON DELETE SET NULL,
    id_usuario          BIGINT NOT NULL REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
    cantidad_pasajeros  SMALLINT NOT NULL,
    monto_total         NUMERIC(12, 2) NOT NULL,
    estado              VARCHAR(15) NOT NULL DEFAULT 'pendiente',
    observaciones       TEXT,
    motivo_cancelacion  VARCHAR(200),
    fecha_cancelacion   TIMESTAMPTZ,
    fecha_reserva       TIMESTAMPTZ NOT NULL DEFAULT now(),
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_reserva_cantidad CHECK (cantidad_pasajeros > 0),
    CONSTRAINT ck_reserva_monto CHECK (monto_total >= 0),
    CONSTRAINT ck_reserva_estado CHECK
        (estado IN ('pendiente', 'confirmada', 'cancelada', 'finalizada')),
    CONSTRAINT ck_reserva_cancelacion CHECK (
        (estado = 'cancelada'
            AND fecha_cancelacion IS NOT NULL
            AND motivo_cancelacion IS NOT NULL)
        OR (estado <> 'cancelada')
    )
);

CREATE INDEX ix_reserva_salida_estado ON reserva (id_salida, estado);
CREATE INDEX ix_reserva_cliente ON reserva (id_cliente);
CREATE INDEX ix_reserva_fecha ON reserva (fecha_reserva);

CREATE TABLE reserva_pasajero (
    id_reserva          BIGINT NOT NULL REFERENCES reserva(id_reserva) ON DELETE CASCADE,
    id_pasajero         BIGINT NOT NULL REFERENCES pasajero(id_pasajero) ON DELETE RESTRICT,
    PRIMARY KEY (id_reserva, id_pasajero)
);

-- ---------------------------------------------------------------------
-- 7. Pagos
--    Se permite un anticipo y un saldo por reserva. La restricción
--    UNIQUE (id_reserva, tipo) impide duplicar cualquiera de los dos.
-- ---------------------------------------------------------------------

CREATE TABLE pago (
    id_pago             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_reserva          BIGINT NOT NULL REFERENCES reserva(id_reserva) ON DELETE CASCADE,
    tipo                VARCHAR(15) NOT NULL,
    monto               NUMERIC(12, 2) NOT NULL,
    metodo              VARCHAR(20) NOT NULL,
    referencia          VARCHAR(100),
    fecha_pago          TIMESTAMPTZ NOT NULL DEFAULT now(),
    id_usuario          BIGINT NOT NULL REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
    observacion         VARCHAR(200),
    CONSTRAINT uq_pago_reserva_tipo UNIQUE (id_reserva, tipo),
    CONSTRAINT ck_pago_tipo CHECK (tipo IN ('anticipo', 'saldo')),
    CONSTRAINT ck_pago_monto CHECK (monto > 0),
    CONSTRAINT ck_pago_metodo CHECK
        (metodo IN ('efectivo', 'transferencia', 'tarjeta', 'otro'))
);

CREATE INDEX ix_pago_reserva ON pago (id_reserva);
CREATE INDEX ix_pago_fecha ON pago (fecha_pago);

-- ---------------------------------------------------------------------
-- 8. Historiales de auditoría
-- ---------------------------------------------------------------------

CREATE TABLE historial_reserva (
    id_historial        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_reserva          BIGINT NOT NULL REFERENCES reserva(id_reserva) ON DELETE CASCADE,
    estado_anterior     VARCHAR(15),
    estado_nuevo        VARCHAR(15) NOT NULL,
    fecha_cambio        TIMESTAMPTZ NOT NULL DEFAULT now(),
    id_usuario          BIGINT NOT NULL REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
    observacion         VARCHAR(200),
    CONSTRAINT ck_historial_reserva_anterior CHECK (
        estado_anterior IS NULL
        OR estado_anterior IN ('pendiente', 'confirmada', 'cancelada', 'finalizada')
    ),
    CONSTRAINT ck_historial_reserva_nuevo CHECK
        (estado_nuevo IN ('pendiente', 'confirmada', 'cancelada', 'finalizada'))
);

CREATE INDEX ix_historial_reserva ON historial_reserva (id_reserva, fecha_cambio);

CREATE TABLE historial_salida (
    id_historial        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_salida           BIGINT NOT NULL REFERENCES salida(id_salida) ON DELETE CASCADE,
    campo_modificado    VARCHAR(30) NOT NULL,
    valor_anterior      VARCHAR(100),
    valor_nuevo         VARCHAR(100),
    motivo              VARCHAR(200),
    fecha_cambio        TIMESTAMPTZ NOT NULL DEFAULT now(),
    id_usuario          BIGINT NOT NULL REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
    CONSTRAINT ck_historial_salida_campo CHECK (
        campo_modificado IN
        ('fecha_salida', 'fecha_retorno', 'cupo_maximo', 'precio', 'estado', 'punto_encuentro')
    )
);

CREATE INDEX ix_historial_salida ON historial_salida (id_salida, fecha_cambio);

-- ---------------------------------------------------------------------
-- 9. Actualización automática de la fecha de modificación
-- ---------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_actualizar_fecha_modificacion()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_usuario_actualizacion
    BEFORE UPDATE ON usuario
    FOR EACH ROW EXECUTE FUNCTION fn_actualizar_fecha_modificacion();

CREATE TRIGGER tr_paquete_actualizacion
    BEFORE UPDATE ON paquete
    FOR EACH ROW EXECUTE FUNCTION fn_actualizar_fecha_modificacion();

CREATE TRIGGER tr_salida_actualizacion
    BEFORE UPDATE ON salida
    FOR EACH ROW EXECUTE FUNCTION fn_actualizar_fecha_modificacion();

CREATE TRIGGER tr_reserva_actualizacion
    BEFORE UPDATE ON reserva
    FOR EACH ROW EXECUTE FUNCTION fn_actualizar_fecha_modificacion();

-- ---------------------------------------------------------------------
-- 10. Vistas de apoyo
-- ---------------------------------------------------------------------

-- Disponibilidad calculada: nunca se almacena un cupo duplicado.
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
        FILTER (WHERE r.estado IN ('pendiente', 'confirmada')), 0)::INT AS pasajeros_ocupados,
    (s.cupo_maximo - COALESCE(SUM(r.cantidad_pasajeros)
        FILTER (WHERE r.estado IN ('pendiente', 'confirmada')), 0))::INT AS cupo_disponible,
    s.precio,
    s.estado
FROM salida s
JOIN paquete p ON p.id_paquete = s.id_paquete
LEFT JOIN reserva r ON r.id_salida = s.id_salida
GROUP BY s.id_salida, s.id_paquete, p.codigo, p.nombre,
         s.fecha_salida, s.fecha_retorno, s.cupo_maximo, s.precio, s.estado;

-- Saldo de cada reserva a partir del anticipo y del saldo registrados.
CREATE OR REPLACE VIEW vista_saldo_reserva AS
SELECT
    r.id_reserva,
    r.codigo,
    r.id_cliente,
    r.id_salida,
    r.monto_total,
    COALESCE(MAX(pg.monto) FILTER (WHERE pg.tipo = 'anticipo'), 0) AS anticipo,
    COALESCE(MAX(pg.monto) FILTER (WHERE pg.tipo = 'saldo'), 0) AS saldo_pagado,
    COALESCE(SUM(pg.monto), 0) AS total_pagado,
    r.monto_total - COALESCE(SUM(pg.monto), 0) AS saldo_pendiente,
    r.estado
FROM reserva r
LEFT JOIN pago pg ON pg.id_reserva = r.id_reserva
GROUP BY r.id_reserva, r.codigo, r.id_cliente, r.id_salida,
         r.monto_total, r.estado;

-- Resumen de ocupación por fecha para los reportes (HU-11).
CREATE OR REPLACE VIEW vista_reservas_por_fecha AS
SELECT
    s.fecha_salida,
    s.id_salida,
    p.nombre AS paquete,
    COUNT(r.id_reserva)
        FILTER (WHERE r.estado IN ('pendiente', 'confirmada')) AS reservas_activas,
    COALESCE(SUM(r.cantidad_pasajeros)
        FILTER (WHERE r.estado IN ('pendiente', 'confirmada')), 0)::INT AS pasajeros,
    s.cupo_maximo,
    (s.cupo_maximo - COALESCE(SUM(r.cantidad_pasajeros)
        FILTER (WHERE r.estado IN ('pendiente', 'confirmada')), 0))::INT AS cupo_disponible
FROM salida s
JOIN paquete p ON p.id_paquete = s.id_paquete
LEFT JOIN reserva r ON r.id_salida = s.id_salida
GROUP BY s.fecha_salida, s.id_salida, p.nombre, s.cupo_maximo
ORDER BY s.fecha_salida;

-- ---------------------------------------------------------------------
-- 11. Semilla mínima de roles
-- ---------------------------------------------------------------------

INSERT INTO rol (codigo, nombre, descripcion) VALUES
    ('ADMIN',    'Administrador',      'Gestiona usuarios, paquetes, salidas y reportes.'),
    ('PERSONAL', 'Personal de agencia', 'Consulta, cotiza, registra reservas y pagos.'),
    ('TURISTA',  'Turista',             'Consulta disponibilidad y su información de reserva.')
ON CONFLICT (codigo) DO NOTHING;

-- =====================================================================
--  Fin del esquema temporal
-- =====================================================================
