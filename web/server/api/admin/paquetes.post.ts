import * as schema from '../../../db/schema'
import type { PaqueteAdmin } from '#shared/types/api'
import { exigirAdmin } from '../../utils/autorizacion'
import {
  aPaqueteAdmin,
  cargarItinerario,
  cargarLugares,
  cargarParadas,
  cargarServicios,
  esquemaPaquete,
  generarCodigoPaquete,
  reemplazarItinerario,
  reemplazarParadas,
  reemplazarServicios,
  validarLugares,
  validarPaquetePublicable,
  validarServicios,
} from '../../utils/paquetes'
import { esDuplicado, leerCuerpo } from '../../utils/validacion'
import { cargarProveedoresDePaquetes } from '../../utils/proveedores'

/**
 * Alta de un paquete turístico.
 *
 * El código no viaja en el cuerpo: lo genera la base a partir del destino
 * o del nombre y no se edita después. El itinerario llega como lista de
 * días y se renumera por su orden (RN-PAQ-18).
 */
export default defineEventHandler(async (event): Promise<PaqueteAdmin> => {
  const sesion = exigirAdmin(event)
  const datos = await leerCuerpo(event, esquemaPaquete)

  validarPaquetePublicable({
    estado: datos.estado,
    idLugarDestino: datos.idLugarDestino,
    descripcion: datos.descripcion,
    itinerario: datos.itinerario,
    servicios: datos.servicios,
  })

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
      await reemplazarItinerario(tx, creado.idPaquete, datos.itinerario)
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
  const itinerario = await cargarItinerario([fila.idPaquete])
  const servicios = await cargarServicios([fila.idPaquete])
  const proveedores = await cargarProveedoresDePaquetes([fila.idPaquete])

  return aPaqueteAdmin(
    fila,
    fila.idLugarDestino ? (lugares.get(fila.idLugarDestino) ?? null) : null,
    fila.idLugarOrigen ? (lugares.get(fila.idLugarOrigen) ?? null) : null,
    paradas.get(fila.idPaquete) ?? [],
    itinerario.get(fila.idPaquete) ?? [],
    servicios.get(fila.idPaquete) ?? [],
    proveedores.get(fila.idPaquete) ?? [],
  )
})
