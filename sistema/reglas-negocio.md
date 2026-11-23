# Reglas de negocio

Catálogo canónico de las reglas de negocio del sistema web de gestión de
paquetes turísticos y reservas de Vizcacha Tours. **No forma parte de
`main.tex`**: es documentación de trabajo.

- **Alcance de esta versión:** catálogo, paquetes turísticos, salidas,
  proveedores, cotizaciones y reservas con su confirmación y vencimiento.
- **Fuera de alcance por ahora:** pagos, pasajeros, cancelaciones,
  reportes y avisos. Cada módulo tendrá su propia ampliación del catálogo.
- **Fuente del esquema físico:** `bd/esquema.sql` y `bd/diccionario-datos.md`.
- **Implementación web:** `web/db/schema.ts`, `web/server/` y `web/app/`.

## 1. Propósito

Las reglas estaban repartidas entre el esquema, las historias de usuario, la
aplicación y el informe. Eso permitió que una tarea se marcara como hecha sin
cumplir su propio criterio. Este catálogo fija **qué** debe cumplirse, **por
qué**, **dónde** se aplica y **cómo** se comprueba.

## 2. Términos canónicos

| Término | Definición | Uso |
|---|---|---|
| **Cliente** | Persona o entidad que contrata y paga un paquete. Puede viajar o no. | Entidad `cliente`, API `/api/clientes`, interfaz «Clientes». |
| **Pasajero** | Persona que ocupa un cupo en una salida. Puede ser el cliente u otra persona. | Entidad `pasajero` y `reserva_pasajero`. |
| **Turista** | Persona que viaja por recreación. En este sistema es un sinónimo comercial de cliente cuando el cliente viaja; no es una entidad técnica. | Solo textos públicos o glosario. |
| **Usuario** | Cuenta de acceso. No es una persona del negocio. | Entidad `usuario`. |
| **Servicio** | Prestación que cubre el precio del paquete: desayuno, transporte, guía, etc. | Catálogo `servicio` y vínculo `paquete_servicio`. |
| **Lugar** | Ubicación reutilizable del catálogo: destino principal, origen o parada. | Entidad `lugar`, `paquete.id_lugar_destino`, `paquete.id_lugar_origen` y `paquete_parada`. |
| **Proveedor** | Empresa o persona que presta transporte, hospedaje, guía, alimentación u otro servicio. | Entidad `proveedor` y vínculo `paquete_proveedor`. |
| **Cotización** | Propuesta económica para un cliente y una salida, con plazo y condiciones. No ocupa cupo. | Entidad `cotizacion` y API `/api/cotizaciones`. |

El rol de acceso del cliente se llama `CLIENTE`. El código `TURISTA` queda
obsoleto y no debe volver a introducirse.

## 3. Convenciones del catálogo

1. Cada regla tiene un identificador `RN-<ÁREA>-<NN>`.
2. El enunciado es único y verificable.
3. La fuente puede ser una historia de usuario, el informe, una norma o una
   decisión del proyecto.
4. La aplicación indica si la regla vive en la base, en la API, en la
   interfaz o en un proceso manual.
5. Una regla no está terminada si no tiene caso de éxito y caso de error.
6. Si una regla cambia, cambian el esquema, Drizzle, los tipos, Zod, la
   interfaz, las pruebas y este catálogo.
7. Las pruebas de las reglas están en `bd/pruebas/reglas-paquetes.sql` y
   `bd/pruebas/reglas-reservas.sql`; se ejecutan con `make db-probar` y
   terminan con `ROLLBACK`.

## 4. Reglas generales

| ID | Regla | Fuente | Aplicación | Estado |
|---|---|---|---|---|
| RN-GEN-01 | El cliente contrata y paga; el pasajero viaja; el usuario accede. Los tres conceptos no se usan como sinónimos. | Decisión del proyecto | Documentación, tipos y textos | Vigente |
| RN-GEN-02 | Ningún registro histórico se elimina: se inactiva, se cancela o se conserva. | HU-01, HU-04, HU-13 | Diseño de la API y del esquema | Vigente |
| RN-GEN-03 | Los estados solo cambian por las transiciones documentadas en este catálogo. | HU-01, HU-02, HU-07 | Funciones, API y pruebas | Vigente |
| RN-GEN-04 | El cupo no se almacena: se calcula desde las reservas vigentes. | HU-03, HU-06 | `vista_disponibilidad_salida` | Vigente |
| RN-GEN-05 | Los cambios de reservas y salidas registran usuario, fecha y valores anterior y nuevo; los del paquete registran usuario y fecha de actualización. | HU-07, HU-09, HU-13 | `historial_reserva`, `historial_salida` y `paquete.id_usuario_actualizacion` | Vigente |
| RN-GEN-06 | Un cambio de regla se documenta aquí antes de implementarse. | Decisión del proyecto | Proceso de trabajo | Vigente |

## 5. Paquetes turísticos

### 5.1 Lugares y recorrido

| ID | Regla | Fuente | Aplicación | Estado |
|---|---|---|---|---|
| RN-LUG-01 | El catálogo de lugares es único por nombre normalizado. Cada lugar tiene un código corto en mayúsculas que sirve de prefijo al código del paquete. | Decisión del proyecto | `lugar`, `ux_lugar_nombre` y `ck_lugar_codigo` | Vigente |
| RN-LUG-02 | Un lugar puede no tener coordenadas; si las tiene, la latitud y la longitud son válidas. | Decisión del proyecto | `ck_lugar_coordenadas` | Vigente |
| RN-LUG-03 | Un lugar usado por un paquete no se elimina. | Decisión del proyecto | Clave foránea con `ON DELETE RESTRICT` | Vigente |
| RN-PAQ-16 | El origen es opcional. El recorrido es `sencillo` o `circuito`; un circuito exige origen y vuelve a él. | Decisión del proyecto | `ck_paquete_circuito` y Zod | Vigente |
| RN-PAQ-17 | Las paradas del recorrido se ordenan y no se repiten en el mismo paquete. | Decisión del proyecto | `paquete_parada` y `ux_paquete_parada_lugar` | Vigente |

### 5.2 Identidad y contenido

| ID | Regla | Fuente | Aplicación | Estado |
|---|---|---|---|---|
| RN-PAQ-01 | El código identifica al paquete, es único, tiene entre 3 y 20 caracteres y se guarda en mayúsculas. Se genera al crear con el formato `PREFIJO-AAAA-NNN`: el prefijo es el código del destino principal o, si falta, el del nombre; la secuencia es global. No se edita después. | HU-01 | `fn_generar_codigo_paquete`, `ck_paquete_codigo` y API | Vigente |
| RN-PAQ-02 | El nombre es obligatorio y tiene entre 3 y 150 caracteres. | HU-01 | Zod y base | Vigente |
| RN-PAQ-03 | El destino principal es una referencia a un lugar, opcional en borrador y obligatoria para publicar. | HU-01, T-HU-01.1 | Disparador de publicación y Zod | Vigente |
| RN-PAQ-04 | La descripción es opcional en borrador y obligatoria para publicar. | HU-01 | Disparador de publicación | Vigente |
| RN-PAQ-05 | La duración es un entero mayor que cero y menor o igual a 365 días. | HU-01, HU-02 | `ck_paquete_duracion` y Zod | Vigente |
| RN-PAQ-06 | El precio base es mayor que cero. | HU-01 | `ck_paquete_precio` y Zod | Vigente |
| RN-PAQ-07 | El itinerario es opcional en borrador y obligatorio para publicar. | HU-01, T-HU-01.1 | Disparador de publicación y Zod | Vigente |
| RN-PAQ-08 | Los servicios incluidos son opcionales en borrador y, para publicar, se exige al menos uno marcado. | HU-01 | Disparador de publicación y Zod | Vigente |
| RN-PAQ-09 | Los servicios marcados son la lista canónica de lo que cubre el precio. Los detalles y las exclusiones son textos opcionales. | Decisión del proyecto | `servicio`, `paquete_servicio`, `servicios_detalle` y `servicios_excluidos` | Vigente |
| RN-PAQ-10 | Un paquete con salidas o reservas no se elimina: pasa a inactivo y conserva su historial. | HU-01 | Diseño de la API; no hay ruta de borrado | Vigente |

### 5.3 Publicación

| ID | Regla | Fuente | Aplicación | Estado |
|---|---|---|---|---|
| RN-PAQ-11 | Solo el paquete `activo` se ofrece al cliente y admite nuevas salidas. | HU-01, HU-02, HU-03 | Disparador de publicación, `fn_crear_salida` y consulta de disponibilidad | Vigente |
| RN-PAQ-12 | Un paquete `activo` no puede volver a `borrador`; para retirarlo se pasa a `inactivo`. | Decisión del proyecto | API de paquetes | Vigente |
| RN-PAQ-13 | Un paquete `inactivo` conserva sus salidas y reservas existentes, pero no admite salidas nuevas. | HU-01 | `fn_crear_salida` | Vigente |
| RN-PAQ-14 | Al aplicar la regla de publicación, un paquete activo que no cumple el contenido mínimo pasa a `borrador`; no se ofrecen paquetes incompletos. | Decisión del proyecto | Migración `2026-11-20-lugares-servicios.sql` | Vigente |
| RN-PAQ-15 | Cada edición del paquete registra el usuario que la hizo y la fecha de actualización. | Decisión del proyecto | `id_usuario_actualizacion` y `fecha_actualizacion` | Vigente |

### 5.4 Matriz de campos del paquete

| Campo | Borrador | Activo | Inactivo |
|---|---|---|---|
| `codigo` | Generado | Generado | Generado |
| `nombre` | Obligatorio | Obligatorio | Obligatorio |
| `id_lugar_destino` | Opcional | **Obligatorio** | Opcional |
| `id_lugar_origen` | Opcional | Opcional | Opcional |
| `tipo_recorrido` | Obligatorio | Obligatorio | Obligatorio |
| `descripcion` | Opcional | **Obligatorio** | Opcional |
| `duracion_dias` | Obligatorio (> 0) | Obligatorio (> 0) | Obligatorio (> 0) |
| `precio_base` | Obligatorio (> 0) | Obligatorio (> 0) | Obligatorio (> 0) |
| `itinerario` | Opcional | **Obligatorio** | Opcional |
| `servicios` | Opcional | **Al menos uno** | Opcional |
| `servicios_detalle` | Opcional | Opcional | Opcional |
| `servicios_excluidos` | Opcional | Opcional | Opcional |
| `paradas` | Opcional | Opcional | Opcional |

La regla es deliberada: un borrador puede estar incompleto; un paquete
publicado, no. Así se evita bloquear el trabajo diario y se protege al
cliente.

## 6. Servicios incluidos

| ID | Regla | Fuente | Aplicación | Estado |
|---|---|---|---|---|
| RN-SER-01 | El catálogo de servicios es fijo en el MVP y se amplía con la semilla. | Decisión del proyecto | Tabla `servicio` | Vigente |
| RN-SER-02 | Un paquete puede tener cero o más servicios marcados. | Decisión del proyecto | `paquete_servicio` | Vigente |
| RN-SER-03 | Un servicio no se repite en el mismo paquete. | Decisión del proyecto | PK (`id_paquete`, `id_servicio`) | Vigente |
| RN-SER-04 | Los servicios describen lo que cubre el precio; el itinerario describe qué ocurre cada día. No se sustituyen entre sí. | Decisión del proyecto | Interfaz, API y reglas de publicación | Vigente |
| RN-SER-05 | Para publicar, el paquete debe tener al menos un servicio marcado. | Decisión del proyecto | Disparador de publicación | Vigente |

Servicios iniciales: desayuno, almuerzo, cena, transporte, alojamiento,
guía, entradas a sitios, traslado a terminal o aeropuerto, seguro de viaje,
bebidas y actividades recreativas.

## 7. Salidas programadas

### 7.1 Creación

| ID | Regla | Fuente | Aplicación | Estado |
|---|---|---|---|---|
| RN-SAL-01 | Una salida pertenece a un paquete `activo`. | HU-02 | `fn_crear_salida` | Vigente |
| RN-SAL-02 | La fecha de salida no puede ser anterior a hoy. | HU-02 | `fn_crear_salida` y API | Vigente |
| RN-SAL-03 | La fecha de retorno no puede ser anterior a la de salida. | HU-02 | `ck_salida_fechas` y `fn_crear_salida` | Vigente |
| RN-SAL-04 | La duración de la salida, en días inclusivos, coincide con `paquete.duracion_dias`. | Decisión del proyecto | `fn_crear_salida` y `fn_actualizar_salida` | Vigente |
| RN-SAL-05 | Un paquete no puede tener dos salidas el mismo día. | T-HU-02.2 | `ux_salida_paquete_fecha` | Vigente |
| RN-SAL-06 | La capacidad es un entero mayor que cero. | HU-02 | `ck_salida_cupo` y `fn_crear_salida` | Vigente |
| RN-SAL-07 | El precio de la salida es mayor que cero. | HU-02 | `ck_salida_precio` y `fn_crear_salida` | Vigente |
| RN-SAL-08 | Toda salida nace en estado `programada` y deja su creación auditada. | HU-02 | `fn_crear_salida` | Vigente |

### 7.2 Modificación y estados

| ID | Regla | Fuente | Aplicación | Estado |
|---|---|---|---|---|
| RN-SAL-09 | La capacidad no puede quedar por debajo de los pasajeros de reservas pendientes y confirmadas. | HU-09 | `fn_actualizar_salida` | Vigente |
| RN-SAL-10 | Una salida `realizada` o `cancelada` no admite cambios. | HU-09 | `fn_actualizar_salida` | Vigente |
| RN-SAL-11 | Las transiciones válidas son `programada → confirmada`, `programada → cancelada`, `confirmada → realizada` y `confirmada → cancelada`. | HU-09 | `fn_actualizar_salida` | Vigente |
| RN-SAL-12 | La cancelación de una salida exige un motivo. | HU-09, HU-13 | `fn_actualizar_salida` | Vigente |
| RN-SAL-13 | Cada cambio de fecha, retorno, capacidad, precio, punto de encuentro o estado queda auditado con valor anterior y nuevo. | HU-09 | `historial_salida` | Vigente |
| RN-SAL-14 | El cambio de precio no altera el monto de las reservas ya creadas; el precio se congela al reservar. | Decisión del proyecto | `reserva.monto_total` | Vigente |
| RN-SAL-15 | Los cambios de fecha o capacidad se comunican a los clientes con reservas vigentes. | HU-16 | Pendiente: módulo de avisos | Propuesta |
| RN-SAL-16 | Cancelar una salida con reservas vigentes exige decidir si se cancelan o se reprograman. | HU-09, HU-13 | Pendiente: módulo de reservas | Propuesta |

### 7.3 Visibilidad

| ID | Regla | Fuente | Aplicación | Estado |
|---|---|---|---|---|
| RN-SAL-17 | La consulta de disponibilidad muestra solo paquetes `activos` y salidas `programadas` o `confirmadas` con fecha desde hoy. | HU-03 | Vista o consulta de disponibilidad | Vigente |
| RN-SAL-18 | Las reservas vencidas y las canceladas no ocupan cupo. | HU-03, HU-06 | `vista_disponibilidad_salida` | Vigente |
| RN-SAL-19 | Una solicitud pendiente cuyo plazo venció deja de ocupar cupo aunque su estado guardado siga siendo `pendiente`. | HU-03, HU-17 | `vista_disponibilidad_salida` | Vigente |
| RN-SAL-20 | Una salida no cambia de paquete; si se necesita otra combinación, se crea una salida nueva. | Decisión del proyecto | API de salidas | Vigente |
| RN-SAL-21 | El precio de la salida es el precio efectivo de esa fecha. Parte del precio base del paquete y puede ajustarse; el paquete conserva su precio de catálogo. | Decisión del proyecto | `salida.precio` e interfaz de salidas | Vigente |

## 8. Máquinas de estado del alcance actual

### 8.1 Paquete

```text
borrador ──▶ activo ──▶ inactivo
    │           │           │
    └───────────┴───────────┘
         inactivo ──▶ activo
```

- `borrador → activo`: exige contenido mínimo.
- `activo → inactivo`: retira la oferta sin borrar historial.
- `inactivo → activo`: exige contenido mínimo otra vez.
- `activo → borrador`: no permitido.
- Cualquier otro cambio: rechazado.

### 8.2 Salida

```text
programada ──▶ confirmada ──▶ realizada
     │              │
     └──────────────┴──────▶ cancelada
```

- `realizada` y `cancelada` son terminales.
- La cancelación exige motivo.
- Una salida cancelada libera cupo por cálculo, porque deja de contar en la
  disponibilidad.

## 9. Trazabilidad con las historias

| Historia | Reglas |
|---|---|
| HU-01 · Gestión de paquetes | RN-LUG-01 a RN-LUG-03, RN-PAQ-01 a RN-PAQ-17, RN-SER-01 a RN-SER-05 |
| HU-02 · Fechas de salida y cupos | RN-SAL-01 a RN-SAL-08 y RN-SAL-21 |
| HU-03 · Consulta de disponibilidad | RN-SAL-17 a RN-SAL-19 |
| HU-09 · Modificar fechas o capacidad | RN-SAL-09 a RN-SAL-16 |
| HU-08 · Acceso por rol | RN-USU-01, RN-USU-02 |
| HU-10 · Proveedores y vínculos | RN-PRV-01 a RN-PRV-07 |
| HU-05 · Cotizaciones | RN-COT-01 a RN-COT-09 |
| HU-06 · Registro de reservas | RN-GEN-04, RN-GEN-05, RN-SAL-14, RN-SAL-18, RN-COT-08 y RN-RES-01 a RN-RES-06, RN-RES-11, RN-RES-12 |
| HU-17 · Confirmación y vencimiento de solicitudes | RN-GEN-03, RN-GEN-05, RN-SAL-19 y RN-RES-01, RN-RES-05, RN-RES-07 a RN-RES-10, RN-RES-13 |

## 10. Reglas de usuarios y roles del alcance

| ID | Regla | Fuente | Aplicación | Estado |
|---|---|---|---|---|
| RN-USU-01 | Los roles son `ADMIN`, `PERSONAL` y `CLIENTE`. El código `TURISTA` queda obsoleto. | Decisión del proyecto | `rol.codigo`, tipos y textos | Vigente |
| RN-USU-02 | Un usuario `CLIENTE` debe tener una ficha de cliente; una ficha puede existir sin cuenta. | HU-15, HU-04 | Pendiente: módulo de cuentas de cliente | Propuesta |

## 11. Proveedores

| ID | Regla | Fuente | Aplicación | Estado |
|---|---|---|---|---|
| RN-PRV-01 | El nombre o razón social es obligatorio, tiene entre 3 y 150 caracteres y no se repite. | HU-10 | `ux_proveedor_nombre`, Zod y API | Vigente |
| RN-PRV-02 | El tipo es uno de `transporte`, `hospedaje`, `guia`, `alimentacion` u `otro`. | HU-10 | `ck_proveedor_tipo` | Vigente |
| RN-PRV-03 | NIT, teléfono, correo y dirección son opcionales y tienen longitud limitada. | HU-10 | Zod y tabla | Vigente |
| RN-PRV-04 | El estado es `activo` o `inactivo`. Un proveedor con vínculos no se elimina: pasa a inactivo. | HU-10 | `ck_proveedor_estado` y API | Vigente |
| RN-PRV-05 | Solo un proveedor `activo` se vincula a un paquete nuevo. | HU-10 | API de proveedores | Vigente |
| RN-PRV-06 | Un paquete y un proveedor se vinculan una sola vez; el vínculo guarda el servicio y su costo, que no puede ser negativo. | HU-10 | PK (`id_paquete`, `id_proveedor`) y `ck_paquete_proveedor_costo` | Vigente |
| RN-PRV-07 | Un proveedor puede atender varios paquetes y un paquete puede tener varios proveedores. | HU-10 | `paquete_proveedor` | Vigente |

## 12. Cotizaciones

| ID | Regla | Fuente | Aplicación | Estado |
|---|---|---|---|---|
| RN-COT-01 | La cotización se prepara con un cliente y una salida `programada` o `confirmada` de un paquete activo, con fecha desde hoy. | HU-05 | `validarReferencias` | Vigente |
| RN-COT-02 | El número es único, se genera como `COT-AAAA-NNN` y no se edita. | HU-05 | `fn_generar_codigo_cotizacion` y `numero` único | Vigente |
| RN-COT-03 | La cantidad de pasajeros es mayor que cero; el precio unitario es mayor que cero; el descuento no es negativo ni supera el subtotal. | HU-05 | Zod y restricciones de `cotizacion` | Vigente |
| RN-COT-04 | La validez no es anterior a la emisión. La cotización vencida pasa a `vencida` al consultar la lista. | HU-05 | `ck_cotizacion_validez` y `fn_vencer_cotizaciones` | Vigente |
| RN-COT-05 | Los estados son `borrador`, `enviada`, `aceptada`, `rechazada` y `vencida`. Una cotización terminal no se edita. | HU-05 | API de cotizaciones | Vigente |
| RN-COT-06 | La cotización no descuenta cupo ni crea una reserva. | HU-05 | API de cotizaciones | Vigente |
| RN-COT-07 | Las condiciones y las observaciones son textos opcionales. Las condiciones son los términos comerciales que se muestran al cliente. | HU-05 | `condiciones` y `observaciones` | Vigente |
| RN-COT-08 | Una cotización aceptada puede originar una reserva; el vínculo se guarda en `reserva.id_cotizacion` y la API comprueba que la cotización esté aceptada y corresponda al mismo cliente y a la misma salida. | HU-05, HU-06 | API de reservas | Vigente |
| RN-COT-09 | La cotización no descuenta cupo, pero la cantidad de pasajeros no puede superar el cupo disponible de la salida al prepararla o editarla; la reserva que nazca de ella vuelve a verificarlo. | HU-05, T-COT | API de cotizaciones e interfaz | Vigente |

## 13. Reservas y solicitudes

Las reservas se crean en los dos canales con el mismo proceso validado: la
atención del personal y la solicitud directa del cliente, distinguidas por
el campo `origen`. El cupo lo calcula la base; ninguna capa la reimplementa.

| ID | Regla | Fuente | Aplicación | Estado |
|---|---|---|---|---|
| RN-RES-01 | Toda reserva nace en estado `pendiente`, con su canal de origen `personal` o `web` y con la cantidad de pasajeros mayor que cero. | HU-06 | `fn_crear_reserva`, `ck_reserva_estado` y API | Vigente |
| RN-RES-02 | La validación de cupos se ejecuta dentro de una transacción que bloquea la fila de la salida, de modo que dos registros simultáneos no superen la capacidad. | HU-06 | `fn_crear_reserva` | Vigente |
| RN-RES-03 | El cupo se calcula sobre las reservas pendientes vigentes y las confirmadas; las vencidas y las canceladas no se cuentan. | HU-03, HU-06 | `vista_disponibilidad_salida` y `fn_crear_reserva` | Vigente |
| RN-RES-04 | Un cliente tiene una sola solicitud pendiente por salida; una necesidad adicional se gestiona modificando la solicitud existente. | HU-06 | `ux_reserva_solicitud_activa` y `fn_crear_reserva` | Vigente |
| RN-RES-05 | Toda reserva pendiente tiene fecha de vencimiento a 48 horas de su creación; al vencer deja de ocupar cupo por sí misma. | HU-06, HU-17 | `reserva.fecha_expiracion` y vistas | Vigente |
| RN-RES-06 | El monto de la reserva se congela al crear con el precio de la salida por la cantidad de pasajeros; los cambios de precio posteriores no lo alteran. | HU-06 | `reserva.monto_total` y `fn_crear_reserva` | Vigente |
| RN-RES-07 | Confirmar una solicitud pendiente la pasa a `confirmada`, limpia su fecha de vencimiento y deja el cambio auditado con usuario y fecha. | HU-17 | `fn_confirmar_reserva` e `historial_reserva` | Vigente |
| RN-RES-08 | Una solicitud vencida no puede confirmarse; el intento la marca como `vencida` y audita el intento. El cliente debe registrar una nueva si la salida sigue disponible. | HU-17 | `fn_confirmar_reserva` | Vigente |
| RN-RES-09 | El barrido diario pasa las solicitudes pendientes fuera de plazo a `vencida` y deja el cambio auditado; es limpieza, porque el cupo ya se liberó por cálculo. | HU-17 | `fn_vencer_solicitudes_pendientes` y el cron `vencer-solicitudes` | Vigente |
| RN-RES-10 | La reserva nace auditada: `historial_reserva` registra la creación con su canal y usuario. Las solicitudes del canal web se firman con la cuenta de sistema, que no tiene contraseña y no permite ingreso. | HU-06, HU-17 | `historial_reserva` y la semilla de `usuario` | Vigente |
| RN-RES-11 | La solicitud web identifica al cliente por su documento y tipo; la ficha se reutiliza si existe y se registra con los datos de contacto si no existe, sin duplicar el documento. | HU-06, HU-04 | API de reservas y `uq_cliente_documento` | Vigente |
| RN-RES-12 | Solo una cotización aceptada del mismo cliente y de la misma salida puede originar una reserva, y el vínculo es único. | HU-06 | API de reservas y `reserva.id_cotizacion` | Vigente |
| RN-RES-13 | La consulta del personal muestra las solicitudes de ambos canales con su cliente, su salida, su monto y su fecha de vencimiento, con filtro por estado. | HU-17 | API `GET /api/reservas` e interfaz «Solicitudes» | Vigente |
| RN-RES-14 | La reserva no se elimina nunca: la cancelación la ejecuta el personal con motivo y fecha, y las reservas vencidas, canceladas y finalizadas no se modifican. | HU-13, HU-07 | Pendiente: módulo de cancelaciones | Propuesta |

### 13.1 Máquina de estados de la reserva

```text
pendiente ──▶ confirmada
    │
    └──────▶ vencida
```

- `pendiente → confirmada`: la hace el personal dentro del plazo y audita.
- `pendiente → vencida`: la hacen el intento de confirmación fuera de plazo
  o el barrido diario; es la única transición automática de estado.
- `cancelada` y `finalizada`: llegan con los módulos de cancelaciones (HU-13)
  y seguimiento (HU-07); cualquier otro cambio de estado está rechazado.

## 14. Reglas pendientes de otros módulos

Se documentan aquí para que no se pierdan, pero no se implementan en esta
iteración:

- **Reservas:** manifiesto completo al confirmar; modificación de cantidad
  y salida con nueva verificación de cupos (HU-07); transición a
  `finalizada`; cancelaciones con motivo (HU-13); reportes por fecha (HU-11).
- **Pagos:** no superar el total; estado de la reserva; orden anticipo/saldo;
  `total_pagado` solo con validados; métodos `banca_movil` y `qr`.
- **Pasajeros:** pasajero reutilizable entre reservas; conteo exacto al
  confirmar; el registro debe coincidir con la cantidad declarada.
- **Proveedores:** permitir varios servicios del mismo proveedor en un
  paquete; hoy el vínculo guarda un solo servicio y su costo.
- **Avisos:** cambios de fecha o capacidad de una salida (HU-16).
- **Cuentas de cliente:** alta, vínculo con la ficha y restricción a
  información propia (HU-15). Mientras HU-15 no esté implementada, la
  solicitud web se hace sin cuenta y queda firmada por la cuenta de
  sistema; el panel de usuarios permite crear un `CLIENTE` sin ficha.
- **Roles:** resolver `ADMIN`, `PERSONAL` y `CLIENTE` por `codigo` en lugar
  de depender de los identificadores fijos de la semilla.

## 15. Gobierno del catálogo

1. Una regla nueva se propone aquí con su ID y su fuente.
2. Se decide si se implementa en la base, en la API, en la interfaz o en un
   proceso manual.
3. Se actualizan `bd/esquema.sql`, `web/db/schema.ts`, los tipos, Zod, la
   interfaz y las pruebas.
4. Se agrega el caso de éxito y el caso de error.
5. Se actualiza la historia de usuario y la trazabilidad.
6. Se registra el trabajo aceptado en `docs/changelog/`.

## 16. Decisiones abiertas

- ¿El catálogo de servicios y el de lugares se podrán editar desde la
  administración o seguirán siendo una semilla fija?
- ¿La duración se expresa solo en días o también en noches?
- ¿Se agregará hora de salida y hora de encuentro a la salida?
- ¿La cancelación de una salida con reservas vigentes las cancela o las
  reprograma?
