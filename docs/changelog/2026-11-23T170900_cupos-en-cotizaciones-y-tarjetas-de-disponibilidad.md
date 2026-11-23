# Cupos en cotizaciones, tarjetas de disponibilidad y solicitud web

- **Fecha:** 23 de noviembre de 2026, 17:09 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios; el trabajo no modifica el informe)
- **Alcance:** corrección de dos problemas de la interfaz y una regla de
  negocio que faltaba en cotizaciones: control de pasajeros contra el cupo
  disponible de la salida, tarjetas informativas en el panel de
  disponibilidad y botón de envío en la solicitud web.

## Antecedente

Al probar la creación de cotizaciones se detectó que la cantidad de
pasajeros no se controlaba contra el cupo disponible de la salida. Además,
la solicitud de reserva del canal web no mostraba el botón para enviar el
formulario, y el panel de disponibilidad presentaba la información en una
tabla distinta a la de salidas del panel.

## Decisiones aplicadas

1. **Regla de cupo en cotizaciones (`RN-COT-09`).** La cotización no
   descuenta cupo, pero tampoco puede prometer más pasajeros que los
   disponibles: la API rechaza el alta y la edición si la cantidad supera
   `cupo_disponible`, y el campo de la interfaz se limita al máximo de la
   salida elegida. La reserva que nazca de ella vuelve a verificarlo dentro
   de la transacción, porque el cupo puede cambiar en el interín.
2. **Disponibilidad con tarjetas.** La página pública `/disponibilidad`
   usa la misma forma que la gestión de salidas: tarjetas con el paquete,
   destino, fechas y duración, barra de ocupación, precio y punto de
   encuentro; en el pie, la acción «Solicitar» o la etiqueta «Agotada».
3. **Desglose dentro de la tarjeta.** El desglose de pendientes y
   confirmados, que antes era una nota al pie de la tabla, se muestra en la
   tarjeta solo para el personal.
4. **Botón de envío en la solicitud.** El formulario del canal web incluye
   «Enviar solicitud» con estado de carga y «Cancelar»; el fallo era la
   ausencia del pie de acción en el componente.
5. **Datos enriquecidos del endpoint.** `/api/disponibilidad` agrega
   destino, duración, punto de encuentro y precio base del paquete, que
   alimentan la tarjeta y las fichas de cotización.

## Cambios de formato

No hubo cambios de formato en el informe: no se modificó ningún archivo
LaTeX y el PDF conserva sus 21 páginas.

## Cambios de contenido

### Reglas y criterios

- `RN-COT-09` nueva en el catálogo, la trazabilidad de HU-05 actualizada y
  un criterio nuevo en la historia HU-05: la cantidad no puede superar el
  cupo disponible; la cotización no lo descuenta, pero tampoco promete
  lugares que no hay.

### Web

- `web/server/utils/cotizaciones.ts`: consulta de la vista de
  disponibilidad en `validarReferencias` (alta y edición) con rechazo
  `cupo_insuficiente`.
- `web/app/pages/cotizaciones.vue`: máximo del campo de pasajeros fijado
  por el cupo disponible y texto de ayuda nuevo.
- `web/app/components/disponibilidad/Tarjeta.vue` (nuevo): espejo público
  de la tarjeta de salidas, con acción `solicitar`.
- `web/app/pages/disponibilidad.vue`: grilla de tarjetas con esqueletos y
  estado vacío; ya no usa la tabla de datos.
- `web/app/components/solicitudes/FormularioPublico.vue`: pie con los
  botones «Enviar solicitud» y «Cancelar» (evento `cancelar`).
- `web/server/api/disponibilidad.get.ts` y `web/shared/types/api.ts`:
  `SalidaDisponible` extendida con `id_paquete`, `destino`,
  `duracion_dias`, `punto_encuentro` y `precio_base`.
- Textos nuevos en español e inglés; se retiró la clave de la nota al pie
  que quedó sin uso (`disponibilidad.desglosePersonal`).
- `web/docs/componentes.md` documenta la tarjeta de disponibilidad.

## Archivos modificados

- **Reglas:** `sistema/reglas-negocio.md` y
  `sistema/historias-usuario/historias-usuario.md`.
- **Tipos y servidor:** `web/shared/types/api.ts`,
  `web/server/api/disponibilidad.get.ts` y
  `web/server/utils/cotizaciones.ts`.
- **Interfaz:** `web/app/pages/disponibilidad.vue`,
  `web/app/pages/cotizaciones.vue`,
  `web/app/components/disponibilidad/Tarjeta.vue` (nuevo),
  `web/app/components/solicitudes/FormularioPublico.vue` y los archivos de
  textos.
- **Documentación:** `web/docs/componentes.md`.
- **Registro:** este archivo y la tabla de `docs/changelog/README.md`.

## Validación realizada

- `npm run typecheck --workspace web`: sin errores.
- `npm run build --workspace web`: compila.
- Prueba de API: cotización con 16 pasajeros sobre una salida de 15 cupos
  rechazada con `cupo_insuficiente`; con 5 pasajeros aceptada. Los datos
  de prueba se eliminaron después.
- Render en desarrollo de `/disponibilidad`: tarjetas con destino,
  ocupación y botón «Solicitar» para el canal anónimo.
- El servidor de desarrollo quedó detenido al terminar.

## Pendientes o decisiones

- La cotización de ejemplo `COT-2026-002` (20 pasajeros sobre una salida de
  15 cupos) quedó de una prueba anterior a la regla; puede eliminarse desde
  la interfaz si se decide.
- HU-15 (cuentas de cliente) sigue planificada: el registro de la cuenta,
  el portal del cliente y el bloqueo por uso indebido.
- El informe no se modifica en esta iteración.
