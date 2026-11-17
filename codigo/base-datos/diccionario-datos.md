# Diccionario de la base de datos temporal

Esquema PostgreSQL de trabajo para el sistema web de gestión de paquetes
turísticos y reservas. **No forma parte de `main.tex`** y no contiene datos
reales.

- **Motor:** PostgreSQL 14 o superior
- **Esquema:** `turismo`
- **Archivo:** `codigo/base-datos/esquema-temporal.sql`
- **Roles iniciales:** `ADMIN`, `PERSONAL`, `TURISTA`

## Ejecución

```bash
psql -U postgres -f codigo/base-datos/esquema-temporal.sql
```

Para reiniciar desde cero, descomentar al inicio del script:

```sql
DROP SCHEMA IF EXISTS turismo CASCADE;
CREATE SCHEMA turismo;
```

## Tablas

| Tabla | Propósito | Claves y relaciones principales |
|---|---|---|
| `rol` | Catálogo de roles del sistema. | `codigo` único: `ADMIN`, `PERSONAL`, `TURISTA`. |
| `usuario` | Cuentas de acceso del personal y de los turistas. | `id_rol` → `rol`; `correo` único. |
| `cliente` | Ficha comercial del cliente. | `id_usuario` opcional → `usuario`; documento único. |
| `pasajero` | Personas que viajan en una reserva. | `id_cliente` → `cliente`; documento único. |
| `proveedor` | Transporte, hospedaje, guías y otros servicios. | `tipo` restringido por `CHECK`. |
| `paquete` | Catálogo de paquetes turísticos. | `codigo` único; `id_usuario_creador` → `usuario`. |
| `paquete_proveedor` | Servicios de proveedores incluidos en un paquete. | PK compuesta (`id_paquete`, `id_proveedor`). |
| `salida` | Fecha, cupo y precio de una salida concreta. | `id_paquete` → `paquete`; `cupo_maximo > 0`. |
| `cotizacion` | Propuesta económica para un cliente y una salida. | `id_cliente`, `id_salida`, `id_usuario`; `numero` único. |
| `reserva` | Reserva de cupos para una salida. | `id_cliente`, `id_salida`; `id_cotizacion` opcional y único. |
| `reserva_pasajero` | Pasajeros incluidos en cada reserva. | PK compuesta (`id_reserva`, `id_pasajero`). |
| `pago` | Anticipo y saldo de una reserva. | `id_reserva` → `reserva`; único (`id_reserva`, `tipo`). |
| `historial_reserva` | Auditoría de cambios de estado de una reserva. | `id_reserva` → `reserva`. |
| `historial_salida` | Auditoría de cambios de fecha, cupo, precio o estado. | `id_salida` → `salida`. |

## Campos añadidos para el canal del cliente

| Tabla | Campo | Propósito |
|---|---|---|
| `reserva` | `origen` | Canal de ingreso: `personal` o `web`. Permite conocer de qué vía proviene cada reserva sin duplicar el proceso. |
| `reserva` | `fecha_expiracion` | Fecha límite para confirmar la reserva pendiente. Por omisión, `now() + 48 horas`. |
| `reserva` | `estado = 'vencida'` | Resultado del vencimiento por falta de confirmación. |

Índices asociados:

| Índice | Propósito |
|---|---|
| `ix_reserva_vencimiento` | Localiza las solicitudes pendientes que ya vencieron. |
| `ux_reserva_solicitud_activa` | Una sola solicitud pendiente por cliente y salida, en cualquiera de los dos canales. |

## Estados

| Entidad | Valores permitidos |
|---|---|
| `usuario.estado` | `activo`, `inactivo`, `bloqueado` |
| `cliente.estado` | `activo`, `inactivo` |
| `paquete.estado` | `borrador`, `activo`, `inactivo` |
| `salida.estado` | `programada`, `confirmada`, `realizada`, `cancelada` |
| `cotizacion.estado` | `borrador`, `enviada`, `aceptada`, `rechazada`, `vencida` |
| `reserva.estado` | `pendiente`, `confirmada`, `vencida`, `cancelada`, `finalizada` |
| `reserva.origen` | `personal`, `web` |
| `pago.tipo` | `anticipo`, `saldo` |
| `pago.metodo` | `efectivo`, `transferencia`, `tarjeta`, `otro` |

## Reglas de negocio reflejadas en el esquema

1. **El cupo no se almacena.** `vista_disponibilidad_salida` calcula:
   `cupo_maximo − pasajeros de reservas pendientes o confirmadas`.
2. **Una reserva cancelada no se elimina.** Cambia a `cancelada`, guarda
   `motivo_cancelacion` y `fecha_cancelacion`, y libera el cupo porque la
   vista deja de contarla.
3. **No se puede reducir la capacidad por debajo de lo reservado.** La
   validación se hace en la transacción, antes del `UPDATE` de `salida`.
4. **Una cotización puede originar una reserva o no.** `id_cotizacion` es
   opcional y único cuando existe.
5. **Solo un anticipo y un saldo por reserva.** La restricción
   `UNIQUE (id_reserva, tipo)` lo garantiza.
6. **Los cambios quedan auditados.** `historial_reserva` e
   `historial_salida` registran usuario, fecha y valores anterior/nuevo.
7. **Los pagos son informativos.** No se conecta ninguna pasarela bancaria.
8. **Los dos canales siguen el mismo flujo.** Una reserva creada por
   solicitud del cliente (`origen = 'web'`) nace en `pendiente` y requiere la
   confirmación del personal, igual que una creada en la atención presencial
   (`origen = 'personal'`). El sistema no confirma por sí solo.
9. **Las solicitudes pendientes vencen.** A las 48 horas de creadas, o al
   llegar a `fecha_expiracion`, pasan a `vencida` y liberan el cupo de forma
   automática, sin intervención manual. La rutina
   `fn_vencer_solicitudes_pendientes()` ejecuta el cambio y lo audita.
10. **Una sola solicitud activa por cliente y salida.** El índice único
    parcial `ux_reserva_solicitud_activa` impide crear dos solicitudes
    pendientes para la misma salida. Una necesidad adicional se resuelve
    modificando la solicitud existente.
11. **El pago del cliente no confirma la reserva.** El pago registrado desde
    el acceso directo del cliente queda pendiente de validación del personal,
    igual que el resto de los pagos.

## Concurrencia

La validación de cupos debe ejecutarse dentro de una transacción y bloquear
la fila de la salida:

```sql
BEGIN;
SELECT cupo_maximo
FROM turismo.salida
WHERE id_salida = $1
FOR UPDATE;

SELECT COALESCE(SUM(cantidad_pasajeros), 0) AS ocupados
FROM turismo.reserva
WHERE id_salida = $1
  AND estado IN ('pendiente', 'confirmada');

-- Si cantidad_solicitada <= cupo_maximo - ocupados:
INSERT INTO turismo.reserva (...) VALUES (...);
COMMIT;
```

Así se evita que dos cajeros confirmen simultáneamente más pasajeros que el
cupo disponible. La misma transacción y el mismo bloqueo se aplican cuando la
solicitud proviene del acceso directo del cliente: los dos canales compiten
por el mismo cupo y ninguno puede reservarlo por encima de la capacidad.

## Vencimiento de las solicitudes pendientes

```sql
-- Rutina que el personal ejecuta de forma periódica:
SELECT turismo.fn_vencer_solicitudes_pendientes();
```

La rutina localiza las reservas `pendiente` cuya `fecha_expiracion` ya pasó,
las cambia a `vencida` y registra el cambio en `historial_reserva`. Al dejar de
computar en `vista_disponibilidad_salida`, los cupos quedan liberados sin
intervención manual. La aplicación debe borrar `fecha_expiracion` al
confirmar la reserva, porque el plazo deja de correr.

## Vistas

| Vista | Uso |
|---|---|
| `vista_disponibilidad_salida` | Consulta de cupos para HU-03, HU-05 y HU-06. Separa pasajeros pendientes de confirmados y expone `cupo_disponible_sin_pendientes`. |
| `vista_saldo_reserva` | Anticipo, saldo pagado y saldo pendiente para HU-07 y HU-14. |
| `vista_reservas_por_fecha` | Reporte de ocupación y reservas por fecha para HU-11. Distingue pendientes, confirmadas y vencidas. |

## Supuestos de esta primera versión

- Una cotización y una reserva corresponden a **una sola salida**. Si luego
  se necesitan varias salidas por cotización, se agrega una tabla de detalle.
- El pasajero puede ser el propio cliente o un acompañante; por eso
  `pasajero` se registra aparte y se vincula mediante `reserva_pasajero`.
- `reserva.cantidad_pasajeros` es un dato de control para agilizar la
  validación; el control de la aplicación debe mantenerlo igual al número de
  filas de `reserva_pasajero`.
- La devolución de dinero por una cancelación se gestiona fuera del sistema
  en esta versión.
- El plazo de 48 horas para confirmar una solicitud es un valor inicial y
  puede ajustarse por la agencia; el esquema lo toma por omisión en
  `fecha_expiracion` y permite fijarlo de forma explícita en cada reserva.
- La cancelación solicitada por el cliente se registra y la ejecuta el
  personal; el sistema no la procesa por sí solo.
- La cuenta del cliente es opcional: un cliente sin cuenta sigue siendo
  atendido por el personal, porque `cliente.id_usuario` admite valor nulo.
