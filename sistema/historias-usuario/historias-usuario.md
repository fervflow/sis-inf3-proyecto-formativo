# Historias de usuario

Documento de trabajo **paralelo al informe**. No forma parte de `main.tex`
ni de la compilación LaTeX: se conserva como respaldo de la planificación
del sistema web de gestión de paquetes turísticos y reservas.

- **Materia:** Sistemas de Información III — Ingeniería de Sistemas
- **Universidad:** Universidad Privada Domingo Savio (UPDS), Sede Potosí
- **Registro:** 17 de noviembre de 2026
- **Fuente de datos:** `sistema/historias-usuario/historias-usuario.csv`
- **Alcance del sistema considerado:** sistema web de gestión de reservas de
  Vizcacha Tours con dos canales de atención, la atención del personal y el
  acceso directo del cliente, que desembocan en el mismo proceso validado.

## Backlog

El CSV conserva los campos tabulares de cada historia. Este documento agrega
el enunciado completo, los criterios de aceptación y las observaciones de
revisión.

| ID | Historia de usuario | Actor | Canal | Prioridad | Riesgo | Estimación | N° tareas |
|---|---|---|---|---|---|---|---|
| HU-08 | Iniciar sesión y acceder según el rol | Personal, Cliente | Web | Alta | Alto | 3 pts | 3 tareas |
| HU-15 | Abrir una cuenta de cliente y acceder a su información | Cliente | Web | Media | Alto | 3 pts | 3 tareas |
| HU-01 | Gestión de paquetes turísticos | Administrador | Web | Alta | Medio | 3 pts | 2 tareas |
| HU-02 | Registro de fechas de salida y cupos | Administrador | Web | Alta | Alto | 2 pts | 2 tareas |
| HU-03 | Consulta de disponibilidad | Cliente, Personal | Web, Oficina | Alta | Medio | 2 pts | 2 tareas |
| HU-04 | Registro y actualización de la ficha del cliente | Personal | Web, Oficina | Media | Medio | 2 pts | 2 tareas |
| HU-10 | Registrar proveedores y vincularlos a los paquetes | Administrador | Web | Media | Bajo | 2 pts | 2 tareas |
| HU-05 | Elaboración de cotizaciones | Personal | Web, Oficina | Baja | Medio | 3 pts | 2 tareas |
| HU-06 | Registro de reservas con validación de cupos | Personal, Cliente | Web, Oficina | Alta | Alto | 5 pts | 3 tareas |
| HU-12 | Registro de pasajeros y vinculación a una reserva | Personal, Cliente | Web | Media | Medio | 3 pts | 2 tareas |
| HU-07 | Seguimiento y actualización de reservas | Personal | Web | Media | Medio | 3 pts | 3 tareas |
| HU-17 | Confirmación de solicitudes y control de su vencimiento | Personal | Web | Alta | Alto | 3 pts | 3 tareas |
| HU-09 | Modificar fechas o capacidad de una salida | Administrador | Web | Media | Alto | 3 pts | 2 tareas |
| HU-11 | Consultar reportes de ocupación y reservas por fecha | Personal | Web | Baja | Medio | 2 pts | 2 tareas |
| HU-13 | Solicitud y ejecución de la cancelación de una reserva | Cliente, Personal | Web, Oficina | Media | Alto | 3 pts | 2 tareas |
| HU-14 | Registro y validación de anticipos y saldos de una reserva | Cliente, Personal | Web, Oficina | Alta | Medio | 3 pts | 2 tareas |
| HU-16 | Avisos de cambios de fecha y capacidad de una salida | Cliente | Web | Baja | Medio | 2 pts | 2 tareas |
| **TOTAL** | **17 historias de usuario** | | | | | **47 pts** | **39 tareas** |

## Criterio de prioridades

La prioridad mide cuánto sostiene el flujo mínimo de reservas, no el
esfuerzo ni el riesgo. Una historia con riesgo alto puede quedar en
prioridad media si el MVP puede resolverla de forma manual.

| Prioridad | Criterio | Historias |
|---|---|---|
| Alta | Sostiene el flujo mínimo: acceso, catálogo, salida con cupo, disponibilidad, reserva, confirmación y pago. Sin estas historias no hay proceso validado. | HU-08, HU-01, HU-02, HU-03, HU-06, HU-17, HU-14 |
| Media | Necesaria para operar, pero se puede resolver después del flujo mínimo o de forma manual durante el MVP. | HU-15, HU-04, HU-10, HU-12, HU-07, HU-09, HU-13 |
| Baja | Complementaria o fuera del alcance inmediato: cotizaciones, reportes y avisos por correo. | HU-05, HU-11, HU-16 |

La distribución queda en 7 historias de prioridad alta, 7 de prioridad
media y 3 de prioridad baja.

## Actores

| Actor | Rol en el sistema | Historias |
|---|---|---|
| Cliente (turista) | Cuenta propia. Consulta, solicita reservas, registra pagos y solicita cancelaciones. Solo accede a su propia información. | HU-03, HU-06, HU-08, HU-12, HU-13, HU-14, HU-15, HU-16 |
| Personal de agencia | Agentes de atención y ventas, responsables de operaciones y personal de apoyo administrativo. Confirma reservas, valida pagos, ejecuta cancelaciones y responde consultas. | HU-01, HU-02, HU-03, HU-04, HU-05, HU-06, HU-07, HU-08, HU-10, HU-11, HU-12, HU-13, HU-14, HU-17 |
| Administrador | Gestiona usuarios, paquetes, salidas, proveedores y reportes. | HU-01, HU-02, HU-07, HU-09, HU-10, HU-11, HU-15, HU-17 |

## Enunciado de las historias

| ID | Enunciado |
|---|---|
| HU-08 | Como usuario del sistema, quiero iniciar sesión y entrar según mi rol, para acceder solo a las funciones y a los datos que me corresponden. |
| HU-15 | Como cliente, quiero abrir una cuenta con mis datos de identificación, para consultar paquetes, solicitar reservas y seguir mis solicitudes sin pasar por la oficina. |
| HU-01 | Como administrador, quiero registrar y mantener los paquetes turísticos, para que el personal y el cliente consulten una oferta vigente y única. |
| HU-02 | Como administrador, quiero programar las salidas con su fecha y su capacidad, para que exista un cupo real que se pueda vender. |
| HU-03 | Como cliente, quiero consultar los paquetes y los cupos disponibles, para elegir una salida sin recibir información desactualizada. |
| HU-04 | Como personal, quiero registrar y actualizar la ficha del cliente, para atender sus solicitudes con datos completos. |
| HU-05 | Como personal, quiero elaborar cotizaciones con precio, plazo y condiciones, para formalizar la propuesta económica antes de reservar. |
| HU-06 | Como personal o como cliente, quiero registrar una reserva con validación de cupos, para obtener un registro que nunca exceda la capacidad de la salida. |
| HU-07 | Como personal, quiero consultar el historial y actualizar los datos de una reserva, para dar seguimiento verificable a cada cambio. |
| HU-09 | Como administrador, quiero modificar la fecha o la capacidad de una salida, para corregir el programa sin dejar reservas sin respaldo. |
| HU-10 | Como administrador, quiero registrar proveedores y vincularlos a los paquetes, para que cada paquete tenga sus servicios identificados. |
| HU-11 | Como personal, quiero consultar reportes de ocupación y reservas por fecha, para responder con datos actualizados. |
| HU-12 | Como personal o como cliente, quiero registrar los pasajeros y vincularlos a una reserva, para que el cupo reservado corresponda a personas identificadas. |
| HU-13 | Como cliente, quiero solicitar la cancelación de mi reserva, para que el personal la ejecute aplicando el mismo criterio y libere el cupo. |
| HU-14 | Como cliente, quiero registrar mi anticipo o mi saldo, y como personal, quiero validarlo, para que la reserva quede con respaldo verificado. |
| HU-16 | Como cliente, quiero recibir aviso de los cambios de fecha o de capacidad de mi salida, para enterarme a tiempo y organizar mi viaje. |
| HU-17 | Como personal, quiero ver las solicitudes pendientes y confirmarlas dentro del plazo, para que ningún cupo quede bloqueado por una solicitud sin atender. |

## Criterios de aceptación

Las 17 historias tienen criterios de aceptación redactados. Se ordenan como el
backlog y cada criterio se apoya en las reglas de negocio ya reflejadas en el
esquema de la base de datos, de modo que las historias no exijan nada que el
sistema no pueda cumplir.

### HU-08 · Iniciar sesión y acceder según el rol

- El sistema reconoce tres roles: administrador, personal de agencia y
  cliente.
- Un cliente solo ve sus propias reservas, pagos y solicitudes; no accede a
  la información de otros clientes ni a los módulos administrativos.
- El personal accede a los módulos de operación según su rol.
- Las cuentas se pueden desactivar o bloquear sin borrar su historial.
- El acceso se registra con fecha, hora y usuario.

### HU-15 · Abrir una cuenta de cliente y acceder a su información

- La cuenta se crea con correo, tipo y número de documento, nombre y
  teléfono; el documento no puede repetirse.
- Un cliente puede tener como máximo una cuenta vinculada a su ficha.
- La ficha del cliente puede existir sin cuenta: el personal sigue atendiendo
  a quien no se registra.
- El cliente ve sus reservas, sus pagos y el estado de sus solicitudes, y
  ninguna otra información.
- La cuenta puede bloquearse si se detectan solicitudes repetidas o un uso
  indebido del sistema.

### HU-01 · Gestión de paquetes turísticos

- El paquete se registra con código único, nombre, destino, descripción,
  duración e itinerario.
- El precio es un número mayor que cero y el código del paquete no se repite.
- El paquete tiene estados borrador, activo e inactivo; solo el activo se
  ofrece en la consulta del cliente y admite salidas.
- Los servicios del paquete son los proveedores que se vinculan a él.
- Un paquete con salidas o reservas asociadas no se elimina: pasa a inactivo
  y conserva su historial.
- El mantenimiento corresponde al administrador; el personal y el cliente solo
  consultan los paquetes activos.

### HU-02 · Registro de fechas de salida y cupos

- Cada salida pertenece a un paquete y tiene fecha de salida, fecha de
  retorno, capacidad y precio.
- La capacidad es un número entero positivo y la fecha de retorno no es
  anterior a la de salida.
- Una salida modificada no puede quedar con capacidad menor que la cantidad
  de pasajeros ya reservados.
- Cada cambio de fecha, capacidad, precio o estado queda auditado.

### HU-03 · Consulta de disponibilidad

- La consulta muestra los paquetes activos con sus salidas programadas o
  confirmadas y el cupo disponible de cada una.
- El cupo se calcula en el momento de la consulta como la capacidad menos los
  pasajeros de las reservas pendientes y confirmadas; las vencidas y las
  canceladas no se cuentan.
- La web del cliente y la consulta en oficina devuelven el mismo resultado,
  porque ambos provienen de la misma vista de disponibilidad.
- El cliente ve el total disponible y nunca la identidad de los pasajeros; el
  personal ve además el desglose de pendientes y confirmados.
- Una salida sin cupo disponible se muestra como agotada y no admite una
  solicitud de reserva.

### HU-04 · Registro y actualización de la ficha del cliente

- La ficha se registra con tipo y número de documento, nombre y teléfono; el
  documento no puede repetirse.
- Al ingresar un documento ya existente, el sistema muestra la ficha vigente
  en lugar de crear otra.
- La ficha puede existir sin cuenta de usuario: el personal sigue atendiendo a
  quien no se registra en el sistema.
- Vincular una cuenta a la ficha no la duplica ni altera sus reservas, pagos y
  solicitudes.
- La ficha no se elimina: se marca como inactiva y conserva su historial.
- Solo el personal de agencia registra y actualiza fichas; el cliente accede
  a la suya mediante su cuenta.

### HU-10 · Registrar proveedores y vincularlos a los paquetes

- El proveedor se registra con nombre o razón social, tipo (transporte,
  hospedaje, guía u otro), datos de contacto y estado.
- El tipo del proveedor está restringido a las categorías definidas por el
  sistema.
- Un proveedor puede vincularse a varios paquetes y un paquete puede tener
  varios proveedores; el vínculo no se repite.
- El paquete muestra los servicios que lo identifican y el proveedor muestra
  los paquetes que atiende.
- Un proveedor con vínculos no se elimina: pasa a inactivo y conserva sus
  datos.
- El mantenimiento de proveedores y de sus vínculos corresponde al
  administrador.

### HU-05 · Elaboración de cotizaciones

- La cotización se prepara a partir de un cliente y una salida, con número
  único y fecha de emisión.
- El importe se calcula con el precio de la salida y la cantidad de
  pasajeros, y se muestra junto con los servicios incluidos.
- La cotización declara su plazo de validez y sus condiciones; vencido el
  plazo, pasa al estado vencida.
- La cotización no descuenta cupo ni crea reserva: el cupo de la salida no
  cambia al prepararla.
- Una cotización aceptada puede originar una reserva, que guarda el vínculo
  con ella; una sola reserva puede referirse a esa cotización.
- El personal prepara, consulta y cambia el estado de las cotizaciones:
  borrador, enviada, aceptada o rechazada.

### HU-06 · Registro de reservas con validación de cupos

- La reserva se crea en estado pendiente en los dos canales; la atención del
  personal y la solicitud del cliente se distinguen por el campo de origen.
- La validación de cupos se ejecuta dentro de una transacción que bloquea la
  fila de la salida, de modo que dos registros simultáneos no puedan superar
  la capacidad.
- El cupo se calcula sobre las reservas pendientes y confirmadas; las
  vencidas y las canceladas no se cuentan.
- El cliente puede tener una sola solicitud pendiente por salida; una
  necesidad adicional se gestiona modificando la solicitud existente.
- Toda reserva pendiente tiene fecha de vencimiento a 48 horas de su
  creación.
- El registro de los pasajeros coincide con la cantidad declarada en la
  reserva.

### HU-12 · Registro de pasajeros y vinculación a una reserva

- El pasajero se registra con nombre y documento; el documento no puede
  repetirse.
- El pasajero puede ser el propio cliente o un acompañante, y se vincula a la
  reserva mediante la reserva y el pasajero.
- La cantidad de pasajeros de la reserva coincide con el número de pasajeros
  registrados en ella; una reserva no se confirma con la cantidad
  desajustada.
- Un mismo pasajero no se registra dos veces en la misma reserva, aunque sí
  puede viajar en reservas distintas.
- El cliente solo registra pasajeros en sus propias reservas.
- Los cambios en la lista de pasajeros se reflejan de inmediato en la
  cantidad declarada de la reserva.

### HU-07 · Seguimiento y actualización de reservas

- La consulta muestra las reservas de ambos canales con su estado, su origen,
  el cliente, la salida y su fecha de vencimiento, con filtros por fecha,
  estado y canal.
- Confirmar una reserva pendiente la pasa a confirmada, limpia su fecha de
  vencimiento y queda auditado.
- Modificar la cantidad de pasajeros o la salida vuelve a verificar los cupos
  dentro de la misma transacción; si la modificación excede la capacidad, se
  rechaza y la reserva queda sin cambios.
- La cantidad de pasajeros de la reserva coincide en todo momento con el
  número de pasajeros registrados en ella.
- Una reserva vencida, cancelada o finalizada no se modifica; para cambiar sus
  datos se registra una nueva reserva.
- Cada cambio de estado o de datos queda en el historial de la reserva con el
  usuario, la fecha y los valores anterior y nuevo.

### HU-17 · Confirmación de solicitudes y control de su vencimiento

- El personal ve una lista de solicitudes pendientes de ambos canales con su
  fecha de vencimiento.
- Confirmar una solicitud cambia su estado a confirmada, limpia la fecha de
  vencimiento y queda auditado.
- Una solicitud no confirmada dentro del plazo pasa a vencida y libera los
  cupos de forma automática.
- Una solicitud vencida no puede confirmarse después; el cliente debe
  registrar una nueva solicitud si la salida sigue disponible.

### HU-09 · Modificar fechas o capacidad de una salida

- La modificación se ejecuta dentro de una transacción que bloquea la salida.
- La nueva capacidad no puede ser menor que los pasajeros de las reservas
  pendientes y confirmadas.
- Un cambio de fecha no rompe el vínculo de las reservas existentes con la
  salida.
- El cambio queda auditado con el valor anterior y el nuevo, y se comunica a
  los clientes afectados.

### HU-11 · Consultar reportes de ocupación y reservas por fecha

- El reporte se filtra por fecha o por periodo y, de forma opcional, por
  paquete.
- Por salida muestra la capacidad, los pasajeros pendientes, los confirmados,
  los cupos libres y la cantidad de reservas por estado.
- Las reservas vencidas y canceladas se informan en el reporte, pero no
  ocupan cupo.
- Las cifras del reporte coinciden con la consulta de disponibilidad, porque
  ambas parten de la misma vista.
- El reporte distingue las reservas de la atención del personal de las
  solicitudes del cliente.
- Solo el personal de agencia y el administrador consultan el reporte.

### HU-13 · Solicitud y ejecución de la cancelación de una reserva

- El cliente puede solicitar la cancelación de una reserva propia que no
  esté finalizada; la solicitud no modifica el estado por sí sola.
- El personal ejecuta la cancelación, indica el motivo y la fecha.
- La cancelación es lógica: la reserva conserva su historial y los cupos se
  liberan por cálculo, sin eliminar registros.
- La devolución del dinero se gestiona fuera del sistema y no se registra
  como un nuevo pago.
- Los cambios de estado quedan auditados con el usuario que los ejecutó.

### HU-14 · Registro y validación de anticipos y saldos de una reserva

- El pago se registra con tipo (anticipo o saldo), importe mayor que cero,
  fecha, método y concepto.
- Solo puede existir un anticipo y un saldo por reserva; un segundo pago del
  mismo tipo se rechaza.
- El pago registrado por el cliente desde su cuenta queda en estado registrado
  y no cuenta como abonado hasta que el personal lo valida.
- El personal valida o anula el pago, dejando el usuario y la fecha de la
  validación; solo los pagos validados suman al total abonado.
- El saldo pendiente se calcula como el importe total de la reserva menos los
  pagos validados.
- La consulta del saldo muestra el total abonado, el saldo pendiente y el
  historial de pagos con su estado.

### HU-16 · Avisos de cambios de fecha y capacidad de una salida

- Cuando cambia la fecha o la capacidad de una salida, el sistema genera un
  aviso para cada reserva pendiente o confirmada de esa salida.
- El aviso muestra el valor anterior y el nuevo, la salida y la fecha del
  cambio.
- El aviso se deriva del historial de cambios de la salida y se muestra en las
  pantallas del cliente, sin ser un registro independiente.
- Solo el cliente afectado ve el aviso; ningún otro cliente accede a avisos
  ajenos.
- El aviso no cambia el estado de la reserva ni la confirma por sí solo.
- Las reservas canceladas y vencidas no generan aviso.

## Desglose de tareas

Las 39 tareas se detallan por historia, en el orden del backlog. Cada tarea
hereda los criterios de aceptación de su historia y la prioridad y el riesgo
de esa historia. El responsable indicado corresponde al reparto de trabajo
entre los dos programadores: 20 tareas para el programador A y 19 para el
programador B.

En el tablero, el programador A aparece como **EV** y el programador B como
**RE**.

### HU-08 · Iniciar sesión y acceder según el rol

**Responsable:** Programador A · **3 tareas** · **Criterios:** los de HU-08

- **T-HU-08.1** Crear el inicio de sesión y validar las credenciales.
- **T-HU-08.2** Aplicar permisos de administrador y personal de
  ventas/reservas.
- **T-HU-08.3** Comprobar accesos válidos, inválidos y sin autorización.

### HU-15 · Abrir una cuenta de cliente y acceder a su información

**Responsable:** Programador B · **3 tareas** · **Criterios:** los de HU-15

- **T-HU-15.1** Registrar la cuenta del cliente con correo, documento, nombre
  y teléfono, sin repetir el documento ni duplicar la ficha.
- **T-HU-15.2** Vincular la cuenta con la ficha del cliente y mostrarle solo
  sus reservas, sus pagos y el estado de sus solicitudes.
- **T-HU-15.3** Comprobar el acceso del cliente, el bloqueo de la cuenta y la
  restricción a información ajena.

### HU-01 · Gestión de paquetes turísticos

**Responsable:** Programador A · **2 tareas** · **Criterios:** los de HU-01

- **T-HU-01.1** Registrar y editar paquetes con destino, itinerario,
  servicios y precio.
- **T-HU-01.2** Mostrar el listado y validar campos obligatorios y precios.

### HU-02 · Registro de fechas de salida y cupos

**Responsable:** Programador A · **2 tareas** · **Criterios:** los de HU-02

- **T-HU-02.1** Registrar las fechas de salida y la capacidad de cada
  paquete.
- **T-HU-02.2** Validar cupos positivos y evitar salidas duplicadas.

### HU-03 · Consulta de disponibilidad

**Responsable:** Programador A · **2 tareas** · **Criterios:** los de HU-03

- **T-HU-03.1** Consultar cupos por paquete y fecha de salida, desde la web o
  en la oficina.
- **T-HU-03.2** Calcular los disponibles descontando las reservas pendientes
  y confirmadas, y comprobar el resultado.

### HU-04 · Registro y actualización de la ficha del cliente

**Responsable:** Programador B · **2 tareas** · **Criterios:** los de HU-04

- **T-HU-04.1** Registrar clientes con documento y datos de contacto,
  evitando duplicados.
- **T-HU-04.2** Consultar y actualizar la información de los clientes.

### HU-10 · Registrar proveedores y vincularlos a los paquetes

**Responsable:** Programador B · **2 tareas** · **Criterios:** los de HU-10

- **T-HU-10.1** Registrar, consultar y editar proveedores de servicios.
- **T-HU-10.2** Vincular uno o varios proveedores a los paquetes turísticos.

### HU-05 · Elaboración de cotizaciones

**Responsable:** Programador B · **2 tareas** · **Criterios:** los de HU-05

- **T-HU-05.1** Seleccionar cliente y paquete y calcular el precio de la
  cotización.
- **T-HU-05.2** Mostrar servicios, importe y condiciones, sin descontar
  cupos.

### HU-06 · Registro de reservas con validación de cupos

**Responsable:** Programador A · **3 tareas** · **Criterios:** los de HU-06

- **T-HU-06.1** Crear una reserva desde la atención del personal o como
  solicitud del cliente, con su origen, el cliente, la salida y la cantidad
  de pasajeros.
- **T-HU-06.2** Verificar los cupos antes de guardar y rechazar las reservas
  que excedan la capacidad.
- **T-HU-06.3** Guardar la reserva en estado pendiente con su fecha de
  vencimiento y reflejar la ocupación en la disponibilidad.

### HU-12 · Registro de pasajeros y vinculación a una reserva

**Responsable:** Programador B · **2 tareas** · **Criterios:** los de HU-12

- **T-HU-12.1** Registrar los pasajeros asociados a cada reserva, incluido el
  cliente si viaja.
- **T-HU-12.2** Validar los datos y que la cantidad de pasajeros coincida con
  la reserva.

### HU-07 · Seguimiento y actualización de reservas

**Responsable:** Programador A · **3 tareas** · **Criterios:** los de HU-07

- **T-HU-07.1** Consultar las reservas de ambos canales, su estado y su
  fecha de vencimiento.
- **T-HU-07.2** Confirmar o modificar reservas y volver a verificar los cupos.
- **T-HU-07.3** Conservar los cambios realizados para su seguimiento.

### HU-17 · Confirmación de solicitudes y control de su vencimiento

**Responsable:** Programador A · **3 tareas** · **Criterios:** los de HU-17

- **T-HU-17.1** Listar las solicitudes pendientes de ambos canales con su
  fecha de vencimiento.
- **T-HU-17.2** Confirmar la solicitud, limpiar el vencimiento y auditar el
  cambio.
- **T-HU-17.3** Vencer las solicitudes fuera de plazo, liberar los cupos y
  rechazar su confirmación posterior.

### HU-09 · Modificar fechas o capacidad de una salida

**Responsable:** Programador A · **2 tareas** · **Criterios:** los de HU-09

- **T-HU-09.1** Editar la fecha o capacidad e identificar las reservas
  asociadas.
- **T-HU-09.2** Advertir excesos de cupos y marcar reservas afectadas sin
  borrarlas.

### HU-11 · Consultar reportes de ocupación y reservas por fecha

**Responsable:** Programador B · **2 tareas** · **Criterios:** los de HU-11

- **T-HU-11.1** Consultar el reporte filtrado por fecha o periodo.
- **T-HU-11.2** Mostrar capacidad, ocupación, cupos libres y cantidad de
  reservas por estado.

### HU-13 · Solicitud y ejecución de la cancelación de una reserva

**Responsable:** Programador B · **2 tareas** · **Criterios:** los de HU-13

- **T-HU-13.1** Registrar la solicitud de cancelación del cliente y
  conservar su historial, sin cambiar el estado de la reserva.
- **T-HU-13.2** Ejecutar la cancelación indicando el motivo y la fecha,
  liberar el cupo una sola vez y verificar la nueva disponibilidad.

### HU-14 · Registro y validación de anticipos y saldos de una reserva

**Responsable:** Programador B · **2 tareas** · **Criterios:** los de HU-14

- **T-HU-14.1** Registrar anticipos y pagos con importe, fecha, método y
  concepto, desde el personal o desde la cuenta del cliente.
- **T-HU-14.2** Validar o anular el pago y calcular el total abonado, el
  saldo pendiente y el historial de pagos.

### HU-16 · Avisos de cambios de fecha y capacidad de una salida

**Responsable:** Programador B · **2 tareas** · **Criterios:** los de HU-16

- **T-HU-16.1** Generar el aviso al cliente afectado cuando cambia la fecha o
  la capacidad de una salida.
- **T-HU-16.2** Mostrar el aviso con el valor anterior y el nuevo, y
  comprobar que solo lo vea el cliente afectado.

## Convenciones del backlog

- El **CSV** es la fuente tabular: UTF-8 con BOM y separador `;`. Sus
  columnas son ID, historia, actor, canal, prioridad, riesgo, estimación y
  tareas. La prioridad y el riesgo van en columnas separadas.
- Este documento **Markdown** es la versión legible: añade el enunciado
  completo, los criterios de aceptación, el desglose de tareas y las
  observaciones de revisión.
- El **desglose de tareas** se documenta solo en esta versión legible: el CSV
  conserva la cantidad de tareas por historia, no su detalle.
- El desglose mantiene el formato `### HU-NN · título`,
  `**Responsable:** Programador A · N tareas` y `- **T-HU-NN.n** texto`
  porque `tablero/generar.py` lo lee para generar el tablero. Un
  cambio de formato exige actualizar el generador.
- Las historias **no se incluyen en `main.tex`** sin una instrucción
  explícita.
- Los datos del backlog **no se corrigen** salvo que el usuario lo solicite.

## Resumen

| Concepto | Valor |
|---|---|
| Historias de usuario | 17 |
| Historias con criterios de aceptación | 17 |
| Estimación total | 47 pts |
| Tareas totales | 39 |
| Tareas desglosadas | 39 |
| Prioridad alta | 7 |
| Prioridad media | 7 |
| Prioridad baja | 3 |
| Riesgo alto | 7 |
| Riesgo medio | 9 |
| Riesgo bajo | 1 |

## Escala de estimación

Escala de Fibonacci (1, 2, 3, 5, 8, 13) aplicada a la complejidad y al
esfuerzo relativo de cada historia, con independencia del plazo de entrega.
En esta versión se usan los valores 2, 3 y 5. La priorización se expresa
mediante las columnas de prioridad y riesgo, no mediante el puntaje: el
total de 47 puntos sirve para dimensionar el alcance, no para-planificar
iteraciones, porque todavía no se ha definido una velocidad de referencia.

## Observaciones

1. El orden del backlog no sigue la numeración de los ID: comienza en HU-08.
   Se conserva porque parece reflejar el orden de priorización.
2. El solapamiento entre HU-04 y HU-12 quedó resuelto. HU-04 cubre la ficha
   comercial del cliente y HU-12 los pasajeros y su vinculación a la
   reserva, de modo que ninguna de las dos repite el registro del cliente.
3. La prioridad y el riesgo se separaron en dos columnas. Antes iban en un
   solo campo «Prioridad (riesgo)», lo que impedía consultar cada dimensión
   por separado.
4. La escala de estimación quedó declarada. Antes solo se observaban los
   valores usados (2, 3 y 5) sin escala ni referencia de velocidad.
5. Las estimaciones y el número de tareas se guardan con su unidad
   («3 pts», «2 tareas»), tal como fueron entregados.
6. El desglose de las 39 tareas se incorporó a este documento en una
   subsección por historia, con su responsable. Veintiuna tareas quedaron
   como estaban, diez se ajustaron y ocho son nuevas.
7. Totales verificados: 17 historias, 47 pts y 39 tareas.
8. Tres historias se agregaron para cubrir el acceso directo del cliente que
   exige el informe: HU-15, HU-16 y HU-17.
9. Cinco historias cambian de alcance: HU-03, HU-06, HU-07, HU-13 y HU-14.
   Ahora distinguen el canal de atención y separan la acción del cliente de
   la validación del personal.
10. HU-04 y HU-12 se renombraron para eliminar el solapamiento funcional.
11. Los criterios de aceptación se completaron para las 17 historias. Ya no
    queda ninguna historia sin redactar.
12. Las tareas de HU-03, HU-06, HU-07, HU-13 y HU-14 se ajustaron para que
    su redacción distinga la solicitud del cliente de la validación del
    personal, de acuerdo con el alcance nuevo de esas historias.
13. El actor de HU-01, HU-02 y HU-10 se corrigió a administrador en el CSV,
    con el enunciado y la tabla de actores de este documento. El personal
    sigue apareciendo en esas historias porque consulta, pero el mantenimiento
    de paquetes, salidas y proveedores corresponde al administrador.
14. El aviso al cliente de HU-16 se deriva del historial de cambios de la
    salida y de las reservas del cliente. No se creó una tabla de avisos en
    el esquema ni se modificó la base de datos.
15. El plazo de confirmación de una solicitud queda fijado en 48 horas, que es
    el valor por omisión del esquema, el que aplican los criterios de HU-06 y
    HU-17 y el que recoge el informe.

## Pendientes para la próxima revisión

- Definir una velocidad de referencia para convertir los 47 puntos en un
  plan de entrega.
- Revisar la estimación de HU-06, que concentra 5 de los 47 puntos y tres
  tareas, por ser la historia de mayor riesgo y alcance.
- Elaborar los diagramas de secuencia de HU-15, HU-16 y HU-17, que no tienen
  representación propia en `sistema/diagramas/uml/secuencia/`.
