import { APIError } from 'better-auth/api'
import { and, eq } from 'drizzle-orm'
import { z } from 'zod'
import * as schema from '../../db/schema'
import { USUARIO_DOMINIO } from '#shared/usuarios'
import type { RespuestaOperacion } from '#shared/types/api'
import { sesionActual } from '../utils/autorizacion'
import {
  buscarFichaPorDocumento,
  codigoDuplicadoCliente,
  normalizarDocumento,
} from '../utils/clientes'
import { leerCuerpo } from '../utils/validacion'

/**
 * Registro público de una cuenta de cliente (HU-15).
 *
 * Crea la cuenta de Better Auth y la ficha del cliente en un solo paso
 * (RN-USU-03): el correo y el documento son obligatorios y únicos
 * (RN-USU-05). Si el documento ya tiene ficha, la cuenta se vincula a
 * ella en lugar de duplicarla; la ficha sin cuenta sigue existiendo para
 * la atención de oficina (RN-USU-02).
 *
 * Las cuentas del personal se crean solo desde el panel de usuarios
 * (RN-USU-04): el dominio interno está reservado y el rol nace CLIENTE.
 */
const cuerpo = z.object({
  correo: z
    .string()
    .trim()
    .email('correo_invalido')
    .max(150)
    .refine((valor) => !valor.toLowerCase().endsWith(`@${USUARIO_DOMINIO}`), {
      message: 'correo_reservado',
    }),
  contrasena: z.string().min(8, 'contrasena_corta').max(72),
  nombres: z.string().trim().min(2).max(100),
  apellidos: z.string().trim().min(2).max(100),
  tipoDocumento: z.enum(['CI', 'NIT', 'PASAPORTE', 'OTRO']),
  numeroDocumento: z.string().trim().min(3).max(30),
  telefono: z.string().trim().max(30).optional(),
})

export default defineEventHandler(async (event): Promise<RespuestaOperacion> => {
  // Una sesión activa no necesita registrarse: la ruta es solo pública.
  if (sesionActual(event)?.user) {
    throw createError({ statusCode: 403, statusMessage: 'sesion_activa' })
  }

  const datos = await leerCuerpo(event, cuerpo)
  const correo = datos.correo.toLowerCase()
  const numeroDocumento = normalizarDocumento(datos.numeroDocumento)
  const db = useDb()

  const [correoEnUso] = await db
    .select({ id: schema.usuario.id })
    .from(schema.usuario)
    .where(eq(schema.usuario.email, correo))
    .limit(1)

  if (correoEnUso) {
    throw createError({ statusCode: 409, statusMessage: 'correo_en_uso' })
  }

  // Vinculación por documento: la ficha existente no se duplica.
  const idFicha = await buscarFichaPorDocumento(datos.tipoDocumento, numeroDocumento)
  if (idFicha !== null) {
    const [ficha] = await db
      .select({ idUsuario: schema.cliente.idUsuario, correo: schema.cliente.correo })
      .from(schema.cliente)
      .where(eq(schema.cliente.idCliente, idFicha))
      .limit(1)

    if (ficha?.idUsuario) {
      throw createError({ statusCode: 409, statusMessage: 'documento_vinculado' })
    }
  }

  try {
    // La cuenta se crea en Better Auth; la sesión se entrega por cookie
    // para que el cliente continúe su reserva sin volver a ingresar.
    const respuesta = await useAuth().api.signUpEmail({
      body: {
        email: correo,
        password: datos.contrasena,
        name: `${datos.nombres} ${datos.apellidos}`,
        nombres: datos.nombres,
        apellidos: datos.apellidos,
        telefono: datos.telefono || undefined,
      },
      headers: event.headers,
      returnHeaders: true,
    })

    for (const cookie of respuesta.headers.getSetCookie()) {
      appendHeader(event, 'set-cookie', cookie)
    }

    const idCuenta = respuesta.response?.user?.id
    if (!idCuenta) {
      throw createError({ statusCode: 500, statusMessage: 'alta_incompleta' })
    }

    try {
      const idRol = await idRolCliente()
      if (!idRol) {
        throw createError({ statusCode: 500, statusMessage: 'alta_incompleta' })
      }

      await db
        .update(schema.usuario)
        .set({ idRol })
        .where(eq(schema.usuario.id, idCuenta))

      if (idFicha !== null) {
        // La cuenta toma el correo de la ficha: la ficha conserva su
        // historial de reservas y cotizaciones (HU-04).
        await db
          .update(schema.cliente)
          .set({ idUsuario: idCuenta, correo })
          .where(eq(schema.cliente.idCliente, idFicha))
      } else {
        await db
          .insert(schema.cliente)
          .values({
            idUsuario: idCuenta,
            tipoDocumento: datos.tipoDocumento,
            numeroDocumento,
            nombres: datos.nombres,
            apellidos: datos.apellidos,
            correo,
            telefono: datos.telefono || null,
          })
          .returning()
      }
    } catch (error) {
      // Sin ficha la cuenta de cliente no sirve (RN-USU-02): se deshace
      // el alta para no dejar una cuenta huérfana.
      await db
        .delete(schema.usuario)
        .where(and(eq(schema.usuario.id, idCuenta), eq(schema.usuario.email, correo)))
      throw error
    }

    return { ok: true }
  } catch (error) {
    if (error instanceof APIError) {
      const yaExiste = error.body?.code === 'USER_ALREADY_EXISTS'
      throw createError({
        statusCode: yaExiste ? 409 : 400,
        statusMessage: yaExiste ? 'correo_en_uso' : 'datos_invalidos',
      })
    }

    const duplicado = codigoDuplicadoCliente(error)
    if (duplicado === 'correo_duplicado') {
      throw createError({ statusCode: 409, statusMessage: 'correo_en_uso' })
    }
    if (duplicado === 'cliente_duplicado') {
      throw createError({ statusCode: 409, statusMessage: 'documento_duplicado' })
    }
    throw error
  }
})

/** El identificador del rol CLIENTE en la tabla `rol`. */
async function idRolCliente(): Promise<number | null> {
  const [rol] = await useDb()
    .select({ idRol: schema.rol.idRol })
    .from(schema.rol)
    .where(eq(schema.rol.codigo, 'CLIENTE'))
    .limit(1)
  return rol?.idRol ?? null
}
