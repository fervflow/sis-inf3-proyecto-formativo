# Reglas de negocio

Catálogo canónico de las reglas de negocio del sistema web de gestión de
paquetes turísticos y reservas de Vizcacha Tours. **No forma parte de
`main.tex`**: es documentación de trabajo.

- **Alcance de esta versión:** catálogo, paquetes turísticos y salidas.
- **Fuera de alcance por ahora:** reservas, pagos, cotizaciones, pasajeros,
  proveedores y avisos. Cada módulo tendrá su propia ampliación del catálogo.
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
7. Las pruebas de paquetes y salidas están en
   `bd/pruebas/reglas-paquetes.sql`; se ejecutan con `make db-probar` y
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
| HU-02 · Fechas de salida y cupos | RN-SAL-01 a RN-SAL-08 |
| HU-03 · Consulta de disponibilidad | RN-SAL-17 a RN-SAL-19 |
| HU-09 · Modificar fechas o capacidad | RN-SAL-09 a RN-SAL-16 |
| HU-08 · Acceso por rol | RN-USU-01, RN-USU-02 |

## 10. Reglas de usuarios y roles del alcance

| ID | Regla | Fuente | Aplicación | Estado |
|---|---|---|---|---|
| RN-USU-01 | Los roles son `ADMIN`, `PERSONAL` y `CLIENTE`. El código `TURISTA` queda obsoleto. | Decisión del proyecto | `rol.codigo`, tipos y textos | Vigente |
| RN-USU-02 | Un usuario `CLIENTE` debe tener una ficha de cliente; una ficha puede existir sin cuenta. | HU-15, HU-04 | Pendiente: módulo de cuentas de cliente | Propuesta |

## 11. Reglas pendientes de otros módulos

Se documentan aquí para que no se pierdan, pero no se implementan en esta
iteración:

- **Reservas:** manifiesto completo al confirmar; historial de cambios de
  datos; transición a `finalizada`; cotización coherente; actor «sistema» en
  vencimientos.
- **Pagos:** no superar el total; estado de la reserva; orden anticipo/saldo;
  `total_pagado` solo con validados; métodos `banca_movil` y `qr`.
- **Cotizaciones:** vencimiento automático, condiciones, numeración y
  coherencia con la reserva.
- **Pasajeros:** pasajero reutilizable entre reservas; conteo exacto al
  confirmar.
- **Proveedores:** PK que permita varios servicios del mismo proveedor;
  proveedor inactivo no se vincula.
- **Avisos:** cambios de fecha o capacidad de una salida (HU-16).
- **Cuentas de cliente:** alta, vínculo con la ficha y restricción a
  información propia. Mientras HU-15 no esté implementada, el panel de
  usuarios permite crear un `CLIENTE` sin ficha; es una brecha conocida.
- **Roles:** resolver `ADMIN`, `PERSONAL` y `CLIENTE` por `codigo` en lugar
  de depender de los identificadores fijos de la semilla.

## 12. Gobierno del catálogo

1. Una regla nueva se propone aquí con su ID y su fuente.
2. Se decide si se implementa en la base, en la API, en la interfaz o en un
   proceso manual.
3. Se actualizan `bd/esquema.sql`, `web/db/schema.ts`, los tipos, Zod, la
   interfaz y las pruebas.
4. Se agrega el caso de éxito y el caso de error.
5. Se actualiza la historia de usuario y la trazabilidad.
6. Se registra el trabajo aceptado en `docs/changelog/`.

## 13. Decisiones abiertas

- ¿El catálogo de servicios y el de lugares se podrán editar desde la
  administración o seguirán siendo una semilla fija?
- ¿La duración se expresa solo en días o también en noches?
- ¿Se agregará hora de salida y hora de encuentro a la salida?
- ¿La cancelación de una salida con reservas vigentes las cancela o las
  reprograma?
