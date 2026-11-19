import { and, eq, ne } from 'drizzle-orm'
import * as schema from '../../../db/schema'
import type { ClienteResumen } from '#shared/types/api'
import { exigirPersonal } from '../../utils/autorizacion'
import {
  aClienteResumen,
  esquemaCliente,
  normalizarDocumento,
} from '../../utils/clientes'
import { esDuplicado, leerCuerpo } from '../../utils/validacion'

/**
 * Actualización de la ficha de un cliente.
 */
export default defineEventHandler(async (event): Promise<ClienteResumen> => {
  exigirPersonal(event)
  const id = Number(getRouterParam(event, 'id'))

  if (!Number.isInteger(id) || id < 1) {
    throw createError({ statusCode: 400, statusMessage: 'datos_invalidos' })
  }

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
        ne(schema.cliente.idCliente, id),
      ),
    )
    .limit(1)

  if (existente) {
    throw createError({ statusCode: 409, statusMessage: 'cliente_duplicado' })
  }

  try {
    const [fila] = await db
      .update(schema.cliente)
      .set({
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
      .where(eq(schema.cliente.idCliente, id))
      .returning()

    if (!fila) {
      throw createError({
        statusCode: 404,
        statusMessage: 'cliente_inexistente',
      })
    }

    return aClienteResumen(fila)
  } catch (error) {
    if (esDuplicado(error)) {
      throw createError({ statusCode: 409, statusMessage: 'cliente_duplicado' })
    }
    throw error
  }
})
