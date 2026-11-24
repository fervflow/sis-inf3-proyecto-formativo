import { eq, sql } from 'drizzle-orm'
import * as schema from '../../../../db/schema'
import type { ReservaResumen } from '#shared/types/api'
import { ROL_ADMIN, ROL_PERSONAL, sesionActual } from '../../../utils/autorizacion'
import { consultar } from '../../../utils/db'
import {
  codigoErrorReserva,
  obtenerReserva,
} from '../../../utils/reservas'

/**
 * Solicitud de cancelación del cliente (HU-13, T-HU-13.1).
 *
 * El cliente la pide sobre una reserva propia pendiente o confirmada; la
 * marca queda en `fecha_solicitud_cancelacion` y el estado no cambia hasta
 * que el personal la ejecuta (RN-RES-14). El personal también puede
 * levantar la solicitud por el cliente.
 */
export default defineEventHandler(async (event): Promise<ReservaResumen> => {
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

  try {
    await consultar(sql`
      select turismo.fn_solicitar_cancelacion(
        ${id}::bigint,
        ${sesion.user.id}::text
      ) as ok
    `)
  } catch (error) {
    if ((error as { statusCode?: number }).statusCode) throw error
    throw createError({
      statusCode: 400,
      statusMessage: codigoErrorReserva(error),
    })
  }

  const reserva = await obtenerReserva(id)
  if (!reserva) {
    throw createError({ statusCode: 404, statusMessage: 'reserva_inexistente' })
  }
  return reserva
})
