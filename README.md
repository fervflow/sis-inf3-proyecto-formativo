# Informe de Proyecto de Grado — Sistemas de Información III

Repositorio del informe de la materia **Sistemas de Información III**,
Carrera de Ingeniería de Sistemas, Universidad Privada Domingo Savio
(UPDS), Sede Potosí.

El documento analiza y propone un **sistema web de gestión de paquetes
turísticos y reservas** para **Vizcacha Tours**, una agencia ficticia de
Potosí. La clase LaTeX aplica el formato **APA 7.ª edición en español** con
los ajustes de la cátedra: papel carta, márgenes 2,54 / 2,54 / 3 / 2 cm,
Arial 11 pt, interlineado 2, texto justificado y paginación inferior
derecha. Las reglas editoriales completas están en `informe/README.md`.

## Documentación

| Documento | Contenido |
|---|---|
| `informe/README.md` | Reglas de edición, formato y orden del informe |
| `docs/GUIA-LATEX.md` | Sintaxis, tablas, figuras, citas y compilación |
| `docs/INSTALACION-WINDOWS.md` | Instalación en Windows 11 |
| `AGENTS.md` | Guía operativa para agentes y modelos |
| `sistema/diagramas/README.md` | Reglas de los diagramas |
| `tablero/README.md` | Uso del tablero kanban |
| `bd/diccionario-datos.md` | Esquema y reglas de la base de datos |
| `web/README.md` | Puesta en marcha de la web del sistema |
| `sistema/estimacion/README.md` | Cálculo del esfuerzo y del costo |
| `docs/changelog/` | Bitácora de los trabajos aceptados |

## Requisitos e instalación

En Arch/Omarchy:

```bash
sudo pacman -S --needed texlive-basic texlive-xetex texlive-binextra \
  texlive-latexrecommended texlive-latexextra texlive-fontsrecommended \
  texlive-fontsextra texlive-langspanish texlive-bibtexextra \
  biber plantuml jre-openjdk librsvg texlab
```

- `texlive-xetex` aporta XeLaTeX y `texlive-binextra` aporta `latexmk`.
- `librsvg` aporta `rsvg-convert`, que convierte los SVG a PDF con las
  fuentes embebidas.
- `plantuml` y `jre-openjdk` generan los diagramas UML.

Arial es opcional: si no está instalada, la clase usa **Liberation Sans**,
que es métricamente idéntica y no altera la paginación.

```bash
yay -S ttf-ms-fonts          # Arial
sudo fmtutil-sys --byfmt xelatex   # solo si falta el formato de XeLaTeX
```

## Compilación

| Comando | Qué hace |
|---|---|
| `make` | Genera diagramas, compila y publica el PDF |
| `make pdf` | Compila sin regenerar diagramas |
| `make diagramas` | Convierte los `.puml` a PDF |
| `make png` | Exporta los diagramas a PNG |
| `make publicar` | Copia el PDF a `entregables/` |
| `make verificar` | Revisa diagramas y rutas |
| `make estimacion` | Compila la hoja de resumen de la estimación |
| `make estimacion-scrum` | Compila la hoja de resumen con Scrum |
| `make ver` | Muestra páginas, tamaño y fuentes del PDF |
| `make clean` / `make distclean` | Borra auxiliares / también las salidas |

En Windows:

```powershell
.\build.ps1              # compila y publica
.\build.ps1 -Diagramas   # regenera los diagramas y compila
.\build.ps1 -Png         # exporta los PNG y compila
.\build.ps1 -Ver         # compila y muestra información del PDF
.\build.ps1 -Limpiar     # borra _build
.\build.ps1 -LimpiarTodo # borra _build y los diagramas generados
```

El PDF intermedio queda en `_build/main.pdf` y el entregable en
`entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes
Turísticos y Reservas.pdf`. La carpeta `entregables/` no se versiona.

La bibliografía usa **biber**, no BibTeX. Compile con **XeLaTeX** o
**LuaLaTeX**; `pdflatex` no sirve porque la clase carga Arial con
`fontspec`.

## Estructura

```text
proyecto-formativo/
├── main.tex                 Documento maestro
├── si3apa7.cls              Formato APA y ajustes de la cátedra
├── entornos-apa.sty         Tablas, figuras y citas en bloque
├── Makefile / build.ps1     Compilación en Linux / Windows
├── informe/                 Contenido del documento
│   ├── configuracion/       Portada y metadatos
│   ├── capitulos/           Secciones 01 a 11
│   ├── finales/             Referencias, glosario y anexos
│   ├── anexos/              Anexo A: árbol de problemas (TikZ)
│   ├── bibliografia/        Base BibLaTeX
│   └── figuras/             Logos y capturas
├── sistema/                 Diseño del sistema
│   ├── diagramas/           Fuentes UML, TikZ y otros
│   ├── historias-usuario/   Backlog (MD y CSV)
│   └── estimacion/          Estimación de esfuerzo y costo
├── bd/                      Esquema y diccionario de datos
├── tablero/                 Tablero kanban y planificación
├── web/                     Aplicación Nuxt, Drizzle y Better Auth
├── docs/                    Guías y bitácora
├── entregables/             PDF final y diagramas generados
└── _build/                  Salida del compilador
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
| `bd/esquema.sql` | Sí | Esquema de la base de datos |
| `sistema/historias-usuario/*` | Sí | Backlog |
| `web/**` | Sí | La web del sistema |
| `tablero/tablero.md` | Sí, desde la vista kanban | Fuente de ejecución: columnas, texto, prioridad, fechas y costos |
| `main.tex` | Poco | Agregar o quitar capítulos |
| `si3apa7.cls` y `entornos-apa.sty` | No\* | Ya definen el formato |
| `entregables/` y `_build/` | Nunca | Se regeneran |

\* Solo para cambiar el formato de todo el documento.

## La web del sistema

El repositorio es un monorepo: el informe en la raíz y la aplicación en
`web/` (Nuxt 4, Drizzle ORM, Better Auth y PostgreSQL en Neon).

```bash
make web-install   # instala el espacio de trabajo
make web-dev       # levanta la aplicación en http://localhost:3000
make web-build     # compila para producción
make db-crear      # crea el esquema con bd/esquema.sql
```

La puesta en marcha completa, las variables de entorno y el despliegue en
Vercel están en `web/README.md`.

## Diagramas

```bash
make diagramas   # PDF en entregables/diagramas/pdf/
make png         # PNG en entregables/diagramas/png/
```

Las fuentes están en `sistema/diagramas/uml/` y las reglas del modelo en
`sistema/diagramas/README.md`. Los diagramas que no son UML (DER,
arquitectura, mockups) se hacen con draw.io y se guardan en
`sistema/diagramas/otros/`.

En VS Code, las extensiones recomendadas son **LaTeX Workshop** y
**PlantUML**. La vista previa de PlantUML funciona sin configurar nada: la
extensión usa su propio JAR. Si hiciera falta otro, se configura en los
ajustes de usuario de VS Code, no en el repositorio.

## Problemas frecuentes

| Síntoma | Solución |
|---|---|
| `latexmk: command not found` | `sudo pacman -S texlive-binextra` |
| Falta el formato `xelatex.fmt` | `sudo pacman -S texlive-xetex` y `sudo fmtutil-sys --byfmt xelatex` |
| Aparece «Liberation Sans» en lugar de Arial | `yay -S ttf-ms-fonts` |
| Un diagrama aparece como recuadro de aviso | `make diagramas` |
| El PDF no muestra las referencias | `make pdf` (incluye biber) |
| Cambió el título y no se actualiza | Compile otra vez para regenerar índices |

Las opciones de la clase y los detalles de APA están en
`docs/GUIA-LATEX.md` y `informe/README.md`.
