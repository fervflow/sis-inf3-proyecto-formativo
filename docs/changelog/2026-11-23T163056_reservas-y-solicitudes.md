# Reservas y solicitudes con validación de cupos

- **Fecha:** 23 de noviembre de 2026, 16:30 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios; el trabajo no modifica el informe)
- **Alcance:** implementación de HU-06 (registro de reservas con validación
  de cupos) y HU-17 (confirmación de solicitudes y control de su
  vencimiento), en la base, la API y la interfaz de los dos canales.

## Antecedente

El esquema ya contenía las tablas, las funciones PL/pgSQL y las vistas de
reservas, pero la aplicación no tenía ningún endpoint de reservas: las
seis tarjetas de HU-06 y las tres de HU-17 estaban en «Por hacer». El cron
de vencimiento (`vencer-solicitudes`) también existía sin uso visible.

## Decisiones aplicadas

1. **Un proceso para los dos canales.** Toda reserva nace `pendiente` con
   el canal en `origen`: `personal` cuando la crea el personal desde su
   sesión, y `web` cuando la solicita el cliente sin cuenta. La validación
   de cupos vive en `fn_crear_reserva`, que bloquea la fila de la salida.
2. **Solicitud web por documento.** El cliente se identifica con su
   documento; la ficha se reutiliza si existe y se registra con los datos
   de contacto si no existe, sin duplicar el documento.
3. **Cuenta de sistema.** Las reservas del canal web y los vencimientos
   automáticos se firman con una cuenta `sistema` de la semilla, sin
   contraseña en `account`, de modo que nadie puede ingresar con ella.
4. **Vencimiento a 48 horas.** Toda pendiente guarda `fecha_expiracion`;
   al vencer deja de ocupar cupo por cálculo y el barrido diario la pasa a
   `vencida` con auditoría.
5. **Confirmación auditable.** Confirmar limpia el vencimiento y registra
   el cambio en `historial_reserva`; una vencida no puede confirmarse, y
   el intento la marca como `vencida`.
6. **Cotización aceptada puede originar reserva.** El vínculo queda en
   `reserva.id_cotizacion` y la API comprueba que la cotización esté
   aceptada y corresponda al mismo cliente y a la misma salida (RN-COT-08).
7. **Errores traducibles.** Los fallos de la base se clasifican en códigos
   (`cupo_insuficiente`, `solicitud_pendiente`, `solicitud_vencida`,
   `salida_no_disponible`, entre otros) y la interfaz los traduce.
8. **Pruebas de reglas nuevas.** `bd/pruebas/reglas-reservas.sql` cubre
   ocho casos con `ROLLBACK`; `make db-probar` ejecuta todos los archivos
   de `bd/pruebas/`.

## Cambios de formato

No hubo cambios de formato en el informe: no se modificó ningún archivo
LaTeX y el PDF conserva sus 21 páginas.

## Cambios de contenido

### Reglas de negocio

- Se creó la sección «Reservas y solicitudes» con `RN-RES-01` a `RN-RES-13`
  y la máquina de estados de la reserva.
- Se actualizó el alcance del catálogo, la trazabilidad de HU-06 y HU-17,
  y `RN-COT-08` pasó a Vigente.
- Quedan pendientes de otros módulos: manifiesto al confirmar, modificación
  de reservas (HU-07), cancelaciones (HU-13), reportes (HU-11) y pagos.

### Esquema y migración

- `bd/esquema.sql`: semilla de la cuenta de sistema en la sección de
  semillas. No cambió ninguna tabla ni restricción; `web/db/schema.ts`
  quedó alineado.
- `bd/actualizaciones/2026-11-23-cuenta-sistema.sql` (nuevo), aplicado de
  forma idempotente en la base de producción de Neon.

### Web

- `web/server/utils/reservas.ts` (nuevo): esquemas Zod de los dos canales,
  traducción de filas y de errores de la base.
- Endpoints nuevos: `GET /api/reservas` (listado del personal con filtro
  por estado), `POST /api/reservas` (alta en los dos canales) y
  `POST /api/reservas/[id]/confirmar`.
- Corrección de mapeo de errores: `DrizzleQueryError` envuelve el fallo de
  la base y su código va en `cause`; se corrigió en `codigoErrorReserva` y
  en `codigoErrorSalida`.
- Página `/solicitudes` (nueva) para el personal: tabla de ambos canales
  con vencimiento, filtro pendientes/todas, confirmación por fila y alta de
  reserva desde la atención del personal.
- Formulario público `app/components/solicitudes/FormularioPublico.vue`
  (nuevo) y acción «Solicitar» en la página de disponibilidad.
- Navegación con «Solicitudes» para `ADMIN` y `PERSONAL`; el middleware
  restringe la página al personal.
- `useFormato` agregó `fechaHora` para los vencimientos.
- Textos y códigos de error nuevos en español e inglés.

### Tablero

- `T-HU-06.1`, `T-HU-06.2`, `T-HU-06.3`, `T-HU-17.1`, `T-HU-17.2` y
  `T-HU-17.3` pasaron a «En pruebas / QA» con inicio 23/11/2026.

## Archivos modificados

- **Reglas y datos:** `sistema/reglas-negocio.md`, `bd/esquema.sql`,
  `bd/actualizaciones/2026-11-23-cuenta-sistema.sql` (nuevo),
  `bd/pruebas/reglas-reservas.sql` (nuevo) y `Makefile` (`db-probar`
  ejecuta todos los archivos de pruebas).
- **Tipos y servidor:** `web/shared/types/api.ts`
  (`ReservaResumen` extendida), `web/server/utils/reservas.ts` (nuevo),
  `web/server/utils/salidas.ts`, `web/server/api/reservas.get.ts` (nuevo),
  `web/server/api/reservas.post.ts` (nuevo),
  `web/server/api/reservas/[id]/confirmar.post.ts` (nuevo) y
  `web/server/middleware/sesion.ts`.
- **Interfaz:** `web/app/pages/solicitudes.vue` (nuevo),
  `web/app/pages/disponibilidad.vue`,
  `web/app/components/solicitudes/FormularioPublico.vue` (nuevo),
  `web/app/components/BarraNavegacion.vue`,
  `web/app/composables/useFormato.ts`,
  `web/app/composables/useMensajeError.ts` y los archivos de textos.
- **Documentación:** `web/docs/componentes.md`.
- **Tablero:** `tablero/tablero.md`.
- **Registro:** este archivo y la tabla de `docs/changelog/README.md`.

## Validación realizada

- `npm run typecheck --workspace web`: sin errores.
- `npm run build --workspace web`: compila.
- `npm run db:check --workspace web`: el esquema y Drizzle están alineados.
- `bd/pruebas/reglas-reservas.sql`: pasan los ocho casos (creación
  pendiente a 48 horas con auditoría, exceso de cupo, segunda solicitud
  pendiente, canal inválido, confirmación con vencimiento limpio y
  auditado, pendiente vencida que libera cupo y no se confirma, salida
  realizada que no admite reservas).
- `bd/pruebas/reglas-paquetes.sql`: sigue pasando sin regresiones.
- Pruebas de API en desarrollo: solicitud web anónima que crea la ficha y
  la reserva; alta personal; listado por estado con vencimiento;
  confirmación; rechazo de duplicado (`solicitud_pendiente`), de exceso de
  cupo (`cupo_insuficiente`) y de confirmación vencida
  (`solicitud_vencida`); 401 sin sesión.
- Comprobación del barrido `fn_vencer_solicitudes_pendientes` y del
  historial de la reserva en la base.
- Los datos de prueba se eliminaron; la base quedó con las fichas y
  paquetes de ejemplo acordados y sin reservas.

## Pendientes o decisiones

- «En pruebas / QA» supera su WIP (6 sobre 2): el equipo revisa y pasa las
  tarjetas a «Hecho» cuando las acepte.
- `make db-probar`, `tablero/validar.py` y `make verificar` exigen `psql` y
  Python, no disponibles en la máquina de trabajo; el formato de las
  tarjetas copia el patrón existente y las pruebas corrieron con un
  ejecutor Node temporal.
- El informe no se modifica en esta iteración.
