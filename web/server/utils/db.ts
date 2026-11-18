import { drizzle } from 'drizzle-orm/node-postgres'
import { Pool } from 'pg'
import type { NodePgDatabase } from 'drizzle-orm/node-postgres'
import type { SQL } from 'drizzle-orm'
import * as schema from '../../db/schema'

let pool: Pool | undefined
let conexion: NodePgDatabase<typeof schema> | undefined

/**
 * Conexión a la base de datos.
 *
 * Se usa el controlador de PostgreSQL (`pg`) porque funciona tanto contra
 * un PostgreSQL local como contra Neon: en producción se le pasa la
 * cadena de conexión *pooled* de Neon, que multiplexa las conexiones y
 * evita agotarlas en un entorno sin estado.
 *
 * Las reglas que necesitan un bloqueo de fila —la validación de cupos, el
 * cambio de capacidad, la confirmación de una solicitud— están en
 * funciones PL/pgSQL dentro de la base (ver `bd/esquema.sql`), de modo
 * que la aplicación no depende del transporte para que la operación sea
 * atómica.
 */
export function useDb(): NodePgDatabase<typeof schema> {
  if (!conexion) {
    const url = configServidor().databaseUrl
    if (!url) {
      throw new Error(
        'Falta DATABASE_URL. Ejecutá «neon env pull» en la raíz del repositorio, ' +
          'o copiá web/.env.example a web/.env y completalo.',
      )
    }
    pool = new Pool({
      connectionString: url,
      max: 5,
      // La aplicación abre y cierra conexiones en cada petición; sin esto
      // el pool mantiene conexiones abiertas que un entorno sin estado no
      // necesita.
      idleTimeoutMillis: 10_000,
    })
    conexion = drizzle(pool, { schema })
  }
  return conexion
}

/**
 * Consulta SQL directo, para las vistas y las funciones de la base.
 *
 * Devuelve siempre un arreglo de filas, cualquiera sea la forma que tome
 * el resultado según el controlador.
 */
export async function consultar<T = Record<string, unknown>>(
  consulta: SQL,
): Promise<T[]> {
  const resultado = (await useDb().execute(consulta)) as unknown
  if (Array.isArray(resultado)) {
    return resultado as T[]
  }
  const filas = (resultado as { rows?: T[] } | null)?.rows
  return Array.isArray(filas) ? filas : []
}
