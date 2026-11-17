# Exportación de diagramas a PNG y corrección de los diagramas

- **Fecha:** 17 de noviembre de 2026, 12:03 (hora local)
- **Documento:** `_build/main.pdf`
- **Páginas:** 21 (sin cambios)
- **Alcance:** opción de exportación de los diagramas en formato PNG, sin
  versionar los archivos resultantes, y corrección de dos diagramas de
  secuencia con participantes sin declarar.

> Este registro fusiona dos entregas que se habían anotado por separado:
> la exportación a PNG y la corrección de los diagramas. Se unifican porque
> el trabajo se aceptó como un solo bloque.

## Cambios de contenido

No hubo cambios en el contenido del informe. La entrega afecta al proceso de
compilación, a los diagramas y a la documentación.

## Cambios de formato

Ninguno en el documento.

## Cambios de proceso

### Exportación a PNG

- Se añadió el objetivo `make png`, que exporta todos los diagramas a PNG en
  `entregables/diagramas/png/`, con la misma estructura de carpetas que
  `entregables/diagramas/pdf/`.
- La resolución es de **300 DPI** por omisión y se puede cambiar con
  `make png PNG_DPI=600`.
- Como el SVG de PlantUML ya trae el tamaño en píxeles a 96 DPI, el
  exportador calcula un factor de escala equivalente (`PNG_ZOOM`).
- El fondo es **blanco opaco**, sin canal de transparencia: se añade
  `-b white` a la llamada de `rsvg-convert` y `--export-background=white` con
  `--export-background-opacity=1` a la de Inkscape.
- Los archivos `.puml` se exportan primero a SVG y luego se rasterizan con
  `rsvg-convert`, de modo que el PNG tenga las mismas fuentes que el PDF. Si
  `rsvg-convert` no está instalado, PlantUML rasteriza directamente y el
  fondo ya es blanco.
- El árbol de problemas es un diagrama TikZ, no PlantUML, así que se compila
  aparte con XeLaTeX en un documento `standalone` temporal y se rasteriza con
  `pdftoppm`. Si la herramienta no está disponible, el PNG del árbol se omite
  y se avisa por pantalla.
- La exportación es incremental: solo se regenera lo que cambió.
- `make distclean` elimina también la carpeta de PNG.

### Compatibilidad con Windows

- `build.ps1` incorporó el parámetro `-Png` y el parámetro `-Dpi`, con 300
  DPI por omisión.
- Se agregó la función `Convertir-DiagramasPng`, que usa Inkscape para
  rasterizar los SVG y, si no está disponible, ImageMagick para convertir el
  PDF del árbol de problemas.
- La detección del motor de PlantUML y la de Inkscape se factoringonaron en
  las funciones `Obtener-MotorPlantUml` y `Obtener-Inkscape`, que ahora
  comparten el código de `Convertir-Diagramas`.
- `build.ps1 -LimpiarTodo` elimina también la carpeta de PNG.
- El documento temporal del árbol de problemas se escribe en ASCII para
  evitar la marca BOM que Windows PowerShell 5.1 agrega con `-Encoding UTF8`
  y que LaTeX no admite al inicio de un archivo.

### Exclusión del control de versiones

- `entregables/diagramas/` se añadió a `.gitignore`.
- Se verificó con `git check-ignore` que los PNG quedan fuera del índice y
  con `git status` que ninguno aparece como cambio.

## Corrección de los diagramas de secuencia

- **HU-05 · Elaboración de cotizaciones:** se declaró la entidad `Reserva`
  que faltaba y se reconstruyó la cadena de interacción, de modo que la
  salida consulta a la reserva, la reserva consulta a la tabla y la tabla
  devuelve el resultado a la reserva, que lo entrega a la salida. Se añadió
  además la respuesta del cliente a la propuesta recibida.
- **HU-06 · Registro de reservas:** se declaró la entidad `ReservaPasajero`
  que faltaba, con el mismo síntoma en su línea de vida.

La causa era la misma en ambos casos: un participante usado en los mensajes
pero nunca declarado. PlantUML no produce ningún error en esas
circunstancias; el diagrama se genera, pero la línea de vida se dibuja con
el alias en lugar del icono con su etiqueta.

### Herramienta de verificación

- Se añadió `sistema/verificar-uml.py`, una utilidad que revisa los archivos
  `.puml` del proyecto y detecta tres clases de fallo: un participante
  usado sin declarar, un participante declarado que no aparece en ningún
  mensaje, y una entidad o tabla que solo emite o solo recibe.
- Se añadió el objetivo `make verificar`, que ejecuta esa comprobación.
- La herramienta quedó documentada en `README.md` y `AGENTS.md`, con el
  aviso de que estos fallos no generan error de compilación y por eso
  conviene ejecutarla tras cada edición.

## Archivos modificados

- `Makefile`
- `build.ps1`
- `README.md`
- `AGENTS.md`
- `.gitignore`
- `sistema/verificar-uml.py` (nuevo)
- `sistema/diagramas/uml/secuencia/hu-05-elaborar-cotizacion.puml`
- `sistema/diagramas/uml/secuencia/hu-06-registrar-reserva.puml`

## Validación

- `make verificar` revisó los 22 archivos `.puml` del proyecto y terminó con
  cero problemas. Antes de la corrección detectó cuatro: `E_RESERVA` sin
  declarar en HU-05, `T_RESERVA` y `TUR` con líneas de vida colgando en el
  mismo archivo, y `E_RESERVA_PASAJERO` sin declarar en HU-06.
- Se regeneraron los diagramas en PDF y en PNG y se revisaron visualmente
  los encabezados de HU-05 y HU-06: las entidades «Reserva» y
  «ReservaPasajero» aparecen con su icono `<<entidad>>` y su etiqueta.
- `make png` generó los 28 PNG. Las imágenes pasaron de 1530 × 1781 a
  4697 × 5566 px en el diagrama de HU-06, y de 682 × 354 a 2132 × 1107 px en
  su versión ligera.
- Todos los PNG quedaron sin canal alfa, con tres canales RGB, y el píxel de
  la esquina es blanco puro `srgb(255,255,255)`; la luminancia media de la
  imagen es 250,5 sobre 255.
- El conjunto completo de PNG ocupa 14 MB.
- La exportación a PDF no se vio afectada: el PDF de HU-05 conserva su
  tamaño de página y su fondo blanco.
- `make pdf` terminó correctamente y el informe conserva 21 páginas.
- El script de PowerShell no pudo ejecutarse en este equipo porque no hay
  PowerShell instalado: se verificó de forma estática el balance de llaves,
  paréntesis y corchetes, que todas las funciones propias estén definidas
  y llamadas, y que todos los parámetros declarados se utilicen.

## Pendientes

- Verificar `build.ps1 -Png` en un equipo con Windows, PowerShell 5.1 o
  superior e Inkscape instalado.
