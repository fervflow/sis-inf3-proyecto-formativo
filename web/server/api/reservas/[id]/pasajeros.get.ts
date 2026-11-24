import { eq } from 'drizzle-orm'
import * as schema from '../../../../db/schema'
import type { RespuestaPasajeros } from '#shared/types/api'
import { ROL_ADMIN, ROL_PERSONAL, sesionActual } from '../../../utils/autorizacion'
import { obtenerManifiesto } from '../../../utils/pasajeros'

/**
 * Manifiesto de pasajeros de una reserva (HU-12).
 *
 * El personal consulta el de cualquier reserva; el cliente solo el de las
 * suyas. La respuesta incluye la cantidad declarada: el manifiesto debe
 * igualarla antes de confirmar (RN-RES-19).
 */
export default defineEventHandler(async (event): Promise<RespuestaPasajeros> => {
  const sesion = sesionActual(event)
  const esPersonal =
    sesion?.user &&
    (sesion.user.idRol === ROL_ADMIN || sesion.user.idRol === ROL_PERSONAL)

  if (!sesion?.user) {
    throw createError({ statusCode: 401, statusMessage: 'sesion_requerida' })
  }

  const id = Number(getRouterParam(event, 'id'))
  if (!Number.isInteger(id) || id < 1) {
    throw createError({ statusCode: 400, statusMessage: 'datos_invalidos' })
  }

  if (!esPersonal) {
    const [ficha] = await useDb()
      .select({ idCliente: schema.cliente.idCliente })
      .from(schema.cliente)
      .where(eq(schema.cliente.idUsuario, sesion.user.id))
      .limit(1)

    const [reserva] = ficha
      ? await useDb()
          .select({ idCliente: schema.reserva.idCliente })
          .from(schema.reserva)
          .where(eq(schema.reserva.idReserva, id))
          .limit(1)
      : []

    if (!ficha || !reserva || reserva.idCliente !== ficha.idCliente) {
      throw createError({ statusCode: 403, statusMessage: 'sin_permiso' })
    }
  }

  return obtenerManifiesto(id)
})
