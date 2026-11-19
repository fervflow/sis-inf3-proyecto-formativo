import { APIError } from 'better-auth/api'
import { eq } from 'drizzle-orm'
import { z } from 'zod'
import * as schema from '../../../db/schema'
import type { RespuestaOperacion } from '#shared/types/api'
import { exigirSesion } from '../../utils/autorizacion'
import { leerCuerpo } from '../../utils/validacion'

/**
 * Cambio de contraseña de la propia cuenta.
 *
 * Better Auth verifica la contraseña actual; la aplicación solo apaga el
 * indicador de contraseña inicial cuando el cambio se hizo de verdad.
 */
const cuerpo = z.object({
  actual: z.string().min(1).max(128),
  nueva: z.string().min(8).max(128),
})

export default defineEventHandler(async (event): Promise<RespuestaOperacion> => {
  const sesion = exigirSesion(event)
  const datos = await leerCuerpo(event, cuerpo)

  if (datos.nueva === datos.actual) {
    throw createError({ statusCode: 400, statusMessage: 'password_igual' })
  }

  try {
    await useAuth().api.changePassword({
      body: {
        currentPassword: datos.actual,
        newPassword: datos.nueva,
      },
      headers: event.headers,
    })
  } catch (error) {
    if (error instanceof APIError) {
      throw createError({
        statusCode: 400,
        statusMessage:
          error.body?.code === 'INVALID_PASSWORD'
            ? 'password_incorrecta'
            : 'datos_invalidos',
      })
    }
    throw error
  }

  await useDb()
    .update(schema.usuario)
    .set({ debeCambiarPassword: false, updatedAt: new Date() })
    .where(eq(schema.usuario.id, sesion.user.id))

  return { ok: true }
})
