# Ficha de la salida: proveedores con formato y solicitud dentro de la ficha

## Fecha y alcance

25 de noviembre de 2026. Pulido de la ficha de la salida (HU-18):
formato de los textos de los proveedores de servicio y botón de
solicitud de reserva dentro de la propia ficha, además de los que ya
tenían las tarjetas.

## Documento generado

El informe no cambió en este trabajo; no se regeneró el PDF.

## Decisiones adoptadas

- **Proveedores con jerarquía visual:** cada proveedor lleva un chip
  con el icono de su tipo de servicio (transporte, hospedaje, guía,
  alimentación u otro), el nombre con su insignia de tipo, la
  descripción en tono suave debajo y el costo interno del personal a
  la derecha. Los detalles por servicio se listan bajo una línea
  divisoria con un marcador propio por entrada, en lugar de bloques
  planos. Con la ficha ancha, los proveedores se reparten en dos
  columnas.
- **Insignias con icono en las asignaciones:** el guía y la unidad
  asignados muestran el mismo icono de tipo de servicio que los
  proveedores.
- **Solicitud dentro de la ficha:** el botón «Solicitar» aparece en el
  pie de la ficha cuando quedan cupos y sigue el mismo flujo que en
  las tarjetas — sin sesión lleva a ingresar, el personal va a su
  bandeja de solicitudes y el cliente abre el formulario en el mismo
  diálogo de solicitud. La ficha se cierra al continuar el flujo.
- **Formulario con contrato propio:** el formulario de solicitud web
  declara `SalidaSolicitud`, el resumen mínimo que consume (salida,
  paquete, código, fechas, cupo disponible y precio); la ficha lo
  construye con sus datos sin depender de las listas ya cargadas, y
  las tarjetas siguen pasando la salida completa, que lo respeta por
  estructura.

## Cambios de contenido

### Web

- `web/shared/types/api.ts`: tipo nuevo `SalidaSolicitud` con los
  siete datos que consume el formulario de solicitud web.
- `web/app/components/solicitudes/FormularioCliente.vue`: su prop
  `salida` pasa a `SalidaSolicitud`.
- `web/app/components/salidas/FichaSalida.vue`: proveedores con chip
  de icono por tipo, detalles con marcador y dos columnas; insignias
  de asignaciones con icono; botón «Solicitar» en el pie y evento
  `solicitar` nuevo; «Editar salida» pasa a variante suave para que la
  solicitud siga siendo la acción principal.
- `web/app/pages/disponibilidad.vue`: `solicitar` recibe el resumen
  `SalidaSolicitud`; la ficha abre el flujo con
  `solicitarDesdeFicha`.

### Documentación

- `docs/changelog/`: este registro.

## Validación realizada

- `npm run typecheck --workspace web` y
  `npm run build --workspace web` sin errores.
- Revisión del flujo: la ficha cierra su diálogo y el formulario de
  solicitud recibe salida, fechas, cupo y precio de la ficha cargada.

## Archivos modificados

Web: `web/shared/types/api.ts`,
`web/app/components/solicitudes/FormularioCliente.vue`,
`web/app/components/salidas/FichaSalida.vue`,
`web/app/pages/disponibilidad.vue`. Documentación: `docs/changelog/`.

## Pendientes o decisiones para el siguiente trabajo

- Eliminar la rama de respaldo
  `respaldo-tarjetas-sobre-base-vieja` cuando se confirme que no hace
  falta rescatar nada de la iteración descartada.
- Aviso flotante desde la ficha si la lista pública quedó desactualizada.
