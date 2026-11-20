/**
 * Salidas programadas.
 *
 * La validación de negocio vive en `fn_crear_salida` y
 * `fn_actualizar_salida`; aquí solo se valida la forma del cuerpo y se
 * traduce la fila de la base a la interfaz.
 */
import { eq } from 'drizzle-orm'
import { z } from 'zod'
import * as schema from '../../db/schema'
import type { SalidaAdmin } from '#shared/types/api'
import type { EstadoSalida } from '#shared/types/domain'

const fecha = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'datos_invalidos')

/** Cuerpo del alta y de la edición de una salida. */
export const esquemaSalida = z
  .object({
    idPaquete: z.coerce.number().int().positive(),
    fechaSalida: fecha,
    fechaRetorno: fecha,
    cupoMaximo: z.coerce.number().int().min(1).max(32_767),
    precio: z.coerce.number().min(0.01).max(9_999_999.99),
    puntoEncuentro: z.string().trim().max(200).optional(),
    estado: z.enum(['programada', 'confirmada', 'realizada', 'cancelada']),
    observaciones: z.string().trim().max(1000).optional(),
    motivo: z.string().trim().max(200).optional(),
  })
  .refine((datos) => datos.fechaRetorno >= datos.fechaSalida, {
    message: 'fechas_invalidas',
    path: ['fechaRetorno'],
  })

/** Fecha local en formato ISO corto. */
export function hoyIso(): string {
  return new Date().toISOString().slice(0, 10)
}

/** Días inclusivos entre dos fechas ISO. */
export function diasInclusivos(desde: string, hasta: string): number {
  const inicio = Date.parse(`${desde}T00:00:00Z`)
  const fin = Date.parse(`${hasta}T00:00:00Z`)
  return Math.round((fin - inicio) / 86_400_000) + 1
}

/** Fila de la vista de salidas con el paquete resuelto. */
export interface FilaSalida {
  idSalida: number
  idPaquete: number
  codigoPaquete: string
  paquete: string
  fechaSalida: string
  fechaRetorno: string
  cupoMaximo: number
  precio: string
  puntoEncuentro: string | null
  estado: string
  observaciones: string | null
  fechaActualizacion: Date
}

/** Convierte la fila de la base en lo que consume la interfaz. */
export function aSalidaAdmin(fila: FilaSalida): SalidaAdmin {
  return {
    idSalida: fila.idSalida,
    idPaquete: fila.idPaquete,
    codigoPaquete: fila.codigoPaquete,
    paquete: fila.paquete,
    fechaSalida: fila.fechaSalida,
    fechaRetorno: fila.fechaRetorno,
    cupoMaximo: fila.cupoMaximo,
    precio: fila.precio,
    puntoEncuentro: fila.puntoEncuentro,
    estado: fila.estado as EstadoSalida,
    observaciones: fila.observaciones,
    fechaActualizacion: fila.fechaActualizacion.toISOString(),
  }
}

/** Devuelve una salida con su paquete, o `null` si no existe. */
export async function obtenerSalida(id: number): Promise<SalidaAdmin | null> {
  const [fila] = await useDb()
    .select({
      idSalida: schema.salida.idSalida,
      idPaquete: schema.salida.idPaquete,
      codigoPaquete: schema.paquete.codigo,
      paquete: schema.paquete.nombre,
      fechaSalida: schema.salida.fechaSalida,
      fechaRetorno: schema.salida.fechaRetorno,
      cupoMaximo: schema.salida.cupoMaximo,
      precio: schema.salida.precio,
      puntoEncuentro: schema.salida.puntoEncuentro,
      estado: schema.salida.estado,
      observaciones: schema.salida.observaciones,
      fechaActualizacion: schema.salida.fechaActualizacion,
    })
    .from(schema.salida)
    .innerJoin(schema.paquete, eq(schema.paquete.idPaquete, schema.salida.idPaquete))
    .where(eq(schema.salida.idSalida, id))
    .limit(1)

  return fila ? aSalidaAdmin(fila) : null
}

/**
 * Traduce una violación de la base a un código de la interfaz. Las
 * validaciones normales se hacen antes; esto cubre la carrera entre dos
 * peticiones simultáneas.
 */
export function codigoErrorSalida(error: unknown): string {
  const codigo = (error as { code?: string }).code
  if (codigo === '23505') return 'salida_duplicada'
  if (codigo === '23514') return 'datos_invalidos'
  if (codigo === 'P0002') return 'salida_inexistente'
  return 'datos_invalidos'
}
