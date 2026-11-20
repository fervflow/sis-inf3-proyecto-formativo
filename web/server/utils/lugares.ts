/**
 * Catálogo de lugares y búsqueda geográfica.
 *
 * El catálogo es la fuente de los destinos, orígenes y paradas de un
 * paquete. La búsqueda externa usa Photon (OpenStreetMap): no necesita
 * clave y permite autocompletar. La aplicación guarda el lugar en el
 * catálogo para que el paquete no dependa de un servicio externo.
 */
import { and, asc, eq, ilike, or, sql } from 'drizzle-orm'
import { z } from 'zod'
import * as schema from '../../db/schema'
import type {
  LugarResumen,
  ResultadoGeocodificacion,
} from '#shared/types/api'
import type { TipoLugar } from '#shared/types/domain'

/** Tipos admitidos por `lugar.tipo`. */
export const TIPOS_LUGAR: TipoLugar[] = [
  'ciudad',
  'atractivo',
  'terminal',
  'hospedaje',
  'otro',
]

/** Cuerpo del alta de un lugar. */
export const esquemaLugar = z
  .object({
    nombre: z.string().trim().min(2).max(150),
    codigo: z
      .string()
      .trim()
      .min(2)
      .max(6)
      .regex(/^[A-Za-z0-9]+$/, 'codigo_invalido')
      .optional(),
    tipo: z.enum(['ciudad', 'atractivo', 'terminal', 'hospedaje', 'otro']).default('otro'),
    direccion: z.string().trim().max(200).optional(),
    latitud: z.coerce.number().min(-90).max(90).nullable().optional(),
    longitud: z.coerce.number().min(-180).max(180).nullable().optional(),
    osmTipo: z.string().trim().max(2).nullable().optional(),
    osmId: z.coerce.number().int().nullable().optional(),
  })
  .refine(
    (datos) =>
      (datos.latitud === undefined || datos.latitud === null) ===
      (datos.longitud === undefined || datos.longitud === null),
    { message: 'coordenadas_incompletas', path: ['latitud'] },
  )

/** Fila de `lugar` con los campos que usa la interfaz. */
interface FilaLugar {
  idLugar: number
  codigo: string
  nombre: string
  tipo: string
  direccion: string | null
  latitud: string | null
  longitud: string | null
}

/** Convierte una fila de `lugar` en su forma pública. */
export function aLugarResumen(fila: FilaLugar): LugarResumen {
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

/** Campos que se seleccionan de `lugar`. */
const CAMPOS_LUGAR = {
  idLugar: schema.lugar.idLugar,
  codigo: schema.lugar.codigo,
  nombre: schema.lugar.nombre,
  tipo: schema.lugar.tipo,
  direccion: schema.lugar.direccion,
  latitud: schema.lugar.latitud,
  longitud: schema.lugar.longitud,
}

/** Busca en el catálogo por nombre o código. */
export async function listarLugares(q?: string): Promise<LugarResumen[]> {
  const texto = q?.trim()

  const filas = await useDb()
    .select(CAMPOS_LUGAR)
    .from(schema.lugar)
    .where(
      texto
        ? and(
            eq(schema.lugar.activo, true),
            or(
              ilike(schema.lugar.nombre, `%${texto}%`),
              ilike(schema.lugar.codigo, `%${texto}%`),
            ),
          )
        : eq(schema.lugar.activo, true),
    )
    .orderBy(asc(schema.lugar.nombre))
    .limit(100)

  return filas.map(aLugarResumen)
}

/** Código corto y único derivado del nombre. */
async function codigoDisponible(nombre: string): Promise<string> {
  const base =
    nombre
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^A-Za-z0-9]/g, '')
      .toUpperCase()
      .slice(0, 3)
      .padEnd(3, 'X') || 'LUG'

  let codigo = base
  let numero = 1

  while (true) {
    const [existente] = await useDb()
      .select({ idLugar: schema.lugar.idLugar })
      .from(schema.lugar)
      .where(eq(schema.lugar.codigo, codigo))
      .limit(1)

    if (!existente) return codigo

    numero += 1
    codigo = `${base}${numero}`
  }
}

/**
 * Crea un lugar o devuelve el existente. La identidad se resuelve por el
 * identificador de OpenStreetMap y, si no hay, por el nombre normalizado.
 */
export async function crearLugar(
  datos: z.infer<typeof esquemaLugar>,
): Promise<LugarResumen> {
  const db = useDb()

  if (datos.osmTipo && datos.osmId) {
    const [porOsm] = await db
      .select(CAMPOS_LUGAR)
      .from(schema.lugar)
      .where(
        and(
          eq(schema.lugar.osmTipo, datos.osmTipo),
          eq(schema.lugar.osmId, datos.osmId),
        ),
      )
      .limit(1)

    if (porOsm) return aLugarResumen(porOsm)
  }

  const [porNombre] = await db
    .select(CAMPOS_LUGAR)
    .from(schema.lugar)
    .where(sql`lower(btrim(${schema.lugar.nombre})) = lower(btrim(${datos.nombre}))`)
    .limit(1)

  if (porNombre) {
    // Si el lugar ya existía sin coordenadas, la búsqueda las completa.
    if (datos.latitud !== null && datos.latitud !== undefined) {
      const [actualizado] = await db
        .update(schema.lugar)
        .set({
          direccion: datos.direccion ?? porNombre.direccion,
          latitud: datos.latitud.toFixed(6),
          longitud: datos.longitud?.toFixed(6) ?? null,
          osmTipo: datos.osmTipo ?? null,
          osmId: datos.osmId ?? null,
          tipo:
            porNombre.tipo === 'otro' && datos.tipo !== 'otro'
              ? datos.tipo
              : porNombre.tipo,
        })
        .where(eq(schema.lugar.idLugar, porNombre.idLugar))
        .returning(CAMPOS_LUGAR)

      if (actualizado) return aLugarResumen(actualizado)
    }

    return aLugarResumen(porNombre)
  }

  const codigo = datos.codigo
    ? datos.codigo.toUpperCase()
    : await codigoDisponible(datos.nombre)

  const [creado] = await db
    .insert(schema.lugar)
    .values({
      codigo,
      nombre: datos.nombre,
      tipo: datos.tipo,
      direccion: datos.direccion || null,
      latitud:
        datos.latitud === undefined || datos.latitud === null
          ? null
          : datos.latitud.toFixed(6),
      longitud:
        datos.longitud === undefined || datos.longitud === null
          ? null
          : datos.longitud.toFixed(6),
      osmTipo: datos.osmTipo || null,
      osmId: datos.osmId ?? null,
    })
    .returning(CAMPOS_LUGAR)

  if (!creado) {
    throw createError({ statusCode: 500, statusMessage: 'lugar_no_creado' })
  }
  return aLugarResumen(creado)
}

// --- Búsqueda externa (Photon) -----------------------------------------

interface PropiedadesPhoton {
  name?: string
  street?: string
  housenumber?: string
  city?: string
  district?: string
  state?: string
  country?: string
  countrycode?: string
  osm_type?: string
  osm_id?: number
  osm_key?: string
  osm_value?: string
}

interface RespuestaPhoton {
  features?: Array<{
    geometry?: { coordinates?: [number, number] }
    properties?: PropiedadesPhoton
  }>
}

/** Traduce la clasificación de OpenStreetMap a un tipo del catálogo. */
function inferirTipo(propiedades: PropiedadesPhoton): TipoLugar {
  if (propiedades.osm_key === 'place') return 'ciudad'
  if (propiedades.osm_key === 'aeroway') return 'terminal'
  if (
    propiedades.osm_key === 'amenity' &&
    ['bus_station', 'taxi', 'ferry_terminal'].includes(propiedades.osm_value ?? '')
  ) {
    return 'terminal'
  }
  if (
    propiedades.osm_key === 'tourism' &&
    ['hotel', 'guest_house', 'hostel', 'motel', 'apartment'].includes(
      propiedades.osm_value ?? '',
    )
  ) {
    return 'hospedaje'
  }
  if (
    propiedades.osm_key === 'tourism' &&
    ['attraction', 'viewpoint', 'museum', 'artwork'].includes(
      propiedades.osm_value ?? '',
    )
  ) {
    return 'atractivo'
  }
  return 'otro'
}

/** Compone una dirección legible con los datos de Photon. */
function componerDireccion(propiedades: PropiedadesPhoton): string | null {
  const partes = [
    [propiedades.street, propiedades.housenumber].filter(Boolean).join(' '),
    propiedades.city ?? propiedades.district,
    propiedades.state,
    propiedades.country,
  ].filter((parte) => Boolean(parte && String(parte).trim()))

  return partes.length > 0 ? partes.join(', ') : null
}

const CACHE_BUSQUEDA = new Map<
  string,
  { resultados: ResultadoGeocodificacion[]; expira: number }
>()
const DURACION_CACHE = 5 * 60 * 1000

/**
 * Busca lugares en Photon. Se sesga la búsqueda a Potosí y se descartan
 * los resultados sin coordenadas. La respuesta se cachea en memoria.
 */
export async function geocodificar(
  q: string,
): Promise<ResultadoGeocodificacion[]> {
  const consulta = q.trim()
  if (consulta.length < 3) return []

  const enCache = CACHE_BUSQUEDA.get(consulta.toLowerCase())
  if (enCache && enCache.expira > Date.now()) {
    return enCache.resultados
  }

  let respuesta: RespuestaPhoton
  try {
    respuesta = await $fetch<RespuestaPhoton>(
      'https://photon.komoot.io/api/',
      {
        query: {
          q: consulta,
          limit: 8,
          lat: -19.5836,
          lon: -65.7531,
        },
        headers: {
          'User-Agent':
            'VizcachaTours/1.0 (proyecto formativo UPDS; contacto@vizcacha.tours)',
        },
        timeout: 6000,
      },
    )
  } catch {
    return []
  }

  const resultados: ResultadoGeocodificacion[] = []
  const vistos = new Set<string>()

  for (const feature of respuesta.features ?? []) {
    const coordenadas = feature.geometry?.coordinates
    const propiedades = feature.properties
    if (!coordenadas || !propiedades) continue

    const [longitud, latitud] = coordenadas
    if (typeof latitud !== 'number' || typeof longitud !== 'number') continue

    const nombre =
      propiedades.name?.trim() ||
      [propiedades.street, propiedades.housenumber].filter(Boolean).join(' ') ||
      propiedades.city ||
      consulta

    const clave = `${propiedades.osm_type ?? ''}-${propiedades.osm_id ?? ''}-${nombre}`
    if (vistos.has(clave)) continue
    vistos.add(clave)

    resultados.push({
      nombre,
      direccion: componerDireccion(propiedades),
      latitud,
      longitud,
      osmTipo: propiedades.osm_type ?? null,
      osmId: propiedades.osm_id ?? null,
      tipo: inferirTipo(propiedades),
    })
  }

  if (resultados.length > 0) {
    CACHE_BUSQUEDA.set(consulta.toLowerCase(), {
      resultados,
      expira: Date.now() + DURACION_CACHE,
    })
  }

  return resultados
}
