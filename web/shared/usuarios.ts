/**
 * Cuentas internas.
 *
 * El MVP no envía correo: la cuenta se identifica con un nombre de
 * usuario y el correo que exige Better Auth se arma con un dominio
 * interno que no recibe mensajes. El nombre de usuario es, además, la
 * contraseña inicial; la aplicación obliga a cambiarla en el primer
 * ingreso.
 *
 * Este archivo lo usan la interfaz y el servidor: la regla es la misma en
 * los dos lados.
 */

/** Dominio interno de los correos. No recibe ni envía mensajes. */
export const USUARIO_DOMINIO = 'vizcacha.tours'

/**
 * Largo mínimo del nombre de usuario.
 *
 * Coincide con el mínimo de contraseña de Better Auth: como la contraseña
 * inicial es el nombre de usuario, un usuario más corto no se podría
 * crear.
 */
export const USUARIO_LARGO_MINIMO = 8

/** Largo máximo del nombre de usuario. */
export const USUARIO_LARGO_MAXIMO = 30

/**
 * Nombres que no se pueden usar: se confunden con rutas o con roles, o
 * son los primeros que probaría un atacante.
 */
const RESERVADOS = new Set([
  'admin',
  'administrador',
  'api',
  'root',
  'sistema',
  'soporte',
  'usuario',
  'www',
])

/** Nombre de usuario válido: minúsculas, números, punto, guion y guion bajo. */
const PATRON = /^[a-z0-9][a-z0-9._-]*[a-z0-9]$/

/** Quita espacios y pasa a minúsculas. */
export function normalizarUsuario(valor: string): string {
  return valor.trim().toLowerCase()
}

/** Correo interno que Better Auth guarda para un nombre de usuario. */
export function correoDeUsuario(usuario: string): string {
  return `${normalizarUsuario(usuario)}@${USUARIO_DOMINIO}`
}

/** Nombre de usuario a partir del correo interno. */
export function usuarioDeCorreo(correo: string): string {
  return correo.split('@')[0] ?? correo
}

/**
 * Devuelve el código del problema, o `null` si el nombre es válido.
 *
 * Los códigos los traducen las rutas y la interfaz; aquí no hay textos.
 */
export function validarUsuario(valor: string): string | null {
  const usuario = normalizarUsuario(valor)

  if (usuario.length < USUARIO_LARGO_MINIMO) {
    return 'usuario_corto'
  }
  if (usuario.length > USUARIO_LARGO_MAXIMO) {
    return 'usuario_largo'
  }
  if (!PATRON.test(usuario)) {
    return 'usuario_invalido'
  }
  if (RESERVADOS.has(usuario)) {
    return 'usuario_reservado'
  }

  return null
}

/**
 * Correo completo a partir de lo que se escribe en el formulario de
 * ingreso: si ya incluye `@` se respeta; si no, se le agrega el dominio.
 */
export function correoDeIngreso(valor: string): string {
  const texto = valor.trim().toLowerCase()
  return texto.includes('@') ? texto : correoDeUsuario(texto)
}
