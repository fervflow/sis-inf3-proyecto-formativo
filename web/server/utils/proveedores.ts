/**
 * Catálogo de proveedores y sus vínculos con los paquetes.
 *
 * Un proveedor puede atender varios paquetes y un paquete puede tener
 * varios proveedores. El vínculo no se repite y guarda el servicio y su
 * costo. El proveedor no se elimina: pasa a inactivo.
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

/** Cuerpo del alta y de la edición de un proveedor. */
export const esquemaProveedor = z.object({
  nombre: z.string().trim().min(3).max(150),
  tipo: z.enum(['transporte', 'hospedaje', 'guia', 'alimentacion', 'otro']),
  nit: z.string().trim().max(30).nullable().optional(),
  telefono: z.string().trim().max(30).nullable().optional(),
  correo: z.string().trim().max(150).nullable().optional(),
  direccion: z.string().trim().max(200).nullable().optional(),
  estado: z.enum(['activo', 'inactivo']).default('activo'),
})

/** Cuerpo del vínculo de un proveedor con un paquete. */
export const esquemaVinculo = z.object({
  idPaquete: z.coerce.number().int().positive(),
  servicio: z.string().trim().min(3).max(150),
  costo: z.coerce.number().min(0).max(9_999_999.99),
})

/** Fila de la tabla `proveedor`. */
interface FilaProveedor {
  idProveedor: number
  nombre: string
  tipo: string
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
  costo: string
}

/** Convierte una fila en la forma pública. */
function aProveedorAdmin(
  fila: FilaProveedor,
  paquetes: ProveedorPaquete[],
): ProveedorAdmin {
  return {
    idProveedor: fila.idProveedor,
    nombre: fila.nombre,
    tipo: fila.tipo as TipoProveedor,
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
      servicio: fila.servicio,
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
      tipo: schema.proveedor.tipo,
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

  return filas.map((fila) =>
    aProveedorAdmin(fila, vinculos.get(fila.idProveedor) ?? []),
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
      tipo: schema.proveedor.tipo,
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
  return aProveedorAdmin(fila, vinculos.get(id) ?? [])
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

  const [creado] = await useDb()
    .insert(schema.proveedor)
    .values({
      nombre: datos.nombre,
      tipo: datos.tipo,
      nit: datos.nit || null,
      telefono: datos.telefono || null,
      correo: datos.correo || null,
      direccion: datos.direccion || null,
      estado: datos.estado,
    })
    .returning({
      idProveedor: schema.proveedor.idProveedor,
      nombre: schema.proveedor.nombre,
      tipo: schema.proveedor.tipo,
      nit: schema.proveedor.nit,
      telefono: schema.proveedor.telefono,
      correo: schema.proveedor.correo,
      direccion: schema.proveedor.direccion,
      estado: schema.proveedor.estado,
    })

  if (!creado) {
    throw createError({ statusCode: 500, statusMessage: 'alta_incompleta' })
  }
  return aProveedorAdmin(creado, [])
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

  const [actualizado] = await useDb()
    .update(schema.proveedor)
    .set({
      nombre: datos.nombre,
      tipo: datos.tipo,
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
      tipo: schema.proveedor.tipo,
      nit: schema.proveedor.nit,
      telefono: schema.proveedor.telefono,
      correo: schema.proveedor.correo,
      direccion: schema.proveedor.direccion,
      estado: schema.proveedor.estado,
    })

  if (!actualizado) {
    throw createError({ statusCode: 404, statusMessage: 'proveedor_inexistente' })
  }
  return aProveedorAdmin(actualizado, actual.paquetes)
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
      costo: datos.costo.toFixed(2),
    })
    .onConflictDoUpdate({
      target: [
        schema.paqueteProveedor.idPaquete,
        schema.paqueteProveedor.idProveedor,
      ],
      set: {
        servicio: datos.servicio,
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
      tipo: schema.proveedor.tipo,
      servicio: schema.paqueteProveedor.servicio,
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
      servicio: fila.servicio,
      costo: fila.costo,
    })
    mapa.set(fila.idPaquete, lista)
  }
  return mapa
}
