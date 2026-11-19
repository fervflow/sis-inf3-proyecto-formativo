import { asc, ilike, or } from 'drizzle-orm'
import { z } from 'zod'
import * as schema from '../../db/schema'
import type { RespuestaClientes } from '#shared/types/api'
import { exigirPersonal } from '../utils/autorizacion'
import { aClienteResumen } from '../utils/clientes'
import { leerConsulta } from '../utils/validacion'

/**
 * Fichas de clientes, con búsqueda por documento o nombre.
 */
const consulta = z.object({
  q: z.string().trim().max(100).optional(),
})

export default defineEventHandler(async (event): Promise<RespuestaClientes> => {
  exigirPersonal(event)
  const { q } = leerConsulta(event, consulta)

  const filtro = q
    ? or(
        ilike(schema.cliente.nombres, `%${q}%`),
        ilike(schema.cliente.apellidos, `%${q}%`),
        ilike(schema.cliente.numeroDocumento, `%${q}%`),
      )
    : undefined

  const filas = await useDb()
    .select()
    .from(schema.cliente)
    .where(filtro)
    .orderBy(asc(schema.cliente.apellidos), asc(schema.cliente.nombres))
    .limit(200)

  return { clientes: filas.map(aClienteResumen) }
})
