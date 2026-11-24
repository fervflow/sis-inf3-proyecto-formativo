import { and, eq, inArray, sql } from 'drizzle-orm'
import * as schema from '../../db/schema'
import type { RespuestaAvisos } from '#shared/types/api'
import { ROL_ADMIN, ROL_PERSONAL, sesionActual } from '../utils/autorizacion'

/**
 * Avisos de cambios de salida para el cliente (HU-16, RN-RES-22).
 *
 * El aviso se deriva del historial de la salida: para cada reserva
 * `pendiente` o `confirmada` del cliente se listan los cambios de fecha
 * o capacidad ocurridos después de crear la reserva, con el valor
 * anterior, el nuevo y la fecha. Solo el cliente afectado los ve; las
 * reservas vencidas y canceladas no generan aviso.
 */
export default defineEventHandler(async (event): Promise<RespuestaAvisos> => {
  const sesion = sesionActual(event)
  const esPersonal =
    sesion?.user &&
    (sesion.user.idRol === ROL_ADMIN || sesion.user.idRol === ROL_PERSONAL)

  if (!sesion?.user) {
    throw createError({ statusCode: 401, statusMessage: 'sesion_requerida' })
  }

  // El aviso es del cliente: el personal tiene su propia bandeja.
  if (esPersonal) {
    throw createError({ statusCode: 403, statusMessage: 'sin_permiso' })
  }

  const [ficha] = await useDb()
    .select({ idCliente: schema.cliente.idCliente })
    .from(schema.cliente)
    .where(eq(schema.cliente.idUsuario, sesion.user.id))
    .limit(1)

  if (!ficha) {
    return { avisos: [] }
  }

  const filas = await useDb()
    .select({
      idReserva: schema.reserva.idReserva,
      codigo: schema.reserva.codigo,
      fechaReserva: schema.reserva.fechaReserva,
      codigoPaquete: schema.paquete.codigo,
      paquete: schema.paquete.nombre,
      fechaSalida: schema.salida.fechaSalida,
      campo: schema.historialSalida.campoModificado,
      valorAnterior: schema.historialSalida.valorAnterior,
      valorNuevo: schema.historialSalida.valorNuevo,
      motivo: schema.historialSalida.motivo,
      fechaCambio: schema.historialSalida.fechaCambio,
    })
    .from(schema.reserva)
    .innerJoin(
      schema.salida,
      eq(schema.salida.idSalida, schema.reserva.idSalida),
    )
    .innerJoin(
      schema.paquete,
      eq(schema.paquete.idPaquete, schema.salida.idPaquete),
    )
    .innerJoin(
      schema.historialSalida,
      eq(schema.historialSalida.idSalida, schema.salida.idSalida),
    )
    .where(
      and(
        eq(schema.reserva.idCliente, ficha.idCliente),
        inArray(schema.reserva.estado, ['pendiente', 'confirmada']),
        inArray(schema.historialSalida.campoModificado, [
          'fecha_salida',
          'fecha_retorno',
          'cupo_maximo',
        ]),
        sql`${schema.historialSalida.fechaCambio} > ${schema.reserva.fechaReserva}`,
      ),
    )
    .orderBy(schema.historialSalida.fechaCambio)

  return {
    avisos: filas.map((fila) => ({
      idReserva: fila.idReserva,
      codigo: fila.codigo,
      codigoPaquete: fila.codigoPaquete,
      paquete: fila.paquete,
      fechaSalida: fila.fechaSalida,
      campo: fila.campo,
      valorAnterior: fila.valorAnterior,
      valorNuevo: fila.valorNuevo,
      motivo: fila.motivo,
      fechaCambio: fila.fechaCambio.toISOString(),
    })),
  }
})
