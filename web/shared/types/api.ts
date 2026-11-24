/**
 * Tipos de las respuestas de la API.
 *
 * Los usa el servidor para describir lo que devuelve y la interfaz para
 * saber lo que espera. Cuando una ruta de `server/api` cambia, cambia
 * aquí.
 */

import type {
  EstadoCliente,
  EstadoCotizacion,
  EstadoPaquete,
  EstadoProveedor,
  EstadoReserva,
  EstadoSalida,
  EstadoUsuario,
  OrigenReserva,
  Rol,
  TipoDocumento,
  TipoLugar,
  TipoProveedor,
  TipoRecorrido,
} from './domain'

/** Respuesta de la comprobación de estado. */
export interface EstadoSalud {
  estado: 'ok'
  base: {
    conectado: boolean
    paquetes: number
    salidas: number
    reservas: number
  }
}

/** Una salida con su disponibilidad, tal como la devuelve la vista. */
export interface SalidaDisponible {
  id_salida: number
  id_paquete: number
  codigo_paquete: string
  paquete: string
  estado_paquete: string
  /** Destino principal comercial del paquete, si lo tiene. */
  destino: string | null
  /** Origen del recorrido, si el paquete lo declara. */
  origen: string | null
  /** Nombres de las paradas del recorrido, en orden. */
  paradas: string[] | null
  /** Tipo de recorrido: `sencillo` o `circuito`. */
  tipo_recorrido: string
  duracion_dias: number
  fecha_salida: string
  fecha_retorno: string
  cupo_maximo: number
  pasajeros_ocupados: number
  /** Pasajeros de solicitudes pendientes vigentes (en revisión). */
  pasajeros_pendientes: number
  /** Pasajeros de reservas confirmadas. */
  pasajeros_confirmados: number
  cupo_disponible: number
  precio: string
  /** Precio de catálogo del paquete, para comparar con el de la salida. */
  precio_base: string
  punto_encuentro: string | null
  estado: string
}

/** Respuesta de la consulta de disponibilidad. */
export interface RespuestaDisponibilidad {
  salidas: SalidaDisponible[]
}

/** Respuesta del barrido de solicitudes vencidas. */
export interface RespuestaBarrido {
  vencidas: number
}

/** Datos de una reserva, en la forma en que los muestra la interfaz. */
export interface ReservaResumen {
  idReserva: number
  codigo: string
  idCliente: number
  cliente: string
  documento: string
  idSalida: number
  codigoPaquete: string
  paquete: string
  fechaSalida: string
  fechaRetorno: string
  /** Canal por el que ingresó: atención del personal o solicitud web. */
  origen: OrigenReserva
  cantidadPasajeros: number
  montoTotal: string
  estado: EstadoReserva
  fechaExpiracion: string | null
  fechaReserva: string
}

/** Respuesta de la consulta de reservas. */
export interface RespuestaReservas {
  reservas: ReservaResumen[]
}

/** Cuenta de la sesión en curso. */
export interface CuentaActual {
  id: string
  usuario: string
  nombres: string
  apellidos: string
  rol: Rol
  estado: EstadoUsuario
  debeCambiarPassword: boolean
}

/** Respuesta de la cuenta de la sesión en curso. */
export interface RespuestaCuenta {
  usuario: CuentaActual | null
}

/** Una cuenta tal como la ve el panel de administración. */
export interface UsuarioAdmin {
  id: string
  usuario: string
  nombres: string
  apellidos: string
  rol: Rol
  estado: EstadoUsuario
  debeCambiarPassword: boolean
  creadoEn: string
}

/** Respuesta de la lista de cuentas. */
export interface RespuestaUsuarios {
  usuarios: UsuarioAdmin[]
}

/** Respuesta de una operación que no devuelve datos. */
export interface RespuestaOperacion {
  ok: true
}

/** Un lugar del catálogo geográfico. */
export interface LugarResumen {
  idLugar: number
  codigo: string
  nombre: string
  tipo: TipoLugar
  direccion: string | null
  latitud: number | null
  longitud: number | null
}

/** Un servicio que un paquete puede incluir. */
export interface ServicioResumen {
  idServicio: number
  codigo: string
  nombre: string
  orden: number
}

/** Un proveedor vinculado a un paquete, para la ficha del paquete. */
export interface ProveedorPaqueteResumen {
  idProveedor: number
  nombre: string
  /** Tipo de servicio declarado que presta en el paquete (RN-PRV-06). */
  tipo: TipoProveedor
  /** Descripción opcional del servicio concreto. */
  detalle: string | null
  costo: string
}

/** Un paquete atendido por un proveedor. */
export interface ProveedorPaquete {
  idPaquete: number
  codigoPaquete: string
  paquete: string
  /** Tipo de servicio declarado por el proveedor (RN-PRV-06). */
  servicio: TipoProveedor
  /** Descripción opcional del servicio concreto. */
  detalle: string | null
  costo: string
}

/** Un proveedor tal como lo edita el administrador. */
export interface ProveedorAdmin {
  idProveedor: number
  nombre: string
  /** Tipos de servicio que declara prestar (RN-PRV-02). */
  tipos: TipoProveedor[]
  nit: string | null
  telefono: string | null
  correo: string | null
  direccion: string | null
  estado: EstadoProveedor
  paquetes: ProveedorPaquete[]
}

/** Respuesta de la lista de proveedores. */
export interface RespuestaProveedores {
  proveedores: ProveedorAdmin[]
}

/** Un paquete turístico tal como lo edita el administrador. */
export interface PaqueteAdmin {
  idPaquete: number
  codigo: string
  nombre: string
  destino: LugarResumen | null
  origen: LugarResumen | null
  paradas: LugarResumen[]
  tipoRecorrido: TipoRecorrido
  descripcion: string | null
  duracionDias: number
  precioBase: string
  itinerario: string | null
  serviciosDetalle: string | null
  serviciosExcluidos: string | null
  servicios: ServicioResumen[]
  proveedores: ProveedorPaqueteResumen[]
  estado: EstadoPaquete
  fechaActualizacion: string
}

/** Respuesta de la lista de paquetes. */
export interface RespuestaPaquetes {
  paquetes: PaqueteAdmin[]
}

/** Respuesta del catálogo de servicios. */
export interface RespuestaServicios {
  servicios: ServicioResumen[]
}

/** Respuesta del catálogo de lugares. */
export interface RespuestaLugares {
  lugares: LugarResumen[]
}

/** Un resultado de la búsqueda geográfica externa. */
export interface ResultadoGeocodificacion {
  nombre: string
  direccion: string | null
  latitud: number
  longitud: number
  osmTipo: string | null
  osmId: number | null
  tipo: TipoLugar
}

/** Respuesta de la búsqueda geográfica. */
export interface RespuestaGeocodificacion {
  resultados: ResultadoGeocodificacion[]
}

/** Una salida programada tal como la edita el administrador. */
export interface SalidaAdmin {
  idSalida: number
  idPaquete: number
  codigoPaquete: string
  paquete: string
  destino: string | null
  duracionDias: number
  fechaSalida: string
  fechaRetorno: string
  cupoMaximo: number
  pasajerosOcupados: number
  /** Pasajeros de reservas confirmadas. */
  pasajerosConfirmados: number
  /** Pasajeros de solicitudes pendientes vigentes (en revisión). */
  pasajerosPendientes: number
  cupoDisponible: number
  precio: string
  precioBase: string
  puntoEncuentro: string | null
  estado: EstadoSalida
  estadoPaquete: EstadoPaquete
  observaciones: string | null
  fechaActualizacion: string
}

/** Respuesta de la lista de salidas. */
export interface RespuestaSalidas {
  salidas: SalidaAdmin[]
}

/** Una cotización tal como la edita el personal. */
export interface CotizacionAdmin {
  idCotizacion: number
  numero: string
  idCliente: number
  cliente: string
  documento: string
  idSalida: number
  codigoPaquete: string
  paquete: string
  fechaSalida: string
  fechaRetorno: string
  cantidadPasajeros: number
  precioUnitario: string
  subtotal: string
  descuento: string
  total: string
  estado: EstadoCotizacion
  fechaEmision: string
  fechaValidez: string
  condiciones: string | null
  observaciones: string | null
  fechaCreacion: string
}

/** Respuesta de la lista de cotizaciones. */
export interface RespuestaCotizaciones {
  cotizaciones: CotizacionAdmin[]
}

/** La ficha de un cliente. */
export interface ClienteResumen {
  idCliente: number
  tipoDocumento: TipoDocumento
  numeroDocumento: string
  nombres: string
  apellidos: string
  correo: string | null
  telefono: string | null
  direccion: string | null
  fechaNacimiento: string | null
  estado: EstadoCliente
  fechaRegistro: string
}

/** Respuesta de la lista de clientes. */
export interface RespuestaClientes {
  clientes: ClienteResumen[]
}
