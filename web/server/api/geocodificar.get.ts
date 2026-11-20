import type { RespuestaGeocodificacion } from '#shared/types/api'
import { exigirAdmin } from '../utils/autorizacion'
import { geocodificar } from '../utils/lugares'

/**
 * Búsqueda de lugares en Photon. La interfaz la usa para autocompletar;
 * el paquete guarda el lugar elegido, no el resultado externo.
 */
export default defineEventHandler(
  async (event): Promise<RespuestaGeocodificacion> => {
    exigirAdmin(event)
    const q = getQuery(event).q
    const texto = typeof q === 'string' ? q.trim() : ''

    if (texto.length < 3) {
      return { resultados: [] }
    }

    return { resultados: await geocodificar(texto) }
  },
)
