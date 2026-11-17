# =====================================================================
#  Makefile del informe
#  Objetivos:
#    make            -> genera diagramas, compila y publica el PDF
#    make pdf        -> solo compila el PDF
#    make diagramas  -> convierte todos los .puml a PDF
#    make png        -> exporta todos los diagramas a PNG
#    make ver        -> muestra paginas, tamano y fuentes del PDF
#    make clean      -> borra auxiliares
#    make distclean  -> borra tambien diagramas generados y PNG
# =====================================================================

MAIN    := main
BUILD   := _build
PLANTUML := plantuml
PUML_CONFIG := sistema/diagramas/estilos/tema-apa.puml

# Carpetas del proyecto.
INFORME   := informe
SISTEMA   := sistema
ENTREGAS  := entregables
DIAGRAMAS := $(SISTEMA)/diagramas

# Entregable oficial. El PDF se copia aqui con su nombre definitivo y
# queda versionado; los diagramas van en una subcarpeta ignorada.
PDF_ENTREGA := $(ENTREGAS)/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf

PUML_SRC := $(shell find $(DIAGRAMAS)/uml -name '*.puml' 2>/dev/null)
PUML_PDF := $(patsubst $(DIAGRAMAS)/uml/%.puml,$(ENTREGAS)/diagramas/pdf/%.pdf,$(PUML_SRC))

# Exportacion a PNG: material de revision, no se versiona.
PNG_DIR  := $(ENTREGAS)/diagramas/png
PNG_DPI  ?= 300
# Los SVG de PlantUML ya traen el tamano en pixeles a 96 DPI, de modo que
# la resolucion final se obtiene con un factor de escala sobre esa base.
PNG_ZOOM := $(shell awk "BEGIN{printf \"%.4f\", $(PNG_DPI)/96}")
PUML_PNG := $(patsubst $(DIAGRAMAS)/uml/%.puml,$(PNG_DIR)/%.png,$(PUML_SRC))
TIKZ_TXT := $(DIAGRAMAS)/tikz/arbol-problemas.tex
TIKZ_PNG := $(PNG_DIR)/arbol-problemas.png

LATEXMK := $(shell command -v latexmk 2>/dev/null)
SVG2PDF := $(shell command -v rsvg-convert 2>/dev/null)
PDFTOPPM := $(shell command -v pdftoppm 2>/dev/null)

.PHONY: all pdf diagramas png publicar verificar ver clean distclean ayuda

all: pdf

# --- Compilacion ------------------------------------------------------
ifeq ($(LATEXMK),)
pdf: diagramas
	@echo ">> latexmk no esta instalado; se usa xelatex + biber directamente."
	@mkdir -p $(BUILD)
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(BUILD) $(MAIN).tex
	biber $(BUILD)/$(MAIN)
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(BUILD) $(MAIN).tex
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(BUILD) $(MAIN).tex
	@$(MAKE) --no-print-directory publicar
else
pdf: diagramas
	$(LATEXMK) -xelatex $(MAIN).tex
	@$(MAKE) --no-print-directory publicar
endif

# --- Publicacion del entregable ----------------------------------------
#  Copia el PDF compilado a entregables/ con el nombre definitivo.
publicar:
	@mkdir -p "$(ENTREGAS)"
	@cp "$(BUILD)/$(MAIN).pdf" "$(PDF_ENTREGA)"
	@echo ">> Entregable: $(PDF_ENTREGA)"

# --- Diagramas UML ----------------------------------------------------
diagramas: $(PUML_PDF)

ifeq ($(SVG2PDF),)
# Sin rsvg-convert: PlantUML exporta PDF directamente.
$(ENTREGAS)/diagramas/pdf/%.pdf: $(DIAGRAMAS)/uml/%.puml $(PUML_CONFIG)
	@mkdir -p "$(dir $@)"
	$(PLANTUML) -tpdf -charset UTF-8 -config "$(PUML_CONFIG)" -o "$(CURDIR)/$(dir $@)" "$<"
	@echo ">> Generado: $@"
else
# Con rsvg-convert: se exporta SVG y se convierte a PDF para que las
# fuentes queden embebidas (requisito habitual de impresión y archivo).
$(ENTREGAS)/diagramas/pdf/%.pdf: $(DIAGRAMAS)/uml/%.puml $(PUML_CONFIG)
	@mkdir -p "$(dir $@)"
	$(PLANTUML) -tsvg -charset UTF-8 -config "$(PUML_CONFIG)" -o "$(CURDIR)/$(dir $@)" "$<"
	$(SVG2PDF) -f pdf -o "$@" "$(CURDIR)/$(dir $@)/$(notdir $(basename $<)).svg"
	@rm -f "$(CURDIR)/$(dir $@)/$(notdir $(basename $<)).svg"
	@echo ">> Generado: $@"
endif

# --- Exportacion a PNG -------------------------------------------------
#  Copia rasterizada de cada diagrama para revision rapida, presentaciones
#  y documentacion. Es material derivado: no se versiona.
png: $(PUML_PNG) $(TIKZ_PNG)
	@echo ">> PNG generados en $(PNG_DIR) ($(PNG_DPI) DPI, fondo blanco). No se versionan."

ifeq ($(SVG2PDF),)
# Sin rsvg-convert: PlantUML rasteriza directamente.
$(PNG_DIR)/%.png: $(DIAGRAMAS)/uml/%.puml $(PUML_CONFIG)
	@mkdir -p "$(dir $@)"
	$(PLANTUML) -tpng -charset UTF-8 -config "$(PUML_CONFIG)" -o "$(CURDIR)/$(dir $@)" "$<"
	@echo ">> Generado: $@"
else
# Con rsvg-convert: se exporta SVG y se rasteriza, de modo que la imagen
# tenga las mismas fuentes que el PDF. El fondo se fija en blanco opaco.
$(PNG_DIR)/%.png: $(DIAGRAMAS)/uml/%.puml $(PUML_CONFIG)
	@mkdir -p "$(dir $@)"
	$(PLANTUML) -tsvg -charset UTF-8 -config "$(PUML_CONFIG)" -o "$(CURDIR)/$(dir $@)" "$<"
	$(SVG2PDF) -f png -b white -z $(PNG_ZOOM) -o "$@" "$(CURDIR)/$(dir $@)/$(notdir $(basename $<)).svg"
	@rm -f "$(CURDIR)/$(dir $@)/$(notdir $(basename $<)).svg"
	@echo ">> Generado: $@"
endif

# El arbol de problemas es TikZ, no PlantUML: se compila aparte.
$(TIKZ_PNG): $(TIKZ_TXT)
	@mkdir -p "$(dir $@)" "$(BUILD)/tikz"
	@printf '%s\n' \
	  '\documentclass[tikz,border=6pt]{standalone}' \
	  '\usepackage{tikz}' \
	  '\usetikzlibrary{arrows.meta,positioning,calc}' \
	  '\begin{document}' \
	  '\input{$(CURDIR)/$(TIKZ_TXT)}' \
	  '\end{document}' > "$(BUILD)/tikz/arbol.tex"
	@xelatex -interaction=nonstopmode -halt-on-error -output-directory="$(BUILD)/tikz" "$(BUILD)/tikz/arbol.tex" >/dev/null
	@if [ -z "$(PDFTOPPM)" ]; then \
	  echo "AVISO: pdftoppm no esta instalado; se omite el arbol de problemas."; \
	else \
	  $(PDFTOPPM) -png -r $(PNG_DPI) -singlefile "$(BUILD)/tikz/arbol.pdf" "$(dir $@)arbol-problemas"; \
	  echo ">> Generado: $@"; \
	fi

# --- Verificacion de los diagramas -------------------------------------
#  Revisa que cada participante de los diagramas de secuencia este declarado
#  y bien conectado. Una entidad usada sin declarar aparece en la imagen
#  como texto de alias, en lugar del icono con su estereotipo.
verificar:
	@python3 $(SISTEMA)/verificar-uml.py
	@python3 $(SISTEMA)/verificar-rutas.py

# --- Utilidades -------------------------------------------------------
ver: pdf
	pdfinfo $(BUILD)/$(MAIN).pdf | grep -E "Pages|Page size|File size"
	@echo "--- Fuentes embebidas ---"
	pdffonts $(BUILD)/$(MAIN).pdf

clean:
	@rm -rf $(BUILD)
	@rm -f *.aux *.log *.out *.toc *.lof *.lot *.bbl *.bcf *.blg *.run.xml *.fls *.fdb_latexmk
	@echo ">> Archivos auxiliares eliminados."

distclean: clean
	@rm -rf $(ENTREGAS)/diagramas
	@echo ">> Diagramas generados y PNG eliminados."

ayuda:
	@echo "make            genera diagramas, compila y publica el PDF"
	@echo "make pdf        compila sin regenerar diagramas"
	@echo "make diagramas  convierte .puml -> PDF en $(ENTREGAS)/diagramas/pdf"
	@echo "make png        exporta los diagramas a PNG en $(ENTREGAS)/diagramas/png"
	@echo "make publicar   copia el PDF a $(ENTREGAS)/ con el nombre definitivo"
	@echo "make verificar  revisa los diagramas y las rutas del proyecto"
	@echo "make ver        inspecciona el PDF (paginas, tamano, fuentes)"
	@echo "make clean      borra archivos auxiliares"
	@echo "make distclean  borra auxiliares, diagramas y PNG"
