import type { CotizacionAdmin } from '#shared/types/api'
import { exigirPersonal } from '../../utils/autorizacion'
import {
  actualizarCotizacion,
  esquemaCotizacion,
} from '../../utils/cotizaciones'
import { leerCuerpo } from '../../utils/validacion'

/**
 * Edición de una cotización en borrador o enviada.
 */
export default defineEventHandler(
  async (event): Promise<CotizacionAdmin> => {
    exigirPersonal(event)
    const id = Number(getRouterParam(event, 'id'))

    if (!Number.isInteger(id) || id < 1) {
      throw createError({ statusCode: 400, statusMessage: 'datos_invalidos' })
    }

    const datos = await leerCuerpo(event, esquemaCotizacion)
    return actualizarCotizacion(id, datos)
  },
)
