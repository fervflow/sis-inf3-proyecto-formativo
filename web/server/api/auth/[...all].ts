import { toNodeHandler } from 'better-auth/node'

/**
 * Manejador de autenticación.
 *
 * Better Auth expone sus rutas (`/api/auth/*`) a través de un manejador
 * de Node. Se monta en el servidor de Nitro, junto al resto de la API.
 */
export default defineEventHandler((event) => {
  return toNodeHandler(useAuth())(event.node.req, event.node.res)
})
