"""Resumen del tablero kanban.

Uso:

    python3 tablero/resumen.py

No escribe archivos: imprime el estado actual para revisarlo o copiarlo
al informe.
"""

import sys
from collections import Counter

from lector import (
    COLUMNAS,
    Error,
    LIMITES,
    PRIORIDADES,
    leer_tablero,
)


def main():
    try:
        tarjetas, _ = leer_tablero()
    except Error as error:
        print(f'ERROR: {error}', file=sys.stderr)
        return 1

    if not tarjetas:
        print('ERROR: el tablero no tiene tarjetas', file=sys.stderr)
        return 1

    print(f'Total: {len(tarjetas)} tarjetas')

    columnas = Counter(tarjeta['columna'] for tarjeta in tarjetas)
    print('\nPor columna:')
    for columna in COLUMNAS:
        limite = f'/{LIMITES[columna]}' if columna in LIMITES else ''
        print(f'  {columna}: {columnas[columna]}{limite}')

    prioridades = Counter(tarjeta['prioridad'] for tarjeta in tarjetas)
    print('\nPor prioridad:')
    for prioridad in PRIORIDADES:
        print(f'  {prioridad}: {prioridades[prioridad]}')

    responsables = Counter(tarjeta['responsable'] for tarjeta in tarjetas)
    print('\nPor responsable:')
    for iniciales in sorted(responsables):
        print(f'  {iniciales}: {responsables[iniciales]}')

    return 0


if __name__ == '__main__':
    sys.exit(main())
