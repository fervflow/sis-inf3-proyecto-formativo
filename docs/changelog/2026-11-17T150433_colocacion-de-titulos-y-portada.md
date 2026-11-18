# Colocación de los títulos y portada con dos autores

- **Fecha:** 17 de noviembre de 2026, 15:04 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios)
- **Alcance:** los títulos del informe ya no dejan huecos en blanco sobre
  ellos cuando caen al principio de una página, el párrafo de la sección 3
  deja de partirse entre dos páginas, y la portada institucional declara a
  los dos autores del trabajo y a la docente.

## Antecedente

La revisión del PDF publicado señalar tres defectos de colocación:

1. En la página 4 sobraba espacio al pie y la última línea del párrafo de la
   sección 3 («pecto de las reservas confirmadas.») quedaba sola en la
   página 5.
2. En la página 12, donde empiezan las referencias, había un hueco en blanco
   antes del título.
3. En la página 15, la del título del anexo, se sospechaba un hueco
   equivalente.

## Cambios de formato

### Causa común de los tres defectos

`titlesec` y `tocloft` construyen el título con `\vspace*`, un espacio que
**no es descartable**. De ahí se derivaban los dos síntomas:

- El espacio sobrevive aunque el título quede al principio de la página, de
  modo que el título quedaba por debajo del margen superior.
- `titlesec` no coloca ninguna penalización antes del título de capítulo
  (las secciones sí llevan `\addpenalty{\@secpenalty}`), por lo que no era
  posible cortar de página justo antes del título. El párrafo anterior se
  veía obligado a partirse y dejaba una sola línea en la página siguiente.

### Corrección aplicada en `si3apa7.cls`

Se sustituyó `\vspace*` por la solución que LaTeX ya aplica a las secciones:
el espacio se agrega con `\addvspace` (descartable, de modo que desaparece
al inicio de la página) y se precede del castigo `\@secpenalty`, que permite
el corte antes del título. Son cuatro parches, cada uno con un aviso si la
operación no se aplica:

| Paquete | Macro | Cambio |
|---|---|---|
| `titlesec` | `\ttl@mkchap@i` | `\vspace*{\@tempskipa}` → `\addpenalty{\@secpenalty}\addvspace{\@tempskipa}` |
| `tocloft` | `\@cftmaketoctitle` | `\vspace*{\cftbeforetoctitleskip}` → `\addvspace{\cftbeforetoctitleskip}` |
| `tocloft` | `\@cftmakelottitle` | `\vspace*{\cftbeforelottitleskip}` → `\addvspace{\cftbeforelottitleskip}` |
| `tocloft` | `\@cftmakeloftitle` | `\vspace*{\cftbeforeloftitleskip}` → `\addvspace{\cftbeforeloftitleskip}` |

### Efecto medido

Posición de cada título respecto del margen superior de la hoja (72 pt):

| Título | Antes | Después |
|---|---|---|
| Índice, Índice de tablas e Índice de figuras | 96,9 pt | 75,0 pt |
| Capítulos 1, 2, 5, 8 y 9 al inicio de página | 129,8 pt | 79,4 pt |
| Referencias | 129,8 pt | 79,4 pt |
| Anexo A, página apaisada | 142,9 pt | 92,4 pt |

### Página 4

El párrafo de la sección 3 ya no se parte: la página termina con «De
confirmarse estas dificultades… respecto de las reservas confirmadas.» y
continúa con el capítulo 4 y su texto. Antes quedaba una línea huérfana en
la página 5 y sobraban 174 pt al pie de la página 4; ahora sobran 109 pt,
porque el bloque «5. Objeto de estudio y campo de acción», su subsección
5.1 y la primera línea de texto no caben completos y se trasladan juntos a
la página 5. Es el comportamiento correcto: un título de capítulo no debe
quedar solo al pie de una página.

## Cambios de contenido

No hubo cambios en el texto de las secciones del informe. Los cambios se
limitan a la portada y a los datos del documento.

### Portada institucional

Declara a los dos autores del trabajo y a la docente:

- Roberto Carlos Ereño Acuña
- Erick Fernando Velasco Flores
- Docente: Ing. Carmen Nelinda Ozuna Villca

Los números de registro universitario **no** se incluyen: el autor del
proyecto pidió retirarlos de la portada.

### Datos del documento

`informe/configuracion/metadatos.tex` declara ahora los datos por separado:

```latex
\newcommand{\autorUno}{Roberto Carlos Ereño Acuña}
\newcommand{\autorDos}{Erick Fernando Velasco Flores}
\newcommand{\autor}{\autorUno\space y\space \autorDos}
\newcommand{\docente}{Ing. Carmen Nelinda Ozuna Villca}
```

`\autor` resume la lista y sigue alimentando el metadato `Author` del PDF,
que ahora vale «Roberto Carlos Ereño Acuña y Erick Fernando Velasco
Flores». La portada institucional imprime los dos nombres en negrita y la
portada APA alternativa (`portada=apa`) los lista en dos líneas.

## Archivos modificados

- `si3apa7.cls`: colocación de los títulos.
- `informe/configuracion/metadatos.tex`: datos de los autores y de la docente.
- `informe/configuracion/portada.tex`: presentación de los dos autores.
- `informe/README.md`: se documenta el parche de colocación de los títulos y
  se corrigen los nombres de las macros de la portada.
- `documentacion/GUIA-LATEX.md`: el ejemplo de edición de los datos de la
  portada refleja las macros nuevas.
- `README.md`: la sección de edición del informe menciona los dos autores.

## Validación

- `make` compiló desde cero (`make clean` y `make`) sin errores ni avisos de
  LaTeX, y publicó el PDF en `entregables/`. El número de páginas se
  mantiene en 21.
- `make verificar` terminó con cero problemas: 22 diagramas, 20 rutas LaTeX
  y 24 entradas del árbol del README.
- No hay citas indefinidas, ni apariciones de «s. f.», ni primera persona
  del plural en el texto extraído del PDF.
- Se revisaron visualmente las páginas 1, 3, 4, 10, 12, 15, 18 y 21, y la
  variante de portada APA, que compila sin errores.
- El aviso `xdvipdfmx:warning: Object @page.1 already defined` es previo a
  estos cambios: se reproduce con la clase sin parchear.

## Pendientes

- La macro `\correo` conserva el valor genérico `estudiante@upds.edu.bo` y no
  se usa en ningún punto del documento. Queda por decidir si se elimina o si
  se declara un correo por autor.
- Al pie de la página 4 quedan 109 pt libres: el bloque del capítulo 5 no
  cabe completo. Se acepta como resultado normal del corte de página; para
  una página más compacta habría que reducir el espacio antes de los
  títulos de capítulo.
- En la página apaisada del anexo, el título queda a 92,4 pt del borde. El
  desplazamiento restante proviene de `lscape`/`pdflscape` al rotar la
  página, no del espacio de título: se comprobó que con espacio nulo antes
  del título la posición no cambia.
