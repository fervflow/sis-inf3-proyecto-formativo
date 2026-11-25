/**
 * Reservas y solicitudes.
 *
 * Las reglas críticas viven en la base: `fn_crear_reserva` valida los
 * cupos dentro de una transacción que bloquea la fila de la salida,
 * `fn_confirmar_reserva` exige el anticipo validado y limpia el
 * vencimiento, y `fn_vencer_solicitudes_pendientes` pasa a vencidas las
 * que no se confirmaron. Aquí solo se valida la forma del cuerpo, se
 * traduce la fila de la base y se clasifican los errores de la base en
 * códigos de la interfaz.
 */
import { eq, sql } from 'drizzle-orm'
import { z } from 'zod'
import * as schema from '../../db/schema'
import type { ReservaResumen } from '#shared/types/api'
import type { EstadoPago, EstadoReserva, OrigenReserva } from '#shared/types/domain'
import { SOLICITUD_WEB_MAXIMO_PASAJEROS } from '#shared/reservas'

const fecha = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'datos_invalidos')

/** Cuerpo del alta de una reserva desde la atención del personal. */
export const esquemaReservaPersonal = z.object({
  idCliente: z.coerce.number().int().positive(),
  idSalida: z.coerce.number().int().positive(),
  cantidadPasajeros: z.coerce.number().int().min(1).max(32_767),
  idCotizacion: z.coerce.number().int().positive().optional(),
})

/**
 * Cuerpo de la solicitud del cliente con sesión (canal web).
 *
 * El cliente viene de su cuenta: la ficha la resuelve el servidor con
 * `cliente.id_usuario` (RN-RES-17). El tope de pasajeros es el de
 * RN-RES-15; la función de la base lo vuelve a comprobar.
 */
export const esquemaReservaCliente = z.object({
  idSalida: z.coerce.number().int().positive(),
  cantidadPasajeros: z.coerce
    .number()
    .int()
    .min(1)
    .max(SOLICITUD_WEB_MAXIMO_PASAJEROS, 'solicitud_grande'),
})

/** Fila de la consulta de reservas con cliente, salida y paquete resueltos. */
export interface FilaReserva {
  idReserva: number
  codigo: string
  idCliente: number
  nombresCliente: string
  apellidosCliente: string
  tipoDocumento: string
  numeroDocumento: string
  idSalida: number
  codigoPaquete: string
  paquete: string
  fechaSalida: string
  fechaRetorno: string
  origen: string
  cantidadPasajeros: number
  montoTotal: string
  estado: string
  fechaExpiracion: Date | null
  fechaReserva: Date
  /** Marca de la solicitud de cancelación del cliente (HU-13). */
  fechaSolicitudCancelacion: Date | null
  /** Estado del anticipo de la reserva, si tiene pago. */
  anticipo: string | null
  /** Total menos lo abonado validado. */
  saldoPendiente: string
  /** Pasajeros ya registrados en el manifiesto (RN-RES-19). */
  pasajerosRegistrados: number
}

/** Convierte la fila de la base en lo que consume la interfaz. */
export function aReservaResumen(fila: FilaReserva): ReservaResumen {
  return {
    idReserva: fila.idReserva,
    codigo: fila.codigo,
    idCliente: fila.idCliente,
    cliente: `${fila.nombresCliente} ${fila.apellidosCliente}`.trim(),
    documento: `${fila.tipoDocumento} ${fila.numeroDocumento}`,
    idSalida: fila.idSalida,
    codigoPaquete: fila.codigoPaquete,
    paquete: fila.paquete,
    fechaSalida: fila.fechaSalida,
    fechaRetorno: fila.fechaRetorno,
    origen: fila.origen as OrigenReserva,
    cantidadPasajeros: fila.cantidadPasajeros,
    montoTotal: fila.montoTotal,
    estado: fila.estado as EstadoReserva,
    fechaExpiracion: fila.fechaExpiracion?.toISOString() ?? null,
    fechaReserva: fila.fechaReserva.toISOString(),
    fechaSolicitudCancelacion: fila.fechaSolicitudCancelacion?.toISOString() ?? null,
    anticipo: (fila.anticipo as EstadoPago | null) ?? null,
    saldoPendiente: fila.saldoPendiente,
    pasajerosRegistrados: fila.pasajerosRegistrados,
  }
}

/** Selección compartida por la lista y la consulta de una reserva. */
export function seleccionReserva() {
  return {
    idReserva: schema.reserva.idReserva,
    codigo: schema.reserva.codigo,
    idCliente: schema.reserva.idCliente,
    nombresCliente: schema.cliente.nombres,
    apellidosCliente: schema.cliente.apellidos,
    tipoDocumento: schema.cliente.tipoDocumento,
    numeroDocumento: schema.cliente.numeroDocumento,
    idSalida: schema.reserva.idSalida,
    codigoPaquete: schema.paquete.codigo,
    paquete: schema.paquete.nombre,
    fechaSalida: schema.salida.fechaSalida,
    fechaRetorno: schema.salida.fechaRetorno,
    origen: schema.reserva.origen,
    cantidadPasajeros: schema.reserva.cantidadPasajeros,
    montoTotal: schema.reserva.montoTotal,
    estado: schema.reserva.estado,
    fechaExpiracion: schema.reserva.fechaExpiracion,
    fechaReserva: schema.reserva.fechaReserva,
    fechaSolicitudCancelacion: schema.reserva.fechaSolicitudCancelacion,
    // El estado del anticipo lo resuelve una subconsulta: la reserva no
    // guarda pagos, pero la vista del personal y la del cliente muestran
    // si el respaldo existe (RN-RES-18).
    anticipo: sql<string | null>`(
      select p2.estado
      from ${schema.pago} p2
      where p2.id_reserva = ${schema.reserva.idReserva}
        and p2.tipo = 'anticipo'
        and p2.estado <> 'anulado'
      order by p2.id_pago
      limit 1
    )`,
    saldoPendiente: sql<string>`(
      select ${schema.reserva.montoTotal} - coalesce(sum(p2.monto), 0)
      from ${schema.pago} p2
      where p2.id_reserva = ${schema.reserva.idReserva}
        and p2.estado = 'validado'
    )`,
    // Los pasajeros del manifiesto ya registrados, para que la interfaz
    // marque el manifiesto pendiente (RN-RES-19).
    pasajerosRegistrados: sql<number>`(
      select count(*)::int
      from ${schema.reservaPasajero} rp2
      where rp2.id_reserva = ${schema.reserva.idReserva}
    )`,
  }
}

/** Devuelve una reserva con sus datos resueltos, o `null` si no existe. */
export async function obtenerReserva(id: number): Promise<ReservaResumen | null> {
  const [fila] = await useDb()
    .select(seleccionReserva())
    .from(schema.reserva)
    .innerJoin(
      schema.cliente,
      eq(schema.cliente.idCliente, schema.reserva.idCliente),
    )
    .innerJoin(schema.salida, eq(schema.salida.idSalida, schema.reserva.idSalida))
    .innerJoin(schema.paquete, eq(schema.paquete.idPaquete, schema.salida.idPaquete))
    .where(eq(schema.reserva.idReserva, id))
    .limit(1)

  return fila ? aReservaResumen(fila) : null
}

/**
 * Traduce una violación de la base a un código de la interfaz.
 *
 * Las funciones de la base levantan excepciones con mensajes descriptivos;
 * el mensaje se usa para distinguir el cupo insuficiente de la solicitud
 * duplicada, del vencimiento y del anticipo faltante.
 */
export function codigoErrorReserva(error: unknown): string {
  const base = causaBase(error)
  const codigo = base.code
  const mensaje = base.message ?? ''

  if (mensaje.includes('cupo suficiente')) return 'cupo_insuficiente'
  if (
    mensaje.includes(
      `hasta ${SOLICITUD_WEB_MAXIMO_PASAJEROS} pasajeros`,
    )
  ) {
    return 'solicitud_grande'
  }
  if (mensaje.includes('demasiadas solicitudes pendientes')) {
    return 'solicitudes_excedidas'
  }
  if (mensaje.includes('ya tiene una solicitud pendiente')) {
    return 'solicitud_pendiente'
  }
  if (mensaje.includes('venció sin confirmarse')) return 'solicitud_vencida'
  if (mensaje.includes('anticipo mínimo validado')) return 'anticipo_requerido'
  if (mensaje.includes('manifiesto incompleto')) return 'manifiesto_incompleto'
  if (mensaje.includes('pagos comprometidos superan')) return 'pagos_excedidos'
  if (mensaje.includes('no admite su manifiesto')) return 'reserva_no_editable'
  if (mensaje.includes('se modifica; el estado')) return 'reserva_no_editable'
  if (mensaje.includes('ficha de otro cliente')) return 'pasajero_ajeno'
  if (mensaje.includes('no admite cancelación')) return 'reserva_no_cancelable'
  if (mensaje.includes('ya está cancelada')) return 'reserva_no_cancelable'
  if (mensaje.includes('Solo una solicitud pendiente')) {
    return 'transicion_invalida'
  }
  if (mensaje.includes('no existe o no admite reservas')) {
    return 'salida_no_disponible'
  }
  if (mensaje.includes('debe ser mayor que cero')) return 'datos_invalidos'

  if (codigo === '23505') {
    if (mensaje.includes('reserva_pasajero') || mensaje.includes('pasajero')) {
      return 'pasajero_duplicado'
    }
    return mensaje.includes('cliente') ? 'solicitud_pendiente' : 'datos_invalidos'
  }
  if (codigo === 'P0002') return 'reserva_inexistente'
  if (codigo === '23503') return 'cliente_inexistente'
  return 'datos_invalidos'
}

/**
 * El error original de PostgreSQL.
 *
 * Drizzle envuelve los fallos de consulta en `DrizzleQueryError`; el
 * código y el mensaje de la base quedan en `cause`.
 */
function causaBase(
  error: unknown,
): { code?: string; message?: string } {
  const envuelto = error as { code?: string; message?: string; cause?: { code?: string; message?: string } }
  if (envuelto.code === undefined && envuelto.cause?.code) {
    return envuelto.cause
  }
  return (error as { code?: string; message?: string }) ?? {}
}

/** Comprueba que una cotización pueda originar una reserva. */
export async function validarCotizacionOrigen(
  idCotizacion: number,
  idCliente: number,
  idSalida: number,
): Promise<void> {
  const [cotizacion] = await useDb()
    .select({
      idCliente: schema.cotizacion.idCliente,
      idSalida: schema.cotizacion.idSalida,
      estado: schema.cotizacion.estado,
    })
    .from(schema.cotizacion)
    .where(eq(schema.cotizacion.idCotizacion, idCotizacion))
    .limit(1)

  if (!cotizacion) {
    throw createError({ statusCode: 404, statusMessage: 'cotizacion_inexistente' })
  }
  if (
    cotizacion.estado !== 'aceptada' ||
    cotizacion.idCliente !== idCliente ||
    cotizacion.idSalida !== idSalida
  ) {
    throw createError({ statusCode: 400, statusMessage: 'cotizacion_incoherente' })
  }
}
