# latexmkrc
# Configuracion de compilacion: XeLaTeX + biber, salida en _build/
$pdf_mode   = 5;                      # 5 = xelatex
$xelatex    = 'xelatex -interaction=nonstopmode -file-line-error -synctex=1 %O %S';
$bibtex_use = 2;                      # ejecuta biber cuando sea necesario
$out_dir    = '_build';
$max_repeat = 5;
$clean_ext  = 'bbl run.xml synctex.gz';
