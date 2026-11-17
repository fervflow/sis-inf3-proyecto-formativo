# Procesos

Diagramas de proceso: el recorrido del sistema, el flujo del trabajo en el
tablero Kanban y el proceso de estimación de costos. No son casos de uso:
describen cómo se recorre el sistema y cómo se trabaja.

| Archivo | Contenido | Tamaño |
|---|---|---|
| `mapa-procesos.puml` | Mapa de actividades con carriles: el recorrido principal del sistema. | 1228 × 701 pt |
| `flujo-tablero-kanban.puml` | Recorrido de una tarjeta por las cinco columnas del tablero, con sus límites de trabajo en curso. | 555 × 1073 pt |
| `estimacion-entrada-proceso-salida.puml` | De dónde sale cada cifra de la estimación: entradas, proceso y salidas. | 860 × 778 pt |

---

## Mapa de procesos

Diagrama de actividades con carriles que agrupa las historias de usuario por
rol y muestra el recorrido principal del sistema.

### Carriles

| Carril | Actividades |
|---|---|
| Turista | Consulta, aceptación de la cotización, solicitud de reserva, registro de su pago y solicitud de cancelación. |
| Personal | Cotización, registro de reserva, validación del pago, confirmación de la solicitud, seguimiento, cancelación y saldo. |
| Administrador | Supervisión, modificación de fechas o capacidad y aviso a los clientes afectados. |
| Sistema | Validación de cupos, saldos e historiales, y vencimiento de las solicitudes sin confirmar. |

### Recorrido

```text
Consulta → [Cotización] → Solicitud de reserva → Pago → Validación del pago
    → Confirmación → Seguimiento ─┬─ Cancelación
                                  └─ Saldo y finalización
```

El mapa incluye una leyenda con las HU de soporte: paquetes, salidas,
ficha del cliente, pasajeros, proveedores, reportes y cuenta de cliente.

---

## Flujo del tablero Kanban

Muestra el recorrido de una tarjeta:

```text
Por hacer → En curso → En pruebas / QA → Listo para producción → Hecho
```

y las dos vueltas atrás: una tarea que no pasa la revisión regresa a
`En curso` con su motivo, y una tarjeta solo se toma de `Por hacer` **cuando
hay cupo** en `En curso`. Ese «cuando hay cupo» es la política de *pull*: el
límite de trabajo en curso es lo que impide tomar más trabajo del que se
puede terminar.

La leyenda recoge las cuatro métricas que hay que medir a partir del cierre
de la primera ventana, y la ley de Little que las relaciona.

---

## Estimación de costos: entradas, proceso y salidas

Es el diagrama de entrada–proceso–salida del cálculo:

| Entradas | De dónde salen |
|---|---|
| Alcance del sistema: 17 historias, 47 pts, 39 tareas | Backlog y CSV |
| Ritmo medido: 1,75 tareas por día, 4,00 h-persona por punto | Tablero Kanban |
| Condiciones del equipo: 2 desarrolladores, 4 h por día hábil | Definición del proyecto |
| Tarifa: 5.000 Bs por mes-persona | Parámetro de la estimación |

| Proceso | Qué hace |
|---|---|
| Esfuerzo unitario | Convierte el ritmo medido en horas-persona por punto. |
| Proyección | Multiplica los puntos pendientes por el esfuerzo unitario. |
| Esfuerzo total | Suma lo gastado y lo proyectado, y lo pasa a mes-persona. |
| Costo | Multiplica el esfuerzo por la tarifa. |
| Plazo | Divide las horas-persona por las horas que el equipo aporta por día. |

| Salidas | Valor |
|---|---|
| Esfuerzo total | 188 horas-persona = 1,18 mes-persona |
| Costo estimado | 5.875 Bs |
| Cierre estimado | 15/12/2026 (2,35 ventanas) |
| Costo del MVP | 2.500 Bs (ventana 1) |

El detalle completo de los cálculos está en `sistema/estimacion/estimacion.md`.

---

## Generación

```powershell
.\build.ps1 -Diagramas
```

Los PDF quedan en `entregables/diagramas/pdf/procesos/`.
