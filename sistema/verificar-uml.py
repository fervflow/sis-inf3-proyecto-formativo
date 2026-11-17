#!/usr/bin/env python3
"""Verifica los diagramas de secuencia de PlantUML.

Comprueba que cada participante este bien conectado:

- que no se use un participante sin declararlo (PlantUML lo crea sin
  estereotipo y muestra el alias en vez de la etiqueta);
- que todo participante declarado aparezca en algún mensaje;
- que las entidades y las tablas se llamen entre sí, de modo que la línea
  de vida no quede colgando.

Uso:

    python3 diagramas/verificar-uml.py
"""

import re
import sys
from pathlib import Path

DECL = re.compile(
    r'^\s*(actor|entity|database|boundary|control|participant)\s+'
    r'(?:"([^"]+)"|(\w+))(?:\s+as\s+(\w+))?')
MSG = re.compile(r'^\s*([\w]+)\s*(?:-+>?|>>?-)\s*([\w]+)\s*:')

CARPETAS = ['secuencia', 'secuencia-light', 'secuencia-comunes',
            'secuencia-fusionados', 'procesos']

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

    print(f"\n{examinados} archivos revisados. Problemas encontrados: {total}")
    return 1 if total else 0


if __name__ == '__main__':
    sys.exit(main())
