import { sql } from 'drizzle-orm'
import type { RespuestaBarrido } from '#shared/types/api'
import { exigirPersonal } from '../../utils/autorizacion'
import { consultar } from '../../utils/db'

/**
 * Barrido manual de las solicitudes pendientes vencidas (HU-17,
 * T-HU-17.4).
 *
 * El personal lo ejecuta desde la bandeja de solicitudes, sin esperar al
 * barrido diario de Vercel (`/api/vencer-solicitudes`). Ninguna regla
 * depende de este proceso: una solicitud cuyo plazo venció deja de ocupar
 * cupo por el cálculo de las vistas; pasarla a `vencida` es limpieza con
 * su auditoría (RN-RES-09). La auditoría deja la cuenta que lo corrió.
 */
export default defineEventHandler(async (event): Promise<RespuestaBarrido> => {
  const sesion = exigirPersonal(event)

  const [resultado] = await consultar<{ vencidas: number }>(
    sql`select turismo.fn_vencer_solicitudes_pendientes(${sesion.user.id}::text) as vencidas`,
  )

  return { vencidas: resultado?.vencidas ?? 0 }
})
