import type { RespuestaServicios } from '#shared/types/api'
import { exigirAdmin } from '../../utils/autorizacion'
import { listarServicios } from '../../utils/paquetes'

/**
 * Catálogo fijo de servicios que un paquete puede incluir.
 */
export default defineEventHandler(async (event): Promise<RespuestaServicios> => {
  exigirAdmin(event)
  return { servicios: await listarServicios() }
})
