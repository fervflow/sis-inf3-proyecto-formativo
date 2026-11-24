# Ciclo completo de la reserva: manifiesto, modificación, cancelación, avisos y reportes

## Fecha y alcance

24 de noviembre de 2026. Ejecución de las seis historias restantes del
flujo de reservas: HU-12 (manifiesto de pasajeros), HU-07 (seguimiento y
modificación), HU-13 (cancelaciones), HU-16 (avisos), HU-11 (reportes) y
la verificación de HU-09 (que ya estaba implementada en API, interfaz y
base). Alcanza al catálogo de reglas, las historias, el esquema y las
funciones de la base, las pruebas SQL, la API y la interfaz de la web, y
los diagramas de secuencia.

## Documento generado

El informe no cambió en este trabajo; los PDF de los diagramas nuevos se
publicaron en `entregables/diagramas/pdf/secuencia/`.

## Decisiones adoptadas

- **Manifiesto como lista completa (RN-RES-21):** guardar el manifiesto
  reemplaza la lista de pasajeros y ajusta la cantidad declarada a la
  cantidad de pasajeros registrados, reutilizando al pasajero por
  documento dentro de la ficha del cliente de la reserva.
- **Confirmación con manifiesto completo (RN-RES-19):** `fn_confirmar_
  reserva` exige, junto con el anticipo validado, que los pasajeros
  registrados igualen la cantidad declarada.
- **Modificación con revalidación (RN-RES-20):** cambiar la salida o el
  manifiesto revalida los cupos sin contar la reserva propia, recalcula
  el monto con el precio vigente y rechaza que los pagos no anulados
  queden por encima del nuevo total; todo queda auditado con los valores
  anterior y nuevo.
- **Cancelación en dos pasos (RN-RES-14):** el cliente solicita sobre una
  reserva pendiente o confirmada y el personal la ejecuta con motivo y
  fecha; el cupo se libera por cálculo.
- **Avisos derivados del historial (RN-RES-22):** cada reserva pendiente
  o confirmada ve los cambios de fecha o capacidad de su salida
  ocurridos después de crearla; sin correo en el MVP, en las pantallas.
- **Reportes desde la vista (RN-REP-01 a RN-REP-04):** misma base de
  cálculo que la disponibilidad, con canceladas informadas sin ocupar
  cupo y conteo por canal.

## Cambios de contenido

### Catálogo de reglas (`sistema/reglas-negocio.md`)

- RN-RES-14 a Vigente (cancelaciones) y nuevas RN-RES-19, RN-RES-20,
  RN-RES-21 y RN-RES-22.
- Sección nueva «16. Reportes» con RN-REP-01 a RN-REP-04; secciones
  renumeradas.
- Trazabilidad con filas nuevas para HU-07, HU-11, HU-12, HU-13 y HU-16;
  pendientes reducidos a la transición a `finalizada`, la reutilización
  de pasajeros entre fichas distintas, las devoluciones, el proveedor
  multitipo y los roles por código.

### Historias de usuario (`sistema/historias-usuario/historias-usuario.md`)

- Criterio de HU-12 alineado al manifiesto; observación 20 nueva;
  pendiente de diagramas reducido a HU-17.

### Base de datos

- `fn_confirmar_reserva` exige el manifiesto completo.
- Funciones nuevas: `fn_revalidar_reserva`, `fn_actualizar_reserva` y
  `fn_guardar_manifiesto`.
- `vista_reservas_por_fecha` extendida: canceladas, conteos por canal y
  referencias del paquete.
- Archivo de actualización
  `2026-11-24-manifiesto-modificaciones-cancelaciones-reportes.sql`
  (crea la vista desde cero, porque `CREATE OR REPLACE` no añade
  columnas).
- Datos de prueba: el manifiesto de Juan antes de su confirmación.
- Pruebas nuevas en `bd/pruebas/reglas-reservas.sql` (manifiesto,
  modificación, pagos comprometidos, cancelación) y ajustes de los
  tests de confirmación previos.

### Web

- API: `PATCH /api/reservas/:id` (mover de salida),
  `GET/PUT /api/reservas/:id/pasajeros`,
  `GET /api/reservas/:id/historial`,
  `POST /api/reservas/:id/solicitar-cancelacion`,
  `POST /api/reservas/:id/ejecutar-cancelacion`,
  `GET /api/avisos` (solo cliente) y `GET /api/reportes` (personal).
  `GET /api/reservas` con filtros por canal y por rango de fecha de
  salida. Cada reserva reporta su marca de cancelación solicitada.
- Interfaz: manifiesto editable para personal y cliente
  (`pasajeros/Manifiesto.vue`), historial de la reserva
  (`solicitudes/Historial.vue`), modificación de salida
  (`solicitudes/Modificar.vue`), ejecución de cancelaciones con motivo
  en la bandeja del personal, solicitud de cancelación en «Mis
  reservas», avisos derivados del historial en las pantallas del
  cliente, y página nueva `/reportes` con filtros por periodo y
  paquete. Navegación y middleware protegidos.

### Diagramas

- Secuencias nuevas de HU-12 (manifiesto), HU-16 (avisos) y HU-11
  (reportes); verificación con 39 diagramas y sin problemas.

## Validación realizada

- `make db-probar` completo, incluidos los trece casos de reservas:
  confirmación sin manifiesto rechazada, manifiesto que ajusta cantidad
  y monto, pasajero repetido rechazado, modificación de salida con
  revalidación y auditoría, reducción por debajo de los pagos
  comprometidos rechazada y cancelación solicitada, ejecutada y
  liberada por cálculo.
- `npm run typecheck --workspace web` y `npm run build --workspace web`
  sin errores.
- Prueba en vivo del ciclo completo: manifiesto de ocho pasajeros que
  ajusta la cantidad declarada, confirmación con manifiesto y anticipo,
  historial con auditoría, movimiento de salida con monto recalculado
  (480 → 10000 con el precio vigente), solicitud de cancelación del
  cliente rechazada al intentar ejecutarla él mismo y ejecutada por el
  personal, avisos del cliente tras el cambio de fecha de su salida
  (auditado desde la base), y reportes con conteos por canal y filtro
  por paquete.
- Los archivos de actualización se aplicaron sobre la base viva; se
  detectó y corrigió en el camino que la confirmación con manifiesto no
  estaba en la base aplicada.

## Archivos modificados

Documentación: `sistema/reglas-negocio.md`,
`sistema/historias-usuario/historias-usuario.md`, `bd/diccionario-datos.md`.
Base: `bd/esquema.sql`,
`bd/actualizaciones/2026-11-24-manifiesto-modificaciones-cancelaciones-reportes.sql`,
`bd/datos-prueba.sql`, `bd/pruebas/reglas-reservas.sql`,
`bd/pruebas/reglas-pagos.sql`.
Web: `web/shared/types/api.ts`, `web/server/utils/reservas.ts`,
`web/server/utils/pasajeros.ts`, rutas nuevas y ajustadas en
`web/server/api/`, `web/server/middleware/sesion.ts`,
`web/app/pages/{solicitudes,mis-reservas,reportes}.vue`,
`web/app/components/{pasajeros,solicitudes}/*`,
`web/app/components/BarraNavegacion.vue`,
`web/app/composables/useMensajeError.ts`,
`web/app/i18n/locales/{es,en}.ts`.
Diagramas: `uml/secuencia/hu-11-reportes.puml`,
`uml/secuencia/hu-12-registrar-pasajeros.puml`,
`uml/secuencia/hu-16-avisos.puml`, `sistema/diagramas/README.md`.

## Pendientes o decisiones para el siguiente trabajo

- Mover en el tablero las trece tarjetas de esta ejecución a «Hecho»
  (T-HU-07.1/2/3, T-HU-09.1/2, T-HU-11.1/2, T-HU-12.1/2, T-HU-13.1/2,
  T-HU-16.1/2) y sincronizar con `make tablero-backlog`.
- Transición a `finalizada` cuando la salida pase a `realizada`
  (única regla del ciclo aún sin implementar).
- Reutilizar el pasajero entre fichas de clientes distintos; hoy el
  manifiesto se arma dentro de la ficha del cliente de la reserva.
- Ejecución y registro de las devoluciones (RN-PAG-07) y pasarela real.
