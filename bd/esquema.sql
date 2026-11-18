-- =====================================================================
--  esquema.sql
--  Sistema web de gestión de paquetes turísticos y reservas
--  UPDS · Ingeniería de Sistemas · Sistemas de Información III
--
--  Motor: PostgreSQL 14 o superior
--  Uso:
--    psql -U postgres -f bd/esquema.sql
--
--  Este archivo es el script de creación del esquema. La base de datos
--  todavía no existe, así que no hay migraciones: el script la crea
--  completa. No contiene datos reales y no implementa pasarelas de pago.
--
--  Dos decisiones gobiernan el diseño:
--
--  1. La identidad la gestiona Better Auth. Sus cuatro tablas (usuario,
--     session, account y verification) están adaptadas a la nomenclatura
--     de este esquema: identificador de texto y nombres en snake_case.
--     Los datos que el dominio necesita de la cuenta —rol, estado,
--     nombres, apellidos y teléfono— son campos adicionales de `usuario`.
--
--  2. Las reglas que dependen de un bloqueo de fila —validación de
--     cupos, cambio de capacidad, confirmación de una solicitud—
--     están en funciones PL/pgSQL. La aplicación las llama con una sola
--     sentencia, de modo que la atomicidad no dependa del transporte con
--     el que se conecte a la base.
--
--  Para reiniciar el esquema desde cero, descomentar y ejecutar:
--  DROP SCHEMA IF EXISTS turismo CASCADE;
--  CREATE SCHEMA turismo;
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS turismo;

SET search_path TO turismo, public;

-- ---------------------------------------------------------------------
-- 1. Acceso y roles
-- ---------------------------------------------------------------------
--  `rol` es el catálogo de roles del sistema. La tabla `usuario` es la de
--  Better Auth: la Application la crea con su propio identificador de
--  texto y su migración; aquí se declara con los campos que el dominio
--  agrega y con los índices que el resto del esquema necesita.

CREATE TABLE rol (
    id_rol              SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo              VARCHAR(20) NOT NULL UNIQUE,
    nombre              VARCHAR(60) NOT NULL,
    descripcion         VARCHAR(200),
    CONSTRAINT ck_rol_codigo CHECK (codigo IN ('ADMIN', 'PERSONAL', 'TURISTA'))
);

-- Tabla `usuario` de Better Auth, con los campos adicionales del dominio.
CREATE TABLE usuario (
    id                  TEXT PRIMARY KEY,
    name                TEXT NOT NULL,
    email               TEXT NOT NULL UNIQUE,
    email_verificado    BOOLEAN NOT NULL DEFAULT false,
    image               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- Campos adicionales del dominio.
    id_rol              SMALLINT REFERENCES rol(id_rol) ON DELETE SET NULL,
    nombres             VARCHAR(100) NOT NULL,
    apellidos           VARCHAR(100) NOT NULL,
    telefono            VARCHAR(30),
    estado              VARCHAR(15) NOT NULL DEFAULT 'activo',
    CONSTRAINT ck_user_estado CHECK (estado IN ('activo', 'inactivo', 'bloqueado')),
    CONSTRAINT ck_user_correo CHECK (email = lower(email))
);

-- Tabla `session` de Better Auth.
CREATE TABLE session (
    id                  TEXT PRIMARY KEY,
    user_id             TEXT NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
    token               TEXT NOT NULL UNIQUE,
    expires_at          TIMESTAMPTZ NOT NULL,
    ip_address          VARCHAR(45),
    user_agent          TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX ix_session_user ON session (user_id);
CREATE INDEX ix_session_expires ON session (expires_at);

-- Tabla `account` de Better Auth. La contraseña del personal y de los
-- clientes vive aquí, no en `usuario`.
CREATE TABLE account (
    id                  TEXT PRIMARY KEY,
    user_id             TEXT NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
    account_id          TEXT NOT NULL,
    provider_id         TEXT NOT NULL,
    password            TEXT,
    -- Datos de los proveedores de acceso externo. El sistema solo usa
    -- correo y contraseña, pero la biblioteca los espera en la tabla.
    access_token            TEXT,
    refresh_token           TEXT,
    id_token                TEXT,
    access_token_expires_at TIMESTAMPTZ,
    refresh_token_expires_at TIMESTAMPTZ,
    scope                   TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX ix_account_user ON account (user_id);

-- Tabla `verification` de Better Auth: verificaciones de correo y
--_tokens de un solo uso.
CREATE TABLE verification (
    id                  TEXT PRIMARY KEY,
    identifier          TEXT NOT NULL,
    value               TEXT NOT NULL,
    expires_at          TIMESTAMPTZ NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX ix_verification_identifier ON verification (identifier);

-- Registro de accesos. La trazabilidad de los ingresos la exige el
-- criterio de HU-08, que no forma parte de la sesión de Better Auth.
CREATE TABLE acceso (
    id_acceso           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario          TEXT REFERENCES usuario(id) ON DELETE SET NULL,
    fecha_hora          TIMESTAMPTZ NOT NULL DEFAULT now(),
    tipo                VARCHAR(20) NOT NULL,
    direccion_ip        VARCHAR(45),
    resultado           VARCHAR(20) NOT NULL,
    CONSTRAINT ck_acceso_tipo CHECK (tipo IN ('ingreso', 'salida', 'intento')),
    CONSTRAINT ck_acceso_resultado CHECK (resultado IN ('permitido', 'denegado'))
);

CREATE INDEX ix_acceso_usuario_fecha ON acceso (id_usuario, fecha_hora);

-- ---------------------------------------------------------------------
-- 2. Clientes y pasajeros
-- ---------------------------------------------------------------------
--  La cuenta del turista es opcional: un cliente puede no registrarse y
--  ser atendido igualmente por el personal. Por eso la vínculo es
--  opcional y admits como máximo una cuenta por ficha.

CREATE TABLE cliente (
    id_cliente          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- Cuenta de turista vinculada, opcional. Un cliente puede no tener cuenta.
    id_usuario          TEXT UNIQUE REFERENCES usuario(id) ON DELETE SET NULL,
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
    id_usuario_creador  TEXT REFERENCES usuario(id) ON DELETE SET NULL,
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
    id_usuario          TEXT REFERENCES usuario(id) ON DELETE SET NULL,
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
    id_usuario          TEXT NOT NULL REFERENCES usuario(id) ON DELETE RESTRICT,
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
--  La reserva nunca se borra: se cancela y conserva su historial. Los
--  cupos no se almacenan; se calculan en las vistas, a partir de las
--  reservas que están pendientes o confirmadas.

CREATE TABLE reserva (
    id_reserva          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo              VARCHAR(20) NOT NULL UNIQUE,
    id_cliente          BIGINT NOT NULL REFERENCES cliente(id_cliente) ON DELETE RESTRICT,
    id_salida           BIGINT NOT NULL REFERENCES salida(id_salida) ON DELETE RESTRICT,
    -- Vínculo opcional con una cotización aceptada.
    id_cotizacion       BIGINT UNIQUE REFERENCES cotizacion(id_cotizacion) ON DELETE SET NULL,
    id_usuario          TEXT NOT NULL REFERENCES usuario(id) ON DELETE RESTRICT,
    -- Canal por el que ingresa la reserva: atención del personal o
    -- solicitud directa del cliente. Ambas siguen el mismo flujo.
    origen              VARCHAR(15) NOT NULL DEFAULT 'personal',
    cantidad_pasajeros  SMALLINT NOT NULL,
    monto_total         NUMERIC(12, 2) NOT NULL,
    estado              VARCHAR(15) NOT NULL DEFAULT 'pendiente',
    -- Fecha límite para confirmar una reserva pendiente. Al vencer, la
    -- solicitud deja de ocupar cupo por sí misma (estado derivado) y el
    -- barrido diario la pasa a 'vencida' para limpiar el historial.
    fecha_expiracion    TIMESTAMPTZ DEFAULT (now() + INTERVAL '48 hours'),
    -- Marca la solicitud de cancelación del cliente. La cancelación la
    -- ejecuta el personal, de modo que el estado no cambia por sí solo.
    fecha_solicitud_cancelacion TIMESTAMPTZ,
    observaciones       TEXT,
    motivo_cancelacion  VARCHAR(200),
    fecha_cancelacion   TIMESTAMPTZ,
    fecha_reserva       TIMESTAMPTZ NOT NULL DEFAULT now(),
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_reserva_cantidad CHECK (cantidad_pasajeros > 0),
    CONSTRAINT ck_reserva_monto CHECK (monto_total >= 0),
    CONSTRAINT ck_reserva_origen CHECK (origen IN ('personal', 'web')),
    CONSTRAINT ck_reserva_estado CHECK
        (estado IN ('pendiente', 'confirmada', 'vencida', 'cancelada', 'finalizada')),
    -- Una reserva pendiente siempre tiene fecha de vencimiento.
    CONSTRAINT ck_reserva_expiracion CHECK (
        (estado = 'pendiente' AND fecha_expiracion IS NOT NULL)
        OR (estado <> 'pendiente')
    ),
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
CREATE INDEX ix_reserva_vencimiento ON reserva (fecha_expiracion)
    WHERE estado = 'pendiente';

-- Una sola solicitud activa por cliente y salida, en cualquiera de los dos
-- canales. Una segunda necesidad se gestiona modificando la solicitud
-- existente, no creando otra.
CREATE UNIQUE INDEX ux_reserva_solicitud_activa
    ON reserva (id_cliente, id_salida)
    WHERE estado = 'pendiente';

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
    id_usuario          TEXT NOT NULL REFERENCES usuario(id) ON DELETE RESTRICT,
    -- Un pago registrado por el cliente queda 'registrado' hasta que el
    -- personal lo valida. El pago no confirma la reserva por sí solo.
    estado              VARCHAR(15) NOT NULL DEFAULT 'registrado',
    id_usuario_validacion TEXT REFERENCES usuario(id) ON DELETE SET NULL,
    fecha_validacion    TIMESTAMPTZ,
    observacion         VARCHAR(200),
    CONSTRAINT uq_pago_reserva_tipo UNIQUE (id_reserva, tipo),
    CONSTRAINT ck_pago_tipo CHECK (tipo IN ('anticipo', 'saldo')),
    CONSTRAINT ck_pago_monto CHECK (monto > 0),
    CONSTRAINT ck_pago_metodo CHECK
        (metodo IN ('efectivo', 'transferencia', 'tarjeta', 'otro')),
    CONSTRAINT ck_pago_estado CHECK
        (estado IN ('registrado', 'validado', 'anulado')),
    CONSTRAINT ck_pago_validacion CHECK (
        (estado = 'validado'
            AND id_usuario_validacion IS NOT NULL
            AND fecha_validacion IS NOT NULL)
        OR (estado <> 'validado')
    )
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
    id_usuario          TEXT NOT NULL REFERENCES usuario(id) ON DELETE RESTRICT,
    observacion         VARCHAR(200),
    CONSTRAINT ck_historial_reserva_anterior CHECK (
        estado_anterior IS NULL
        OR estado_anterior IN ('pendiente', 'confirmada', 'vencida', 'cancelada', 'finalizada')
    ),
    CONSTRAINT ck_historial_reserva_nuevo CHECK
        (estado_nuevo IN ('pendiente', 'confirmada', 'vencida', 'cancelada', 'finalizada'))
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
    id_usuario          TEXT NOT NULL REFERENCES usuario(id) ON DELETE RESTRICT,
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

CREATE TRIGGER tr_user_actualizacion
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

-- El código de la reserva se deriva de su identificador, de modo que la
-- aplicación no tenga que inventarlo.
CREATE OR REPLACE FUNCTION fn_asignar_codigo_reserva()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.codigo IS NULL OR NEW.codigo = '' THEN
        NEW.codigo := 'R' || lpad(NEW.id_reserva::TEXT, 8, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_reserva_codigo
    BEFORE INSERT ON reserva
    FOR EACH ROW EXECUTE FUNCTION fn_asignar_codigo_reserva();

-- ---------------------------------------------------------------------
-- 10. Reglas de negocio en funciones
-- ---------------------------------------------------------------------
--  Las reglas que necesitan un bloqueo de fila viven aquí. La aplicación
--  las invoca con una sola sentencia: la atomicidad la garantiza la
--  transacción de la base, no el transporte con el que se conecte.

-- Creación de una reserva con validación de cupos (HU-06).
-- Bloquea la fila de la salida, de modo que dos registros simultáneos no
-- puedan superar la capacidad, y aplica la regla de una sola solicitud
-- activa por cliente y salida.
CREATE OR REPLACE FUNCTION fn_crear_reserva(
    p_id_cliente      BIGINT,
    p_id_salida       BIGINT,
    p_cantidad        INTEGER,
    p_origen          VARCHAR,
    p_id_usuario      TEXT,
    p_id_cotizacion   BIGINT DEFAULT NULL
) RETURNS BIGINT AS $$
DECLARE
    v_cupo_maximo SMALLINT;
    v_ocupados    INT;
    v_id_reserva  BIGINT;
BEGIN
    IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
        RAISE EXCEPTION 'La cantidad de pasajeros debe ser mayor que cero'
            USING ERRCODE = 'check_violation';
    END IF;

    IF p_origen IS NULL OR p_origen NOT IN ('personal', 'web') THEN
        RAISE EXCEPTION 'El canal de ingreso debe ser «personal» o «web»'
            USING ERRCODE = 'check_violation';
    END IF;

    SELECT s.cupo_maximo INTO v_cupo_maximo
    FROM salida s
    WHERE s.id_salida = p_id_salida
      AND s.estado IN ('programada', 'confirmada')
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La salida % no existe o no admite reservas', p_id_salida
            USING ERRCODE = 'no_data_found';
    END IF;

    -- Ocupación efectiva: una solicitud pendiente cuyo plazo ya venció
    -- deja de ocupar cupo, aunque su estado guardado siga siendo
    -- 'pendiente' hasta el barrido diario.
    SELECT COALESCE(SUM(r.cantidad_pasajeros), 0)::INT INTO v_ocupados
    FROM reserva r
    WHERE r.id_salida = p_id_salida
      AND r.estado IN ('pendiente', 'confirmada')
      AND (r.estado <> 'pendiente'
           OR r.fecha_expiracion IS NULL
           OR r.fecha_expiracion > now());

    IF v_cupo_maximo - v_ocupados < p_cantidad THEN
        RAISE EXCEPTION 'No hay cupo suficiente: quedan % lugares y se piden %',
            v_cupo_maximo - v_ocupados, p_cantidad
            USING ERRCODE = 'check_violation';
    END IF;

    IF EXISTS (
        SELECT 1 FROM reserva r
        WHERE r.id_cliente = p_id_cliente
          AND r.id_salida = p_id_salida
          AND r.estado = 'pendiente'
    ) THEN
        RAISE EXCEPTION 'El cliente ya tiene una solicitud pendiente para esa salida'
            USING ERRCODE = 'unique_violation';
    END IF;

    INSERT INTO reserva (
        id_cliente, id_salida, id_cotizacion, id_usuario, origen,
        cantidad_pasajeros, monto_total, estado, fecha_expiracion
    )
    SELECT p_id_cliente, p_id_salida, p_id_cotizacion, p_id_usuario, p_origen,
           p_cantidad, s.precio * p_cantidad, 'pendiente',
           now() + INTERVAL '48 hours'
    FROM salida s
    WHERE s.id_salida = p_id_salida
    RETURNING id_reserva INTO v_id_reserva;

    INSERT INTO historial_reserva (
        id_reserva, estado_anterior, estado_nuevo, id_usuario, observacion
    ) VALUES (
        v_id_reserva, NULL, 'pendiente', p_id_usuario,
        'Reserva creada por el canal ' || p_origen || '.'
    );

    RETURN v_id_reserva;
END;
$$ LANGUAGE plpgsql;

-- Confirmación de una solicitud pendiente (HU-17).
-- Limpia la fecha de vencimiento y deja el cambio auditado. Una
-- solicitud vencida no puede confirmarse: el cliente debe registrar una
-- nueva si la salida sigue disponible.
CREATE OR REPLACE FUNCTION fn_confirmar_reserva(
    p_id_reserva BIGINT,
    p_id_usuario TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    v_estado      VARCHAR(15);
    v_expiracion  TIMESTAMPTZ;
BEGIN
    SELECT r.estado, r.fecha_expiracion INTO v_estado, v_expiracion
    FROM reserva r
    WHERE r.id_reserva = p_id_reserva
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La reserva % no existe', p_id_reserva
            USING ERRCODE = 'no_data_found';
    END IF;

    IF v_estado <> 'pendiente' THEN
        RAISE EXCEPTION 'Solo una solicitud pendiente puede confirmarse; el estado actual es «%»',
            v_estado USING ERRCODE = 'check_violation';
    END IF;

    IF v_expiracion IS NOT NULL AND v_expiracion <= now() THEN
        UPDATE reserva r
        SET estado = 'vencida',
            observaciones = COALESCE(r.observaciones || ' | ', '')
                          || 'Vencida por falta de confirmación dentro del plazo previsto.'
        WHERE r.id_reserva = p_id_reserva;

        INSERT INTO historial_reserva (
            id_reserva, estado_anterior, estado_nuevo, id_usuario, observacion
        ) VALUES (
            p_id_reserva, 'pendiente', 'vencida', p_id_usuario,
            'Vencimiento al intentar confirmar fuera de plazo.'
        );

        RAISE EXCEPTION 'La solicitud % venció sin confirmarse', p_id_reserva
            USING ERRCODE = 'check_violation';
    END IF;

    UPDATE reserva
    SET estado = 'confirmada',
        fecha_expiracion = NULL
    WHERE id_reserva = p_id_reserva;

    INSERT INTO historial_reserva (
        id_reserva, estado_anterior, estado_nuevo, id_usuario, observacion
    ) VALUES (
        p_id_reserva, 'pendiente', 'confirmada', p_id_usuario,
        'Solicitud confirmada dentro del plazo previsto.'
    );

    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Cambio de fecha o capacidad de una salida (HU-09).
-- Bloquea la salida, impide bajar la capacidad por debajo de los
-- pasajeros ya reservados y deja auditado el valor anterior y el nuevo.
CREATE OR REPLACE FUNCTION fn_actualizar_salida(
    p_id_salida      BIGINT,
    p_id_usuario     TEXT,
    p_fecha_salida   DATE DEFAULT NULL,
    p_fecha_retorno  DATE DEFAULT NULL,
    p_capacidad      INTEGER DEFAULT NULL,
    p_precio         NUMERIC DEFAULT NULL,
    p_motivo         VARCHAR DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_ocupados INT;
    v_anterior RECORD;
BEGIN
    SELECT s.fecha_salida, s.fecha_retorno, s.cupo_maximo, s.precio
    INTO v_anterior
    FROM salida s
    WHERE s.id_salida = p_id_salida
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La salida % no existe', p_id_salida
            USING ERRCODE = 'no_data_found';
    END IF;

    IF p_capacidad IS NOT NULL THEN
        SELECT COALESCE(SUM(r.cantidad_pasajeros), 0)::INT INTO v_ocupados
        FROM reserva r
        WHERE r.id_salida = p_id_salida
          AND r.estado IN ('pendiente', 'confirmada')
          AND (r.estado <> 'pendiente'
               OR r.fecha_expiracion IS NULL
               OR r.fecha_expiracion > now());

        IF p_capacidad < v_ocupados THEN
            RAISE EXCEPTION 'La capacidad no puede ser menor que los % pasajeros ya reservados',
                v_ocupados USING ERRCODE = 'check_violation';
        END IF;
    END IF;

    IF p_fecha_salida IS NOT NULL
       AND p_fecha_retorno IS NOT NULL
       AND p_fecha_retorno < p_fecha_salida THEN
        RAISE EXCEPTION 'La fecha de retorno no puede ser anterior a la de salida'
            USING ERRCODE = 'check_violation';
    END IF;

    UPDATE salida s
    SET fecha_salida   = COALESCE(p_fecha_salida, s.fecha_salida),
        fecha_retorno  = COALESCE(p_fecha_retorno, s.fecha_retorno),
        cupo_maximo    = COALESCE(p_capacidad, s.cupo_maximo),
        precio         = COALESCE(p_precio, s.precio)
    WHERE s.id_salida = p_id_salida;

    IF p_fecha_salida IS NOT NULL AND p_fecha_salida <> v_anterior.fecha_salida THEN
        INSERT INTO historial_salida (
            id_salida, campo_modificado, valor_anterior, valor_nuevo, motivo, id_usuario
        ) VALUES (
            p_id_salida, 'fecha_salida', v_anterior.fecha_salida::TEXT,
            p_fecha_salida::TEXT, p_motivo, p_id_usuario
        );
    END IF;

    IF p_fecha_retorno IS NOT NULL AND p_fecha_retorno <> v_anterior.fecha_retorno THEN
        INSERT INTO historial_salida (
            id_salida, campo_modificado, valor_anterior, valor_nuevo, motivo, id_usuario
        ) VALUES (
            p_id_salida, 'fecha_retorno', v_anterior.fecha_retorno::TEXT,
            p_fecha_retorno::TEXT, p_motivo, p_id_usuario
        );
    END IF;

    IF p_capacidad IS NOT NULL AND p_capacidad <> v_anterior.cupo_maximo THEN
        INSERT INTO historial_salida (
            id_salida, campo_modificado, valor_anterior, valor_nuevo, motivo, id_usuario
        ) VALUES (
            p_id_salida, 'cupo_maximo', v_anterior.cupo_maximo::TEXT,
            p_capacidad::TEXT, p_motivo, p_id_usuario
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

    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Solicitud de cancelación del cliente (HU-13). La petición queda
-- registrada, pero el estado de la reserva no cambia: la ejecuta el
-- personal.
CREATE OR REPLACE FUNCTION fn_solicitar_cancelacion(
    p_id_reserva BIGINT,
    p_id_usuario TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    v_estado VARCHAR(15);
BEGIN
    SELECT r.estado INTO v_estado
    FROM reserva r
    WHERE r.id_reserva = p_id_reserva
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La reserva % no existe', p_id_reserva
            USING ERRCODE = 'no_data_found';
    END IF;

    IF v_estado IN ('cancelada', 'finalizada', 'vencida') THEN
        RAISE EXCEPTION 'Una reserva en estado «%» no admite cancelación', v_estado
            USING ERRCODE = 'check_violation';
    END IF;

    UPDATE reserva
    SET fecha_solicitud_cancelacion = now()
    WHERE id_reserva = p_id_reserva;

    INSERT INTO historial_reserva (
        id_reserva, estado_anterior, estado_nuevo, id_usuario, observacion
    ) VALUES (
        p_id_reserva, v_estado, v_estado, p_id_usuario,
        'El cliente solicitó la cancelación; la ejecuta el personal.'
    );

    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Ejecución de la cancelación por parte del personal. La cancelación es
-- lógica: la reserva conserva su historial y el cupo se libera por
-- cálculo, porque deja de computar en las vistas.
CREATE OR REPLACE FUNCTION fn_ejecutar_cancelacion(
    p_id_reserva BIGINT,
    p_motivo     VARCHAR,
    p_id_usuario TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    v_estado VARCHAR(15);
BEGIN
    SELECT r.estado INTO v_estado
    FROM reserva r
    WHERE r.id_reserva = p_id_reserva
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La reserva % no existe', p_id_reserva
            USING ERRCODE = 'no_data_found';
    END IF;

    IF v_estado = 'cancelada' THEN
        RAISE EXCEPTION 'La reserva % ya está cancelada', p_id_reserva
            USING ERRCODE = 'check_violation';
    END IF;

    IF v_estado = 'finalizada' THEN
        RAISE EXCEPTION 'Una reserva finalizada no puede cancelarse'
            USING ERRCODE = 'check_violation';
    END IF;

    UPDATE reserva
    SET estado = 'cancelada',
        motivo_cancelacion = p_motivo,
        fecha_cancelacion = now()
    WHERE id_reserva = p_id_reserva;

    INSERT INTO historial_reserva (
        id_reserva, estado_anterior, estado_nuevo, id_usuario, observacion
    ) VALUES (
        p_id_reserva, v_estado, 'cancelada', p_id_usuario,
        'Cancelación ejecutada por el personal: ' || COALESCE(p_motivo, 'sin motivo declarado')
    );

    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Registro de un pago (HU-14). El pago registrado por el cliente desde su
-- cuenta queda en estado 'registrado' y no cuenta como abonado hasta que
-- el personal lo valida.
CREATE OR REPLACE FUNCTION fn_registrar_pago(
    p_id_reserva  BIGINT,
    p_tipo        VARCHAR,
    p_monto       NUMERIC,
    p_metodo      VARCHAR,
    p_id_usuario  TEXT,
    p_referencia  VARCHAR DEFAULT NULL,
    p_observacion VARCHAR DEFAULT NULL
) RETURNS BIGINT AS $$
DECLARE
    v_id_pago BIGINT;
BEGIN
    INSERT INTO pago (
        id_reserva, tipo, monto, metodo, referencia, observacion,
        id_usuario, estado
    ) VALUES (
        p_id_reserva, p_tipo, p_monto, p_metodo, p_referencia, p_observacion,
        p_id_usuario, 'registrado'
    )
    RETURNING id_pago INTO v_id_pago;

    RETURN v_id_pago;
END;
$$ LANGUAGE plpgsql;

-- Validación o anulación de un pago por parte del personal. Solo los
-- pagos validados suman al total abonado.
CREATE OR REPLACE FUNCTION fn_validar_pago(
    p_id_pago    BIGINT,
    p_id_usuario TEXT,
    p_anular     BOOLEAN DEFAULT false
) RETURNS BOOLEAN AS $$
DECLARE
    v_estado VARCHAR(15);
BEGIN
    SELECT pg.estado INTO v_estado
    FROM pago pg
    WHERE pg.id_pago = p_id_pago
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El pago % no existe', p_id_pago
            USING ERRCODE = 'no_data_found';
    END IF;

    IF v_estado <> 'registrado' THEN
        RAISE EXCEPTION 'Solo un pago registrado puede validarse o anularse; el estado actual es «%»',
            v_estado USING ERRCODE = 'check_violation';
    END IF;

    IF p_anular THEN
        UPDATE pago
        SET estado = 'anulado',
            id_usuario_validacion = p_id_usuario,
            fecha_validacion = now()
        WHERE id_pago = p_id_pago;
    ELSE
        UPDATE pago
        SET estado = 'validado',
            id_usuario_validacion = p_id_usuario,
            fecha_validacion = now()
        WHERE id_pago = p_id_pago;
    END IF;

    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 11. Vencimiento de las solicitudes pendientes
-- ---------------------------------------------------------------------
--  Una reserva pendiente que no se confirma dentro del plazo previsto
--  deja de ocupar cupo en el momento en que vence, sin necesidad de
--  ningún proceso: ese cálculo está en las vistas. Esta rutina es la
--  limpieza: pasa las solicitudes vencidas a 'vencida' y deja el cambio
--  auditado. El personal puede ejecutarla una vez al día.

CREATE OR REPLACE FUNCTION fn_vencer_solicitudes_pendientes()
RETURNS INT AS $$
DECLARE
    v_vencidas INT := 0;
    r RECORD;
BEGIN
    FOR r IN
        SELECT id_reserva, id_usuario
        FROM reserva
        WHERE estado = 'pendiente'
          AND fecha_expiracion IS NOT NULL
          AND fecha_expiracion <= now()
        FOR UPDATE
    LOOP
        UPDATE reserva
        SET estado = 'vencida',
            observaciones = COALESCE(observaciones || ' | ', '')
                          || 'Vencida por falta de confirmación dentro del plazo previsto.'
        WHERE id_reserva = r.id_reserva;

        INSERT INTO historial_reserva (
            id_reserva, estado_anterior, estado_nuevo, id_usuario, observacion
        ) VALUES (
            r.id_reserva, 'pendiente', 'vencida', r.id_usuario,
            'Vencimiento automático de la solicitud pendiente.'
        );

        v_vencidas := v_vencidas + 1;
    END LOOP;

    RETURN v_vencidas;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 12. Vistas de apoyo
-- ---------------------------------------------------------------------
--  Disponibilidad calculada: nunca se almacena un cupo duplicado.
--  Las reservas vencidas no se cuentan, porque el filtro solo considera
--  las pendientes cuyo plazo no venció y las confirmadas. Así el cupo se
--  libera en el momento en que expira la solicitud, sin depender del
--  barrido diario.
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
    s.estado
FROM salida s
JOIN paquete p ON p.id_paquete = s.id_paquete
LEFT JOIN reserva r ON r.id_salida = s.id_salida
GROUP BY s.id_salida, s.id_paquete, p.codigo, p.nombre,
         s.fecha_salida, s.fecha_retorno, s.cupo_maximo, s.precio, s.estado;

-- Saldo de cada reserva a partir del anticipo y del saldo registrados.
-- El saldo pendiente se calcula sobre los pagos validados por el personal:
-- un pago solo registrado por el cliente todavía no se considera cobrado.
CREATE OR REPLACE VIEW vista_saldo_reserva AS
SELECT
    r.id_reserva,
    r.codigo,
    r.id_cliente,
    r.id_salida,
    r.monto_total,
    COALESCE(MAX(pg.monto) FILTER (WHERE pg.tipo = 'anticipo' AND pg.estado <> 'anulado'), 0) AS anticipo,
    COALESCE(MAX(pg.monto) FILTER (WHERE pg.tipo = 'saldo' AND pg.estado <> 'anulado'), 0) AS saldo_pagado,
    COALESCE(SUM(pg.monto) FILTER (WHERE pg.estado <> 'anulado'), 0) AS total_pagado,
    COALESCE(SUM(pg.monto) FILTER (WHERE pg.estado = 'validado'), 0) AS total_validado,
    r.monto_total - COALESCE(SUM(pg.monto) FILTER (WHERE pg.estado = 'validado'), 0) AS saldo_pendiente,
    r.estado
FROM reserva r
LEFT JOIN pago pg ON pg.id_reserva = r.id_reserva
GROUP BY r.id_reserva, r.codigo, r.id_cliente, r.id_salida,
         r.monto_total, r.estado;

-- Resumen de ocupación por fecha para los reportes (HU-11).
-- Las solicitudes pendientes se muestran aparte de las reservas
-- confirmadas, para que el personal distinga la ocupación comprometida de
-- la que todavía está por confirmar. Una solicitud cuyo plazo venció
-- deja de contarse como pendiente, aunque su estado guardado siga
-- siendo 'pendiente' hasta el barrido.
CREATE OR REPLACE VIEW vista_reservas_por_fecha AS
SELECT
    s.fecha_salida,
    s.id_salida,
    p.nombre AS paquete,
    COUNT(r.id_reserva)
        FILTER (WHERE r.estado = 'pendiente'
                  AND (r.fecha_expiracion IS NULL OR r.fecha_expiracion > now())) AS reservas_pendientes,
    COUNT(r.id_reserva)
        FILTER (WHERE r.estado = 'confirmada') AS reservas_confirmadas,
    COUNT(r.id_reserva)
        FILTER (WHERE r.estado IN ('pendiente', 'confirmada')
                  AND (r.estado <> 'pendiente'
                       OR r.fecha_expiracion IS NULL
                       OR r.fecha_expiracion > now())) AS reservas_activas,
    COUNT(r.id_reserva)
        FILTER (WHERE r.estado = 'vencida') AS reservas_vencidas,
    COALESCE(SUM(r.cantidad_pasajeros)
        FILTER (WHERE r.estado = 'pendiente'
                  AND (r.fecha_expiracion IS NULL OR r.fecha_expiracion > now())), 0)::INT AS pasajeros_pendientes,
    COALESCE(SUM(r.cantidad_pasajeros)
        FILTER (WHERE r.estado = 'confirmada'), 0)::INT AS pasajeros_confirmados,
    COALESCE(SUM(r.cantidad_pasajeros)
        FILTER (WHERE r.estado IN ('pendiente', 'confirmada')
                  AND (r.estado <> 'pendiente'
                       OR r.fecha_expiracion IS NULL
                       OR r.fecha_expiracion > now())), 0)::INT AS pasajeros,
    s.cupo_maximo,
    (s.cupo_maximo - COALESCE(SUM(r.cantidad_pasajeros)
        FILTER (WHERE r.estado IN ('pendiente', 'confirmada')
                  AND (r.estado <> 'pendiente'
                       OR r.fecha_expiracion IS NULL
                       OR r.fecha_expiracion > now())), 0))::INT AS cupo_disponible
FROM salida s
JOIN paquete p ON p.id_paquete = s.id_paquete
LEFT JOIN reserva r ON r.id_salida = s.id_salida
GROUP BY s.fecha_salida, s.id_salida, p.nombre, s.cupo_maximo
ORDER BY s.fecha_salida;

-- ---------------------------------------------------------------------
-- 13. Semilla mínima de roles
-- ---------------------------------------------------------------------

INSERT INTO rol (codigo, nombre, descripcion) VALUES
    ('ADMIN',    'Administrador',      'Gestiona usuarios, paquetes, salidas y reportes.'),
    ('PERSONAL', 'Personal de agencia', 'Consulta, cotiza, registra reservas y confirma pagos.'),
    ('TURISTA',  'Turista',             'Consulta la disponibilidad, solicita reservas, registra pagos y sigue sus reservas.')
ON CONFLICT (codigo) DO NOTHING;
