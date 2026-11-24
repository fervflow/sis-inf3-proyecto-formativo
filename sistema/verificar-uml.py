#!/usr/bin/env python3
"""Verifica los diagramas UML de PlantUML del proyecto.

Hay dos grupos de comprobaciones.

**Diagramas de secuencia** (`uml/secuencia/`, `uml/secuencia-light/`,
`uml/secuencia-comunes/`, `uml/secuencia-fusionados/`): se comprueba que
cada participante este bien conectado:

- que no se use un participante sin declararlo (PlantUML lo crea sin
  estereotipo y muestra el alias en vez de la etiqueta);
- que todo participante declarado aparezca en algún mensaje;
- que las entidades y las tablas se llamen entre sí, de modo que la línea
  de vida no quede colgando.

**Diagramas estructurales** (`uml/estructural/`): se comprueba que cada
clase, enumeración u objeto declarado participe en alguna relación y que
ninguna relación use un elemento sin declarar.

Uso:

    python3 sistema/verificar-uml.py
"""

import re
import sys
from pathlib import Path

DECL = re.compile(
    r'^\s*(actor|entity|database|boundary|control|participant)\s+'
    r'(?:"([^"]+)"|(\w+))(?:\s+as\s+(\w+))?')
MSG = re.compile(r'^\s*([\w]+)\s*(?:-+>?|>>?-)\s*([\w]+)\s*:')

CARPETAS = ['secuencia', 'secuencia-light', 'secuencia-comunes',
            'secuencia-fusionados']

# --- Diagramas estructurales -------------------------------------------
# Declaracion: class|enum|object|interface|abstract|usecase|actor|state
# |rectangle|component|node|database|cloud|queue, con etiqueta opcional y
# alias opcional.
DECL_ESTRUCT = re.compile(
    r'^\s*(?:class|enum|object|interface|abstract|usecase|actor|state'
    r'|rectangle|component|node|database|cloud|queue|artifact)\s+'
    r'(?:"[^"]+"\s+as\s+)?(\w+)')
# Relacion: A [multiplicidad] operador [multiplicidad] B [: etiqueta]
# Se admiten <--, --, *--, --> y ..> (dependencia), con o sin calificador
# de direccion: -down->, -left->, .right.> y variantes.
REL_ESTRUCT = re.compile(
    r'^\s*(\w+)\s*(?:"[^"]*"\s*)?'
    r'(?:<--|\*--|-->|\.\.>|--'
    r'|<[ox+]*[-.]+(?:down|up|left|right)?[-.]*>?'
    r'|[-.]+(?:down|up|left|right)?[-.]*>?)'
    r'\s*(?:"[^"]*"\s*)?(\w+)\s*(?::.*)?$')

CARPETAS_ESTRUCT = ['estructural', 'procesos', 'casos-uso']


def analizar(ruta):
    """Devuelve la lista de problemas de un archivo .puml."""
    decls = {}
    fuentes, destinos = set(), set()

    for linea in ruta.read_text(encoding='utf-8').splitlines():
        d = DECL.match(linea)
        if d:
            tipo = d.group(1)
            etiqueta = d.group(2) or d.group(3)
            alias = d.group(4) or etiqueta
            decls[alias] = (tipo, etiqueta)
            continue
        m = MSG.match(linea)
        if m:
            fuentes.add(m.group(1))
            destinos.add(m.group(2))

    fallos = []

    for alias in sorted((fuentes | destinos) - set(decls)):
        fallos.append(f"{alias} se usa pero no esta declarado: aparecera como "
                      f"texto de alias, sin icono ni etiqueta")

    for alias, (tipo, etiqueta) in decls.items():
        if alias not in fuentes and alias not in destinos:
            fallos.append(f"{alias} ({tipo} «{etiqueta}») no aparece en ningun mensaje")
        elif alias not in destinos:
            fallos.append(f"{alias} ({tipo} «{etiqueta}») solo emite: su linea de vida "
                          f"puede mostrar el alias en vez de la etiqueta")
        elif alias not in fuentes:
            fallos.append(f"{alias} ({tipo} «{etiqueta}») solo recibe: nunca responde")

    return fallos


def analizar_estructural(ruta):
    """Devuelve la lista de problemas de un diagrama de clases u objetos."""
    declarados, relacionados = set(), set()

    for linea in ruta.read_text(encoding='utf-8').splitlines():
        texto = linea.strip()
        if not texto or texto.startswith("'") or texto.startswith('//'):
            continue
        # Las aristas ocultas solo guian la disposicion.
        if '-[hidden]->' in texto:
            continue
        d = DECL_ESTRUCT.match(linea)
        if d:
            declarados.add(d.group(1))
            continue
        m = REL_ESTRUCT.match(linea)
        if m:
            relacionados.add(m.group(1))
            relacionados.add(m.group(2))

    fallos = []

    for alias in sorted(relacionados - declarados):
        fallos.append(f"{alias} aparece en una relacion pero no esta declarado")

    for alias in sorted(declarados - relacionados):
        fallos.append(f"{alias} esta declarado pero no participa en ninguna relacion")

    return fallos


def main():
    raiz = Path(__file__).resolve().parent.parent
    total = 0
    examinados = 0

    for carpeta in CARPETAS:
        directorio = raiz / 'sistema/diagramas/uml' / carpeta
        if not directorio.is_dir():
            continue
        for ruta in sorted(directorio.glob('*.puml')):
            examinados += 1
            fallos = analizar(ruta)
            if fallos:
                total += len(fallos)
                print(f"\n{ruta.relative_to(raiz)}")
                for fallo in fallos:
                    print(f"   - {fallo}")

    for carpeta in CARPETAS_ESTRUCT:
        directorio = raiz / 'sistema/diagramas/uml' / carpeta
        if not directorio.is_dir():
            continue
        for ruta in sorted(directorio.glob('*.puml')):
            examinados += 1
            fallos = analizar_estructural(ruta)
            if fallos:
                total += len(fallos)
                print(f"\n{ruta.relative_to(raiz)}")
                for fallo in fallos:
                    print(f"   - {fallo}")

    print(f"\n{examinados} archivos revisados. Problemas encontrados: {total}")
    return 1 if total else 0


if __name__ == '__main__':
    sys.exit(main())
