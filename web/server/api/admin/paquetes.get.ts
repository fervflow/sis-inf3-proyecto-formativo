import { asc } from 'drizzle-orm'
import * as schema from '../../../db/schema'
import type { RespuestaPaquetes } from '#shared/types/api'
import { exigirAdmin } from '../../utils/autorizacion'
import {
  aPaqueteAdmin,
  cargarLugares,
  cargarParadas,
  cargarServicios,
} from '../../utils/paquetes'

/**
 * Catálogo completo de paquetes, para el administrador.
 */
export default defineEventHandler(async (event): Promise<RespuestaPaquetes> => {
  exigirAdmin(event)

  const filas = await useDb()
    .select()
    .from(schema.paquete)
    .orderBy(asc(schema.paquete.codigo))

  const ids = filas.map((fila) => fila.idPaquete)
  const idsLugares = [
    ...new Set(
      filas
        .flatMap((fila) => [fila.idLugarDestino, fila.idLugarOrigen])
        .filter((id): id is number => typeof id === 'number'),
    ),
  ]

  const lugares = await cargarLugares(idsLugares)
  const paradas = await cargarParadas(ids)
  const servicios = await cargarServicios(ids)

  return {
    paquetes: filas.map((fila) =>
      aPaqueteAdmin(
        fila,
        fila.idLugarDestino ? (lugares.get(fila.idLugarDestino) ?? null) : null,
        fila.idLugarOrigen ? (lugares.get(fila.idLugarOrigen) ?? null) : null,
        paradas.get(fila.idPaquete) ?? [],
        servicios.get(fila.idPaquete) ?? [],
      ),
    ),
  }
})
