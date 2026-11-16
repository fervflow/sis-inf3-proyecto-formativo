# Mapa de procesos

Diagrama de actividades con carriles que agrupa las historias de usuario por
rol y muestra el recorrido principal del sistema.

## Carriles

| Carril | Actividades |
|---|---|
| Turista | Consulta, aceptación de la cotización, solicitud de reserva y cancelación. |
| Personal | Cotización, registro de reserva, anticipo, seguimiento y saldo. |
| Administrador | Supervisión y modificación de fechas o capacidad. |
| Sistema | Validación de cupos, saldos e historiales. |

## Recorrido

```text
Consulta → Cotización → Reserva → Anticipo → Seguimiento → Saldo → Fin
                                                ├── Cancelar reserva
                                                └── Modificar salida
```

El diagrama incluye una leyenda con las HU de soporte: paquetes, salidas,
clientes/pasajeros, proveedores y reportes.

## Generación

```powershell
.\build.ps1 -Diagramas
```

El PDF queda en `diagramas/generados/procesos/`.
