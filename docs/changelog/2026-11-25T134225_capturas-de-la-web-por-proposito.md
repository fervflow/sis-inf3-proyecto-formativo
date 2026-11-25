# Capturas de la web del sistema agrupadas por propósito

## Fecha y alcance

25 de noviembre de 2026. Toma de capturas de pantalla de la aplicación
web en desarrollo local y organización en `sistema/capturas/` por
propósito, como material para documentos futuros del proyecto. No
cambió el informe ni la aplicación.

## Documento generado

El informe no cambió en este trabajo; no se regeneró el PDF.

## Decisiones adoptadas

- **Agrupación por propósito:** cuatro carpetas numeradas —
  `01-publico/` (lo que ve quien no ingresa), `02-flujo-reserva-web/`
  (solicitud y reserva del cliente de punta a punta), `03-personal/`
  (atención del personal) y `04-administracion/` (gestión del
  administrador) — con el número del archivo marcando el orden del
  recorrido dentro de cada grupo.
- **Índice con procedencia:** `sistema/capturas/README.md` documenta
  cómo y cuándo se tomaron (ventana de 1440×900, Chromium sin interfaz
  vía Playwright, cuentas de prueba de `bd/datos-prueba.sql`), qué
  reserva nació durante el proceso (`R00000520`) y el aviso del formato
  de fecha del navegador sin interfaz.
- **Flujo principal capturado entero:** solicitud web desde la
  disponibilidad, pasarela del anticipo simulado, manifiesto de
  pasajeros, bandeja del personal con validación del pago y
  confirmación, y «Mis reservas» con la reserva ya confirmada.
- **Datos de demostración reales:** la reserva `R00000520` nació en las
  capturas y queda en la base como estado final coherente del flujo
  (confirmada, saldo Bs 336,00); las cuentas de prueba no cambiaron.
- **Administración con cuenta temporal:** para las páginas de
  `/admin` se creó un administrador temporal con la misma contraseña de
  las cuentas de prueba, se usó solo para capturar y se borró después;
  en la captura de usuarios su fila se ocultó para mostrar solo las
  cuentas reales.

## Cambios de contenido

### Sistema

- `sistema/capturas/`: 27 capturas nuevas en las cuatro carpetas y el
  `README.md` índice.

### Base de datos

- La base de desarrollo quedó desfasada frente a `bd/esquema.sql`:
  `/reportes` respondía 500 porque la vista
  `vista_reservas_por_fecha` no tenía `reservas_finalizadas`. Se
  aplicó la actualización pendiente
  `bd/actualizaciones/2026-11-24-finalizacion-retencion-web.sql`
  directamente con `psql`; el reporte volvió a funcionar y no cambió
  ningún archivo del repositorio.

### Documentación

- `docs/changelog/`: este registro.

## Validación realizada

- Revisión visual de las 27 capturas: render con el sistema de diseño
  aplicado, píldora de herramientas de desarrollo oculta y sin estado
  de error en pantalla.
- Tras la actualización de la base, `/reportes` carga el reporte de
  ocupación completo.

## Archivos modificados

Sistema: `sistema/capturas/` (27 PNG y `README.md`). Documentación:
`docs/changelog/`.

## Pendientes o decisiones para el siguiente trabajo

- La actualización `2026-11-24-codigo-de-salida.sql` no es idempotente:
  al reejecutar `make db-actualizar` su `UPDATE` choca con
  `uq_salida_codigo` porque los códigos ya existen. Convendría guardarla
  con una condición de inexistencia; por eso la actualización pendiente
  se aplicó por archivo.
- Los campos de fecha en las capturas muestran mm/dd/yyyy (locale del
  navegador sin interfaz); retomar con locale es-BO si el documento
  final lo exige.
- Definir en qué documento del informe (anexo u otra sección) entran
  estas capturas y elegir el subconjunto que se publicará.
