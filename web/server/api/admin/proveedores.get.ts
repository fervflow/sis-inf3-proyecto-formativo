import type { RespuestaProveedores } from '#shared/types/api'
import { exigirAdmin } from '../../utils/autorizacion'
import { listarProveedores } from '../../utils/proveedores'

/**
 * Catálogo de proveedores con los paquetes que atienden.
 */
export default defineEventHandler(
  async (event): Promise<RespuestaProveedores> => {
    exigirAdmin(event)
    return { proveedores: await listarProveedores() }
  },
)
