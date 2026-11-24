import { asc, eq, sql } from 'drizzle-orm'
import { z } from 'zod'
import * as schema from '../../db/schema'
import type { RespuestaReservas } from '#shared/types/api'
import {
  ROL_ADMIN,
  ROL_PERSONAL,
  sesionActual,
} from '../utils/autorizacion'
import { aReservaResumen, seleccionReserva } from '../utils/reservas'
import { leerConsulta } from '../utils/validacion'

/**
 * Consulta de reservas.
 *
 * - Personal y administrador (HU-17): todas las solicitudes de ambos
 *   canales. Por defecto lista las pendientes, ordenadas por vencimiento;
 *   con `estado=todas` devuelve el historial completo.
 * - Cliente (HU-15): solo sus propias reservas, en cualquier estado.
 * - Sin sesión: 401, porque nadie consulta reservas de forma anónima
 *   (RN-RES-17).
 */
const consulta = z.object({
  estado: z
    .enum(['pendiente', 'confirmada', 'vencida', 'cancelada', 'finalizada', 'todas'])
    .default('pendiente'),
})

export default defineEventHandler(async (event): Promise<RespuestaReservas> => {
  const sesion = sesionActual(event)
  const esPersonal =
    sesion?.user &&
    (sesion.user.idRol === ROL_ADMIN || sesion.user.idRol === ROL_PERSONAL)

  if (!sesion?.user) {
    throw createError({ statusCode: 401, statusMessage: 'sesion_requerida' })
  }

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

  // El cliente ve solo lo suyo: la ficha de su cuenta es el filtro.
  if (!esPersonal) {
    const [ficha] = await useDb()
      .select({ idCliente: schema.cliente.idCliente })
      .from(schema.cliente)
      .where(eq(schema.cliente.idUsuario, sesion.user.id))
      .limit(1)

    if (!ficha) {
      return { reservas: [] }
    }

    const filas = await consultaReserva.where(
      eq(schema.reserva.idCliente, ficha.idCliente),
    )
    return { reservas: filas.map(aReservaResumen) }
  }

  const { estado } = leerConsulta(event, consulta)

  const filas =
    estado === 'todas'
      ? await consultaReserva
      : await consultaReserva.where(eq(schema.reserva.estado, estado))

  return { reservas: filas.map(aReservaResumen) }
})
