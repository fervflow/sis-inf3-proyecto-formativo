# Estimación de costos

Estimación del esfuerzo y del costo de construir el sistema con el método
ágil del proyecto: puntos de historia como tamaño, tablero kanban para medir
el flujo y una tarifa por mes-persona.

**No forma parte del informe compilado**: es documentación de trabajo.

## Archivos

| Archivo | Rol |
|---|---|
| `estimacion.md` | Unidades, datos, ritmo, proyección, costo y riesgos |
| `resumen-estimacion.tex` | Hoja de resumen de dos páginas |
| `scrum/resumen-scrum.tex` | Hoja de una página con metodología Scrum |
| `README.md` | Este documento |

## Comandos

```bash
make estimacion         # hoja de dos páginas
make estimacion-scrum   # hoja de una página con Scrum
```

En Windows: `.\build.ps1 -Estimacion` y `.\build.ps1 -EstimacionScrum`.
Se compilan aparte para que un error no bloquee el PDF final y salen en
`entregables/`.

## Las dos hojas

| Hoja | Contenido |
|---|---|
| `estimacion.md` + resumen | Puntos de historia y tablero con límites de WIP |
| `scrum/resumen-scrum.tex` | Sprint, compromiso, velocidad y revisión |

**El costo no cambia entre las dos**: 188 horas-persona, 1,18 mes-persona y
5.875 Bs. Cambia el mecanismo de control y la métrica: *throughput* y tiempo
de ciclo frente a velocidad y *burndown*.

## De dónde salen los datos

| Dato | Origen |
|---|---|
| Historias, puntos, tareas y responsable | `sistema/historias-usuario/historias-usuario.md` |
| Prioridad y riesgo | `sistema/historias-usuario/historias-usuario.csv` |
| Estado de cada tarea | `tablero/tablero.md` |
| Límites de WIP y reglas del flujo | `tablero/README.md` |

La estimación no tiene cifras propias: si el backlog o el tablero cambian,
se recalcula.

## Unidades

| Unidad | Valor |
|---|---|
| Dedicación diaria | 4 h por persona y día hábil |
| Días hábiles por mes | 20 |
| Día-persona | 4 h |
| Mes-persona | 160 h |
| Tarifa | 5.000 Bs por mes-persona (31,25 Bs/h) |
| Tamaño relativo | 1 punto de historia |

## Reglas

- No se edita un resultado a mano: si cambia el tablero, se recalcula.
- La tarifa es una entrada, no un resultado.
- El escenario es único: se estima con el ritmo medido.
- No se anexa al informe sin instrucción explícita.

## Cálculo

```text
Esfuerzo restante = puntos pendientes × (horas-persona gastadas ÷ puntos cerrados)
Costo total       = (horas-persona gastadas + esfuerzo restante) ÷ 160 × 5.000 Bs
```

Las magnitudes se leen del tablero: tareas en `Hecho`, puntos de historias
cerradas y horas-persona acumuladas desde el 12 de noviembre de 2026.
