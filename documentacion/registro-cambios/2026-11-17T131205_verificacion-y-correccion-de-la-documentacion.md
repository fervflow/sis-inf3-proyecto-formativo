# Verificación y corrección de la documentación

- **Fecha:** 17 de noviembre de 2026, 13:12 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios)
- **Alcance:** comprobación de que la reagrupación del proyecto hubiera
  aplicado todos los cambios previstos en la documentación, y corrección de
  los que no se habían guardado.

## Antecedente

La reagrupación del proyecto movió 68 archivos y cambió las rutas de
referencia en toda la documentación. Una revisión posterior detectó que
varios de esos cambios no se habían aplicado, y que la herramienta que debía
detectarlo no existía.

El alcance se obtuvo del registro de la reagrupación: la sección
«Archivos modificados» enumeraba los documentos que debían cambiar. Al
comparar esa lista con el estado real de los archivos, las diferencias
quedaron a la vista.

## Cambios de contenido

No hubo cambios en el contenido del informe.

## Cambios de formato

Ninguno en el documento.

## Cambios de proceso

### Documentación que no había cambiado

- **`documentacion/INSTALACION-WINDOWS.md`** era el caso más grave: el
  archivo se había movido de sitio, pero **no se había modificado en
  absoluto**. Todas sus rutas seguían apuntando a la estructura anterior:
  `_build\main.pdf` en lugar del entregable, sin el parámetro `-Png`, sin la
  carpeta de diagramas nueva y sin el árbol de carpetas.
- **`README.md`** tenía cuatro problemas: la sección «Documentación» citaba
  `GUIA-LATEX.md` e `INSTALACION-WINDOWS.md` en la raíz; una frase rota
  introducida por la sustitución automática («bitácora de los trabajos
  aceptados y contenido aplicadas en cada iteración»); una introducción que
  seguía llamándolo «Plantilla LaTeX modular» e instruía a conservar unas
  etiquetas `% TODO:` que solo existen en dos archivos de respaldo no
  incluidos en el informe; y la ausencia de `make publicar` y
  `make verificar` en la lista de comandos.
- **`documentacion/GUIA-LATEX.md`** tenía tres problemas: el diagrama del
  pipeline terminaba en `_build/main.pdf` sin mostrar la publicación del
  entregable; la tabla de comandos no incluía `make png`, `make publicar` ni
  `make verificar`; y la frase «El resultado siempre es `_build/main.pdf`»
  no mencionaba el entregable.
- **`AGENTS.md`** conservaba dos referencias en su sección de documentos de
  referencia que apuntaban a `GUIA-LATEX.md` e `INSTALACION-WINDOWS.md` en la
  raíz.

### Causa

La sustitución automática de rutas se ejecutó antes de que existiera la
carpeta `informe/`, de modo que el patrón de `preliminares/` y `finales/`
quedó desalineado. El caso de la guía de Windows fue distinto: sus rutas
no coincidían con ningún patrón del script, porque usaban barras
invertidas, y por eso nunca se tocó.

### Herramienta de verificación

- Se añadió `sistema/verificar-rutas.py`, que hace dos controles:
  - que cada `\input`, `\include`, `\addbibresource` e `\includegraphics`
    apunte a un archivo que exista, y que las carpetas de `\graphicspath`
    existan;
  - que la documentación no mencione carpetas de una estructura anterior.
- `make verificar` ejecuta ahora las dos comprobaciones, además de la
  revisión de los diagramas.
- El script se validó de forma estática antes de usarlo: se comprobó que
  detectara los cuatro casos realmente presentes, y se ajustó dos veces
  para que no produjera falsos positivos con los árboles de directorios y
  con las rutas que contienen como subcadena las antiguas.

## Archivos modificados

- `README.md`
- `AGENTS.md`
- `documentacion/GUIA-LATEX.md`
- `documentacion/INSTALACION-WINDOWS.md`
- `Makefile`
- `sistema/verificar-rutas.py` (nuevo)
- `sistema/verificar-uml.py`

## Validación

- `make verificar` terminó con cero problemas en las dos comprobaciones.
- Se comprobó que ninguna ruta del proyecto apuntara a un archivo
  inexistente: 20 rutas LaTeX revisadas, 0 inexistentes.
- `make pdf` terminó correctamente y el informe conserva 21 páginas.
- El contenido del informe no se modificó: `git diff --stat` sobre los
  archivos `.tex`, `.cls` y `.sty` sale vacío.
- La diferencia de tres palabras en el recuento de texto del PDF frente a
  la medición anterior se investigó y no supone pérdida de contenido: es el
  corte de línea con guion dentro de los nodos estrechos del árbol de
  problemas, que hace que el extractor de texto cuente distinto según dónde
  caiga el corte. Se comprobó que dos compilaciones consecutivas producen
  un texto extraído idéntico.

## Pendientes

- Verificar `build.ps1 -Png` en un equipo con Windows, PowerShell 5.1 o
  superior e Inkscape instalado.
