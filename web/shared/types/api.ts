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
  EstadoPago,
  EstadoPaquete,
  EstadoProveedor,
  EstadoReserva,
  EstadoSalida,
  EstadoUsuario,
  OrigenReserva,
  Rol,
  TipoDocumento,
  TipoLugar,
  TipoPago,
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
  /** Código propio de la salida: paquete más ordinal (RN-SAL-22). */
  codigo_salida: string
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

/** Un proveedor en la ficha de la salida (HU-18). */
export interface ProveedorFicha {
  idProveedor: number
  nombre: string
  /** Tipo de servicio declarado que presta en el paquete (RN-PRV-06). */
  servicio: TipoProveedor
  /** Descripción del vínculo con el paquete. */
  detalle: string | null
  /** Costo interno del vínculo; solo lo ve el personal (RN-SAL-24). */
  costo: string | null
  /** Los detalles del servicio de este proveedor (RN-PRV-08). */
  detallesServicio: DetalleServicioResumen[]
}

/**
 * La ficha de una salida (HU-18): el paquete, el mapa del recorrido, el
 * itinerario, los servicios y los proveedores, con los costos solo para
 * el personal (RN-SAL-24).
 */
export interface FichaSalida {
  idSalida: number
  codigoSalida: string
  codigoPaquete: string
  paquete: string
  descripcion: string | null
  tipoRecorrido: TipoRecorrido
  duracionDias: number
  destino: string | null
  origen: string | null
  /** Paradas con coordenadas, para el mapa del recorrido. */
  paradas: LugarResumen[]
  itinerario: ItinerarioDia[]
  servicios: ServicioResumen[]
  serviciosDetalle: string | null
  serviciosExcluidos: string | null
  fechaSalida: string
  fechaRetorno: string
  cupoMaximo: number
  /** Pasajeros de solicitudes pendientes vigentes (en revisión). */
  pasajerosPendientes: number
  pasajerosConfirmados: number
  cupoDisponible: number
  precio: string
  precioBase: string
  puntoEncuentro: string | null
  estado: EstadoSalida
  estadoPaquete: EstadoPaquete
  proveedores: ProveedorFicha[]
  asignaciones: AsignacionSalidaResumen[]
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
  /** Marca de la solicitud de cancelación del cliente (HU-13). */
  fechaSolicitudCancelacion: string | null
  /** Estado del anticipo de la reserva: nulo cuando no hay pago. */
  anticipo: EstadoPago | null
  /** Total menos lo abonado validado. */
  saldoPendiente: string
  /** Pasajeros ya registrados en el manifiesto (RN-RES-19). */
  pasajerosRegistrados: number
}

/** Un pasajero del manifiesto de una reserva (HU-12). */
export interface PasajeroResumen {
  idPasajero: number
  tipoDocumento: TipoDocumento
  numeroDocumento: string
  nombres: string
  apellidos: string
  fechaNacimiento: string | null
}

/** Respuesta del manifiesto de una reserva. */
export interface RespuestaPasajeros {
  pasajeros: PasajeroResumen[]
  /** Cantidad declarada de la reserva: el manifiesto debe igualarla. */
  cantidadDeclarada: number
}

/** Una entrada del historial de una reserva (HU-07). */
export interface HistorialResumen {
  idHistorial: number
  estadoAnterior: string | null
  estadoNuevo: string
  fechaCambio: string
  /** Nombre de la cuenta que hizo el cambio, si se conserva. */
  usuario: string | null
  observacion: string | null
}

/** Respuesta del historial de una reserva. */
export interface RespuestaHistorial {
  historial: HistorialResumen[]
}

/** Un aviso de cambio de salida para el cliente (HU-16). */
export interface AvisoResumen {
  idReserva: number
  codigo: string
  codigoPaquete: string
  paquete: string
  fechaSalida: string
  /** Campo modificado: fecha_salida, fecha_retorno o cupo_maximo. */
  campo: string
  valorAnterior: string | null
  valorNuevo: string | null
  motivo: string | null
  fechaCambio: string
}

/** Respuesta de los avisos del cliente. */
export interface RespuestaAvisos {
  avisos: AvisoResumen[]
}

/** Una fila del reporte de ocupación y reservas (HU-11). */
export interface ReporteResumen {
  idSalida: number
  idPaquete: number
  codigoPaquete: string
  paquete: string
  fechaSalida: string
  cupoMaximo: number
  pasajerosPendientes: number
  pasajerosConfirmados: number
  cupoDisponible: number
  reservasPendientes: number
  reservasConfirmadas: number
  reservasActivas: number
  reservasVencidas: number
  reservasCanceladas: number
  /** Reservas confirmadas cuyo viaje ya se realizó (T-HU-07.4). */
  reservasFinalizadas: number
  /** Reservas activas de cada canal (RN-REP-03). */
  reservasWeb: number
  reservasPersonal: number
}

/** Respuesta del reporte por fecha. */
export interface RespuestaReportes {
  salidas: ReporteResumen[]
}

/** Un día del itinerario de un paquete, día por día (RN-PAQ-18). */
export interface ItinerarioDia {
  /** Posición en el relato: 1 es el primer día. */
  dia: number
  titulo: string
  detalle: string | null
}

/** Un detalle de servicio de un proveedor (RN-PRV-08). */
export interface DetalleServicioResumen {
  /** Tipo de servicio declarado al que pertenece el detalle. */
  tipo: TipoProveedor
  titulo: string
  detalle: string | null
}

/** Una asignación operativa de proveedor en una salida (RN-SAL-23). */
export interface AsignacionSalidaResumen {
  idProveedor: number
  nombre: string
  /** Tipo de servicio declarado del proveedor (RN-PRV-06). */
  servicio: TipoProveedor
  /** Descripción opcional de la asignación concreta. */
  detalle: string | null
}

/** Respuesta de la consulta de reservas. */
export interface RespuestaReservas {
  reservas: ReservaResumen[]
}

/** Un pago de una reserva, tal como lo muestra la interfaz. */
export interface PagoResumen {
  idPago: number
  idReserva: number
  tipo: TipoPago
  monto: string
  metodo: MetodoPago
  referencia: string | null
  fechaPago: string
  estado: EstadoPago
  fechaValidacion: string | null
}

/** Resumen de los pagos de una reserva. */
export interface ResumenPagos {
  montoTotal: string
  /** Suma de los pagos validados. */
  abonado: string
  /** Suma de los pagos registrados que esperan validación. */
  enRevision: string
  /** Total menos lo abonado validado. */
  saldoPendiente: string
  /** Hay un anticipo validado que cumple el mínimo (RN-RES-18). */
  anticipoValidado: boolean
}

/** Respuesta de la consulta de pagos de una reserva. */
export interface RespuestaPagos {
  pagos: PagoResumen[]
  resumen: ResumenPagos
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
  /** Ficha del cliente dueño de la cuenta; nula fuera del canal web. */
  ficha: FichaCliente | null
}

/** Los datos de la ficha de cliente que el manifiesto puede reutilizar. */
export interface FichaCliente {
  tipoDocumento: TipoDocumento
  numeroDocumento: string
  nombres: string
  apellidos: string
  fechaNacimiento: string | null
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
  /** Detalles por servicio, para la ficha de la salida (RN-PRV-08). */
  detalles: DetalleServicioResumen[]
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
  /** Itinerario día por día, renumerado al guardar (RN-PAQ-18). */
  itinerario: ItinerarioDia[]
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
  /** Código propio de la salida: paquete más ordinal (RN-SAL-22). */
  codigoSalida: string
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
  /** Asignaciones operativas de proveedores (RN-SAL-23). */
  asignaciones: AsignacionSalidaResumen[]
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
  /** Reserva originada por esta cotización, si existe (RN-COT-08). */
  idReservaOriginada: number | null
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
  /** Correo obligatorio y único (RN-USU-05). */
  correo: string
  telefono: string | null
  direccion: string | null
  fechaNacimiento: string | null
  estado: EstadoCliente
  fechaRegistro: string
  /** Cuenta vinculada a la ficha, si la tiene (RN-USU-02). */
  cuenta: {
    usuario: string
    estado: EstadoUsuario
  } | null
}

/** Respuesta de la lista de clientes. */
export interface RespuestaClientes {
  clientes: ClienteResumen[]
}
