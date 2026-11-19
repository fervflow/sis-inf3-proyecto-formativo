import { hashPassword } from 'better-auth/crypto'
import { and, eq } from 'drizzle-orm'
import * as schema from '../../../../../db/schema'
import { usuarioDeCorreo } from '#shared/usuarios'
import type { RespuestaOperacion } from '#shared/types/api'
import { exigirAdmin } from '../../../../utils/autorizacion'

/**
 * Restablecimiento de la contraseña por el administrador.
 *
 * No hay correo en el MVP, así que la vía es volver a la contraseña
 * inicial (el nombre de usuario), cerrar las sesiones abiertas y obligar
 * el cambio en el siguiente ingreso.
 */
export default defineEventHandler(async (event): Promise<RespuestaOperacion> => {
  const sesion = exigirAdmin(event)
  const id = getRouterParam(event, 'id')

  if (!id) {
    throw createError({ statusCode: 400, statusMessage: 'datos_invalidos' })
  }
  if (id === sesion.user.id) {
    throw createError({ statusCode: 400, statusMessage: 'propia_cuenta' })
  }

  const db = useDb()

  const [objetivo] = await db
    .select({ id: schema.usuario.id, email: schema.usuario.email })
    .from(schema.usuario)
    .where(eq(schema.usuario.id, id))
    .limit(1)

  if (!objetivo) {
    throw createError({ statusCode: 404, statusMessage: 'usuario_inexistente' })
  }

  const usuario = usuarioDeCorreo(objetivo.email)
  const clave = await hashPassword(usuario)

  const actualizadas = await db
    .update(schema.account)
    .set({ password: clave, updatedAt: new Date() })
    .where(
      and(
        eq(schema.account.userId, id),
        eq(schema.account.providerId, 'credential'),
      ),
    )
    .returning({ id: schema.account.id })

  if (actualizadas.length === 0) {
    throw createError({ statusCode: 400, statusMessage: 'sin_contrasena' })
  }

  await db
    .update(schema.usuario)
    .set({ debeCambiarPassword: true, updatedAt: new Date() })
    .where(eq(schema.usuario.id, id))

  await db.delete(schema.session).where(eq(schema.session.userId, id))

  return { ok: true }
})
