import type { ProveedorAdmin } from '#shared/types/api'
import { exigirAdmin } from '../../../../utils/autorizacion'
import {
  esquemaVinculo,
  vincularPaquete,
} from '../../../../utils/proveedores'
import { leerCuerpo } from '../../../../utils/validacion'

/**
 * Vincula un proveedor con un paquete, o actualiza el servicio y el costo
 * del vínculo existente.
 */
export default defineEventHandler(async (event): Promise<ProveedorAdmin> => {
  exigirAdmin(event)
  const id = Number(getRouterParam(event, 'id'))

  if (!Number.isInteger(id) || id < 1) {
    throw createError({ statusCode: 400, statusMessage: 'datos_invalidos' })
  }

  const datos = await leerCuerpo(event, esquemaVinculo)
  return vincularPaquete(id, datos)
})
