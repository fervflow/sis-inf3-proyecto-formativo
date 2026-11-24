import { sql } from 'drizzle-orm'
import type { SalidaDisponible } from '#shared/types/api'
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
/**
 * Disponibilidad de las salidas programadas.
 *
 * Los cupos no se almacenan: salen de la vista
 * `vista_disponibilidad_salida`, que descuenta los pasajeros de las
 * reservas vigentes. Una solicitud pendiente cuyo plazo venció ya no
 * cuenta, aunque su estado guardado siga siendo `pendiente`.
 *
 * El desglose de confirmados y pendientes es público: distingue la venta
 * hecha de las solicitudes que están en revisión (RN-RES-16).
 */
export default defineEventHandler(async (event) => {
  const salidas = await consultar<SalidaDisponible>(sql`
    SELECT v.id_salida, v.id_paquete, v.codigo_paquete, v.codigo_salida,
           v.paquete,
           v.estado_paquete, v.fecha_salida, v.fecha_retorno, v.cupo_maximo,
           v.pasajeros_ocupados, v.pasajeros_pendientes,
           v.pasajeros_confirmados, v.cupo_disponible, v.precio, v.estado,
           l.nombre AS destino, lo.nombre AS origen, p.tipo_recorrido,
           p.duracion_dias, s.punto_encuentro, p.precio_base,
           (SELECT array_agg(lp.nombre ORDER BY pp.orden)
              FROM turismo.paquete_parada pp
              JOIN turismo.lugar lp ON lp.id_lugar = pp.id_lugar
             WHERE pp.id_paquete = p.id_paquete) AS paradas
    FROM turismo.vista_disponibilidad_salida v
    JOIN turismo.paquete p ON p.id_paquete = v.id_paquete
    JOIN turismo.salida s ON s.id_salida = v.id_salida
    LEFT JOIN turismo.lugar l ON l.id_lugar = p.id_lugar_destino
    LEFT JOIN turismo.lugar lo ON lo.id_lugar = p.id_lugar_origen
    WHERE v.fecha_salida >= CURRENT_DATE
      AND v.estado_paquete = 'activo'
      AND v.estado IN ('programada', 'confirmada')
    ORDER BY v.fecha_salida, v.codigo_paquete
  `)

  return { salidas }
})
