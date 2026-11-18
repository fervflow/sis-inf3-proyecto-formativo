import { defineConfig } from 'drizzle-kit'

/**
 * Configuración de Drizzle Kit.
 *
 * El esquema de la base se crea con el script `bd/esquema.sql`, que es la
 * fuente canónica. Esta configuración sirve para generar migraciones a
 * partir del esquema de TypeScript cuando el proyecto necesite versionar
 * cambios de esquema.
 */
export default defineConfig({
  schema: './db/schema.ts',
  out: './drizzle',
  dialect: 'postgresql',
  dbCredentials: {
    url: process.env.DATABASE_URL ?? '',
  },
})
