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
  proveedor_duplicado: 'errores.proveedorDuplicado',
  proveedor_inexistente: 'errores.proveedorInexistente',
  proveedor_inactivo: 'errores.proveedorInactivo',
  cotizacion_inexistente: 'errores.cotizacionInexistente',
  cotizacion_no_editable: 'errores.cotizacionNoEditable',
  salida_no_disponible: 'errores.salidaNoDisponible',
  descuento_invalido: 'errores.descuentoInvalido',
  validez_invalida: 'errores.validezInvalida',
  paquete_incompleto: 'errores.paqueteIncompleto',
  paquete_inactivo: 'errores.paqueteInactivo',
  codigo_invalido: 'errores.codigoInvalido',
  actividad_invalida: 'errores.actividadInvalida',
  servicio_invalido: 'errores.servicioInvalido',
  lugar_invalido: 'errores.lugarInvalido',
  lugar_no_creado: 'errores.lugarNoCreado',
  origen_requerido: 'errores.origenRequerido',
  coordenadas_incompletas: 'errores.coordenadasIncompletas',
  codigo_no_generado: 'errores.codigoNoGenerado',
  transicion_invalida: 'errores.transicionInvalida',
  salida_duplicada: 'errores.salidaDuplicada',
  salida_inexistente: 'errores.salidaInexistente',
  salida_no_editable: 'errores.salidaNoEditable',
  paquete_no_editable: 'errores.paqueteNoEditable',
  capacidad_menor: 'errores.capacidadMenor',
  duracion_incoherente: 'errores.duracionIncoherente',
  fecha_pasada: 'errores.fechaPasada',
  fechas_invalidas: 'errores.fechasInvalidas',
  precio_invalido: 'errores.precioInvalido',
  motivo_requerido: 'errores.motivoRequerido',
  cliente_duplicado: 'errores.clienteDuplicado',
  cliente_inexistente: 'errores.clienteInexistente',
  cliente_inactivo: 'errores.clienteInactivo',
  fecha_futura: 'errores.fechaFutura',
  cupo_insuficiente: 'errores.cupoInsuficiente',
  solicitud_pendiente: 'errores.solicitudPendiente',
  solicitud_vencida: 'errores.solicitudVencida',
  reserva_inexistente: 'errores.reservaInexistente',
  cotizacion_incoherente: 'errores.cotizacionIncoherente',
  sistema_faltante: 'errores.sistemaFaltante',
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
