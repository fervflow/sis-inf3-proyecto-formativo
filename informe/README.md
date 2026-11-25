# Guía de edición del informe

Reglas para modificar el documento LaTeX. **No forma parte del informe
compilado**: es documentación de trabajo.

El informe analiza y propone un **sistema web de gestión de paquetes
turísticos y reservas** para **Vizcacha Tours**, agencia ficticia de Potosí.
Se escribe en español, en tercera persona, con formato APA 7 adaptado por la
cátedra.

## Contenido de la carpeta

| Carpeta | Contenido |
|---|---|
| `configuracion/` | `metadatos.tex` (título, autores, docente, gestión) y `portada.tex` |
| `preliminares/` | El resumen; los demás archivos quedan como respaldo |
| `capitulos/` | Las secciones 01 a 11 |
| `finales/` | Referencias, glosario y anexos |
| `anexos/` | Anexo A: árbol de problemas en TikZ |
| `bibliografia/` | `referencias.bib` |
| `figuras/` | Logotipo institucional y capturas |

## Reglas editoriales

1. Escribir en **español** y en **tercera persona**.
2. Evitar “nuestro proyecto”, “consideramos”, “creemos” y otras formas de
   primera persona del plural.
3. Usar siempre **Vizcacha Tours** al mencionar la agencia.
4. No incluir la solución tecnológica dentro del problema científico.
5. Mantener el tono académico: el informe no es un manual técnico.
6. Citar con `\textcite{...}` o `\parencite{...}`; no escribir autores y
   años a mano.
7. Toda entrada de `referencias.bib` debe tener `year`; evitar “s. f.”.
8. No reintroducir dedicatoria, agradecimientos ni abstract: los archivos
   existen como respaldo, pero no se incluyen en `main.tex`.
9. No reintroducir `capitulos/06-variables.tex`: la variable dependiente
   está en el problema científico y la independiente en el objetivo
   general.
10. Mantener la coherencia con las historias de usuario y los diagramas.

## Formato del documento

La clase `si3apa7.cls` es la fuente de verdad del formato global. No cambiar
el formato desde los capítulos.

| Elemento | Definición |
|---|---|
| Papel | Carta |
| Márgenes | Superior 2,54 cm; inferior 2,54 cm; izquierdo 3 cm; derecho 2 cm |
| Fuente | Arial 11 pt; Liberation Sans como respaldo |
| Interlineado | 2 |
| Alineación | Justificada |
| Sangría | Primera línea 1,27 cm, incluido el primer párrafo |
| Paginación | Inferior derecha; preliminares en romanos y cuerpo en árabes |
| Monoespaciada | Liberation Mono → DejaVu Sans Mono → Consolas → Courier New |

Sobre APA 7: las tablas y figuras se numeran de forma consecutiva, con
título en cursiva y nota con «*Nota.*»; las referencias usan `spanish-apa`,
sangría francesa y orden alfabético; las comillas son inglesas
(`\enquote{...}`).

### Títulos

- Las secciones de contenido usan `\chapter{...}` pero se comportan como
  subtítulos: a la izquierda, en negrita, numerados y **sin la palabra
  “Capítulo”**.
- Las secciones de contenido **no comienzan en página nueva**.
- Referencias, glosario y anexos sí comienzan en página nueva y sus títulos
  van centrados. El resumen también va centrado.
- Secciones y subsecciones se numeran con punto: `2.1.`, `5.2.`, etc.
- El índice usa la misma numeración.

Los detalles de implementación de la clase están en `docs/GUIA-LATEX.md`.

## Orden del documento

Formato de la cátedra: carátula e índices al inicio, **secciones
preliminares sin numerar** y la propuesta como único capítulo numerado
(**CAPÍTULO III**, con subsecciones 3.1 a 3.4).

`main.tex` incluye, en este orden:

| # | Sección | Archivo |
|---|---|---|
| 0 | Resumen | `informe/preliminares/resumen.tex` |
| 1 | Introducción | `informe/capitulos/01-introduccion.tex` |
| 2 | Antecedentes | `informe/capitulos/02-antecedentes.tex` |
| 3 | Situación problemática (con el árbol de problemas como figura) | `informe/capitulos/03-situacion-problematica.tex` |
| 4 | Problema científico | `informe/capitulos/04-problema-cientifico.tex` |
| 5 | Objeto de estudio y campo de acción | `informe/capitulos/05-objeto-estudio.tex` |
| 6 | Objetivos | `informe/capitulos/07-objetivos.tex` |
| 7 | Población y muestra | `informe/capitulos/08-poblacion-muestra.tex` |
| 8 | Métodos de investigación | `informe/capitulos/08b-metodos-investigacion.tex` |
| 9 | Justificación social | `informe/capitulos/09-justificacion-social.tex` |
| 10 | Alcances del sistema | `informe/capitulos/10-alcances-sistema.tex` |
| 11 | Límites del proyecto | `informe/capitulos/11-limites-proyecto.tex` |
| 12 | CAPÍTULO III: la propuesta (marco referencial, estimación, proceso de negocio, Kanban y diagramas) | `informe/capitulos/12-propuesta.tex` |

Las secciones preliminares usan `\capituloSinNumero{...}` (definido en
`entornos-apa.sty`) y sus subsecciones usan `\section*{...}`. El capítulo de
la propuesta recupera la numeración en `main.tex` (contador en 3, rótulo
`CAPÍTULO III`). Después van `finales/referencias.tex` y
`finales/anexos.tex` → `anexos/A-estimacion.tex` (Anexo A: estimación de
costos). El glosario y el árbol como anexo quedan como respaldo, sin incluir.

## Flujo de trabajo

### Editar una sección

1. Abrir el archivo de `capitulos/`.
2. Mantener el `\chapter{...}` y el `\label{...}` existentes.
3. Escribir en tercera persona y con citas.
4. Compilar y revisar el PDF.

### Agregar una sección

1. Crear `capitulos/NN-nombre.tex` con `\chapter{...}`.
2. Agregar `\input{informe/capitulos/NN-nombre}` en `main.tex`.
3. Actualizar la tabla de secciones de este archivo y la de `README.md`.

### Tablas, figuras y citas

Los ejemplos completos están en `docs/GUIA-LATEX.md`.

- `\incluirDiagrama` busca un PDF en `entregables/diagramas/pdf/`, con ruta
  relativa y sin extensión.
- `\incluirImagen` se usa para PNG/JPG y requiere extensión.
- Agregar la fuente en `referencias.bib` con `year` y citar con
  `\textcite{clave}` o `\parencite{clave}`.
- Verificar que no aparezca “s. f.” en el PDF.

## Correspondencia con el reglamento UPDS

| Reglamento | Plantilla |
|---|---|
| Pre-texto | Portada, resumen, índices |
| Capítulo I: Marco teórico | Sección 2 (Antecedentes) |
| Capítulo II: Diagnóstico | Sección 3 (con el árbol de problemas) |
| Capítulo III: Propuesta | CAPÍTULO III (`12-propuesta.tex`) y Anexo A |
| Post-texto | Referencias y anexos |

## Documentos relacionados

- `docs/GUIA-LATEX.md`: sintaxis, tablas, figuras, citas y compilación.
- `sistema/diagramas/README.md`: reglas de los diagramas.
- `README.md`: estructura completa del proyecto.
