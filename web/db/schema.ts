/**
 * Esquema de la base de datos, en TypeScript.
 *
 * Refleja el script de creación `bd/esquema.sql`, que es la fuente
 * canónica: aquí están los tipos y las relaciones que usa la aplicación,
 * pero las restricciones (claves foráneas, `CHECK`, índices únicos) viven
 * en el script de creación.
 *
 * En esta fase el esquema no lo genera la aplicación: se crea una vez con
 * `psql -f bd/esquema.sql`. Drizzle se usa para consultar y escribir.
 */

import { relations, sql } from 'drizzle-orm'
import {
  boolean,
  date,
  index,
  numeric,
  pgSchema,
  smallint,
  text,
  timestamp,
  uniqueIndex,
  varchar,
  bigint,
} from 'drizzle-orm/pg-core'

/**
 * El esquema de la base es `turismo` (ver `bd/esquema.sql`).
 *
 * Las tablas se declaran con su esquema porque la aplicación se conecta
 * con la cadena *pooled* de Neon: el pooler no admite el parámetro
 * `search_path` en el arranque de la conexión, de modo que las tablas
 * tienen que ir calificadas.
 */
const turismo = pgSchema('turismo')

// --- Roles --------------------------------------------------------------

export const rol = turismo.table('rol', {
  idRol: smallint('id_rol').primaryKey().generatedAlwaysAsIdentity(),
  codigo: varchar('codigo', { length: 20 }).notNull().unique(),
  nombre: varchar('nombre', { length: 60 }).notNull(),
  descripcion: varchar('descripcion', { length: 200 }),
})

export type Rol = typeof rol.$inferSelect
export type NuevoRol = typeof rol.$inferInsert

// --- Identidad (Better Auth) -------------------------------------------

/**
 * Tabla `user` de Better Auth, renombrada a `usuario` porque `user` es
 * palabra reservada en SQL. El identificador es de texto: lo genera la
 * biblioteca. Los campos del dominio son campos adicionales.
 *
 * Las propiedades usan el nombre de campo de Better Auth (camelCase) y la
 * columna real va en snake_case: el adaptador de Drizzle busca la
 * propiedad por su nombre.
 */
export const usuario = turismo.table('usuario', {
  id: text('id').primaryKey(),
  name: text('name').notNull(),
  email: text('email').notNull().unique(),
  emailVerified: boolean('email_verificado').notNull().default(false),
  image: text('image'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  idRol: smallint('id_rol').references(() => rol.idRol, { onDelete: 'set null' }),
  nombres: varchar('nombres', { length: 100 }).notNull(),
  apellidos: varchar('apellidos', { length: 100 }).notNull(),
  telefono: varchar('telefono', { length: 30 }),
  estado: varchar('estado', { length: 15 }).notNull().default('activo'),
  /**
   * Contraseña inicial pendiente de cambio en el primer ingreso.
   * Better Auth no conoce este campo: lo lee la aplicación para decidir
   * si redirige a `/cambiar-password`.
   */
  debeCambiarPassword: boolean('debe_cambiar_password')
    .notNull()
    .default(false),
})

export const session = turismo.table('session', {
  id: text('id').primaryKey(),
  userId: text('user_id')
    .notNull()
    .references(() => usuario.id, { onDelete: 'cascade' }),
  token: text('token').notNull().unique(),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
  ipAddress: varchar('ip_address', { length: 45 }),
  userAgent: text('user_agent'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
}, (tabla) => [index('ix_session_user').on(tabla.userId)])

export const account = turismo.table('account', {
  id: text('id').primaryKey(),
  userId: text('user_id')
    .notNull()
    .references(() => usuario.id, { onDelete: 'cascade' }),
  accountId: text('account_id').notNull(),
  providerId: text('provider_id').notNull(),
  password: text('password'),
  accessToken: text('access_token'),
  refreshToken: text('refresh_token'),
  idToken: text('id_token'),
  accessTokenExpiresAt: timestamp('access_token_expires_at', { withTimezone: true }),
  refreshTokenExpiresAt: timestamp('refresh_token_expires_at', { withTimezone: true }),
  scope: text('scope'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
}, (tabla) => [index('ix_account_user').on(tabla.userId)])

export const verification = turismo.table('verification', {
  id: text('id').primaryKey(),
  identifier: text('identifier').notNull(),
  value: text('value').notNull(),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
}, (tabla) => [index('ix_verification_identifier').on(tabla.identifier)])

/** Registro de accesos: lo exige el criterio de HU-08. */
export const acceso = turismo.table('acceso', {
  idAcceso: bigint('id_acceso', { mode: 'number' }).primaryKey().generatedAlwaysAsIdentity(),
  idUsuario: text('id_usuario').references(() => usuario.id, { onDelete: 'set null' }),
  fechaHora: timestamp('fecha_hora', { withTimezone: true }).notNull().defaultNow(),
  tipo: varchar('tipo', { length: 20 }).notNull(),
  direccionIp: varchar('direccion_ip', { length: 45 }),
  resultado: varchar('resultado', { length: 20 }).notNull(),
}, (tabla) => [index('ix_acceso_usuario_fecha').on(tabla.idUsuario, tabla.fechaHora)])

// --- Clientes y pasajeros ------------------------------------------------

export const cliente = turismo.table('cliente', {
  idCliente: bigint('id_cliente', { mode: 'number' }).primaryKey().generatedAlwaysAsIdentity(),
  idUsuario: text('id_usuario')
    .unique()
    .references(() => usuario.id, { onDelete: 'set null' }),
  tipoDocumento: varchar('tipo_documento', { length: 15 }).notNull(),
  numeroDocumento: varchar('numero_documento', { length: 30 }).notNull(),
  nombres: varchar('nombres', { length: 100 }).notNull(),
  apellidos: varchar('apellidos', { length: 100 }).notNull(),
  correo: varchar('correo', { length: 150 }),
  telefono: varchar('telefono', { length: 30 }),
  direccion: varchar('direccion', { length: 200 }),
  fechaNacimiento: date('fecha_nacimiento'),
  fechaRegistro: timestamp('fecha_registro', { withTimezone: true }).notNull().defaultNow(),
  estado: varchar('estado', { length: 15 }).notNull().default('activo'),
}, (tabla) => [
  uniqueIndex('uq_cliente_documento').on(tabla.tipoDocumento, tabla.numeroDocumento),
])

export const pasajero = turismo.table('pasajero', {
  idPasajero: bigint('id_pasajero', { mode: 'number' }).primaryKey().generatedAlwaysAsIdentity(),
  idCliente: bigint('id_cliente', { mode: 'number' })
    .notNull()
    .references(() => cliente.idCliente, { onDelete: 'restrict' }),
  tipoDocumento: varchar('tipo_documento', { length: 15 }).notNull(),
  numeroDocumento: varchar('numero_documento', { length: 30 }).notNull(),
  nombres: varchar('nombres', { length: 100 }).notNull(),
  apellidos: varchar('apellidos', { length: 100 }).notNull(),
  fechaNacimiento: date('fecha_nacimiento'),
}, (tabla) => [
  uniqueIndex('uq_pasajero_documento').on(tabla.tipoDocumento, tabla.numeroDocumento),
  index('ix_pasajero_cliente').on(tabla.idCliente),
])

// --- Lugares, paquetes y proveedores ------------------------------------

export const lugar = turismo.table(
  'lugar',
  {
    idLugar: bigint('id_lugar', { mode: 'number' }).primaryKey().generatedAlwaysAsIdentity(),
    codigo: varchar('codigo', { length: 6 }).notNull().unique(),
    nombre: varchar('nombre', { length: 150 }).notNull(),
    tipo: varchar('tipo', { length: 20 }).notNull().default('otro'),
    direccion: varchar('direccion', { length: 200 }),
    latitud: numeric('latitud', { precision: 9, scale: 6 }),
    longitud: numeric('longitud', { precision: 9, scale: 6 }),
    osmTipo: varchar('osm_tipo', { length: 2 }),
    osmId: bigint('osm_id', { mode: 'number' }),
    activo: boolean('activo').notNull().default(true),
  },
  (tabla) => [
    uniqueIndex('ux_lugar_nombre').on(sql`lower(btrim(${tabla.nombre}))`),
    uniqueIndex('ux_lugar_osm')
      .on(tabla.osmTipo, tabla.osmId)
      .where(sql`${tabla.osmId} is not null`),
  ],
)

export const proveedor = turismo.table('proveedor', {
  idProveedor: bigint('id_proveedor', { mode: 'number' }).primaryKey().generatedAlwaysAsIdentity(),
  nombre: varchar('nombre', { length: 150 }).notNull(),
  tipo: varchar('tipo', { length: 20 }).notNull(),
  nit: varchar('nit', { length: 30 }),
  telefono: varchar('telefono', { length: 30 }),
  correo: varchar('correo', { length: 150 }),
  direccion: varchar('direccion', { length: 200 }),
  estado: varchar('estado', { length: 15 }).notNull().default('activo'),
})

export const paquete = turismo.table('paquete', {
  idPaquete: bigint('id_paquete', { mode: 'number' }).primaryKey().generatedAlwaysAsIdentity(),
  codigo: varchar('codigo', { length: 20 }).notNull().unique(),
  nombre: varchar('nombre', { length: 150 }).notNull(),
  idLugarDestino: bigint('id_lugar_destino', { mode: 'number' }).references(
    () => lugar.idLugar,
    { onDelete: 'restrict' },
  ),
  idLugarOrigen: bigint('id_lugar_origen', { mode: 'number' }).references(
    () => lugar.idLugar,
    { onDelete: 'restrict' },
  ),
  tipoRecorrido: varchar('tipo_recorrido', { length: 15 })
    .notNull()
    .default('sencillo'),
  descripcion: text('descripcion'),
  duracionDias: smallint('duracion_dias').notNull(),
  precioBase: numeric('precio_base', { precision: 12, scale: 2 }).notNull(),
  itinerario: text('itinerario'),
  serviciosDetalle: text('servicios_detalle'),
  serviciosExcluidos: text('servicios_excluidos'),
  estado: varchar('estado', { length: 15 }).notNull().default('borrador'),
  idUsuarioCreador: text('id_usuario_creador').references(() => usuario.id, {
    onDelete: 'set null',
  }),
  idUsuarioActualizacion: text('id_usuario_actualizacion').references(
    () => usuario.id,
    { onDelete: 'set null' },
  ),
  fechaCreacion: timestamp('fecha_creacion', { withTimezone: true }).notNull().defaultNow(),
  fechaActualizacion: timestamp('fecha_actualizacion', { withTimezone: true })
    .notNull()
    .defaultNow(),
})

export const paqueteParada = turismo.table(
  'paquete_parada',
  {
    idPaquete: bigint('id_paquete', { mode: 'number' })
      .notNull()
      .references(() => paquete.idPaquete, { onDelete: 'cascade' }),
    idLugar: bigint('id_lugar', { mode: 'number' })
      .notNull()
      .references(() => lugar.idLugar, { onDelete: 'restrict' }),
    orden: smallint('orden').notNull(),
  },
  (tabla) => [
    uniqueIndex('paquete_parada_pkey').on(tabla.idPaquete, tabla.orden),
    uniqueIndex('ux_paquete_parada_lugar').on(tabla.idPaquete, tabla.idLugar),
  ],
)

export const servicio = turismo.table('servicio', {
  idServicio: smallint('id_servicio').primaryKey().generatedAlwaysAsIdentity(),
  codigo: varchar('codigo', { length: 30 }).notNull().unique(),
  nombre: varchar('nombre', { length: 80 }).notNull(),
  orden: smallint('orden').notNull().default(0),
  activo: boolean('activo').notNull().default(true),
})

export const paqueteServicio = turismo.table(
  'paquete_servicio',
  {
    idPaquete: bigint('id_paquete', { mode: 'number' })
      .notNull()
      .references(() => paquete.idPaquete, { onDelete: 'cascade' }),
    idServicio: smallint('id_servicio')
      .notNull()
      .references(() => servicio.idServicio, { onDelete: 'restrict' }),
  },
  (tabla) => [uniqueIndex('paquete_servicio_pkey').on(tabla.idPaquete, tabla.idServicio)],
)

export const paqueteProveedor = turismo.table(
  'paquete_proveedor',
  {
    idPaquete: bigint('id_paquete', { mode: 'number' })
      .notNull()
      .references(() => paquete.idPaquete, { onDelete: 'cascade' }),
    idProveedor: bigint('id_proveedor', { mode: 'number' })
      .notNull()
      .references(() => proveedor.idProveedor, { onDelete: 'restrict' }),
    servicio: varchar('servicio', { length: 150 }).notNull(),
    costo: numeric('costo', { precision: 12, scale: 2 }).notNull().default('0'),
  },
  (tabla) => [uniqueIndex('pq_paquete_proveedor').on(tabla.idPaquete, tabla.idProveedor)],
)

// --- Salidas -------------------------------------------------------------

export const salida = turismo.table(
  'salida',
  {
    idSalida: bigint('id_salida', { mode: 'number' }).primaryKey().generatedAlwaysAsIdentity(),
    idPaquete: bigint('id_paquete', { mode: 'number' })
      .notNull()
      .references(() => paquete.idPaquete, { onDelete: 'restrict' }),
    fechaSalida: date('fecha_salida').notNull(),
    fechaRetorno: date('fecha_retorno').notNull(),
    cupoMaximo: smallint('cupo_maximo').notNull(),
    precio: numeric('precio', { precision: 12, scale: 2 }).notNull(),
    puntoEncuentro: varchar('punto_encuentro', { length: 200 }),
    estado: varchar('estado', { length: 15 }).notNull().default('programada'),
    observaciones: text('observaciones'),
    idUsuario: text('id_usuario').references(() => usuario.id, { onDelete: 'set null' }),
    fechaCreacion: timestamp('fecha_creacion', { withTimezone: true }).notNull().defaultNow(),
    fechaActualizacion: timestamp('fecha_actualizacion', { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (tabla) => [
    uniqueIndex('ux_salida_paquete_fecha').on(tabla.idPaquete, tabla.fechaSalida),
    index('ix_salida_paquete_fecha').on(tabla.idPaquete, tabla.fechaSalida),
    index('ix_salida_fecha').on(tabla.fechaSalida),
  ],
)

// --- Cotizaciones --------------------------------------------------------

export const cotizacion = turismo.table(
  'cotizacion',
  {
    idCotizacion: bigint('id_cotizacion', { mode: 'number' })
      .primaryKey()
      .generatedAlwaysAsIdentity(),
    numero: varchar('numero', { length: 20 }).notNull().unique(),
    idCliente: bigint('id_cliente', { mode: 'number' })
      .notNull()
      .references(() => cliente.idCliente, { onDelete: 'restrict' }),
    idSalida: bigint('id_salida', { mode: 'number' })
      .notNull()
      .references(() => salida.idSalida, { onDelete: 'restrict' }),
    idUsuario: text('id_usuario')
      .notNull()
      .references(() => usuario.id, { onDelete: 'restrict' }),
    cantidadPasajeros: smallint('cantidad_pasajeros').notNull(),
    precioUnitario: numeric('precio_unitario', { precision: 12, scale: 2 }).notNull(),
    subtotal: numeric('subtotal', { precision: 12, scale: 2 }).generatedAlwaysAs(
      sql`cantidad_pasajeros * precio_unitario`,
    ),
    descuento: numeric('descuento', { precision: 12, scale: 2 }).notNull().default('0'),
    total: numeric('total', { precision: 12, scale: 2 }).generatedAlwaysAs(
      sql`cantidad_pasajeros * precio_unitario - descuento`,
    ),
    estado: varchar('estado', { length: 15 }).notNull().default('borrador'),
    fechaEmision: date('fecha_emision').notNull().defaultNow(),
    fechaValidez: date('fecha_validez').notNull(),
    observaciones: text('observaciones'),
    fechaCreacion: timestamp('fecha_creacion', { withTimezone: true }).notNull().defaultNow(),
  },
  (tabla) => [
    index('ix_cotizacion_cliente').on(tabla.idCliente),
    index('ix_cotizacion_salida').on(tabla.idSalida),
  ],
)

// --- Reservas ------------------------------------------------------------

export const reserva = turismo.table(
  'reserva',
  {
    idReserva: bigint('id_reserva', { mode: 'number' }).primaryKey().generatedAlwaysAsIdentity(),
    codigo: varchar('codigo', { length: 20 }).notNull().unique(),
    idCliente: bigint('id_cliente', { mode: 'number' })
      .notNull()
      .references(() => cliente.idCliente, { onDelete: 'restrict' }),
    idSalida: bigint('id_salida', { mode: 'number' })
      .notNull()
      .references(() => salida.idSalida, { onDelete: 'restrict' }),
    idCotizacion: bigint('id_cotizacion', { mode: 'number' })
      .unique()
      .references(() => cotizacion.idCotizacion, { onDelete: 'set null' }),
    idUsuario: text('id_usuario')
      .notNull()
      .references(() => usuario.id, { onDelete: 'restrict' }),
    origen: varchar('origen', { length: 15 }).notNull().default('personal'),
    cantidadPasajeros: smallint('cantidad_pasajeros').notNull(),
    montoTotal: numeric('monto_total', { precision: 12, scale: 2 }).notNull(),
    estado: varchar('estado', { length: 15 }).notNull().default('pendiente'),
    fechaExpiracion: timestamp('fecha_expiracion', { withTimezone: true }).default(
      sql`now() + interval '48 hours'`,
    ),
    fechaSolicitudCancelacion: timestamp('fecha_solicitud_cancelacion', { withTimezone: true }),
    observaciones: text('observaciones'),
    motivoCancelacion: varchar('motivo_cancelacion', { length: 200 }),
    fechaCancelacion: timestamp('fecha_cancelacion', { withTimezone: true }),
    fechaReserva: timestamp('fecha_reserva', { withTimezone: true }).notNull().defaultNow(),
    fechaActualizacion: timestamp('fecha_actualizacion', { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (tabla) => [
    index('ix_reserva_salida_estado').on(tabla.idSalida, tabla.estado),
    index('ix_reserva_cliente').on(tabla.idCliente),
    index('ix_reserva_fecha').on(tabla.fechaReserva),
    index('ix_reserva_vencimiento')
      .on(tabla.fechaExpiracion)
      .where(sql`${tabla.estado} = 'pendiente'`),
    uniqueIndex('ux_reserva_solicitud_activa')
      .on(tabla.idCliente, tabla.idSalida)
      .where(sql`${tabla.estado} = 'pendiente'`),
  ],
)

export const reservaPasajero = turismo.table(
  'reserva_pasajero',
  {
    idReserva: bigint('id_reserva', { mode: 'number' })
      .notNull()
      .references(() => reserva.idReserva, { onDelete: 'cascade' }),
    idPasajero: bigint('id_pasajero', { mode: 'number' })
      .notNull()
      .references(() => pasajero.idPasajero, { onDelete: 'restrict' }),
  },
  (tabla) => [uniqueIndex('pq_reserva_pasajero').on(tabla.idReserva, tabla.idPasajero)],
)

// --- Pagos ---------------------------------------------------------------

export const pago = turismo.table(
  'pago',
  {
    idPago: bigint('id_pago', { mode: 'number' }).primaryKey().generatedAlwaysAsIdentity(),
    idReserva: bigint('id_reserva', { mode: 'number' })
      .notNull()
      .references(() => reserva.idReserva, { onDelete: 'cascade' }),
    tipo: varchar('tipo', { length: 15 }).notNull(),
    monto: numeric('monto', { precision: 12, scale: 2 }).notNull(),
    metodo: varchar('metodo', { length: 20 }).notNull(),
    referencia: varchar('referencia', { length: 100 }),
    fechaPago: timestamp('fecha_pago', { withTimezone: true }).notNull().defaultNow(),
    idUsuario: text('id_usuario')
      .notNull()
      .references(() => usuario.id, { onDelete: 'restrict' }),
    estado: varchar('estado', { length: 15 }).notNull().default('registrado'),
    idUsuarioValidacion: text('id_usuario_validacion').references(() => usuario.id, {
      onDelete: 'set null',
    }),
    fechaValidacion: timestamp('fecha_validacion', { withTimezone: true }),
    observacion: varchar('observacion', { length: 200 }),
  },
  (tabla) => [
    uniqueIndex('uq_pago_reserva_tipo').on(tabla.idReserva, tabla.tipo),
    index('ix_pago_reserva').on(tabla.idReserva),
    index('ix_pago_fecha').on(tabla.fechaPago),
  ],
)

// --- Auditoría -----------------------------------------------------------

export const historialReserva = turismo.table(
  'historial_reserva',
  {
    idHistorial: bigint('id_historial', { mode: 'number' })
      .primaryKey()
      .generatedAlwaysAsIdentity(),
    idReserva: bigint('id_reserva', { mode: 'number' })
      .notNull()
      .references(() => reserva.idReserva, { onDelete: 'cascade' }),
    estadoAnterior: varchar('estado_anterior', { length: 15 }),
    estadoNuevo: varchar('estado_nuevo', { length: 15 }).notNull(),
    fechaCambio: timestamp('fecha_cambio', { withTimezone: true }).notNull().defaultNow(),
    idUsuario: text('id_usuario')
      .notNull()
      .references(() => usuario.id, { onDelete: 'restrict' }),
    observacion: varchar('observacion', { length: 200 }),
  },
  (tabla) => [index('ix_historial_reserva').on(tabla.idReserva, tabla.fechaCambio)],
)

export const historialSalida = turismo.table(
  'historial_salida',
  {
    idHistorial: bigint('id_historial', { mode: 'number' })
      .primaryKey()
      .generatedAlwaysAsIdentity(),
    idSalida: bigint('id_salida', { mode: 'number' })
      .notNull()
      .references(() => salida.idSalida, { onDelete: 'cascade' }),
    campoModificado: varchar('campo_modificado', { length: 30 }).notNull(),
    valorAnterior: varchar('valor_anterior', { length: 100 }),
    valorNuevo: varchar('valor_nuevo', { length: 100 }),
    motivo: varchar('motivo', { length: 200 }),
    fechaCambio: timestamp('fecha_cambio', { withTimezone: true }).notNull().defaultNow(),
    idUsuario: text('id_usuario')
      .notNull()
      .references(() => usuario.id, { onDelete: 'restrict' }),
  },
  (tabla) => [index('ix_historial_salida').on(tabla.idSalida, tabla.fechaCambio)],
)

// --- Relaciones ----------------------------------------------------------

export const rolRelations = relations(rol, ({ many }) => ({
  usuarios: many(usuario),
}))

export const usuarioRelations = relations(usuario, ({ one, many }) => ({
  rol: one(rol, { fields: [usuario.idRol], references: [rol.idRol] }),
  cliente: one(cliente),
  sesiones: many(session),
  cuentas: many(account),
  accesos: many(acceso),
}))

export const clienteRelations = relations(cliente, ({ one, many }) => ({
  usuario: one(usuario, { fields: [cliente.idUsuario], references: [usuario.id] }),
  pasajeros: many(pasajero),
  reservas: many(reserva),
  cotizaciones: many(cotizacion),
}))

export const pasajeroRelations = relations(pasajero, ({ one, many }) => ({
  cliente: one(cliente, { fields: [pasajero.idCliente], references: [cliente.idCliente] }),
  reservas: many(reservaPasajero),
}))

export const paqueteRelations = relations(paquete, ({ one, many }) => ({
  destino: one(lugar, {
    fields: [paquete.idLugarDestino],
    references: [lugar.idLugar],
    relationName: 'paquete_destino',
  }),
  origen: one(lugar, {
    fields: [paquete.idLugarOrigen],
    references: [lugar.idLugar],
    relationName: 'paquete_origen',
  }),
  paradas: many(paqueteParada),
  salidas: many(salida),
  proveedores: many(paqueteProveedor),
  servicios: many(paqueteServicio),
}))

export const lugarRelations = relations(lugar, ({ many }) => ({
  paquetesDestino: many(paquete, { relationName: 'paquete_destino' }),
  paquetesOrigen: many(paquete, { relationName: 'paquete_origen' }),
  paradas: many(paqueteParada),
}))

export const paqueteParadaRelations = relations(paqueteParada, ({ one }) => ({
  paquete: one(paquete, {
    fields: [paqueteParada.idPaquete],
    references: [paquete.idPaquete],
  }),
  lugar: one(lugar, {
    fields: [paqueteParada.idLugar],
    references: [lugar.idLugar],
  }),
}))

export const servicioRelations = relations(servicio, ({ many }) => ({
  paquetes: many(paqueteServicio),
}))

export const paqueteServicioRelations = relations(paqueteServicio, ({ one }) => ({
  paquete: one(paquete, {
    fields: [paqueteServicio.idPaquete],
    references: [paquete.idPaquete],
  }),
  servicio: one(servicio, {
    fields: [paqueteServicio.idServicio],
    references: [servicio.idServicio],
  }),
}))

export const proveedorRelations = relations(proveedor, ({ many }) => ({
  paquetes: many(paqueteProveedor),
}))

export const paqueteProveedorRelations = relations(paqueteProveedor, ({ one }) => ({
  paquete: one(paquete, {
    fields: [paqueteProveedor.idPaquete],
    references: [paquete.idPaquete],
  }),
  proveedor: one(proveedor, {
    fields: [paqueteProveedor.idProveedor],
    references: [proveedor.idProveedor],
  }),
}))

export const salidaRelations = relations(salida, ({ one, many }) => ({
  paquete: one(paquete, { fields: [salida.idPaquete], references: [paquete.idPaquete] }),
  reservas: many(reserva),
  historial: many(historialSalida),
}))

export const reservaRelations = relations(reserva, ({ one, many }) => ({
  cliente: one(cliente, { fields: [reserva.idCliente], references: [cliente.idCliente] }),
  salida: one(salida, { fields: [reserva.idSalida], references: [salida.idSalida] }),
  cotizacion: one(cotizacion, {
    fields: [reserva.idCotizacion],
    references: [cotizacion.idCotizacion],
  }),
  pasajeros: many(reservaPasajero),
  pagos: many(pago),
  historial: many(historialReserva),
}))

export const pagoRelations = relations(pago, ({ one }) => ({
  reserva: one(reserva, { fields: [pago.idReserva], references: [reserva.idReserva] }),
}))
