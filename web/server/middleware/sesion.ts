import { getSessionCookie } from 'better-auth/cookies'

/**
 * Sesión de la petición.
 *
 * Adjunta a `event.context.session` la sesión del usuario cuando hay una
 * cookie válida. No consulta la base si no hay cookie, de modo que las
 * peticiones públicas no pagan el costo de una búsqueda de sesión.
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
  }
})
