// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },

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
