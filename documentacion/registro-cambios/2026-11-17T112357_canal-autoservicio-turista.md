# Canal de autoservicio del cliente

- **Fecha:** 17 de noviembre de 2026, 11:23 (hora local)
- **Documento:** `_build/main.pdf`
- **Páginas:** 21
- **Alcance:** incorporación del actor turista al informe y a la base de
  datos temporal, con el modelo de autoservicio controlado.

## Antecedente

El informe describía un proceso de reserva atendido exclusivamente por el
personal de la agencia, mientras que el esquema de base de datos ya definía
el rol `TURISTA`, la tabla `usuario` para cuentas de clientes y el vínculo
opcional `cliente.id_usuario`. El backlog de historias de usuario y los
diagramas de secuencia también incluían al turista como actor. La falta de
respaldo textual en el informe dejaba el diseño sin cobertura en el documento.

Antes de aplicar los cambios se revisó si el acceso directo del cliente
interrumpía el flujo del personal. La conclusión fue que no lo interrumpe si
su solicitud ingresa al mismo proceso validado: nace en estado `pendiente`,
requiere la confirmación del personal y se vence si no se atiende a tiempo.

## Cambios de formato

- Se amplió el ancho de la caja del número en el índice
  (`\cftsecnumwidth` y `\cftsubsecnumwidth` en `si3apa7.cls`). El valor
  anterior quedaba corto para números de dos cifras como `10.1.`, que se
  tocaban con el título de la entrada en el índice.

## Cambios de contenido

### Antecedentes

- En «Flujo de información de la agencia» se añadió que el acceso web del
  cliente es un canal adicional de consulta y que la consulta y la solicitud
  pueden originarse en la atención del personal o directamente en el sistema,
  siempre bajo el mismo criterio de disponibilidad y de registro.

### Objeto de estudio y campo de acción

- Se declaró que el sistema atiende a dos grupos de usuarios: el personal de
  la agencia y los clientes con cuenta propia.
- Se aclaró que la participación de los clientes no genera un proceso
  paralelo, porque sus solicitudes ingresan al mismo flujo de validación.
- En el campo de acción se precisó que la interacción del cliente se limita a
  la consulta, a la solicitud de reserva y al seguimiento de su propia reserva.

### Población y muestra

- Se añadió que los clientes que utilizan el sistema accedieron con cuenta
  propia y que el resto continúa atendido por el personal, sin modificar el
  catálogo de la población.

### Justificación social

- Se reforzó el beneficio al cliente: consulta de la disponibilidad y del
  estado de su reserva sin depender de la atención presencial, y aviso de los
  cambios de fecha o de capacidad de una salida.
- Se añadió que la unificación de los canales beneficia también a la agencia.
- Se conservó la cautela académica sobre el aumento de ventas.

### Alcances del sistema

- Se añadió el módulo «Acceso del cliente» y se ajustaron los módulos de
  reservas y de pagos para indicar que ambos canales terminan en la
  confirmación del personal.
- Se cambió «accesos según el rol de cada trabajador» por «accesos según el
  rol de cada usuario, sea trabajador o cliente».
- Se añadió la subsección «Canales de atención y confirmación», que describe
  los dos canales y la convergencia de ambos en el mismo proceso validado.
- Se añadió la subsección «Avisos al cliente», que cubre la comunicación de
  los cambios de fecha y de capacidad de una salida.

### Límites del proyecto

- Se añadió la subsección «Límites del acceso directo del cliente»: el
  sistema no confirma reservas por sí solo, el pago registrado por el cliente
  no produce la confirmación, solo se admite una solicitud activa por salida,
  las solicitudes no confirmadas se vencen y liberan los cupos, las
  modificaciones posteriores a la confirmación las realiza el personal, la
  cancelación se registra como solicitud y la devolución se gestiona fuera
  del sistema, y el acceso del cliente complementa la atención del personal.

### Resumen y glosario

- El resumen menciona que el sistema es utilizado por el personal y por los
  clientes, y que ambas entradas siguen el mismo criterio de validación.
- El glosario incorpora «Solicitud de reserva», «Canal de atención» y
  «Vencimiento de una solicitud».

### Base de datos

- `reserva` incorpora `origen` (`personal` o `web`), `fecha_expiracion` y el
  estado `vencida`.
- Se añadió la restricción `ck_reserva_expiracion`, que exige fecha de
  vencimiento en toda reserva pendiente.
- Se añadieron los índices `ix_reserva_vencimiento` y
  `ux_reserva_solicitud_activa`, que limita a una solicitud pendiente por
  cliente y salida en cualquiera de los dos canales.
- Se añadió la función `fn_vencer_solicitudes_pendientes()`, que cambia a
  `vencida` las solicitudes no confirmadas dentro del plazo y registra el
  cambio en el historial.
- `historial_reserva` admite el estado `vencida`.
- `vista_disponibilidad_salida` separa pasajeros pendientes y confirmados y
  expone `cupo_disponible_sin_pendientes`.
- `vista_reservas_por_fecha` distingue reservas pendientes, confirmadas y
  vencidas.
- Se actualizó la descripción del rol `TURISTA`.
- El diccionario de datos documenta los campos nuevos, las reglas 8 a 11, la
  rutina de vencimiento, los supuestos y la concurrencia aplicada a los dos
  canales.

## Archivos modificados

- `capitulos/02-antecedentes.tex`
- `capitulos/05-objeto-estudio.tex`
- `capitulos/08-poblacion-muestra.tex`
- `capitulos/09-justificacion-social.tex`
- `capitulos/10-alcances-sistema.tex`
- `capitulos/11-limites-proyecto.tex`
- `preliminares/resumen.tex`
- `finales/glosario.tex`
- `si3apa7.cls`
- `codigo/base-datos/esquema-temporal.sql`
- `codigo/base-datos/diccionario-datos.md`
- `AGENTS.md`
- `registro-cambios/README.md`

## Validación

- `make pdf` terminó correctamente y generó `_build/main.pdf`.
- El PDF final tiene 21 páginas.
- El índice muestra las secciones 1 a 10 con numeración y punto, incluidas
  las nuevas 9.2, 9.3 y 10.1, con separación correcta entre número y título.
- No se encontraron referencias ni citas indefinidas en el registro de
  compilación.
- No se encontraron avisos de caja `Overfull` ni `Underfull`.
- No se encontraron citas con «s. f.» ni expresiones en primera persona del
  plural en el texto extraído del PDF.
- Se revisaron visualmente las páginas con los apartados nuevos.

## Pendientes

- Actualizar el backlog de historias de usuario para que HU-03, HU-06,
  HU-08, HU-13 y HU-14 reflejen el canal del cliente, con las reglas de
  vencimiento, unicidad de solicitud y confirmación a cargo del personal.
- Actualizar los diagramas de secuencia, que todavía muestran la reserva y la
  cancelación ejecutadas por el personal.
- Decidir el plazo definitivo de confirmación de una solicitud: el esquema
  usa 48 horas por omisión.
