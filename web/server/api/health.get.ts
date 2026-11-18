import { sql } from 'drizzle-orm'
import { consultar } from '../utils/db'

/**
 * Comprobación de estado.
 *
 * Verifica que la aplicación llegue a la base de datos y devuelve el
 * tamaño de las tablas principales. Es la primera comprobación cuando
 * la aplicación se despliega por primera vez.
 */
export default defineEventHandler(async () => {
  const [conexion] = await consultar<{ ok: number }>(sql`select 1 as ok`)
  const [paquetes] = await consultar<{ n: number }>(
    sql`select count(*)::int as n from turismo.paquete`,
  )
  const [salidas] = await consultar<{ n: number }>(
    sql`select count(*)::int as n from turismo.salida`,
  )
  const [reservas] = await consultar<{ n: number }>(
    sql`select count(*)::int as n from turismo.reserva`,
  )

  return {
    estado: 'ok',
    base: {
      conectado: conexion?.ok === 1,
      paquetes: paquetes?.n ?? 0,
      salidas: salidas?.n ?? 0,
      reservas: reservas?.n ?? 0,
    },
  }
})
