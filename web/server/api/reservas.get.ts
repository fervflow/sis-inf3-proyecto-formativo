import { asc, eq, sql } from 'drizzle-orm'
import { z } from 'zod'
import * as schema from '../../db/schema'
import type { RespuestaReservas } from '#shared/types/api'
import { exigirPersonal } from '../utils/autorizacion'
import { aReservaResumen, seleccionReserva } from '../utils/reservas'
import { leerConsulta } from '../utils/validacion'

/**
 * Consulta de reservas para el personal (HU-17).
 *
 * Por defecto lista las solicitudes pendientes de ambos canales, ordenadas
 * por vencimiento: la que expira primero encabeza la lista. Con
 * `estado=todas` devuelve el historial completo.
 */
const consulta = z.object({
  estado: z
    .enum(['pendiente', 'confirmada', 'vencida', 'cancelada', 'finalizada', 'todas'])
    .default('pendiente'),
})

export default defineEventHandler(async (event): Promise<RespuestaReservas> => {
  exigirPersonal(event)
  const { estado } = leerConsulta(event, consulta)

  const consultaReserva = useDb()
    .select(seleccionReserva())
    .from(schema.reserva)
    .innerJoin(
      schema.cliente,
      eq(schema.cliente.idCliente, schema.reserva.idCliente),
    )
    .innerJoin(schema.salida, eq(schema.salida.idSalida, schema.reserva.idSalida))
    .innerJoin(schema.paquete, eq(schema.paquete.idPaquete, schema.salida.idPaquete))
    .orderBy(asc(sql`coalesce(${schema.reserva.fechaExpiracion}, 'infinity')`))

  const filas =
    estado === 'todas'
      ? await consultaReserva
      : await consultaReserva.where(eq(schema.reserva.estado, estado))

  return { reservas: filas.map(aReservaResumen) }
})
