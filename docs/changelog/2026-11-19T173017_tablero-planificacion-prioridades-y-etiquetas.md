# Tablero: planificación, prioridades y etiquetas

- **Fecha:** 19 de noviembre de 2026, 17:30 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios; el trabajo no modifica el informe)
- **Alcance:** el tablero pasa de mostrar solo texto y columnas a tarjetas con
  responsable, prioridad, fechas y costos. Se reequilibran las prioridades
  del backlog y se reemplaza el emoji de prioridad por etiquetas de la
  extensión Unified Kanban.

## Antecedente

El tablero tenía 39 tarjetas en una sola línea, sin fechas ni costos, y el
reparto figuraba como «A» y «B». La extensión instalada, Unified Kanban
0.7.4, admite campos en línea, etiquetas y ajustes por tablero. El trabajo
aprovecha esas capacidades para que la planificación se lea sin abrir el
archivo Markdown y para que las tarjetas se puedan filtrar.

## Cambios de formato

No hubo cambios de formato en el informe: no se modificó ningún archivo
LaTeX y el PDF conserva sus 21 páginas.

## Cambios de contenido

### Responsables y prioridades

- El programador A aparece como **EV** y el B como **RE**. El reparto queda
  en 20 tarjetas de EV y 19 de RE.
- Las prioridades se reequilibraron con un criterio explícito: 7 altas, 7
  medias y 3 bajas.
  - **Alta:** sostiene el flujo mínimo de reservas (HU-08, HU-01, HU-02,
    HU-03, HU-06, HU-17 y HU-14).
  - **Media:** necesaria para operar, pero resoluble después o de forma
    manual en el MVP (HU-15, HU-04, HU-10, HU-12, HU-07, HU-09 y HU-13).
  - **Baja:** complementaria o post-MVP (HU-05, HU-11 y HU-16).
- El criterio quedó escrito en el backlog, junto con los conteos del
  resumen.

### Planificación de las tarjetas

- `tablero/planificacion.csv` (nuevo) guarda una fila por tarea: inicio, fin,
  entrega, costo inicial y costo pendiente.
- La entrega vacía toma `26/11/2026` por defecto.
- Las fechas que se habían cargado a mano en el tablero se trasladaron al
  CSV antes de regenerar: HU-08 del 12/11 al 17/11, y HU-01 y HU-04 del
  12/11 al 18/11.
- `tablero/generar.py` valida el CSV: tareas faltantes o sobrantes, fechas
  inválidas, costos negativos y filas repetidas cortan la generación.

### Presentación de la tarjeta

Cada tarjeta tiene tres líneas:

```text
- [ ] **T-HU-08.1** · EV · HU-08 \
  Crear el inicio de sesión y validar las credenciales.
  [Inicio:: 12/11/2026] [Fin:: 17/11/2026] [Entrega:: 26/11/2026] [Costo inicial:: —] [Costo pendiente:: —] [Prioridad y riesgo:: Alta/Alto] #prio-alta
```

- La barra invertida final del encabezado es un salto de línea duro de
  Markdown. Sin ella, Markdown une el encabezado y la descripción.
- Los campos usan la sintaxis de campos en línea de Dataview
  (`[Clave:: valor]`), que la extensión muestra como etiquetas al pie.
- El tablero define `inline-metadata-position: footer`, `tag-action:
  kanban` y el formato de fecha `DD/MM/AAAA`.
- La prioridad ya no usa emoji: se marca con `#prio-alta`, `#prio-media` o
  `#prio-baja`. Los colores quedaron configurados en `tag-colors` (rojo
  apagado, ámbar y verde). Al hacer clic en la etiqueta, el tablero filtra
  por esa prioridad.
- No existe color de fondo por tarjeta: el fondo es común. La extensión
  solo permite colorear etiquetas, fechas y el indicador de prioridad
  nativo.

### Extensión investigada

Se documentó lo que admite el formato, además de lo usado:

| Sintaxis | Resultado |
|---|---|
| `#etiqueta` | Insignia con color |
| `@{AAAA-MM-DD}` | Fecha con color de urgencia |
| `🛫`, `📅`, `⏳`, `✅` | Fechas de Obsidian Tasks |
| `[Clave:: valor]` | Campo con etiqueta |
| `%% kanban:settings %%` | Ajustes por tablero |

### Español neutro

`web/app/i18n/locales/es.ts` pasa a español latino neutro. Se cambiaron las
formas voseantes que quedaban («Escribí», «Consultá», «Elegí», «Revisá»)
por «Escribe», «Consulta», «Elige» y «Revisa».

### Documentación

- `tablero/README.md`: propiedades, cómo mover las tres líneas, lo que
  admite la extensión y el procedimiento para cambios manuales.
- `sistema/historias-usuario/historias-usuario.md`: nota de equivalencia
  A/EV y B/RE, criterio de prioridades y conteos actualizados.
- `README.md` y `AGENTS.md`: la planificación como fuente de fechas y
  costos.

## Archivos modificados

- `tablero/generar.py`.
- `tablero/planificacion.csv` (nuevo).
- `tablero/tablero.md` (regenerado).
- `tablero/README.md`.
- `sistema/historias-usuario/historias-usuario.md`.
- `sistema/historias-usuario/historias-usuario.csv`.
- `web/app/i18n/locales/es.ts`.
- `README.md`, `AGENTS.md`.

## Validación

- `make tablero-verificar`: 39 tarjetas, tablero al día, WIP respetado.
- `make verificar`: cero problemas.
- El JSON de `%% kanban:settings %%` se analizó y tiene los tres colores de
  prioridad.
- Las 39 tarjetas tienen salto duro, campo de prioridad y etiqueta
  `#prio-*`; la etiqueta coincide con la prioridad escrita.
- `npm run typecheck --workspace web` sin errores después del cambio de
  textos.
- El CSV del backlog conserva el BOM y los finales de línea originales.

## Pendientes

- Versionar y desplegar los cambios de la web en Vercel.
- Cargar los costos iniciales y pendientes de cada tarea; hoy están vacíos.
- Corregir el barrido diario: Vercel lo invoca con GET y la ruta es
  `vencer-solicitudes.post.ts`.
- Continuar con las historias del tablero.
- Evaluar si el salto duro con `\` se conserva al editar tarjetas desde la
  extensión; si no, reemplazarlo por otra separación estable.
