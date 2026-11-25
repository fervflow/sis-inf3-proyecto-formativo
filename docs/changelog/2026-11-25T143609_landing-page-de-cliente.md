# Portada del sistema reorientada al cliente

## Fecha y alcance

25 de noviembre de 2026. Rediseño de la página de inicio de la
aplicación web (`/`) como portada pública orientada al cliente: mensaje
de venta, beneficios y pasos de la reserva en lugar de la descripción
técnica del sistema. Solo cambió la interfaz de la portada y sus
textos; no cambió el informe ni la base de datos.

## Documento generado

El informe no cambió en este trabajo; no se regeneró el PDF.

## Decisiones adoptadas

- **Portada para todo el mundo:** el texto anterior explicaba el
  sistema al personal («atiende a dos canales», «las cuentas las
  entrega la agencia», capacidades de gestión). La portada nueva
  habla solo del viajero: a dónde ir, por qué reservar aquí y cómo
  se reserva, sin instrucciones de uso interno.
- **Mensaje adaptado a la sesión:** la persona sin sesión ve
  «Ver próximas salidas» (acción pública) y «Crear tu cuenta»; quien
  ya ingresó ve «Ir al panel» según su rol y «Ver próximas salidas».
- **Estructura de tres bloques de marketing:** una portada oscura con
  degradado de la marca y luces suaves decorativas, cuatro tarjetas de
  beneficios (cupos reales, reserva sin trámites, pagos bajo control,
  equipo local) y tres pasos numerados de la reserva, cerrando con una
  franja de invitación final hacia `/disponibilidad`.
- **Contraste robusto en modo claro:** el panel y la franja final
  declaran un color base sólido además del degradado y terminan en
  tonos oscuros (`marca-800`/`marca-600`), y los párrafos usan
  `--vt-color-marca-100` opaco en lugar de blanco translúcido, que era
  lo que se leía mal en modo claro.
- **Textos solo por claves:** todo el contenido nuevo vive en
  `inicio.*` de `es.ts` y `en.ts`; se retiraron las claves de la
  portada anterior (`inicio.cuentas`, `inicio.queSePuedeHacer`,
  `inicio.tarjetas.*`, `inicio.capacidades.*`), que no se usaban en
  ninguna otra vista.

## Cambios de contenido

### Web

- `web/app/pages/index.vue`: portada reescrita con la estructura de
  portada, beneficios, pasos y cierre; conserva la lógica de destino
  del panel por rol.
- `web/app/i18n/locales/es.ts`: claves nuevas de portada
  (`inicio.crearCuenta`, `inicio.beneficios.*`, `inicio.pasos.*`,
  `inicio.cierre.*`) y textos de título e introducción reorientados al
  cliente; claves antiguas retiradas.
- `web/app/i18n/locales/en.ts`: el mismo bloque traducido al inglés,
  alineado clave por clave con el tipo `Mensajes`.

### Documentación

- `docs/changelog/`: este registro.

## Validación realizada

- `npm run typecheck --workspace web` sin errores (el tipo de las
  claves obliga a que `es.ts` y `en.ts` coincidan).
- `npm run build --workspace web` compila sin errores, dos veces: tras
  el rediseño y tras el ajuste de contraste.
- Comprobación de las clases compiladas del degradado y los colores en
  el CSS de salida al diagnosticar el contraste en modo claro.

## Archivos modificados

Web: `web/app/pages/index.vue`, `web/app/i18n/locales/es.ts`,
`web/app/i18n/locales/en.ts`. Documentación: `docs/changelog/`.

## Pendientes o decisiones para el siguiente trabajo

- Se intentó generar una fotografía del Salar de Uyuni para la portada
  y el servicio falló por credenciales; la portada quedó solo con CSS.
  Si se quiere una foto, colocarla en `web/public/img/` y superponerla
  al panel con un velo oscuro.
- La franja de cierre usa un degradado hacia `marca-600`; si se
  publica con foto en la portada, revisar que ambos bloques no compitan
  visualmente.
