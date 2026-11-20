import { getSessionCookie } from 'better-auth/cookies'
import { eq } from 'drizzle-orm'
import * as schema from '../../db/schema'
import { ROL_ADMIN, ROL_PERSONAL } from '../utils/autorizacion'

/**
 * Sesión de la petición.
 *
 * Adjunta a `event.context.session` la sesión del usuario cuando hay una
 * cookie válida. No consulta la base si no hay cookie, de modo que las
 * peticiones públicas no pagan el costo de una búsqueda de sesión.
 *
 * Además aplica dos reglas de acceso que no pueden quedar solo en la
 * interfaz:
 *
 * - una cuenta bloqueada o inactiva no conserva la sesión;
 * - una contraseña inicial sin cambiar solo permite llegar a la pantalla
 *   de cambio.
 */
export default defineEventHandler(async (event) => {
  event.context = { ...event.context, session: null }

  const cookie = getSessionCookie(event.headers)
  if (!cookie) {
    return
  }

  try {
    const session = await useAuth().api.getSession({ headers: event.headers })
    event.context = { ...event.context, session }
  } catch (error) {
    console.error('No se pudo leer la sesión:', error)
    return
  }

  const sesion = event.context.session as
    | {
        user: {
          id: string
          idRol: number | null
          estado: string
          debeCambiarPassword: boolean
        }
      }
    | null
    | undefined

  if (!sesion?.user) {
    return
  }

  const ruta = (event.path.split('?')[0] ?? '/') || '/'
  const esApi = ruta.startsWith('/api/')
  const esAuth = ruta.startsWith('/api/auth/')

  // Una cuenta bloqueada o inactiva pierde la sesión en el acto.
  if (sesion.user.estado !== 'activo') {
    await useDb().delete(schema.session).where(eq(schema.session.userId, sesion.user.id))
    event.context = { ...event.context, session: null }

    if (esApi) {
      throw createError({ statusCode: 403, statusMessage: 'cuenta_inactiva' })
    }
    return sendRedirect(event, '/ingresar')
  }

  // Las rutas de la biblioteca y los archivos estáticos no se tocan.
  if (esAuth || esRecurso(ruta)) {
    return
  }

  // Contraseña inicial: solo se puede cambiar o consultar la cuenta.
  if (sesion.user.debeCambiarPassword) {
    const permitidas = new Set([
      '/cambiar-password',
      '/api/cuenta',
      '/api/cuenta/cambiar-password',
    ])

    if (!permitidas.has(ruta)) {
      if (esApi) {
        throw createError({ statusCode: 403, statusMessage: 'cambio_pendiente' })
      }
      return sendRedirect(event, '/cambiar-password')
    }
    return
  }

  if (ruta === '/ingresar') {
    return sendRedirect(event, '/')
  }

  // El panel de administración exige el rol en el servidor, no solo en
  // la interfaz.
  if (ruta.startsWith('/admin') || ruta.startsWith('/api/admin')) {
    if (sesion.user.idRol !== ROL_ADMIN) {
      if (esApi) {
        throw createError({ statusCode: 403, statusMessage: 'sin_permiso' })
      }
      return sendRedirect(event, '/')
    }
  }

  // La ficha de clientes la maneja el personal; el cliente no entra.
  if (ruta.startsWith('/clientes') || ruta.startsWith('/api/clientes')) {
    const esPersonal =
      sesion.user.idRol === ROL_ADMIN || sesion.user.idRol === ROL_PERSONAL

    if (!esPersonal) {
      if (esApi) {
        throw createError({ statusCode: 403, statusMessage: 'sin_permiso' })
      }
      return sendRedirect(event, '/')
    }
  }
})

/** Archivos y respuestas internas de Nuxt que nunca se redirigen. */
function esRecurso(ruta: string): boolean {
  return (
    ruta.startsWith('/_nuxt') ||
    ruta.startsWith('/_payload') ||
    ruta.startsWith('/__nuxt') ||
    ruta === '/favicon.ico' ||
    /\.[a-z0-9]+$/i.test(ruta)
  )
}
