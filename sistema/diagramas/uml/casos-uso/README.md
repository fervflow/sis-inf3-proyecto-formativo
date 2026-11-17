# Casos de uso

Diagrama de casos de uso del sistema de gestión de paquetes turísticos y
reservas. Los 17 casos de uso del backlog se agrupan en **14 casos de uso**:
el diagrama muestra lo que el actor quiere conseguir, no las tareas internas
de programación.

| Archivo | Contenido | Tamaño |
|---|---|---|
| `casos-uso.puml` | Actores, casos de uso y sus relaciones `<<include>>` y `<<extend>>`. | 820 × 1078 pt |

## Actores

| Actor | Casos de uso |
|---|---|
| Cliente (turista) | Acceder al sistema, Abrir cuenta de cliente, Consultar disponibilidad, Registrar reserva, Registrar pasajeros, Cancelar reserva, Registrar y validar pagos, Recibir avisos de cambios |
| Personal de agencia | Acceder al sistema, Consultar disponibilidad, Elaborar cotización, Registrar reserva, Registrar pasajeros, Gestionar la reserva, Confirmar solicitudes, Cancelar reserva, Registrar y validar pagos, Consultar reportes |
| Administrador | Acceder al sistema, Administrar la oferta, Programar y modificar salidas, Consultar reportes |

Los tres vienen de la tabla de actores del backlog. El administrador es un
rol propio del sistema (`rol.codigo = 'ADMIN'`), no una extensión del
personal de agencia.

## Trazabilidad con el backlog

| Caso de uso | Historia de usuario |
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

**`<<include>>`: el caso de uso incluye a otro, siempre.**

| Caso | Incluye a | Por qué |
|---|---|---|
| Elaborar cotización | Consultar disponibilidad | El precio de la propuesta se calcula sobre los cupos de la salida. |
| Registrar reserva | Consultar disponibilidad | La reserva valida el cupo antes de guardarse. |
| Registrar reserva | Registrar pasajeros | Los pasajeros quedan identificados y vinculados a la reserva. |
| Consultar reportes | Consultar disponibilidad | El reporte publica la ocupación y los cupos libres por fecha. |

**`<<extend>>`: el caso de uso es una variante de otro, con precondición.**

| Caso | Extiende a | Precondición |
|---|---|---|
| Confirmar solicitudes | Gestionar la reserva | La solicitud está pendiente y dentro del plazo. |
| Cancelar reserva | Gestionar la reserva | La reserva no está finalizada. |
| Registrar y validar pagos | Gestionar la reserva | La reserva está confirmada. |
| Recibir avisos de cambios | Programar y modificar salidas | Cambió la fecha o la capacidad de la salida. |

Las cuatro extensiones cuelgan de los dos casos de uso generales: la gestión
de la reserva y el mantenimiento de las salidas. Así se ve en el diagrama que
confirmar, cancelar y cobrar **no son procesos aparte**: son maneras
particulares de gestionar la reserva, con su precondición.

## Generación

```powershell
.\build.ps1 -Diagramas
```

El PDF queda en `entregables/diagramas/pdf/casos-uso/`.
