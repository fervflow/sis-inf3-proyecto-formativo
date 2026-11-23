import type { CotizacionAdmin } from '#shared/types/api'
import { exigirPersonal } from '../utils/autorizacion'
import {
  crearCotizacion,
  esquemaCotizacion,
} from '../utils/cotizaciones'
import { leerCuerpo } from '../utils/validacion'

/**
 * Alta de una cotización para una salida. No descuenta cupo.
 */
export default defineEventHandler(
  async (event): Promise<CotizacionAdmin> => {
    const sesion = exigirPersonal(event)
    const datos = await leerCuerpo(event, esquemaCotizacion)
    return crearCotizacion(datos, sesion.user.id)
  },
)
