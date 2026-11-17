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
| HU-15 | Abrir una cuenta de cliente y acceder a su información | Cliente | Web | Alta | Alto | 3 pts | 3 tareas |
| HU-01 | Gestión de paquetes turísticos | Personal | Web | Alta | Medio | 3 pts | 2 tareas |
| HU-02 | Registro de fechas de salida y cupos | Personal | Web | Alta | Alto | 2 pts | 2 tareas |
| HU-03 | Consulta de disponibilidad | Cliente, Personal | Web, Oficina | Alta | Medio | 2 pts | 2 tareas |
| HU-04 | Registro y actualización de la ficha del cliente | Personal | Web, Oficina | Alta | Medio | 2 pts | 2 tareas |
| HU-10 | Registrar proveedores y vincularlos a los paquetes | Personal | Web | Media | Bajo | 2 pts | 2 tareas |
| HU-05 | Elaboración de cotizaciones | Personal | Web, Oficina | Media | Medio | 3 pts | 2 tareas |
| HU-06 | Registro de reservas con validación de cupos | Personal, Cliente | Web, Oficina | Alta | Alto | 5 pts | 3 tareas |
| HU-12 | Registro de pasajeros y vinculación a una reserva | Personal, Cliente | Web | Alta | Medio | 3 pts | 2 tareas |
| HU-07 | Seguimiento y actualización de reservas | Personal | Web | Alta | Medio | 3 pts | 3 tareas |
| HU-17 | Confirmación de solicitudes y control de su vencimiento | Personal | Web | Alta | Alto | 3 pts | 3 tareas |
| HU-09 | Modificar fechas o capacidad de una salida | Administrador | Web | Alta | Alto | 3 pts | 2 tareas |
| HU-11 | Consultar reportes de ocupación y reservas por fecha | Personal | Web | Media | Medio | 2 pts | 2 tareas |
| HU-13 | Solicitud y ejecución de la cancelación de una reserva | Cliente, Personal | Web, Oficina | Alta | Alto | 3 pts | 2 tareas |
| HU-14 | Registro y validación de anticipos y saldos de una reserva | Cliente, Personal | Web, Oficina | Alta | Medio | 3 pts | 2 tareas |
| HU-16 | Avisos de cambios de fecha y capacidad de una salida | Cliente | Web | Alta | Medio | 2 pts | 2 tareas |
| **TOTAL** | **17 historias de usuario** | | | | | **47 pts** | **39 tareas** |

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

Se documentan los criterios de las historias con riesgo alto y de las que
cambian de alcance en esta revisión. El resto de las historias requiere
redacción posterior.

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

### HU-02 · Registro de fechas de salida y cupos

- Cada salida pertenece a un paquete y tiene fecha de salida, fecha de
  retorno, capacidad y precio.
- La capacidad es un número entero positivo y la fecha de retorno no es
  anterior a la de salida.
- Una salida modificada no puede quedar con capacidad menor que la cantidad
  de pasajeros ya reservados.
- Cada cambio de fecha, capacidad, precio o estado queda auditado.

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

### HU-09 · Modificar fechas o capacidad de una salida

- La modificación se ejecuta dentro de una transacción que bloquea la salida.
- La nueva capacidad no puede ser menor que los pasajeros de las reservas
  pendientes y confirmadas.
- Un cambio de fecha no rompe el vínculo de las reservas existentes con la
  salida.
- El cambio queda auditado con el valor anterior y el nuevo, y se comunica a
  los clientes afectados.

### HU-13 · Solicitud y ejecución de la cancelación de una reserva

- El cliente puede solicitar la cancelación de una reserva propia que no
  esté finalizada; la solicitud no modifica el estado por sí sola.
- El personal ejecuta la cancelación, indica el motivo y la fecha.
- La cancelación es lógica: la reserva conserva su historial y los cupos se
  liberan por cálculo, sin eliminar registros.
- La devolución del dinero se gestiona fuera del sistema y no se registra
  como un nuevo pago.
- Los cambios de estado quedan auditados con el usuario que los ejecutó.

### HU-17 · Confirmación de solicitudes y control de su vencimiento

- El personal ve una lista de solicitudes pendientes de ambos canales con su
  fecha de vencimiento.
- Confirmar una solicitud cambia su estado a confirmada, limpia la fecha de
  vencimiento y queda auditado.
- Una solicitud no confirmada dentro del plazo pasa a vencida y libera los
  cupos de forma automática.
- Una solicitud vencida no puede confirmarse después; el cliente debe
  registrar una nueva solicitud si la salida sigue disponible.

## Convenciones del backlog

- El **CSV** es la fuente tabular: UTF-8 con BOM y separador `;`. Sus
  columnas son ID, historia, actor, canal, prioridad, riesgo, estimación y
  tareas. La prioridad y el riesgo van en columnas separadas.
- Este documento **Markdown** es la versión legible: añade el enunciado
  completo, los criterios de aceptación y las observaciones de revisión.
- Las historias **no se incluyen en `main.tex`** sin una instrucción
  explícita.
- Los datos del backlog **no se corrigen** salvo que el usuario lo solicite.

## Resumen

| Concepto | Valor |
|---|---|
| Historias de usuario | 17 |
| Estimación total | 47 pts |
| Tareas totales | 39 |
| Prioridad alta | 14 |
| Prioridad media | 3 |
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
6. No se incluye el desglose de las 39 tareas, solo su cantidad por historia.
7. Totales verificados: 17 historias, 47 pts y 39 tareas.
8. Tres historias se agregaron para cubrir el acceso directo del cliente que
   exige el informe: HU-15, HU-16 y HU-17.
9. Cinco historias cambian de alcance: HU-03, HU-06, HU-07, HU-13 y HU-14.
   Ahora distinguen el canal de atención y separan la acción del cliente de
   la validación del personal.
10. HU-04 y HU-12 se renombraron para eliminar el solapamiento funcional.

## Pendientes para la próxima revisión

- Redactar los criterios de aceptación de las historias que aún no los
  tienen: HU-01, HU-03, HU-04, HU-05, HU-07, HU-10, HU-11, HU-12, HU-14,
  HU-15 y HU-16.
- Desglosar las 39 tareas y relacionarlas con cada historia.
- Definir una velocidad de referencia para convertir los 47 puntos en un
  plan de entrega.
- Precisar el plazo definitivo de confirmación de una solicitud: el esquema
  usa 48 horas por omisión.
- Revisar la estimación de HU-06, que concentra 5 de los 47 puntos y tres
  tareas, por ser la historia de mayor riesgo y alcance.
