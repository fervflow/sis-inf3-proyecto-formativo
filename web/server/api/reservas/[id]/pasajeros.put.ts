import { and, eq } from 'drizzle-orm'
import * as schema from '../../../../db/schema'
import type { RespuestaPasajeros } from '#shared/types/api'
import { ROL_ADMIN, ROL_PERSONAL, sesionActual } from '../../../utils/autorizacion'
import {
  esquemaManifiesto,
  guardarManifiesto,
  obtenerManifiesto,
} from '../../../utils/pasajeros'
import { leerCuerpo } from '../../../utils/validacion'

/**
 * Guardado del manifiesto de una reserva (HU-12).
 *
 * Reemplaza la lista completa de pasajeros (RN-RES-21): la cantidad
 * declarada pasa a ser la del manifiesto y la base revalida cupos, monto
 * y pagos comprometidos. El personal lo guarda en cualquier reserva; el
 * cliente solo en las suyas. Ambos sobre reservas pendientes o
 * confirmadas (RN-RES-20).
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

  const { pasajeros } = await leerCuerpo(event, esquemaManifiesto)

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
          .where(
            and(
              eq(schema.reserva.idReserva, id),
              eq(schema.reserva.idCliente, ficha.idCliente),
            ),
          )
          .limit(1)
      : []

    if (!reserva) {
      throw createError({ statusCode: 403, statusMessage: 'sin_permiso' })
    }
  }

  try {
    await guardarManifiesto(id, pasajeros, sesion.user.id)
  } catch (error) {
    if ((error as { statusCode?: number }).statusCode) throw error
    throw createError({
      statusCode: 400,
      statusMessage: 'datos_invalidos',
    })
  }

  return obtenerManifiesto(id)
})
