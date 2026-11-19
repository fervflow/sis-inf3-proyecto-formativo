# Procesos

Diagramas de proceso: el recorrido del sistema, el flujo del tablero kanban
y la estimación de costos.

| Archivo | Contenido | Tamaño |
|---|---|---|
| `mapa-procesos.puml` | Mapa de actividades con carriles | 1228 × 701 pt |
| `flujo-tablero-kanban.puml` | Recorrido de una tarjeta por las cinco columnas | 555 × 1073 pt |
| `estimacion-entrada-proceso-salida.puml` | Entradas, proceso y salidas del cálculo | 860 × 778 pt |

## Mapa de procesos

Agrupa las historias por rol y muestra el recorrido principal.

| Carril | Actividades |
|---|---|
| Turista | Consulta, aceptación de la cotización, solicitud de reserva, registro del pago y solicitud de cancelación |
| Personal | Cotización, registro de reserva, validación del pago, confirmación, seguimiento, cancelación y saldo |
| Administrador | Supervisión, cambio de fechas o capacidad y aviso a los clientes |
| Sistema | Cupos, saldos, historiales y vencimiento de solicitudes |

```text
Consulta → [Cotización] → Solicitud de reserva → Pago → Validación
    → Confirmación → Seguimiento ─┬─ Cancelación
                                  └─ Saldo y finalización
```

La leyenda incluye las HU de soporte: paquetes, salidas, ficha del cliente,
pasajeros, proveedores, reportes y cuenta de cliente.

## Flujo del tablero kanban

```text
Por hacer → En curso → En pruebas / QA → Listo para producción → Hecho
```

Una tarea que no pasa la revisión vuelve a `En curso` con su motivo, y solo
se toma trabajo de `Por hacer` cuando hay cupo. Ese es el *pull*: el límite
de WIP impide tomar más de lo que se puede terminar. La leyenda recoge las
métricas y la ley de Little.

## Estimación de costos

| Entradas | Origen |
|---|---|
| 17 historias, 47 pts, 39 tareas | Backlog y CSV |
| 1,75 tareas por día, 4,00 h-persona por punto | Tablero |
| 2 desarrolladores, 4 h por día hábil | Definición del proyecto |
| 5.000 Bs por mes-persona | Parámetro |

| Proceso | Qué hace |
|---|---|
| Esfuerzo unitario | Convierte el ritmo en horas-persona por punto |
| Proyección | Multiplica los puntos pendientes por el esfuerzo unitario |
| Esfuerzo total | Suma lo gastado y lo proyectado |
| Costo | Multiplica el esfuerzo por la tarifa |
| Plazo | Divide las horas-persona por las horas del equipo |

| Salidas | Valor |
|---|---|
| Esfuerzo total | 188 horas-persona = 1,18 mes-persona |
| Costo estimado | 5.875 Bs |
| Cierre estimado | 15/12/2026 (2,35 ventanas) |
| Costo del MVP | 2.500 Bs (ventana 1) |

El detalle está en `sistema/estimacion/estimacion.md`.

## Generación

```powershell
.\build.ps1 -Diagramas
```

Los PDF quedan en `entregables/diagramas/pdf/procesos/`.
