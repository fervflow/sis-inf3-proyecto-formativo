# Reglas de negocio

Catálogo canónico de las reglas de negocio del sistema web de gestión de
paquetes turísticos y reservas de Vizcacha Tours. **No forma parte de
`main.tex`**: es documentación de trabajo.

- **Alcance de esta versión:** catálogo, paquetes turísticos, salidas,
  proveedores, cotizaciones, reservas con confirmación, vencimiento,
  manifiesto, modificación, cancelación y finalización (RN-RES-14 a
  RN-RES-22), avisos derivados del historial, cuentas de cliente
  (RN-USU-02 a RN-USU-05), pagos con pasarela simulada (RN-PAG-01 a
  RN-PAG-08) y reportes (RN-REP-01 a RN-REP-04).
- **Fuera de alcance por ahora:** el envío real de correos y la pasarela
  real de pagos. Cada módulo tendrá su propia ampliación del catálogo.
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
| **Anticipo** | Primer pago de la reserva. No puede ser menor al 30% del monto total y puede cubrir la totalidad. | Entidad `pago` con `tipo = 'anticipo'`. |
| **Saldo** | Pago que completa la reserva con lo que falta después del anticipo. | Entidad `pago` con `tipo = 'saldo'`. |
| **Pasarela simulada** | Emulación del cobro por banca móvil o código QR: genera la referencia y registra el pago, sin mover dinero real. | Módulo de pagos de la web. |

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
| RN-PAQ-18 | El itinerario es el relato día por día del paquete: cada día lleva número, título y detalle. Los días se renumeran al reordenar y un paquete activo necesita al menos uno; la columna de texto libre desapareció. | Decisión del proyecto | `paquete_itinerario` y disparador de publicación | Vigente |

### 5.2 Identidad y contenido

| ID | Regla | Fuente | Aplicación | Estado |
|---|---|---|---|---|
| RN-PAQ-01 | El código identifica al paquete, es único, tiene entre 3 y 20 caracteres y se guarda en mayúsculas. Se genera al crear con el formato `PREFIJO-AAAA-NNN`: el prefijo es el código del destino principal o, si falta, el del nombre; la secuencia es global. No se edita después. | HU-01 | `fn_generar_codigo_paquete`, `ck_paquete_codigo` y API | Vigente |
| RN-PAQ-02 | El nombre es obligatorio y tiene entre 3 y 150 caracteres. | HU-01 | Zod y base | Vigente |
| RN-PAQ-03 | El destino principal es una referencia a un lugar, opcional en borrador y obligatoria para publicar. | HU-01, T-HU-01.1 | Disparador de publicación y Zod | Vigente |
| RN-PAQ-04 | La descripción es opcional en borrador y obligatoria para publicar. | HU-01 | Disparador de publicación | Vigente |
| RN-PAQ-05 | La duración es un entero mayor que cero y menor o igual a 365 días. | HU-01, HU-02 | `ck_paquete_duracion` y Zod | Vigente |
| RN-PAQ-06 | El precio base es mayor que cero. | HU-01 | `ck_paquete_precio` y Zod | Vigente |
| RN-PAQ-07 | El itinerario es opcional en borrador y obligatorio para publicar: al menos un día en `paquete_itinerario` (RN-PAQ-18). | HU-01, T-HU-01.1 | Disparador de publicación, Zod e interfaz | Vigente |
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
| `itinerario` (días en `paquete_itinerario`) | Opcional | **Al menos un día** | Opcional |
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
| RN-SAL-22 | El código de la salida es único, se genera al crear con el código del paquete y un ordinal por paquete (`PAQUETE-NNN`), y no se edita después. Distingue las salidas de un mismo paquete en la consulta de disponibilidad. | Decisión del proyecto | Disparador `tr_salida_codigo`, `uq_salida_codigo` y `vista_disponibilidad_salida` | Vigente |
| RN-SAL-23 | Una salida puede registrar asignaciones operativas de proveedores activos con un tipo declarado y una descripción opcional, y el mismo proveedor no se repite en la salida. La capa del paquete es el contrato con su costo; la de la salida dice qué guía conduce y con qué unidad se viaja. Es opcional, sin costos y no cambia el cupo ni el precio. | HU-18, HU-19 | `salida_proveedor`, FK compuesta e interfaz | Vigente |
| RN-SAL-24 | La ficha de la salida muestra el paquete, el mapa del recorrido, el itinerario por días, los servicios incluidos, sus detalles y las exclusiones, y los proveedores con sus detalles por servicio. El cliente nunca ve costos internos; el personal ve además los costos de los vínculos y el estado de la salida. | HU-18 | API de ficha e interfaz | Vigente |

### 7.2 Modificación y estados

| ID | Regla | Fuente | Aplicación | Estado |
|---|---|---|---|---|
| RN-SAL-09 | La capacidad no puede quedar por debajo de los pasajeros de reservas pendientes y confirmadas. | HU-09 | `fn_actualizar_salida` | Vigente |
| RN-SAL-10 | Una salida `realizada` o `cancelada` no admite cambios. | HU-09 | `fn_actualizar_salida` | Vigente |
| RN-SAL-11 | Las transiciones válidas son `programada → confirmada`, `programada → cancelada`, `confirmada → realizada` y `confirmada → cancelada`. | HU-09 | `fn_actualizar_salida` | Vigente |
| RN-SAL-12 | La cancelación de una salida exige un motivo. | HU-09, HU-13 | `fn_actualizar_salida` | Vigente |
| RN-SAL-13 | Cada cambio de fecha, retorno, capacidad, precio, punto de encuentro o estado queda auditado con valor anterior y nuevo. | HU-09 | `historial_salida` | Vigente |
| RN-SAL-14 | El cambio de precio no altera el monto de las reservas ya creadas; el precio se congela al reservar. | Decisión del proyecto | `reserva.monto_total` | Vigente |
| RN-SAL-15 | Los cambios de fecha o capacidad se comunican a los clientes con reservas vigentes. | HU-16 | API de avisos derivados del `historial_salida` y «Mis reservas» | Vigente |
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
| HU-01 · Gestión de paquetes | RN-LUG-01 a RN-LUG-03, RN-PAQ-01 a RN-PAQ-18, RN-SER-01 a RN-SER-05 |
| HU-02 · Fechas de salida y cupos | RN-SAL-01 a RN-SAL-08, RN-SAL-21 a RN-SAL-24 |
| HU-03 · Consulta de disponibilidad | RN-SAL-17 a RN-SAL-19 |
| HU-09 · Modificar fechas o capacidad | RN-SAL-09 a RN-SAL-16 |
| HU-08 · Acceso por rol | RN-USU-01, RN-USU-02 |
| HU-10 · Proveedores y vínculos | RN-PRV-01 a RN-PRV-08 |
| HU-05 · Cotizaciones | RN-COT-01 a RN-COT-09 |
| HU-15 · Cuenta de cliente | RN-USU-02 a RN-USU-05 |
| HU-06 · Registro de reservas | RN-GEN-04, RN-GEN-05, RN-SAL-14, RN-SAL-18, RN-COT-08 y RN-RES-01 a RN-RES-06, RN-RES-11, RN-RES-12, RN-RES-17 |
| HU-14 · Anticipos y saldos | RN-PAG-01 a RN-PAG-08 |
| HU-12 · Pasajeros y manifiesto | RN-RES-19, RN-RES-21 |
| HU-07 · Seguimiento y actualización | RN-GEN-03, RN-GEN-05, RN-RES-14, RN-RES-20, RN-RES-21 |
| HU-13 · Cancelaciones | RN-RES-14 |
| HU-16 · Avisos de cambios | RN-RES-22 |
| HU-11 · Reportes | RN-REP-01 a RN-REP-04 |
| HU-17 · Confirmación y vencimiento de solicitudes | RN-GEN-03, RN-GEN-05, RN-SAL-19 y RN-RES-01, RN-RES-05, RN-RES-07 a RN-RES-10, RN-RES-13, RN-RES-18, RN-RES-19 |
| HU-18 · Ficha de la salida | RN-LUG-02, RN-SAL-20 a RN-SAL-24, RN-PAQ-18, RN-SER-01 a RN-SER-04 y RN-PRV-06, RN-PRV-08 |
| HU-19 · Detalles de servicios de proveedores | RN-PRV-02, RN-PRV-04 a RN-PRV-08, RN-SAL-23 |

## 10. Reglas de usuarios y roles del alcance

| ID | Regla | Fuente | Aplicación | Estado |
|---|---|---|---|---|
| RN-USU-01 | Los roles son `ADMIN`, `PERSONAL` y `CLIENTE`. El código `TURISTA` queda obsoleto. | Decisión del proyecto | `rol.codigo`, tipos y textos | Vigente |
| RN-USU-02 | Un usuario `CLIENTE` tiene exactamente una ficha de cliente vinculada; una ficha puede existir sin cuenta. | HU-15, HU-04 | `cliente.id_usuario`, registro de cuentas y registro de fichas | Vigente |
| RN-USU-03 | El registro público crea la cuenta y la ficha del cliente en un solo paso, con correo y documento obligatorios y únicos. Si el documento ya tiene ficha, la cuenta se vincula a ella en lugar de duplicarla. El dominio interno `vizcacha.tours` queda reservado a las cuentas del personal. | HU-15 | API `/api/registro`, Better Auth y `uq_cliente_documento` | Vigente |
| RN-USU-04 | El panel de usuarios solo crea cuentas `ADMIN` y `PERSONAL`; las de cliente nacen del registro público. Una cuenta puede bloquearse sin borrar su historial. | HU-15, HU-08 | API `/api/admin/usuarios` y panel de usuarios | Vigente |
| RN-USU-05 | El correo es obligatorio y único en toda ficha de cliente: es el canal de contacto para cotizaciones y avisos, y la identidad del registro. | HU-15, HU-04 | `cliente.correo`, `ux_cliente_correo` y formularios | Vigente |

## 11. Proveedores

| ID | Regla | Fuente | Aplicación | Estado |
|---|---|---|---|---|
| RN-PRV-01 | El nombre o razón social es obligatorio, tiene entre 3 y 150 caracteres y no se repite. | HU-10 | `ux_proveedor_nombre`, Zod y API | Vigente |
| RN-PRV-02 | El tipo es uno de `transporte`, `hospedaje`, `guia`, `alimentacion` u `otro`, y un proveedor declara uno o varios de ellos sin repetir. | HU-10 | `proveedor_tipo`, Zod e interfaz | Vigente |
| RN-PRV-03 | NIT, teléfono, correo y dirección son opcionales y tienen longitud limitada. | HU-10 | Zod y tabla | Vigente |
| RN-PRV-04 | El estado es `activo` o `inactivo`. Un proveedor con vínculos no se elimina: pasa a inactivo. | HU-10 | `ck_proveedor_estado` y API | Vigente |
| RN-PRV-05 | Solo un proveedor `activo` se vincula a un paquete nuevo. | HU-10 | API de proveedores | Vigente |
| RN-PRV-06 | Un paquete y un proveedor se vinculan una sola vez; el vínculo guarda uno de los tipos declarados del proveedor, una descripción opcional (`detalle`) y su costo, que no puede ser negativo. Un tipo declarado que está en uso no se retira de la ficha. | HU-10 | PK (`id_paquete`, `id_proveedor`), FK compuesta a `proveedor_tipo`, `ck_paquete_proveedor_costo` y API | Vigente |
| RN-PRV-07 | Un proveedor puede atender varios paquetes y un paquete puede tener varios proveedores. | HU-10 | `paquete_proveedor` | Vigente |
| RN-PRV-08 | Cada proveedor registra detalles por cada tipo de servicio que declara, con título obligatorio, descripción y orden: el guía con su certificación e idiomas, el menú con sus platos y sus alérgenos, la unidad con su capacidad. La oferta es del proveedor, no del paquete; al retirar un tipo declarado se retiran sus detalles. | HU-19 | `proveedor_servicio`, FK compuesta y API | Vigente |

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
atención del personal y la solicitud del cliente con sesión, distinguidas
por el campo `origen`. El canal web exige una cuenta de cliente con su
ficha; nadie reserva de forma anónima. El cupo lo calcula la base;
ninguna capa la reimplementa.

| ID | Regla | Fuente | Aplicación | Estado |
|---|---|---|---|---|
| RN-RES-01 | Toda reserva nace en estado `pendiente`, con su canal de origen `personal` o `web` y con la cantidad de pasajeros mayor que cero. | HU-06 | `fn_crear_reserva`, `ck_reserva_estado` y API | Vigente |
| RN-RES-02 | La validación de cupos se ejecuta dentro de una transacción que bloquea la fila de la salida, de modo que dos registros simultáneos no superen la capacidad. | HU-06 | `fn_crear_reserva` | Vigente |
| RN-RES-03 | El cupo se calcula sobre las reservas pendientes vigentes y las confirmadas; las vencidas y las canceladas no se cuentan. | HU-03, HU-06 | `vista_disponibilidad_salida` y `fn_crear_reserva` | Vigente |
| RN-RES-04 | Un cliente tiene una sola solicitud pendiente por salida; una necesidad adicional se gestiona modificando la solicitud existente. | HU-06 | `ux_reserva_solicitud_activa` y `fn_crear_reserva` | Vigente |
| RN-RES-05 | Toda reserva pendiente tiene fecha de vencimiento a 24 horas de su creación; al vencer deja de ocupar cupo por sí misma. | HU-06, HU-17 | `reserva.fecha_expiracion` y vistas | Vigente |
| RN-RES-06 | El monto de la reserva se congela al crear con el precio de la salida por la cantidad de pasajeros; los cambios de precio posteriores no lo alteran. | HU-06 | `reserva.monto_total` y `fn_crear_reserva` | Vigente |
| RN-RES-07 | Confirmar una solicitud pendiente la pasa a `confirmada`, limpia su fecha de vencimiento y deja el cambio auditado con usuario y fecha. | HU-17 | `fn_confirmar_reserva` e `historial_reserva` | Vigente |
| RN-RES-08 | Una solicitud vencida no puede confirmarse; el intento la marca como `vencida` y audita el intento. El cliente debe registrar una nueva si la salida sigue disponible. | HU-17 | `fn_confirmar_reserva` | Vigente |
| RN-RES-09 | El barrido de las solicitudes pendientes fuera de plazo las pasa a `vencida` y deja el cambio auditado con la cuenta que lo corrió; es limpieza, porque el cupo ya se liberó por cálculo. Lo ejecuta el cron diario y también el personal desde la bandeja de solicitudes, sin esperar al cron. | HU-17 | `fn_vencer_solicitudes_pendientes`, el cron `vencer-solicitudes` y `POST /api/reservas/vencer` | Vigente |
| RN-RES-10 | La reserva nace auditada: `historial_reserva` registra la creación con su canal y el usuario que la firmó. En el canal web firma la cuenta del cliente; en el personal, la cuenta del trabajador. | HU-06, HU-17 | `historial_reserva`, API de reservas | Vigente |
| RN-RES-11 | El canal web no crea fichas: la solicitud usa la ficha vinculada a la cuenta del cliente, y el registro de la ficha corresponde al registro de la cuenta (RN-USU-03). | HU-06, HU-15 | API de reservas | Vigente |
| RN-RES-12 | Solo una cotización aceptada del mismo cliente y de la misma salida puede originar una reserva, y el vínculo es único. | HU-06 | API de reservas y `reserva.id_cotizacion` | Vigente |
| RN-RES-13 | La consulta del personal muestra las solicitudes de ambos canales con su cliente, su salida, su monto, su vencimiento y el estado de su anticipo, con filtro por estado. | HU-17 | API `GET /api/reservas` e interfaz «Solicitudes» | Vigente |
| RN-RES-14 | La reserva no se elimina nunca: el cliente solicita la cancelación de una reserva `pendiente` o `confirmada` y el personal la ejecuta con motivo y fecha; las reservas `vencida`, `cancelada` y `finalizada` no se modifican. | HU-13, HU-07 | `fn_solicitar_cancelacion` y `fn_ejecutar_cancelacion` | Vigente |
| RN-RES-15 | Una solicitud del canal web admite como máximo 4 pasajeros; los grupos mayores se atienden por la oficina, en el canal personal, que no tiene ese tope. | Decisión del proyecto | `fn_crear_reserva`, Zod e interfaz | Vigente |
| RN-RES-16 | Las solicitudes web pendientes vigentes de una misma salida no retienen en conjunto más del 70% de los cupos disponibles: los cupos aún no confirmados ni retenidos por el canal personal, con un mínimo de 1 cupo solicitable por web mientras haya capacidad. Alcanzado el tope, nuevas solicitudes web se rechazan hasta que el personal confirme o venza alguna. Los pendientes web no suman a la base porque son justamente lo que se limita, y las pendientes del canal personal no cuentan para el tope. La retención se comprueba al crear y también al modificar una reserva del canal web, con el manifiesto incluido. | Decisión del proyecto | `fn_crear_reserva` y `fn_revalidar_reserva` | Vigente |
| RN-RES-17 | Reservar por el canal web exige una sesión de `CLIENTE` con ficha activa vinculada. Sin sesión, la interfaz redirige a ingresar o crear cuenta; la API responde 401. | HU-15, HU-06 | API de reservas, middleware e interfaz | Vigente |
| RN-RES-18 | Confirmar una solicitud exige un anticipo validado que cumpla el mínimo (RN-PAG-01); la base lo exige en `fn_confirmar_reserva` y no admite confirmar sin pago. | HU-17, HU-14 | `fn_confirmar_reserva` | Vigente |
| RN-RES-19 | Confirmar una reserva exige el manifiesto completo: los pasajeros registrados en ella igualan su cantidad declarada. El manifiesto se llena antes de confirmar. | HU-12, HU-17 | `fn_confirmar_reserva` e `historial_reserva` | Vigente |
| RN-RES-20 | Solo una reserva `pendiente` o `confirmada` se modifica. Cambiar la salida o la cantidad vuelve a verificar los cupos dentro de una transacción que bloquea la salida; el monto se recalcula con el precio vigente de la salida por la cantidad nueva, y los pagos no anulados no pueden quedar por encima del nuevo total. Cada cambio queda en el historial con los valores anterior y nuevo. | HU-07 | `fn_actualizar_reserva` y `fn_guardar_manifiesto` | Vigente |
| RN-RES-21 | El manifiesto es la lista de pasajeros de la reserva, con documento único por persona. Al guardarlo, la cantidad declarada pasa a ser la cantidad de pasajeros registrados, con la misma verificación de cupos. En el canal web el manifiesto no declara más pasajeros que los solicitados: el cliente puede reducir su grupo, no ampliarlo; el canal personal sí puede ampliarlo. | HU-12 | `fn_guardar_manifiesto` | Vigente |
| RN-RES-22 | Cuando cambia la fecha o la capacidad de una salida, cada cliente con reserva `pendiente` o `confirmada` en ella ve un aviso con el valor anterior, el nuevo y la fecha del cambio, derivado del historial de la salida. El aviso no cambia el estado de la reserva y no lo ve nadie más. | HU-16 | `historial_salida` y API de avisos | Vigente |

### 13.1 Máquina de estados de la reserva

```text
pendiente ──▶ confirmada ──▶ finalizada
    │
    └──────▶ vencida
```

- `pendiente → confirmada`: la hace el personal dentro del plazo, con el
  anticipo validado exigido por RN-RES-18, y audita.
- `pendiente → vencida`: la hacen el intento de confirmación fuera de plazo
  o el barrido (cron o bandeja del personal); es la única transición
  automática de estado.
- `confirmada → finalizada`: la hace la salida que pasa a `realizada`
  (T-HU-07.4); el viaje se concretó y la reserva queda con su historial.
- `cancelada`: llega con el módulo de cancelaciones (HU-13); cualquier
  otro cambio de estado está rechazado.

## 14. Pagos

El pago emula la transacción con una pasarela simulada: registra la
referencia y el estado del cobro, sin mover dinero real. La validación
sigue siendo del personal: un pago del cliente no cuenta hasta que se
comprueba.

| ID | Regla | Fuente | Aplicación | Estado |
|---|---|---|---|---|
| RN-PAG-01 | El primer anticipo de la reserva no puede ser menor al 30% del monto total. Puede cubrir la totalidad: pagar todo de una vez se registra como un anticipo por el monto completo. Los anticipos adicionales, que respaldan un total que creció con el manifiesto, solo respetan el saldo pendiente. | HU-14 | `fn_registrar_pago`, Zod e interfaz | Vigente |
| RN-PAG-02 | Por reserva puede haber varios pagos de cada tipo: la restricción ya no limita uno por tipo y el tope real es el saldo pendiente, que `fn_registrar_pago` aplica. | HU-14 | `fn_registrar_pago` y API | Vigente |
| RN-PAG-03 | Por la web se paga con `banca_movil` o `qr`, con referencia generada por la pasarela simulada. En la oficina se registra con `efectivo`, `transferencia`, `tarjeta` u `otro`. | HU-14 | `ck_pago_metodo` y módulo de pagos | Vigente |
| RN-PAG-04 | Los pagos que registra el personal nacen `validado`; los que registra el cliente nacen `registrado` y no suman al abonado hasta que el personal los valide o los anule. | HU-14 | `fn_registrar_pago` y `fn_validar_pago` | Vigente |
| RN-PAG-05 | Ningún pago supera el saldo pendiente de la reserva. El saldo puede pagarse por partes: cada pago reduce el pendiente y pueden sumarse varios hasta cubrirlo. Solo pagos `validado` reducen el saldo mostrado. | HU-14 | `fn_registrar_pago` e interfaz | Vigente |
| RN-PAG-06 | Solo las reservas `pendiente` o `confirmada` admiten pagos; las `vencida`, `cancelada` y `finalizada` no. | HU-14 | `fn_registrar_pago` | Vigente |
| RN-PAG-07 | La devolución por cancelación del cliente sigue tramos sobre lo abonado validado: a 15 días o más de la salida, el 100%; entre 8 y 14 días, el 50%; con 7 días o menos, o inasistencia, nada. Si la cancela la agencia o la solicitud vence sin confirmarse por falta de atención, se devuelve el 100%. La ejecución queda fuera del sistema; los lineamientos se muestran al cliente antes de pagar. | HU-13, HU-14 | Política documentada e interfaz de pagos | Vigente |
| RN-PAG-08 | Confirmar una reserva exige el anticipo validado del mínimo (RN-RES-18); el pago por sí solo no confirma nada. | HU-14, HU-17 | `fn_confirmar_reserva` | Vigente |

### 14.1 Máquina de estados del pago

```text
registrado ──▶ validado
     │
     └──────▶ anulado
```

- `registrado`: nace así el pago del cliente por la web.
- `validado`: lo marca el personal, con su usuario y fecha; solo entonces
  suma al total abonado y habilita la confirmación si es el anticipo.
- `anulado`: lo marca el personal cuando el cobro no se corresponde; deja
  de comprometer el saldo pendiente.

## 15. Reglas pendientes de otros módulos

Se documentan aquí para que no se pierdan, pero no se implementan en esta
iteración:

- **Reservas:** reutilizar un pasajero entre fichas de clientes distintos
  (hoy el manifiesto se arma dentro de la ficha del cliente de la
  reserva); aviso al cliente cuando el personal mueve su reserva de
  salida (hoy lo ve en Mis reservas por el cambio de salida y fecha).
- **Pagos:** ejecución y registro de las devoluciones del catálogo (RN-PAG-07);
  pasarela real en lugar de la simulada.
- **Proveedores:** permitir varios tipos del mismo proveedor en un mismo
  paquete; hoy el vínculo guarda un solo tipo y su costo.
- **Roles:** resolver `ADMIN`, `PERSONAL` y `CLIENTE` por `codigo` en lugar
  de depender de los identificadores fijos de la semilla.

## 16. Reportes

| ID | Regla | Fuente | Aplicación | Estado |
|---|---|---|---|---|
| RN-REP-01 | El reporte se filtra por periodo de fecha de salida y, de forma opcional, por paquete. | HU-11 | API de reportes e interfaz «Reportes» | Vigente |
| RN-REP-02 | Por salida muestra la capacidad, los pasajeros pendientes y confirmados, los cupos libres y la cantidad de reservas por estado; las vencidas y las canceladas se informan sin ocupar cupo. | HU-11 | `vista_reservas_por_fecha` | Vigente |
| RN-REP-03 | El reporte distingue las reservas de la atención del personal de las solicitudes del cliente, con conteos por canal. | HU-11 | `vista_reservas_por_fecha` | Vigente |
| RN-REP-04 | Solo el personal y el administrador consultan el reporte. | HU-11 | API e interfaz | Vigente |

## 17. Gobierno del catálogo

1. Una regla nueva se propone aquí con su ID y su fuente.
2. Se decide si se implementa en la base, en la API, en la interfaz o en un
   proceso manual.
3. Se actualizan `bd/esquema.sql`, `web/db/schema.ts`, los tipos, Zod, la
   interfaz y las pruebas.
4. Se agrega el caso de éxito y el caso de error.
5. Se actualiza la historia de usuario y la trazabilidad.
6. Se registra el trabajo aceptado en `docs/changelog/`.

## 18. Decisiones abiertas

- ¿El catálogo de servicios y el de lugares se podrán editar desde la
  administración o seguirán siendo una semilla fija?
- ¿La duración se expresa solo en días o también en noches?
- ¿Se agregará hora de salida y hora de encuentro a la salida?
- ¿La cancelación de una salida con reservas vigentes las cancela o las
  reprograma?
