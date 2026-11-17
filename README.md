# Informe de Proyecto de Grado — Sistemas de Información III

Repositorio del informe de proyecto de grado de la materia **Sistemas de
Información III**, Carrera de Ingeniería de Sistemas, Universidad Privada
Domingo Savio (UPDS), Sede Potosí.

El documento analiza y propone un **sistema web para la gestión de paquetes
turísticos y reservas en Vizcacha Tours, Potosí**. La clase LaTeX impone el
formato **APA 7.ª edición en español** con los ajustes institucionales
indicados por la cátedra:

| Elemento | Definición |
|---|---|
| Papel | Carta (21,59 × 27,94 cm) |
| Márgenes | Superior 2,54 cm · Inferior 2,54 cm · **Izquierdo 3 cm** · Derecho 2 cm |
| Fuente | Arial 11 pt (o Liberation Sans si Arial no está instalada) |
| Interlineado | 2 |
| Paginado | Esquina inferior derecha; preliminares en romanos y cuerpo en árabes |
| Alineación | Justificada (ajuste solicitado; APA recomienda izquierda) |
| Sangría | Primera línea 1,27 cm; sin espacio adicional entre párrafos |

El contenido corresponde a un perfil de proyecto sobre un sistema web de
gestión de paquetes turísticos y reservas para Vizcacha Tours, Potosí. Cada
sección vive en un archivo propio dentro de `informe/capitulos/`, con su
`\chapter` y su `\label`, para poder editarlas por separado.

## Documentación

- **`documentacion/GUIA-LATEX.md`** — cómo funciona LaTeX, cómo está
  organizada este proyecto, cómo editarlo y cómo compilarlo.
- **`documentacion/INSTALACION-WINDOWS.md`** — instalación completa en
  Windows 11 con winget y Scoop, y compilación con `build.ps1`.
- **`AGENTS.md`** — guía operativa para agentes y modelos que trabajen en el
  repositorio: qué es el proyecto, los comandos y a qué documento leer según
  la tarea.
- **`informe/README.md`** — las reglas de edición del documento: formato,
  orden de las secciones y flujo de trabajo.
- **`sistema/diagramas/README.md`** — las reglas que deben respetar los
  diagramas del sistema.
- **`sistema/tablero/README.md`** — cómo se genera y se usa el tablero
  kanban de las 39 tareas.
- **`sistema/estimacion/README.md`** — cómo se calcula el costo del sistema
  con el método ágil y de dónde sale cada cifra.
- **`documentacion/registro-cambios/`** — bitácora de los trabajos aceptados,
  con el detalle del contenido aplicado en cada uno.

---

## 1. Requisitos e instalación

Todo se instala desde los repositorios oficiales de Arch/Omarchy:

```bash
sudo pacman -S --needed texlive-basic texlive-xetex texlive-binextra \
  texlive-latexrecommended texlive-latexextra texlive-fontsrecommended \
  texlive-fontsextra texlive-langspanish texlive-bibtexextra \
  biber plantuml jre-openjdk librsvg texlab
```

- `texlive-xetex` aporta el motor y el formato de XeLaTeX.
- `texlive-binextra` aporta `latexmk` (compilación incremental).
- `librsvg` aporta `rsvg-convert`, que convierte los diagramas SVG a PDF
  con las **fuentes embebidas**.
- `plantuml` + `jre-openjdk` generan los diagramas UML.

Arial real (opcional, porque ya viene incluida en `ttf-ms-fonts`):

```bash
yay -S ttf-ms-fonts
```

Si Arial no está disponible, la clase usa automáticamente **Liberation
Sans**, que es métricamente idéntica y no altera la paginación.

### Si XeLaTeX indica que falta el formato

```bash
sudo fmtutil-sys --byfmt xelatex
```

Si existe un formato de usuario creado previamente, elimínelo para que se
use el del sistema:

```bash
rm -f ~/.texlive/texmf-var/web2c/xetex/xelatex.fmt
```

---

## 2. Compilación

```bash
make            # genera diagramas, compila y publica el PDF
make pdf        # compila sin regenerar diagramas
make diagramas  # convierte todos los .puml a PDF
make png        # exporta todos los diagramas a PNG en entregables/diagramas/png/
make publicar   # vuelve a copiar el PDF a entregables/ con su nombre definitivo
make verificar  # revisa que los diagramas no tengan participantes sueltos
make tablero    # regenera el tablero kanban desde el backlog
make estimacion # compila la hoja de resumen de la estimación de dos páginas
make estimacion-scrum  # compila la hoja de una página con metodología Scrum
make ver        # muestra páginas, tamaño y fuentes del PDF
make clean      # borra archivos auxiliares
make distclean  # borra también los diagramas generados y los PNG
```

El PDF se publica en **`entregables/`** con su nombre definitivo:

```
entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf
```

El PDF intermedio queda en `_build/main.pdf`, junto a los archivos
auxiliares de compilación. Toda la carpeta `entregables/` es material
generado y **no se versiona**: el PDF se reconstruye desde las fuentes con
un solo `make`.

En Windows, los mismos pasos se ejecutan con `build.ps1`:

```powershell
.\build.ps1              # compila el informe
.\build.ps1 -Diagramas   # genera diagramas y compila
.\build.ps1 -Png         # exporta los diagramas a PNG y compila
.\build.ps1 -Ver         # compila y muestra información del PDF
.\build.ps1 -Limpiar     # borra _build
.\build.ps1 -LimpiarTodo # borra _build, los PDF y los PNG de diagramas
```

### 2.1 Exportación a PNG

`make png` (o `.\build.ps1 -Png`) genera una copia rasterizada de cada
diagrama en **`entregables/diagramas/png/`**, manteniendo la misma estructura de
carpetas que `entregables/diagramas/pdf/`.

- **Resolución:** 300 DPI por omisión. Se cambia con `make png PNG_DPI=600` o
  `.\build.ps1 -Png -Dpi 600`.
- **Fondo:** blanco opaco, sin canal de transparencia, para que las
  imágenes se impriman y se peguen en cualquier documento.
- Los PNG son material derivado para revisión rápida, presentaciones y
  documentación: **no se versionan**, y la carpeta está en `.gitignore`.
- El árbol de problemas, que es un diagrama TikZ y no PlantUML, también se
  exporta; para eso se requiere `pdftoppm` (poppler-utils) en Linux o
  Inkscape o ImageMagick en Windows.

También puede compilar con `latexmk -xelatex main.tex` (respeta
`.latexmkrc`). No use `pdflatex`: la clase exige XeLaTeX o LuaLaTeX porque
carga Arial mediante `fontspec`.

---

## 3. Estructura del proyecto

```
proyecto-formativo/
├── main.tex                 Archivo maestro: orden de todos los archivos
├── si3apa7.cls              Clase: formato, fuentes, márgenes, títulos APA
├── entornos-apa.sty         Entornos: tabla APA, figura APA, cita en bloque
├── latexmkrc                Configuración de latexmk (XeLaTeX + biber)
├── Makefile                 Atajos de compilación y de diagramas (Linux)
├── build.ps1                Compilación y diagramas en Windows
├── AGENTS.md                Guía operativa para agentes y modelos
├── informe/                 El contenido del documento
│   ├── README.md            Reglas de edición del informe
│   ├── configuracion/       Portada y metadatos
│   ├── preliminares/        Resumen
│   ├── capitulos/           Secciones 01 a 11 (06 no incluida)
│   ├── finales/             Referencias, glosario y anexos
│   ├── anexos/              Anexo A: árbol de problemas (TikZ)
│   ├── bibliografia/        Base bibliográfica BibLaTeX
│   └── figuras/             Logos y capturas
├── sistema/                 El sistema que se diseña
│   ├── diagramas/
│   │   ├── README.md        Reglas del modelo y verificación
│   │   ├── uml/             Archivos .puml por tipo de diagrama
│   │   ├── tikz/            Diagramas dibujados en LaTeX
│   │   ├── otros/           DER, arquitectura y mockups
│   │   ├── estilos/         Tema visual de PlantUML
│   │   └── ejemplos-plantilla/  Ejemplos heredados, no del proyecto
│   ├── base-de-datos/       Esquema SQL y diccionario de datos
│   ├── historias-usuario/   Backlog de historias de usuario (CSV y MD)
│   ├── tablero/             Tablero kanban generado desde el backlog
│   ├── estimacion/          Estimación de costos del sistema
│   ├── verificar-uml.py     Comprueba los diagramas UML
│   └── verificar-rutas.py   Comprueba que las rutas existan
├── documentacion/           Guías y bitácora
│   ├── GUIA-LATEX.md        Guía de LaTeX y del proyecto
│   ├── INSTALACION-WINDOWS.md  Instalación en Windows 11
│   └── registro-cambios/    Bitácora de los trabajos aceptados
├── entregables/             Lo que se entrega
│   ├── Informe de Proyecto Formativo - Sistema de Gestión de
│   │   Paquetes Turísticos y Reservas.pdf   (PDF final)
│   └── diagramas/           PDF y PNG de los diagramas
├── _build/                  Salida del compilador (se borra sola)
└── .vscode/                 Configuración y extensiones recomendadas
```

### Qué archivo se edita

| Archivo | ¿Editar? | Para qué |
|---|---|---|
| `informe/configuracion/metadatos.tex` | Sí | Portada, autores, docente, gestión |
| `informe/capitulos/*.tex` | Sí | Contenido del informe |
| `informe/bibliografia/referencias.bib` | Sí | Agregar fuentes |
| `informe/finales/glosario.tex` | Sí | Términos y acrónimos |
| `informe/anexos/*.tex` | Sí | Material complementario |
| `sistema/diagramas/uml/*.puml` | Sí | Diagramas UML |
| `sistema/base-de-datos/*.sql` | Sí | Esquema de la base de datos |
| `sistema/historias-usuario/*` | Sí | Backlog de historias de usuario |
| `main.tex` | Poco | Solo para agregar o quitar capítulos |
| `si3apa7.cls` | No\* | Ya impone el formato |
| `entornos-apa.sty` | No\* | Ya define las tablas y figuras |
| `entregables/` | Nunca | Se regenera con `make` |
| `_build/` | Nunca | Se regenera solo |

\* Solo si necesita cambiar el formato para todo el documento.

---

## 4. Cómo editar el informe

### 4.1 Datos generales

Edite **`informe/configuracion/metadatos.tex`**: título, subtítulo, autores
(`\autorUno` y `\autorDos`), docente, gestión, ciudad y fecha de entrega. La
portada, los metadatos del PDF y la bibliografía se actualizan solos.

### 4.2 Secciones principales

Cada archivo de `informe/capitulos/` corresponde a una sección principal del
informe. Estas secciones se numeran y se suceden sin salto de página:

1. Introducción
2. Antecedentes
3. Situación problemática
4. Problema científico
5. Objeto de estudio y campo de acción
6. Objetivos
7. Población y muestra
8. Justificación social
9. Alcances del sistema
10. Límites del proyecto

La antigua sección de variables (`informe/capitulos/06-variables.tex`) ya no se
incluye: la variable dependiente se integra en el problema científico y la
variable independiente en el objetivo general. El árbol de problemas está en
el Anexo A. Cuando el proyecto avance, las secciones de metodología,
desarrollo, resultados y conclusiones se agregan como archivos nuevos sin
alterar el formato.

Para agregar un capítulo, cree el archivo y añada su `\input` en
`main.tex`.

### 4.3 Antes de escribir

- **Las reglas editoriales obligatorias**, el formato del documento, los
  niveles de título, el orden de las secciones y el flujo para agregar una
  sección nueva están en **`informe/README.md`**.
- **La sintaxis de LaTeX** (tablas, figuras, citas, comillas y guiones) está
  en **`documentacion/GUIA-LATEX.md`**, con ejemplos copiables.

---

## 5. Diagramas

Los diagramas son archivos `.puml` dentro de `sistema/diagramas/uml/`. El
flujo completo (crear, generar e insertar en el informe) está en
`documentacion/GUIA-LATEX.md`, y las reglas del modelo que deben respetar
en `sistema/diagramas/README.md`.

```bash
make diagramas   # genera los PDF en entregables/diagramas/pdf/
make png         # genera los PNG en entregables/diagramas/png/
```

Por tipo de diagrama:

| Carpeta | Diagramas |
|---|---|
| `uml/secuencia/` | Los 7 flujos completos de las historias de usuario |
| `uml/secuencia-light/` | Las versiones resumidas de esos 7 |
| `uml/secuencia-comunes/` | 5 subflujos reutilizables |
| `uml/secuencia-fusionados/` | 2 variantes que combinan historias |
| `uml/estructural/` | El diagrama de clases y el de objetos, completos y simplificados |
| `uml/casos-uso/` | El diagrama de casos de uso, con sus `include` y `extend` |
| `uml/procesos/` | El mapa de actividades, el flujo del tablero Kanban y el proceso de estimación |
| `uml/procesos/` | El mapa de actividades con carriles |

Para diagramas que no son UML (DER, arquitectura o prototipos de interfaz)
puede usar [draw.io](https://www.drawio.com/) (`sudo pacman -S
drawio-desktop`), exportar a PDF vectorial y guardarlo en
`sistema/diagramas/otros/`. Luego:

```latex
\incluirImagen[0.9\linewidth]{sistema/diagramas/otros/der.pdf}
```

### VS Code

Extensiones recomendadas (VS Code las sugerirá al abrir el proyecto):

- **LaTeX Workshop** — compilación y vista previa.
- **PlantUML** — vista previa de los `.puml`.
- **Spanish Language Pack** — interfaz en español.

El proyecto incluye `.vscode/settings.json` con la receta de compilación y
la ruta del `plantuml.jar` de Arch (`/usr/share/java/plantuml/plantuml.jar`).

---

## 6. Opciones de la clase

Se configuran en `main.tex`:

| Opción | Valores | Predeterminado |
|---|---|---|
| `fuente` | `auto`, `arial`, `liberation` | `auto` |
| `alineacion` | `izquierda`, `justificada` | `izquierda` |
| `paginacion` | `institucional`, `apa` | `institucional` |
| `interlineado` | `1.5`, `2` | `1.5` |
| `capitulos` | `romanos`, `arabigos`, `sin` | `romanos` (el proyecto usa `arabigos`) |
| `portada` | `institucional`, `apa`, `ninguna` | `institucional` |

El proyecto usa `alineacion=justificada`, `interlineado=2` y
`capitulos=arabigos`.

Ejemplo para un trabajo con texto justificado y secciones en árabe:

```latex
\documentclass[alineacion=justificada,capitulos=arabigos]{si3apa7}
```

---

## 7. Formato APA 7 aplicado

- Secciones de contenido numeradas y alineadas a la izquierda; referencias,
  glosario y anexos con títulos centrados.
- Tablas y figuras numeradas de forma consecutiva (**Tabla 1**, **Figura 1**),
  con título en cursiva y nota con «*Nota.*».
- Citas parentéticas y narrativas, con «y» entre autores en español.
- Referencias con sangría francesa, orden alfabético y localización
  `spanish-apa` de BibLaTeX.
- Comillas inglesas (“ ”) mediante `\enquote{...}`, como indica la
  adaptación española de APA.
- Citas en bloque sin comillas y con sangría de 1,27 cm.
- Listas con sangría APA y sin espacio adicional entre elementos.
- Paginación inferior derecha y sin encabezado de página.

> Nota: APA 7 original exige doble espacio y márgenes de 2,54 cm en los
> cuatro lados. Esta plantilla mantiene el doble espacio y aplica el margen
> izquierdo de 3 cm para el empastado y la justificación solicitada por la
> cátedra.

---

## 8. Correspondencia con el Reglamento de Graduación de la UPDS

El reglamento institucional organiza el trabajo en pre-texto, cuerpo y
post-texto. Esta plantilla cubre esa estructura y la amplía:

| Reglamento UPDS | Plantilla |
|---|---|
| Pre-texto | Portada, resumen, índices |
| Capítulo I: Marco teórico | Sección 2 (Antecedentes) |
| Capítulo II: Diagnóstico | Sección 3 y Anexo A (árbol de problemas) |
| Capítulo III: Propuesta | Secciones 4 a 10 |
| Post-texto | Referencias, glosario y anexos |

Esta versión corresponde a un **perfil de proyecto** con diez secciones
principales. Cuando se agreguen metodología, desarrollo, resultados y
conclusiones, se crean archivos nuevos en `informe/capitulos/` y se añaden a
`main.tex`; el formato no se altera.

---

## 9. Problemas frecuentes

| Síntoma | Solución |
|---|---|
| `latexmk: command not found` | `sudo pacman -S texlive-binextra` |
| `I can't find the format file 'xelatex.fmt'` | `sudo pacman -S texlive-xetex` y `sudo fmtutil-sys --byfmt xelatex` |
| Aparece «Liberation Sans» en lugar de Arial | `yay -S ttf-ms-fonts` |
| Un diagrama aparece como recuadro de aviso | Ejecute `make diagramas` |
| `Please use CSS style instead of skinparam padding` dentro del diagrama | Ya está corregido en `tema-apa.puml`; no agregue `skinparam padding` |
| El PDF no muestra las referencias | Ejecute `make pdf` (incluye biber) o `biber _build/main` |
| Cambié el título y no se actualiza | Compile dos veces (`make pdf`) para regenerar índices |

---

## 10. Buenas prácticas

- Mantenga el proyecto en Git; `_build/` ya está excluido.
- Escriba una idea por párrafo y cite siempre la fuente.
- No modifique `si3apa7.cls` para cambios de contenido: use las opciones de
  clase o `informe/configuracion/metadatos.tex`.
- Verifique el PDF final con `make ver` antes de imprimir: todas las
  fuentes deben aparecer con `emb = yes`.
