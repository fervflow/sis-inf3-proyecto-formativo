/**
 * Textos de la interfaz, en español.
 *
 * Este archivo es la única fuente de los textos que ve la persona usuaria.
 * Ningún componente escribe texto suelto: todo pasa por `useTexto()`.
 *
 * Las claves son planas y con puntos, por área:
 * `area.elemento.estado`.
 *
 * Para traducir, se copia el archivo con el mismo nombre de idioma y se
 * traducen los valores; el tipo obliga a que las claves coincidan.
 *
 * Los marcadores entre llaves se sustituyen con valores: `{detalle}`.
 */
export const es = {
  'app.nombre': 'Vizcacha Tours',
  'app.subtitulo': 'Gestión de paquetes turísticos y reservas',
  'app.pie':
    'Sistema web de gestión de paquetes turísticos y reservas · Proyecto formativo de Sistemas de Información III · UPDS, sede Potosí.',
  'app.idioma': 'Idioma',

  'nav.inicio': 'Inicio',
  'nav.disponibilidad': 'Disponibilidad',
  'nav.cuenta': 'Mi cuenta',
  'nav.salir': 'Cerrar sesión',

  'inicio.titulo': 'Gestión de paquetes turísticos y reservas',
  'inicio.introduccion':
    'Sistema web para la agencia Vizcacha Tours, en Potosí. Atiende a dos canales con el mismo proceso validado: la atención del personal de agencia y el acceso directo del cliente.',
  'inicio.queSePuedeHacer': 'Qué se puede hacer',
  'inicio.capacidades.1':
    'Registrar y mantener los paquetes turísticos y sus proveedores.',
  'inicio.capacidades.2':
    'Programar salidas con fecha, cupo y precio.',
  'inicio.capacidades.3':
    'Consultar la disponibilidad y registrar reservas con validación de cupos.',
  'inicio.capacidades.4':
    'Registrar clientes y pasajeros, cotizaciones, anticipos y saldos.',
  'inicio.capacidades.5':
    'Confirmar solicitudes, consultar reportes y auditar los cambios.',

  'salud.titulo': 'Estado del sistema',
  'salud.comprobar': 'Comprobar la conexión con la base',
  'salud.comprobando': 'Comprobando…',
  'salud.conexion': 'Conexión',
  'salud.conectada': 'correcta',
  'salud.fallida': 'fallida',
  'salud.paquetes': 'Paquetes',
  'salud.salidas': 'Salidas',
  'salud.reservas': 'Reservas',

  'disponibilidad.titulo': 'Disponibilidad',
  'disponibilidad.introduccion':
    'Salidas programadas y lugares disponibles. El cupo se calcula en la base de datos a partir de las reservas vigentes.',
  'disponibilidad.vacia': 'No hay salidas programadas desde hoy.',
  'disponibilidad.columnas.paquete': 'Paquete',
  'disponibilidad.columnas.salida': 'Salida',
  'disponibilidad.columnas.retorno': 'Retorno',
  'disponibilidad.columnas.cupo': 'Cupo',
  'disponibilidad.columnas.ocupados': 'Ocupados',
  'disponibilidad.columnas.disponibles': 'Disponibles',
  'disponibilidad.columnas.precio': 'Precio',

  'comun.cargando': 'Cargando…',
  'comun.vacio': 'No hay nada para mostrar',
  'comun.error': 'No se pudo completar la operación',
  'comun.reintentar': 'Reintentar',
  'comun.entrar': 'Entrar',
  'comun.cerrar': 'Cerrar',
  'comun.guardar': 'Guardar',
  'comun.cancelar': 'Cancelar',
  'comun.buscar': 'Buscar',
  'comun.sinResultados': 'Sin resultados',
  'comun.total': 'Total',

  'errores.conexion': 'No se pudo comprobar: {detalle}',
  'errores.generico': 'Ocurrió un error inesperado. Inténtalo de nuevo.',
} as const
