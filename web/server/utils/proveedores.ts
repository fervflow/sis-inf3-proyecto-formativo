/**
 * Catálogo de proveedores y sus vínculos con los paquetes.
 *
 * Un proveedor declara uno o varios tipos de servicio (RN-PRV-02) y el
 * vínculo con un paquete usa uno de los declarados, con un detalle
 * opcional y su costo (RN-PRV-06). El proveedor no se elimina: pasa a
 * inactivo.
 */
import { asc, eq, inArray, sql } from 'drizzle-orm'
import { z } from 'zod'
import * as schema from '../../db/schema'
import type {
  ProveedorAdmin,
  ProveedorPaquete,
  ProveedorPaqueteResumen,
} from '#shared/types/api'
import type { EstadoProveedor, TipoProveedor } from '#shared/types/domain'

const tiposValidos = [
  'transporte',
  'hospedaje',
  'guia',
  'alimentacion',
  'otro',
] as const

/** Cuerpo del alta y de la edición de un proveedor. */
export const esquemaProveedor = z.object({
  nombre: z.string().trim().min(3).max(150),
  // Uno o varios tipos declarados, sin repetir (RN-PRV-02).
  tipos: z
    .array(z.enum(tiposValidos))
    .min(1, 'tipos_faltantes')
    .max(tiposValidos.length)
    .refine((tipos) => new Set(tipos).size === tipos.length, {
      message: 'tipos_repetidos',
    }),
  nit: z.string().trim().max(30).nullable().optional(),
  telefono: z.string().trim().max(30).nullable().optional(),
  correo: z.string().trim().max(150).nullable().optional(),
  direccion: z.string().trim().max(200).nullable().optional(),
  estado: z.enum(['activo', 'inactivo']).default('activo'),
})

/** Cuerpo del vínculo de un proveedor con un paquete. */
export const esquemaVinculo = z.object({
  idPaquete: z.coerce.number().int().positive(),
  // Uno de los tipos declarados del proveedor (RN-PRV-06).
  servicio: z.enum(tiposValidos),
  detalle: z.string().trim().max(200).nullable().optional(),
  costo: z.coerce.number().min(0).max(9_999_999.99),
})

/** Fila de la tabla `proveedor`. */
interface FilaProveedor {
  idProveedor: number
  nombre: string
  nit: string | null
  telefono: string | null
  correo: string | null
  direccion: string | null
  estado: string
}

/** Fila del vínculo con el paquete resuelto. */
interface FilaVinculo {
  idProveedor: number
  idPaquete: number
  codigoPaquete: string
  paquete: string
  servicio: string
  detalle: string | null
  costo: string
}

/** Tipos declarados por cada proveedor de un conjunto. */
async function cargarTipos(
  idsProveedores: number[],
): Promise<Map<number, TipoProveedor[]>> {
  const mapa = new Map<number, TipoProveedor[]>()
  if (idsProveedores.length === 0) return mapa

  const filas = await useDb()
    .select({
      idProveedor: schema.proveedorTipo.idProveedor,
      tipo: schema.proveedorTipo.tipo,
    })
    .from(schema.proveedorTipo)
    .where(inArray(schema.proveedorTipo.idProveedor, idsProveedores))
    .orderBy(asc(schema.proveedorTipo.tipo))

  for (const fila of filas) {
    const lista = mapa.get(fila.idProveedor) ?? []
    lista.push(fila.tipo as TipoProveedor)
    mapa.set(fila.idProveedor, lista)
  }
  return mapa
}

/** Convierte una fila en la forma pública. */
function aProveedorAdmin(
  fila: FilaProveedor,
  tipos: TipoProveedor[],
  paquetes: ProveedorPaquete[],
): ProveedorAdmin {
  return {
    idProveedor: fila.idProveedor,
    nombre: fila.nombre,
    tipos,
    nit: fila.nit,
    telefono: fila.telefono,
    correo: fila.correo,
    direccion: fila.direccion,
    estado: fila.estado as EstadoProveedor,
    paquetes,
  }
}

/** Carga los vínculos de un conjunto de proveedores. */
async function cargarVinculos(
  idsProveedores: number[],
): Promise<Map<number, ProveedorPaquete[]>> {
  const mapa = new Map<number, ProveedorPaquete[]>()
  if (idsProveedores.length === 0) return mapa

  const filas = await useDb()
    .select({
      idProveedor: schema.paqueteProveedor.idProveedor,
      idPaquete: schema.paqueteProveedor.idPaquete,
      codigoPaquete: schema.paquete.codigo,
      paquete: schema.paquete.nombre,
      servicio: schema.paqueteProveedor.servicio,
      detalle: schema.paqueteProveedor.detalle,
      costo: schema.paqueteProveedor.costo,
    })
    .from(schema.paqueteProveedor)
    .innerJoin(
      schema.paquete,
      eq(schema.paquete.idPaquete, schema.paqueteProveedor.idPaquete),
    )
    .where(inArray(schema.paqueteProveedor.idProveedor, idsProveedores))
    .orderBy(asc(schema.paquete.codigo))

  for (const fila of filas) {
    const lista = mapa.get(fila.idProveedor) ?? []
    lista.push({
      idPaquete: fila.idPaquete,
      codigoPaquete: fila.codigoPaquete,
      paquete: fila.paquete,
      servicio: fila.servicio as TipoProveedor,
      detalle: fila.detalle,
      costo: fila.costo,
    })
    mapa.set(fila.idProveedor, lista)
  }
  return mapa
}

/** Catálogo completo de proveedores con sus paquetes. */
export async function listarProveedores(): Promise<ProveedorAdmin[]> {
  const filas = await useDb()
    .select({
      idProveedor: schema.proveedor.idProveedor,
      nombre: schema.proveedor.nombre,
      nit: schema.proveedor.nit,
      telefono: schema.proveedor.telefono,
      correo: schema.proveedor.correo,
      direccion: schema.proveedor.direccion,
      estado: schema.proveedor.estado,
    })
    .from(schema.proveedor)
    .orderBy(asc(schema.proveedor.nombre))

  const vinculos = await cargarVinculos(
    filas.map((fila) => fila.idProveedor),
  )
  const tipos = await cargarTipos(
    filas.map((fila) => fila.idProveedor),
  )

  return filas.map((fila) =>
    aProveedorAdmin(
      fila,
      tipos.get(fila.idProveedor) ?? [],
      vinculos.get(fila.idProveedor) ?? [],
    ),
  )
}

/** Un proveedor con sus paquetes, o `null` si no existe. */
export async function obtenerProveedor(
  id: number,
): Promise<ProveedorAdmin | null> {
  const [fila] = await useDb()
    .select({
      idProveedor: schema.proveedor.idProveedor,
      nombre: schema.proveedor.nombre,
      nit: schema.proveedor.nit,
      telefono: schema.proveedor.telefono,
      correo: schema.proveedor.correo,
      direccion: schema.proveedor.direccion,
      estado: schema.proveedor.estado,
    })
    .from(schema.proveedor)
    .where(eq(schema.proveedor.idProveedor, id))
    .limit(1)

  if (!fila) return null
  const vinculos = await cargarVinculos([id])
  const tipos = await cargarTipos([id])
  return aProveedorAdmin(fila, tipos.get(id) ?? [], vinculos.get(id) ?? [])
}

/** Comprueba que el nombre no esté usado por otro proveedor. */
async function validarNombreUnico(
  nombre: string,
  exceptoId?: number,
): Promise<void> {
  const [existente] = await useDb()
    .select({ idProveedor: schema.proveedor.idProveedor })
    .from(schema.proveedor)
    .where(
      exceptoId
        ? sql`lower(btrim(${schema.proveedor.nombre})) = lower(btrim(${nombre}))
              and ${schema.proveedor.idProveedor} <> ${exceptoId}`
        : sql`lower(btrim(${schema.proveedor.nombre})) = lower(btrim(${nombre}))`,
    )
    .limit(1)

  if (existente) {
    throw createError({
      statusCode: 409,
      statusMessage: 'proveedor_duplicado',
    })
  }
}

/** Alta de un proveedor. */
export async function crearProveedor(
  datos: z.infer<typeof esquemaProveedor>,
): Promise<ProveedorAdmin> {
  await validarNombreUnico(datos.nombre)

  const db = useDb()

  const [creado] = await db
    .insert(schema.proveedor)
    .values({
      nombre: datos.nombre,
      nit: datos.nit || null,
      telefono: datos.telefono || null,
      correo: datos.correo || null,
      direccion: datos.direccion || null,
      estado: datos.estado,
    })
    .returning({
      idProveedor: schema.proveedor.idProveedor,
      nombre: schema.proveedor.nombre,
      nit: schema.proveedor.nit,
      telefono: schema.proveedor.telefono,
      correo: schema.proveedor.correo,
      direccion: schema.proveedor.direccion,
      estado: schema.proveedor.estado,
    })

  if (!creado) {
    throw createError({ statusCode: 500, statusMessage: 'alta_incompleta' })
  }

  try {
    await db
      .insert(schema.proveedorTipo)
      .values(
        datos.tipos.map((tipo) => ({
          idProveedor: creado.idProveedor,
          tipo,
        })),
      )
  } catch (error) {
    // Sin tipos declarados el proveedor no sirve: se deshace el alta para
    // no dejar una fila a medias.
    await db
      .delete(schema.proveedor)
      .where(eq(schema.proveedor.idProveedor, creado.idProveedor))
    throw error
  }

  return aProveedorAdmin(creado, datos.tipos, [])
}

/** Edición de un proveedor. */
export async function actualizarProveedor(
  id: number,
  datos: z.infer<typeof esquemaProveedor>,
): Promise<ProveedorAdmin> {
  const actual = await obtenerProveedor(id)
  if (!actual) {
    throw createError({ statusCode: 404, statusMessage: 'proveedor_inexistente' })
  }

  await validarNombreUnico(datos.nombre, id)

  // Un tipo que está en uso por un vínculo no se puede retirar: primero
  // se quita o se cambia el vínculo.
  const retirados = actual.tipos.filter(
    (tipo) => !datos.tipos.includes(tipo),
  )
  if (retirados.length > 0) {
    const enUso = actual.paquetes
      .filter((vinculo) => retirados.includes(vinculo.servicio))
      .map((vinculo) => vinculo.codigoPaquete)
    if (enUso.length > 0) {
      throw createError({
        statusCode: 400,
        statusMessage: 'tipo_en_uso',
      })
    }
  }

  const db = useDb()

  const [actualizado] = await db
    .update(schema.proveedor)
    .set({
      nombre: datos.nombre,
      nit: datos.nit || null,
      telefono: datos.telefono || null,
      correo: datos.correo || null,
      direccion: datos.direccion || null,
      estado: datos.estado,
    })
    .where(eq(schema.proveedor.idProveedor, id))
    .returning({
      idProveedor: schema.proveedor.idProveedor,
      nombre: schema.proveedor.nombre,
      nit: schema.proveedor.nit,
      telefono: schema.proveedor.telefono,
      correo: schema.proveedor.correo,
      direccion: schema.proveedor.direccion,
      estado: schema.proveedor.estado,
    })

  if (!actualizado) {
    throw createError({ statusCode: 404, statusMessage: 'proveedor_inexistente' })
  }

  // Los tipos se reemplazan por completo: es la lista declarada.
  await db
    .delete(schema.proveedorTipo)
    .where(eq(schema.proveedorTipo.idProveedor, id))
  await db
    .insert(schema.proveedorTipo)
    .values(datos.tipos.map((tipo) => ({ idProveedor: id, tipo })))

  return aProveedorAdmin(actualizado, datos.tipos, actual.paquetes)
}

/** Vincula o actualiza el servicio de un proveedor en un paquete. */
export async function vincularPaquete(
  idProveedor: number,
  datos: z.infer<typeof esquemaVinculo>,
): Promise<ProveedorAdmin> {
  const proveedor = await obtenerProveedor(idProveedor)
  if (!proveedor) {
    throw createError({ statusCode: 404, statusMessage: 'proveedor_inexistente' })
  }
  if (proveedor.estado !== 'activo') {
    throw createError({ statusCode: 400, statusMessage: 'proveedor_inactivo' })
  }

  // Solo un tipo declarado puede usarse en el vínculo (RN-PRV-06); la FK
  // compuesta lo exige en la base y aquí se avisa con un código claro.
  if (!proveedor.tipos.includes(datos.servicio)) {
    throw createError({
      statusCode: 400,
      statusMessage: 'servicio_no_declarado',
    })
  }

  const [paquete] = await useDb()
    .select({ idPaquete: schema.paquete.idPaquete })
    .from(schema.paquete)
    .where(eq(schema.paquete.idPaquete, datos.idPaquete))
    .limit(1)

  if (!paquete) {
    throw createError({ statusCode: 404, statusMessage: 'paquete_inexistente' })
  }

  await useDb()
    .insert(schema.paqueteProveedor)
    .values({
      idPaquete: datos.idPaquete,
      idProveedor,
      servicio: datos.servicio,
      detalle: datos.detalle || null,
      costo: datos.costo.toFixed(2),
    })
    .onConflictDoUpdate({
      target: [
        schema.paqueteProveedor.idPaquete,
        schema.paqueteProveedor.idProveedor,
      ],
      set: {
        servicio: datos.servicio,
        detalle: datos.detalle || null,
        costo: datos.costo.toFixed(2),
      },
    })

  const actualizado = await obtenerProveedor(idProveedor)
  if (!actualizado) {
    throw createError({ statusCode: 500, statusMessage: 'datos_invalidos' })
  }
  return actualizado
}

/** Quita el vínculo de un proveedor con un paquete. */
export async function desvincularPaquete(
  idProveedor: number,
  idPaquete: number,
): Promise<ProveedorAdmin> {
  const proveedor = await obtenerProveedor(idProveedor)
  if (!proveedor) {
    throw createError({ statusCode: 404, statusMessage: 'proveedor_inexistente' })
  }

  await useDb()
    .delete(schema.paqueteProveedor)
    .where(
      sql`${schema.paqueteProveedor.idProveedor} = ${idProveedor}
          and ${schema.paqueteProveedor.idPaquete} = ${idPaquete}`,
    )

  const actualizado = await obtenerProveedor(idProveedor)
  if (!actualizado) {
    throw createError({ statusCode: 500, statusMessage: 'datos_invalidos' })
  }
  return actualizado
}

/** Proveedores de varios paquetes, para la ficha del paquete. */
export async function cargarProveedoresDePaquetes(
  idsPaquetes: number[],
): Promise<Map<number, ProveedorPaqueteResumen[]>> {
  const mapa = new Map<number, ProveedorPaqueteResumen[]>()
  if (idsPaquetes.length === 0) return mapa

  const filas = await useDb()
    .select({
      idPaquete: schema.paqueteProveedor.idPaquete,
      idProveedor: schema.proveedor.idProveedor,
      nombre: schema.proveedor.nombre,
      tipo: schema.paqueteProveedor.servicio,
      detalle: schema.paqueteProveedor.detalle,
      costo: schema.paqueteProveedor.costo,
    })
    .from(schema.paqueteProveedor)
    .innerJoin(
      schema.proveedor,
      eq(schema.proveedor.idProveedor, schema.paqueteProveedor.idProveedor),
    )
    .where(inArray(schema.paqueteProveedor.idPaquete, idsPaquetes))
    .orderBy(asc(schema.proveedor.nombre))

  for (const fila of filas) {
    const lista = mapa.get(fila.idPaquete) ?? []
    lista.push({
      idProveedor: fila.idProveedor,
      nombre: fila.nombre,
      tipo: fila.tipo as TipoProveedor,
      detalle: fila.detalle,
      costo: fila.costo,
    })
    mapa.set(fila.idPaquete, lista)
  }
  return mapa
}
