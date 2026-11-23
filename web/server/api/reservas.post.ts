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
  buscarClientePorDocumento,
  codigoErrorReserva,
  esquemaReservaPersonal,
  esquemaReservaPublica,
  idUsuarioSistema,
  obtenerReserva,
  validarCotizacionOrigen,
} from '../utils/reservas'
import { leerCuerpo } from '../utils/validacion'

/**
 * Alta de una reserva en los dos canales (HU-06).
 *
 * - Con sesión de personal (`ADMIN` o `PERSONAL`), la reserva nace del
 *   canal `personal`: el cliente se elige de las fichas registradas.
 * - Sin sesión, es la solicitud directa del cliente por el canal `web`:
 *   el cliente se identifica por documento y, si no tiene ficha, se
 *   registra con los datos de contacto que envía.
 *
 * La validación de cupos y la creación con vencimiento de 48 horas están
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

  if (sesion) {
    // El cliente autenticado podrá reservar desde su cuenta cuando se
    // implemente HU-15; por ahora solo el personal y el anónimo llegan.
    throw createError({ statusCode: 403, statusMessage: 'sin_permiso' })
  }

  return crearReservaPublica(await leerCuerpo(event, esquemaReservaPublica))
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

/** Solicitud directa del cliente por el canal web. */
async function crearReservaPublica(
  datos: ReturnType<typeof esquemaReservaPublica.parse>,
): Promise<ReservaResumen> {
  const documento = datos.numeroDocumento.trim().toUpperCase()
  const db = useDb()

  // La ficha se reutiliza si existe; si no, se registra con lo que envía
  // el formulario. El documento es la clave de negocio y evita duplicados.
  let idCliente = await buscarClientePorDocumento(datos.tipoDocumento, documento)

  if (!idCliente) {
    try {
      const [creada] = await db
        .insert(schema.cliente)
        .values({
          tipoDocumento: datos.tipoDocumento,
          numeroDocumento: documento,
          nombres: datos.nombres,
          apellidos: datos.apellidos,
          correo: datos.correo || null,
          telefono: datos.telefono || null,
        })
        .returning({ idCliente: schema.cliente.idCliente })
      idCliente = creada?.idCliente ?? null
    } catch (error) {
      // Una carrera entre dos solicitudes con el mismo documento se
      // resuelve buscando la ficha que la otra petición creó.
      if ((error as { code?: string }).code === '23505') {
        idCliente = await buscarClientePorDocumento(datos.tipoDocumento, documento)
      }
      if (!idCliente) throw error
    }
  }

  if (idCliente === null) {
    throw createError({ statusCode: 500, statusMessage: 'alta_incompleta' })
  }

  const idUsuario = await idUsuarioSistema()

  try {
    const filas = await consultar<{ id_reserva: string | number }>(sql`
      select turismo.fn_crear_reserva(
        ${idCliente}::bigint,
        ${datos.idSalida}::bigint,
        ${datos.cantidadPasajeros}::integer,
        'web',
        ${idUsuario}::text
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
