import { eq } from 'drizzle-orm'
import * as schema from '../../db/schema'
import type { RespuestaPagos } from '#shared/types/api'
import { ROL_ADMIN, ROL_PERSONAL, sesionActual } from '../utils/autorizacion'
import { codigoErrorPago, obtenerPagosDeReserva } from '../utils/pagos'

/**
 * Pagos de una reserva (HU-14).
 *
 * El personal consulta los de cualquier reserva; el cliente solo los de
 * las suyas. La respuesta incluye el resumen del saldo: total, abonado
 * validado, en revisión y pendiente.
 */
export default defineEventHandler(async (event): Promise<RespuestaPagos> => {
  const sesion = sesionActual(event)
  const esPersonal =
    sesion?.user &&
    (sesion.user.idRol === ROL_ADMIN || sesion.user.idRol === ROL_PERSONAL)

  if (!sesion?.user) {
    throw createError({ statusCode: 401, statusMessage: 'sesion_requerida' })
  }

  const idReserva = Number(getQuery(event).reserva)
  if (!Number.isInteger(idReserva) || idReserva < 1) {
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
          .where(eq(schema.reserva.idReserva, idReserva))
          .limit(1)
      : []

    if (!ficha || !reserva || reserva.idCliente !== ficha.idCliente) {
      throw createError({ statusCode: 403, statusMessage: 'sin_permiso' })
    }
  }

  return obtenerPagosDeReserva(idReserva)
})
