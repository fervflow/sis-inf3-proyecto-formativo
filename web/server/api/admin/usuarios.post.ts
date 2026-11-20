import { APIError } from 'better-auth/api'
import { eq } from 'drizzle-orm'
import { z } from 'zod'
import * as schema from '../../../db/schema'
import {
  correoDeUsuario,
  normalizarUsuario,
  validarUsuario,
} from '#shared/usuarios'
import type { UsuarioAdmin } from '#shared/types/api'
import { exigirAdmin } from '../../utils/autorizacion'
import { aUsuarioAdmin, idRolDe, seleccionUsuario } from '../../utils/usuarios'
import { leerCuerpo } from '../../utils/validacion'

/**
 * Alta de una cuenta desde el panel.
 *
 * La contraseña inicial es el nombre de usuario y queda marcada para
 * cambiarse en el primer ingreso. El registro público está cerrado: esta
 * es la única vía de alta.
 */
const cuerpo = z.object({
  usuario: z.string().trim().min(1).max(40),
  nombres: z.string().trim().min(1).max(100),
  apellidos: z.string().trim().min(1).max(100),
  telefono: z.string().trim().max(30).optional(),
  rol: z.enum(['ADMIN', 'PERSONAL', 'CLIENTE']),
})

type DatosAlta = z.infer<typeof cuerpo>

export default defineEventHandler(async (event): Promise<UsuarioAdmin> => {
  exigirAdmin(event)
  const datos = await leerCuerpo(event, cuerpo)

  const usuario = normalizarUsuario(datos.usuario)
  const problema = validarUsuario(usuario)
  if (problema) {
    throw createError({ statusCode: 400, statusMessage: problema })
  }

  const correo = correoDeUsuario(usuario)
  const db = useDb()

  const [existente] = await db
    .select({ id: schema.usuario.id })
    .from(schema.usuario)
    .where(eq(schema.usuario.email, correo))
    .limit(1)

  if (existente) {
    throw createError({ statusCode: 409, statusMessage: 'usuario_duplicado' })
  }

  const idRol = await idRolDe(datos.rol)
  if (!idRol) {
    throw createError({ statusCode: 400, statusMessage: 'rol_invalido' })
  }

  const creado = await crearCuenta(correo, usuario, datos)

  try {
    await db
      .update(schema.usuario)
      .set({ idRol, debeCambiarPassword: true })
      .where(eq(schema.usuario.id, creado.user.id))
  } catch (error) {
    // Sin rol la cuenta no sirve: se deshace el alta para no dejar una
    // fila a medias.
    await db.delete(schema.usuario).where(eq(schema.usuario.id, creado.user.id))
    throw error
  }

  const [fila] = await db
    .select(seleccionUsuario)
    .from(schema.usuario)
    .leftJoin(schema.rol, eq(schema.rol.idRol, schema.usuario.idRol))
    .where(eq(schema.usuario.id, creado.user.id))
    .limit(1)

  if (!fila) {
    throw createError({ statusCode: 500, statusMessage: 'alta_incompleta' })
  }

  return aUsuarioAdmin(fila)
})

/** Crea la cuenta en Better Auth y traduce sus errores a códigos. */
async function crearCuenta(correo: string, usuario: string, datos: DatosAlta) {
  try {
    return await useAuth().api.signUpEmail({
      body: {
        email: correo,
        password: usuario,
        name: `${datos.nombres} ${datos.apellidos}`,
        nombres: datos.nombres,
        apellidos: datos.apellidos,
        telefono: datos.telefono || undefined,
      },
    })
  } catch (error) {
    if (error instanceof APIError) {
      const duplicado = error.body?.code === 'USER_ALREADY_EXISTS'
      throw createError({
        statusCode: duplicado ? 409 : 400,
        statusMessage: duplicado ? 'usuario_duplicado' : 'datos_invalidos',
      })
    }
    throw error
  }
}
