# Estimación de costos

Estimación del esfuerzo y del costo de construir el sistema, con el método
ágil del proyecto: puntos de historia como unidad de tamaño, el tablero
Kanban como forma de medir el flujo y una tarifa por mes-persona para
convertir el esfuerzo en dinero.

**No forma parte del informe compilado**: es documentación de trabajo.

## Archivos

| Archivo | Rol |
|---|---|
| `estimacion.md` | La estimación: unidades, datos de partida, ritmo medido, proyección, costo y riesgos |
| `resumen-estimacion.tex` | La hoja de resumen de dos páginas, para presentar |
| `scrum/resumen-scrum.tex` | La hoja de una página con la misma estimación bajo metodología Scrum |
| `README.md` | Este documento |

## Comandos

```bash
make estimacion         # compila la hoja de resumen (dos páginas)
make estimacion-scrum   # compila la hoja de resumen con metodología Scrum (una página)
```

Las dos hojas se compilan aparte, con XeLaTeX y sin depender del informe: son
documentos autónomos que salen en `entregables/`. Se compilan por separado
para que un error en ellas no bloquee la compilación del PDF final.

Equivalentes en Windows: `.\build.ps1 -Estimacion` y
`.\build.ps1 -EstimacionScrum`.

El detalle de los cálculos está en `estimacion.md`; las hojas solo los resumen
en tablas.

## Las dos hojas

| Hoja | Contenido |
|---|---|
| `estimacion.md` + su resumen | La estimación con el método que usa el proyecto: puntos de historia y tablero Kanban con límites de trabajo en curso. |
| `scrum/resumen-scrum.tex` | La misma estimación bajo metodología Scrum: sprint, compromiso, velocidad y revisión. Sirve para comparar las dos alternativas. |

**El costo y el esfuerzo no cambian entre las dos**: 188 horas-persona, 1,18
mes-persona y 5.875 Bs. Lo que cambia es el mecanismo de control —límites de
trabajo en curso y *pull* frente a sprint y compromiso— y la métrica que se
mide: *throughput* y tiempo de ciclo frente a velocidad y *burndown*.

## De dónde salen los datos

| Dato | Origen |
|---|---|
| Historias, puntos, tareas, responsable | `sistema/historias-usuario/historias-usuario.md` |
| Prioridad y riesgo | `sistema/historias-usuario/historias-usuario.csv` |
| Qué hay terminado y en qué columna | `sistema/tablero/tablero.md` |
| Límites de WIP y reglas del flujo | `sistema/tablero/README.md` |

**La estimación no tiene cifras propias**: todo lo que cuenta sale de esos
archivos. Si el backlog o el tablero cambian, la estimación se recalcula.

## Las seis unidades

| Unidad | Valor |
|---|---|
| Dedicación diaria | 4 h por persona y día hábil |
| Días hábiles por mes | 20 |
| Día-persona | 4 h |
| Mes-persona | 160 h (tiempo completo) |
| Tarifa | 5.000 Bs por mes-persona de tiempo completo (31,25 Bs/h) |
| Tamaño relativo | 1 punto de historia (escala Fibonacci del backlog) |

## Reglas

- **No se edita a mano un resultado.** Si cambia el tablero, se recalcula la
  proyección y se actualiza `estimacion.md`.
- **La tarifa es una entrada, no un resultado.** Está en `estimacion.md`,
  junto a las demás unidades, y cambiar solo esa línea recalcula el costo.
- **El escenario es único.** Se estimates con el ritmo medido, sin rango.
  Cuando haya historial suficiente, se documentará el por qué del cambio.
- **No se anexa al informe** sin una instrucción explícita del autor del
  proyecto, igual que el backlog.

## Cómo se recalcula

```text
Esfuerzo restante = puntos pendientes × (horas-persona gastadas ÷ puntos cerrados)
Costo total       = (horas-persona gastadas + esfuerzo restante) ÷ 160 × 5.000 Bs
```

Las tres magnitudes de la primera línea se leen del tablero: tareas en
`Hecho`, puntos de las historias cerradas y horas-persona acumuladas desde
el 12 de noviembre de 2026.
