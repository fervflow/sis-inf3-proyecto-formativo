import { eq } from 'drizzle-orm'
import * as schema from '../../../../db/schema'
import type { RespuestaHistorial } from '#shared/types/api'
import { ROL_ADMIN, ROL_PERSONAL, sesionActual } from '../../../utils/autorizacion'

/**
 * Historial de una reserva (HU-07, T-HU-07.3).
 *
 * Cada cambio de estado y de datos queda con usuario, fecha y observación;
 * la modificación de salida, cantidad y monto se registra con los valores
 * anterior y nuevo en la observación (RN-RES-20). Solo el personal lo
 * consulta.
 */
export default defineEventHandler(async (event): Promise<RespuestaHistorial> => {
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

  const filas = await useDb()
    .select({
      idHistorial: schema.historialReserva.idHistorial,
      estadoAnterior: schema.historialReserva.estadoAnterior,
      estadoNuevo: schema.historialReserva.estadoNuevo,
      fechaCambio: schema.historialReserva.fechaCambio,
      nombres: schema.usuario.nombres,
      apellidos: schema.usuario.apellidos,
      observacion: schema.historialReserva.observacion,
    })
    .from(schema.historialReserva)
    .leftJoin(schema.usuario, eq(schema.usuario.id, schema.historialReserva.idUsuario))
    .where(eq(schema.historialReserva.idReserva, id))
    .orderBy(schema.historialReserva.fechaCambio)

  return {
    historial: filas.map((fila) => ({
      idHistorial: fila.idHistorial,
      estadoAnterior: fila.estadoAnterior,
      estadoNuevo: fila.estadoNuevo,
      fechaCambio: fila.fechaCambio.toISOString(),
      usuario: `${fila.nombres ?? ''} ${fila.apellidos ?? ''}`.trim() || null,
      observacion: fila.observacion,
    })),
  }
})
