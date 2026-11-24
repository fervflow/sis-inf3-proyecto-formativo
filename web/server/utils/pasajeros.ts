/**
 * Pasajeros y manifiesto de una reserva.
 *
 * Las reglas viven en la base: `fn_guardar_manifiesto` reemplaza el
 * manifiesto, reutiliza al pasajero por documento dentro de la ficha del
 * cliente de la reserva, ajusta la cantidad declarada y revalida cupos,
 * monto y pagos comprometidos (RN-RES-21); `fn_confirmar_reserva` exige
 * el manifiesto completo (RN-RES-19). Aquí solo se valida la forma del
 * cuerpo y se clasifican los errores de la base.
 */
import { eq, sql } from 'drizzle-orm'
import { z } from 'zod'
import * as schema from '../../db/schema'
import type { PasajeroResumen, RespuestaPasajeros } from '#shared/types/api'
import type { TipoDocumento } from '#shared/types/domain'
import { SOLICITUD_WEB_MAXIMO_PASAJEROS } from '#shared/reservas'

/** Un pasajero del manifiesto, tal como lo envía la interfaz. */
export const esquemaPasajero = z.object({
  tipoDocumento: z.enum(['CI', 'NIT', 'PASAPORTE', 'OTRO']),
  numeroDocumento: z.string().trim().min(3).max(30),
  nombres: z.string().trim().min(2).max(100),
  apellidos: z.string().trim().min(2).max(100),
  fechaNacimiento: z
    .string()
    .trim()
    .regex(/^\d{4}-\d{2}-\d{2}$/)
    .optional()
    .or(z.literal('')),
})

/** Cuerpo del guardado del manifiesto: la lista completa de pasajeros. */
export const esquemaManifiesto = z.object({
  pasajeros: z
    .array(esquemaPasajero)
    .min(1, 'manifiesto_vacio')
    .max(Math.max(SOLICITUD_WEB_MAXIMO_PASAJEROS, 60), 'manifiesto_grande'),
})

/** Fila de la tabla `pasajero`. */
export interface FilaPasajero {
  idPasajero: number
  tipoDocumento: string
  numeroDocumento: string
  nombres: string
  apellidos: string
  fechaNacimiento: string | null
}

/** Convierte la fila de la base en lo que consume la interfaz. */
export function aPasajeroResumen(fila: FilaPasajero): PasajeroResumen {
  return {
    idPasajero: fila.idPasajero,
    tipoDocumento: fila.tipoDocumento as TipoDocumento,
    numeroDocumento: fila.numeroDocumento,
    nombres: fila.nombres,
    apellidos: fila.apellidos,
    fechaNacimiento: fila.fechaNacimiento,
  }
}

/** Lista el manifiesto de una reserva con su cantidad declarada. */
export async function obtenerManifiesto(
  idReserva: number,
): Promise<RespuestaPasajeros> {
  const filas = await useDb()
    .select({
      idPasajero: schema.pasajero.idPasajero,
      tipoDocumento: schema.pasajero.tipoDocumento,
      numeroDocumento: schema.pasajero.numeroDocumento,
      nombres: schema.pasajero.nombres,
      apellidos: schema.pasajero.apellidos,
      fechaNacimiento: schema.pasajero.fechaNacimiento,
    })
    .from(schema.reservaPasajero)
    .innerJoin(
      schema.pasajero,
      eq(schema.pasajero.idPasajero, schema.reservaPasajero.idPasajero),
    )
    .where(eq(schema.reservaPasajero.idReserva, idReserva))
    .orderBy(schema.pasajero.apellidos, schema.pasajero.nombres)

  const [reserva] = await useDb()
    .select({ cantidad: schema.reserva.cantidadPasajeros })
    .from(schema.reserva)
    .where(eq(schema.reserva.idReserva, idReserva))
    .limit(1)

  return {
    pasajeros: filas.map(aPasajeroResumen),
    cantidadDeclarada: reserva?.cantidad ?? 0,
  }
}

/** Guarda el manifiesto llamando a la función de la base. */
export async function guardarManifiesto(
  idReserva: number,
  pasajeros: Array<ReturnType<typeof esquemaPasajero.parse>>,
  idUsuario: string,
): Promise<void> {
  const cuerpo = JSON.stringify(
    pasajeros.map((pasajero) => ({
      tipo_documento: pasajero.tipoDocumento,
      numero_documento: pasajero.numeroDocumento.toUpperCase(),
      nombres: pasajero.nombres,
      apellidos: pasajero.apellidos,
      fecha_nacimiento: pasajero.fechaNacimiento || '',
    })),
  )

  try {
    await useDb().execute(sql`
      select turismo.fn_guardar_manifiesto(
        ${idReserva}::bigint,
        ${cuerpo}::jsonb,
        ${idUsuario}::text
      ) as cantidad
    `)
  } catch (error) {
    if ((error as { statusCode?: number }).statusCode) throw error
    console.error('[manifiesto] error real:', error)
    throw createError({
      statusCode: 400,
      statusMessage: codigoErrorManifiesto(error),
    })
  }
}

/** El error original de PostgreSQL, aunque Drizzle lo envuelva. */
export function causaBase(error: unknown): { code?: string; message?: string } {
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

/** Traduce una violación de la base a un código de la interfaz. */
export function codigoErrorManifiesto(error: unknown): string {
  const base = causaBase(error)
  const codigo = base.code
  const mensaje = base.message ?? ''

  if (mensaje.includes('ficha de otro cliente')) return 'pasajero_ajeno'
  if (mensaje.includes('manifiesto necesita')) return 'manifiesto_vacio'
  if (mensaje.includes('pagos comprometidos superan')) return 'pagos_excedidos'
  if (mensaje.includes('cupo suficiente')) return 'cupo_insuficiente'
  if (mensaje.includes('ya tiene una solicitud pendiente')) {
    return 'solicitud_pendiente'
  }
  if (mensaje.includes('no existe o no admite reservas')) {
    return 'salida_no_disponible'
  }
  if (mensaje.includes('admite su manifiesto')) return 'reserva_no_editable'
  if (mensaje.includes('hasta 4 pasajeros')) return 'solicitud_grande'
  if (mensaje.includes('debe ser mayor que cero')) return 'datos_invalidos'

  if (codigo === '23505') return 'pasajero_duplicado'
  if (codigo === '23503') return 'datos_invalidos'
  if (codigo === 'P0002') return 'reserva_inexistente'
  return 'datos_invalidos'
}
