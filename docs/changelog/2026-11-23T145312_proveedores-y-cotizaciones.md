# Proveedores y cotizaciones

- **Fecha:** 23 de noviembre de 2026, 14:53 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios; el trabajo no modifica el informe)
- **Alcance:** cierre de HU-10 (proveedores y vínculos con paquetes) y HU-05
  (cotizaciones), con datos de ejemplo para probar ambos flujos.

## Antecedente

Las tablas `proveedor`, `paquete_proveedor` y `cotizacion` existían en el
esquema, pero no tenían interfaz ni API. Las reglas de negocio las dejaban
fuera del alcance de la primera iteración. Al cerrar HU-02 y HU-03 quedaron
como los dos únicos tickets en curso.

## Decisiones aplicadas

1. **Catálogo de proveedores.** Alta, edición y estado `activo`/`inactivo`.
   El nombre o razón social es único por nombre normalizado. No hay borrado:
   un proveedor con vínculos pasa a inactivo.
2. **Vínculo con paquetes.** Un proveedor puede atender varios paquetes y un
   paquete puede tener varios proveedores. Cada vínculo guarda el servicio y
   su costo; solo un proveedor activo se vincula a un paquete.
3. **El paquete muestra sus proveedores.** La ficha del paquete incluye la
   lista de proveedores vinculados con el servicio y el costo. La gestión se
   hace desde la página de proveedores.
4. **Cotización desde una salida.** Se elige el cliente y una salida futura
   `programada` o `confirmada` de un paquete activo. El precio unitario se
   completa desde la salida y puede ajustarse.
5. **Número automático.** El número se genera como `COT-AAAA-NNN` con una
   secuencia global y no se edita.
6. **Condiciones y vencimiento.** Se agregó `cotizacion.condiciones`. La
   validez no puede ser anterior a la emisión y una cotización fuera de plazo
   pasa a `vencida` al consultar la lista.
7. **Estados.** `borrador`, `enviada`, `aceptada`, `rechazada` y `vencida`.
   Las cotizaciones terminales se consultan en modo lectura; no se editan.
8. **La cotización no ocupa cupo.** No descuenta asientos ni crea una reserva.
   El vínculo con la reserva queda para HU-06.
9. **Datos de ejemplo.** Se sembraron tres proveedores, dos clientes, seis
   vínculos con los paquetes existentes y una cotización de ejemplo
   (`COT-2026-001`).

## Cambios de formato

No hubo cambios de formato en el informe: no se modificó ningún archivo
LaTeX y el PDF conserva sus 21 páginas.

## Cambios de contenido

### Reglas y diccionario

- Se agregaron las secciones de proveedores (`RN-PRV-01` a `RN-PRV-07`) y
  cotizaciones (`RN-COT-01` a `RN-COT-08`).
- Se actualizaron el alcance, los términos canónicos, la trazabilidad de
  HU-10 y HU-05 y las reglas pendientes.
- `bd/diccionario-datos.md` describe el nombre único del proveedor, el
  vínculo con servicio y costo, y las condiciones y totales generados de la
  cotización.

### Esquema y migración

- `ux_proveedor_nombre` para el nombre normalizado del proveedor.
- `condiciones TEXT` en `cotizacion`.
- `seq_cotizacion_codigo` y `fn_generar_codigo_cotizacion`.
- `fn_vencer_cotizaciones` para marcar las vencidas al consultar.
- Semilla idempotente de clientes, proveedores, vínculos y una cotización.

### Web

- Página `/admin/proveedores` con tarjetas, alta/edición, vínculo y desvínculo
  de paquetes.
- Página `/cotizaciones` con tarjetas, alta, consulta y edición según el
  estado.
- La ficha del paquete muestra los proveedores vinculados.
- La navegación agrega «Proveedores» y «Cotizaciones» según el rol.
- El middleware permite cotizaciones a `ADMIN` y `PERSONAL`; los proveedores
  quedan para `ADMIN`.
- Se agregaron los textos en español e inglés y los códigos de error.

### Tablero

- `T-HU-10.1`, `T-HU-10.2`, `T-HU-05.1` y `T-HU-05.2` pasaron a `Hecho`.
- El tablero queda con 40 tarjetas, 24 por hacer, 0 en curso, 0 en pruebas,
  0 listas para producción y 16 hechas.

## Archivos modificados

- **Reglas y datos:** `sistema/reglas-negocio.md`,
  `bd/diccionario-datos.md`, `bd/esquema.sql` y
  `bd/actualizaciones/2026-11-23-proveedores-cotizaciones.sql` (nuevo).
- **Tipos y servidor:** `web/shared/types/api.ts`,
  `web/shared/types/domain.ts`, `web/db/schema.ts`,
  `web/server/utils/proveedores.ts` (nuevo),
  `web/server/utils/cotizaciones.ts` (nuevo),
  `web/server/api/admin/proveedores*` (nuevo),
  `web/server/api/cotizaciones*` (nuevo) y
  `web/server/middleware/sesion.ts`.
- **Interfaz:** `web/app/pages/admin/proveedores.vue` (nuevo),
  `web/app/pages/cotizaciones.vue` (nuevo),
  `web/app/components/proveedores/Tarjeta.vue` (nuevo),
  `web/app/components/cotizaciones/Tarjeta.vue` (nuevo),
  `web/app/components/paquetes/FormularioPaquete.vue`,
  `web/app/components/BarraNavegacion.vue`,
  `web/app/components/base/BaseCampoMoneda.vue` y los archivos de textos.
- **Documentación:** `web/docs/arquitectura.md`,
  `web/docs/base-de-datos.md` y `web/README.md`.
- **Tablero:** `tablero/tablero.md`.
- **Registro:** este archivo y la tabla de `docs/changelog/README.md`.

## Validación realizada

- `npm run typecheck --workspace web`: sin errores.
- `npm run build --workspace web`: compila.
- `make db-actualizar`: ejecuta las migraciones de forma idempotente.
- `make db-probar`: pasan los casos de paquetes y salidas.
- El esquema canónico se creó en una transacción de prueba: 22 tablas, los
  clientes, proveedores y vínculos de ejemplo se insertan sin errores.
- Pruebas de API: alta y edición de proveedor, vínculo y desvínculo; alta de
  cotización, transición a enviada y aceptada, rechazo de edición de una
  cotización terminal y barrido de una cotización vencida.
- Prueba en navegador: tarjetas de proveedores, tarjetas de cotizaciones,
  formulario con precio de la salida, condiciones y totales. Sin errores de
  consola.
- Los datos de prueba de las pruebas de API se eliminaron; se conservaron los
  datos de ejemplo acordados.
- `make verificar` y `make` se ejecutan sin problemas; el PDF conserva sus
  21 páginas.

## Pendientes o decisiones

- El vínculo `paquete_proveedor` guarda un solo servicio por proveedor y
  paquete. Permitir varios servicios del mismo proveedor queda como
  refinamiento posterior.
- La cotización aceptada todavía no origina una reserva: el vínculo
  `reserva.id_cotizacion` se implementará con HU-06.
- El informe no se modifica en esta iteración.
