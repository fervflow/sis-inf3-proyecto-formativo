# Tablero kanban de las tareas

Vista de ejecución de las 39 tareas del backlog, en cinco columnas. El
contenido sale de `sistema/historias-usuario/historias-usuario.md` y de
`historias-usuario.csv`; las fechas y los costos, de
`tablero/planificacion.csv`. El tablero solo guarda el estado de cada
tarjeta.

| Columna | Significado | WIP |
|---|---|---|
| `Por hacer` | Cola de entrada | — |
| `En curso` | Se está trabajando en ella | **4** |
| `En pruebas / QA` | Terminada, a la espera de comprobación | **2** |
| `Listo para producción` | Comprobada, pendiente de publicación | **1** |
| `Hecho` | Publicada y con los criterios de su historia cumplidos | — |

## Límites de trabajo en curso

El límite de WIP es el número máximo de tarjetas en una columna. Se cuenta
en tarjetas, no en puntos, y se escribe en el encabezado:

```markdown
## En curso (WIP 4)
```

`make tablero-verificar` falla si una columna supera su límite, y
`make tablero` se niega a escribir mientras eso ocurra.

## Archivos y comandos

| Archivo | Rol |
|---|---|
| `tablero.md` | El tablero; solo se edita para mover tarjetas |
| `planificacion.csv` | Fechas y costos de cada tarea |
| `generar.py` | Regenera el tablero desde el backlog y conserva las columnas |
| `README.md` | Este documento |

```bash
make tablero            # regenera el tablero
make tablero-verificar  # comprueba que esté al día, sin escribir
```

Sin `make`: `python3 tablero/generar.py` y `python3 tablero/generar.py --check`.

`generar.py` comprueba que el documento y el CSV coincidan (historias,
tareas por historia y total). Si algo no cuadra, muestra el detalle y no
toca el tablero.

## Cómo mover una tarjeta

Cada tarjeta ocupa tres líneas: el encabezado, la descripción y la
planificación. Se cortan las tres y se pegan bajo el encabezado de la otra
columna. Al usar la vista de tablero, el complemento mueve la tarjeta
completa.

La columna es el estado; la casilla `[ ]` la escriben los visores y el
generador la deja siempre vacía. No se usa para marcar terminado.

## Propiedades de las tarjetas

- **Responsable:** iniciales del programador. `EV` es el programador A y
  `RE` el programador B.
- **Prioridad:** etiqueta `#prio-alta`, `#prio-media` o `#prio-baja`, y el
  campo `[Prioridad y riesgo:: Alta/Alto]` al final de la planificación. El
  color lo da la extensión según `tag-colors`; la prioridad siempre está
  escrita.

| Prioridad | Etiqueta |
|---|---|
| Alta | `#prio-alta` |
| Media | `#prio-media` |
| Baja | `#prio-baja` |

La segunda línea es la descripción. La tercera contiene los campos con la
sintaxis de campos en línea de Dataview:

```text
- [ ] **T-HU-08.1** · EV · HU-08 \
  Crear el inicio de sesión y validar las credenciales.
  [Inicio:: 12/11/2026] [Fin:: 17/11/2026] [Entrega:: 26/11/2026] [Costo inicial:: —] [Costo pendiente:: —] [Prioridad y riesgo:: Alta/Alto] #prio-alta
```

La barra invertida al final del encabezado es un salto de línea duro de
Markdown: mantiene la descripción en una línea aparte. Si se borra, el
encabezado y la descripción se unen.

La extensión reconoce `[Clave:: valor]` y, con
`inline-metadata-position: footer`, los muestra como etiquetas al pie de
la tarjeta. En el cuerpo quedan el encabezado y la descripción; las
propiedades no se ven como una línea de texto corrida.

Los valores salen de `planificacion.csv`, una fila por tarea:

```csv
tarea;inicio;fin;entrega;costo_inicial;costo_pendiente
T-HU-08.1;12/11/2026;17/11/2026;26/11/2026;0;0
```

- Las fechas van como `DD/MM/AAAA`; se puede dejar vacío.
- La entrega vacía toma `26/11/2026` por defecto.
- Los costos van en bolivianos, sin símbolo; vacío se muestra como `—`.
- Si falta una tarea o sobra una que no está en el backlog, el generador
  falla.

Después de editar la planificación: `make tablero`.

## Cambios manuales

| Qué cambia | Dónde se edita | Después |
|---|---|---|
| Fechas o costos | `planificacion.csv` | `make tablero` |
| Prioridad | `historias-usuario.csv` y la tabla del backlog | `make tablero` |
| Texto de una tarea | `historias-usuario.md` | `make tablero` |
| Agregar o quitar tareas | desglose, conteos, CSV y planificación | `make tablero` |
| Mover una tarjeta | `tablero.md` o la vista de tablero | — |
| Ajustes del tablero | engranaje de la extensión | se conservan |

Reglas para no romper la consistencia:

- En `tablero.md` **solo se mueven tarjetas**. El texto, las fechas, los
  costos y la prioridad se regeneran; si se editan ahí, se pierden.
- `planificacion.csv` tiene una fila por tarea. No se agregan ni se quitan
  filas sin cambiar el backlog: el generador falla si no coinciden.
- Las fechas van como `DD/MM/AAAA`; los costos, con punto decimal. Se puede
  dejar vacío.
- Si se agrega o quita una tarea, hay que ajustar el `N tareas` de su
  historia, la fila TOTAL del CSV y la fila de `planificacion.csv`.
- La prioridad se cambia en el CSV del backlog y en la tabla del documento.
  Los conteos del resumen también se actualizan a mano.
- Los ajustes del tablero se cambian desde el engranaje; el generador
  conserva el bloque `%% kanban:settings %%`.

Al terminar: `make tablero-verificar` y `make verificar`.

### Lo que admite la extensión

El tablero usa el formato de Obsidian Kanban, que Unified Kanban interpreta:

| Sintaxis | Qué hace |
|---|---|
| `#etiqueta` | Insignia con color |
| `@{AAAA-MM-DD}` | Fecha con color según la urgencia |
| `🛫`, `📅`, `⏳`, `✅` | Fechas de Obsidian Tasks: inicio, entrega, programada y hecha |
| `[Clave:: valor]` | Campo con etiqueta; se muestra según `inline-metadata-position` |
| `%% kanban:settings %%` | Ajustes del tablero, en JSON |

Los ajustes actuales muestran los campos al pie
(`inline-metadata-position: footer`) y usan `DD/MM/AAAA` para las fechas.
Si se cambian desde el engranaje del tablero, el generador los conserva.

No hay color de fondo por tarjeta: el fondo es común a todas. Sí se pueden
colorear las etiquetas `#` y las fechas. Por eso la prioridad se marca con
la etiqueta y el texto; al hacer clic en una etiqueta, el tablero filtra
por ella (`tag-action: kanban`). Las líneas de la descripción se unen en un
solo párrafo: Markdown trata los saltos simples como espacios.

## Requisitos para verlo

El archivo es Markdown: cualquier editor lo abre y GitHub o GitLab lo
muestran como cinco listas. Las extensiones solo agregan la vista de
tablero.

### VS Code (recomendado)

1. Instalar **Unified Kanban** (`divisionseven.unified-kanban`), desde el
   Marketplace o Open VSX. Requiere VS Code 1.85 o superior.
2. Abrir `tablero.md` con clic derecho → **Open With…** → **Kanban Board**,
   o ejecutar **Kanban: View as Board**.

### Obsidian (opcional)

1. Instalar Obsidian desde <https://obsidian.md/download> y abrir la
   carpeta del repositorio como bóveda.
2. Ajustes → **Complementos de la comunidad** → desactivar el modo
   restringido.
3. **Examinar** → buscar **Boardwalk** → **Instalar** → **Activar**.
   Boardwalk está mantenido y usa el mismo formato que el Kanban original.
4. Abrir `tablero.md`: el encabezado `kanban-plugin: basic` lo abre como
   tablero.

### Sin extensión

Cualquier editor de texto o la vista del repositorio: las columnas se ven
como listas y las tarjetas como casillas.

## Reglas

- No se edita el texto de una tarjeta en el tablero: se cambia en
  `historias-usuario.md` y se regenera.
- Las fechas y los costos se cambian en `planificacion.csv`, no en el
  tablero.
- No se agregan tareas solo en el tablero: entran por el documento y el
  CSV.
- No se renombran las columnas ni se quita el encabezado
  `kanban-plugin: basic`.
- No se usa la casilla como estado ni se archivan tarjetas desde el
  complemento.
- Cada tarjeta tiene un solo responsable (`A` o `B`), indicado en ella.

## Verificación

`make tablero-verificar` devuelve 0 y «El tablero está al día» cuando el
contenido coincide con el backlog. Devuelve 1 si el documento y el CSV no
cuadran, si falta o sobra una tarjeta, si la planificación no coincide con
las tareas, si una columna supera su WIP o si el texto de una tarjeta quedó
viejo.

## Regla de cierre de historia

Las tareas miden el flujo; los puntos, el alcance. Una historia está
**Hecho** cuando todas sus tareas están en `Hecho`; suma sus puntos una
sola vez, en la ventana en que cierra su última tarea.
