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
    SELECT v.id_salida, v.id_paquete, v.codigo_paquete, v.paquete,
           v.estado_paquete, v.fecha_salida, v.fecha_retorno, v.cupo_maximo,
           v.pasajeros_ocupados, v.pasajeros_pendientes,
           v.pasajeros_confirmados, v.cupo_disponible, v.precio, v.estado,
           l.nombre AS destino, p.duracion_dias, s.punto_encuentro,
           p.precio_base
    FROM turismo.vista_disponibilidad_salida v
    JOIN turismo.paquete p ON p.id_paquete = v.id_paquete
    JOIN turismo.salida s ON s.id_salida = v.id_salida
    LEFT JOIN turismo.lugar l ON l.id_lugar = p.id_lugar_destino
    WHERE v.fecha_salida >= CURRENT_DATE
      AND v.estado_paquete = 'activo'
      AND v.estado IN ('programada', 'confirmada')
    ORDER BY v.fecha_salida, v.codigo_paquete
  `)

  return {
    salidas: salidas.map((salida) => ({
      ...salida,
      pasajeros_pendientes: esPersonal ? salida.pasajeros_pendientes : null,
      pasajeros_confirmados: esPersonal ? salida.pasajeros_confirmados : null,
    })),
  }
})
