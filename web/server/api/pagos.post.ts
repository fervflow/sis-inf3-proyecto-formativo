import { and, eq, sql } from 'drizzle-orm'
import * as schema from '../../db/schema'
import type { RespuestaPagos } from '#shared/types/api'
import {
  ROL_ADMIN,
  ROL_PERSONAL,
  sesionActual,
} from '../utils/autorizacion'
import { consultar } from '../utils/db'
import {
  codigoErrorPago,
  esquemaPagoCliente,
  esquemaPagoPersonal,
  obtenerPagosDeReserva,
} from '../utils/pagos'
import { referenciaSimulada } from '#shared/pagos'
import { leerCuerpo } from '../utils/validacion'

/**
 * Registro de un pago (HU-14).
 *
 * - Con sesión de cliente: pago sobre una reserva propia, con la pasarela
 *   simulada (`banca_movil` o `qr`). El pago nace `registrado` y la
 *   referencia la genera el servidor (RN-PAG-03 y RN-PAG-04).
 * - Con sesión de personal: pago de oficina sobre cualquier reserva.
 *   Nace `validado` con su usuario y fecha (RN-PAG-04).
 *
 * El mínimo del anticipo, el tope del saldo y la reserva pagable los
 * aplica `fn_registrar_pago` dentro de su transacción.
 */
export default defineEventHandler(async (event): Promise<RespuestaPagos> => {
  const sesion = sesionActual(event)
  const esPersonal =
    sesion?.user &&
    (sesion.user.idRol === ROL_ADMIN || sesion.user.idRol === ROL_PERSONAL)

  if (!sesion?.user) {
    throw createError({ statusCode: 401, statusMessage: 'sesion_requerida' })
  }

  if (esPersonal) {
    const datos = await leerCuerpo(event, esquemaPagoPersonal)
    await registrarPago(datos, sesion.user.id, true)
    return obtenerPagosDeReserva(datos.idReserva)
  }

  const datos = await leerCuerpo(event, esquemaPagoCliente)
  const ficha = await fichaDeCuenta(sesion.user.id)
  await exigirReservaPropia(datos.idReserva, ficha.idCliente)

  // La pasarela simulada genera la referencia; el pago del cliente nace
  // registrado a la espera de la validación del personal.
  await registrarPago(datos, sesion.user.id, false, referenciaSimulada(datos.tipo))
  return obtenerPagosDeReserva(datos.idReserva)
})

/** La ficha de la cuenta en sesión; sin ella, el cliente no paga. */
async function fichaDeCuenta(idUsuario: string): Promise<{ idCliente: number }> {
  const [ficha] = await useDb()
    .select({ idCliente: schema.cliente.idCliente })
    .from(schema.cliente)
    .where(eq(schema.cliente.idUsuario, idUsuario))
    .limit(1)

  if (!ficha) {
    throw createError({ statusCode: 409, statusMessage: 'sin_ficha' })
  }
  return ficha
}

/** Solo se paga sobre reservas propias (HU-15). */
async function exigirReservaPropia(
  idReserva: number,
  idCliente: number,
): Promise<void> {
  const [reserva] = await useDb()
    .select({ idCliente: schema.reserva.idCliente })
    .from(schema.reserva)
    .where(and(eq(schema.reserva.idReserva, idReserva), eq(schema.reserva.idCliente, idCliente)))
    .limit(1)

  if (!reserva) {
    throw createError({ statusCode: 404, statusMessage: 'reserva_inexistente' })
  }
}

/** Llama a `fn_registrar_pago` y traduce sus errores. */
async function registrarPago(
  datos: { idReserva: number; tipo: string; monto: number; metodo: string; referencia?: string; observacion?: string },
  idUsuario: string,
  validado: boolean,
  referencia?: string,
): Promise<void> {
  try {
    await consultar(sql`
      select turismo.fn_registrar_pago(
        ${datos.idReserva}::bigint,
        ${datos.tipo}::text,
        ${datos.monto}::numeric,
        ${datos.metodo}::text,
        ${idUsuario}::text,
        ${(referencia ?? datos.referencia ?? null)}::text,
        ${datos.observacion ?? null}::text,
        ${validado}::boolean
      ) as id_pago
    `)
  } catch (error) {
    if ((error as { statusCode?: number }).statusCode) throw error
    throw createError({
      statusCode: 400,
      statusMessage: codigoErrorPago(error),
    })
  }
}
