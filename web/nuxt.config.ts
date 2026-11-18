// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },

  // Nuxt UI aporta los componentes; el sistema de diseño de la aplicación
  // (app/design/) manda sobre ellos: los tokens redefinen sus variables.
  modules: ['@nuxt/ui'],

  css: ['~/assets/css/main.css'],

  typescript: {
    strict: true,
    typeCheck: false,
  },

  // Las variables del servidor no se exponen al cliente. En Vercel se
  // declaran en Settings → Environment Variables; en local, en `web/.env`.
  runtimeConfig: {
    databaseUrl: process.env.DATABASE_URL,
    betterAuthSecret: process.env.BETTER_AUTH_SECRET,
    betterAuthUrl: process.env.BETTER_AUTH_URL,
    cronSecret: process.env.CRON_SECRET,
    public: {
      appName: 'Vizcacha Tours',
    },
  },
})
