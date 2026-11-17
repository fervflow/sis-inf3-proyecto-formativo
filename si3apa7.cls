%% =====================================================================
%%  si3apa7.cls
%%  Clase de documento para informes de proyecto de grado.
%%  Universidad Privada Domingo Savio (UPDS) - Ingenieria de Sistemas.
%%
%%  Formato base: APA 7.a edicion (adaptacion en espanol)
%%  Ajustes institucionales:
%%    - Papel carta
%%    - Margenes: superior 2,54 cm / inferior 2,54 cm
%%                izquierdo 3 cm / derecho 2 cm
%%    - Fuente Arial 11 pt (o Liberation Sans como sustituto metrico)
%%    - Interlineado 1,5
%%    - Numero de pagina en la esquina inferior derecha
%%
%%  Requiere compilar con XeLaTeX (o LuaLaTeX) y biber.
%% =====================================================================
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{si3apa7}[2026/11/14 v1.0 Informe APA 7 - UPDS]

\RequirePackage{iftex}
\ifPDFTeX
  \ClassError{si3apa7}%
    {Esta clase requiere XeLaTeX o LuaLaTeX}%
    {Compile con: make, latexmk o xelatex main.tex. pdfLaTeX no permite usar Arial real.}%
\fi

\RequirePackage{etoolbox}

%% ---------------------------------------------------------------------
%%  Opciones de la clase
%% ---------------------------------------------------------------------
\newif\ifsi@justificado   \si@justificadofalse
\newif\ifsi@paginacionAPA \si@paginacionAPAfalse
\newif\ifsi@interlineadoDos \si@interlineadoDosfalse
\def\si@fuente{auto}
\def\si@capitulos{romanos}
\def\si@portadaTipo{institucional}

\DeclareOption{alineacion=izquierda}{\si@justificadofalse}
\DeclareOption{alineacion=justificada}{\si@justificadotrue}
\DeclareOption{paginacion=institucional}{\si@paginacionAPAfalse}
\DeclareOption{paginacion=apa}{\si@paginacionAPAtrue}
\DeclareOption{interlineado=1.5}{\si@interlineadoDosfalse}
\DeclareOption{interlineado=2}{\si@interlineadoDostrue}
\DeclareOption{fuente=auto}{\def\si@fuente{auto}}
\DeclareOption{fuente=arial}{\def\si@fuente{arial}}
\DeclareOption{fuente=liberation}{\def\si@fuente{liberation}}
\DeclareOption{capitulos=romanos}{\def\si@capitulos{romanos}}
\DeclareOption{capitulos=arabigos}{\def\si@capitulos{arabigos}}
\DeclareOption{capitulos=sin}{\def\si@capitulos{sin}}
\DeclareOption{portada=institucional}{\def\si@portadaTipo{institucional}}
\DeclareOption{portada=apa}{\def\si@portadaTipo{apa}}
\DeclareOption{portada=ninguna}{\def\si@portadaTipo{ninguna}}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{report}}
\ProcessOptions\relax

\LoadClass[11pt,letterpaper,oneside]{report}

%% Los capitulos de este informe funcionan como secciones: no deben
%% comenzar en una pagina nueva ni mostrar la palabra "Capítulo".
\patchcmd{\chapter}{\cleardoublepage}{\par}{}{}
\patchcmd{\chapter}{\clearpage}{\par}{}{}
%% ---------------------------------------------------------------------
%%  Fuentes: Arial 11 pt con sustituto metrico (Liberation Sans)
%% ---------------------------------------------------------------------
\RequirePackage{fontspec}

\newcommand{\si@cargarLiberation}{%
  \setmainfont{Liberation Sans}%
  \setsansfont{Liberation Sans}%
}
\newcommand{\si@cargarArial}{%
  \IfFontExistsTF{Arial}%
    {\setmainfont{Arial}%
     \setsansfont{Arial}}%
    {\si@cargarLiberation}%
}
\ifdefstring{\si@fuente}{liberation}{\si@cargarLiberation}{%
  \ifdefstring{\si@fuente}{arial}{\si@cargarArial}{%
    \IfFontExistsTF{Arial}{\si@cargarArial}{\si@cargarLiberation}}}

%% Monoespaciada: se intenta primero en Linux y luego en Windows.
%% Liberation Mono y DejaVu Sans Mono son habituales en Arch;
%% Consolas y Courier New vienen incluidas en Windows.
\IfFontExistsTF{Liberation Mono}
  {\setmonofont{Liberation Mono}[Scale=0.9]}
  {\IfFontExistsTF{DejaVu Sans Mono}
    {\setmonofont{DejaVu Sans Mono}[Scale=0.85]}
    {\IfFontExistsTF{Consolas}
      {\setmonofont{Consolas}[Scale=0.9]}
      {\setmonofont{Courier New}[Scale=0.9]}}}

%% ---------------------------------------------------------------------
%%  Geometria de la pagina (carta)
%% ---------------------------------------------------------------------
\RequirePackage[
  letterpaper,
  top=2.54cm, bottom=2.54cm, left=3cm, right=2cm,
  headheight=14.5pt, headsep=0.5cm, footskip=1.0cm
]{geometry}

%% ---------------------------------------------------------------------
%%  Interlineado, sangria y alineacion
%% ---------------------------------------------------------------------
\RequirePackage{setspace}
\ifsi@interlineadoDos \doublespacing \else \onehalfspacing \fi

\setlength{\parindent}{1.27cm}
\setlength{\parskip}{0pt}
\raggedbottom

\RequirePackage{ragged2e}
\setlength{\RaggedRightParindent}{1.27cm}
\ifsi@justificado\else
  \AtBeginDocument{\RaggedRight}
\fi
\setlength{\RaggedRightRightskip}{0pt plus 2em}
\setlength{\emergencystretch}{2em}

\RequirePackage{indentfirst}

%% ---------------------------------------------------------------------
%%  Idioma y comillas
%% ---------------------------------------------------------------------
\RequirePackage[spanish,es-tabla,es-noshorthands]{babel}

%% Numeros romanos de pagina en minusculas normales (babel-spanish los
%% convierte por omision en versalitas, que Arial no posee).
\spanishlcroman

%% APA 7 en espanol usa comillas inglesas (" ") y no angulares (« »).
\RequirePackage[autostyle=false]{csquotes}
\setquotestyle{american}

\addto\captionsspanish{%
  \renewcommand{\contentsname}{Índice}%
  \renewcommand{\listtablename}{Índice de tablas}%
  \renewcommand{\listfigurename}{Índice de figuras}%
  \renewcommand{\bibname}{Referencias}%
  \renewcommand{\chaptername}{Capítulo}%
  \renewcommand{\appendixname}{Anexo}%
  \renewcommand{\tablename}{Tabla}%
  \renewcommand{\figurename}{Figura}%
}

%% ---------------------------------------------------------------------
%%  Encabezado y pie: numero de pagina abajo a la derecha
%% ---------------------------------------------------------------------
\RequirePackage{fancyhdr}
\setlength{\headheight}{14.5pt}
\pagestyle{fancy}
\fancyhf{}
\renewcommand{\headrulewidth}{0pt}
\renewcommand{\footrulewidth}{0pt}
\fancyfoot[R]{\thepage}
\fancypagestyle{plain}{%
  \fancyhf{}%
  \fancyfoot[R]{\thepage}%
  \renewcommand{\headrulewidth}{0pt}%
  \renewcommand{\footrulewidth}{0pt}%
}

%% Pagina horizontal: al rotarse, el numero queda abajo a la derecha.
\fancypagestyle{paisaje}{%
  \fancyhf{}%
  \fancyhead[R]{\thepage}%
  \renewcommand{\headrulewidth}{0pt}%
  \renewcommand{\footrulewidth}{0pt}%
}

%% ---------------------------------------------------------------------
%%  Titulos del informe
%%    \chapter: izquierda, negrita, numerado, sin salto de pagina
%%    \section: izquierda, negrita
%%    \subsection: izquierda, negrita cursiva
%%    \subsubsection: sangrado, negrita, punto
%%    \paragraph: sangrado, negrita cursiva, punto
%% ---------------------------------------------------------------------
\RequirePackage{titlesec}

\ifdefstring{\si@capitulos}{romanos}{\renewcommand{\thechapter}{\Roman{chapter}}}{}
\ifdefstring{\si@capitulos}{arabigos}{\renewcommand{\thechapter}{\arabic{chapter}}}{}

\renewcommand{\thesection}{\arabic{chapter}.\arabic{section}}
\renewcommand{\thesubsection}{\thesection.\arabic{subsection}}
\renewcommand{\thesubsubsection}{\thesubsection.\arabic{subsubsection}}
\setcounter{secnumdepth}{3}

%% APA 7 numera tablas y figuras de forma consecutiva en todo el
%% documento (Tabla 1, Tabla 2...), no por capitulo.
\counterwithout{table}{chapter}
\counterwithout{figure}{chapter}
\renewcommand{\thetable}{\arabic{table}}
\renewcommand{\thefigure}{\arabic{figure}}

\ifdefstring{\si@capitulos}{sin}{%
  \titleformat{\chapter}[hang]{\normalfont\bfseries}{}{0pt}{}[\@afterindenttrue]%
}{%
  \titleformat{\chapter}[hang]{\normalfont\bfseries}{\thechapter.}{0.6em}{}[\@afterindenttrue]%
}
\titlespacing*{\chapter}{0pt}{1.5\baselineskip}{0.5\baselineskip}

\titleformat{\section}[hang]{\normalfont\bfseries}{\thesection.}{0.6em}{}[\@afterindenttrue]
\titlespacing*{\section}{0pt}{1\baselineskip}{0.5\baselineskip}

\titleformat{\subsection}[hang]{\normalfont\bfseries\itshape}{\thesubsection.}{0.6em}{}[\@afterindenttrue]
\titlespacing*{\subsection}{0pt}{1\baselineskip}{0.5\baselineskip}

\titleformat{\subsubsection}[runin]{\normalfont\bfseries}{\thesubsubsection.}{0.6em}{}[.]
\titlespacing*{\subsubsection}{1.27cm}{1\baselineskip}{0.5em}

\titleformat{\paragraph}[runin]{\normalfont\bfseries\itshape}{}{0pt}{}[.]
\titlespacing*{\paragraph}{1.27cm}{1\baselineskip}{0.5em}

%% ---------------------------------------------------------------------
%%  Indices
%% ---------------------------------------------------------------------
\RequirePackage{tocloft}
\renewcommand{\cftchapfont}{\normalfont\bfseries}
\renewcommand{\cftchappagefont}{\normalfont\bfseries}
\renewcommand{\cftchapleader}{\cftdotfill{\cftdotsep}}
\renewcommand{\cftsecleader}{\cftdotfill{\cftdotsep}}
\renewcommand{\cftsubsecleader}{\cftdotfill{\cftdotsep}}
\setlength{\cftbeforechapskip}{8pt}
\setlength{\cftbeforesecskip}{2pt}
\renewcommand{\cftchapaftersnum}{.}
\renewcommand{\cftsecaftersnum}{.}
\renewcommand{\cftsubsecaftersnum}{.}

%% Ancho de la caja del numero en el indice. El valor por omision queda
%% corto para numeros de dos cifras como "10.1.", que se tocan con el
%% titulo de la entrada.
\setlength{\cftsecnumwidth}{2.4em}
\setlength{\cftsubsecnumwidth}{2.8em}

%% Titulos de los indices: centrados, negrita y del mismo tamano que el
%% texto (nivel 1 de APA).
\setlength{\cftbeforetoctitleskip}{0pt}
\setlength{\cftbeforelottitleskip}{0pt}
\setlength{\cftbeforeloftitleskip}{0pt}
\renewcommand{\cfttoctitlefont}{\hfill\normalsize\bfseries}
\renewcommand{\cftaftertoctitle}{\hfill}
\setlength{\cftaftertoctitleskip}{1\baselineskip}
\renewcommand{\cftlottitlefont}{\hfill\normalsize\bfseries}
\renewcommand{\cftafterlottitle}{\hfill}
\setlength{\cftafterlottitleskip}{1\baselineskip}
\renewcommand{\cftloftitlefont}{\hfill\normalsize\bfseries}
\renewcommand{\cftafterloftitle}{\hfill}
\setlength{\cftafterloftitleskip}{1\baselineskip}

%% ---------------------------------------------------------------------
%%  Tablas y figuras con formato APA
%% ---------------------------------------------------------------------
\RequirePackage{graphicx}
\graphicspath{{diagramas/generados/}{diagramas/otros/}{imagenes/}{imagenes/logos/}{imagenes/capturas/}}

\RequirePackage{booktabs}
\RequirePackage{array}
\RequirePackage{multirow}
\RequirePackage{longtable}
\RequirePackage{tabularx}
\RequirePackage{float}
\RequirePackage{xcolor}

\RequirePackage{caption}
\DeclareCaptionFormat{apa}{%
  \singlespacing\bfseries#1\par\normalfont\itshape#3}
\captionsetup{
  format=apa,
  labelsep=none,
  justification=raggedright,
  singlelinecheck=false,
  font=normalsize,
  skip=4pt,
  position=above
}

\setlength{\intextsep}{0.6\baselineskip}
\setlength{\textfloatsep}{1\baselineskip}
\setlength{\floatsep}{1\baselineskip}

%% ---------------------------------------------------------------------
%%  Listas, citas en bloque y utilidades
%% ---------------------------------------------------------------------
\RequirePackage{enumitem}
\setlist{itemsep=0pt,parsep=0pt,topsep=0.5\baselineskip,partopsep=0pt}
\setlist[itemize]{leftmargin=1.27cm,labelsep=0.6em}
\setlist[enumerate]{leftmargin=1.27cm,labelsep=0.6em,label=\arabic*.,ref=\arabic*}

\RequirePackage{changepage}
\RequirePackage{pdflscape}
\RequirePackage{tikz}
\usetikzlibrary{arrows.meta,positioning,calc}

\RequirePackage{amsmath}
\RequirePackage{amssymb}

\RequirePackage{listings}
\renewcommand{\lstlistingname}{Listado}
\renewcommand{\lstlistlistingname}{Índice de listados}
\lstset{
  basicstyle=\ttfamily\small,
  breaklines=true,
  columns=fullflexible,
  keepspaces=true,
  numberbychapter=false,
  showstringspaces=false,
  frame=none,
  numbers=left,
  numberstyle=\tiny\color{gray},
  numbersep=8pt,
  keywordstyle=\bfseries,
  commentstyle=\itshape\color{gray!80!black},
  stringstyle=\color{black},
  xleftmargin=1.5em,
  aboveskip=0.5\baselineskip,
  belowskip=0.5\baselineskip,
  captionpos=t
}

%% ---------------------------------------------------------------------
%%  Hipervinculos
%% ---------------------------------------------------------------------
\RequirePackage[
  unicode,
  colorlinks=true,
  linkcolor=black,
  citecolor=black,
  urlcolor=black,
  filecolor=black,
  bookmarksnumbered=true,
  bookmarksopen=true,
  pdfstartview=FitH
]{hyperref}
\urlstyle{same}
\Urlmuskip=0mu
\AtBeginDocument{\hypersetup{%
  pdftitle={\titulo},%
  pdfauthor={\autor},%
  pdfsubject={\materia\ -- \universidad},%
  pdfkeywords={APA 7, Ingeniería de Sistemas, UPDS}%
}}

%% ---------------------------------------------------------------------
%%  Bibliografia APA 7 en espanol
%% ---------------------------------------------------------------------
\RequirePackage[style=apa,backend=biber,sortlocale=es_ES]{biblatex}
\DeclareLanguageMapping{spanish}{spanish-apa}
\setlength{\bibhang}{1.27cm}
\renewcommand*{\bibfont}{\normalsize}

%% Evita que los puntos de corte de las URL se estiren y dejen huecos.
\biburlbigskip=0mu\relax

%% APA 7 en espanol: se usa "y" entre autores en lugar de "&".
%% Si su docente exige el ampersand original del APA, elimine las dos
%% declaraciones siguientes.
\DeclareDelimFormat[parencite]{finalnamedelim}{\addspace y\addspace}
\DeclareDelimFormat[textcite]{finalnamedelim}{\addspace y\addspace}
\DeclareDelimFormat[bib,biblist]{finalnamedelim}{%
  \ifthenelse{\value{listcount}>\maxprtauth}{}{\addspace y\addspace}}

%% "s. f." con espacio, como en la adaptacion espanola de APA.
\DefineBibliographyStrings{spanish}{%
  nodate = {s\adddot\addspace f\adddot}%
}

%% ---------------------------------------------------------------------
%%  Numeracion y portadas
%% ---------------------------------------------------------------------
\newcommand{\iniciarPreliminares}{%
  \clearpage
  \ifsi@paginacionAPA\else\pagenumbering{roman}\fi
}
\newcommand{\iniciarCuerpo}{%
  \clearpage
  \ifsi@paginacionAPA\else\pagenumbering{arabic}\fi
}

%% A partir de referencias, glosario y anexos los titulos vuelven a ir
%% centrados, como secciones finales del informe.
\newcommand{\iniciarSeccionesFinales}{%
  \titleformat{\chapter}[block]{\normalfont\bfseries\centering}%
    {\thechapter.}{0.6em}{}[\@afterindenttrue]%
  \titlespacing*{\chapter}{0pt}{1.5\baselineskip}{0.5\baselineskip}%
}

%%  Estilo de pagina de la portada: sin numero (institucional) o con
%%  numero (APA, que numera todas las paginas).
\newcommand{\estiloPortada}{%
  \ifsi@paginacionAPA \thispagestyle{fancy}\else\thispagestyle{empty}\fi
}

%%  La portada se define en config/portada.tex
\newcommand{\portadaDocumento}{%
  \ifdefstring{\si@portadaTipo}{apa}{\portadaAPA}{%
  \ifdefstring{\si@portadaTipo}{ninguna}{}{\portadaInstitucional}}%
}

\endinput
