#!/usr/bin/env python3
"""Genera el tablero kanban a partir del backlog.

El documento `sistema/historias-usuario/historias-usuario.md` es la fuente
del contenido de cada tarjeta (texto, historia y responsable); el CSV es la
fuente de la prioridad, el riesgo y la cantidad de tareas. El tablero solo
guarda el estado: la columna en la que está cada tarjeta.

Uso:

    python3 tablero/generar.py            # regenera el tablero
    python3 tablero/generar.py --check    # verifica sin escribir

El código de salida es 0 si todo está en orden y 1 si hay un error de
consistencia o, con `--check`, si el tablero está desactualizado.
"""

import csv
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
DOCUMENTO = RAIZ / 'sistema' / 'historias-usuario' / 'historias-usuario.md'
DATOS = RAIZ / 'sistema' / 'historias-usuario' / 'historias-usuario.csv'
TABLERO = RAIZ / 'tablero' / 'tablero.md'

COLUMNAS = ['Por hacer', 'En curso', 'En pruebas / QA',
            'Listo para producción', 'Hecho']
INICIAL = 'Por hacer'

# Límites de trabajo en curso por columna. None significa que la columna
# no tiene tope: es la cola de entrada o el histórico, donde acumular no
# estorba. El límite va escrito en el encabezado de la columna, para que
# se lea sin necesidad de ninguna extensión.
LIMITES = {
    'En curso': 4,
    'En pruebas / QA': 2,
    'Listo para producción': 1,
}

# Sufijo opcional del encabezado: «## En curso (WIP 4)».
RE_LIMITE = re.compile(r'\s*\(WIP\s+(\d+)\)\s*$')


class Error(Exception):
    """Error de consistencia del backlog o del tablero."""


def leer_documento():
    """Extrae las historias y sus tareas del desglose del documento."""
    if not DOCUMENTO.exists():
        raise Error(f'no existe el documento {DOCUMENTO}')

    texto = DOCUMENTO.read_text(encoding='utf-8')
    try:
        seccion = texto.split('## Desglose de tareas', 1)[1]
        seccion = seccion.split('## Convenciones del backlog', 1)[0]
    except IndexError:
        raise Error('no se encontró la sección «Desglose de tareas»')

    partes = re.split(r'^### (HU-\d{2}) · (.+)$', seccion, flags=re.M)
    if len(partes) < 4:
        raise Error('la sección «Desglose de tareas» no tiene historias')

    historias = {}
    for indice in range(1, len(partes), 3):
        hu = partes[indice]
        titulo = partes[indice + 1].strip()
        cuerpo = partes[indice + 2]

        encabezado = re.search(
            r'\*\*Responsable:\*\*\s*(Programador [AB])\s*·\s*'
            r'\*\*(\d+) tareas\*\*',
            cuerpo)
        if not encabezado:
            raise Error(f'{hu}: falta la línea de responsable y tareas')
        responsable = encabezado.group(1)
        declaradas = int(encabezado.group(2))

        tareas = []
        actual = None
        for linea in cuerpo.splitlines():
            nueva = re.match(r'^- \*\*(T-HU-\d{2}\.\d+)\*\*\s*(.*)$', linea)
            if nueva:
                if actual:
                    tareas.append(actual)
                actual = {'id': nueva.group(1), 'texto': nueva.group(2).strip()}
            elif actual is not None and linea[:1].isspace() and linea.strip():
                actual['texto'] = f"{actual['texto']} {linea.strip()}"
            elif actual is not None and not linea.strip():
                tareas.append(actual)
                actual = None
        if actual:
            tareas.append(actual)

        if not tareas:
            raise Error(f'{hu}: no se encontraron tareas')
        if declaradas != len(tareas):
            raise Error(
                f'{hu}: la historia declara {declaradas} tareas y el '
                f'desglose tiene {len(tareas)}')

        historias[hu] = {
            'titulo': titulo,
            'responsable': responsable,
            'tareas': tareas,
        }

    return historias


def leer_datos():
    """Lee prioridad, riesgo y cantidad de tareas de cada historia."""
    if not DATOS.exists():
        raise Error(f'no existe el CSV {DATOS}')

    with DATOS.open(encoding='utf-8-sig', newline='') as archivo:
        filas = [fila for fila in csv.reader(archivo, delimiter=';') if fila]

    if not filas:
        raise Error('el CSV está vacío')

    datos = {}
    totales = None
    for fila in filas[1:]:
        if fila[0] == 'TOTAL':
            totales = fila
            continue
        if len(fila) < 8:
            raise Error(f'fila incompleta en el CSV: {";".join(fila)}')

        cantidad = re.match(r'(\d+)', fila[7])
        if not cantidad:
            raise Error(f'{fila[0]}: la cantidad de tareas no es un número')
        datos[fila[0]] = {
            'historia': fila[1],
            'prioridad': fila[4],
            'riesgo': fila[5],
            'tareas': int(cantidad.group(1)),
        }

    if not totales:
        raise Error('el CSV no tiene la fila TOTAL')
    return datos, totales


def comprobar(historias, datos, totales):
    """Comprueba que el documento, el CSV y los totales coincidan."""
    if set(historias) != set(datos):
        faltan = sorted(set(datos) - set(historias))
        sobran = sorted(set(historias) - set(datos))
        detalle = []
        if faltan:
            detalle.append(f'sin desglose: {", ".join(faltan)}')
        if sobran:
            detalle.append(f'sin fila en el CSV: {", ".join(sobran)}')
        raise Error('las historias no coinciden (' + '; '.join(detalle) + ')')

    for hu, historia in historias.items():
        if historia['responsable'].split()[-1] not in ('A', 'B'):
            raise Error(f'{hu}: responsable desconocido')
        if datos[hu]['tareas'] != len(historia['tareas']):
            raise Error(
                f'{hu}: el CSV declara {datos[hu]["tareas"]} tareas y el '
                f'desglose tiene {len(historia["tareas"])}')

    vistas = set()
    for hu, historia in historias.items():
        for tarea in historia['tareas']:
            if not tarea['id'].startswith(f'T-{hu}.'):
                raise Error(
                    f'{hu}: la tarea {tarea["id"]} no pertenece a la historia')
            if tarea['id'] in vistas:
                raise Error(f'tarea repetida: {tarea["id"]}')
            vistas.add(tarea['id'])
            if not tarea['texto']:
                raise Error(f'{tarea["id"]}: la tarea no tiene texto')

    tareas_csv = sum(fila['tareas'] for fila in datos.values())
    if totales[7].split()[0] != str(tareas_csv):
        raise Error(
            f'la fila TOTAL declara {totales[7]} y la suma es {tareas_csv}')


def leer_tablero():
    """Devuelve la columna de cada tarjeta y el texto actual del tablero."""
    if not TABLERO.exists():
        return {}, ''

    texto = TABLERO.read_text(encoding='utf-8')
    columnas = {}
    actual = None
    for numero, linea in enumerate(texto.splitlines(), 1):
        encabezado = re.match(r'^##\s+(.+?)\s*$', linea)
        if encabezado:
            # Se descarta el sufijo del límite: «En curso (WIP 4)» es la
            # columna «En curso».
            actual = RE_LIMITE.sub('', encabezado.group(1)).strip()
            continue

        tarjeta = re.match(
            r'^- (?:\[[ xX]\] )?\*\*(T-HU-\d{2}\.\d+)\*\*', linea)
        if not tarjeta:
            continue
        if actual not in COLUMNAS:
            raise Error(
                f'tablero.md, línea {numero}: la tarjeta {tarjeta.group(1)} '
                f'está en una columna desconocida ({actual or "sin columna"}). '
                f'Las columnas son: {", ".join(COLUMNAS)}')
        if tarjeta.group(1) in columnas:
            raise Error(
                f'tablero.md, línea {numero}: tarjeta repetida '
                f'{tarjeta.group(1)}')
        columnas[tarjeta.group(1)] = actual

    return columnas, texto


def bloques_finales(texto):
    """Conserva los bloques de comentarios que agregan los visores.

    Boardwalk escribe `%% kanban:settings` y `%% boardwalk-history`; el
    complemento original, solo `%% kanban:settings`. Se conservan tal cual
    para no perder los ajustes visuales ni el historial de movimientos.
    """
    inicio = re.search(
        r'^%%\s*(?:kanban:settings|boardwalk-history)', texto, re.M)
    if not inicio:
        return ''
    bloque = texto[inicio.start():].strip()
    return bloque if bloque.endswith('%%') else ''


def construir(historias, datos, estado, ajustes=''):
    """Arma el contenido del tablero respetando la columna de cada tarjeta."""
    orden = {hu: indice for indice, hu in enumerate(datos)}
    tarjetas = []
    for hu, historia in historias.items():
        for tarea in historia['tareas']:
            numero = int(tarea['id'].rsplit('.', 1)[1])
            tarjetas.append({
                'id': tarea['id'],
                'texto': re.sub(r'\s+', ' ', tarea['texto']).strip(),
                'hu': hu,
                'responsable': historia['responsable'].split()[-1],
                'prioridad': datos[hu]['prioridad'],
                'riesgo': datos[hu]['riesgo'],
                'orden': (orden[hu], numero),
            })
    tarjetas.sort(key=lambda tarjeta: tarjeta['orden'])

    por_columna = {columna: [] for columna in COLUMNAS}
    for tarjeta in tarjetas:
        por_columna[estado.get(tarjeta['id'], INICIAL)].append(tarjeta)

    lineas = ['---', '', 'kanban-plugin: basic', '', '---', '']
    for columna in COLUMNAS:
        limite = LIMITES.get(columna)
        sufijo = f' (WIP {limite})' if limite else ''
        lineas.append(f'## {columna}{sufijo}')
        lineas.append('')
        for tarjeta in por_columna[columna]:
            lineas.append(
                f"- [ ] **{tarjeta['id']}** {tarjeta['texto']} · "
                f"{tarjeta['hu']} · {tarjeta['responsable']} · "
                f"{tarjeta['prioridad']}/{tarjeta['riesgo']}")
        if por_columna[columna]:
            lineas.append('')

    texto = '\n'.join(lineas).rstrip() + '\n'
    if ajustes:
        texto += '\n' + ajustes + '\n'

    return texto, por_columna, tarjetas


def comprobar_wip(por_columna):
    """Comprueba que ninguna columna supere su límite de trabajo en curso.

    Devuelve la lista de columnas que lo superan, con el detalle.
    """
    fallos = []
    for columna, limite in LIMITES.items():
        tarjetas = len(por_columna.get(columna, []))
        if tarjetas > limite:
            fallos.append(
                f'«{columna}» tiene {tarjetas} tarjetas y su límite es {limite}: '
                f'sobran {tarjetas - limite}. Termine o mueva tarjetas antes '
                f'de tomar trabajo nuevo')
    return fallos


def main():
    verificar = '--check' in sys.argv[1:]
    desconocidos = [arg for arg in sys.argv[1:] if arg != '--check']
    if desconocidos:
        print(f'ERROR: opción desconocida: {desconocidos[0]}', file=sys.stderr)
        return 2

    try:
        historias = leer_documento()
        datos, totales = leer_datos()
        comprobar(historias, datos, totales)
        estado, anterior = leer_tablero()
        contenido, por_columna, tarjetas = construir(
            historias, datos, estado, bloques_finales(anterior))
    except Error as error:
        print(f'ERROR: {error}', file=sys.stderr)
        return 1

    existentes = set(estado)
    conocidas = {tarjeta['id'] for tarjeta in tarjetas}
    for sobrante in sorted(existentes - conocidas):
        print(f'AVISO: {sobrante} ya no existe en el backlog y se descarta',
              file=sys.stderr)

    excedidos = comprobar_wip(por_columna)
    for exceso in excedidos:
        print(f'ERROR: {exceso}', file=sys.stderr)

    if verificar:
        actual = TABLERO.read_text(encoding='utf-8') if TABLERO.exists() else ''
        if actual != contenido:
            print('ERROR: el tablero está desactualizado. '
                  'Ejecutá «make tablero».', file=sys.stderr)
            return 1
        print('El tablero está al día.')
    elif excedidos:
        print('ERROR: el tablero no se escribe porque hay columnas que '
              'superan su límite de WIP.', file=sys.stderr)
        return 1
    else:
        TABLERO.parent.mkdir(parents=True, exist_ok=True)
        TABLERO.write_bytes(contenido.encode('utf-8'))
        print(f'Tablero generado: {TABLERO.relative_to(RAIZ)}')

    resumen = ', '.join(
        f'{columna}: {len(por_columna[columna])}'
        + (f'/{LIMITES[columna]}' if columna in LIMITES else '')
        for columna in COLUMNAS)
    a = sum(1 for tarjeta in tarjetas if tarjeta['responsable'] == 'A')
    b = len(tarjetas) - a
    print(f'{len(tarjetas)} tarjetas ({a} de A, {b} de B) · {resumen}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
