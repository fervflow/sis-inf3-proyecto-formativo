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
  'nav.cuenta': 'My account',
  'nav.salir': 'Sign out',

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
}
