import { tema } from './design/tema'

/**
 * Configuración de la aplicación, accesible desde `useAppConfig()`.
 *
 * El tema de Nuxt UI vive aquí. Los colores vienen de los tokens del
 * sistema de diseño, definidos en `app/design/tokens.css`.
 */
export default defineAppConfig({
  ui: tema,
})
