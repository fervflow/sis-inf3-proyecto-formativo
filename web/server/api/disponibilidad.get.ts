import { sql } from 'drizzle-orm'
import { consultar } from '../utils/db'

/**
 * Disponibilidad de las salidas programadas.
 *
 * Los cupos no se almacenan: salen de la vista
 * `vista_disponibilidad_salida`, que descuenta los pasajeros de las
 * reservas vigentes. Una solicitud pendiente cuyo plazo venció ya no
 * cuenta, aunque su estado guardado siga siendo `pendiente`.
 */
export default defineEventHandler(async () => {
  const salidas = await consultar<{
    id_salida: number
    codigo_paquete: string
    paquete: string
    estado_paquete: string
    fecha_salida: string
    fecha_retorno: string
    cupo_maximo: number
    pasajeros_ocupados: number
    cupo_disponible: number
    precio: string
    estado: string
  }>(sql`
    SELECT id_salida, codigo_paquete, paquete, estado_paquete, fecha_salida,
           fecha_retorno, cupo_maximo, pasajeros_ocupados, cupo_disponible,
           precio, estado
    FROM turismo.vista_disponibilidad_salida
    WHERE fecha_salida >= CURRENT_DATE
      AND estado_paquete = 'activo'
      AND estado IN ('programada', 'confirmada')
    ORDER BY fecha_salida, codigo_paquete
  `)

  return { salidas }
})
