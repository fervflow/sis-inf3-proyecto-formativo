/**
 * Autorización de las rutas del servidor.
 *
 * La sesión la adjunta `server/middleware/sesion.ts`. Aquí solo se
 * comprueba lo que cada ruta necesita: sesión, cuenta activa y rol.
 *
 * El rol `ADMIN` es el identificador 1 en la semilla de `rol` (ver
 * `bd/esquema.sql`).
 */
import type { H3Event } from 'h3'

/** El rol de administrador en la tabla `rol`. */
export const ROL_ADMIN = 1

/** El rol de personal de la agencia en la tabla `rol`. */
export const ROL_PERSONAL = 2

/** Datos de la cuenta que viajan en la sesión. */
export interface UsuarioSesion {
  id: string
  email: string
  name: string
  idRol: number | null
  nombres: string
  apellidos: string
  telefono: string | null
  estado: 'activo' | 'inactivo' | 'bloqueado'
  debeCambiarPassword: boolean
}

/** Sesión adjunta por el middleware. */
export interface SesionActual {
  session: {
    id: string
    userId: string
    token: string
    expiresAt: Date
  }
  user: UsuarioSesion
}

/** La sesión de la petición, o `null`. */
export function sesionActual(event: H3Event): SesionActual | null {
  return (event.context.session as SesionActual | null | undefined) ?? null
}

/** Exige una cuenta con sesión y en estado activo. */
export function exigirSesion(event: H3Event): SesionActual {
  const sesion = sesionActual(event)

  if (!sesion?.user) {
    throw createError({ statusCode: 401, statusMessage: 'sin_sesion' })
  }
  if (sesion.user.estado !== 'activo') {
    throw createError({ statusCode: 403, statusMessage: 'cuenta_inactiva' })
  }

  return sesion
}

/** Exige una cuenta con sesión y rol de administrador. */
export function exigirAdmin(event: H3Event): SesionActual {
  const sesion = exigirSesion(event)

  if (sesion.user.idRol !== ROL_ADMIN) {
    throw createError({ statusCode: 403, statusMessage: 'sin_permiso' })
  }

  return sesion
}

/** Exige una cuenta con sesión de administrador o personal de agencia. */
export function exigirPersonal(event: H3Event): SesionActual {
  const sesion = exigirSesion(event)

  if (sesion.user.idRol !== ROL_ADMIN && sesion.user.idRol !== ROL_PERSONAL) {
    throw createError({ statusCode: 403, statusMessage: 'sin_permiso' })
  }

  return sesion
}
