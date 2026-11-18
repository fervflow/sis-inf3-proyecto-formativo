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

Los registros de `docs/changelog/` quedan fuera del
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
    # Estructura vigente: las guías en `docs/`, la bitácora en `docs/changelog/`.
    (r'(?<!docs/)GUIA-LATEX\.md', 'GUIA-LATEX.md'),
    (r'(?<!docs/)INSTALACION-WINDOWS\.md', 'INSTALACION-WINDOWS.md'),
    (r'(?<!docs/)changelog/', 'changelog/'),
    (r'registro-cambios/', 'registro-cambios/'),
    (r'documentacion/', 'documentacion/'),
    # Base de datos y tablero, movidos a la raíz.
    (r'sistema/base-de-datos/', 'bd/'),
    (r'sistema/tablero/', 'tablero/'),
    (r'esquema-temporal\.sql', 'esquema.sql'),
    # La web del sistema, movida de `app/` a `web/`.
    (r'(?<![\w/])app/(README\.md|server/|db/|nuxt\.config|package\.json|vercel\.json)',
     'app/'),
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
               'docs/GUIA-LATEX.md',
               'docs/INSTALACION-WINDOWS.md']


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


def _nombre_de(linea):
    """Extrae el nombre de una entrada del árbol.

    El nombre va después de la ramificación y termina donde empieza la
    descripción, que se separa con dos o más espacios.
    """
    texto = linea.split('── ', 1)[1] if '── ' in linea else linea
    texto = re.sub(r'^[│├└\s]+', '', texto).strip()
    return re.split(r'\s{2,}', texto)[0].strip()


def comprobar_arbol_readme():
    """Comprueba que el árbol del README coincida con las carpetas reales.

    Los árboles duplicados en varios documentos se desincronizan con
    facilidad. Este control detecta el olvido en el momento de mover una
    carpeta, que es cuando ocurre.
    """
    fallos = []
    revisados = 0

    readme = RAIZ / 'README.md'
    if not readme.exists():
        return 0, ['falta el README.md']

    lineas = readme.read_text(encoding='utf-8').splitlines()

    # Se recorren solo las líneas del árbol, que empiezan por el carácter
    # de dibujo de ramas, y se reconstruye la ruta a partir de la
    # sangría. Una entrada puede ocupar dos líneas cuando el nombre es
    # largo; la continuación se reconoce porque no lleva ramificación.
    raiz = []
    for indice, linea in enumerate(lineas):
        if not re.match(r'^[│├└ ]*[├└]── ', linea):
            continue
        nivel = (len(linea) - len(linea.lstrip('│ '))) // 4
        nombre = _nombre_de(linea)

        # Continuación de una entrada demasiado larga.
        siguiente = lineas[indice + 1] if indice + 1 < len(lineas) else ''
        if (siguiente.strip() and '── ' not in siguiente
                and re.match(r'^[│ ]*[│└├]', siguiente)):
            nombre = f'{nombre} {_nombre_de(siguiente)}'.strip()

        raiz = raiz[:nivel]
        if nivel == 0:
            raiz = [nombre]
            continue
        raiz.append(nombre)
        revisados += 1
        if not (RAIZ / '/'.join(raiz)).exists():
            fallos.append(f'el árbol del README menciona {"/".join(raiz)}, '
                          f'que no existe en el disco')

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

    revisados, fallos = comprobar_arbol_readme()
    print(f'\nEntradas del árbol del README comprobadas: {revisados}')
    for fallo in fallos:
        print(f'   - no existe: {fallo}')
    total += len(fallos)

    print(f'\nProblemas encontrados: {total}')
    return 1 if total else 0


if __name__ == '__main__':
    sys.exit(main())
