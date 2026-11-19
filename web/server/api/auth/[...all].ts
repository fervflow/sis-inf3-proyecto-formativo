import { toNodeHandler } from 'better-auth/node'

/**
 * Manejador de autenticación.
 *
 * Better Auth expone sus rutas (`/api/auth/*`) a través de un manejador
 * de Node. Se monta en el servidor de Nitro, junto al resto de la API.
 */
export default defineEventHandler((event) => {
  const ruta = event.path.split('?')[0] ?? ''

  // El registro público está cerrado: las cuentas las crea únicamente el
  // administrador desde el panel. La ruta se bloquea también para quien
  // intente llamarla directamente, no solo para la interfaz.
  if (ruta.startsWith('/api/auth/sign-up')) {
    throw createError({ statusCode: 404, statusMessage: 'not_found' })
  }

  return toNodeHandler(useAuth())(event.node.req, event.node.res)
})
