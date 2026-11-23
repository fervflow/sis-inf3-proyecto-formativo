import { sql } from 'drizzle-orm'
import type { SalidaDisponible } from '#shared/types/api'
import { sesionActual, ROL_ADMIN, ROL_PERSONAL } from '../utils/autorizacion'
import { consultar } from '../utils/db'

/**
 * Disponibilidad de las salidas programadas.
 *
 * Los cupos no se almacenan: salen de la vista
 * `vista_disponibilidad_salida`, que descuenta los pasajeros de las
 * reservas vigentes. Una solicitud pendiente cuyo plazo venció ya no
 * cuenta, aunque su estado guardado siga siendo `pendiente`.
 *
 * El desglose de pendientes y confirmados solo se entrega al personal;
 * el cliente recibe los totales.
 */
export default defineEventHandler(async (event) => {
  const sesion = sesionActual(event)
  const esPersonal =
    sesion?.user.idRol === ROL_ADMIN || sesion?.user.idRol === ROL_PERSONAL

  const salidas = await consultar<SalidaDisponible>(sql`
    SELECT id_salida, codigo_paquete, paquete, estado_paquete, fecha_salida,
           fecha_retorno, cupo_maximo, pasajeros_ocupados,
           pasajeros_pendientes, pasajeros_confirmados, cupo_disponible,
           precio, estado
    FROM turismo.vista_disponibilidad_salida
    WHERE fecha_salida >= CURRENT_DATE
      AND estado_paquete = 'activo'
      AND estado IN ('programada', 'confirmada')
    ORDER BY fecha_salida, codigo_paquete
  `)

  return {
    salidas: salidas.map((salida) => ({
      ...salida,
      pasajeros_pendientes: esPersonal ? salida.pasajeros_pendientes : null,
      pasajeros_confirmados: esPersonal ? salida.pasajeros_confirmados : null,
    })),
  }
})
