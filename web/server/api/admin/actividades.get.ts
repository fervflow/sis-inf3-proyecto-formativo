import type { RespuestaActividades } from '#shared/types/api'
import { exigirAdmin } from '../../utils/autorizacion'
import { listarActividades } from '../../utils/paquetes'

/**
 * Catálogo fijo de acciones comunes del itinerario.
 */
export default defineEventHandler(async (event): Promise<RespuestaActividades> => {
  exigirAdmin(event)
  return { actividades: await listarActividades() }
})
