# Guía rápida de LaTeX y de este proyecto

Para alguien que ya programa: LaTeX es un **compilador de documentos**. Uno
escribe texto con comandos y el motor calcula márgenes, saltos de línea,
índices y bibliografía. No se arrastra nada con el mouse: todo se expresa
en el código.

---

## 1. Cómo funciona LaTeX

### El pipeline

```
main.tex + informe/capitulos/*.tex + informe/configuracion/*.tex
        │
        │  xelatex  (1.ª pasada)
        ▼
 _build/main.aux   → posiciones de \label y \ref
 _build/main.toc   → entradas del índice
 _build/main.bcf   → pedido de bibliografía
        │
        │  biber
        ▼
 _build/main.bbl   → referencias ya ordenadas en APA
        │
        │  xelatex (2.ª y 3.ª pasada)
        ▼
 _build/main.pdf
        │
        │  make publicar (copia)
        ▼
 entregables/Informe de Proyecto Formativo - ....pdf
```

¿Por qué varias pasadas? Porque LaTeX necesita leer su propia salida: en la
primera pasada descubre cuántas páginas hay y dónde quedó cada etiqueta; en
las siguientes escribe los números correctos en el índice y en las
referencias. `make` y `latexmk` hacen esto automáticamente.

### Analogías si vienes de programar

| LaTeX | Equivalente mental |
|---|---|
| `si3apa7.cls` | Configuración global / framework |
| `entornos-apa.sty` | Librería de funciones auxiliares |
| `main.tex` | `main()`: ordena las llamadas |
| `informe/capitulos/*.tex` | Módulos del programa |
| `\label` / `\ref` | IDs y referencias simbólicas |
| `referencias.bib` | Base de datos de fuentes |
| `Makefile` / `build.ps1` | Script de build |

### El motor

Este proyecto usa **XeLaTeX** porque permite cargar Arial directamente desde
el sistema (`fontspec`). Por eso `pdflatex` no sirve aquí. La bibliografía
usa **biber**, no BibTeX.

---

## 2. Sintaxis mínima

### Comandos y entornos

```latex
\comando{argumento obligatorio}
\comando[opción]{argumento}

\begin{entorno}
  contenido
\end{entorno}
```

- `%` inicia un comentario (todo lo que sigue en la línea se ignora).
- Las llaves `{}` agrupan; si falta una, el error suele ser
  `Runaway argument`.
- Los espacios y saltos de línea del fuente no importan: LaTeX decide el
  formato. Deje una línea en blanco entre párrafos.

### Caracteres reservados

| Quiere escribir | Escriba |
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

Los cinco niveles ya tienen el formato APA. No agregue negritas ni tamaños
a mano: el comando `\chapter`/`\section`/... ya aplica el estilo.

### Citas y bibliografía

```latex
\textcite{huaman2017}              % Huaman Quispe (2017)
\parencite{huaman2017}             % (Huaman Quispe, 2017)
\parencite[p.~45]{huaman2017}      % (Huaman Quispe, 2017, p. 45)
```

La clave (`huaman2017`) se define en `informe/bibliografia/referencias.bib`:

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

### Comillas y guiones

```latex
\enquote{texto entre comillas}   % “texto entre comillas”
un guion \textendash{} corto      % –
un guion \textemdash{} largo      % —
```

---

## 3. Mapa del proyecto

```
main.tex
 ├── si3apa7.cls ............ formato: márgenes, Arial 11, 2, justificado
 ├── entornos-apa.sty ....... tablaapa, figuraapa, citalarga, \incluirDiagrama
 ├── informe/ ............... el contenido del documento
 │    ├── configuracion/
 │    │    ├── metadatos.tex . SUS datos (título, autor, docente, gestión)
 │    │    └── portada.tex .. diseño de la portada
 │    ├── informe/preliminares/ ..... resumen
 │    ├── informe/capitulos/01..11 . secciones del informe (06 no incluida)
 │    ├── informe/finales/
 │    │    ├── referencias.tex  imprime la bibliografía
 │    │    ├── glosario.tex     glosario y acrónimos
 │    │    └── anexos.tex       activa los anexos y los llama
 │    ├── informe/anexos/A-arbol-problemas.tex ... árbol de problemas (TikZ)
 │    ├── informe/bibliografia/referencias.bib
 │    └── figuras/ ........... logos y capturas
 ├── sistema/ ................ el sistema que se diseña
 │    ├── diagramas/
 │    │    ├── uml/ .......... archivos .puml que usted edita
 │    │    ├── tikz/ ......... diagramas dibujados en LaTeX
 │    │    ├── estilos/ ...... tema visual de PlantUML
 │    │    ├── otros/ ........ DER, arquitectura, mockups
 │    │    └── ejemplos-plantilla/ ... ejemplos heredados de la plantilla
 │    ├── base-de-datos/ ..... esquema SQL y diccionario
 │    ├── historias-usuario/ . backlog de historias de usuario
 │    ├── verificar-uml.py .. comprueba los diagramas
 │    └── verificar-rutas.py . comprueba las rutas
 ├── entregables/ ........... lo que se entrega
 │    ├── Informe de Proyecto Formativo - ....pdf   (PDF final)
 │    └── diagramas/ ......... PDF y PNG de los diagramas
 └── _build/ ................ salida del compilador (no editar, se borra)
```

### ¿Qué archivo edito?

| Archivo | ¿Editar? | Para qué |
|---|---|---|
| `informe/configuracion/metadatos.tex` | Sí | Portada, autor, docente, gestión |
| `informe/capitulos/*.tex` | Sí | Contenido del informe |
| `informe/bibliografia/referencias.bib` | Sí | Agregar fuentes |
| `informe/finales/glosario.tex` | Sí | Términos y acrónimos |
| `informe/anexos/*.tex` | Sí | Material complementario |
| `sistema/diagramas/uml/*.puml` | Sí | Diagramas UML |
| `sistema/base-de-datos/*.sql` | Sí | Esquema de la base de datos |
| `sistema/historias-usuario/*` | Sí | Backlog de historias de usuario |
| `main.tex` | Poco | Solo para agregar/quitar capítulos |
| `si3apa7.cls` | No* | Ya impone el formato |
| `entornos-apa.sty` | No* | Ya define las tablas/figuras |
| `entregables/` | Nunca | Se regenera con `make` |
| `_build/` | Nunca | Se regenera solo |

\* Solo si necesita cambiar el formato para todo el documento.

---

## 4. Ediciones frecuentes

### Cambiar los datos de la portada

Edite `informe/configuracion/metadatos.tex`:

```latex
\newcommand{\titulo}{Mi nuevo título}
\newcommand{\autor}{Mi Nombre}
\newcommand{\docente}{Nombre del docente}
\newcommand{\gestion}{2026}
```

### Escribir una sección principal

Abra `informe/capitulos/02-antecedentes.tex` y reemplace el texto. Cada sección
principal ya tiene su `\chapter{...}` y sus subsecciones. Los títulos se
numeran y se suceden sin salto de página. Para agregar una subsección:

```latex
\section{Nueva sección}
Texto...
```

### Insertar una tabla APA

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

### Insertar una figura o diagrama

```latex
\begin{figuraapa}{fig:mi-figura}{Título de la figura}
  \incluirDiagrama[0.9\linewidth]{casos-uso/general}
  \nota{Fuente: elaboración propia.}
\end{figuraapa}
```

La ruta es relativa a `entregables/diagramas/pdf/` y va **sin extensión**.

### Insertar código

```latex
\begin{lstlisting}[language=PHP,caption={Descripción},label={lst:ejemplo}]
echo "Hola";
\end{lstlisting}
```

### Agregar un capítulo o anexo

1. Cree `informe/capitulos/12-nuevo.tex` con `\chapter{...}`.
2. Agregue `\input{informe/capitulos/12-nuevo}` en `main.tex`, en el orden deseado.

Para un anexo: cree `informe/anexos/B-nuevo.tex` y agréguelo en
`informe/finales/anexos.tex`. Si el anexo incluye figuras, ajuste el prefijo del
contador (`A`, `B`, ...) como se hace en `informe/anexos/A-arbol-problemas.tex`.

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

### Cambiar opciones globales

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

---

## 5. Compilar

| Comando | Qué hace |
|---|---|
| `make` | Regenera diagramas, compila y publica el PDF |
| `make pdf` | Compila sin tocar los diagramas |
| `make diagramas` | Convierte `.puml` → PDF en `entregables/diagramas/pdf/` |
| `make png` | Exporta los diagramas a PNG en `entregables/diagramas/png/` |
| `make publicar` | Copia el PDF a `entregables/` con el nombre definitivo |
| `make verificar` | Revisa que los diagramas no tengan participantes sueltos |
| `make ver` | Muestra páginas, tamaño y fuentes del PDF |
| `make clean` | Borra `_build` |
| `make distclean` | Borra `_build` y los diagramas generados |

El PDF intermedio queda en `_build/main.pdf` y el entregable en
`entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes
Turísticos y Reservas.pdf`. La carpeta `entregables/` no se versiona.

En VS Code: guarde con `Ctrl+S` y LaTeX Workshop compila solo; el PDF se
abre en una pestaña al costado.

### Si algo falla

1. Lea **el primer error** del log (`_build/main.log`), no el último.
2. La opción `-file-line-error` indica `archivo:línea` exactos.
3. Casi siempre es: una llave sin cerrar, un `%` sin escapar, una ruta mal
   escrita o un comando mal tipeado.

| Error | Causa habitual |
|---|---|
| `Undefined control sequence` | Comando mal escrito o paquete no cargado |
| `Missing $ inserted` | `_`, `^` o `&` fuera de su contexto |
| `Runaway argument` | Falta una `}` |
| `File ... not found` | Ruta o nombre de archivo incorrecto |
| `Emergency stop` | Falta `\end{document}` o una llave |
| `There were undefined references` | Falta compilar otra vez |
| `Package biblatex Warning: Please rerun` | Falta ejecutar biber (`make pdf`) |

### Avisos que puede ignorar

| Aviso | Significado |
|---|---|
| `Overfull \hbox` | Una línea sobresale unos milímetros |
| `Underfull \hbox` | Una línea quedó con espacios amplios |
| `Font shape ... undefined` | Se usó una variante inexistente y se sustituyó |
| `Rerun to get cross-references right` | Normal; la siguiente pasada lo resuelve |

---

## 6. Diagramas UML

```
sistema/diagramas/uml/secuencia/registrar-proyecto.puml
        │  make diagramas
        ▼
entregables/diagramas/pdf/secuencia/registrar-proyecto.pdf
        │  \incluirDiagrama{secuencia/registrar-proyecto}
        ▼
main.pdf
```

- Cree el `.puml` en la carpeta del tipo de diagrama.
- Ejecute `make diagramas`.
- Inclúyalo con `\incluirDiagrama{tipo/nombre}`.
- En diagramas de secuencia agregue `hide footbox` para no repetir los
  participantes al pie.
- Para diagramas que no son UML (DER, arquitectura, mockups) use draw.io,
  exporte a PDF y guárdelo en `sistema/diagramas/otros/`.
- El árbol de problemas del Anexo A está dibujado con **TikZ** en
  `sistema/diagramas/tikz/`. Se compila junto con el documento; no requiere
  `make diagramas`.

---

## 7. Reglas de oro

1. **No formatee a mano**: use los comandos (`\chapter`, `tablaapa`,
   `figuraapa`). El formato es responsabilidad de la clase.
2. **Una idea por párrafo** y una línea en blanco entre párrafos.
3. **Nunca edite `_build/`**: es salida del compilador.
4. **Compile seguido**: es más fácil encontrar el error que uno introdujo.
5. **Cite siempre**: si la idea no es suya, va con `\textcite` o
   `\parencite` y su entrada en el `.bib`.
