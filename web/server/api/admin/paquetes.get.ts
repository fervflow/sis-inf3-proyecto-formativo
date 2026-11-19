import { asc } from 'drizzle-orm'
import * as schema from '../../../db/schema'
import type { RespuestaPaquetes } from '#shared/types/api'
import { exigirAdmin } from '../../utils/autorizacion'
import { aPaqueteAdmin } from '../../utils/paquetes'

/**
 * Catálogo completo de paquetes, para el administrador.
 */
export default defineEventHandler(async (event): Promise<RespuestaPaquetes> => {
  exigirAdmin(event)

  const filas = await useDb()
    .select()
    .from(schema.paquete)
    .orderBy(asc(schema.paquete.codigo))

  return { paquetes: filas.map(aPaqueteAdmin) }
})
