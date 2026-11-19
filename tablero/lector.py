"""Lectura del tablero kanban.

El tablero es la fuente de ejecución: las columnas, el texto, el
responsable, la prioridad, las fechas y los costos viven en
`tablero/tablero.md`. Este módulo lo lee y valida la estructura; no
escribe nada.

Lo usan `validar.py`, `resumen.py` y `exportar.py`.
"""

import json
import re
from datetime import datetime
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
TABLERO = RAIZ / 'tablero' / 'tablero.md'

COLUMNAS = ['Por hacer', 'En curso', 'En pruebas / QA',
            'Listo para producción', 'Hecho']

LIMITES = {
    'En curso': 4,
    'En pruebas / QA': 2,
    'Listo para producción': 1,
}

INICIALES = ('EV', 'RE')
PRIORIDADES = ('Alta', 'Media', 'Baja')
RIESGOS = ('Alto', 'Medio', 'Bajo')

ETIQUETAS = {
    'Alta': '#prio-alta',
    'Media': '#prio-media',
    'Baja': '#prio-baja',
}

CAMPOS = [
    'Inicio',
    'Fin',
    'Entrega',
    'Costo inicial',
    'Costo pendiente',
    'Prioridad y riesgo',
]

RE_ENCABEZADO = re.compile(
    r'^- \[[ x]\] \*\*(T-HU-\d{2}\.\d+)\*\*\s*·\s*(EV|RE)\s*·\s*'
    r'(HU-\d{2})(?:\s*\\)?\s*$')
RE_COLUMNA = re.compile(r'^##\s+(.+?)\s*$')
RE_WIP = re.compile(r'\s*\(WIP\s+\d+\)\s*$')
RE_TARJETA = re.compile(r'^- \[[ x]\] ')
RE_CAMPO = re.compile(r'\[([^\[\]]+?)::\s*([^\[\]]*?)\]')


class Error(Exception):
    """Problema de estructura del tablero."""


def leer_tablero(ruta=None):
    """Devuelve `(tarjetas, ajustes)` a partir del tablero."""
    ruta = Path(ruta) if ruta else TABLERO
    if not ruta.exists():
        raise Error(f'no existe el tablero {ruta}')

    texto = ruta.read_text(encoding='utf-8')
    return _leer_tarjetas(texto), leer_ajustes(texto)


def _leer_tarjetas(texto):
    lineas = texto.splitlines()
    tarjetas = []
    columna = None
    indice = 0

    while indice < len(lineas):
        linea = lineas[indice]
        encabezado = RE_COLUMNA.match(linea)
        if encabezado:
            columna = RE_WIP.sub('', encabezado.group(1)).strip()
            indice += 1
            continue

        if RE_TARJETA.match(linea):
            inicio = indice
            bloque = [linea]
            indice += 1
            while indice < len(lineas):
                siguiente = lineas[indice]
                if RE_TARJETA.match(siguiente) or RE_COLUMNA.match(siguiente):
                    break
                if siguiente.strip().startswith('%%'):
                    break
                if siguiente.strip():
                    bloque.append(siguiente)
                indice += 1
            tarjetas.append(_parsear(bloque, columna, inicio + 1))
            continue

        indice += 1

    return tarjetas


def _parsear(bloque, columna, linea):
    primera = bloque[0]
    encabezado = RE_ENCABEZADO.match(primera)
    if not encabezado:
        raise Error(
            f'tablero.md, línea {linea}: el encabezado de la tarjeta no '
            f'sigue el formato «**T-HU-NN.n** · EV|RE · HU-NN \\». '
            f'Se leyó: {primera}')

    id_tarea, iniciales, hu = encabezado.groups()
    barra = bool(re.search(r'\\\s*$', primera))

    indice_meta = None
    for posicion, texto in enumerate(bloque[1:], 1):
        if '[Inicio::' in texto:
            indice_meta = posicion
            break
    if indice_meta is None:
        raise Error(
            f'tablero.md, línea {linea}: la tarjeta {id_tarea} no tiene la '
            f'línea de campos «[Inicio:: …]»')

    campos = {
        clave.strip(): valor.strip()
        for clave, valor in RE_CAMPO.findall(bloque[indice_meta])
    }
    faltan = [campo for campo in CAMPOS if campo not in campos]
    if faltan:
        raise Error(
            f'tablero.md, línea {linea}: a {id_tarea} le faltan los campos '
            f'{", ".join(faltan)}')

    descripcion = ' '.join(
        texto.strip()
        for posicion, texto in enumerate(bloque[1:], 1)
        if posicion != indice_meta
    ).strip()
    if not descripcion:
        raise Error(
            f'tablero.md, línea {linea}: la tarjeta {id_tarea} no tiene '
            f'descripción')

    prioridad_riesgo = campos['Prioridad y riesgo']
    if '/' not in prioridad_riesgo:
        raise Error(
            f'tablero.md, línea {linea}: el campo «Prioridad y riesgo» de '
            f'{id_tarea} debe tener la forma «Alta/Alto»')
    prioridad, riesgo = [parte.strip() for parte in
                         prioridad_riesgo.split('/', 1)]

    etiqueta = re.search(r'#prio-(alta|media|baja)\b', bloque[indice_meta])
    etiqueta = f'#prio-{etiqueta.group(1)}' if etiqueta else None

    if columna not in COLUMNAS:
        raise Error(
            f'tablero.md, línea {linea}: la tarjeta {id_tarea} está en una '
            f'columna desconocida ({columna or "sin columna"}). Las '
            f'columnas son: {", ".join(COLUMNAS)}')

    return {
        'id': id_tarea,
        'hu': hu,
        'responsable': iniciales,
        'columna': columna,
        'linea': linea,
        'descripcion': descripcion,
        'inicio': campos['Inicio'],
        'fin': campos['Fin'],
        'entrega': campos['Entrega'],
        'costo_inicial': campos['Costo inicial'],
        'costo_pendiente': campos['Costo pendiente'],
        'prioridad': prioridad,
        'riesgo': riesgo,
        'etiqueta': etiqueta,
        'barra': barra,
    }


def leer_ajustes(texto):
    """Lee el bloque `%% kanban:settings %%`."""
    encontrado = re.search(
        r'%%\s*kanban:settings\s*\n([\s\S]*?)\n%%', texto)
    if not encontrado:
        return {}
    try:
        ajustes = json.loads(encontrado.group(1))
    except json.JSONDecodeError as error:
        raise Error(
            f'tablero.md: los ajustes no son JSON válido ({error.msg})')
    if not isinstance(ajustes, dict):
        raise Error('tablero.md: los ajustes deben ser un objeto JSON')
    return ajustes


def es_fecha(valor):
    """Fecha `DD/MM/AAAA` o el guion de vacío."""
    if valor == '—':
        return True
    if not re.fullmatch(r'\d{2}/\d{2}/\d{4}', valor):
        return False
    try:
        datetime.strptime(valor, '%d/%m/%Y')
    except ValueError:
        return False
    return True


def numero_costo(valor):
    """Número de un costo «Bs 1.500,50», o `None` si está vacío."""
    if valor == '—':
        return None
    if not valor.startswith('Bs '):
        raise ValueError('el costo debe empezar con «Bs »')
    return float(valor[3:].replace('.', '').replace(',', '.'))


def contar_por(tarjetas, campo):
    """Cuenta tarjetas por el valor de un campo."""
    conteo = {}
    for tarjeta in tarjetas:
        valor = tarjeta[campo]
        conteo[valor] = conteo.get(valor, 0) + 1
    return conteo
