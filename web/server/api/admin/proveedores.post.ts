import type { ProveedorAdmin } from '#shared/types/api'
import { exigirAdmin } from '../../utils/autorizacion'
import { crearProveedor, esquemaProveedor } from '../../utils/proveedores'
import { leerCuerpo } from '../../utils/validacion'

/**
 * Alta de un proveedor de servicios.
 */
export default defineEventHandler(async (event): Promise<ProveedorAdmin> => {
  exigirAdmin(event)
  const datos = await leerCuerpo(event, esquemaProveedor)
  return crearProveedor(datos)
})
