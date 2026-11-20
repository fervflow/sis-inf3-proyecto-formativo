/**
 * Paquetes turísticos.
 *
 * La validación y la forma de la respuesta se comparten entre el alta y
 * la edición, para que las dos acepten exactamente lo mismo. Las reglas
 * están en `sistema/reglas-negocio.md`.
 */
import { and, asc, eq, inArray } from 'drizzle-orm'
import type { NodePgDatabase } from 'drizzle-orm/node-postgres'
import { z } from 'zod'
import * as schema from '../../db/schema'
import type { ActividadResumen, PaqueteAdmin } from '#shared/types/api'
import type { EstadoPaquete } from '#shared/types/domain'

type BaseDatos = NodePgDatabase<typeof schema>
type Transaccion = Parameters<Parameters<BaseDatos['transaction']>[0]>[0]

/** Cuerpo del alta y de la edición de un paquete. */
export const esquemaPaquete = z.object({
  codigo: z
    .string()
    .trim()
    .min(3)
    .max(20)
    .regex(/^[A-Za-z0-9-]+$/, 'codigo_invalido'),
  nombre: z.string().trim().min(3).max(150),
  destino: z.string().trim().max(150).optional(),
  descripcion: z.string().trim().max(2000).optional(),
  duracionDias: z.coerce.number().int().min(1).max(365),
  precioBase: z.coerce.number().min(0.01).max(9_999_999.99),
  itinerario: z.string().trim().max(4000).optional(),
  serviciosIncluidos: z.string().trim().max(4000).optional(),
  actividades: z.array(z.coerce.number().int().positive()).max(50).default([]),
  estado: z.enum(['borrador', 'activo', 'inactivo']),
})

/** El código se guarda en mayúsculas y sin espacios. */
export function normalizarCodigo(valor: string): string {
  return valor.trim().toUpperCase()
}

/**
 * Un paquete publicado necesita el contenido mínimo que el cliente
 * consulta antes de comprar. El borrador puede quedar incompleto.
 */
export function validarPaquetePublicable(datos: {
  estado: EstadoPaquete
  destino?: string
  descripcion?: string
  itinerario?: string
  serviciosIncluidos?: string
}): void {
  if (datos.estado !== 'activo') return

  const faltantes: string[] = []
  if (!datos.destino?.trim()) faltantes.push('destino')
  if (!datos.descripcion?.trim()) faltantes.push('descripcion')
  if (!datos.itinerario?.trim()) faltantes.push('itinerario')
  if (!datos.serviciosIncluidos?.trim()) faltantes.push('serviciosIncluidos')

  if (faltantes.length > 0) {
    throw createError({
      statusCode: 400,
      statusMessage: 'paquete_incompleto',
      data: { campos: faltantes },
    })
  }
}

/** Transiciones válidas del estado de un paquete. */
export function validarTransicionPaquete(
  actual: EstadoPaquete,
  nuevo: EstadoPaquete,
): void {
  if (actual === nuevo) return

  const permitidas: Record<EstadoPaquete, EstadoPaquete[]> = {
    borrador: ['activo', 'inactivo'],
    activo: ['inactivo'],
    inactivo: ['activo'],
  }

  if (!permitidas[actual].includes(nuevo)) {
    throw createError({
      statusCode: 400,
      statusMessage: 'transicion_invalida',
      data: { actual, nuevo },
    })
  }
}

/** Fila de la tabla `paquete`. */
export interface FilaPaquete {
  idPaquete: number
  codigo: string
  nombre: string
  destino: string | null
  descripcion: string | null
  duracionDias: number
  precioBase: string
  itinerario: string | null
  serviciosIncluidos: string | null
  estado: string
  fechaActualizacion: Date
}

/** Convierte la fila de la base en lo que consume la interfaz. */
export function aPaqueteAdmin(
  fila: FilaPaquete,
  actividades: ActividadResumen[] = [],
): PaqueteAdmin {
  return {
    idPaquete: fila.idPaquete,
    codigo: fila.codigo,
    nombre: fila.nombre,
    destino: fila.destino,
    descripcion: fila.descripcion,
    duracionDias: fila.duracionDias,
    precioBase: fila.precioBase,
    itinerario: fila.itinerario,
    serviciosIncluidos: fila.serviciosIncluidos,
    actividades,
    estado: fila.estado as EstadoPaquete,
    fechaActualizacion: fila.fechaActualizacion.toISOString(),
  }
}

/** Catálogo completo de actividades, ordenado para la interfaz. */
export async function listarActividades(): Promise<ActividadResumen[]> {
  const filas = await useDb()
    .select({
      idActividad: schema.actividad.idActividad,
      codigo: schema.actividad.codigo,
      nombre: schema.actividad.nombre,
      orden: schema.actividad.orden,
    })
    .from(schema.actividad)
    .where(eq(schema.actividad.activo, true))
    .orderBy(asc(schema.actividad.orden), asc(schema.actividad.nombre))

  return filas
}

/** Actividades marcadas, agrupadas por paquete. */
export async function cargarActividades(
  idsPaquetes: number[],
): Promise<Map<number, ActividadResumen[]>> {
  const mapa = new Map<number, ActividadResumen[]>()
  if (idsPaquetes.length === 0) return mapa

  const filas = await useDb()
    .select({
      idPaquete: schema.paqueteActividad.idPaquete,
      idActividad: schema.actividad.idActividad,
      codigo: schema.actividad.codigo,
      nombre: schema.actividad.nombre,
      orden: schema.actividad.orden,
    })
    .from(schema.paqueteActividad)
    .innerJoin(
      schema.actividad,
      eq(schema.actividad.idActividad, schema.paqueteActividad.idActividad),
    )
    .where(inArray(schema.paqueteActividad.idPaquete, idsPaquetes))
    .orderBy(asc(schema.actividad.orden), asc(schema.actividad.nombre))

  for (const fila of filas) {
    const lista = mapa.get(fila.idPaquete) ?? []
    lista.push({
      idActividad: fila.idActividad,
      codigo: fila.codigo,
      nombre: fila.nombre,
      orden: fila.orden,
    })
    mapa.set(fila.idPaquete, lista)
  }

  return mapa
}

/** Comprueba que las actividades existan y estén activas. */
export async function validarActividades(ids: number[]): Promise<void> {
  if (ids.length === 0) return

  const unicas = [...new Set(ids)]
  const filas = await useDb()
    .select({ idActividad: schema.actividad.idActividad })
    .from(schema.actividad)
    .where(
      and(
        inArray(schema.actividad.idActividad, unicas),
        eq(schema.actividad.activo, true),
      ),
    )

  if (filas.length !== unicas.length) {
    throw createError({
      statusCode: 400,
      statusMessage: 'actividad_invalida',
    })
  }
}

/** Reemplaza las actividades de un paquete dentro de una transacción. */
export async function reemplazarActividades(
  tx: Transaccion,
  idPaquete: number,
  ids: number[],
): Promise<void> {
  await tx
    .delete(schema.paqueteActividad)
    .where(eq(schema.paqueteActividad.idPaquete, idPaquete))

  if (ids.length === 0) return

  await tx.insert(schema.paqueteActividad).values(
    [...new Set(ids)].map((idActividad) => ({ idPaquete, idActividad })),
  )
}
