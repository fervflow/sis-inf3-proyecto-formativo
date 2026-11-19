/**
 * Ficha del cliente.
 *
 * El documento y su tipo forman la clave de negocio: no se repiten. La
 * validación se comparte entre el alta y la edición.
 */
import { z } from 'zod'
import type { ClienteResumen } from '#shared/types/api'
import type { EstadoCliente, TipoDocumento } from '#shared/types/domain'

const hoy = () => new Date().toISOString().slice(0, 10)

/** Cuerpo del alta y de la edición de un cliente. */
export const esquemaCliente = z.object({
  tipoDocumento: z.enum(['CI', 'NIT', 'PASAPORTE', 'OTRO']),
  numeroDocumento: z.string().trim().min(3).max(30),
  nombres: z.string().trim().min(2).max(100),
  apellidos: z.string().trim().min(2).max(100),
  correo: z.union([z.literal(''), z.email().max(150)]).optional(),
  telefono: z.string().trim().max(30).optional(),
  direccion: z.string().trim().max(200).optional(),
  fechaNacimiento: z
    .string()
    .trim()
    .regex(/^\d{4}-\d{2}-\d{2}$/)
    .optional()
    .or(z.literal(''))
    .refine((valor) => !valor || valor <= hoy(), {
      message: 'fecha_futura',
    }),
  estado: z.enum(['activo', 'inactivo']),
})

/** El documento se guarda en mayúsculas, sin espacios. */
export function normalizarDocumento(valor: string): string {
  return valor.trim().toUpperCase()
}

/** Fila de la tabla `cliente`. */
export interface FilaCliente {
  idCliente: number
  tipoDocumento: string
  numeroDocumento: string
  nombres: string
  apellidos: string
  correo: string | null
  telefono: string | null
  direccion: string | null
  fechaNacimiento: string | null
  estado: string
  fechaRegistro: Date
}

/** Convierte la fila de la base en lo que consume la interfaz. */
export function aClienteResumen(fila: FilaCliente): ClienteResumen {
  return {
    idCliente: fila.idCliente,
    tipoDocumento: fila.tipoDocumento as TipoDocumento,
    numeroDocumento: fila.numeroDocumento,
    nombres: fila.nombres,
    apellidos: fila.apellidos,
    correo: fila.correo,
    telefono: fila.telefono,
    direccion: fila.direccion,
    fechaNacimiento: fila.fechaNacimiento,
    estado: fila.estado as EstadoCliente,
    fechaRegistro: fila.fechaRegistro.toISOString(),
  }
}
