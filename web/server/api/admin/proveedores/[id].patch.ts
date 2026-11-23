import type { ProveedorAdmin } from '#shared/types/api'
import { exigirAdmin } from '../../../utils/autorizacion'
import {
  actualizarProveedor,
  esquemaProveedor,
} from '../../../utils/proveedores'
import { leerCuerpo } from '../../../utils/validacion'

/**
 * Edición de un proveedor. El estado permite retirarlo sin borrar sus
 * vínculos.
 */
export default defineEventHandler(async (event): Promise<ProveedorAdmin> => {
  exigirAdmin(event)
  const id = Number(getRouterParam(event, 'id'))

  if (!Number.isInteger(id) || id < 1) {
    throw createError({ statusCode: 400, statusMessage: 'datos_invalidos' })
  }

  const datos = await leerCuerpo(event, esquemaProveedor)
  return actualizarProveedor(id, datos)
})
