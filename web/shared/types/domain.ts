/**
 * Tipos del dominio.
 *
 * Son el reflejo en TypeScript de los valores que admite la base de datos
 * (`bd/esquema.sql`). Si cambia una restricción `CHECK` de la base, cambia
 * el tipo de aquí.
 *
 * Estos tipos se importan desde la interfaz y desde el servidor: viven en
 * `shared/`, que Nuxt expone con el alias `#shared`.
 */

/** Roles del sistema. */
export type Rol = 'ADMIN' | 'PERSONAL' | 'CLIENTE'

/** Estados de una cuenta. */
export type EstadoUsuario = 'activo' | 'inactivo' | 'bloqueado'

/** Estados de la ficha del cliente. */
export type EstadoCliente = 'activo' | 'inactivo'

/** Estados del catálogo de paquetes. */
export type EstadoPaquete = 'borrador' | 'activo' | 'inactivo'

/** Forma del recorrido de un paquete. */
export type TipoRecorrido = 'sencillo' | 'circuito'

/** Tipos de lugar del catálogo geográfico. */
export type TipoLugar =
  | 'ciudad'
  | 'atractivo'
  | 'terminal'
  | 'hospedaje'
  | 'otro'

/** Estados de una salida programada. */
export type EstadoSalida = 'programada' | 'confirmada' | 'realizada' | 'cancelada'

/** Estados de una cotización. */
export type EstadoCotizacion =
  | 'borrador'
  | 'enviada'
  | 'aceptada'
  | 'rechazada'
  | 'vencida'

/** Estados de una reserva. */
export type EstadoReserva =
  | 'pendiente'
  | 'confirmada'
  | 'vencida'
  | 'cancelada'
  | 'finalizada'

/** Canal por el que ingresa una reserva. */
export type OrigenReserva = 'personal' | 'web'

/** Tipos de pago. */
export type TipoPago = 'anticipo' | 'saldo'

/** Métodos de pago admitidos. */
export type MetodoPago = 'efectivo' | 'transferencia' | 'tarjeta' | 'otro'

/** Estados de un pago. */
export type EstadoPago = 'registrado' | 'validado' | 'anulado'

/** Tipos de documento de las personas. */
export type TipoDocumento = 'CI' | 'NIT' | 'PASAPORTE' | 'OTRO'

/** Tipos de proveedor de servicios. */
export type TipoProveedor =
  | 'transporte'
  | 'hospedaje'
  | 'guia'
  | 'alimentacion'
  | 'otro'

/** Tipos de acceso registrado. */
export type TipoAcceso = 'ingreso' | 'salida' | 'intento'

/** Resultado de un acceso. */
export type ResultadoAcceso = 'permitido' | 'denegado'
