/**
 * Pagos de una reserva.
 *
 * Las reglas viven en la base: `fn_registrar_pago` aplica el anticipo
 * mínimo del 30%, exige anticipo previo para el saldo y respeta el saldo
 * pendiente (RN-PAG-01, RN-PAG-05); `fn_validar_pago` valida o anula
 * (RN-PAG-04). Aquí solo se valida la forma del cuerpo, se traduce la fila
 * de la base y se clasifican los errores de la base en códigos de la
 * interfaz.
 */
import { eq, sql } from 'drizzle-orm'
import { z } from 'zod'
import * as schema from '../../db/schema'
import type {
  PagoResumen,
  RespuestaPagos,
} from '#shared/types/api'
import type { EstadoPago, MetodoPago, TipoPago } from '#shared/types/domain'
import { METODOS_OFICINA, METODOS_WEB, saldoPendienteDe } from '#shared/pagos'

/** Cuerpo del registro de un pago desde la web del cliente. */
export const esquemaPagoCliente = z.object({
  idReserva: z.coerce.number().int().positive(),
  tipo: z.enum(['anticipo', 'saldo']),
  monto: z.coerce.number().positive('datos_invalidos'),
  metodo: z.enum(METODOS_WEB),
  observacion: z.string().trim().max(200).optional(),
})

/** Cuerpo del registro de un pago desde la oficina. */
export const esquemaPagoPersonal = z.object({
  idReserva: z.coerce.number().int().positive(),
  tipo: z.enum(['anticipo', 'saldo']),
  monto: z.coerce.number().positive('datos_invalidos'),
  metodo: z.enum(METODOS_OFICINA),
  referencia: z.string().trim().max(100).optional(),
  observacion: z.string().trim().max(200).optional(),
})

/** Cuerpo de la validación o anulación de un pago. */
export const esquemaValidacionPago = z.object({
  anular: z.boolean().optional(),
})

/** Fila de la tabla `pago`. */
export interface FilaPago {
  idPago: number
  idReserva: number
  tipo: string
  monto: string
  metodo: string
  referencia: string | null
  fechaPago: Date
  estado: string
  fechaValidacion: Date | null
}

/** Convierte la fila de la base en lo que consume la interfaz. */
export function aPagoResumen(fila: FilaPago): PagoResumen {
  return {
    idPago: fila.idPago,
    idReserva: fila.idReserva,
    tipo: fila.tipo as TipoPago,
    monto: fila.monto,
    metodo: fila.metodo as MetodoPago,
    referencia: fila.referencia,
    fechaPago: fila.fechaPago.toISOString(),
    estado: fila.estado as EstadoPago,
    fechaValidacion: fila.fechaValidacion?.toISOString() ?? null,
  }
}

/** Lista los pagos de una reserva con su resumen (HU-14). */
export async function obtenerPagosDeReserva(
  idReserva: number,
): Promise<RespuestaPagos> {
  const db = useDb()

  const [reserva] = await db
    .select({ montoTotal: schema.reserva.montoTotal })
    .from(schema.reserva)
    .where(eq(schema.reserva.idReserva, idReserva))
    .limit(1)

  if (!reserva) {
    throw createError({ statusCode: 404, statusMessage: 'reserva_inexistente' })
  }

  const filas = await db
    .select({
      idPago: schema.pago.idPago,
      idReserva: schema.pago.idReserva,
      tipo: schema.pago.tipo,
      monto: schema.pago.monto,
      metodo: schema.pago.metodo,
      referencia: schema.pago.referencia,
      fechaPago: schema.pago.fechaPago,
      estado: schema.pago.estado,
      fechaValidacion: schema.pago.fechaValidacion,
    })
    .from(schema.pago)
    .where(eq(schema.pago.idReserva, idReserva))
    .orderBy(sql`${schema.pago.fechaPago}, ${schema.pago.idPago}`)

  const abonado = filas
    .filter((fila) => fila.estado === 'validado')
    .reduce((total, fila) => total + Number(fila.monto), 0)
  const enRevision = filas
    .filter((fila) => fila.estado === 'registrado')
    .reduce((total, fila) => total + Number(fila.monto), 0)

  return {
    pagos: filas.map(aPagoResumen),
    resumen: {
      montoTotal: reserva.montoTotal,
      abonado: abonado.toFixed(2),
      enRevision: enRevision.toFixed(2),
      saldoPendiente: saldoPendienteDe(reserva.montoTotal, abonado).toFixed(2),
      anticipoValidado: filas.some(
        (fila) =>
          fila.tipo === 'anticipo' &&
          fila.estado === 'validado' &&
          Number(fila.monto) >=
            Math.round(Number(reserva.montoTotal) * 0.3 * 100) / 100,
      ),
    },
  }
}

/**
 * Traduce una violación de la base a un código de la interfaz.
 */
export function codigoErrorPago(error: unknown): string {
  const base = causaBase(error)
  const codigo = base.code
  const mensaje = base.message ?? ''

  if (mensaje.includes('anticipo no puede ser menor')) return 'anticipo_minimo'
  if (mensaje.includes('saldo debe pagar el resto')) return 'saldo_incompleto'
  if (mensaje.includes('saldo exige un anticipo')) return 'saldo_sin_anticipo'
  if (mensaje.includes('supera el saldo pendiente')) return 'monto_excedido'
  if (mensaje.includes('admite pagos')) return 'reserva_no_pagable'
  if (mensaje.includes('no existe')) return 'reserva_inexistente'

  if (codigo === '23505') return 'pago_duplicado'
  if (codigo === 'P0002') return 'reserva_inexistente'
  return 'datos_invalidos'
}

/** El error original de PostgreSQL, aunque Drizzle lo envuelva. */
function causaBase(
  error: unknown,
): { code?: string; message?: string } {
  const envuelto = error as {
    code?: string
    message?: string
    cause?: { code?: string; message?: string }
  }
  if (envuelto.code === undefined && envuelto.cause?.code) {
    return envuelto.cause
  }
  return (error as { code?: string; message?: string }) ?? {}
}
