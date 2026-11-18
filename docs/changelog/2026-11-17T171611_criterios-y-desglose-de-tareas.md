# Criterios de aceptación y desglose de tareas del backlog

- **Fecha:** 17 de noviembre de 2026, 17:16 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios; el trabajo no modifica el informe)
- **Alcance:** completado el documento de historias de usuario: criterios de
  aceptación de las 17 historias, desglose de las 39 tareas y corrección del
  actor de tres historias en el CSV.

## Antecedente

La revisión del backlog detectó que la planificación del sistema estaba
incompleta en dos frentes que el informe exige:

1. De las 17 historias, solo siete tenían criterios de aceptación redactados
   (HU-08, HU-15, HU-02, HU-06, HU-09, HU-13 y HU-17). Las demás exigían
   requisitos que el sistema no iba a poder cumplir.
2. Las 39 tareas solo existían como cantidad en el CSV. No había un
   desglose por historia, que es lo que permite usarlas como tarjetas de un
   tablero.

Además, la lista de pendientes señalaba once historias sin criterios,
incluida HU-15, que ya los tenía; el actor de HU-01, HU-02 y HU-10 figuraba
como «Personal» en el CSV, en contradicción con sus enunciados y con la
tabla de actores; y HU-16 exigía avisos al cliente sin que el esquema
tuviera una entidad donde registrarlos.

## Cambios de formato

No hubo cambios de formato en el informe, porque no se modificó ningún
archivo LaTeX. En el documento de historias de usuario, las secciones nuevas
siguen el estilo vigente: un bloque por historia, con viñetas de una línea
por criterio y un encabezado `###` con el ID y el nombre de la historia.

## Cambios de contenido

### Criterios de aceptación

El encabezado de la sección se reescribió: ya no documenta solo las historias
de riesgo alto y las que cambiaron de alcance, sino las 17. Los criterios se
ordenaron como el backlog y se apoyan en las reglas de negocio ya reflejadas
en el esquema de la base de datos, de modo que ninguna historia exija algo
que el sistema no pueda cumplir.

Se redactaron los criterios de las diez historias que no los tenían:

| Historia | Contenido de los criterios |
|---|---|
| HU-01 | Código único, precio mayor que cero, estados borrador/activo/inactivo, no se elimina un paquete con salidas o reservas, el mantenimiento es del administrador |
| HU-03 | Cálculo del cupo en el momento de la consulta, solo pendientes y confirmadas ocupan cupo, mismo resultado en web y en oficina, el cliente no ve la identidad de los pasajeros |
| HU-04 | Documento único, la ficha existente se muestra en vez de duplicarla, la ficha puede existir sin cuenta, se inactiva en vez de borrarse, solo el personal la actualiza |
| HU-05 | Número único, importe según precio de salida y pasajeros, plazo de validez, la cotización no descuenta cupo ni crea reserva, el vínculo con la reserva es único |
| HU-07 | Filtros por fecha, estado y canal, la confirmación limpia el vencimiento, la modificación revalida cupos en la transacción, no se modifican reservas vencidas, canceladas ni finalizadas |
| HU-10 | Tipo restringido, relación de varios a varios con los paquetes, el vínculo no se repite, se inactiva en vez de borrarse, mantenimiento del administrador |
| HU-11 | Filtro por fecha o periodo y por paquete, capacidad, pendientes, confirmados, cupos libres y reservas por estado, las cifras coinciden con la vista de disponibilidad |
| HU-12 | Documento único del pasajero, el pasajero puede ser el cliente, la cantidad coincide con los pasajeros registrados, no se confirma con la cantidad desajustada |
| HU-14 | Importe mayor que cero, un anticipo y un saldo por reserva, el pago del cliente queda registrado hasta que el personal lo valida, el saldo se calcula sobre pagos validados |
| HU-16 | El aviso se genera para las reservas pendientes y confirmadas de la salida, muestra el valor anterior y el nuevo, se deriva del historial de la salida, no cambia el estado de la reserva |

HU-17 se reubicó en la posición que le corresponde en el backlog.

### Desglose de tareas

Se agregó la sección con las 39 tareas, una subsección por historia y en el
orden del backlog. Cada subsección declara el responsable, la cantidad de
tareas y que cada tarea hereda los criterios de aceptación de su historia.

De las 31 tareas que ya existían, veintiuna quedaron sin cambios, diez se
ajustaron para que su redacción distinga la solicitud del cliente de la
validación del personal, y ocho son nuevas:

| Tarea | Ajuste |
|---|---|
| T-HU-03.1 | Consultar cupos por paquete y fecha de salida, desde la web o en la oficina |
| T-HU-03.2 | Calcular los disponibles descontando las reservas pendientes y confirmadas |
| T-HU-06.1 | Crear la reserva desde la atención del personal o como solicitud del cliente, con su origen |
| T-HU-06.3 | Guardar la reserva en estado pendiente con su fecha de vencimiento |
| T-HU-07.1 | Consultar las reservas de ambos canales, su estado y su fecha de vencimiento |
| T-HU-13.1 | Registrar la solicitud de cancelación del cliente sin cambiar el estado de la reserva |
| T-HU-13.2 | Ejecutar la cancelación indicando el motivo y la fecha, y liberar el cupo una sola vez |
| T-HU-14.1 | Registrar anticipos y pagos desde el personal o desde la cuenta del cliente |
| T-HU-14.2 | Validar o anular el pago y calcular el total abonado y el saldo pendiente |

Las ocho tareas nuevas cubren las tres historias agregadas para el acceso
directo del cliente: HU-15 (alta de la cuenta, vínculo con la ficha y
pruebas de acceso y bloqueo), HU-17 (listado de solicitudes pendientes,
confirmación y vencimiento automático) y HU-16 (generación del aviso y su
presentación al cliente afectado).

El reparto queda en 20 tareas para el programador A (HU-08, HU-01, HU-02,
HU-03, HU-06, HU-07, HU-17 y HU-09) y 19 para el programador B (HU-15,
HU-04, HU-10, HU-05, HU-12, HU-11, HU-13, HU-14 y HU-16).

### Corrección del actor de tres historias

En el CSV, el actor de HU-01, HU-02 y HU-10 pasó de «Personal» a
«Administrador», para coincidir con sus enunciados y con la tabla de
actores. La tabla del backlog en el documento Markdown se actualizó en la
misma forma. El personal sigue apareciendo en esas historias porque
consulta, pero el mantenimiento de paquetes, salidas y proveedores
corresponde al administrador; los criterios nuevos lo dicen de forma
explícita.

### Cierre del documento

- El resumen suma «Historias con criterios de aceptación: 17» y «Tareas
  desglosadas: 39».
- Las convenciones aclaran que el desglose de tareas se documenta solo en la
  versión legible y que el CSV conserva la cantidad por historia.
- La observación 6 se reescribió y se agregaron cinco: criterios
  completados, tareas ajustadas por cambio de alcance, corrección del actor,
  derivación de los avisos desde el historial de la salida y fijación del
  plazo de confirmación en 48 horas, que es el valor por omisión del esquema,
  el que aplican los criterios de HU-06 y HU-17 y el que recoge el informe.
- Los pendientes quedaron reducidos a la velocidad de referencia, la
  revisión de la estimación de HU-06 y los diagramas de secuencia de HU-15,
  HU-16 y HU-17.

## Archivos modificados

- `sistema/historias-usuario/historias-usuario.md`: criterios de aceptación
  de las 17 historias, sección de desglose de tareas y cierre del documento.
- `sistema/historias-usuario/historias-usuario.csv`: actor de HU-01, HU-02 y
  HU-10. Se conservaron la codificación UTF-8 con BOM y los finales de línea
  CRLF.
- `documentacion/registro-cambios/README.md`: iteración del registro.

## Validación

- El CSV conserva 17 historias, 47 pts y 39 tareas, de acuerdo con su fila
  TOTAL.
- La tabla del backlog del documento Markdown coincide con el CSV en las 17
  filas: historia, actor, canal, prioridad, riesgo, estimación y cantidad de
  tareas.
- Las 39 tareas del desglose tienen identificador único y el conteo por
  historia es igual al del CSV. La suma por responsable es 20 + 19.
- Los bloques de criterios y las subsecciones del desglose están en el
  orden del backlog, y las 17 historias tienen criterios redactados.
- `make verificar` terminó con cero problemas: 26 archivos revisados, 20
  rutas LaTeX y 24 entradas del árbol del README.
- El PDF no se recompiló porque ningún archivo LaTeX cambió; conserva sus
  21 páginas.

## Pendientes

- Definir una velocidad de referencia para convertir los 47 puntos en un
  plan de entrega.
- Revisar la estimación de HU-06, que concentra 5 de los 47 puntos y tres
  tareas, por ser la historia de mayor riesgo y alcance.
- Elaborar los diagramas de secuencia de HU-15, HU-16 y HU-17, que no tienen
  representación propia en `sistema/diagramas/uml/secuencia/`.
- Decidir si los diagramas de secuencia se incorporan al cuerpo del informe
  o a los anexos.
