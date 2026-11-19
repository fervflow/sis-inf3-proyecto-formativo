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
  'nav.clientes': 'Clientes',
  'nav.paquetes': 'Paquetes',
  'nav.usuarios': 'Usuarios',
  'nav.cuenta': 'Mi cuenta',
  'nav.salir': 'Cerrar sesión',
  'nav.ingresar': 'Ingresar',

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

  'ingreso.titulo': 'Ingresar al sistema',
  'ingreso.introduccion':
    'Las cuentas las crea el administrador. Escribí el nombre de usuario que te entregó.',
  'ingreso.usuario': 'Usuario',
  'ingreso.contrasena': 'Contraseña',
  'ingreso.pista':
    'La primera vez, la contraseña es el mismo nombre de usuario.',
  'ingreso.error': 'Usuario o contraseña incorrectos.',
  'ingreso.bloqueada': 'La cuenta no está activa. Consultá con el administrador.',

  'cambio.titulo': 'Cambiar la contraseña',
  'cambio.introduccion':
    'Estás usando la contraseña inicial. Elegí una nueva para continuar.',
  'cambio.actual': 'Contraseña actual',
  'cambio.nueva': 'Contraseña nueva',
  'cambio.repetir': 'Repetir la contraseña nueva',
  'cambio.noCoinciden': 'Las contraseñas nuevas no coinciden.',
  'cambio.corta': 'La contraseña nueva debe tener al menos 8 caracteres.',
  'cambio.igual': 'La contraseña nueva debe ser distinta de la actual.',
  'cambio.error':
    'No se pudo cambiar la contraseña. Revisá la contraseña actual.',
  'cambio.exito': 'Contraseña actualizada.',

  'usuarios.titulo': 'Usuarios',
  'usuarios.introduccion':
    'Cuentas del sistema. La contraseña inicial es el nombre de usuario y se cambia en el primer ingreso.',
  'usuarios.crear': 'Crear usuario',
  'usuarios.vacio': 'Todavía no hay cuentas.',
  'usuarios.columnas.usuario': 'Usuario',
  'usuarios.columnas.nombres': 'Nombres',
  'usuarios.columnas.apellidos': 'Apellidos',
  'usuarios.columnas.rol': 'Rol',
  'usuarios.columnas.estado': 'Estado',
  'usuarios.columnas.acciones': 'Acciones',
  'usuarios.roles.ADMIN': 'Administrador',
  'usuarios.roles.PERSONAL': 'Personal',
  'usuarios.roles.TURISTA': 'Turista',
  'usuarios.estados.activo': 'Activo',
  'usuarios.estados.inactivo': 'Inactivo',
  'usuarios.estados.bloqueado': 'Bloqueado',
  'usuarios.acciones.restablecer': 'Restablecer',
  'usuarios.acciones.bloquear': 'Bloquear',
  'usuarios.acciones.activar': 'Activar',
  'usuarios.restablecer.hecho':
    'La contraseña de {usuario} volvió a ser el nombre de usuario.',
  'usuarios.confirmarRestablecer':
    'La contraseña de {usuario} volverá a ser su nombre de usuario. ¿Continuar?',
  'usuarios.creado':
    'Cuenta creada: {usuario}. La contraseña inicial es el mismo nombre de usuario.',
  'usuarios.actualizado': 'Cuenta actualizada.',
  'usuarios.pendiente': 'Debe cambiar la contraseña',
  'usuarios.form.usuario': 'Nombre de usuario',
  'usuarios.form.nombres': 'Nombres',
  'usuarios.form.apellidos': 'Apellidos',
  'usuarios.form.telefono': 'Teléfono (opcional)',
  'usuarios.form.rol': 'Rol',
  'usuarios.form.ayudaUsuario':
    'Entre 8 y 30 caracteres: minúsculas, números, punto, guion o guion bajo. También será la contraseña inicial.',

  'paquetes.titulo': 'Paquetes turísticos',
  'paquetes.introduccion':
    'Catálogo de paquetes. El código identifica el paquete y no se repite.',
  'paquetes.crear': 'Nuevo paquete',
  'paquetes.editar': 'Editar paquete',
  'paquetes.vacio': 'Todavía no hay paquetes.',
  'paquetes.columnas.codigo': 'Código',
  'paquetes.columnas.nombre': 'Paquete',
  'paquetes.columnas.dias': 'Días',
  'paquetes.columnas.precio': 'Precio base',
  'paquetes.columnas.estado': 'Estado',
  'paquetes.columnas.acciones': 'Acciones',
  'paquetes.estados.borrador': 'Borrador',
  'paquetes.estados.activo': 'Activo',
  'paquetes.estados.inactivo': 'Inactivo',
  'paquetes.acciones.editar': 'Editar',
  'paquetes.form.codigo': 'Código',
  'paquetes.form.nombre': 'Nombre',
  'paquetes.form.descripcion': 'Descripción',
  'paquetes.form.duracion': 'Duración en días',
  'paquetes.form.precio': 'Precio base por persona',
  'paquetes.form.itinerario': 'Itinerario',
  'paquetes.form.servicios': 'Servicios incluidos',
  'paquetes.form.estado': 'Estado',
  'paquetes.ayudaCodigo':
    'Entre 3 y 20 caracteres: letras, números y guion. Se guarda en mayúsculas.',
  'paquetes.ayudaPrecio': 'En bolivianos.',
  'paquetes.creado': 'Paquete creado: {codigo}.',
  'paquetes.actualizado': 'Paquete actualizado: {codigo}.',

  'clientes.titulo': 'Clientes',
  'clientes.introduccion':
    'Fichas de clientes. El documento identifica a la persona y no se repite.',
  'clientes.crear': 'Nuevo cliente',
  'clientes.editar': 'Editar cliente',
  'clientes.vacio': 'No hay clientes registrados.',
  'clientes.sinResultados': 'No se encontraron clientes con esa búsqueda.',
  'clientes.buscar': 'Buscar por nombre o documento',
  'clientes.columnas.documento': 'Documento',
  'clientes.columnas.nombres': 'Nombres',
  'clientes.columnas.apellidos': 'Apellidos',
  'clientes.columnas.telefono': 'Teléfono',
  'clientes.columnas.correo': 'Correo',
  'clientes.columnas.estado': 'Estado',
  'clientes.columnas.acciones': 'Acciones',
  'clientes.estados.activo': 'Activo',
  'clientes.estados.inactivo': 'Inactivo',
  'clientes.tipos.CI': 'Cédula',
  'clientes.tipos.NIT': 'NIT',
  'clientes.tipos.PASAPORTE': 'Pasaporte',
  'clientes.tipos.OTRO': 'Otro',
  'clientes.acciones.editar': 'Editar',
  'clientes.form.tipoDocumento': 'Tipo de documento',
  'clientes.form.numeroDocumento': 'Número de documento',
  'clientes.form.nombres': 'Nombres',
  'clientes.form.apellidos': 'Apellidos',
  'clientes.form.correo': 'Correo (opcional)',
  'clientes.form.telefono': 'Teléfono (opcional)',
  'clientes.form.direccion': 'Dirección (opcional)',
  'clientes.form.fechaNacimiento': 'Fecha de nacimiento (opcional)',
  'clientes.form.estado': 'Estado',
  'clientes.creado': 'Cliente registrado: {nombre}.',
  'clientes.actualizado': 'Cliente actualizado: {nombre}.',

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
  'errores.usuarioDuplicado': 'Ese nombre de usuario ya está en uso.',
  'errores.usuarioCorto': 'El usuario debe tener al menos 8 caracteres.',
  'errores.usuarioLargo': 'El usuario no puede superar los 30 caracteres.',
  'errores.usuarioInvalido':
    'El usuario solo admite minúsculas, números, punto, guion y guion bajo.',
  'errores.usuarioReservado': 'Ese nombre de usuario está reservado.',
  'errores.propiaCuenta': 'No podés modificar tu propia cuenta desde el panel.',
  'errores.sinPermiso': 'No tenés permisos para esta operación.',
  'errores.sinSesion': 'Tu sesión expiró. Volvé a ingresar.',
  'errores.cuentaInactiva': 'La cuenta no está activa.',
  'errores.cambioPendiente': 'Primero tenés que cambiar la contraseña.',
  'errores.passwordIgual':
    'La contraseña nueva debe ser distinta de la actual.',
  'errores.passwordIncorrecta': 'La contraseña actual no es correcta.',
  'errores.datosInvalidos': 'Revisá los datos ingresados.',
  'errores.usuarioInexistente': 'La cuenta no existe.',
  'errores.rolInvalido': 'El rol elegido no es válido.',
  'errores.sinContrasena': 'La cuenta no tiene una contraseña para restablecer.',
  'errores.paqueteDuplicado': 'Ya existe un paquete con ese código.',
  'errores.paqueteInexistente': 'El paquete no existe.',
  'errores.codigoInvalido':
    'El código solo admite letras, números y guion (entre 3 y 20).',
  'errores.clienteDuplicado': 'Ya existe un cliente con ese documento.',
  'errores.clienteInexistente': 'El cliente no existe.',
  'errores.fechaFutura': 'La fecha de nacimiento no puede ser futura.',
} as const
