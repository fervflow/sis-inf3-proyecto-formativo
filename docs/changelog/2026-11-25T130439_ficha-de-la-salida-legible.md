# Ficha de la salida legible: detalles compactos y paradas al lado del mapa

## Fecha y alcance

25 de noviembre de 2026. Puesta al día del repositorio local con el
trabajo remoto de la ficha de la salida (HU-18) y rediseño de esa
ficha: los detalles de un vistazo pasan de mini-bloques con marco a
filas compactas con icono, el itinerario de paradas se coloca al lado
del mapa en lugar de debajo, la ficha gana ancho en escritorio y las
secciones reciben encabezados uniformes. Se descartó una iteración
previa del mismo objetivo que había partido de una copia desactualizada
del repositorio.

## Documento generado

El informe no cambió en este trabajo; no se regeneró el PDF.

## Decisiones adoptadas

- **Descarte de la iteración sobre la base desactualizada:** el rediseño
  previo de las tarjetas de salida se había hecho contra la copia local
  desactualizada, sin conocer la ficha de la salida ni su mapa con ruta
  (commits remotos `df4c956` y `36bd7ea`). En lugar de rebasar — con
  conflictos seguros y un resultado semánticamente incorrecto — se
  descartó el commit local, se puso al día el repositorio con
  `reset --hard` hacia el remoto y se rehízo el trabajo donde
  correspondía. El commit descartado queda referenciado por la rama de
  respaldo `respaldo-tarjetas-sobre-base-vieja` y su registro de cambio
  desapareció con él, por no haberse publicado nunca.
- **Detalles como filas compactas, no como tarjetas:** fechas,
  duración, precio, cupo y punto de encuentro comparten una cuadrícula
  de tres columnas con icono de la marca, etiqueta en versalitas y
  valor con peso medio; desaparecen los cuatro bloques con anillo que
  ocupaban la franja completa. Se aprovechó para mostrar la duración
  del paquete, que la ficha no declaraba.
- **Paradas al lado del mapa:** con la ficha a `max-w-5xl`, el mapa
  ocupa tres quintos y la lista numerada de paradas dos quintos, en
  correspondencia con la numeración de los marcadores; la lista vuelve
  a ponerse debajo solo cuando ningún punto tiene coordenadas.
- **Encabezados de sección uniformes:** el patrón repetido de etiqueta
  en versalitas con icono se extrajo al componente base
  `BaseSubtitulo` y se usa en recorrido, itinerario, incluye, no
  incluye, proveedores y asignaciones, con separadores finos que
  ordenan las partes de la ficha.

## Cambios de contenido

### Web

- `web/app/components/base/Subtitulo.vue` (nuevo): subtítulo de
  sección con icono; documentado en `web/docs/componentes.md`.
- `web/app/components/salidas/FichaSalida.vue`: cuadrícula compacta de
  detalles con iconos (fechas, duración, precio, cupo con desglose y
  punto de encuentro), secciones con `BaseSubtitulo`, itinerario de
  paradas al lado del mapa con chips numerados acordes a los
  marcadores, texto del recorrido como línea propia bajo el subtítulo
  y separadores entre bloques.
- `web/app/pages/disponibilidad.vue`: el diálogo de la ficha pasa de
  `max-w-3xl` a `max-w-5xl` para sostener el acomodo lado a lado.

### Documentación

- `web/docs/componentes.md`: `BaseSubtitulo` en la tabla de
  componentes base.
- `docs/changelog/`: este registro.

## Validación realizada

- `npm run typecheck --workspace web` y
  `npm run build --workspace web` sin errores.
- Revisión del componente contra la respuesta real de
  `/api/salidas/[id]`: las paradas traen coordenadas y el mapa une la
  ruta con la línea discontinua de `BaseMapa`.

## Archivos modificados

Web: `web/app/components/base/Subtitulo.vue` (nuevo),
`web/app/components/salidas/FichaSalida.vue`,
`web/app/pages/disponibilidad.vue`, `web/docs/componentes.md`.
Documentación: `docs/changelog/`.

## Pendientes o decisiones para el siguiente trabajo

- Eliminar la rama de respaldo
  `respaldo-tarjetas-sobre-base-vieja` cuando se confirme que no hace
  falta rescatar nada de la iteración descartada.
- Origen y destino viajan como nombres sin coordenadas; si la ficha
  los incorpora como puntos del recorrido, el mapa podrá unir también
  la salida y la llegada.
