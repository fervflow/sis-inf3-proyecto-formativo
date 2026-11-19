"""Actualiza el backlog a partir del tablero kanban.

Uso:

    python3 tablero/exportar.py

El tablero es la fuente de ejecución. Este script actualiza en el backlog
solo las partes que dependen de él:

- la prioridad, el riesgo y la cantidad de tareas de cada historia;
- el desglose de tareas y el responsable de cada historia;
- la tabla de criterios de prioridad;
- los conteos del resumen;
- el CSV del backlog.

El texto de las historias, sus criterios y las estimaciones no se tocan.
"""

import csv
import re
import sys
import textwrap
from collections import Counter

from lector import (
    Error,
    PRIORIDADES,
    RAIZ,
    RIESGOS,
    leer_tablero,
)

DOCUMENTO = RAIZ / 'sistema' / 'historias-usuario' / 'historias-usuario.md'
DATOS = RAIZ / 'sistema' / 'historias-usuario' / 'historias-usuario.csv'

RE_FILA = re.compile(r'^\| (HU-\d{2}) \|')
RE_SECCION = re.compile(
    r'(?ms)^### (HU-\d{2}) · ([^\n]+)\n(.*?)(?=^### |^## |\Z)')


def main():
    try:
        tarjetas, _ = leer_tablero()
        historias = agrupar(tarjetas)
        filas_csv = preparar_csv(historias)
        documento = DOCUMENTO.read_text(encoding='utf-8')
        documento = actualizar_tabla(documento, historias)
        documento = actualizar_desglose(documento, historias)
        documento = actualizar_criterios(documento, historias)
        documento = actualizar_resumen(documento, historias)
        documento = actualizar_intro(documento, historias)
        escribir_csv(filas_csv)
        DOCUMENTO.write_text(documento, encoding='utf-8')
    except Error as error:
        print(f'ERROR: {error}', file=sys.stderr)
        return 1

    total = sum(len(tareas) for tareas in historias.values())
    print(f'Backlog actualizado: {len(historias)} historias, '
          f'{total} tareas.')
    return 0


def agrupar(tarjetas):
    """Agrupa las tarjetas por historia y comprueba la uniformidad."""
    historias = {}
    for tarjeta in tarjetas:
        historias.setdefault(tarjeta['hu'], []).append(tarjeta)

    for hu, tareas in historias.items():
        for campo in ('prioridad', 'riesgo', 'responsable'):
            valores = {tarea[campo] for tarea in tareas}
            if len(valores) != 1:
                raise Error(
                    f'{hu}: las tareas tienen valores distintos de {campo} '
                    f'({", ".join(sorted(valores))}). El backlog guarda un '
                    f'solo valor por historia.')

    return historias


def actualizar_tabla(texto, historias):
    lineas = texto.splitlines()
    total = sum(len(tareas) for tareas in historias.values())
    vistas = set()

    for indice, linea in enumerate(lineas):
        fila = RE_FILA.match(linea)
        if fila:
            partes = linea.split('|')
            if len(partes) != 10:
                continue
            hu = fila.group(1)
            tareas = historias.get(hu)
            if not tareas:
                raise Error(
                    f'{hu}: la historia no tiene tarjetas en el tablero')
            vistas.add(hu)
            partes[5] = f' {tareas[0]["prioridad"]} '
            partes[6] = f' {tareas[0]["riesgo"]} '
            partes[8] = f' {len(tareas)} tareas '
            lineas[indice] = '|'.join(partes)
        elif linea.startswith('| **TOTAL** |'):
            partes = linea.split('|')
            if len(partes) != 10:
                continue
            partes[8] = f' **{total} tareas** '
            lineas[indice] = '|'.join(partes)

    faltan = sorted(set(historias) - vistas)
    if faltan:
        raise Error(
            'el tablero tiene historias que no están en la tabla del '
            f'backlog: {", ".join(faltan)}')

    return '\n'.join(lineas) + '\n'


def actualizar_desglose(texto, historias):
    try:
        inicio = texto.index('## Desglose de tareas')
        fin = texto.index('## Convenciones del backlog', inicio)
    except ValueError:
        raise Error(
            'el backlog no tiene las secciones «Desglose de tareas» y '
            '«Convenciones del backlog»')

    seccion = texto[inicio:fin]

    def reemplazar(bloque):
        hu = bloque.group(1)
        titulo = bloque.group(2)
        tareas = historias.get(hu)
        if not tareas:
            raise Error(
                f'{hu}: la historia no tiene tarjetas en el tablero')

        iniciales = tareas[0]['responsable']
        responsable = 'Programador A' if iniciales == 'EV' else 'Programador B'
        tareas = sorted(
            tareas, key=lambda tarea: int(tarea['id'].rsplit('.', 1)[1]))

        lineas = [
            f'**Responsable:** {responsable} · **{len(tareas)} tareas** · '
            f'**Criterios:** los de {hu}',
            '',
        ]
        for tarea in tareas:
            lineas.append(textwrap.fill(
                f"- **{tarea['id']}** {tarea['descripcion']}",
                width=78,
                subsequent_indent='  ',
            ))

        return f'### {hu} · {titulo}\n\n' + '\n'.join(lineas) + '\n\n'

    nueva = RE_SECCION.sub(reemplazar, seccion)
    return texto[:inicio] + nueva + texto[fin:]


def actualizar_criterios(texto, historias):
    por_prioridad = {prioridad: [] for prioridad in PRIORIDADES}
    for hu, tareas in historias.items():
        por_prioridad[tareas[0]['prioridad']].append(hu)

    lineas = texto.splitlines()
    for indice, linea in enumerate(lineas):
        partes = linea.split('|')
        if len(partes) > 3 and partes[1].strip() in PRIORIDADES:
            prioridad = partes[1].strip()
            partes[3] = ' ' + ', '.join(
                sorted(por_prioridad[prioridad])) + ' '
            lineas[indice] = '|'.join(partes)

    texto = '\n'.join(lineas) + '\n'
    conteos = [len(por_prioridad[prioridad]) for prioridad in PRIORIDADES]
    distribucion = (
        f'La distribución queda en {conteos[0]} historias de prioridad '
        f'alta, {conteos[1]} de prioridad\nmedia y {conteos[2]} de prioridad '
        f'baja.')
    texto = re.sub(
        r'La distribución queda en .*?prioridad\s+baja\.',
        distribucion,
        texto,
        flags=re.S,
    )
    return texto


def actualizar_resumen(texto, historias):
    prioridades = Counter(
        tareas[0]['prioridad'] for tareas in historias.values())
    riesgos = Counter(tareas[0]['riesgo'] for tareas in historias.values())
    total = sum(len(tareas) for tareas in historias.values())

    valores = {
        'Prioridad alta': prioridades['Alta'],
        'Prioridad media': prioridades['Media'],
        'Prioridad baja': prioridades['Baja'],
        'Riesgo alto': riesgos['Alto'],
        'Riesgo medio': riesgos['Medio'],
        'Riesgo bajo': riesgos['Bajo'],
        'Tareas totales': total,
        'Tareas desglosadas': total,
    }
    for clave, valor in valores.items():
        texto = re.sub(
            rf'^\| {re.escape(clave)} \| \d+ \|$',
            f'| {clave} | {valor} |',
            texto,
            flags=re.M,
        )
    return texto


def actualizar_intro(texto, historias):
    total = sum(len(tareas) for tareas in historias.values())
    ev = sum(
        1 for tareas in historias.values()
        for tarea in tareas if tarea['responsable'] == 'EV')
    re_ = total - ev

    texto = re.sub(
        r'Las \d+ tareas se detallan',
        f'Las {total} tareas se detallan',
        texto,
    )
    texto = re.sub(
        r'entre los dos programadores:.*?programador B\.',
        f'entre los dos programadores: {ev} tareas para el programador A y '
        f'{re_} para el\nprogramador B.',
        texto,
        flags=re.S,
    )
    return texto


def preparar_csv(historias):
    with DATOS.open(encoding='utf-8-sig', newline='') as archivo:
        filas = list(csv.reader(archivo, delimiter=';'))

    if not filas:
        raise Error('el CSV del backlog está vacío')

    total = sum(len(tareas) for tareas in historias.values())
    vistas = set()

    for fila in filas[1:]:
        if not fila:
            continue
        if fila[0] == 'TOTAL':
            fila[7] = f'{total} tareas'
            continue

        hu = fila[0]
        tareas = historias.get(hu)
        if not tareas:
            raise Error(f'{hu}: la historia no tiene tarjetas en el tablero')
        vistas.add(hu)
        fila[4] = tareas[0]['prioridad']
        fila[5] = tareas[0]['riesgo']
        fila[7] = f'{len(tareas)} tareas'

    faltan = sorted(set(historias) - vistas)
    if faltan:
        raise Error(
            'el tablero tiene historias que no están en el CSV del backlog: '
            + ', '.join(faltan))

    return filas


def escribir_csv(filas):
    with DATOS.open('w', encoding='utf-8-sig', newline='') as archivo:
        csv.writer(archivo, delimiter=';', lineterminator='\r\n').writerows(
            filas)


if __name__ == '__main__':
    sys.exit(main())
