import { eq } from 'drizzle-orm'
import * as schema from '../../../db/schema'
import type { PaqueteAdmin } from '#shared/types/api'
import { exigirAdmin } from '../../utils/autorizacion'
import {
  aPaqueteAdmin,
  cargarActividades,
  esquemaPaquete,
  normalizarCodigo,
  reemplazarActividades,
  validarActividades,
  validarPaquetePublicable,
} from '../../utils/paquetes'
import { leerCuerpo } from '../../utils/validacion'

/**
 * Alta de un paquete turístico.
 */
export default defineEventHandler(async (event): Promise<PaqueteAdmin> => {
  const sesion = exigirAdmin(event)
  const datos = await leerCuerpo(event, esquemaPaquete)

  validarPaquetePublicable(datos)

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

  await validarActividades(datos.actividades)

  const fila = await db.transaction(async (tx) => {
    const [creado] = await tx
      .insert(schema.paquete)
      .values({
        codigo,
        nombre: datos.nombre,
        destino: datos.destino || null,
        descripcion: datos.descripcion || null,
        duracionDias: datos.duracionDias,
        precioBase: datos.precioBase.toFixed(2),
        itinerario: datos.itinerario || null,
        serviciosIncluidos: datos.serviciosIncluidos || null,
        estado: datos.estado,
        idUsuarioCreador: sesion.user.id,
      })
      .returning()

    if (!creado) {
      throw createError({ statusCode: 500, statusMessage: 'alta_incompleta' })
    }

    await reemplazarActividades(tx, creado.idPaquete, datos.actividades)
    return creado
  })

  const actividades = await cargarActividades([fila.idPaquete])
  return aPaqueteAdmin(fila, actividades.get(fila.idPaquete) ?? [])
})
