import { sql } from 'drizzle-orm'
import { z } from 'zod'
import type { ReservaResumen } from '#shared/types/api'
import { exigirPersonal } from '../../../utils/autorizacion'
import { consultar } from '../../../utils/db'
import {
  codigoErrorReserva,
  obtenerReserva,
} from '../../../utils/reservas'
import { leerCuerpo } from '../../../utils/validacion'

/**
 * Ejecución de la cancelación por el personal (HU-13, T-HU-13.2).
 *
 * La cancelación es lógica: el estado pasa a `cancelada` con motivo y
 * fecha, y el cupo se libera por cálculo (RN-RES-14). La base rechaza
 * cancelar dos veces o sobre una reserva finalizada.
 */
const cuerpo = z.object({
  motivo: z.string().trim().min(3, 'motivo_requerido').max(200),
})

export default defineEventHandler(async (event): Promise<ReservaResumen> => {
  const sesion = exigirPersonal(event)
  const id = Number(getRouterParam(event, 'id'))

  if (!Number.isInteger(id) || id < 1) {
    throw createError({ statusCode: 400, statusMessage: 'datos_invalidos' })
  }

  const { motivo } = await leerCuerpo(event, cuerpo)

  try {
    await consultar(sql`
      select turismo.fn_ejecutar_cancelacion(
        ${id}::bigint,
        ${motivo}::varchar,
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
