# Tablero como fuente y exportador al backlog

- **Fecha:** 19 de noviembre de 2026, 19:38 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios; el trabajo no modifica el informe)
- **Alcance:** el tablero kanban pasa a ser la fuente de ejecución. Se
  eliminan el generador y el CSV de planificación; se agregan un validador,
  un resumen y un exportador que actualiza el backlog desde el tablero.

## Antecedente

Una sola tarjeta se armaba con cuatro archivos: el desglose del backlog, el
CSV de historias, el CSV de planificación y el tablero. Cambiar una
prioridad obligaba a tocar tres lugares; agregar una tarea, cinco. La
generación validaba la consistencia, pero convertía el trabajo diario en una
tarea de sincronización.

El tablero es la vista que más se usa y la que conviene editar directamente
con la extensión. El cambio invierte la dirección: el tablero manda y el
backlog se deriva.

## Cambios de formato

No hubo cambios de formato en el informe: no se modificó ningún archivo
LaTeX y el PDF conserva sus 21 páginas.

## Cambios de contenido

### El tablero como fuente

- `tablero/tablero.md` guarda las columnas, el texto, el responsable, la
  prioridad, el riesgo, las fechas y los costos de cada tarjeta.
- Se edita desde la vista kanban: arrastrar, editar en el menú de la tarjeta
  y duplicar una tarjeta parecida para crear una nueva.
- La barra invertida final del encabezado sigue siendo el salto de línea
  duro que separa la descripción.
- La prioridad se mantiene con la etiqueta `#prio-*` y el campo
  `[Prioridad y riesgo:: …]`.

### Scripts

| Archivo | Rol |
|---|---|
| `tablero/lector.py` | Lectura y validación de la estructura |
| `tablero/validar.py` | Comprueba formato, campos, fechas, costos, etiquetas y WIP; no escribe |
| `tablero/resumen.py` | Imprime tarjetas por columna, prioridad y responsable |
| `tablero/exportar.py` | Actualiza las partes derivadas del backlog |

El validador acepta tarjetas con o sin la barra final y avisa si falta. El
WIP se informa como aviso: no bloquea la edición, porque el tablero ya no se
regenera.

### Exportador al backlog

`make tablero-backlog` actualiza:

- prioridad, riesgo y cantidad de tareas de cada historia;
- el desglose de tareas y el responsable de cada historia;
- la tabla de criterios de prioridad y la distribución;
- los conteos del resumen;
- el total de tareas del texto y del CSV;
- el CSV del backlog, conservando BOM y finales de línea.

No modifica el texto de las historias, sus criterios de aceptación ni las
estimaciones. Para exportar se exige:

- que todas las tareas de una historia compartan prioridad, riesgo y
  responsable;
- que no haya historias en el tablero que falten en el backlog, ni al revés;
- que las tarjetas estén en las columnas del tablero, sin archivar.

La exportación es idempotente: dos ejecuciones seguidas dejan los mismos
archivos.

### Comandos

| Comando | Qué hace |
|---|---|
| `make tablero-validar` | Valida el tablero sin escribir |
| `make tablero-resumen` | Muestra el estado actual |
| `make tablero-backlog` | Actualiza el backlog desde el tablero |

Se retiraron `make tablero` y `make tablero-verificar`, y se eliminaron
`tablero/generar.py` y `tablero/planificacion.csv`.

### Documentación

- `tablero/README.md`: flujo de edición, formato de tarjeta, comandos,
  exportador y cómo verlo en VS Code u Obsidian.
- `AGENTS.md`: comandos nuevos y la regla de que el tablero es la fuente.
- `README.md`: la fila de archivos editables.
- `Makefile`: objetivos y ayuda.
- `sistema/historias-usuario/historias-usuario.md`: las convenciones
  distinguen lo que se edita en el backlog de lo que se deriva del tablero.
- `sistema/estimacion/estimacion.md`: la referencia pasó a
  `make tablero-resumen`.

## Archivos modificados

- `tablero/lector.py` (nuevo).
- `tablero/validar.py` (nuevo).
- `tablero/resumen.py` (nuevo).
- `tablero/exportar.py` (nuevo).
- `tablero/generar.py` (eliminado).
- `tablero/planificacion.csv` (eliminado).
- `tablero/README.md`.
- `sistema/historias-usuario/historias-usuario.md`.
- `sistema/estimacion/estimacion.md`.
- `Makefile`, `AGENTS.md`, `README.md`, `.gitignore`.

## Validación

- `make tablero-validar`: 39 tarjetas, columnas 28/4/0/0/7 y WIP respetado.
- `make tablero-resumen`: 17 tarjetas de prioridad alta, 16 media y 6 baja;
  20 de EV y 19 de RE.
- `make tablero-backlog` se ejecutó dos veces seguidas y el `md5` del
  backlog y del CSV no cambió.
- Se probó un cambio real: las dos tarjetas de HU-16 pasaron de Baja a
  Media; el exportador actualizó la tabla, el CSV, el resumen, la tabla de
  criterios y la distribución. Después se revirtió el cambio y se volvió a
  exportar.
- `make verificar` terminó con cero problemas.
- No hay pruebas automatizadas de los scripts; la validación fue manual.

## Pendientes

- Versionar y desplegar los cambios de la web en Vercel.
- Probar la edición de una tarjeta desde la extensión y confirmar que
  conserva la barra final y los campos.
- Corregir el barrido diario: Vercel lo invoca con GET y la ruta es
  `vencer-solicitudes.post.ts`.
- Continuar con las historias del tablero.
