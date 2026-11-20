import { existsSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { loadEnvFile } from 'node:process'

// Archivos de entorno que se cargan en `process.env` antes de resolver la
// configuración: el de la aplicación y los del repositorio, donde la CLI
// de Neon deja las variables de la rama.
//
// El orden importa: en Node gana el primer valor, así que el archivo de la
// aplicación manda sobre el de Neon, y una variable ya presente en el
// entorno manda sobre todas.
const ARCHIVOS_DE_ENTORNO = ['.env', '../.env', '../.env.local']

for (const archivo of ARCHIVOS_DE_ENTORNO) {
  const ruta = fileURLToPath(new URL(archivo, import.meta.url))
  if (existsSync(ruta)) {
    loadEnvFile(ruta)
  }
}

// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },

  // Nuxt UI aporta los componentes; el sistema de diseño de la aplicación
  // (app/design/) manda sobre ellos: los tokens redefinen sus variables.
  modules: ['@nuxt/ui'],

  css: ['~/assets/css/main.css'],

  vite: {
    optimizeDeps: {
      // Leaflet es un paquete CommonJS: se preempaqueta para que el mapa
      // no provoque una recarga en desarrollo.
      include: ['leaflet'],
    },
  },

  typescript: {
    strict: true,
    typeCheck: false,
  },

  // Los valores por defecto van vacíos a propósito: la configuración real
  // se lee en tiempo de ejecución (ver `server/utils/config.ts`), para que
  // las credenciales no queden escritas dentro del paquete compilado.
  // En Vercel funcionan tanto `DATABASE_URL` como `NUXT_DATABASE_URL`.
  runtimeConfig: {
    databaseUrl: '',
    betterAuthSecret: '',
    betterAuthUrl: '',
    cronSecret: '',
    public: {
      appName: 'Vizcacha Tours',
    },
  },
})
