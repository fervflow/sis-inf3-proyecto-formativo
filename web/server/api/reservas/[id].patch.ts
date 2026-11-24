import { eq, sql } from 'drizzle-orm'
import { z } from 'zod'
import * as schema from '../../../db/schema'
import type { ReservaResumen } from '#shared/types/api'
import { ROL_ADMIN, ROL_PERSONAL, sesionActual } from '../../utils/autorizacion'
import { consultar } from '../../utils/db'
import {
  codigoErrorReserva,
  obtenerReserva,
} from '../../utils/reservas'
import { leerCuerpo } from '../../utils/validacion'

/**
 * Modificación de una reserva (HU-07, T-HU-07.2).
 *
 * Cambia la salida de una reserva pendiente o confirmada; la cantidad no
 * cambia aquí (el manifiesto manda, RN-RES-21). La función de la base
 * revalida los cupos en una transacción que bloquea la salida, recalcula
 * el monto con el precio vigente y rechaza que los pagos comprometidos
 * queden por encima del nuevo total (RN-RES-20).
 */
const cuerpo = z.object({
  idSalida: z.coerce.number().int().positive(),
})

export default defineEventHandler(async (event): Promise<ReservaResumen> => {
  const sesion = sesionActual(event)
  const esPersonal =
    sesion?.user &&
    (sesion.user.idRol === ROL_ADMIN || sesion.user.idRol === ROL_PERSONAL)

  if (!esPersonal) {
    throw createError({ statusCode: 403, statusMessage: 'sin_permiso' })
  }

  const id = Number(getRouterParam(event, 'id'))
  if (!Number.isInteger(id) || id < 1) {
    throw createError({ statusCode: 400, statusMessage: 'datos_invalidos' })
  }

  const { idSalida } = await leerCuerpo(event, cuerpo)

  try {
    await consultar(sql`
      select turismo.fn_actualizar_reserva(
        ${id}::bigint,
        ${idSalida}::bigint,
        ${sesion.user.id}::text
      ) as monto
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
