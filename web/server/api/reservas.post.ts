import { eq, sql } from 'drizzle-orm'
import * as schema from '../../db/schema'
import type { ReservaResumen } from '#shared/types/api'
import {
  ROL_ADMIN,
  ROL_PERSONAL,
  sesionActual,
} from '../utils/autorizacion'
import { consultar } from '../utils/db'
import {
  codigoErrorReserva,
  esquemaReservaCliente,
  esquemaReservaPersonal,
  obtenerReserva,
  validarCotizacionOrigen,
} from '../utils/reservas'
import { leerCuerpo } from '../utils/validacion'

/**
 * Alta de una reserva en los dos canales (HU-06).
 *
 * - Con sesión de personal (`ADMIN` o `PERSONAL`), la reserva nace del
 *   canal `personal`: el cliente se elige de las fichas registradas.
 * - Con sesión de cliente, es la solicitud del canal `web`: usa la ficha
 *   vinculada a su cuenta (RN-USU-02) y queda firmada por ella
 *   (RN-RES-10). Sin sesión no hay solicitud: la interfaz redirige a
 *   ingresar o crear cuenta y la API responde 401 (RN-RES-17).
 *
 * La validación de cupos y la creación con vencimiento de 24 horas están
 * en `fn_crear_reserva`, que bloquea la fila de la salida.
 */
export default defineEventHandler(async (event): Promise<ReservaResumen> => {
  const sesion = sesionActual(event)
  const esPersonal =
    sesion?.user &&
    (sesion.user.idRol === ROL_ADMIN || sesion.user.idRol === ROL_PERSONAL)

  if (esPersonal) {
    return crearReservaPersonal(await leerCuerpo(event, esquemaReservaPersonal), sesion.user.id)
  }

  if (sesion?.user) {
    return crearReservaCliente(
      await leerCuerpo(event, esquemaReservaCliente),
      sesion.user,
    )
  }

  throw createError({ statusCode: 401, statusMessage: 'sesion_requerida' })
})

/** Alta desde la atención del personal. */
async function crearReservaPersonal(
  datos: ReturnType<typeof esquemaReservaPersonal.parse>,
  idUsuario: string,
): Promise<ReservaResumen> {
  const db = useDb()

  const [cliente] = await db
    .select({ estado: schema.cliente.estado })
    .from(schema.cliente)
    .where(eq(schema.cliente.idCliente, datos.idCliente))
    .limit(1)

  if (!cliente) {
    throw createError({ statusCode: 404, statusMessage: 'cliente_inexistente' })
  }
  if (cliente.estado !== 'activo') {
    throw createError({ statusCode: 400, statusMessage: 'cliente_inactivo' })
  }

  if (datos.idCotizacion) {
    await validarCotizacionOrigen(datos.idCotizacion, datos.idCliente, datos.idSalida)
  }

  try {
    const filas = await consultar<{ id_reserva: string | number }>(sql`
      select turismo.fn_crear_reserva(
        ${datos.idCliente}::bigint,
        ${datos.idSalida}::bigint,
        ${datos.cantidadPasajeros}::integer,
        'personal',
        ${idUsuario}::text,
        ${datos.idCotizacion ?? null}::bigint
      ) as id_reserva
    `)

    const reserva = await obtenerReserva(Number(filas[0]?.id_reserva))
    if (!reserva) {
      throw createError({ statusCode: 500, statusMessage: 'alta_incompleta' })
    }
    return reserva
  } catch (error) {
    if ((error as { statusCode?: number }).statusCode) throw error
    throw createError({
      statusCode: 400,
      statusMessage: codigoErrorReserva(error),
    })
  }
}

/** Solicitud del cliente con sesión (canal web). */
async function crearReservaCliente(
  datos: ReturnType<typeof esquemaReservaCliente.parse>,
  usuario: { id: string },
): Promise<ReservaResumen> {
  const db = useDb()

  // La ficha viene de la cuenta: el canal web ya no registra fichas al
  // vuelo (RN-RES-11). Una cuenta sin ficha no puede reservar.
  const [ficha] = await db
    .select({ idCliente: schema.cliente.idCliente, estado: schema.cliente.estado })
    .from(schema.cliente)
    .where(eq(schema.cliente.idUsuario, usuario.id))
    .limit(1)

  if (!ficha) {
    throw createError({ statusCode: 409, statusMessage: 'sin_ficha' })
  }
  if (ficha.estado !== 'activo') {
    throw createError({ statusCode: 400, statusMessage: 'cliente_inactivo' })
  }

  try {
    const filas = await consultar<{ id_reserva: string | number }>(sql`
      select turismo.fn_crear_reserva(
        ${ficha.idCliente}::bigint,
        ${datos.idSalida}::bigint,
        ${datos.cantidadPasajeros}::integer,
        'web',
        ${usuario.id}::text
      ) as id_reserva
    `)

    const reserva = await obtenerReserva(Number(filas[0]?.id_reserva))
    if (!reserva) {
      throw createError({ statusCode: 500, statusMessage: 'alta_incompleta' })
    }
    return reserva
  } catch (error) {
    if ((error as { statusCode?: number }).statusCode) throw error
    throw createError({
      statusCode: 400,
      statusMessage: codigoErrorReserva(error),
    })
  }
}
