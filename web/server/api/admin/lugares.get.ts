import type { RespuestaLugares } from '#shared/types/api'
import { exigirAdmin } from '../../utils/autorizacion'
import { listarLugares } from '../../utils/lugares'

/**
 * Catálogo de lugares. Acepta `q` para filtrar por nombre o código.
 */
export default defineEventHandler(async (event): Promise<RespuestaLugares> => {
  exigirAdmin(event)
  const q = getQuery(event).q
  return {
    lugares: await listarLugares(typeof q === 'string' ? q : undefined),
  }
})
