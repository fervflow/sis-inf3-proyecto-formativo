# Barra de navegación nueva, salidas fusionadas con la disponibilidad, tema e idioma

- **Fecha:** 24 de noviembre de 2026, 01:21 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios; el trabajo no modifica el informe)
- **Alcance:** reorganización de la navegación de la web, fusión de la
  gestión de salidas con la página de disponibilidad, selector de tema
  claro/oscuro/sistema y banderas en el selector de idioma.

## Cambios de la interfaz

- **Barra de navegación (`BarraNavegacion.vue`):**
  - El enlace «Inicio» desaparece: el logo ya enlaza a la portada.
  - Los enlaces de operación del personal (Clientes, Cotizaciones,
    Solicitudes) van directos en el encabezado de escritorio.
  - El desplegable «Gestión» queda solo para el administrador, con lo
    exclusivamente administrativo (Paquetes, Proveedores, Usuarios); la
    gestión de salidas sale del menú porque pasa a la página pública.
  - El selector de idioma muestra la bandera del idioma en uso y de cada
    opción (Bolivia para el español latinoamericano, EE. UU. para el
    inglés, colección `circle-flags` local) y se ensanchó para que el
    texto no se trunque con elipsis.
- **Selector de tema:** botón de solo ícono (sol o luna según el tema
  resuelto) y desplegable con las tres opciones completas: Claro, Oscuro
  y Sistema. La preferencia la aplica Nuxt UI como clase `.dark` en
  `<html>`.
- **Página «Próximas salidas»** (antes «Disponibilidad», en
  `pages/disponibilidad.vue`):
  - La misma página atiende los dos canales: la vista de cliente con la
    solicitud de reserva, y para el administrador un par de pestañas con
    la vista de gestión (todas las salidas, alta y edición).
  - La vista pública ahora muestra el recorrido completo del paquete
    (origen, paradas y destino) y no solo el destino principal.
  - Las dos vistas comparten la barra de ocupación a dos segmentos
    (confirmados y pendientes) y el desglose «Confirmados: X ·
    Pendientes: Y».
  - La ruta `/admin/salidas` redirige a `/disponibilidad`.

## Cambios técnicos

- `web/app/components/base/BarraCupo.vue` (nuevo): barra de ocupación en
  dos segmentos, compartida por las dos tarjetas.
- `web/app/composables/useRecorrido.ts` (nuevo): arma la línea de
  recorrido a partir de nombres o lugares; usada por ambas vistas.
- `web/app/components/salidas/FormularioSalida.vue` (nuevo): el modal de
  alta y edición de salidas se extrajo del viejo panel.
- `web/server/api/disponibilidad.get.ts`: la consulta pública entrega
  además origen, paradas y tipo de recorrido del paquete.
- `web/server/api/admin/salidas.get.ts` y `web/server/utils/salidas.ts`:
  la ocupación del administrador incluye pasajeros confirmados y
  pendientes, calculados por la vista de la base; el cupo sigue sin
  almacenarse en la aplicación.
- `web/shared/types/api.ts`: `SalidaDisponible` con origen, paradas y
  tipo de recorrido; `SalidaAdmin` con confirmados y pendientes.
- `web/app/design/tokens.css` y `web/app/assets/css/main.css`: la paleta
  oscura responde a la clase `.dark` (antes solo al sistema operativo) y
  `color-scheme` sigue al tema activo.
- `web/app/i18n/locales/es.ts` y `en.ts`: textos nuevos de tema y vistas;
  se retiraron `nav.inicio` y `nav.salidas`.
- `web/package.json`: dependencia de desarrollo `@iconify-json/circle-flags`.
- Documentación actualizada: `web/docs/componentes.md` (barra de
  navegación, `BaseBarraCupo`, `FormularioSalida`) y
  `web/docs/design-system.md` (gobierno del tema claro y oscuro).

## Cambios de formato

No hubo cambios de formato en el informe: no se modificó ningún archivo
LaTeX y el PDF conserva sus 21 páginas.

## Validación realizada

- `npm run typecheck --workspace web`: sin errores.
- `npm run build --workspace web`: compila; Nuxt Icon empaqueta las dos
  colecciones locales (`lucide` y `circle-flags`), sin servicios externos.
- Las rutas protegidas (`/api/admin/*`) siguen exigiendo el rol en el
  servidor; ocultar las acciones es solo parte de la interfaz.

## Pendientes o decisiones

- **HU-03 y el desglose de pendientes/confirmados:** la historia dice que
  el desglose lo ve solo el personal, pero el API público lo entrega a
  cualquiera. Queda como decisión abierta para otra iteración: alinear el
  código con HU-03 o actualizar la historia.
- El informe no se modifica en esta iteración.
