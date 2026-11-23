import type { RespuestaCotizaciones } from '#shared/types/api'
import { exigirPersonal } from '../utils/autorizacion'
import { listarCotizaciones } from '../utils/cotizaciones'

/**
 * Cotizaciones del personal. El barrido de vencidas se ejecuta al listar.
 */
export default defineEventHandler(
  async (event): Promise<RespuestaCotizaciones> => {
    exigirPersonal(event)
    return { cotizaciones: await listarCotizaciones() }
  },
)
