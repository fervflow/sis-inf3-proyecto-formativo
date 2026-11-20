/**
 * Paquetes turísticos, lugares y servicios.
 *
 * La validación y la forma de la respuesta se comparten entre el alta y
 * la edición, para que las dos acepten exactamente lo mismo. Las reglas
 * están en `sistema/reglas-negocio.md`.
 */
import { and, asc, eq, inArray, sql } from 'drizzle-orm'
import type { NodePgDatabase } from 'drizzle-orm/node-postgres'
import { z } from 'zod'
import * as schema from '../../db/schema'
import type {
  LugarResumen,
  PaqueteAdmin,
  ServicioResumen,
} from '#shared/types/api'
import type { EstadoPaquete, TipoLugar, TipoRecorrido } from '#shared/types/domain'
import { consultar } from './db'

type BaseDatos = NodePgDatabase<typeof schema>
type Transaccion = Parameters<Parameters<BaseDatos['transaction']>[0]>[0]

/** Un identificador de lugar opcional. */
const idLugar = z.coerce.number().int().positive().nullable().optional()

/** Cuerpo del alta y de la edición de un paquete. */
export const esquemaPaquete = z
  .object({
    nombre: z.string().trim().min(3).max(150),
    idLugarDestino: idLugar,
    idLugarOrigen: idLugar,
    tipoRecorrido: z.enum(['sencillo', 'circuito']).default('sencillo'),
    descripcion: z.string().trim().max(2000).nullable().optional(),
    duracionDias: z.coerce.number().int().min(1).max(365),
    precioBase: z.coerce.number().min(0.01).max(9_999_999.99),
    itinerario: z.string().trim().max(4000).nullable().optional(),
    serviciosDetalle: z.string().trim().max(2000).nullable().optional(),
    serviciosExcluidos: z.string().trim().max(2000).nullable().optional(),
    paradas: z.array(z.coerce.number().int().positive()).max(20).default([]),
    servicios: z.array(z.coerce.number().int().positive()).max(50).default([]),
    estado: z.enum(['borrador', 'activo', 'inactivo']),
  })
  .superRefine((datos, contexto) => {
    if (datos.tipoRecorrido === 'circuito' && !datos.idLugarOrigen) {
      contexto.addIssue({
        code: 'custom',
        path: ['idLugarOrigen'],
        message: 'origen_requerido',
      })
    }
  })

/**
 * Un paquete publicado necesita el contenido mínimo que el cliente
 * consulta antes de comprar. El borrador puede quedar incompleto.
 */
export function validarPaquetePublicable(datos: {
  estado: EstadoPaquete
  idLugarDestino?: number | null
  descripcion?: string | null
  itinerario?: string | null
  servicios: number[]
}): void {
  if (datos.estado !== 'activo') return

  const faltantes: string[] = []
  if (!datos.idLugarDestino) faltantes.push('destino')
  if (!datos.descripcion?.trim()) faltantes.push('descripcion')
  if (!datos.itinerario?.trim()) faltantes.push('itinerario')
  if (datos.servicios.length === 0) faltantes.push('servicios')

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
  idLugarDestino: number | null
  idLugarOrigen: number | null
  tipoRecorrido: string
  descripcion: string | null
  duracionDias: number
  precioBase: string
  itinerario: string | null
  serviciosDetalle: string | null
  serviciosExcluidos: string | null
  estado: string
  fechaActualizacion: Date
}

/** Fila de la tabla `lugar`, con los campos que usa la interfaz. */
interface FilaLugar {
  idLugar: number
  codigo: string
  nombre: string
  tipo: string
  direccion: string | null
  latitud: string | null
  longitud: string | null
}

/** Convierte un lugar de la base en su forma pública. */
function aLugarResumen(fila: FilaLugar): LugarResumen {
  return {
    idLugar: fila.idLugar,
    codigo: fila.codigo,
    nombre: fila.nombre,
    tipo: fila.tipo as TipoLugar,
    direccion: fila.direccion,
    latitud: fila.latitud === null ? null : Number(fila.latitud),
    longitud: fila.longitud === null ? null : Number(fila.longitud),
  }
}

/** Convierte la fila de la base en lo que consume la interfaz. */
export function aPaqueteAdmin(
  fila: FilaPaquete,
  destino: LugarResumen | null,
  origen: LugarResumen | null,
  paradas: LugarResumen[],
  servicios: ServicioResumen[],
): PaqueteAdmin {
  return {
    idPaquete: fila.idPaquete,
    codigo: fila.codigo,
    nombre: fila.nombre,
    destino,
    origen,
    paradas,
    tipoRecorrido: fila.tipoRecorrido as TipoRecorrido,
    descripcion: fila.descripcion,
    duracionDias: fila.duracionDias,
    precioBase: fila.precioBase,
    itinerario: fila.itinerario,
    serviciosDetalle: fila.serviciosDetalle,
    serviciosExcluidos: fila.serviciosExcluidos,
    servicios,
    estado: fila.estado as EstadoPaquete,
    fechaActualizacion: fila.fechaActualizacion.toISOString(),
  }
}

/** Carga lugares por identificador, en un solo viaje a la base. */
export async function cargarLugares(
  ids: number[],
): Promise<Map<number, LugarResumen>> {
  const mapa = new Map<number, LugarResumen>()
  const unicos = [...new Set(ids)]
  if (unicos.length === 0) return mapa

  const filas = await useDb()
    .select({
      idLugar: schema.lugar.idLugar,
      codigo: schema.lugar.codigo,
      nombre: schema.lugar.nombre,
      tipo: schema.lugar.tipo,
      direccion: schema.lugar.direccion,
      latitud: schema.lugar.latitud,
      longitud: schema.lugar.longitud,
    })
    .from(schema.lugar)
    .where(inArray(schema.lugar.idLugar, unicos))

  for (const fila of filas) {
    mapa.set(fila.idLugar, aLugarResumen(fila))
  }
  return mapa
}

/** Paradas de un conjunto de paquetes, agrupadas y ordenadas. */
export async function cargarParadas(
  idsPaquetes: number[],
): Promise<Map<number, LugarResumen[]>> {
  const mapa = new Map<number, LugarResumen[]>()
  if (idsPaquetes.length === 0) return mapa

  const filas = await useDb()
    .select({
      idPaquete: schema.paqueteParada.idPaquete,
      idLugar: schema.lugar.idLugar,
      codigo: schema.lugar.codigo,
      nombre: schema.lugar.nombre,
      tipo: schema.lugar.tipo,
      direccion: schema.lugar.direccion,
      latitud: schema.lugar.latitud,
      longitud: schema.lugar.longitud,
    })
    .from(schema.paqueteParada)
    .innerJoin(schema.lugar, eq(schema.lugar.idLugar, schema.paqueteParada.idLugar))
    .where(inArray(schema.paqueteParada.idPaquete, idsPaquetes))
    .orderBy(asc(schema.paqueteParada.idPaquete), asc(schema.paqueteParada.orden))

  for (const fila of filas) {
    const lista = mapa.get(fila.idPaquete) ?? []
    lista.push(aLugarResumen(fila))
    mapa.set(fila.idPaquete, lista)
  }
  return mapa
}

/** Catálogo completo de servicios, ordenado para la interfaz. */
export async function listarServicios(): Promise<ServicioResumen[]> {
  const filas = await useDb()
    .select({
      idServicio: schema.servicio.idServicio,
      codigo: schema.servicio.codigo,
      nombre: schema.servicio.nombre,
      orden: schema.servicio.orden,
    })
    .from(schema.servicio)
    .where(eq(schema.servicio.activo, true))
    .orderBy(asc(schema.servicio.orden), asc(schema.servicio.nombre))

  return filas
}

/** Servicios marcados, agrupados por paquete. */
export async function cargarServicios(
  idsPaquetes: number[],
): Promise<Map<number, ServicioResumen[]>> {
  const mapa = new Map<number, ServicioResumen[]>()
  if (idsPaquetes.length === 0) return mapa

  const filas = await useDb()
    .select({
      idPaquete: schema.paqueteServicio.idPaquete,
      idServicio: schema.servicio.idServicio,
      codigo: schema.servicio.codigo,
      nombre: schema.servicio.nombre,
      orden: schema.servicio.orden,
    })
    .from(schema.paqueteServicio)
    .innerJoin(
      schema.servicio,
      eq(schema.servicio.idServicio, schema.paqueteServicio.idServicio),
    )
    .where(inArray(schema.paqueteServicio.idPaquete, idsPaquetes))
    .orderBy(asc(schema.servicio.orden), asc(schema.servicio.nombre))

  for (const fila of filas) {
    const lista = mapa.get(fila.idPaquete) ?? []
    lista.push({
      idServicio: fila.idServicio,
      codigo: fila.codigo,
      nombre: fila.nombre,
      orden: fila.orden,
    })
    mapa.set(fila.idPaquete, lista)
  }
  return mapa
}

/** Comprueba que los lugares existan y estén activos. */
export async function validarLugares(ids: number[]): Promise<void> {
  const unicos = [...new Set(ids.filter((id) => Number.isInteger(id) && id > 0))]
  if (unicos.length === 0) return

  const filas = await useDb()
    .select({ idLugar: schema.lugar.idLugar })
    .from(schema.lugar)
    .where(
      and(
        inArray(schema.lugar.idLugar, unicos),
        eq(schema.lugar.activo, true),
      ),
    )

  if (filas.length !== unicos.length) {
    throw createError({ statusCode: 400, statusMessage: 'lugar_invalido' })
  }
}

/** Comprueba que los servicios existan y estén activos. */
export async function validarServicios(ids: number[]): Promise<void> {
  const unicos = [...new Set(ids.filter((id) => Number.isInteger(id) && id > 0))]
  if (unicos.length === 0) return

  const filas = await useDb()
    .select({ idServicio: schema.servicio.idServicio })
    .from(schema.servicio)
    .where(
      and(
        inArray(schema.servicio.idServicio, unicos),
        eq(schema.servicio.activo, true),
      ),
    )

  if (filas.length !== unicos.length) {
    throw createError({ statusCode: 400, statusMessage: 'servicio_invalido' })
  }
}

/** Reemplaza las paradas de un paquete dentro de una transacción. */
export async function reemplazarParadas(
  tx: Transaccion,
  idPaquete: number,
  ids: number[],
): Promise<void> {
  await tx
    .delete(schema.paqueteParada)
    .where(eq(schema.paqueteParada.idPaquete, idPaquete))

  const unicos = [...new Set(ids)]
  if (unicos.length === 0) return

  await tx.insert(schema.paqueteParada).values(
    unicos.map((idLugar, indice) => ({
      idPaquete,
      idLugar,
      orden: indice + 1,
    })),
  )
}

/** Reemplaza los servicios de un paquete dentro de una transacción. */
export async function reemplazarServicios(
  tx: Transaccion,
  idPaquete: number,
  ids: number[],
): Promise<void> {
  await tx
    .delete(schema.paqueteServicio)
    .where(eq(schema.paqueteServicio.idPaquete, idPaquete))

  const unicos = [...new Set(ids)]
  if (unicos.length === 0) return

  await tx
    .insert(schema.paqueteServicio)
    .values(unicos.map((idServicio) => ({ idPaquete, idServicio })))
}

/** Prefijo de tres letras derivado de un nombre, para el código. */
export function prefijoDesdeNombre(nombre: string): string {
  const limpio = nombre
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^A-Za-z0-9]/g, '')
    .toUpperCase()

  return limpio.slice(0, 3).padEnd(3, 'X') || 'PKG'
}

/**
 * Genera el código del paquete con la función de la base. El prefijo sale
 * del destino principal o, si el borrador todavía no lo tiene, del nombre.
 */
export async function generarCodigoPaquete(
  idLugarDestino: number | null | undefined,
  nombre: string,
): Promise<string> {
  let prefijo = prefijoDesdeNombre(nombre)

  if (idLugarDestino) {
    const [fila] = await useDb()
      .select({ codigo: schema.lugar.codigo })
      .from(schema.lugar)
      .where(eq(schema.lugar.idLugar, idLugarDestino))
      .limit(1)
    if (fila) prefijo = fila.codigo
  }

  const [fila] = await consultar<{ codigo: string }>(
    sql`select turismo.fn_generar_codigo_paquete(${prefijo}) as codigo`,
  )

  if (!fila?.codigo) {
    throw createError({ statusCode: 500, statusMessage: 'codigo_no_generado' })
  }
  return fila.codigo
}
