import { eq } from 'drizzle-orm'
import * as schema from '../../../db/schema'
import type { PaqueteAdmin } from '#shared/types/api'
import { exigirAdmin } from '../../utils/autorizacion'
import {
  aPaqueteAdmin,
  esquemaPaquete,
  normalizarCodigo,
} from '../../utils/paquetes'
import { leerCuerpo } from '../../utils/validacion'

/**
 * Alta de un paquete turístico.
 */
export default defineEventHandler(async (event): Promise<PaqueteAdmin> => {
  const sesion = exigirAdmin(event)
  const datos = await leerCuerpo(event, esquemaPaquete)

  const codigo = normalizarCodigo(datos.codigo)
  const db = useDb()

  const [existente] = await db
    .select({ idPaquete: schema.paquete.idPaquete })
    .from(schema.paquete)
    .where(eq(schema.paquete.codigo, codigo))
    .limit(1)

  if (existente) {
    throw createError({ statusCode: 409, statusMessage: 'paquete_duplicado' })
  }

  const [fila] = await db
    .insert(schema.paquete)
    .values({
      codigo,
      nombre: datos.nombre,
      descripcion: datos.descripcion || null,
      duracionDias: datos.duracionDias,
      precioBase: datos.precioBase.toFixed(2),
      itinerario: datos.itinerario || null,
      serviciosIncluidos: datos.serviciosIncluidos || null,
      estado: datos.estado,
      idUsuarioCreador: sesion.user.id,
    })
    .returning()

  if (!fila) {
    throw createError({ statusCode: 500, statusMessage: 'alta_incompleta' })
  }

  return aPaqueteAdmin(fila)
})
