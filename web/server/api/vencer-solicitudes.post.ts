import { sql } from 'drizzle-orm'
import { consultar } from '../utils/db'

/**
 * Barrido diario de las solicitudes pendientes vencidas.
 *
 * La regla de las 48 horas no depende de este proceso: una solicitud
 * pendiente cuyo plazo venció deja de ocupar cupo en el momento en que
 * expira, porque así lo calculan las vistas. Esta rutina es la limpieza:
 * pasa las solicitudes vencidas a 'vencida' y deja la auditoría.
 *
 * La invoca el planificador de Vercel (ver `web/vercel.json`) una vez al
 * día. Se protege con `CRON_SECRET`, que Vercel envía en la cabecera
 * `Authorization` cuando esa variable está declarada en el proyecto.
 */
export default defineEventHandler(async (event) => {
  const config = configServidor()

  if (config.cronSecret) {
    const encabezado = getHeader(event, 'authorization') ?? ''
    if (encabezado !== `Bearer ${config.cronSecret}`) {
      throw createError({ statusCode: 401, statusMessage: 'No autorizado' })
    }
  }

  const [resultado] = await consultar<{ vencidas: number }>(
    sql`select turismo.fn_vencer_solicitudes_pendientes() as vencidas`,
  )

  return { vencidas: resultado?.vencidas ?? 0 }
})
