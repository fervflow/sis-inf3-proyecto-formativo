# Corrección de las casillas de verificación por clic en la etiqueta

- **Fecha:** 23 de noviembre de 2026, 18:25 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios; el trabajo no modifica el informe)
- **Alcance:** corrección de la asociación de las casillas de verificación
  con su etiqueta: el clic sobre el texto conmutaba la primera casilla del
  grupo en lugar de la propia.

## Antecedente

Al revisar el formulario de proveedores se notó que, en los grupos de
casillas generadas con `v-for`, el clic sobre el texto marcaba o
desmarcaba la primera casilla del grupo y no la correspondiente. El mismo
defecto latía en las casillas de servicios incluidos del formulario de
paquetes.

## Causa

Las casillas no tenían identificador propio, de modo que las etiquetas
quedaban asociadas al primer control del formulario (comportamiento
estándar de una etiqueta con asociación ambigua).

## Cambios aplicados

- `web/app/pages/admin/proveedores.vue`: cada casilla de tipo lleva
  `id` y `name` únicos (`proveedor-tipo-<tipo>`).
- `web/app/components/paquetes/FormularioPaquete.vue`: cada casilla de
  servicio lleva `id` y `name` únicos (`paquete-servicio-<id>`).

## Cambios de formato

No hubo cambios de formato en el informe: no se modificó ningún archivo
LaTeX y el PDF conserva sus 21 páginas.

## Validación realizada

- `npm run typecheck --workspace web`: sin errores.
- `npm run build --workspace web`: compila.
- El clic sobre el texto marca y desmarca la casilla correspondiente en
  los dos grupos.

## Pendientes o decisiones

- El informe no se modifica en esta iteración.
