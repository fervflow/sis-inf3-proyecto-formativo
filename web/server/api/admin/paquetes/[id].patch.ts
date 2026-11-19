import { and, eq, ne } from 'drizzle-orm'
import * as schema from '../../../../db/schema'
import type { PaqueteAdmin } from '#shared/types/api'
import { exigirAdmin } from '../../../utils/autorizacion'
import {
  aPaqueteAdmin,
  esquemaPaquete,
  normalizarCodigo,
} from '../../../utils/paquetes'
import { leerCuerpo } from '../../../utils/validacion'

/**
 * Edición de un paquete turístico.
 */
export default defineEventHandler(async (event): Promise<PaqueteAdmin> => {
  exigirAdmin(event)
  const id = Number(getRouterParam(event, 'id'))

  if (!Number.isInteger(id) || id < 1) {
    throw createError({ statusCode: 400, statusMessage: 'datos_invalidos' })
  }

  const datos = await leerCuerpo(event, esquemaPaquete)
  const codigo = normalizarCodigo(datos.codigo)
  const db = useDb()

  const [existente] = await db
    .select({ idPaquete: schema.paquete.idPaquete })
    .from(schema.paquete)
    .where(
      and(
        eq(schema.paquete.codigo, codigo),
        ne(schema.paquete.idPaquete, id),
      ),
    )
    .limit(1)

  if (existente) {
    throw createError({ statusCode: 409, statusMessage: 'paquete_duplicado' })
  }

  const [fila] = await db
    .update(schema.paquete)
    .set({
      codigo,
      nombre: datos.nombre,
      descripcion: datos.descripcion || null,
      duracionDias: datos.duracionDias,
      precioBase: datos.precioBase.toFixed(2),
      itinerario: datos.itinerario || null,
      serviciosIncluidos: datos.serviciosIncluidos || null,
      estado: datos.estado,
      fechaActualizacion: new Date(),
    })
    .where(eq(schema.paquete.idPaquete, id))
    .returning()

  if (!fila) {
    throw createError({ statusCode: 404, statusMessage: 'paquete_inexistente' })
  }

  return aPaqueteAdmin(fila)
})
