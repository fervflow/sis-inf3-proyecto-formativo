import { eq } from 'drizzle-orm'
import * as schema from '../../../../db/schema'
import type { PaqueteAdmin } from '#shared/types/api'
import type { EstadoPaquete } from '#shared/types/domain'
import { exigirAdmin } from '../../../utils/autorizacion'
import {
  aPaqueteAdmin,
  cargarLugares,
  cargarParadas,
  cargarServicios,
  esquemaPaquete,
  reemplazarParadas,
  reemplazarServicios,
  validarLugares,
  validarPaquetePublicable,
  validarServicios,
  validarTransicionPaquete,
} from '../../../utils/paquetes'
import { leerCuerpo } from '../../../utils/validacion'
import { cargarProveedoresDePaquetes } from '../../../utils/proveedores'

/**
 * Edición de un paquete turístico. El código no cambia.
 */
export default defineEventHandler(async (event): Promise<PaqueteAdmin> => {
  const sesion = exigirAdmin(event)
  const id = Number(getRouterParam(event, 'id'))

  if (!Number.isInteger(id) || id < 1) {
    throw createError({ statusCode: 400, statusMessage: 'datos_invalidos' })
  }

  const datos = await leerCuerpo(event, esquemaPaquete)
  validarPaquetePublicable(datos)

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

  const idsLugares = [
    datos.idLugarDestino,
    datos.idLugarOrigen,
    ...datos.paradas,
  ].filter((valor): valor is number => typeof valor === 'number')

  await validarLugares(idsLugares)
  await validarServicios(datos.servicios)

  const fila = await db.transaction(async (tx) => {
    const [actualizado] = await tx
      .update(schema.paquete)
      .set({
        nombre: datos.nombre,
        idLugarDestino: datos.idLugarDestino ?? null,
        idLugarOrigen: datos.idLugarOrigen ?? null,
        tipoRecorrido: datos.tipoRecorrido,
        descripcion: datos.descripcion || null,
        duracionDias: datos.duracionDias,
        precioBase: datos.precioBase.toFixed(2),
        itinerario: datos.itinerario || null,
        serviciosDetalle: datos.serviciosDetalle || null,
        serviciosExcluidos: datos.serviciosExcluidos || null,
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

    await reemplazarParadas(tx, id, datos.paradas)
    await reemplazarServicios(tx, id, datos.servicios)
    return actualizado
  })

  const lugares = await cargarLugares(
    [fila.idLugarDestino, fila.idLugarOrigen].filter(
      (valor): valor is number => typeof valor === 'number',
    ),
  )
  const paradas = await cargarParadas([id])
  const servicios = await cargarServicios([id])
  const proveedores = await cargarProveedoresDePaquetes([id])

  return aPaqueteAdmin(
    fila,
    fila.idLugarDestino ? (lugares.get(fila.idLugarDestino) ?? null) : null,
    fila.idLugarOrigen ? (lugares.get(fila.idLugarOrigen) ?? null) : null,
    paradas.get(id) ?? [],
    servicios.get(id) ?? [],
    proveedores.get(id) ?? [],
  )
})
