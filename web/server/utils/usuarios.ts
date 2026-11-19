/**
 * Lectura y forma de las cuentas.
 *
 * El nombre de usuario no se guarda aparte: se deriva del correo interno
 * (`usuario@vizcacha.tours`), que es el identificador que exige Better
 * Auth. Así una sola columna mantiene la unicidad.
 */
import { eq } from 'drizzle-orm'
import * as schema from '../../db/schema'
import { usuarioDeCorreo } from '#shared/usuarios'
import type { UsuarioAdmin } from '#shared/types/api'
import type { EstadoUsuario, Rol } from '#shared/types/domain'

/** Columnas que necesita el panel de administración. */
export const seleccionUsuario = {
  id: schema.usuario.id,
  email: schema.usuario.email,
  nombres: schema.usuario.nombres,
  apellidos: schema.usuario.apellidos,
  estado: schema.usuario.estado,
  debeCambiarPassword: schema.usuario.debeCambiarPassword,
  creadoEn: schema.usuario.createdAt,
  rol: schema.rol.codigo,
} as const

/** Fila devuelta por `seleccionUsuario`. */
export interface FilaUsuario {
  id: string
  email: string
  nombres: string
  apellidos: string
  estado: string
  debeCambiarPassword: boolean
  creadoEn: Date
  rol: string | null
}

/** Convierte la fila de la base en lo que consume la interfaz. */
export function aUsuarioAdmin(fila: FilaUsuario): UsuarioAdmin {
  return {
    id: fila.id,
    usuario: usuarioDeCorreo(fila.email),
    nombres: fila.nombres,
    apellidos: fila.apellidos,
    rol: (fila.rol ?? 'TURISTA') as Rol,
    estado: fila.estado as EstadoUsuario,
    debeCambiarPassword: fila.debeCambiarPassword,
    creadoEn: fila.creadoEn.toISOString(),
  }
}

/** Identificador del rol a partir de su código. */
export async function idRolDe(codigo: Rol): Promise<number | null> {
  const [fila] = await useDb()
    .select({ idRol: schema.rol.idRol })
    .from(schema.rol)
    .where(eq(schema.rol.codigo, codigo))
    .limit(1)

  return fila?.idRol ?? null
}
