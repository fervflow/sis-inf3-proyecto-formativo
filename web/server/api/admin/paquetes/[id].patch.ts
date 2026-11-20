import { and, eq, ne } from 'drizzle-orm'
import * as schema from '../../../../db/schema'
import type { PaqueteAdmin } from '#shared/types/api'
import type { EstadoPaquete } from '#shared/types/domain'
import { exigirAdmin } from '../../../utils/autorizacion'
import {
  aPaqueteAdmin,
  cargarActividades,
  esquemaPaquete,
  normalizarCodigo,
  reemplazarActividades,
  validarActividades,
  validarPaquetePublicable,
  validarTransicionPaquete,
} from '../../../utils/paquetes'
import { leerCuerpo } from '../../../utils/validacion'

/**
 * Edición de un paquete turístico.
 */
export default defineEventHandler(async (event): Promise<PaqueteAdmin> => {
  const sesion = exigirAdmin(event)
  const id = Number(getRouterParam(event, 'id'))

  if (!Number.isInteger(id) || id < 1) {
    throw createError({ statusCode: 400, statusMessage: 'datos_invalidos' })
  }

  const datos = await leerCuerpo(event, esquemaPaquete)
  validarPaquetePublicable(datos)

  const codigo = normalizarCodigo(datos.codigo)
  const db = useDb()

  const [actual] = await db
    .select({ estado: schema.paquete.estado })
    .from(schema.paquete)
    .where(eq(schema.paquete.idPaquete, id))
    .limit(1)

  if (!actual) {
    throw createError({ statusCode: 404, statusMessage: 'paquete_inexistente' })
  }

  validarTransicionPaquete(actual.estado as EstadoPaquete, datos.estado)

  const [existente] = await db
    .select({ idPaquete: schema.paquete.idPaquete })
    .from(schema.paquete)
    .where(
      and(
        eq(schema.paquete.codigo, codigo),
        ne(schema.paquete.idPaquete, id),
      ),
    )
    .limit(1)

  if (existente) {
    throw createError({ statusCode: 409, statusMessage: 'paquete_duplicado' })
  }

  await validarActividades(datos.actividades)

  const fila = await db.transaction(async (tx) => {
    const [actualizado] = await tx
      .update(schema.paquete)
      .set({
        codigo,
        nombre: datos.nombre,
        destino: datos.destino || null,
        descripcion: datos.descripcion || null,
        duracionDias: datos.duracionDias,
        precioBase: datos.precioBase.toFixed(2),
        itinerario: datos.itinerario || null,
        serviciosIncluidos: datos.serviciosIncluidos || null,
        estado: datos.estado,
        idUsuarioActualizacion: sesion.user.id,
        fechaActualizacion: new Date(),
      })
      .where(eq(schema.paquete.idPaquete, id))
      .returning()

    if (!actualizado) {
      throw createError({
        statusCode: 404,
        statusMessage: 'paquete_inexistente',
      })
    }

    await reemplazarActividades(tx, id, datos.actividades)
    return actualizado
  })

  const actividades = await cargarActividades([id])
  return aPaqueteAdmin(fila, actividades.get(id) ?? [])
})
