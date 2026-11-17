#!/usr/bin/env python3
"""Comprueba que las rutas del proyecto sean coherentes.

Dos controles:

1. **Rutas rotas.** Verifica que cada `\\input`, `\\include`,
   `\\addbibresource` e `\\includegraphics` apunte a un archivo que existe, y
   que las carpetas declaradas en `\\graphicspath` existan.

2. **Rutas obsoletas.** Busca referencias a carpetas de una estructura
   anterior que ya no existen. Este control evita el fallo más frecuente
   al reorganizar: mover los archivos pero dejar mentioned la ruta vieja
   en la documentación.

Los registros de `documentacion/registro-cambios/` quedan fuera del
segundo control: describen el estado del proyecto en el momento en que se
escribieron y sus rutas antiguas son correctas como registro histórico.

Uso:

    python3 sistema/verificar-rutas.py
"""

import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent

# --- Rutas del proyecto que ya no existen ------------------------------
# Se buscan cadenas completas y distinguibles, no nombres de carpeta
# sueltos: dentro de un árbol de directorios los nombres de subcarpeta
# (`finales/`, `capitulos/`) son legitimos aunque el proyecto se haya
# reorganizado, porque están bajo `informe/`.
RUTAS_OBSOLETAS = [
    (r'(?<!sistema/)(?<!entregables/)diagramas/(generados|fuentes|png|estilos)/',
     'diagramas/<subcarpeta>/'),
    (r'codigo/base-datos/', 'codigo/base-datos/'),
    (r'tablas/historias-usuario', 'tablas/historias-usuario'),
    (r'imagenes/(logos|capturas)/', 'imagenes/'),
    (r'(?<!informe/)config/(metadatos|portada)', 'config/'),
    (r'(?<!informe/)capitulos/\d\d-', 'capitulos/NN-'),
    (r'(?<!informe/)finales/(glosario|referencias|anexos)\.tex', 'finales/'),
    (r'(?<!informe/)anexos/A-arbol-problemas\.tex', 'anexos/'),
    (r'(?<!informe/)bibliografia/referencias\.bib', 'bibliografia/'),
    (r'(?<!informe/)preliminares/resumen\.tex', 'preliminares/'),
    (r'(?<!documentacion/)GUIA-LATEX\.md', 'GUIA-LATEX.md'),
    (r'(?<!documentacion/)INSTALACION-WINDOWS\.md', 'INSTALACION-WINDOWS.md'),
    (r'(?<!documentacion/)registro-cambios/', 'registro-cambios/'),
]

# --- Rutas LaTeX -------------------------------------------------------
PATRONES_LATEX = [
    (re.compile(r'\\input\{([^}]+)\}'), '.tex'),
    (re.compile(r'\\include\{([^}]+)\}'), '.tex'),
    (re.compile(r'\\addbibresource\{([^}]+)\}'), '.bib'),
    (re.compile(r'\\includegraphics(?:\[[^\]]*\])?\{([^}]+)\}'), None),
]

# --- Archivos donde buscar rutas obsoletas ----------------------------
DOCUMENTOS = ['README.md', 'AGENTS.md',
               'documentacion/GUIA-LATEX.md',
               'documentacion/INSTALACION-WINDOWS.md']


def comprobar_rutas_latex():
    fallos = []
    revisados = 0

    for ruta in sorted(RAIZ.rglob('*.tex')):
        if '_build' in ruta.parts:
            continue
        texto = ruta.read_text(encoding='utf-8')
        for patron, extension in PATRONES_LATEX:
            for destino in patron.findall(texto):
                revisados += 1
                base = RAIZ / destino
                candidatos = [base] if extension is None else [base, base.with_suffix(extension)]
                if not any(c.exists() for c in candidatos):
                    fallos.append(f'{ruta.relative_to(RAIZ)} → {destino}')

    # graphicspath de la clase
    clase = RAIZ / 'si3apa7.cls'
    texto = clase.read_text(encoding='utf-8')
    for bloque in re.findall(r'\\graphicspath\{([^}]+)\}', texto):
        for carpeta in re.findall(r'\{([^}]+)\}', bloque):
            revisados += 1
            if not (RAIZ / carpeta).exists():
                fallos.append(f'si3apa7.cls → \\graphicspath {carpeta}')

    return revisados, fallos


def comprobar_rutas_obsoletas():
    fallos = []
    revisados = 0

    for nombre in DOCUMENTOS:
        ruta = RAIZ / nombre
        if not ruta.exists():
            fallos.append(f'falta el documento {nombre}')
            continue
        for numero, linea in enumerate(ruta.read_text(encoding='utf-8').splitlines(), 1):
            # Las líneas de un árbol de directorios se saltan: el nombre de
            # la subcarpeta depende de su padre, que está en otra línea.
            if re.match(r'^\s*[│├└]', linea):
                continue
            for patron, etiqueta in RUTAS_OBSOLETAS:
                if re.search(patron, linea):
                    revisados += 1
                    fallos.append(f'{nombre}:{numero} → {etiqueta}  «{linea.strip()[:70]}»')

    return revisados, fallos


def main():
    total = 0

    revisados, fallos = comprobar_rutas_latex()
    print(f'Rutas LaTeX revisadas: {revisados}')
    for fallo in fallos:
        print(f'   - rota: {fallo}')
    total += len(fallos)

    revisados, fallos = comprobar_rutas_obsoletas()
    print(f'\nReferencias a rutas antiguas en la documentación: {revisados}')
    for fallo in fallos:
        print(f'   - obsoleta: {fallo}')
    total += len(fallos)

    print(f'\nProblemas encontrados: {total}')
    return 1 if total else 0


if __name__ == '__main__':
    sys.exit(main())
