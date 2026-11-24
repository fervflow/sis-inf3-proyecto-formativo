import { asc, eq, ilike, or } from 'drizzle-orm'
import { z } from 'zod'
import * as schema from '../../db/schema'
import type { RespuestaClientes } from '#shared/types/api'
import { exigirPersonal } from '../utils/autorizacion'
import { aClienteResumen } from '../utils/clientes'
import type { FilaCliente } from '../utils/clientes'
import { leerConsulta } from '../utils/validacion'

/**
 * Fichas de clientes, con búsqueda por documento o nombre. Cada ficha
 * reporta su cuenta vinculada cuando la tiene (RN-USU-02).
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
    .select({
      idCliente: schema.cliente.idCliente,
      tipoDocumento: schema.cliente.tipoDocumento,
      numeroDocumento: schema.cliente.numeroDocumento,
      nombres: schema.cliente.nombres,
      apellidos: schema.cliente.apellidos,
      correo: schema.cliente.correo,
      telefono: schema.cliente.telefono,
      direccion: schema.cliente.direccion,
      fechaNacimiento: schema.cliente.fechaNacimiento,
      estado: schema.cliente.estado,
      fechaRegistro: schema.cliente.fechaRegistro,
      usuarioCuenta: schema.usuario.email,
      estadoCuenta: schema.usuario.estado,
    })
    .from(schema.cliente)
    .leftJoin(schema.usuario, eq(schema.usuario.id, schema.cliente.idUsuario))
    .where(filtro)
    .orderBy(asc(schema.cliente.apellidos), asc(schema.cliente.nombres))
    .limit(200)

  return { clientes: filas.map((fila) => aClienteResumen(fila as FilaCliente)) }
})
