/**
 * Reservas y solicitudes.
 *
 * Las reglas críticas viven en la base: `fn_crear_reserva` valida los
 * cupos dentro de una transacción que bloquea la fila de la salida,
 * `fn_confirmar_reserva` limpia el vencimiento y `fn_vencer_solicitudes_
 * pendientes` pasa a vencidas las que no se confirmaron. Aquí solo se
 * valida la forma del cuerpo, se traduce la fila de la base y se clasifican
 * los errores de la base en códigos de la interfaz.
 */
import { eq, sql } from 'drizzle-orm'
import { z } from 'zod'
import * as schema from '../../db/schema'
import type { ReservaResumen } from '#shared/types/api'
import type { EstadoReserva, OrigenReserva } from '#shared/types/domain'

const fecha = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'datos_invalidos')

/** Cuerpo del alta de una reserva desde la atención del personal. */
export const esquemaReservaPersonal = z.object({
  idCliente: z.coerce.number().int().positive(),
  idSalida: z.coerce.number().int().positive(),
  cantidadPasajeros: z.coerce.number().int().min(1).max(32_767),
  idCotizacion: z.coerce.number().int().positive().optional(),
})

/**
 * Cuerpo de la solicitud directa del cliente por el canal web.
 *
 * El cliente se identifica por su documento: si la ficha ya existe se
 * reutiliza y si no se registra con los datos de contacto que envía.
 */
export const esquemaReservaPublica = z.object({
  tipoDocumento: z.enum(['CI', 'NIT', 'PASAPORTE', 'OTRO']),
  numeroDocumento: z.string().trim().min(3).max(30),
  nombres: z.string().trim().min(2).max(100),
  apellidos: z.string().trim().min(2).max(100),
  correo: z.union([z.literal(''), z.email().max(150)]).optional(),
  telefono: z.string().trim().max(30).optional(),
  idSalida: z.coerce.number().int().positive(),
  cantidadPasajeros: z.coerce.number().int().min(1).max(32_767),
})

/** Identificador de la cuenta de sistema de la semilla. */
export const USUARIO_SISTEMA = 'sistema'

/** Devuelve el identificador de la cuenta de sistema, o falla si falta. */
export async function idUsuarioSistema(): Promise<string> {
  const [fila] = await useDb()
    .select({ id: schema.usuario.id })
    .from(schema.usuario)
    .where(eq(schema.usuario.id, USUARIO_SISTEMA))
    .limit(1)

  if (!fila) {
    throw createError({ statusCode: 500, statusMessage: 'sistema_faltante' })
  }
  return fila.id
}

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
 * duplicada y del vencimiento.
 */
export function codigoErrorReserva(error: unknown): string {
  const base = causaBase(error)
  const codigo = base.code
  const mensaje = base.message ?? ''

  if (mensaje.includes('cupo suficiente')) return 'cupo_insuficiente'
  if (mensaje.includes('ya tiene una solicitud pendiente')) {
    return 'solicitud_pendiente'
  }
  if (mensaje.includes('venció sin confirmarse')) return 'solicitud_vencida'
  if (mensaje.includes('Solo una solicitud pendiente')) {
    return 'transicion_invalida'
  }
  if (mensaje.includes('no existe o no admite reservas')) {
    return 'salida_no_disponible'
  }
  if (mensaje.includes('debe ser mayor que cero')) return 'datos_invalidos'

  if (codigo === '23505') {
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
  const envuelto = error as { code?: string; cause?: { code?: string } }
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

/** Busca la ficha del cliente por documento, sin alterar la búsqueda. */
export async function buscarClientePorDocumento(
  tipoDocumento: string,
  numeroDocumento: string,
): Promise<number | null> {
  const [fila] = await useDb()
    .select({ idCliente: schema.cliente.idCliente })
    .from(schema.cliente)
    .where(
      sql`${schema.cliente.tipoDocumento} = ${tipoDocumento}
          and upper(${schema.cliente.numeroDocumento}) = ${numeroDocumento.toUpperCase()}`,
    )
    .limit(1)

  return fila?.idCliente ?? null
}
