import { asc, eq } from 'drizzle-orm'
import * as schema from '../../../db/schema'
import type { RespuestaUsuarios } from '#shared/types/api'
import { exigirAdmin } from '../../utils/autorizacion'
import { aUsuarioAdmin, seleccionUsuario } from '../../utils/usuarios'

/**
 * Cuentas del sistema, para el panel de administración.
 */
export default defineEventHandler(async (event): Promise<RespuestaUsuarios> => {
  exigirAdmin(event)

  const filas = await useDb()
    .select(seleccionUsuario)
    .from(schema.usuario)
    .leftJoin(schema.rol, eq(schema.rol.idRol, schema.usuario.idRol))
    .orderBy(asc(schema.usuario.createdAt))

  return { usuarios: filas.map(aUsuarioAdmin) }
})
