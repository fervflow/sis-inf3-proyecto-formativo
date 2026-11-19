import { eq } from 'drizzle-orm'
import { z } from 'zod'
import * as schema from '../../../../db/schema'
import type { RespuestaOperacion } from '#shared/types/api'
import { exigirAdmin } from '../../../utils/autorizacion'
import { idRolDe } from '../../../utils/usuarios'
import { leerCuerpo } from '../../../utils/validacion'

/**
 * Cambio de rol o de estado de una cuenta.
 *
 * El administrador no puede modificarse a sí mismo: un error dejaría el
 * sistema sin nadie que pueda entrar al panel.
 */
const cuerpo = z
  .object({
    rol: z.enum(['ADMIN', 'PERSONAL', 'TURISTA']).optional(),
    estado: z.enum(['activo', 'inactivo', 'bloqueado']).optional(),
  })
  .refine((datos) => datos.rol || datos.estado, {
    message: 'sin_cambios',
  })

export default defineEventHandler(async (event): Promise<RespuestaOperacion> => {
  const sesion = exigirAdmin(event)
  const id = getRouterParam(event, 'id')

  if (!id) {
    throw createError({ statusCode: 400, statusMessage: 'datos_invalidos' })
  }
  if (id === sesion.user.id) {
    throw createError({ statusCode: 400, statusMessage: 'propia_cuenta' })
  }

  const datos = await leerCuerpo(event, cuerpo)
  const db = useDb()

  const [objetivo] = await db
    .select({ id: schema.usuario.id })
    .from(schema.usuario)
    .where(eq(schema.usuario.id, id))
    .limit(1)

  if (!objetivo) {
    throw createError({ statusCode: 404, statusMessage: 'usuario_inexistente' })
  }

  const cambios: {
    idRol?: number
    estado?: 'activo' | 'inactivo' | 'bloqueado'
    updatedAt: Date
  } = { updatedAt: new Date() }

  if (datos.rol) {
    const idRol = await idRolDe(datos.rol)
    if (!idRol) {
      throw createError({ statusCode: 400, statusMessage: 'rol_invalido' })
    }
    cambios.idRol = idRol
  }
  if (datos.estado) {
    cambios.estado = datos.estado
  }

  await db
    .update(schema.usuario)
    .set(cambios)
    .where(eq(schema.usuario.id, id))

  // Si deja de estar activa, las sesiones abiertas se cierran.
  if (datos.estado && datos.estado !== 'activo') {
    await db.delete(schema.session).where(eq(schema.session.userId, id))
  }

  return { ok: true }
})
