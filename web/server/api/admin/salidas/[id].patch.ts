import { eq, sql } from 'drizzle-orm'
import * as schema from '../../../../db/schema'
import type { SalidaAdmin } from '#shared/types/api'
import type { EstadoSalida } from '#shared/types/domain'
import { exigirAdmin } from '../../../utils/autorizacion'
import { consultar } from '../../../utils/db'
import {
  codigoErrorSalida,
  diasInclusivos,
  esquemaSalida,
  hoyIso,
  obtenerSalida,
  reemplazarAsignaciones,
  validarAsignaciones,
} from '../../../utils/salidas'
import { leerCuerpo } from '../../../utils/validacion'

/**
 * Edición de una salida programada.
 */
export default defineEventHandler(async (event): Promise<SalidaAdmin> => {
  const sesion = exigirAdmin(event)
  const id = Number(getRouterParam(event, 'id'))

  if (!Number.isInteger(id) || id < 1) {
    throw createError({ statusCode: 400, statusMessage: 'datos_invalidos' })
  }

  const datos = await leerCuerpo(event, esquemaSalida)
  const actual = await obtenerSalida(id)

  if (!actual) {
    throw createError({ statusCode: 404, statusMessage: 'salida_inexistente' })
  }
  if (actual.estado === 'realizada' || actual.estado === 'cancelada') {
    throw createError({ statusCode: 400, statusMessage: 'salida_no_editable' })
  }
  if (datos.idPaquete !== actual.idPaquete) {
    throw createError({ statusCode: 400, statusMessage: 'paquete_no_editable' })
  }
  if (datos.fechaSalida < hoyIso()) {
    throw createError({ statusCode: 400, statusMessage: 'fecha_pasada' })
  }
  if (datos.estado === 'cancelada' && !datos.motivo?.trim()) {
    throw createError({ statusCode: 400, statusMessage: 'motivo_requerido' })
  }

  validarTransicionSalida(actual.estado, datos.estado)

  // Las asignaciones usan proveedores activos con el tipo declarado
  // (RN-SAL-23 y RN-PRV-06).
  await validarAsignaciones(datos.asignaciones)

  const [paquete] = await useDb()
    .select({ duracionDias: schema.paquete.duracionDias })
    .from(schema.paquete)
    .where(eq(schema.paquete.idPaquete, datos.idPaquete))
    .limit(1)

  if (!paquete) {
    throw createError({ statusCode: 404, statusMessage: 'paquete_inexistente' })
  }
  if (
    diasInclusivos(datos.fechaSalida, datos.fechaRetorno) !==
    paquete.duracionDias
  ) {
    throw createError({ statusCode: 400, statusMessage: 'duracion_incoherente' })
  }

  try {
    await consultar(sql`
      select turismo.fn_actualizar_salida(
        ${id}::bigint,
        ${sesion.user.id}::text,
        ${datos.fechaSalida}::date,
        ${datos.fechaRetorno}::date,
        ${datos.cupoMaximo}::integer,
        ${datos.precio}::numeric,
        ${datos.motivo || null}::varchar,
        ${datos.puntoEncuentro ?? null}::varchar,
        ${datos.estado}::varchar
      )
    `)
  } catch (error) {
    if ((error as { statusCode?: number }).statusCode) throw error
    throw createError({
      statusCode: 400,
      statusMessage: codigoErrorSalida(error),
    })
  }

  await reemplazarAsignaciones(id, datos.asignaciones)

  const salida = await obtenerSalida(id)
  if (!salida) {
    throw createError({ statusCode: 404, statusMessage: 'salida_inexistente' })
  }
  return salida
})

/** Transiciones válidas de la salida. */
function validarTransicionSalida(
  actual: EstadoSalida,
  nuevo: EstadoSalida,
): void {
  if (actual === nuevo) return

  const permitidas: Record<EstadoSalida, EstadoSalida[]> = {
    programada: ['confirmada', 'cancelada'],
    confirmada: ['realizada', 'cancelada'],
    realizada: [],
    cancelada: [],
  }

  if (!permitidas[actual].includes(nuevo)) {
    throw createError({ statusCode: 400, statusMessage: 'transicion_invalida' })
  }
}
