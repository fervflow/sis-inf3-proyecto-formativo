# Backlog actualizado y diagramas de secuencia regenerados

- **Fecha:** 17 de noviembre de 2026, 11:44 (hora local)
- **Documento:** `_build/main.pdf`
- **Páginas:** 21 (sin cambios respecto de la iteración anterior)
- **Alcance:** revisión del backlog de historias de usuario y regeneración de
  los diagramas de secuencia a partir del informe y del backlog revisados.

## Antecedente

El análisis de consistencia del backlog detectó que la base de datos ya
implementaba reglas que ninguna historia exigía, y que los diagramas de
secuencia seguían describiendo un proceso con un solo canal de atención,
en contradicción con el informe. Con la incorporación del acceso directo del
cliente, esas diferencias dejaron de ser tolerables.

## Cambios de contenido

### Historias de usuario

- El backlog pasó de 14 a **17 historias**, de 38 a **47 puntos** y de 31 a
  **39 tareas**.
- El CSV incorporó las columnas `Actor`, `Canal`, `Prioridad` y `Riesgo`.
  La prioridad y el riesgo, que antes iban en un solo campo, quedaron
  separados.
- Se declaró la escala de estimación: Fibonacci (1, 2, 3, 5, 8, 13), con
  valores 2, 3 y 5 en esta versión.
- Se resolvió el solapamiento entre HU-04 y HU-12. HU-04 pasó a ser «Registro
  y actualización de la ficha del cliente» y HU-12 «Registro de pasajeros y
  vinculación a una reserva».
- Se agregaron tres historias que cubren el acceso directo del cliente:
  - **HU-15** · Abrir una cuenta de cliente y acceder a su información.
  - **HU-16** · Avisos de cambios de fecha y capacidad de una salida.
  - **HU-17** · Confirmación de solicitudes y control de su vencimiento.
- Cinco historias cambiaron de alcance para distinguir el canal y separar la
  acción del cliente de la validación del personal: HU-03, HU-06, HU-07,
  HU-13 y HU-14. HU-13 pasó a ser «Solicitud y ejecución de la cancelación
  de una reserva» y HU-14 «Registro y validación de anticipos y saldos de
  una reserva».
- El documento legible incorpora el enunciado «Como, quiero, para» de las 17
  historias, la tabla de actores y los criterios de aceptación de siete
  historias: HU-08, HU-15, HU-02, HU-06, HU-09, HU-13 y HU-17.
- Las observaciones del `.md` se actualizaron: se marcan las resueltas y se
  listan los pendientes reales.

### Base de datos

- `reserva.fecha_solicitud_cancelacion` registra la solicitud de
  cancelación del cliente sin cambiar el estado de la reserva.
- `pago.estado` (`registrado`, `validado`, `anulado`) con
  `id_usuario_validacion` y `fecha_validacion`, más la restricción
  `ck_pago_validacion`.
- `vista_saldo_reserva` separa el total pagado del total validado y calcula
  el saldo pendiente sobre los pagos validados.
- El diccionario documenta las reglas 12 y 13 y los campos nuevos.

### Diagramas

- Los 7 diagramas completos de `diagramas/fuentes/uml/secuencia/` se
  regeneraron desde cero: HU-03, HU-05, HU-06, HU-07, HU-09, HU-13 y HU-14.
  Los anteriores quedaron descartados.
- Los 7 diagramas de `secuencia-light/` se reescribieron con el mismo
  modelo.
- Los 5 fragmentos de `secuencia-comunes/` se actualizaron: el cálculo de
  disponibilidad excluye las reservas vencidas, el saldo se calcula sobre
  los pagos validados y la máquina de estados incluye `vencida`.
- Las 2 variantes de `secuencia-fusionados/` se actualizaron: la
  cancelación del cliente se registra como solicitud y el aviso al cliente
  aparece en HU-09.
- El mapa de procesos de `procesos/mapa-procesos.puml` se rehízo con los
  carriles de cliente, personal, administrador y sistema, y con la
  validación del pago y la confirmación dentro del plazo.

## Archivos modificados

- `tablas/historias-usuario.csv`
- `tablas/historias-usuario.md`
- `codigo/base-datos/esquema-temporal.sql`
- `codigo/base-datos/diccionario-datos.md`
- `diagramas/fuentes/uml/secuencia/hu-03-consultar-disponibilidad.puml`
- `diagramas/fuentes/uml/secuencia/hu-05-elaborar-cotizacion.puml`
- `diagramas/fuentes/uml/secuencia/hu-06-registrar-reserva.puml`
- `diagramas/fuentes/uml/secuencia/hu-07-actualizar-reserva.puml`
- `diagramas/fuentes/uml/secuencia/hu-09-modificar-salida.puml`
- `diagramas/fuentes/uml/secuencia/hu-13-cancelar-reserva.puml`
- `diagramas/fuentes/uml/secuencia/hu-14-registrar-pago.puml`
- `diagramas/fuentes/uml/secuencia-light/` (7 archivos y su README)
- `diagramas/fuentes/uml/secuencia-comunes/` (5 archivos y su README)
- `diagramas/fuentes/uml/secuencia-fusionados/` (2 archivos y su README)
- `diagramas/fuentes/uml/procesos/mapa-procesos.puml` y su README
- `AGENTS.md`
- `registro-cambios/README.md`

## Validación

- `make diagramas` regeneró los 21 diagramas sin errores ni advertencias de
  PlantUML.
- `make pdf` terminó correctamente; `_build/main.pdf` conserva 21 páginas.
- El backlog se verificó por cálculo: 17 historias, 47 puntos y 39 tareas, y
  las 17 filas de la tabla del `.md` coinciden sin diferencias con el CSV.
- Los 17 enunciados están redactados y 7 historias tienen criterios de
  aceptación.
- Los 7 diagramas completos conservan los estereotipos `<<interfaz>>`,
  `<<control>>`, `<<entidad>>` y `<<tabla>>`.
- Se revisaron visualmente el diagrama de HU-06 y el mapa de procesos.
- El esquema SQL se revisó por inspección, por no haber servidor PostgreSQL
  disponible en el equipo.

## Pendientes

- Redactar los criterios de aceptación de las diez historias que aún no los
  tienen.
- Desglosar las 39 tareas.
- Definir la velocidad de referencia para convertir los 47 puntos en un plan
  de entrega.
- Decidir si los diagramas de secuencia se incorporan al cuerpo del informe
  o a los anexos.
- Elaborar los diagramas de HU-17 y HU-16, que no tienen representación
  propia en la carpeta `secuencia/`.
