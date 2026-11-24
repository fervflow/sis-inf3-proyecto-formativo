# Diccionario de la base de datos

Esquema PostgreSQL del sistema web de gestión de paquetes turísticos y
reservas. **No forma parte de `main.tex`** y no contiene datos reales.

Este archivo es la **referencia canónica del esquema físico**. Las reglas de
negocio se describen en `sistema/reglas-negocio.md` y aquí solo se indica
cómo las aplica la base. El script que crea el esquema está en `esquema.sql`,
en esta misma carpeta.

- **Motor:** PostgreSQL 14 o superior (probado en PostgreSQL 18)
- **Esquema:** `turismo`
- **Script de creación:** `bd/esquema.sql`
- **Archivo de la aplicación:** `web/db/schema.ts` (Drizzle ORM), que
  refleja este mismo esquema
- **Identidad:** Better Auth, con las tablas adaptadas a la nomenclatura de
  este esquema
- **Contenido:** 22 tablas, 3 vistas, 15 funciones (12 de negocio) y 7
  disparadores

## Ejecución

```bash
psql -U postgres -f bd/esquema.sql
```

Para reiniciar desde cero, descomentar en el script y ejecutar:

```sql
DROP SCHEMA IF EXISTS turismo CASCADE;
CREATE SCHEMA turismo;
```

## Tablas

| Tabla | Propósito | Claves y relaciones principales |
|---|---|---|
| `rol` | Catálogo de roles del sistema. | `codigo` único: `ADMIN`, `PERSONAL`, `CLIENTE`. |
| `usuario` | Cuentas de acceso del personal y de los clientes. | `id` de texto, generado por Better Auth; `id_rol` → `rol`. |
| `session` | Sesiones abiertas de Better Auth. | `user_id` → `usuario`; `token` único. |
| `account` | Métodos de autenticación de una cuenta, con la contraseña. | `user_id` → `usuario`. |
| `verification` | Verificaciones de correo y tokens de un solo uso. | `identifier` indexado. |
| `acceso` | Registro de ingresos al sistema. | `id_usuario` → `usuario`. |
| `cliente` | Ficha comercial del cliente. | `id_usuario` opcional → `usuario`; documento y correo únicos (correo obligatorio). |
| `pasajero` | Personas que viajan en una reserva. | `id_cliente` → `cliente`; documento único. |
| `proveedor` | Transporte, hospedaje, guías y otros servicios. | `nombre` único normalizado; `estado` restringido por `CHECK`. |
| `proveedor_tipo` | Tipos de servicio que declara un proveedor (uno o varios). | PK compuesta (`id_proveedor`, `tipo`); `tipo` restringido por `CHECK`. |
| `lugar` | Catálogo reutilizable de lugares, con coordenadas opcionales. | `codigo` único en mayúsculas; nombre normalizado único; `latitud` y `longitud` válidas o ambas nulas. |
| `paquete` | Catálogo de paquetes turísticos. | `codigo` único y en mayúsculas; `id_lugar_destino` e `id_lugar_origen` → `lugar`; `id_usuario_creador` e `id_usuario_actualizacion` → `usuario`; el estado `activo` exige destino, descripción, itinerario y al menos un servicio. |
| `paquete_parada` | Paradas del recorrido, en orden. | PK compuesta (`id_paquete`, `orden`); un lugar no se repite en el mismo paquete. |
| `servicio` | Catálogo fijo de servicios que un paquete puede incluir. | `codigo` único en minúsculas; se amplía con la semilla, no desde la interfaz. |
| `paquete_servicio` | Servicios incluidos en el precio de un paquete. | PK compuesta (`id_paquete`, `id_servicio`). |
| `paquete_proveedor` | Servicio y costo de un proveedor en un paquete. | PK compuesta (`id_paquete`, `id_proveedor`); `servicio` es uno de los tipos declarados del proveedor (FK compuesta a `proveedor_tipo`); `detalle` opcional y `costo >= 0`. |
| `salida` | Fecha, cupo y precio de una salida concreta. | `id_paquete` → `paquete`; `cupo_maximo > 0`; `precio > 0` y puede diferir del precio base del paquete; única por paquete y fecha. |
| `cotizacion` | Propuesta económica para un cliente y una salida. | `id_cliente`, `id_salida`, `id_usuario`; `numero` único; `subtotal` y `total` generados; `condiciones` y `observaciones` opcionales. |
| `reserva` | Reserva de cupos para una salida. | `id_cliente`, `id_salida`; `id_cotizacion` opcional y único. |
| `reserva_pasajero` | Pasajeros incluidos en cada reserva. | PK compuesta (`id_reserva`, `id_pasajero`). |
| `pago` | Anticipo y saldo de una reserva. | `id_reserva` → `reserva`; único (`id_reserva`, `tipo`). |
| `historial_reserva` | Auditoría de cambios de estado de una reserva. | `id_reserva` → `reserva`. |
| `historial_salida` | Auditoría de cambios de fecha, cupo, precio o estado. | `id_salida` → `salida`. |

## Identidad y acceso

La autenticación la gestiona **Better Auth**, que es una biblioteca, no un
servicio: las tablas viven en la misma base de datos que los datos del
negocio.

| Tabla de Better Auth | Tabla aquí | Qué cambia |
|---|---|---|
| `user` | `usuario` | Se renombra con `modelName`, para no depender de la palabra reservada `user`. El identificador es de texto. |
| `session` | `session` | Mismos campos, con nombres en `snake_case`. |
| `account` | `account` | La contraseña vive aquí, no en `usuario`. |
| `verification` | `verification` | Correo de verificación y tokens de un solo uso. |

Los campos que el dominio necesita de la cuenta son **campos adicionales**
de `usuario`: `id_rol`, `nombres`, `apellidos`, `telefono`, `estado` y
`debe_cambiar_password`. El nombre visible de la cuenta (`name`) se arma con
`nombres` y `apellidos`.

`debe_cambiar_password` lo usa la aplicación, no Better Auth: la contraseña
inicial de una cuenta creada por el administrador es el nombre de usuario y
se obliga a cambiarla en el primer ingreso. El nombre de usuario no tiene
columna: se deriva del correo interno (`usuario@vizcacha.tours`).

El **registro de accesos** va aparte, en `acceso`, porque la trazabilidad de
los ingresos es una regla del negocio (criterio de HU-08) y no una función
de la sesión de Better Auth. La aplicación escribe una fila por intento de
ingreso, con usuario, fecha y hora, dirección IP y resultado.

## Campos añadidos para el canal del cliente

| Tabla | Campo | Propósito |
|---|---|---|
| `reserva` | `origen` | Canal de ingreso: `personal` o `web`. Permite conocer de qué vía proviene cada reserva sin duplicar el proceso. |
| `reserva` | `fecha_expiracion` | Fecha límite para confirmar la reserva pendiente. Por omisión, `now() + 24 horas`. |
| `reserva` | `estado = 'vencida'` | Resultado del vencimiento por falta de confirmación. |
| `reserva` | `fecha_solicitud_cancelacion` | Marca que el cliente pidió la cancelación. El estado de la reserva no cambia hasta que el personal la ejecuta. |
| `pago` | `estado` | `registrado`, `validado` o `anulado`. Un pago registrado por el cliente queda `registrado` hasta que el personal lo valida. |
| `pago` | `id_usuario_validacion`, `fecha_validacion` | Usuario que validó el pago y fecha de la validación. |

Índices asociados:

| Índice | Propósito |
|---|---|
| `ix_reserva_vencimiento` | Localiza las solicitudes pendientes que ya vencieron. |
| `ux_reserva_solicitud_activa` | Una sola solicitud pendiente por cliente y salida, en cualquiera de los dos canales. |
| `ix_acceso_usuario_fecha` | Historial de accesos por usuario. |

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
| `pago.metodo` | `efectivo`, `transferencia`, `tarjeta`, `banca_movil`, `qr`, `otro` |
| `pago.estado` | `registrado`, `validado`, `anulado` |
| `acceso.tipo` | `ingreso`, `salida`, `intento` |
| `acceso.resultado` | `permitido`, `denegado` |

## Invariantes que el esquema garantiza

El enunciado canónico de cada regla, su fuente y su trazabilidad están en
`sistema/reglas-negocio.md`. Esta sección solo resume lo que la base aplica
por sí misma.

1. **El cupo no se almacena.** `vista_disponibilidad_salida` calcula:
   `cupo_maximo − pasajeros de reservas vigentes`.
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
9. **Las solicitudes pendientes vencen.** A las 24 horas de creadas, o al
   llegar a `fecha_expiracion`, dejan de ocupar cupo y pasan a `vencida`
   cuando corre el barrido, que además las audita.
10. **Una sola solicitud activa por cliente y salida.** El índice único
    parcial `ux_reserva_solicitud_activa` impide crear dos solicitudes
    pendientes para la misma salida. Una necesidad adicional se resuelve
    modificando la solicitud existente.
11. **El pago del cliente no confirma la reserva.** El pago registrado desde
    el acceso directo del cliente queda en estado `registrado` hasta que el
    personal lo valida. El saldo pendiente se calcula sobre los pagos
    `validados`, de modo que un pago no verificado todavía no se considera
    cobrado.
12. **La cancelación del cliente es una solicitud.** El cliente registra su
    petición en `reserva.fecha_solicitud_cancelacion`; el estado de la
    reserva no cambia hasta que el personal ejecuta la cancelación, registra
    el motivo y la fecha.
13. **El estado de vencimiento es derivado, no dependiente de un proceso.**
    Una reserva `pendiente` cuya `fecha_expiracion` ya pasó deja de ocupar
    cupo en el momento en que expira, porque así lo calculan las vistas. El
    barrido diario (`fn_vencer_solicitudes_pendientes`) solo limpia el
    estado guardado y deja la auditoría. La regla no depende de que un
    proceso se haya ejecutado a tiempo.
14. **La identidad es de Better Auth.** Las cuentas se crean desde la
    aplicación con el identificador de texto que genera la biblioteca. Las
    cuentas se pueden desactivar o bloquear (`usuario.estado`) sin borrar
    su historial, porque nada se borra.
15. **Un paquete activo tiene contenido mínimo.** El disparador diferido
    `tr_paquete_publicado` exige destino principal, descripción, itinerario
    y al menos un servicio en `paquete_servicio`. El borrador puede quedar
    incompleto.
16. **El destino es un lugar y el recorrido es una lista de paradas.**
    `paquete.id_lugar_destino` es el destino comercial; `id_lugar_origen`
    es el punto de partida y `paquete_parada` guarda las paradas en orden.
    `tipo_recorrido = 'circuito'` indica que el viaje vuelve al origen, sin
    repetir el lugar.
17. **Los servicios son la lista de lo que cubre el precio.**
    `paquete_servicio` guarda las prestaciones marcadas; `servicios_detalle`
    y `servicios_excluidos` son textos opcionales. El itinerario es el
    relato día por día y no se sustituye con las casillas.
18. **Una salida pertenece a un paquete activo y respeta su duración.** La
    función `fn_crear_salida` valida el estado del paquete, que la fecha de
    retorno no sea anterior a la de salida y que la duración coincida con
    `paquete.duracion_dias`. El índice `ux_salida_paquete_fecha` impide dos
    salidas del mismo paquete el mismo día.

## Las reglas críticas viven en funciones

Las reglas que necesitan un bloqueo de fila están en funciones PL/pgSQL, no
en el código de la aplicación. La aplicación las llama con una sola
sentencia: la atomicidad la garantiza la transacción de la base, no el
transporte con el que se conecte. Así el mismo esquema sirve con un
cliente local, con un pool de conexiones o con el controlador sin estado de
Neon.

| Función | Regla que aplica |
|---|---|
| `fn_crear_reserva(cliente, salida, cantidad, origen, usuario [, cotización])` | Bloquea la salida, valida el cupo, rechaza la segunda solicitud activa y crea la reserva `pendiente` con su vencimiento. |
| `fn_confirmar_reserva(reserva, usuario)` | Confirma dentro del plazo, limpia el vencimiento y audita. Una solicitud vencida no se confirma: se marca `vencida` y se rechaza. |
| `fn_crear_salida(paquete, salida, retorno, capacidad, precio, usuario [, punto_encuentro, observaciones])` | Exige un paquete activo, fechas coherentes con la duración del paquete, cupo y precio positivos, y una sola salida por paquete y fecha. Audita la creación. |
| `fn_actualizar_salida(salida, usuario [, fecha_salida, fecha_retorno, capacidad, precio, motivo, punto_encuentro, estado])` | Bloquea la salida, impide bajar la capacidad por debajo de lo reservado, valida la transición de estado y audita cada campo modificado con su valor anterior y el nuevo. |
| `fn_solicitar_cancelacion(reserva, usuario)` | Registra la petición del cliente sin cambiar el estado de la reserva. |
| `fn_ejecutar_cancelacion(reserva, motivo, usuario)` | Ejecuta la cancelación del personal: estado `cancelada`, motivo y fecha, con auditoría. |
| `fn_revalidar_reserva(reserva, salida, cantidad, usuario)` | Revalida cupos sin contar la reserva propia, recalcula el monto con el precio vigente y rechaza que los pagos comprometidos queden por encima. Audita los valores anterior y nuevo. |
| `fn_actualizar_reserva(reserva, salida, usuario)` | Mueve una reserva pendiente o confirmada a otra salida; la cantidad la manda el manifiesto. |
| `fn_guardar_manifiesto(reserva, pasajeros JSONB, usuario)` | Reemplaza el manifiesto, reutiliza al pasajero por documento dentro de la ficha del cliente, ajusta la cantidad declarada y revalida cupos, monto y pagos. |
| `fn_registrar_pago(reserva, tipo, monto, metodo, usuario [, referencia, observacion, validado])` | Registra el pago: `registrado` o, si `validado`, `validado` con su usuario y fecha. Aplica el anticipo mínimo del 30%, exige anticipo previo para el saldo y respeta el saldo pendiente. |
| `fn_validar_pago(pago, usuario [, anular])` | Valida o anula el pago y deja quién lo hizo y cuándo. |
| `fn_vencer_solicitudes_pendientes()` | Barrido: pasa a `vencida` las solicitudes cuyo plazo venció y las audita. |

## Concurrencia

La validación de cupos se ejecuta dentro de una transacción y bloquea la
fila de la salida:

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
INSERT INTO reserva (...)
VALUES (...);
COMMIT;
```

Así se evita que dos cajeros confirmen simultáneamente más pasajeros que el
cupo disponible. La misma transacción y el mismo bloqueo se aplican cuando
la solicitud proviene del acceso directo del cliente: los dos canales compiten
por el mismo cupo y ninguno puede reservarlo por encima de la capacidad.

En la aplicación, esa transacción es la que abre la función
`fn_crear_reserva`: la función hace el bloqueo y la validación, y la
aplicación la llama dentro de su propia transacción.

## Vencimiento de las solicitudes pendientes

```sql
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
| `vista_disponibilidad_salida` | Consulta de cupos para HU-03, HU-05 y HU-06. Separa pasajeros pendientes de confirmados, expone `cupo_disponible_sin_pendientes` y el `estado_paquete`/`estado` de la salida para que la consulta pública filtre. Excluye las solicitudes cuyo plazo venció, aunque su estado guardado siga siendo `pendiente`. |
| `vista_saldo_reserva` | Anticipo, saldo pagado, total validado y saldo pendiente para HU-07 y HU-14. El saldo pendiente se calcula sobre los pagos validados. |
| `vista_reservas_por_fecha` | Reporte de ocupación y reservas por fecha para HU-11. Distingue pendientes, confirmadas y vencidas. |

## Supuestos de esta versión

- Una cotización y una reserva corresponden a **una sola salida**. Si luego
  se necesitan varias salidas por cotización, se agrega una tabla de detalle.
- El pasajero puede ser el propio cliente o un acompañante; por eso
  `pasajero` se registra aparte y se vincula mediante `reserva_pasajero`.
- `reserva.cantidad_pasajeros` es un dato de control para agilizar la
  validación; el control de la aplicación debe mantenerlo igual al número
  de filas de `reserva_pasajero`.
- La devolución de dinero por una cancelación se gestiona fuera del sistema
  en esta versión.
- El plazo de 24 horas para confirmar una solicitud es un valor inicial y
  puede ajustarse por la agencia; el esquema lo toma por omisión en
  `fecha_expiracion` y permite fijarlo de forma explícita en cada reserva.
- La cancelación solicitada por el cliente se registra y la ejecuta el
  personal; el sistema no la procesa por sí solo.
- La cuenta del cliente es opcional: un cliente sin cuenta sigue siendo
  atendido por el personal, porque `cliente.id_usuario` admite valor nulo.
- El identificador de las cuentas es de texto porque Better Auth lo genera.
  Las claves foráneas hacia `usuario` son de texto en consecuencia.
- El catálogo `servicio` es fijo en el MVP. Se amplía con una fila en la
  semilla; no se edita desde la interfaz.
- El catálogo `lugar` se amplía desde la interfaz: la búsqueda en Photon
  crea el lugar la primera vez y luego se reutiliza. El código corto se
  deriva del nombre y no se repite.
- La duración de una salida se cuenta en días inclusivos:
  `fecha_retorno − fecha_salida + 1` debe coincidir con
  `paquete.duracion_dias`.
