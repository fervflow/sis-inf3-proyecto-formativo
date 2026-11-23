import { sql } from 'drizzle-orm'
import type { ReservaResumen } from '#shared/types/api'
import { exigirPersonal } from '../../../utils/autorizacion'
import { consultar } from '../../../utils/db'
import {
  codigoErrorReserva,
  obtenerReserva,
} from '../../../utils/reservas'

/**
 * Confirmación de una solicitud pendiente (HU-17).
 *
 * `fn_confirmar_reserva` limpia la fecha de vencimiento y deja el cambio
 * auditado. Una solicitud vencida no puede confirmarse: la función la
 * marca como vencida y rechaza la operación.
 */
export default defineEventHandler(async (event): Promise<ReservaResumen> => {
  const sesion = exigirPersonal(event)
  const id = Number(getRouterParam(event, 'id'))

  if (!Number.isInteger(id) || id < 1) {
    throw createError({ statusCode: 400, statusMessage: 'datos_invalidos' })
  }

  try {
    await consultar(sql`
      select turismo.fn_confirmar_reserva(
        ${id}::bigint,
        ${sesion.user.id}::text
      ) as confirmada
    `)
  } catch (error) {
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
