# Código propio de cada salida en la consulta de disponibilidad

## Fecha y alcance

24 de noviembre de 2026. Corrección del doble código en «Próximas
salidas»: las dos salidas del paquete Salar de Uyuni e Isla Incahuasi
mostraban el mismo código, porque la tarjeta solo presentaba el código
del paquete. Cada salida lleva ahora su código único e inmutable,
derivado del código del paquete con un ordinal por paquete
(`PAQUETE-NNN`), regla nueva RN-SAL-22. Alcanza al esquema y a las
funciones de la base, las pruebas SQL, la API y la interfaz de la web,
el catálogo de reglas y el diccionario de datos.

## Documento generado

El informe no cambió en este trabajo; no se regeneró el PDF.

## Decisiones adoptadas

- **El código del paquete queda como está:** es único en la base y
  correcto; el problema era de alcance, no de datos. Dos salidas del
  mismo paquete comparten el paquete y se distinguen por la salida.
- **Código de salida derivado (RN-SAL-22):** el disparador
  `tr_salida_codigo` asigna al insertar el código del paquete más un
  ordinal por paquete con tres dígitos (`SAL-2026-001-002`); bloquea la
  fila del paquete para que dos inserciones simultáneas del mismo
  paquete no compartan ordinal. Es único (`uq_salida_codigo`) e
  inmutable: la salida nunca cambia de paquete (RN-SAL-20) y la edición
  no la renombra.
- **Relleno por fecha:** las salidas existentes se numeraron en orden
  de fecha de salida e identificador; la salida del 4 de diciembre
  quedó como `SAL-2026-001-001` y la del 18 como `SAL-2026-001-002`.
- **Exposición mínima:** la vista de disponibilidad añade
  `codigo_salida` al final (CREATE OR REPLACE VIEW no reordena) y las
  pantallas muestran el código de la salida donde antes mostraban el
  del paquete. Las filas de reservas y cotizaciones conservan el
  código del paquete con la fecha, que basta para distinguirlas.

## Cambios de contenido

### Base de datos

- `salida.codigo` VARCHAR(30), no nulo y único; lo asigna el disparador
  `tr_salida_codigo` con la función `fn_asignar_codigo_salida`.
- `vista_disponibilidad_salida`: columna nueva `codigo_salida`.
- Actualización `2026-11-24-codigo-de-salida.sql`, aplicada sobre la
  base viva con el relleno de las salidas existentes.
- Prueba 13 nueva en `bd/pruebas/reglas-paquetes.sql`: la primera
  salida lleva el ordinal 001, una salida nueva toma el ordinal
  siguiente y la edición de la salida no cambia su código.

### Web

- `web/db/schema.ts` refleja la columna nueva.
- API: `GET /api/disponibilidad` entrega `codigo_salida`;
  `GET /api/admin/salidas` y `obtenerSalida` entregan `codigoSalida`.
- Interfaz: la tarjeta de disponibilidad («Próximas salidas») y la
  tarjeta de salidas del panel muestran el código de la salida; los
  recuadros informativos del formulario de reservas y de cotizaciones
  también, para que el personal distinga la salida que elige.

### Documentación y tablero

- `sistema/reglas-negocio.md`: RN-SAL-22 nueva en la creación de
  salidas y trazabilidad de HU-02 actualizada.
- `bd/diccionario-datos.md`: la ficha de `salida` documenta el código
  propio.
- `tablero/tablero.md`: T-HU-08.1 reajustada a prioridad media y riesgo
  bajo desde la vista kanban (edición propia del usuario).

## Validación realizada

- `db-probar` completo: paquetes (con la prueba 13 nueva), pagos y
  reservas; sin errores y con `ROLLBACK` final.
- Aplicación de la actualización SQL sobre la base viva: las cuatro
  salidas quedaron con códigos únicos, con las dos del Salar de Uyuni
  terminadas en 001 y 002.
- Prueba en vivo del disparador dentro de una transacción: una salida
  nueva del paquete `SAL-2026-001` recibió `SAL-2026-001-003` y la
  transacción terminó en `ROLLBACK`, sin dejar datos.
- `npm run typecheck --workspace web`, `npm run build --workspace web`
  y `npm run db:check --workspace web` sin errores.
- `py tablero/validar.py`: 44 tarjetas válidas tras el reajuste de
  T-HU-08.1.

## Archivos modificados

Base: `bd/esquema.sql`,
`bd/actualizaciones/2026-11-24-codigo-de-salida.sql` (nuevo),
`bd/pruebas/reglas-paquetes.sql`, `bd/diccionario-datos.md`.
Web: `web/db/schema.ts`, `web/shared/types/api.ts`,
`web/server/api/disponibilidad.get.ts`,
`web/server/api/admin/salidas.get.ts`, `web/server/utils/salidas.ts`,
`web/app/components/disponibilidad/Tarjeta.vue`,
`web/app/components/salidas/Tarjeta.vue`,
`web/app/pages/{solicitudes,cotizaciones}.vue`.
Documentación: `sistema/reglas-negocio.md`, `tablero/tablero.md`,
`docs/changelog/`.

## Pendientes o decisiones para el siguiente trabajo

- Reutilizar un pasajero entre fichas de clientes distintos; hoy el
  manifiesto se arma dentro de la ficha del cliente de la reserva.
- Aviso al cliente cuando el personal mueve su reserva de salida; hoy
  lo ve en «Mis reservas» por el cambio de salida y fecha.
- Ejecución y registro de las devoluciones (RN-PAG-07) y pasarela real.
- Diagrama de secuencia de HU-17, sin representación propia en
  `sistema/diagramas/uml/secuencia/`.
