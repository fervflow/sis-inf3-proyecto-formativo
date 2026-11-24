import { sql } from 'drizzle-orm'
import { z } from 'zod'
import type { RespuestaReportes } from '#shared/types/api'
import { exigirPersonal } from '../utils/autorizacion'
import { consultar } from '../utils/db'
import { leerConsulta } from '../utils/validacion'

/**
 * Reporte de ocupación y reservas por fecha (HU-11, RN-REP-01 a
 * RN-REP-04).
 *
 * Parten de `vista_reservas_por_fecha`, la misma base de cálculo que la
 * disponibilidad: capacidad, pasajeros pendientes y confirmados, cupos
 * libres, reservas por estado (las vencidas y canceladas se informan sin
 * ocupar cupo) y conteos por canal. Solo el personal lo consulta.
 */
const consulta = z.object({
  desde: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'datos_invalidos')
    .optional(),
  hasta: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'datos_invalidos')
    .optional(),
  idPaquete: z.coerce.number().int().positive().optional(),
})

export default defineEventHandler(async (event): Promise<RespuestaReportes> => {
  exigirPersonal(event)
  const { desde, hasta, idPaquete } = leerConsulta(event, consulta)

  const filas = await consultar(sql`
    SELECT v.id_salida AS "idSalida",
           v.id_paquete AS "idPaquete",
           v.codigo_paquete AS "codigoPaquete",
           v.paquete,
           v.fecha_salida AS "fechaSalida",
           v.cupo_maximo AS "cupoMaximo",
           v.pasajeros_pendientes AS "pasajerosPendientes",
           v.pasajeros_confirmados AS "pasajerosConfirmados",
           v.cupo_disponible AS "cupoDisponible",
           v.reservas_pendientes AS "reservasPendientes",
           v.reservas_confirmadas AS "reservasConfirmadas",
           v.reservas_activas AS "reservasActivas",
           v.reservas_vencidas AS "reservasVencidas",
           v.reservas_canceladas AS "reservasCanceladas",
           v.reservas_finalizadas AS "reservasFinalizadas",
           v.reservas_web AS "reservasWeb",
           v.reservas_personal AS "reservasPersonal"
    FROM turismo.vista_reservas_por_fecha v
    WHERE (${desde ?? null}::date IS NULL OR v.fecha_salida >= ${desde ?? null}::date)
      AND (${hasta ?? null}::date IS NULL OR v.fecha_salida <= ${hasta ?? null}::date)
      AND (${idPaquete ?? null}::bigint IS NULL
           OR v.id_paquete = ${idPaquete ?? null}::bigint)
    ORDER BY v.fecha_salida
  `)

  return { salidas: filas as unknown as RespuestaReportes['salidas'] }
})
