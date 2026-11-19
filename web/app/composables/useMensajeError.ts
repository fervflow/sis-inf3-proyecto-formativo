import type { ClaveMensaje } from '~/i18n'

/**
 * Traducción de los errores del servidor.
 *
 * El servidor responde con códigos (`statusMessage`), no con frases: la
 * interfaz decide cómo se dice. Los códigos desconocidos caen en un
 * mensaje genérico.
 */
const CODIGOS: Record<string, ClaveMensaje> = {
  sin_sesion: 'errores.sinSesion',
  sin_permiso: 'errores.sinPermiso',
  cuenta_inactiva: 'errores.cuentaInactiva',
  cambio_pendiente: 'errores.cambioPendiente',
  usuario_duplicado: 'errores.usuarioDuplicado',
  usuario_corto: 'errores.usuarioCorto',
  usuario_largo: 'errores.usuarioLargo',
  usuario_invalido: 'errores.usuarioInvalido',
  usuario_reservado: 'errores.usuarioReservado',
  usuario_inexistente: 'errores.usuarioInexistente',
  propia_cuenta: 'errores.propiaCuenta',
  rol_invalido: 'errores.rolInvalido',
  password_igual: 'errores.passwordIgual',
  password_incorrecta: 'errores.passwordIncorrecta',
  sin_contrasena: 'errores.sinContrasena',
  datos_invalidos: 'errores.datosInvalidos',
  paquete_duplicado: 'errores.paqueteDuplicado',
  paquete_inexistente: 'errores.paqueteInexistente',
  codigo_invalido: 'errores.codigoInvalido',
  cliente_duplicado: 'errores.clienteDuplicado',
  cliente_inexistente: 'errores.clienteInexistente',
  fecha_futura: 'errores.fechaFutura',
}

/** Devuelve el texto de un fallo de la API. */
export function useMensajeError() {
  const { t } = useTexto()

  return function mensaje(
    fallo: unknown,
    porDefecto: ClaveMensaje = 'errores.generico',
  ): string {
    const datos = (fallo as { data?: { statusMessage?: string } }).data
    const clave = datos?.statusMessage ? CODIGOS[datos.statusMessage] : undefined
    return t(clave ?? porDefecto)
  }
}
