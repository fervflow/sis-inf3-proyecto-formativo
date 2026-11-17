# Guía de edición del informe

Reglas para modificar el documento LaTeX de este repositorio. **No forma
parte del informe compilado**: es documentación de trabajo.

El informe analiza y propone un **sistema web para la gestión de paquetes
turísticos y reservas** para **Vizcacha Tours**, una agencia ficticia de la
ciudad de Potosí. El documento se escribe en español, en tercera persona, con
formato APA 7 adaptado por la cátedra.

## Contenido de la carpeta

| Carpeta | Contenido |
|---|---|
| `configuracion/` | `metadatos.tex` (título, autor, docente, gestión) y `portada.tex` |
| `preliminares/` | El resumen, que es el único preliminar incluido. Los demás archivos quedan como respaldo |
| `capitulos/` | Las secciones 01 a 11 del informe |
| `finales/` | `referencias.tex`, `glosario.tex` y `anexos.tex` |
| `anexos/` | El Anexo A, con el árbol de problemas en TikZ |
| `bibliografia/` | `referencias.bib`, la base BibLaTeX |
| `figuras/` | El logotipo institucional y las capturas de pantalla |

---

## Reglas editoriales obligatorias

1. Escribir en **español** y en **tercera persona**.
2. Evitar "nuestro proyecto", "consideramos", "creemos", "podemos" y otras
   formas de primera persona del plural.
3. Usar siempre el nombre **Vizcacha Tours** cuando se mencione la agencia.
4. No incluir la solución tecnológica dentro del problema científico.
5. No convertir el informe en una descripción técnica del sistema: primero
   debe leerse como un informe académico.
6. Citar con `\textcite{...}` o `\parencite{...}`; no escribir autores y años
   manualmente.
7. Toda entrada de `informe/bibliografia/referencias.bib` debe tener `year`.
   Evitar citas con "s. f."; si una fuente no tiene fecha, buscar una fuente
   equivalente con año.
8. No reintroducir la dedicatoria, los agradecimientos ni el abstract: fueron
   retirados del documento. Los archivos existen como respaldo, pero no se
   incluyen en `main.tex`.
9. No reintroducir `informe/capitulos/06-variables.tex`: la variable
   dependiente está en el problema científico y la variable independiente en el
   objetivo general.
10. Mantener la coherencia con las historias de usuario y los diagramas.

---

## El formato del documento

La clase `si3apa7.cls` es la fuente de verdad del formato global. No cambiar
el formato desde los capítulos.

### Formato general

| Elemento | Definición actual |
|---|---|
| Papel | Carta |
| Márgenes | Superior 2,54 cm; inferior 2,54 cm; izquierdo 3 cm; derecho 2 cm |
| Fuente | Arial 11 pt; Liberation Sans como respaldo |
| Interlineado | 2 |
| Alineación | Justificada |
| Sangría | Primera línea 1,27 cm, incluido el primer párrafo |
| Paginación | Inferior derecha; preliminares en romanos y cuerpo en árabes |
| Fuente monoespaciada | Liberation Mono → DejaVu Sans Mono → Consolas → Courier New |

### Títulos

- Las **secciones de contenido 1 a 10** usan `\chapter{...}` pero se comportan
  como subtítulos: van a la izquierda, en negrita, numerados y **sin la
  palabra "Capítulo"**.
- Las secciones de contenido **no comienzan en página nueva**: el texto
  continúa en la misma hoja.
- **Referencias, glosario y anexos** sí comienzan en página nueva y sus
  títulos van **centrados**.
- El **resumen** va centrado.
- Los títulos de sección y subsección se numeran con punto: `2.1.`, `5.2.`,
  etc.
- El índice usa la misma numeración con punto.

### Detalles de implementación

- `\chapter` está parcheado en `si3apa7.cls` para no ejecutar `\clearpage`;
  se reemplaza por `\par`. No revertir este parche sin revisar los saltos de
  página.
- `\iniciarSeccionesFinales` cambia el formato de `\chapter` a centrado antes
  de referencias, glosario y anexos.
- `\preliminar` genera títulos centrados para resumen y glosario.
- `\RaggedRightParindent` está fijado en 1,27 cm aunque la alineación actual
  sea justificada; sirve si se vuelve a alineación izquierda.
- Las tablas y figuras se numeran de forma consecutiva con `tablaapa` y
  `figuraapa`.

---

## Orden actual del documento

`main.tex` incluye, en este orden:

| # | Sección | Archivo |
|---|---|---|
| 1 | Introducción | `informe/capitulos/01-introduccion.tex` |
| 2 | Antecedentes | `informe/capitulos/02-antecedentes.tex` |
| 3 | Situación problemática | `informe/capitulos/03-situacion-problematica.tex` |
| 4 | Problema científico | `informe/capitulos/04-problema-cientifico.tex` |
| 5 | Objeto de estudio y campo de acción | `informe/capitulos/05-objeto-estudio.tex` |
| 6 | Objetivos | `informe/capitulos/07-objetivos.tex` |
| 7 | Población y muestra | `informe/capitulos/08-poblacion-muestra.tex` |
| 8 | Justificación social | `informe/capitulos/09-justificacion-social.tex` |
| 9 | Alcances del sistema | `informe/capitulos/10-alcances-sistema.tex` |
| 10 | Límites del proyecto | `informe/capitulos/11-limites-proyecto.tex` |

`informe/capitulos/06-variables.tex` no se incluye. Su contenido fue retirado
y el archivo solo conserva un comentario de referencia.

Después de las secciones de contenido se incluyen:

1. `informe/finales/referencias.tex`
2. `informe/finales/glosario.tex`
3. `informe/finales/anexos.tex` → `informe/anexos/A-arbol-problemas.tex`

---

## Flujo de trabajo

### Editar una sección

1. Abrir el archivo correspondiente en `informe/capitulos/`.
2. Mantener el `\chapter{...}` y `\label{...}` existentes.
3. Escribir en tercera persona y con citas.
4. Compilar y revisar el PDF.

### Agregar una sección nueva

1. Crear `informe/capitulos/NN-nombre.tex` con `\chapter{...}`.
2. Agregar `\input{informe/capitulos/NN-nombre}` en `main.tex`, en el orden
   correcto.
3. Actualizar la tabla de secciones de este archivo y la de `README.md`.

### Tablas y figuras

Usar los entornos existentes. Los ejemplos completos y copiables están en
`documentacion/GUIA-LATEX.md`, que es la forma canónica de los entornos
`tablaapa` y `figuraapa`.

Lo que conviene recordar aquí:

- `\incluirDiagrama` busca un **PDF** en `entregables/diagramas/pdf/`, con
  ruta relativa y sin extensión.
- `\incluirImagen` se usa para PNG/JPG y requiere extensión.
- No reemplazar los PDF vectoriales por imágenes raster sin una razón
  justificada.

### Citas y bibliografía

- Agregar la entrada en `informe/bibliografia/referencias.bib` con `year`.
- Usar `\textcite{clave}` o `\parencite{clave}`.
- No escribir "(Autor, año)" manualmente.
- Verificar que no aparezcan "s. f." en el PDF.

---

## Documentos relacionados

- `documentacion/GUIA-LATEX.md`: cómo funciona LaTeX y cómo se escriben
  tablas, figuras, citas y listas.
- `sistema/diagramas/README.md`: las reglas que deben respetar los diagramas
  que se incluyen en el informe.
- `README.md`: el árbol completo del proyecto.
