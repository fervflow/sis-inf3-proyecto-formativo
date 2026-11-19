import { and, eq } from 'drizzle-orm'
import * as schema from '../../db/schema'
import type { ClienteResumen } from '#shared/types/api'
import { exigirPersonal } from '../utils/autorizacion'
import {
  aClienteResumen,
  esquemaCliente,
  normalizarDocumento,
} from '../utils/clientes'
import { esDuplicado, leerCuerpo } from '../utils/validacion'

/**
 * Alta de la ficha de un cliente.
 *
 * El documento no se repite: la base lo garantiza y la ruta lo informa
 * como un conflicto, no como un error interno.
 */
export default defineEventHandler(async (event): Promise<ClienteResumen> => {
  exigirPersonal(event)
  const datos = await leerCuerpo(event, esquemaCliente)
  const numeroDocumento = normalizarDocumento(datos.numeroDocumento)
  const db = useDb()

  const [existente] = await db
    .select({ idCliente: schema.cliente.idCliente })
    .from(schema.cliente)
    .where(
      and(
        eq(schema.cliente.tipoDocumento, datos.tipoDocumento),
        eq(schema.cliente.numeroDocumento, numeroDocumento),
      ),
    )
    .limit(1)

  if (existente) {
    throw createError({ statusCode: 409, statusMessage: 'cliente_duplicado' })
  }

  try {
    const [fila] = await db
      .insert(schema.cliente)
      .values({
        tipoDocumento: datos.tipoDocumento,
        numeroDocumento,
        nombres: datos.nombres,
        apellidos: datos.apellidos,
        correo: datos.correo || null,
        telefono: datos.telefono || null,
        direccion: datos.direccion || null,
        fechaNacimiento: datos.fechaNacimiento || null,
        estado: datos.estado,
      })
      .returning()

    if (!fila) {
      throw createError({ statusCode: 500, statusMessage: 'alta_incompleta' })
    }

    return aClienteResumen(fila)
  } catch (error) {
    if (esDuplicado(error)) {
      throw createError({ statusCode: 409, statusMessage: 'cliente_duplicado' })
    }
    throw error
  }
})
