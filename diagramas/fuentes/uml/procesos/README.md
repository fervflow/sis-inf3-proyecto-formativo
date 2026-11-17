# Mapa de procesos

Diagrama de actividades con carriles que agrupa las historias de usuario por
rol y muestra el recorrido principal del sistema.

## Carriles

| Carril | Actividades |
|---|---|
| Turista | Consulta, aceptación de la cotización, solicitud de reserva, registro de su pago y solicitud de cancelación. |
| Personal | Cotización, registro de reserva, validación del pago, confirmación de la solicitud, seguimiento, cancelación y saldo. |
| Administrador | Supervisión, modificación de fechas o capacidad y aviso a los clientes afectados. |
| Sistema | Validación de cupos, saldos e historiales, y vencimiento de las solicitudes sin confirmar. |

## Recorrido

```text
Consulta → [Cotización] → Solicitud de reserva → Pago → Validación del pago
    → Confirmación → Seguimiento ─┬─ Cancelación
                                  └─ Saldo y finalización
```

El mapa incluye una leyenda con las HU de soporte: paquetes, salidas,
ficha del cliente, pasajeros, proveedores, reportes y cuenta de cliente.

## Generación

```powershell
.\build.ps1 -Diagramas
```

El PDF queda en `diagramas/generados/procesos/`.
