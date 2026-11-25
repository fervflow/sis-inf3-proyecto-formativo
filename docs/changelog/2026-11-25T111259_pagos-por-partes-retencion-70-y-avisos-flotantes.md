# Pagos por partes, retención del 70% y avisos flotantes

## Fecha y alcance

25 de noviembre de 2026. Corrección del ciclo de solicitudes, pagos y
manifiestos con retroalimentación visible en la interfaz. Comprende
cambios de regla de negocio (retención web del 70% de los cupos
disponibles, pagos por partes, manifiesto del canal web sin superar lo
solicitado), la reparación del sistema de diseño en los colores de
estado, avisos flotantes para todas las acciones, indicadores de
manifiesto pendiente y saldo por pagar en las tablas, y la reparación de
la cadena de actualizaciones de la base, que en la base viva no había
llegado a aplicar la finalización de reservas.

## Documento generado

El informe no cambió en este trabajo; no se regeneró el PDF.

## Decisiones adoptadas

- **Retención web del 70% de los cupos disponibles (RN-RES-16):** la
  base del porcentaje son los cupos aún no confirmados ni retenidos por
  el canal personal; los pendientes web no suman a esa base porque son
  justamente lo que se limita. El tope es el piso de 0.7 por la
  disponibilidad, con un mínimo de 1 cupo solicitable por web mientras
  haya capacidad real: así el último cupo no queda bloqueado para la
  web y el personal conserva el canal presencial.
- **Pago del cliente bloqueado mientras el anticipo espera validación:**
  la pasarela avisa que el anticipo está registrado y deshabilita el
  formulario hasta que el personal lo valide; evita estados confusos
  con dos pagos en revisión.
- **Manifiesto por canal (RN-RES-21):** el cliente puede reducir su
  grupo, no ampliarlo; el canal personal conserva la flexibilidad de
  ampliarlo, con la revalidación de cupos y monto que ya existía.
- **Mínimo del 30% solo en el primer anticipo (RN-PAG-01):** los
  anticipos adicionales, que respaldan un total que creció con el
  manifiesto, solo respetan el saldo pendiente. La confirmación exige
  la suma de los anticipos validados contra el mínimo del total
  vigente, de modo que ampliar el grupo ya no puede dejar la
  confirmación en calle.
- **Avisos flotantes centralizados:** el composable `useAvisos` uniforma
  el resultado de las acciones (éxito, fallo de la API y atención); los
  avisos fijos de la página quedan para los errores de carga de listas.
- **Montos con `BaseCampoMoneda`:** los importes de pagos se escriben
  con el componente del sistema de diseño, que elimina el salto de
  +1 que `UInputNumber` provocaba al salir del campo por el ajuste al
  paso.

## Cambios de contenido

### Base de datos

- Caída de la restricción `uq_pago_reserva_tipo`: puede haber varios
  pagos por tipo y el tope real lo aplica `fn_registrar_pago`, que no
  deja superar el saldo pendiente (RN-PAG-02).
- `fn_registrar_pago`: el saldo se paga por partes, cada pago reduce el
  pendiente y pueden sumarse varios hasta cubrirlo (RN-PAG-05); el
  mínimo del 30% se exige solo al primer anticipo.
- `fn_confirmar_reserva`: exige que la suma de los anticipos validados
  cubra el mínimo del 30% del total vigente (RN-RES-18).
- `fn_crear_reserva` y `fn_revalidar_reserva`: retención web del 70% de
  los cupos disponibles con mínimo de 1 (RN-RES-16).
- `fn_guardar_manifiesto`: en el canal web rechaza un manifiesto con
  más pasajeros que los solicitados (RN-RES-21).
- `vista_saldo_reserva`: anticipo y saldo pagado suman todos los pagos
  no anulados de su tipo.
- Actualización nueva
  `2026-11-25-pagos-parciales-retencion-70.sql`, aplicada sobre la base
  viva en dos pasadas para comprobar su idempotencia.
- Cadena de actualizaciones reparada: la vista de disponibilidad de la
  actualización del 20 de noviembre se recrea solo si la base aún no
  tiene la versión nueva; la semilla de proveedores se adapta a la
  forma de la base con o sin la columna `tipo`; la columna, la
  restricción y el disparador del código de salida son idempotentes.
  Con la cadena completa, la base quedó con la finalización de
  reservas de `fn_actualizar_salida` (T-HU-07.4), que las ejecuciones
  anteriores interrumpidas nunca habían aplicado.
- Pruebas SQL al día: `reglas-pagos.sql` con 15 comprobaciones (saldo
  parcial, segundo pago del mismo tipo, tope por saldo y suma de
  anticipos tras crecer el manifiesto) y `reglas-reservas.sql` con 27
  (retención del 70% al crear y al modificar, manifiesto web sin
  superación y salida realizada que finaliza).

### Web

- `tokens.css`: escalas completas de 50 a 950 para los semánticos de
  estado y mapeo de `--ui-color-success/warning/error/info-*` a los
  tokens propios. Sin ese mapeo, Nuxt UI resolvía las variables en una
  referencia circular y los componentes de error, advertencia, éxito e
  información salían sin fondo ni color de texto.
- `useAvisos` (composable nuevo): avisos flotantes de éxito, fallo y
  atención; lo usan la bandeja de solicitudes, «Mis reservas» y el
  panel de pagos.
- `ResumenPagos`: para el personal integra el registro de un pago de
  oficina que reacciona al estado de los pagos: sin anticipo propone el
  mínimo del 30%; con anticipo pasa al saldo y propone el pendiente,
  abonable por partes; el monto que el usuario escribió se respeta y
  las sugerencias solo se reponen mientras el formulario no se toque.
- `FormularioPago`: detección automática del estado del anticipo;
  aviso y bloqueo mientras espera validación; saldo por partes con
  tope en la interfaz.
- `Manifiesto`: el canal web no agrega más filas que las solicitadas,
  botón «Agregar mi ficha como pasajero» con la ficha de la cuenta en
  sesión y aviso flotante al guardar.
- Tablas de «Solicitudes» y «Mis reservas»: badges de manifiesto
  pendiente y de saldo pendiente en cada fila.
- API: la lista de reservas entrega `pasajerosRegistrados`;
  `/api/cuenta` devuelve la ficha del cliente en sesión para el
  manifiesto; `anticipoValidado` se calcula por suma; el código
  `saldo_incompleto` ya no existe.
- `web/db/schema.ts` refleja la caída de la restricción de pagos.
- Textos nuevos y ajustados en español e inglés, entre ellos la ayuda
  de la cantidad de la solicitud web, que ahora distingue el tope de 4
  pasajeros por solicitud (RN-RES-15) de la retención del 70%.

### Documentación

- `sistema/reglas-negocio.md`: RN-RES-16 reformulada con la base del
  porcentaje y el mínimo; RN-PAG-01, RN-PAG-02 y RN-PAG-05 con pagos
  por partes; RN-RES-21 con la regla por canal.
- `sistema/historias-usuario/historias-scrum.md` e
  `historias-usuario.md`: HU-06 y T-HU-06.4 al 70% y HU-14 con el
  comportamiento nuevo.
- `bd/diccionario-datos.md`: la ficha de pagos sin unicidad por tipo y
  la vista de saldo con sumas.
- `web/docs/design-system.md`: el mapeo semántico documentado como
  obligatorio, con la explicación de la referencia circular.
- `web/docs/componentes.md`: `ResumenPagos` con el formulario de
  oficina; `web/docs/arquitectura.md`: los avisos flotantes como parte
  de la capa de composables.

## Validación realizada

- `npm run typecheck --workspace web`, `npm run build --workspace web`
  y `npm run db:check --workspace web` sin errores.
- `make db-probar`: pagos y reservas sin fallos, con `ROLLBACK` final.
- `make db-actualizar` completo: la cadena de doce actualizaciones y
  `permisos.sql` termina sin errores y una segunda pasada confirma la
  idempotencia.
- Revisión del desglose de pagos dentro de la base: la vista de saldo
  suma por tipo y `anticipoValidado` corresponde con la suma de
  anticipos validados.

## Archivos modificados

Base: `bd/esquema.sql`,
`bd/actualizaciones/2026-11-25-pagos-parciales-retencion-70.sql`
(nuevo), `bd/actualizaciones/2026-11-20-reglas-paquetes.sql`,
`bd/actualizaciones/2026-11-23-proveedores-cotizaciones.sql`,
`bd/actualizaciones/2026-11-24-codigo-de-salida.sql`,
`bd/pruebas/reglas-pagos.sql`, `bd/pruebas/reglas-reservas.sql`,
`bd/diccionario-datos.md`.
Web: `web/db/schema.ts`, `web/shared/types/api.ts`,
`web/server/api/cuenta.get.ts`, `web/server/utils/pagos.ts`,
`web/server/utils/pasajeros.ts`, `web/server/utils/reservas.ts`,
`web/app/composables/useAvisos.ts` (nuevo),
`web/app/composables/useMensajeError.ts`,
`web/app/components/pagos/{FormularioPago,ResumenPagos}.vue`,
`web/app/components/pasajeros/Manifiesto.vue`,
`web/app/pages/{solicitudes,mis-reservas}.vue`,
`web/app/design/tokens.css`, `web/app/i18n/locales/{es,en}.ts`,
`web/docs/{design-system,componentes,arquitectura}.md`.
Documentación: `sistema/reglas-negocio.md`,
`sistema/historias-usuario/{historias-scrum,historias-usuario}.md`,
`docs/changelog/`.

## Pendientes o decisiones para el siguiente trabajo

- Aviso al cliente cuando el personal valida su anticipo; hoy lo ve al
  reabrir «Pagos» o el diálogo de pago.
- Ejecución y registro de las devoluciones (RN-PAG-07) y pasarela real.
- Correo: verificación y avisos de HU-16.
- Diagrama de secuencia de HU-17, sin representación propia en
  `sistema/diagramas/uml/secuencia/`.
