/**
 * Paquetes turísticos.
 *
 * La validación y la forma de la respuesta se comparten entre el alta y
 * la edición, para que las dos acepten exactamente lo mismo.
 */
import { z } from 'zod'
import type { PaqueteAdmin } from '#shared/types/api'
import type { EstadoPaquete } from '#shared/types/domain'

/** Cuerpo del alta y de la edición de un paquete. */
export const esquemaPaquete = z.object({
  codigo: z
    .string()
    .trim()
    .min(3)
    .max(20)
    .regex(/^[A-Za-z0-9-]+$/, 'codigo_invalido'),
  nombre: z.string().trim().min(3).max(150),
  descripcion: z.string().trim().max(2000).optional(),
  duracionDias: z.coerce.number().int().min(1).max(365),
  precioBase: z.coerce.number().min(0).max(9_999_999.99),
  itinerario: z.string().trim().max(4000).optional(),
  serviciosIncluidos: z.string().trim().max(4000).optional(),
  estado: z.enum(['borrador', 'activo', 'inactivo']),
})

/** El código se guarda en mayúsculas y sin espacios. */
export function normalizarCodigo(valor: string): string {
  return valor.trim().toUpperCase()
}

/** Fila de la tabla `paquete`. */
export interface FilaPaquete {
  idPaquete: number
  codigo: string
  nombre: string
  descripcion: string | null
  duracionDias: number
  precioBase: string
  itinerario: string | null
  serviciosIncluidos: string | null
  estado: string
  fechaActualizacion: Date
}

/** Convierte la fila de la base en lo que consume la interfaz. */
export function aPaqueteAdmin(fila: FilaPaquete): PaqueteAdmin {
  return {
    idPaquete: fila.idPaquete,
    codigo: fila.codigo,
    nombre: fila.nombre,
    descripcion: fila.descripcion,
    duracionDias: fila.duracionDias,
    precioBase: fila.precioBase,
    itinerario: fila.itinerario,
    serviciosIncluidos: fila.serviciosIncluidos,
    estado: fila.estado as EstadoPaquete,
    fechaActualizacion: fila.fechaActualizacion.toISOString(),
  }
}
