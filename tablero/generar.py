#!/usr/bin/env python3
"""Genera el tablero kanban a partir del backlog.

El documento `sistema/historias-usuario/historias-usuario.md` es la fuente
del contenido de cada tarjeta (texto, historia y responsable); el CSV es la
fuente de la prioridad, el riesgo y la cantidad de tareas. El tablero solo
guarda el estado: la columna en la que está cada tarjeta.

Los datos de planificación —fechas y costos— viven en
`tablero/planificacion.csv`, una fila por tarea. Así el tablero se puede
regenerar sin perder lo que se haya cargado.

Uso:

    python3 tablero/generar.py            # regenera el tablero
    python3 tablero/generar.py --check    # verifica sin escribir

El código de salida es 0 si todo está en orden y 1 si hay un error de
consistencia o, con `--check`, si el tablero está desactualizado.
"""

import csv
import re
import sys
from datetime import datetime
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
DOCUMENTO = RAIZ / 'sistema' / 'historias-usuario' / 'historias-usuario.md'
DATOS = RAIZ / 'sistema' / 'historias-usuario' / 'historias-usuario.csv'
PLANIFICACION = RAIZ / 'tablero' / 'planificacion.csv'
TABLERO = RAIZ / 'tablero' / 'tablero.md'

COLUMNAS = ['Por hacer', 'En curso', 'En pruebas / QA',
            'Listo para producción', 'Hecho']
INICIAL = 'Por hacer'

# Iniciales de los dos programadores en el tablero. El backlog sigue
# nombrando al programador A y al B; el tablero usa las iniciales.
INICIALES = {'A': 'EV', 'B': 'RE'}

# Etiqueta de prioridad. La extensión la extrae del texto y la muestra como
# insignia; el color se configura en los ajustes del tablero. La prioridad
# también queda escrita, para no depender del color.
ETIQUETA_PRIORIDAD = {
    'Alta': '#prio-alta',
    'Media': '#prio-media',
    'Baja': '#prio-baja',
}

# La fecha de entrega que se usa cuando la planificación no trae una.
ENTREGA_POR_DEFECTO = '26/11/2026'

# Ajustes del tablero. Se conservan los que ya tenga el archivo; estos se
# usan cuando se genera desde cero. `inline-metadata-position: footer`
# muestra los campos `[Clave:: valor]` como etiquetas al pie de la tarjeta.
AJUSTES_POR_DEFECTO = '''%% kanban:settings
{
  "kanban-plugin": "basic",
  "date-format": "DD/MM/YYYY",
  "date-display-format": "DD/MM/YYYY",
  "inline-metadata-position": "footer",
  "move-task-metadata": true,
  "move-tags": true,
  "move-dates": true,
  "show-relative-date": false,
  "tag-action": "kanban",
  "tag-colors": [
    {
      "tagKey": "prio-alta",
      "color": "#a94a52",
      "backgroundColor": "#ffffff"
    },
    {
      "tagKey": "prio-media",
      "color": "#b08a3e",
      "backgroundColor": "#1a1a1a"
    },
    {
      "tagKey": "prio-baja",
      "color": "#4f7d5c",
      "backgroundColor": "#ffffff"
    }
  ]
}
%%'''

# Campos de `planificacion.csv`.
CAMPOS_PLAN = ['tarea', 'inicio', 'fin', 'entrega',
               'costo_inicial', 'costo_pendiente']

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
        if fila[4] not in ETIQUETA_PRIORIDAD:
            raise Error(
                f'{fila[0]}: prioridad desconocida «{fila[4]}». '
                f'Se esperan: {", ".join(ETIQUETA_PRIORIDAD)}')
        datos[fila[0]] = {
            'historia': fila[1],
            'prioridad': fila[4],
            'riesgo': fila[5],
            'tareas': int(cantidad.group(1)),
        }

    if not totales:
        raise Error('el CSV no tiene la fila TOTAL')
    return datos, totales


def leer_planificacion():
    """Lee fechas y costos de cada tarea desde `planificacion.csv`."""
    if not PLANIFICACION.exists():
        raise Error(f'no existe el CSV {PLANIFICACION}')

    with PLANIFICACION.open(encoding='utf-8-sig', newline='') as archivo:
        filas = [fila for fila in csv.reader(archivo, delimiter=';') if fila]

    if not filas:
        raise Error('planificacion.csv está vacío')
    if [campo.strip() for campo in filas[0]] != CAMPOS_PLAN:
        raise Error(
            'planificacion.csv: la cabecera debe ser '
            + ';'.join(CAMPOS_PLAN))

    plan = {}
    for numero_fila, fila in enumerate(filas[1:], 2):
        if len(fila) != len(CAMPOS_PLAN):
            raise Error(
                f'planificacion.csv, línea {numero_fila}: se esperan '
                f'{len(CAMPOS_PLAN)} columnas')
        tarea = fila[0].strip()
        if not re.fullmatch(r'T-HU-\d{2}\.\d+', tarea):
            raise Error(
                f'planificacion.csv, línea {numero_fila}: tarea inválida '
                f'«{tarea}»')
        if tarea in plan:
            raise Error(f'planificacion.csv: tarea repetida {tarea}')

        valores = [campo.strip() for campo in fila[1:]]
        for fecha in valores[:3]:
            if fecha:
                try:
                    datetime.strptime(fecha, '%d/%m/%Y')
                except ValueError:
                    raise Error(
                        f'planificacion.csv, línea {numero_fila}: fecha '
                        f'inválida «{fecha}» (se espera DD/MM/AAAA)')
        for valor in valores[3:]:
            if valor:
                try:
                    costo = float(valor.replace(',', '.'))
                except ValueError:
                    raise Error(
                        f'planificacion.csv, línea {numero_fila}: costo '
                        f'inválido «{valor}»')
                if costo < 0:
                    raise Error(
                        f'planificacion.csv, línea {numero_fila}: el costo '
                        f'no puede ser negativo')

        plan[tarea] = {
            'inicio': valores[0],
            'fin': valores[1],
            'entrega': valores[2] or ENTREGA_POR_DEFECTO,
            'costo_inicial': valores[3],
            'costo_pendiente': valores[4],
        }

    return plan


def fecha_o_guion(valor):
    """Muestra la fecha o un guion cuando todavía no está cargada."""
    return valor or '—'


def moneda(valor):
    """Formatea un costo en bolivianos, o un guion si está vacío."""
    if not valor:
        return '—'
    numero = float(valor.replace(',', '.'))
    texto = f'{numero:,.2f}'
    texto = texto.replace(',', '\x00').replace('.', ',').replace('\x00', '.')
    return f'Bs {texto}'


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
            r'^- (?:\[[ xX]\] )?.*?\*\*(T-HU-\d{2}\.\d+)\*\*', linea)
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


def construir(historias, datos, plan, estado, ajustes=''):
    """Arma el contenido del tablero respetando la columna de cada tarjeta."""
    tareas = [tarea for historia in historias.values()
              for tarea in historia['tareas']]
    ids = {tarea['id'] for tarea in tareas}
    faltan = sorted(ids - set(plan))
    sobran = sorted(set(plan) - ids)
    if faltan:
        raise Error(
            'planificacion.csv: faltan las tareas ' + ', '.join(faltan))
    if sobran:
        raise Error(
            'planificacion.csv: tareas que no están en el backlog: '
            + ', '.join(sobran))

    orden = {hu: indice for indice, hu in enumerate(datos)}
    tarjetas = []
    for hu, historia in historias.items():
        for tarea in historia['tareas']:
            numero = int(tarea['id'].rsplit('.', 1)[1])
            tarjetas.append({
                'id': tarea['id'],
                'texto': re.sub(r'\s+', ' ', tarea['texto']).strip(),
                'hu': hu,
                'responsable': INICIALES[historia['responsable'].split()[-1]],
                'prioridad': datos[hu]['prioridad'],
                'riesgo': datos[hu]['riesgo'],
                'plan': plan[tarea['id']],
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
            etiqueta = ETIQUETA_PRIORIDAD[tarjeta['prioridad']]
            # La barra final es un salto de línea duro de Markdown: separa el
            # encabezado de la descripción en la tarjeta.
            lineas.append(
                f"- [ ] **{tarjeta['id']}** · "
                f"{tarjeta['responsable']} · {tarjeta['hu']} \\")
            lineas.append(f"  {tarjeta['texto']}")
            plan_tarea = tarjeta['plan']
            campos = ' '.join([
                f"[Inicio:: {fecha_o_guion(plan_tarea['inicio'])}]",
                f"[Fin:: {fecha_o_guion(plan_tarea['fin'])}]",
                f"[Entrega:: {plan_tarea['entrega']}]",
                f"[Costo inicial:: {moneda(plan_tarea['costo_inicial'])}]",
                f"[Costo pendiente:: {moneda(plan_tarea['costo_pendiente'])}]",
                f"[Prioridad y riesgo:: "
                f"{tarjeta['prioridad']}/{tarjeta['riesgo']}]",
                etiqueta,
            ])
            lineas.append(f'  {campos}')
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
        plan = leer_planificacion()
        estado, anterior = leer_tablero()
        ajustes = bloques_finales(anterior) or AJUSTES_POR_DEFECTO
        contenido, por_columna, tarjetas = construir(
            historias, datos, plan, estado, ajustes)
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
    summary_a = sum(
        1 for tarjeta in tarjetas
        if tarjeta['responsable'] == INICIALES['A'])
    summary_b = len(tarjetas) - summary_a
    print(f'{len(tarjetas)} tarjetas ({summary_a} de EV, {summary_b} de RE) '
          f'· {resumen}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
