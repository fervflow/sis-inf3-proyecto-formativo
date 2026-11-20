import { asc, eq } from 'drizzle-orm'
import * as schema from '../../../db/schema'
import type { RespuestaSalidas } from '#shared/types/api'
import { exigirAdmin } from '../../utils/autorizacion'
import { aSalidaAdmin } from '../../utils/salidas'

/**
 * Salidas programadas, con el paquete resuelto para la tabla.
 */
export default defineEventHandler(async (event): Promise<RespuestaSalidas> => {
  exigirAdmin(event)

  const filas = await useDb()
    .select({
      idSalida: schema.salida.idSalida,
      idPaquete: schema.salida.idPaquete,
      codigoPaquete: schema.paquete.codigo,
      paquete: schema.paquete.nombre,
      fechaSalida: schema.salida.fechaSalida,
      fechaRetorno: schema.salida.fechaRetorno,
      cupoMaximo: schema.salida.cupoMaximo,
      precio: schema.salida.precio,
      puntoEncuentro: schema.salida.puntoEncuentro,
      estado: schema.salida.estado,
      observaciones: schema.salida.observaciones,
      fechaActualizacion: schema.salida.fechaActualizacion,
    })
    .from(schema.salida)
    .innerJoin(schema.paquete, eq(schema.paquete.idPaquete, schema.salida.idPaquete))
    .orderBy(asc(schema.salida.fechaSalida), asc(schema.paquete.codigo))

  return { salidas: filas.map(aSalidaAdmin) }
})
