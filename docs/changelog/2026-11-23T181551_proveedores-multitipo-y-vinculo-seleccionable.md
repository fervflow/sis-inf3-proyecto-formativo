# Proveedores con varios tipos de servicio y vínculo seleccionable

- **Fecha:** 23 de noviembre de 2026, 18:15 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios; el trabajo no modifica el informe)
- **Alcance:** un proveedor declara uno o varios tipos de servicio, y al
  vincularlo a un paquete el servicio se elige de los tipos declarados,
  con detalle opcional.

## Antecedente

El tipo del proveedor era un solo valor y el servicio del vínculo con el
paquete era texto libre: al vincular se podía escribir cualquier servicio,
incluso uno que el proveedor no presta, y la ficha no dejaba registrar a
una empresa que ofrece más de un tipo de servicio. El catálogo ya tenía
registrado el refinamiento como pendiente (§14 de la iteración anterior).

## Decisiones aplicadas

1. **Varios tipos por proveedor (RN-PRV-02).** Tabla nueva
   `proveedor_tipo (id_proveedor, tipo)`: un proveedor declara de uno a
   cinco tipos, sin repetir. La columna `proveedor.tipo` se retiró.
2. **El vínculo usa un tipo declarado (RN-PRV-06).** La FK compuesta
   `fk_paquete_proveedor_servicio` obliga a que
   `paquete_proveedor.servicio` sea un tipo declarado de ese proveedor:
   la regla vive en la base, no solo en la pantalla.
3. **Detalle opcional.** El vínculo agrega `detalle VARCHAR(200)`, la
   descripción del servicio concreto («Bus Potosí–Uyuni»); el tipo queda
   normalizado y el texto libre se conserva como detalle.
4. **Tipos en uso protegidos.** No se puede retirar de la ficha de un
   proveedor un tipo que un vínculo está usando (`tipo_en_uso`); primero
   se quita o se cambia el vínculo.
5. **Interfaz.** El formulario usa casillas de verificación por tipo con
   validación «marca al menos uno»; el modal de vínculo convierte el
   servicio en una lista de selección que solo ofrece los tipos del
   proveedor elegido, y agrega el detalle opcional. La tarjeta del
   proveedor lista sus tipos y muestra el detalle en cada vínculo.
6. **Migración idempotente.** Crea la tabla de tipos, copia el tipo
   actual de cada proveedor, mapea los servicios libres de los vínculos
   al tipo del proveedor (el texto queda en `detalle`) y retira la
   columna; incluye los proveedores de semilla y los creados desde la
   interfaz.

## Cambios de formato

No hubo cambios de formato en el informe: no se modificó ningún archivo
LaTeX y el PDF conserva sus 21 páginas.

## Cambios de contenido

### Reglas y diccionario

- `RN-PRV-02`: un proveedor declara uno o varios tipos, sin repetir.
- `RN-PRV-06`: el vínculo guarda uno de los tipos declarados, un detalle
  opcional y el costo; un tipo en uso no se retira.
- Se retiró el pendiente de §14 sobre varios servicios por proveedor; el
  refinamiento restante es permitir varios tipos del mismo proveedor en
  un mismo paquete.
- `bd/diccionario-datos.md` describe `proveedor_tipo` y la FK compuesta.

### Esquema y migración

- `proveedor_tipo` nueva con `ck_proveedor_tipo`; `proveedor` sin `tipo`.
- `paquete_proveedor`: `servicio VARCHAR(20)`, `detalle` opcional y FK
  compuesta a `proveedor_tipo`.
- Semilla actualizada: tipos y vínculos de ejemplo con servicio = tipo y
  detalle = descripción.
- `bd/actualizaciones/2026-11-23-tipos-de-proveedor.sql` (nuevo),
  aplicado de forma idempotente en la base de producción.

### Web

- `web/db/schema.ts`: tabla `proveedorTipo` y vínculo con FK compuesta.
- `web/shared/types/api.ts`: `ProveedorAdmin.tipos: TipoProveedor[]`;
  `ProveedorPaquete` y `ProveedorPaqueteResumen` con `detalle`.
- `web/server/utils/proveedores.ts`: Zod de tipos y del vínculo,
  sincronización de tipos en alta y edición, verificación de tipos en uso
  y del servicio declarado en el vínculo.
- Página `/admin/proveedores`: casillas de tipos, servicio seleccionable
  en el vínculo y detalle opcional.
- `proveedores/Tarjeta.vue`: lista de tipos y detalle por vínculo.
- `paquetes/FormularioPaquete.vue`: la ficha del paquete muestra el tipo
  declarado y el detalle del vínculo.
- Textos nuevos y retirados en español e inglés; códigos de error nuevos
  (`tipos_faltantes`, `tipos_repetidos`, `tipo_en_uso`,
  `servicio_no_declarado`).

### Pruebas

- `bd/pruebas/reglas-paquetes.sql`: tres casos nuevos (vínculo con tipo
  declarado, vínculo con tipo no declarado rechazado por la FK compuesta,
  proveedor sin tipos que no puede vincularse); 15 casos en total, todos
  en verde.

## Archivos modificados

- **Reglas y datos:** `sistema/reglas-negocio.md`,
  `bd/diccionario-datos.md`, `bd/esquema.sql`,
  `bd/actualizaciones/2026-11-23-tipos-de-proveedor.sql` (nuevo) y
  `bd/pruebas/reglas-paquetes.sql`.
- **Tipos y servidor:** `web/shared/types/api.ts`,
  `web/db/schema.ts` y `web/server/utils/proveedores.ts`.
- **Interfaz:** `web/app/pages/admin/proveedores.vue`,
  `web/app/components/proveedores/Tarjeta.vue`,
  `web/app/components/paquetes/FormularioPaquete.vue`,
  `web/app/composables/useMensajeError.ts` y los archivos de textos.
- **Registro:** este archivo y la tabla de `docs/changelog/README.md`.

## Validación realizada

- `npm run typecheck --workspace web`: sin errores.
- `npm run build --workspace web`: compila.
- `npm run db:check --workspace web`: el esquema y Drizzle están alineados.
- `bd/pruebas/reglas-paquetes.sql`: 15 casos en verde, incluidos los tres
  nuevos; `bd/pruebas/reglas-reservas.sql`: 13 casos en verde.
- Migración aplicada y verificada en la base de producción: los cuatro
  proveedores conservan sus tipos y los vínculos quedaron con servicio =
  tipo y detalle = descripción original.
- Pruebas de API en desarrollo: alta de un proveedor con tres tipos,
  vínculo con servicio no declarado rechazado (`servicio_no_declarado`),
  vínculo con tipo declarado y detalle guardado, y rechazo de retirar un
  tipo en uso (`tipo_en_uso`). Los datos y cuentas de prueba se
  eliminaron después.

## Pendientes o decisiones

- Un mismo proveedor todavía presta un solo tipo por paquete; permitir
  varios tipos del mismo proveedor en un paquete queda como refinamiento
  en §14 del catálogo.
- El vínculo «comida» de la prueba del usuario quedó mapeado al tipo
  `hospedaje` con detalle «comida»; se recomienda editarlo desde la
  interfaz para describirlo mejor.
- El informe no se modifica en esta iteración.
