/**
 * Tipos de las respuestas de la API.
 *
 * Los usa el servidor para describir lo que devuelve y la interfaz para
 * saber lo que espera. Cuando una ruta de `server/api` cambia, cambia
 * aquí.
 */

import type { EstadoReserva } from './domain'

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
  fecha_salida: string
  fecha_retorno: string
  cupo_maximo: number
  pasajeros_ocupados: number
  cupo_disponible: number
  precio: string
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
