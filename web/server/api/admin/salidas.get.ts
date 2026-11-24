import { asc, eq, sql } from 'drizzle-orm'
import * as schema from '../../../db/schema'
import type { RespuestaSalidas } from '#shared/types/api'
import { exigirAdmin } from '../../utils/autorizacion'
import { consultar } from '../../utils/db'
import { aSalidaAdmin } from '../../utils/salidas'

/**
 * Salidas programadas, con el paquete resuelto y la ocupación calculada
 * por la vista de disponibilidad.
 */
export default defineEventHandler(async (event): Promise<RespuestaSalidas> => {
  exigirAdmin(event)

  const filas = await useDb()
    .select({
      idSalida: schema.salida.idSalida,
      idPaquete: schema.salida.idPaquete,
      codigoPaquete: schema.paquete.codigo,
      codigoSalida: schema.salida.codigo,
      paquete: schema.paquete.nombre,
      destino: schema.lugar.nombre,
      duracionDias: schema.paquete.duracionDias,
      fechaSalida: schema.salida.fechaSalida,
      fechaRetorno: schema.salida.fechaRetorno,
      cupoMaximo: schema.salida.cupoMaximo,
      precio: schema.salida.precio,
      precioBase: schema.paquete.precioBase,
      puntoEncuentro: schema.salida.puntoEncuentro,
      estado: schema.salida.estado,
      estadoPaquete: schema.paquete.estado,
      observaciones: schema.salida.observaciones,
      fechaActualizacion: schema.salida.fechaActualizacion,
    })
    .from(schema.salida)
    .innerJoin(
      schema.paquete,
      eq(schema.paquete.idPaquete, schema.salida.idPaquete),
    )
    .leftJoin(
      schema.lugar,
      eq(schema.lugar.idLugar, schema.paquete.idLugarDestino),
    )
    .orderBy(asc(schema.salida.fechaSalida), asc(schema.paquete.codigo))

  const disponibilidad = await consultar<{
    id_salida: string | number
    pasajeros_ocupados: string | number
    pasajeros_confirmados: string | number
    pasajeros_pendientes: string | number
    cupo_disponible: string | number
  }>(sql`
    select id_salida, pasajeros_ocupados, pasajeros_confirmados,
           pasajeros_pendientes, cupo_disponible
    from turismo.vista_disponibilidad_salida
  `)

  const ocupacion = new Map(
    disponibilidad.map((fila) => [
      Number(fila.id_salida),
      {
        pasajerosOcupados: Number(fila.pasajeros_ocupados),
        pasajerosConfirmados: Number(fila.pasajeros_confirmados),
        pasajerosPendientes: Number(fila.pasajeros_pendientes),
        cupoDisponible: Number(fila.cupo_disponible),
      },
    ]),
  )

  return {
    salidas: filas.map((fila) =>
      aSalidaAdmin(fila, ocupacion.get(fila.idSalida)),
    ),
  }
})
