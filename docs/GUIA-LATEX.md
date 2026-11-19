# Guía rápida de LaTeX y de este proyecto

LaTeX es un compilador de documentos: se escribe texto con comandos y el
motor calcula márgenes, saltos de línea, índices y bibliografía. El árbol
del repositorio está en `README.md`; esta guía cubre lo necesario para
editar y compilar.

## 1. Cómo funciona

```text
main.tex + informe/**/*.tex
        │  xelatex → biber → xelatex ×2
        ▼
_build/main.pdf  →  make publicar  →  entregables/….pdf
```

LaTeX necesita varias pasadas porque lee su propia salida: primero descubre
páginas y etiquetas; después escribe los números correctos en el índice y
en las referencias. `make` y `latexmk` lo hacen solos.

Este proyecto usa **XeLaTeX** porque carga Arial desde el sistema con
`fontspec`. Por eso `pdflatex` no sirve. La bibliografía usa **biber**, no
BibTeX.

## 2. Sintaxis mínima

```latex
\comando{argumento obligatorio}
\comando[opción]{argumento}

\begin{entorno}
  contenido
\end{entorno}
```

- `%` inicia un comentario.
- Las llaves `{}` agrupan; si falta una, el error suele ser
  `Runaway argument`.
- Una línea en blanco separa párrafos.

### Caracteres reservados

| Escribir | Comando |
|---|---|
| `%` | `\%` |
| `&` | `\&` |
| `_` | `\_` |
| `#` | `\#` |
| `$` | `\$` |
| `{` `}` | `\{` `\}` |
| `~` | `\textasciitilde{}` |
| `^` | `\textasciicircum{}` |
| `\` | `\textbackslash{}` |

### Títulos, etiquetas y referencias

```latex
\chapter{Planteamiento del problema}\label{cap:problema}
\section{Objetivos}
\subsection{Objetivo general}
\subsubsection{Indicadores}
\paragraph{Criterio de medición}

Como se observa en el capítulo~\ref{cap:problema}...
```

Los cinco niveles ya tienen formato APA. No agregar negritas ni tamaños a
mano.

### Citas y bibliografía

```latex
\textcite{huaman2017}              % Huaman Quispe (2017)
\parencite{huaman2017}             % (Huaman Quispe, 2017)
\parencite[p.~45]{huaman2017}      % (Huaman Quispe, 2017, p. 45)
```

La clave se define en `informe/bibliografia/referencias.bib`:

```bibtex
@thesis{huaman2017,
  author      = {Huaman Quispe, Estefani},
  year        = {2017},
  title       = {Sistema de información para la gestión de reserva de
                 paquetes turísticos en la agencia de viaje Rap Travel},
  type        = {Tesis de licenciatura},
  institution = {Universidad Andina del Cusco},
  url         = {https://hdl.handle.net/20.500.12557/1210}
}
```

Toda entrada debe tener `year`. Si una fuente no tiene fecha, se busca otra
equivalente: el informe no admite citas con “s. f.”.

### Comillas y guiones

```latex
\enquote{texto entre comillas}   % “texto entre comillas”
un guion \textendash{} corto      % –
un guion \textemdash{} largo      % —
```

## 3. Ediciones frecuentes

### Portada y metadatos

Editar `informe/configuracion/metadatos.tex`:

```latex
\newcommand{\titulo}{Mi nuevo título}
\newcommand{\autorUno}{Nombre del primer autor}
\newcommand{\autorDos}{Nombre del segundo autor}
\newcommand{\docente}{Nombre del docente}
\newcommand{\gestion}{2026}
```

### Sección principal

Abrir el archivo de `informe/capitulos/` y reemplazar el texto. Cada sección
ya tiene su `\chapter{...}` y sus subsecciones. Para agregar una:

```latex
\section{Nueva sección}
Texto...
```

### Tabla APA

```latex
\begin{tablaapa}{tab:mi-tabla}{Título de la tabla en cursiva}
\begin{tabular}{@{}lcc@{}}
\toprule
Encabezado & A & B \\
\midrule
Dato & 1 & 2 \\
\bottomrule
\end{tabular}
\nota{Elaboración propia.}
\end{tablaapa}
```

En el texto: `Como muestra la Tabla~\ref{tab:mi-tabla}...`

### Figura o diagrama

```latex
\begin{figuraapa}{fig:mi-figura}{Título de la figura}
  \incluirDiagrama[0.9\linewidth]{casos-uso/general}
  \nota{Fuente: elaboración propia.}
\end{figuraapa}
```

La ruta es relativa a `entregables/diagramas/pdf/` y va sin extensión. Para
PNG o JPG se usa `\incluirImagen`, con extensión.

### Código

```latex
\begin{lstlisting}[language=PHP,caption={Descripción},label={lst:ejemplo}]
echo "Hola";
\end{lstlisting}
```

### Capítulo o anexo

1. Crear `informe/capitulos/12-nuevo.tex` con `\chapter{...}`.
2. Agregar `\input{informe/capitulos/12-nuevo}` en `main.tex`.

Para un anexo: crear `informe/anexos/B-nuevo.tex` y agregarlo en
`informe/finales/anexos.tex`. Si incluye figuras, ajustar el prefijo del
contador como en `informe/anexos/A-arbol-problemas.tex`.

### Citas en bloque y listas

```latex
\begin{citalarga}
Texto de más de 40 palabras, sin comillas.
\end{citalarga}

\begin{itemize}
  \item Primer elemento.
  \item Segundo elemento.
\end{itemize}
```

### Opciones globales

En la primera línea de `main.tex`:

```latex
\documentclass[
  alineacion=justificada,   % izquierda (APA) | justificada
  paginacion=apa,           % institucional | apa
  interlineado=2,           % 1.5 | 2
  capitulos=arabigos,       % romanos | arabigos | sin
  portada=apa               % institucional | apa | ninguna
]{si3apa7}
```

| Opción | Valores | Predeterminado |
|---|---|---|
| `fuente` | `auto`, `arial`, `liberation` | `auto` |
| `alineacion` | `izquierda`, `justificada` | `izquierda` |
| `paginacion` | `institucional`, `apa` | `institucional` |
| `interlineado` | `1.5`, `2` | `1.5` |
| `capitulos` | `romanos`, `arabigos`, `sin` | `romanos` |
| `portada` | `institucional`, `apa`, `ninguna` | `institucional` |

El proyecto usa `alineacion=justificada`, `interlineado=2` y
`capitulos=arabigos`.

### Detalles de la clase

- `\chapter` está parcheado para no ejecutar `\clearpage`: las secciones de
  contenido se suceden sin salto de página.
- La colocación de títulos usa `\addvspace` y `\@secpenalty` para evitar
  huecos no descartables al principio de página.
- `\iniciarSeccionesFinales` centra los títulos de referencias, glosario y
  anexos; `\preliminar` hace lo mismo con el resumen.
- `\RaggedRightParindent` queda en 1,27 cm aunque la alineación sea
  justificada, por si se vuelve a la izquierda.
- Las tablas y figuras se numeran con `tablaapa` y `figuraapa`.

## 4. Compilar

| Comando | Qué hace |
|---|---|
| `make` | Genera diagramas, compila y publica |
| `make pdf` | Compila sin tocar los diagramas |
| `make diagramas` | Convierte `.puml` → PDF |
| `make png` | Exporta los diagramas a PNG |
| `make publicar` | Copia el PDF a `entregables/` |
| `make verificar` | Revisa diagramas y rutas |
| `make ver` | Muestra páginas, tamaño y fuentes |
| `make clean` / `make distclean` | Borra auxiliares / también las salidas |

En VS Code, guardar con `Ctrl+S` y LaTeX Workshop compila solo; el PDF se
abre en una pestaña al costado.

### Si algo falla

1. Leer **el primer error** del log (`_build/main.log`), no el último.
2. `-file-line-error` indica `archivo:línea`.
3. Casi siempre es una llave sin cerrar, un `%` sin escapar, una ruta mal
   escrita o un comando mal tipeado.

| Error | Causa habitual |
|---|---|
| `Undefined control sequence` | Comando mal escrito o paquete no cargado |
| `Missing $ inserted` | `_`, `^` o `&` fuera de contexto |
| `Runaway argument` | Falta una `}` |
| `File ... not found` | Ruta o nombre incorrecto |
| `Emergency stop` | Falta `\end{document}` o una llave |
| `There were undefined references` | Falta compilar otra vez |
| `Package biblatex Warning: Please rerun` | Falta ejecutar biber (`make pdf`) |

### Avisos que se pueden ignorar

| Aviso | Significado |
|---|---|
| `Overfull \hbox` | Una línea sobresale unos milímetros |
| `Underfull \hbox` | Una línea quedó con espacios amplios |
| `Font shape ... undefined` | Se sustituyó una variante inexistente |
| `Rerun to get cross-references right` | Normal; la siguiente pasada lo resuelve |

## 5. Diagramas UML

```text
sistema/diagramas/uml/secuencia/registrar-proyecto.puml
        │  make diagramas
        ▼
entregables/diagramas/pdf/secuencia/registrar-proyecto.pdf
        │  \incluirDiagrama{secuencia/registrar-proyecto}
        ▼
main.pdf
```

- Crear el `.puml` en la carpeta del tipo de diagrama.
- Ejecutar `make diagramas` e incluirlo con `\incluirDiagrama{tipo/nombre}`.
- En los diagramas de secuencia, agregar `hide footbox`.
- Para DER, arquitectura o mockups, usar draw.io y guardar el PDF en
  `sistema/diagramas/otros/`.
- El árbol de problemas es TikZ (`sistema/diagramas/tikz/`) y se compila con
  el documento.

## 6. Reglas de oro

1. No formatear a mano: usar `\chapter`, `tablaapa`, `figuraapa`.
2. Una idea por párrafo y una línea en blanco entre párrafos.
3. No editar `_build/`: es salida del compilador.
4. Compilar seguido.
5. Citar siempre con `\textcite` o `\parencite` y su entrada en el `.bib`.
