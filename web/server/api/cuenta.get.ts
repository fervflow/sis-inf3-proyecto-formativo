import { eq } from 'drizzle-orm'
import * as schema from '../../db/schema'
import { usuarioDeCorreo } from '#shared/usuarios'
import type { RespuestaCuenta } from '#shared/types/api'
import type { EstadoUsuario, Rol } from '#shared/types/domain'
import { sesionActual } from '../utils/autorizacion'

/**
 * Cuenta de la sesión en curso.
 *
 * La interfaz la usa para el encabezado y para decidir si muestra el
 * panel de administración. Devuelve `null` cuando no hay sesión: una
 * visita pública no es un error.
 */
export default defineEventHandler(async (event): Promise<RespuestaCuenta> => {
  const sesion = sesionActual(event)

  if (!sesion?.user) {
    return { usuario: null }
  }

  const [fila] = await useDb()
    .select({ codigo: schema.rol.codigo })
    .from(schema.rol)
    .where(eq(schema.rol.idRol, sesion.user.idRol ?? 0))
    .limit(1)

  return {
    usuario: {
      id: sesion.user.id,
      usuario: usuarioDeCorreo(sesion.user.email),
      nombres: sesion.user.nombres,
      apellidos: sesion.user.apellidos,
      rol: (fila?.codigo ?? 'TURISTA') as Rol,
      estado: sesion.user.estado as EstadoUsuario,
      debeCambiarPassword: sesion.user.debeCambiarPassword,
    },
  }
})
