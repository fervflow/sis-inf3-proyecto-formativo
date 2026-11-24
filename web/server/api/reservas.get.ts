import { and, asc, eq, gte, lte, sql } from 'drizzle-orm'
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
  /** Filtro por canal: todo, la atención del personal o la solicitud web. */
  canal: z.enum(['todo', 'personal', 'web']).default('todo'),
  /** Rango de fecha de salida (HU-07: filtros por fecha, estado y canal). */
  desde: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'datos_invalidos').optional(),
  hasta: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'datos_invalidos').optional(),
})

export default defineEventHandler(async (event): Promise<RespuestaReservas> => {
  const sesion = sesionActual(event)
  const esPersonal =
    sesion?.user &&
    (sesion.user.idRol === ROL_ADMIN || sesion.user.idRol === ROL_PERSONAL)

  if (!sesion?.user) {
    throw createError({ statusCode: 401, statusMessage: 'sesion_requerida' })
  }

  const { canal, desde, hasta, estado } = leerConsulta(event, consulta)

  // Todas las condiciones van en un solo where: el constructor de
  // consultas de Drizzle no lo encadena dos veces.
  const condiciones = [
    canal === 'todo' ? undefined : eq(schema.reserva.origen, canal),
    estado === 'todas' ? undefined : eq(schema.reserva.estado, estado),
    desde ? gte(schema.salida.fechaSalida, desde) : undefined,
    hasta ? lte(schema.salida.fechaSalida, hasta) : undefined,
  ]

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

    condiciones.push(eq(schema.reserva.idCliente, ficha.idCliente))
  }

  const filas = await useDb()
    .select(seleccionReserva())
    .from(schema.reserva)
    .innerJoin(
      schema.cliente,
      eq(schema.cliente.idCliente, schema.reserva.idCliente),
    )
    .innerJoin(schema.salida, eq(schema.salida.idSalida, schema.reserva.idSalida))
    .innerJoin(schema.paquete, eq(schema.paquete.idPaquete, schema.salida.idPaquete))
    .where(and(...condiciones))
    .orderBy(asc(sql`coalesce(${schema.reserva.fechaExpiracion}, 'infinity')`))

  return { reservas: filas.map(aReservaResumen) }
})
