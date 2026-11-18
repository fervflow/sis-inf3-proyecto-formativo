# Estructura de desarrollo agéntico de la web

- **Fecha:** 18 de noviembre de 2026, 14:57 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios; el trabajo no modifica el informe)
- **Alcance:** la web deja de ser un esqueleto y queda con las convenciones
  que necesita un desarrollo asistido por agentes: sistema de diseño propio,
  textos centralizados, componentes reutilizables, tipos compartidos y la
  documentación que las explica.

## Antecedente

El esqueleto de la aplicación tenía lo mínimo para arrancar: una conexión a
la base, la autenticación, dos rutas de la API y dos vistas. Faltaba todo lo
que hace que un equipo (humano o artificial) pueda ampliar el sistema sin
que cada vista invente su propio estilo, sus propios textos y sus propios
tipos.

Se decidió que **Nuxt UI es la implementación, no la identidad**: los
componentes de la biblioteca se usan, pero todos leen sus colores, radios y
tipografías de tokens propios. Así, reestilizar la aplicación es cambiar un
archivo.

## Cambios de formato

No hubo cambios de formato en el informe: no se modificó ningún archivo
LaTeX y el PDF conserva sus 21 páginas. En la aplicación, el formato visual
deja de estar escrito en las plantillas y pasa a estar en el sistema de
diseño.

## Cambios de contenido

### Sistema de diseño

`app/design/tokens.css` es la fuente única de la identidad visual, en dos
capas:

- `--vt-*`: tokens del proyecto, con nombre del dominio (marca, neutro,
  estados, espaciado, radios, sombras, tipografía, transiciones).
- `--ui-color-*`: el mapeo a las variables que lee Nuxt UI.

`app/design/tema.ts` define las variantes de los componentes (tarjeta,
tabla, botón) y `app/app.config.ts` las aplica. Un componente nunca escribe
un color: usa un token, una variable de Nuxt UI o un componente base.

### Textos centralizados

`app/i18n/locales/es.ts` define las claves y `app/i18n/locales/en.ts` las
traduce. El tipo `ClaveMensaje` sale de `es.ts`, y `Mensajes` obliga a que
los dos idiomas tengan exactamente las mismas claves: si falta una, el
proyecto no compila. El composable `useTexto()` traduce y sustituye los
marcadores `{detalle}`. El idioma activo se guarda en una cookie, para que
el servidor y el cliente coincidan al renderizar.

Las dos vistas que existían quedaron sin un solo texto suelto en la
plantilla.

### Componentes reutilizables

En `app/components/base/`, con prefijo `Base`:

| Componente | Para qué |
|---|---|
| `BaseEncabezadoPagina` | Título, descripción y acciones de una vista |
| `BaseTarjeta` | Contenedor con título, cuerpo y pie |
| `BaseTablaDatos` | Tabla genérica con columnas declarativas y plantilla por celda |
| `BaseEstadoVacio` | Lo que se ve cuando una lista no tiene nada |
| `BaseDato` | Un indicador con su etiqueta |

`BaseTablaDatos` es genérico (`generic="Fila extends object"`), así que
sirve para cualquier forma de fila, y entrega a la plantilla `columna`,
`fila` y `valor`.

### Tipos compartidos

`shared/types/` quedó dividido por propósito: `domain.ts` para los valores
del dominio, que son el reflejo de las restricciones de la base; `api.ts`
para los contratos de las respuestas; `ui.ts` para los tipos de los
componentes. La tabla y la página de disponibilidad usan el mismo tipo, así
que un cambio en la respuesta rompe la vista al compilar.

### Composables

`useTexto()` traduce y `useApi()` pide datos a la API manejando carga, error
y dato tipado. Las vistas ya no llaman a `$fetch` por su cuenta.

### Documentación

`web/AGENTS.md` es el punto de entrada para agentes y modelos: las reglas
que no se negocian, los comandos y el índice de qué leer según la tarea.
`web/docs/` tiene las once guías que explican el detalle: arquitectura,
convenciones, design system, componentes, tipos y datos, i18n, base de
datos, autenticación, pruebas, seguridad y flujo de trabajo.

### Dependencias

Se agregó **Nuxt UI 4** con Tailwind v4, y el script `typecheck`.

## Archivos modificados

- `web/AGENTS.md` (nuevo) y `web/docs/*.md` (nuevos): la documentación.
- `web/app/design/tokens.css`, `web/app/design/tema.ts`,
  `web/app/app.config.ts` (nuevos): el sistema de diseño.
- `web/app/i18n/` (nuevos): los textos de la interfaz.
- `web/app/components/base/*.vue` (nuevos): los componentes reutilizables.
- `web/app/composables/useTexto.ts` y `useApi.ts` (nuevos).
- `web/shared/types/*.ts` (nuevos).
- `web/app/assets/css/main.css` (nuevo): estilos globales.
- `web/app/app.vue`, `web/app/pages/index.vue`,
  `web/app/pages/disponibilidad.vue`: migrados a los textos centralizados y
  a los componentes base.
- `web/nuxt.config.ts`, `web/package.json`: Nuxt UI, Tailwind y el script de
  tipos.
- `web/README.md` y `README.md`: enlaces a la documentación de la web.
- `web/CONFIGURACION.md` (nuevo): lista provisional de lo que falta
  configurar en Neon, Vercel y el resto de servicios. Es un documento de
  trabajo y se puede borrar cuando esté todo configurado.

## Validación

- `npx nuxt typecheck` terminó sin errores.
- `npx nuxt build` compiló la aplicación.
- El servidor renderizó la portada: los textos salen del diccionario, los
  componentes base aparecen en el HTML y las variables de los tokens están
  en la hoja de estilos.
- La tabla de disponibilidad y la de estado se sirven con la tipificación
  nueva.
- `npm install` del espacio de trabajo funcionó sobre la partición del
  repositorio.
- `make verificar` terminó con cero problemas: 29 archivos revisados, 20
  rutas LaTeX y 29 entradas del árbol del README.
- El PDF sigue en 21 páginas.

## Pendientes

- Abrir el tablero una vez en Obsidian y una en VS Code para confirmar la
  vista, como quedó pendiente del trabajo anterior.
- Instalar y configurar el proveedor de correo y el de imágenes, y tomar
  las decisiones listadas en `web/CONFIGURACION.md`.
- Escribir las primeras pruebas: las de integración de las funciones de la
  base son las que más aportan, porque es ahí donde están las reglas.
