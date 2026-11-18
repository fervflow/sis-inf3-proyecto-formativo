/**
 * Configuración del servidor.
 *
 * Las variables se leen **en tiempo de ejecución**, no al compilar: así la
 * cadena de conexión y los secretos no quedan escritos dentro del paquete
 * que se despliega.
 *
 * Se aceptan las dos formas:
 *
 * - `DATABASE_URL` y compañía, tal como las deja la CLI de Neon.
 * - `NUXT_DATABASE_URL` y compañía, la forma propia de Nuxt, que tiene
 *   prioridad sobre la anterior.
 */
export function configServidor() {
  const config = useRuntimeConfig()

  return {
    databaseUrl: config.databaseUrl || process.env.DATABASE_URL || '',
    betterAuthSecret:
      config.betterAuthSecret || process.env.BETTER_AUTH_SECRET || '',
    betterAuthUrl: config.betterAuthUrl || process.env.BETTER_AUTH_URL || '',
    cronSecret: config.cronSecret || process.env.CRON_SECRET || '',
  }
}
