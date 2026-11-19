# Portada, navegación y estados de carga

- **Fecha:** 19 de noviembre de 2026, 16:05 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios; el trabajo no modifica el informe)
- **Alcance:** revisión de convenciones de la interfaz, rediseño del
  encabezado, portada nueva sin la prueba de conexión y aviso de carga en
  las navegaciones.

## Antecedente

La aplicación creció rápido con las cuentas, los paquetes y los clientes.
El encabezado acumuló enlaces, el nombre de la cuenta, el cierre de sesión y
el selector de idioma en una sola fila; la portada conservaba la prueba de
conexión con la base, que era una herramienta de desarrollo y no una acción
para la persona usuaria. Además, varios textos y formatos no seguían las
reglas de la web.

## Cambios de formato

No hubo cambios de formato en el informe: no se modificó ningún archivo
LaTeX y el PDF conserva sus 21 páginas.

## Cambios de contenido

### Convenciones de la interfaz

- Los nombres de los idiomas y todos los textos nuevos pasan por
  `useTexto()`; ninguna plantilla nueva escribe cadenas visibles.
- El formato de moneda salió de la página de paquetes y vive en
  `useFormato()`, que usa el idioma de la interfaz. Antes estaba fijo en
  `es-BO`, incluso con la interfaz en inglés.
- La tabla de clientes muestra el tipo de documento traducido, no el
  código interno.
- Se corrigió el selector de idioma: escribía sobre un `computed` sin
  setter y el cambio no se aplicaba.
- Se instaló `@iconify-json/lucide` como dependencia de desarrollo. Los
  iconos se empaquetan localmente y ya no dependen de la API de Iconify;
  el aviso de colección faltante desapareció del arranque.

### Encabezado

- El encabezado se extrajo a `app/components/BarraNavegacion.vue`: recibe
  la cuenta y emite `salir`, sin pedir datos ni llamar a la API.
- Barra fija y más simple: marca a la izquierda, navegación principal al
  centro y cuenta a la derecha.
- Inicio y Disponibilidad siempre visibles; Clientes, Paquetes y Usuarios
  se agrupan en **Gestión**, solo para los roles que corresponden.
- La cuenta muestra nombre y rol; el cierre de sesión está en su menú.
- En móvil, un menú desplegable concentra la navegación y el ingreso queda
  como icono con etiqueta accesible.
- El enlace de la ruta activa se resalta.

### Portada

- Se retiró la tarjeta de estado del sistema y el botón para comprobar la
  conexión con la base.
- Bloque principal con título, explicación y dos acciones: **Ingresar al
  sistema** y **Ver disponibilidad**.
- Con sesión iniciada, la acción principal es **Ir al panel**, según el rol:
  administración, clientes o disponibilidad.
- Se aclara que las cuentas las entrega la agencia y que no hay registro
  público, que es la decisión vigente del MVP.
- Tres tarjetas con las ideas centrales y la lista de capacidades.

### Estados de carga

- `NuxtLoadingIndicator` en la parte superior durante cada navegación.
- Se conservan los esqueletos de las tablas y los botones con estado de
  carga.

### Sistema de diseño

- Se agregó el token `--vt-texto-4xl` para el título de la portada.

### Documentación

- `web/docs/componentes.md`: la barra de navegación y su contrato.

## Archivos modificados

- `web/app/app.vue`.
- `web/app/components/BarraNavegacion.vue` (nuevo).
- `web/app/composables/useFormato.ts` (nuevo).
- `web/app/pages/index.vue`.
- `web/app/pages/admin/paquetes.vue`, `web/app/pages/clientes.vue`.
- `web/app/i18n/locales/es.ts`, `web/app/i18n/locales/en.ts`.
- `web/app/design/tokens.css`.
- `web/package.json`, `package-lock.json`.
- `web/docs/componentes.md`.

## Validación

- `npm run typecheck --workspace web` terminó sin errores.
- `npm run build --workspace web` compiló y descubrió la colección local
  de iconos: 45 iconos, sin el aviso de colección faltante.
- `make verificar` terminó con cero problemas.
- Prueba manual con el servidor local:
  - sin sesión, la portada muestra el ingreso y la nota sobre las cuentas,
    y no contiene la prueba de conexión;
  - con sesión, muestra **Ir al panel** y el menú de gestión;
  - `/ingresar`, `/disponibilidad`, `/admin/paquetes`, `/admin/usuarios` y
    `/clientes` responden 200 con la cuenta adecuada;
  - la portada y el encabezado cambian a inglés con la cookie de idioma.
- El usuario temporal de prueba se borró; las cuentas reales del equipo no
  se modificaron.

## Pendientes

- Versionar y desplegar los cambios en Vercel.
- Revisar la interfaz en un teléfono real y con lector de pantalla.
- Corregir el barrido diario: Vercel lo invoca con GET y la ruta es
  `vencer-solicitudes.post.ts`.
- Agregar pruebas automatizadas de la interfaz; hoy la validación es
  manual.
- Continuar con las historias que siguen en el tablero.
