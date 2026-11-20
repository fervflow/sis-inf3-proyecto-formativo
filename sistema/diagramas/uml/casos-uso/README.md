# Casos de uso

Diagrama de casos de uso del sistema. Los 17 casos del backlog se agrupan
en **14 casos de uso**: muestra lo que el actor quiere conseguir, no las
tareas internas.

| Archivo | Contenido | Tamaño |
|---|---|---|
| `casos-uso.puml` | Actores, casos de uso y relaciones `include` / `extend` | 820 × 1078 pt |

## Actores

| Actor | Casos de uso |
|---|---|
| Cliente | Acceder, abrir cuenta, consultar disponibilidad, registrar reserva y pasajeros, cancelar, pagar, recibir avisos |
| Personal de agencia | Acceder, consultar disponibilidad, cotizar, registrar reserva y pasajeros, gestionar reservas, confirmar, cancelar, validar pagos, reportes |
| Administrador | Acceder, administrar la oferta, programar y modificar salidas, reportes |

El administrador es un rol propio (`rol.codigo = 'ADMIN'`), no una
extensión del personal.

## Trazabilidad con el backlog

| Caso de uso | Historia |
|---|---|
| Acceder al sistema | HU-08 |
| Abrir cuenta de cliente | HU-15 |
| Administrar la oferta | HU-01, HU-10 |
| Programar y modificar salidas | HU-02, HU-09 |
| Consultar disponibilidad | HU-03 |
| Elaborar cotización | HU-05 |
| Registrar reserva | HU-06 |
| Registrar pasajeros | HU-12 |
| Gestionar la reserva | HU-07 |
| Confirmar solicitudes | HU-17 |
| Cancelar reserva | HU-13 |
| Registrar y validar pagos | HU-14 |
| Consultar reportes | HU-11 |
| Recibir avisos de cambios | HU-16 |

## Relaciones

**`include`** (siempre):

| Caso | Incluye | Motivo |
|---|---|---|
| Elaborar cotización | Consultar disponibilidad | El precio depende del cupo |
| Registrar reserva | Consultar disponibilidad | La reserva valida el cupo |
| Registrar reserva | Registrar pasajeros | Los pasajeros quedan vinculados |
| Consultar reportes | Consultar disponibilidad | El reporte publica ocupación y cupos |

**`extend`** (variante con precondición):

| Caso | Extiende | Precondición |
|---|---|---|
| Confirmar solicitudes | Gestionar la reserva | Pendiente y dentro del plazo |
| Cancelar reserva | Gestionar la reserva | No finalizada |
| Registrar y validar pagos | Gestionar la reserva | Confirmada |
| Recibir avisos de cambios | Programar y modificar salidas | Cambió fecha o capacidad |

Confirmar, cancelar y cobrar no son procesos aparte: son formas de
gestionar la reserva, con su precondición.

## Generación

```powershell
.\build.ps1 -Diagramas
```

El PDF queda en `entregables/diagramas/pdf/casos-uso/`.
