import type { ProveedorAdmin } from '#shared/types/api'
import { exigirAdmin } from '../../../../../utils/autorizacion'
import { desvincularPaquete } from '../../../../../utils/proveedores'

/**
 * Quita el vínculo de un proveedor con un paquete.
 */
export default defineEventHandler(async (event): Promise<ProveedorAdmin> => {
  exigirAdmin(event)
  const id = Number(getRouterParam(event, 'id'))
  const idPaquete = Number(getRouterParam(event, 'idPaquete'))

  if (
    !Number.isInteger(id) ||
    id < 1 ||
    !Number.isInteger(idPaquete) ||
    idPaquete < 1
  ) {
    throw createError({ statusCode: 400, statusMessage: 'datos_invalidos' })
  }

  return desvincularPaquete(id, idPaquete)
})
