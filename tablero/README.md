# Tablero kanban

Vista de ejecución de las tareas del backlog, en cinco columnas. El tablero
es la **fuente de ejecución**: las columnas, el texto, el responsable, la
prioridad, las fechas y los costos viven en `tablero.md`. El backlog se
deriva de él cuando hace falta.

| Columna | Significado | WIP |
|---|---|---|
| `Por hacer` | Cola de entrada | — |
| `En curso` | Se está trabajando en ella | **4** |
| `En pruebas / QA` | Terminada, a la espera de comprobación | **2** |
| `Listo para producción` | Comprobada, pendiente de publicación | **1** |
| `Hecho` | Publicada y con los criterios de su historia cumplidos | — |

El WIP se informa como aviso; no bloquea la edición.

## Editar el tablero

1. Abrir `tablero.md` con **Open With… → Kanban Board**.
2. Mover una tarjeta: arrastrarla entre columnas.
3. Editar: menú de la tarjeta → **Edit**.
4. Crear una tarjeta: **Duplicate** sobre una parecida y cambiar el
   identificador, el texto y los campos. Es la vía más rápida.
5. Al terminar: `make tablero-validar` (opcional, no escribe).

No hace falta editar el backlog para el trabajo diario. Su prosa y sus
criterios de aceptación se siguen editando allí; la tabla, el desglose y el
resumen se actualizan con `make tablero-backlog`.

## Formato de una tarjeta

```text
- [ ] **T-HU-08.1** · EV · HU-08 \
  Crear el inicio de sesión y validar las credenciales.
  [Inicio:: 12/11/2026] [Fin:: 17/11/2026] [Entrega:: 26/11/2026] [Costo inicial:: —] [Costo pendiente:: —] [Prioridad y riesgo:: Alta/Alto] #prio-alta
```

- **Encabezado:** identificador, iniciales (`EV` o `RE`) y historia. La
  barra invertida final es un salto de línea duro de Markdown: separa la
  descripción. Si se borra, el encabezado y la descripción se unen.
- **Descripción:** una línea.
- **Campos:** sintaxis de Dataview. La extensión los muestra como etiquetas
  al pie (`inline-metadata-position: footer`).
- **Prioridad:** `#prio-alta`, `#prio-media` o `#prio-baja`, con colores en
  `tag-colors`. Al hacer clic en la etiqueta, el tablero filtra por ella.

El fondo de la tarjeta es común a todas: la extensión no permite un color
de fondo por tarjeta. Solo se colorean etiquetas y fechas.

## Comandos

| Comando | Qué hace |
|---|---|
| `make tablero-validar` | Comprueba columnas, identificadores, campos, fechas, costos y etiquetas. No escribe. |
| `make tablero-resumen` | Imprime tarjetas por columna, prioridad y responsable. |
| `make tablero-backlog` | Actualiza en el backlog la tabla, el desglose, el criterio de prioridades y el resumen; también el CSV. |

Sin `make`: `python3 tablero/validar.py`, `python3 tablero/resumen.py` y
`python3 tablero/exportar.py`.

## Archivos

| Archivo | Rol |
|---|---|
| `tablero.md` | El tablero y la fuente de los datos |
| `lector.py` | Lectura y validación de la estructura |
| `validar.py` | Comprobación sin escritura |
| `resumen.py` | Conteos para revisar o copiar al informe |
| `exportar.py` | Actualiza las partes derivadas del backlog |
| `README.md` | Este documento |

## Exportar al backlog

`make tablero-backlog` actualiza:

- prioridad, riesgo y cantidad de tareas de cada historia;
- el desglose de tareas y el responsable de cada historia;
- la tabla de criterios de prioridad y la distribución;
- los conteos del resumen y los totales del texto;
- el CSV del backlog.

No toca el texto de las historias, sus criterios ni las estimaciones. El
tablero debe cumplir dos reglas para que la exportación funcione:

- todas las tareas de una historia comparten prioridad, riesgo y
  responsable, porque el backlog guarda un solo valor por historia;
- no hay historias en el tablero que falten en el backlog, ni al revés.

## Ver el tablero

### VS Code

1. Instalar **Unified Kanban** (`divisionseven.unified-kanban`).
2. Abrir `tablero.md` con clic derecho → **Open With… → Kanban Board**.

### Obsidian

1. Abrir la carpeta del repositorio como bóveda.
2. Instalar **Boardwalk** desde los complementos de la comunidad.
3. Abrir `tablero.md`: el encabezado `kanban-plugin: basic` lo reconoce.

### Sin extensión

Cualquier editor muestra las columnas como listas y las tarjetas como
casillas. Las etiquetas y los campos se ven como texto.

## Reglas

- El tablero es la fuente: no se regenera desde el backlog.
- Un cambio de tarea se hace en el tablero. El backlog se actualiza con
  `make tablero-backlog`, no a mano en las partes derivadas.
- Una tarjeta nueva se crea duplicando otra y cambiando el identificador.
- El identificador sigue el formato `T-HU-NN.n` y pertenece a su historia.
- No se archivan tarjetas: `Hecho` es el histórico y el exportador lo
  necesita.
- Los ajustes del tablero se cambian desde el engranaje y se guardan en
  `%% kanban:settings %%`.
