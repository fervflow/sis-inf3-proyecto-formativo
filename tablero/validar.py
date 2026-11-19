"""Valida el tablero kanban sin escribir nada.

Uso:

    python3 tablero/validar.py

El tablero es la fuente de ejecución. Este script comprueba que las
tarjetas tengan el formato, los campos y los valores esperados. No
regenera ni corrige: solo informa.
"""

import sys
from collections import Counter

from lector import (
    Error,
    ETIQUETAS,
    LIMITES,
    PRIORIDADES,
    RIESGOS,
    COLUMNAS,
    es_fecha,
    leer_tablero,
    numero_costo,
)


def main():
    try:
        tarjetas, ajustes = leer_tablero()
    except Error as error:
        print(f'ERROR: {error}', file=sys.stderr)
        return 1

    errores = []
    avisos = []
    vistos = set()

    for tarjeta in tarjetas:
        identificador = tarjeta['id']
        linea = tarjeta['linea']

        if identificador in vistos:
            errores.append(f'{identificador}: tarjeta repetida (línea {linea})')
        vistos.add(identificador)

        if not identificador.startswith(f"T-{tarjeta['hu']}."):
            errores.append(
                f'{identificador}: no pertenece a {tarjeta["hu"]} '
                f'(línea {linea})')

        if tarjeta['prioridad'] not in PRIORIDADES:
            errores.append(
                f'{identificador}: prioridad desconocida '
                f'«{tarjeta["prioridad"]}» (línea {linea})')
        elif tarjeta['etiqueta'] != ETIQUETAS[tarjeta['prioridad']]:
            errores.append(
                f'{identificador}: la etiqueta {tarjeta["etiqueta"]} no '
                f'coincide con la prioridad {tarjeta["prioridad"]} '
                f'(línea {linea})')

        if tarjeta['riesgo'] not in RIESGOS:
            errores.append(
                f'{identificador}: riesgo desconocido '
                f'«{tarjeta["riesgo"]}» (línea {linea})')

        for campo in ('inicio', 'fin', 'entrega'):
            if not es_fecha(tarjeta[campo]):
                errores.append(
                    f'{identificador}: {campo} no es una fecha '
                    f'DD/MM/AAAA (línea {linea})')
        if tarjeta['entrega'] == '—':
            errores.append(
                f'{identificador}: la entrega no puede quedar vacía '
                f'(línea {linea})')

        for campo in ('costo_inicial', 'costo_pendiente'):
            try:
                valor = numero_costo(tarjeta[campo])
            except ValueError as error:
                errores.append(
                    f'{identificador}: {campo} inválido ({error}) '
                    f'(línea {linea})')
                continue
            if valor is not None and valor < 0:
                errores.append(
                    f'{identificador}: {campo} no puede ser negativo '
                    f'(línea {linea})')

        if not tarjeta['barra']:
            avisos.append(
                f'{identificador}: falta la barra final del encabezado; '
                f'la descripción puede unirse a la línea anterior')

    if not tarjetas:
        errores.append('el tablero no tiene tarjetas')

    conteo = Counter(tarjeta['columna'] for tarjeta in tarjetas)
    for columna, limite in LIMITES.items():
        if conteo[columna] > limite:
            avisos.append(
                f'«{columna}» tiene {conteo[columna]} tarjetas y su límite '
                f'es {limite}')

    if 'tag-action' not in ajustes:
        avisos.append(
            'los ajustes no declaran tag-action; el clic en una etiqueta '
            'puede buscar en Obsidian en lugar de filtrar')

    for aviso in avisos:
        print(f'AVISO: {aviso}', file=sys.stderr)
    for error in errores:
        print(f'ERROR: {error}', file=sys.stderr)

    if errores:
        print(f'{len(tarjetas)} tarjetas revisadas; '
              f'{len(errores)} errores', file=sys.stderr)
        return 1

    resumen = ', '.join(
        f'{columna}: {conteo[columna]}'
        + (f'/{LIMITES[columna]}' if columna in LIMITES else '')
        for columna in COLUMNAS)
    print(f'Tablero válido: {len(tarjetas)} tarjetas · {resumen}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
