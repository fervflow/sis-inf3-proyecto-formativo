# =====================================================================
#  Makefile del informe
#  Objetivos:
#    make            -> genera diagramas y compila el PDF
#    make pdf        -> solo compila el PDF
#    make diagramas  -> convierte todos los .puml a PDF
#    make ver        -> muestra paginas, tamano y fuentes del PDF
#    make clean      -> borra archivos auxiliares
#    make distclean  -> borra tambien diagramas generados
# =====================================================================

MAIN    := main
BUILD   := _build
PLANTUML := plantuml
PUML_CONFIG := diagramas/estilos/tema-apa.puml

PUML_SRC := $(shell find diagramas/fuentes -name '*.puml' 2>/dev/null)
PUML_PDF := $(patsubst diagramas/fuentes/uml/%.puml,diagramas/generados/%.pdf,$(PUML_SRC))

LATEXMK := $(shell command -v latexmk 2>/dev/null)
SVG2PDF := $(shell command -v rsvg-convert 2>/dev/null)

.PHONY: all pdf diagramas ver clean distclean ayuda

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
	@echo ">> PDF generado en $(BUILD)/$(MAIN).pdf"
else
pdf: diagramas
	$(LATEXMK) -xelatex $(MAIN).tex
	@echo ">> PDF generado en $(BUILD)/$(MAIN).pdf"
endif

# --- Diagramas UML ----------------------------------------------------
diagramas: $(PUML_PDF)

ifeq ($(SVG2PDF),)
# Sin rsvg-convert: PlantUML exporta PDF directamente.
diagramas/generados/%.pdf: diagramas/fuentes/uml/%.puml $(PUML_CONFIG)
	@mkdir -p "$(dir $@)"
	$(PLANTUML) -tpdf -charset UTF-8 -config "$(PUML_CONFIG)" -o "$(CURDIR)/$(dir $@)" "$<"
	@echo ">> Generado: $@"
else
# Con rsvg-convert: se exporta SVG y se convierte a PDF para que las
# fuentes queden embebidas (requisito habitual de impresión y archivo).
diagramas/generados/%.pdf: diagramas/fuentes/uml/%.puml $(PUML_CONFIG)
	@mkdir -p "$(dir $@)"
	$(PLANTUML) -tsvg -charset UTF-8 -config "$(PUML_CONFIG)" -o "$(CURDIR)/$(dir $@)" "$<"
	$(SVG2PDF) -f pdf -o "$@" "$(CURDIR)/$(dir $@)/$(notdir $(basename $<)).svg"
	@rm -f "$(CURDIR)/$(dir $@)/$(notdir $(basename $<)).svg"
	@echo ">> Generado: $@"
endif

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
	@rm -f diagramas/generados/*.pdf
	@rm -f diagramas/generados/*/*.pdf
	@echo ">> Diagramas generados eliminados."

ayuda:
	@echo "make            genera diagramas y compila el informe"
	@echo "make pdf        compila sin regenerar diagramas"
	@echo "make diagramas  convierte .puml -> PDF"
	@echo "make ver        inspecciona el PDF (paginas, tamano, fuentes)"
	@echo "make clean      borra archivos auxiliares"
	@echo "make distclean  borra auxiliares y diagramas generados"
