import * as schema from '../../../db/schema'
import type { PaqueteAdmin } from '#shared/types/api'
import { exigirAdmin } from '../../utils/autorizacion'
import {
  aPaqueteAdmin,
  cargarLugares,
  cargarParadas,
  cargarServicios,
  esquemaPaquete,
  generarCodigoPaquete,
  reemplazarParadas,
  reemplazarServicios,
  validarLugares,
  validarPaquetePublicable,
  validarServicios,
} from '../../utils/paquetes'
import { esDuplicado, leerCuerpo } from '../../utils/validacion'

/**
 * Alta de un paquete turístico.
 *
 * El código no viaja en el cuerpo: lo genera la base a partir del destino
 * o del nombre y no se edita después.
 */
export default defineEventHandler(async (event): Promise<PaqueteAdmin> => {
  const sesion = exigirAdmin(event)
  const datos = await leerCuerpo(event, esquemaPaquete)

  validarPaquetePublicable(datos)

  const idsLugares = [
    datos.idLugarDestino,
    datos.idLugarOrigen,
    ...datos.paradas,
  ].filter((id): id is number => typeof id === 'number')

  await validarLugares(idsLugares)
  await validarServicios(datos.servicios)

  const db = useDb()

  let fila: typeof schema.paquete.$inferSelect
  try {
    fila = await db.transaction(async (tx) => {
      const codigo = await generarCodigoPaquete(
        datos.idLugarDestino,
        datos.nombre,
      )

      const [creado] = await tx
        .insert(schema.paquete)
        .values({
          codigo,
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
          idUsuarioCreador: sesion.user.id,
        })
        .returning()

      if (!creado) {
        throw createError({ statusCode: 500, statusMessage: 'alta_incompleta' })
      }

      await reemplazarParadas(tx, creado.idPaquete, datos.paradas)
      await reemplazarServicios(tx, creado.idPaquete, datos.servicios)
      return creado
    })
  } catch (fallo) {
    if (esDuplicado(fallo)) {
      throw createError({ statusCode: 409, statusMessage: 'paquete_duplicado' })
    }
    throw fallo
  }

  const lugares = await cargarLugares(
    [fila.idLugarDestino, fila.idLugarOrigen].filter(
      (id): id is number => typeof id === 'number',
    ),
  )
  const paradas = await cargarParadas([fila.idPaquete])
  const servicios = await cargarServicios([fila.idPaquete])

  return aPaqueteAdmin(
    fila,
    fila.idLugarDestino ? (lugares.get(fila.idLugarDestino) ?? null) : null,
    fila.idLugarOrigen ? (lugares.get(fila.idLugarOrigen) ?? null) : null,
    paradas.get(fila.idPaquete) ?? [],
    servicios.get(fila.idPaquete) ?? [],
  )
})
