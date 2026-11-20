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
TABLERO   := tablero
BD        := bd
WEB       := web

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

.PHONY: all pdf diagramas png publicar verificar tablero-validar tablero-resumen tablero-backlog estimacion estimacion-scrum web-install web-dev web-build web-preview web-check db-crear neon-env ver clean distclean ayuda

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

# --- Hoja de resumen de la estimacion ----------------------------------
#  Documento autonomo de dos paginas, para presentar. No depende del
#  informe: se compila aparte para que un error aqui no bloquee la
#  compilacion del PDF final.
PDF_ESTIMACION := $(ENTREGAS)/Estimacion de esfuerzo y costo.pdf

estimacion:
	@mkdir -p $(BUILD)/estimacion
	xelatex -interaction=nonstopmode -halt-on-error \
		-output-directory=$(BUILD)/estimacion \
		sistema/estimacion/resumen-estimacion.tex
	@mkdir -p "$(ENTREGAS)"
	@cp "$(BUILD)/estimacion/resumen-estimacion.pdf" "$(PDF_ESTIMACION)"
	@echo ">> Hoja de resumen: $(PDF_ESTIMACION)"

# --- Hoja de resumen de la estimacion con metodologia scrum ------------
PDF_ESTIMACION_SCRUM := $(ENTREGAS)/Estimacion Scrum de esfuerzo y costo.pdf

estimacion-scrum:
	@mkdir -p $(BUILD)/estimacion/scrum
	xelatex -interaction=nonstopmode -halt-on-error \
		-output-directory=$(BUILD)/estimacion/scrum \
		sistema/estimacion/scrum/resumen-scrum.tex
	@mkdir -p "$(ENTREGAS)"
	@cp "$(BUILD)/estimacion/scrum/resumen-scrum.pdf" "$(PDF_ESTIMACION_SCRUM)"
	@echo ">> Hoja de resumen (Scrum): $(PDF_ESTIMACION_SCRUM)"

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

# --- Tablero kanban ----------------------------------------------------
#  El tablero es la fuente de ejecución. El backlog y el resumen se
#  derivan de él; la validación no escribe nada.
tablero-validar:
	python3 $(TABLERO)/validar.py

tablero-resumen:
	python3 $(TABLERO)/resumen.py

tablero-backlog:
	python3 $(TABLERO)/exportar.py

# --- La web del sistema -------------------------------------------------
#  Atajos sobre el espacio de trabajo de npm. La base de datos se crea
#  con el script de `bd/`, que es la fuente canonica del esquema.
web-install:
	npm install

web-dev:
	npm run dev --workspace $(WEB)

web-build:
	npm run build --workspace $(WEB)

web-preview:
	npm run preview --workspace $(WEB)

web-check:
	npm run db:check --workspace $(WEB)

# Crea el esquema en la base. Las migraciones van por la conexión directa
# (DATABASE_URL_UNPOOLED): el pooler de Neon no admite operaciones de sesión.
db-crear:
	@if [ -z "$$DATABASE_URL" ] && [ -z "$$DATABASE_URL_UNPOOLED" ] && [ -f .env.local ]; then \
	  set -a; . ./.env.local; set +a; \
	fi; \
	url="$$DATABASE_URL_UNPOOLED"; \
	if [ -z "$$url" ]; then url="$$DATABASE_URL"; fi; \
	if [ -z "$$url" ]; then echo "Falta DATABASE_URL o DATABASE_URL_UNPOOLED. Revise .env.local o expórtelas."; exit 1; fi; \
	psql "$$url" -v ON_ERROR_STOP=1 -f $(BD)/esquema.sql

# Aplica en orden las actualizaciones de una base que ya existe. Los
# scripts son idempotentes, pero conviene revisar los avisos.
db-actualizar:
	@if [ -z "$$DATABASE_URL" ] && [ -z "$$DATABASE_URL_UNPOOLED" ] && [ -f .env.local ]; then \
	  set -a; . ./.env.local; set +a; \
	fi; \
	url="$$DATABASE_URL_UNPOOLED"; \
	if [ -z "$$url" ]; then url="$$DATABASE_URL"; fi; \
	if [ -z "$$url" ]; then echo "Falta DATABASE_URL o DATABASE_URL_UNPOOLED. Revise .env.local o expórtelas."; exit 1; fi; \
	for archivo in $(BD)/actualizaciones/*.sql; do \
	  echo ">> $$archivo"; \
	  psql "$$url" -v ON_ERROR_STOP=1 -f "$$archivo" || exit 1; \
	done

# Pruebas SQL de las reglas de paquetes y salidas. Terminan con ROLLBACK.
db-probar:
	@if [ -z "$$DATABASE_URL" ] && [ -f .env.local ]; then \
	  set -a; . ./.env.local; set +a; \
	fi; \
	url="$$DATABASE_URL"; \
	if [ -z "$$url" ]; then echo "Falta DATABASE_URL. Revise .env.local o expórtela."; exit 1; fi; \
	psql "$$url" -v ON_ERROR_STOP=1 -f $(BD)/pruebas/reglas-paquetes.sql

# Trae de Neon las variables de la rama a .env.local (en la raíz).
neon-env:
	neon env pull

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
	@echo "make tablero-validar  comprueba el formato del tablero kanban"
	@echo "make tablero-resumen  imprime el estado del tablero"
	@echo "make tablero-backlog  actualiza el backlog desde el tablero"
	@echo "make estimacion compila la hoja de resumen de la estimacion"
	@echo "make estimacion-scrum  compila la hoja de resumen con metodologia scrum"
	@echo "make web-install  instala las dependencias de la web"
	@echo "make web-dev      levanta la web en modo desarrollo"
	@echo "make web-build    compila la web para produccion"
	@echo "make db-crear     crea el esquema en la base de DATABASE_URL"
	@echo "make neon-env    trae de Neon las variables de la rama"
	@echo "make ver        inspecciona el PDF (paginas, tamano, fuentes)"
	@echo "make clean      borra archivos auxiliares"
	@echo "make distclean  borra auxiliares, diagramas y PNG"
