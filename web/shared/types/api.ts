/**
 * Tipos de las respuestas de la API.
 *
 * Los usa el servidor para describir lo que devuelve y la interfaz para
 * saber lo que espera. Cuando una ruta de `server/api` cambia, cambia
 * aquí.
 */

import type {
  EstadoCliente,
  EstadoPaquete,
  EstadoReserva,
  EstadoSalida,
  EstadoUsuario,
  Rol,
  TipoDocumento,
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
  codigo_paquete: string
  paquete: string
  estado_paquete: string
  fecha_salida: string
  fecha_retorno: string
  cupo_maximo: number
  pasajeros_ocupados: number
  cupo_disponible: number
  precio: string
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
  id: number
  codigo: string
  cliente: string
  salida: string
  estado: EstadoReserva
  cantidadPasajeros: number
  fechaExpiracion: string | null
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

/** Una acción común del itinerario. */
export interface ActividadResumen {
  idActividad: number
  codigo: string
  nombre: string
  orden: number
}

/** Un paquete turístico tal como lo edita el administrador. */
export interface PaqueteAdmin {
  idPaquete: number
  codigo: string
  nombre: string
  destino: string | null
  descripcion: string | null
  duracionDias: number
  precioBase: string
  itinerario: string | null
  serviciosIncluidos: string | null
  actividades: ActividadResumen[]
  estado: EstadoPaquete
  fechaActualizacion: string
}

/** Respuesta de la lista de paquetes. */
export interface RespuestaPaquetes {
  paquetes: PaqueteAdmin[]
}

/** Respuesta del catálogo de actividades. */
export interface RespuestaActividades {
  actividades: ActividadResumen[]
}

/** Una salida programada tal como la edita el administrador. */
export interface SalidaAdmin {
  idSalida: number
  idPaquete: number
  codigoPaquete: string
  paquete: string
  fechaSalida: string
  fechaRetorno: string
  cupoMaximo: number
  precio: string
  puntoEncuentro: string | null
  estado: EstadoSalida
  observaciones: string | null
  fechaActualizacion: string
}

/** Respuesta de la lista de salidas. */
export interface RespuestaSalidas {
  salidas: SalidaAdmin[]
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
