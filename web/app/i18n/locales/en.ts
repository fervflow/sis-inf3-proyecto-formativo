/**
 * Textos de la interfaz, en inglés.
 *
 * Traducción de `es.ts`. Las claves deben coincidir exactamente: el tipo
 * `Mensajes` lo comprueba al compilar.
 */
import type { Mensajes } from '../index'

export const en: Mensajes = {
  'app.nombre': 'Vizcacha Tours',
  'app.subtitulo': 'Tour package and booking management',
  'app.pie':
    'Web system for managing tour packages and bookings · Final project for Information Systems III · UPDS, Potosí.',
  'app.idioma': 'Language',

  'nav.inicio': 'Home',
  'nav.disponibilidad': 'Availability',
  'nav.usuarios': 'Users',
  'nav.cuenta': 'My account',
  'nav.salir': 'Sign out',
  'nav.ingresar': 'Sign in',

  'inicio.titulo': 'Tour package and booking management',
  'inicio.introduccion':
    'Web system for the Vizcacha Tours agency, in Potosí. It serves two channels through the same validated process: the agency staff and the customer’s direct access.',
  'inicio.queSePuedeHacer': 'What you can do',
  'inicio.capacidades.1': 'Register and maintain tour packages and their suppliers.',
  'inicio.capacidades.2': 'Schedule departures with a date, a capacity and a price.',
  'inicio.capacidades.3': 'Check availability and record bookings with capacity validation.',
  'inicio.capacidades.4': 'Register customers and passengers, quotations, deposits and balances.',
  'inicio.capacidades.5': 'Confirm requests, check reports and audit every change.',

  'salud.titulo': 'System status',
  'salud.comprobar': 'Check the database connection',
  'salud.comprobando': 'Checking…',
  'salud.conexion': 'Connection',
  'salud.conectada': 'ok',
  'salud.fallida': 'failed',
  'salud.paquetes': 'Packages',
  'salud.salidas': 'Departures',
  'salud.reservas': 'Bookings',

  'disponibilidad.titulo': 'Availability',
  'disponibilidad.introduccion':
    'Scheduled departures and places left. The capacity is calculated by the database from the bookings in force.',
  'disponibilidad.vacia': 'There are no departures scheduled from today.',
  'disponibilidad.columnas.paquete': 'Package',
  'disponibilidad.columnas.salida': 'Departure',
  'disponibilidad.columnas.retorno': 'Return',
  'disponibilidad.columnas.cupo': 'Capacity',
  'disponibilidad.columnas.ocupados': 'Taken',
  'disponibilidad.columnas.disponibles': 'Available',
  'disponibilidad.columnas.precio': 'Price',

  'ingreso.titulo': 'Sign in',
  'ingreso.introduccion':
    'Accounts are created by the administrator. Enter the username you were given.',
  'ingreso.usuario': 'Username',
  'ingreso.contrasena': 'Password',
  'ingreso.pista': 'The first time, the password is the username itself.',
  'ingreso.error': 'Wrong username or password.',
  'ingreso.bloqueada': 'The account is not active. Contact the administrator.',

  'cambio.titulo': 'Change password',
  'cambio.introduccion':
    'You are using the initial password. Choose a new one to continue.',
  'cambio.actual': 'Current password',
  'cambio.nueva': 'New password',
  'cambio.repetir': 'Repeat the new password',
  'cambio.noCoinciden': 'The new passwords do not match.',
  'cambio.corta': 'The new password must be at least 8 characters long.',
  'cambio.igual': 'The new password must differ from the current one.',
  'cambio.error':
    'The password could not be changed. Check the current password.',
  'cambio.exito': 'Password updated.',

  'usuarios.titulo': 'Users',
  'usuarios.introduccion':
    'System accounts. The initial password is the username and is changed on first sign-in.',
  'usuarios.crear': 'Create user',
  'usuarios.vacio': 'There are no accounts yet.',
  'usuarios.columnas.usuario': 'Username',
  'usuarios.columnas.nombres': 'First names',
  'usuarios.columnas.apellidos': 'Last names',
  'usuarios.columnas.rol': 'Role',
  'usuarios.columnas.estado': 'Status',
  'usuarios.columnas.acciones': 'Actions',
  'usuarios.roles.ADMIN': 'Administrator',
  'usuarios.roles.PERSONAL': 'Staff',
  'usuarios.roles.TURISTA': 'Tourist',
  'usuarios.estados.activo': 'Active',
  'usuarios.estados.inactivo': 'Inactive',
  'usuarios.estados.bloqueado': 'Blocked',
  'usuarios.acciones.restablecer': 'Reset',
  'usuarios.acciones.bloquear': 'Block',
  'usuarios.acciones.activar': 'Activate',
  'usuarios.restablecer.hecho':
    'The password for {usuario} is the username again.',
  'usuarios.confirmarRestablecer':
    'The password for {usuario} will be the username again. Continue?',
  'usuarios.creado':
    'Account created: {usuario}. The initial password is the username itself.',
  'usuarios.actualizado': 'Account updated.',
  'usuarios.pendiente': 'Must change password',
  'usuarios.form.usuario': 'Username',
  'usuarios.form.nombres': 'First names',
  'usuarios.form.apellidos': 'Last names',
  'usuarios.form.telefono': 'Phone (optional)',
  'usuarios.form.rol': 'Role',
  'usuarios.form.ayudaUsuario':
    'Between 8 and 30 characters: lowercase letters, numbers, dot, hyphen or underscore. It will also be the initial password.',

  'comun.cargando': 'Loading…',
  'comun.vacio': 'Nothing to show',
  'comun.error': 'The operation could not be completed',
  'comun.reintentar': 'Try again',
  'comun.entrar': 'Sign in',
  'comun.cerrar': 'Close',
  'comun.guardar': 'Save',
  'comun.cancelar': 'Cancel',
  'comun.buscar': 'Search',
  'comun.sinResultados': 'No results',
  'comun.total': 'Total',

  'errores.conexion': 'Could not check: {detalle}',
  'errores.generico': 'An unexpected error occurred. Please try again.',
  'errores.usuarioDuplicado': 'That username is already taken.',
  'errores.usuarioCorto': 'The username must be at least 8 characters long.',
  'errores.usuarioLargo': 'The username cannot exceed 30 characters.',
  'errores.usuarioInvalido':
    'The username only accepts lowercase letters, numbers, dot, hyphen and underscore.',
  'errores.usuarioReservado': 'That username is reserved.',
  'errores.propiaCuenta':
    'You cannot modify your own account from the panel.',
  'errores.sinPermiso': 'You do not have permission for this operation.',
  'errores.sinSesion': 'Your session expired. Please sign in again.',
  'errores.cuentaInactiva': 'The account is not active.',
  'errores.cambioPendiente': 'You must change the password first.',
  'errores.passwordIgual':
    'The new password must differ from the current one.',
  'errores.passwordIncorrecta': 'The current password is not correct.',
  'errores.datosInvalidos': 'Check the submitted data.',
  'errores.usuarioInexistente': 'The account does not exist.',
  'errores.rolInvalido': 'The selected role is not valid.',
  'errores.sinContrasena': 'The account has no password to reset.',
}
