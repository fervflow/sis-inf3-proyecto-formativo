import { and, eq, sql } from 'drizzle-orm'
import * as schema from '../../../db/schema'
import type { SalidaAdmin } from '#shared/types/api'
import { exigirAdmin } from '../../utils/autorizacion'
import { consultar } from '../../utils/db'
import {
  codigoErrorSalida,
  diasInclusivos,
  esquemaSalida,
  hoyIso,
  obtenerSalida,
  reemplazarAsignaciones,
  validarAsignaciones,
} from '../../utils/salidas'
import { leerCuerpo } from '../../utils/validacion'

/**
 * Alta de una salida programada.
 *
 * Las validaciones de negocio se repiten aquí para devolver un código
 * claro; la función `fn_crear_salida` las vuelve a aplicar dentro de la
 * transacción y es la que manda.
 */
export default defineEventHandler(async (event): Promise<SalidaAdmin> => {
  const sesion = exigirAdmin(event)
  const datos = await leerCuerpo(event, esquemaSalida)
  const db = useDb()

  const [paquete] = await db
    .select({
      estado: schema.paquete.estado,
      duracionDias: schema.paquete.duracionDias,
    })
    .from(schema.paquete)
    .where(eq(schema.paquete.idPaquete, datos.idPaquete))
    .limit(1)

  if (!paquete) {
    throw createError({ statusCode: 404, statusMessage: 'paquete_inexistente' })
  }
  if (paquete.estado !== 'activo') {
    throw createError({ statusCode: 400, statusMessage: 'paquete_inactivo' })
  }
  if (datos.fechaSalida < hoyIso()) {
    throw createError({ statusCode: 400, statusMessage: 'fecha_pasada' })
  }
  if (
    diasInclusivos(datos.fechaSalida, datos.fechaRetorno) !==
    paquete.duracionDias
  ) {
    throw createError({ statusCode: 400, statusMessage: 'duracion_incoherente' })
  }

  const [duplicada] = await db
    .select({ idSalida: schema.salida.idSalida })
    .from(schema.salida)
    .where(
      and(
        eq(schema.salida.idPaquete, datos.idPaquete),
        eq(schema.salida.fechaSalida, datos.fechaSalida),
      ),
    )
    .limit(1)

  if (duplicada) {
    throw createError({ statusCode: 409, statusMessage: 'salida_duplicada' })
  }

  // Las asignaciones usan proveedores activos con el tipo declarado
  // (RN-SAL-23 y RN-PRV-06).
  await validarAsignaciones(datos.asignaciones)

  try {
    const filas = await consultar<{ id_salida: string | number }>(sql`
      select turismo.fn_crear_salida(
        ${datos.idPaquete}::bigint,
        ${datos.fechaSalida}::date,
        ${datos.fechaRetorno}::date,
        ${datos.cupoMaximo}::integer,
        ${datos.precio}::numeric,
        ${sesion.user.id}::text,
        ${datos.puntoEncuentro || null}::varchar,
        ${datos.observaciones || null}::text
      ) as id_salida
    `)

    const idSalida = Number(filas[0]?.id_salida)
    if (!Number.isInteger(idSalida) || idSalida < 1) {
      throw createError({ statusCode: 500, statusMessage: 'alta_incompleta' })
    }

    await reemplazarAsignaciones(idSalida, datos.asignaciones)

    const salida = await obtenerSalida(idSalida)
    if (!salida) {
      throw createError({ statusCode: 500, statusMessage: 'alta_incompleta' })
    }
    return salida
  } catch (error) {
    if ((error as { statusCode?: number }).statusCode) throw error
    throw createError({
      statusCode: 400,
      statusMessage: codigoErrorSalida(error),
    })
  }
})


