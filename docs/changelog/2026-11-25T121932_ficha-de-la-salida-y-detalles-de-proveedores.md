# Ficha de la salida y detalles de servicios de proveedores

## Fecha y alcance

25 de noviembre de 2026. Las tarjetas de salida de los dos canales quedan
clicables y abren la ficha de la salida (HU-18): paquete, mapa del
recorrido con la línea de ruta y las paradas ordenadas, itinerario por
días, servicios incluidos con sus detalles y exclusiones, y proveedores
con los detalles de su servicio. Cada proveedor registra ahora detalles
por cada tipo de servicio declarado (HU-19, RN-PRV-08) y cada salida
admite asignaciones operativas (RN-SAL-23). El itinerario del paquete
pasa del texto libre a una tabla día por día reordenable (RN-PAQ-18) y
los datos de demostración se renuevan con contenido regional. Alcanza al
esquema, las pruebas SQL, los datos de demostración, la API y la
interfaz, el tablero, el backlog con dos historias nuevas y la
estimación recalculada.

## Documento generado

El informe no cambió en este trabajo; no se regeneró el PDF. Las hojas
de estimación sí se regeneraron con los totales nuevos (55 puntos, 54
tareas, 6.875 Bs y cierre estimado el 07/01/2027).

## Decisiones adoptadas

- **La ficha es de la salida, no del paquete:** la abre cualquier
  tarjeta de salida, en la consulta del cliente y en la de gestión; el
  personal la ve de cualquier salida y el visitante solo de las
  programadas de paquetes activos.
- **Costos internos solo para el personal:** la API los envía nulos al
  visitante y al cliente (RN-SAL-24); las asignaciones operativas — el
  guía titular y la unidad concreta — sí se muestran a todos, porque
  responden la pregunta del turista sobre quién guía y con qué se viaja.
- **La oferta del proveedor es del proveedor (RN-PRV-08):** los detalles
  por servicio viven junto al proveedor y se reutilizan en todos los
  paquetes y salidas; la FK compuesta a los tipos declarados garantiza
  que un detalle siempre respalde a un tipo vivo, que se lleva sus
  detalles al retirarse.
- **La asignación operativa es una capa extra, no un reemplazo**
  (RN-SAL-23): la ficha muestra el contrato del paquete y encima lo
  asignado a esa salida concreta, sin maquinaria de herencia ni costos.
- **Itinerario estructurado (RN-PAQ-18):** la tabla
  `paquete_itinerario` reemplaza la columna de texto libre; el
  formulario reordena los días y el servidor renumera al guardar; un
  paquete activo necesita al menos un día.
- **Datos de demostración renovados:** el bloque inicial del semillero
  borra el negocio — conservando las cuentas internas de
  administrador, personal y sistema — y recarga clientes, proveedores
  con detalles (guías, menús con alérgenos, unidades, habitaciones),
  paquetes con itinerario por días y paradas con coordenadas reales de
  la región, salidas futuras con asignaciones y las reservas de
  demostración de siempre.

## Cambios de contenido

### Tablero y backlog

- Tareas nuevas en «Por hacer»: T-HU-18.1 a T-HU-18.5 (ficha de la
  salida) y T-HU-19.1 a T-HU-19.4 (detalles de servicios de
  proveedores), con sus historias, criterios y actores en el backlog y
  en el formato Scrum.
- Tarjeta retroactiva T-HU-14.5 en «Hecho», que documenta el ciclo de
  ajustes de pagos, retención y manifiestos del mismo día.
- Correcciones de consistencia: la tarjeta T-HU-06.4 queda con el 70%
  y T-HU-08.1 con la prioridad de su historia; el exportador volvió a
  correr y el backlog total queda en 19 historias, 55 puntos y 54
  tareas.
- Estimación recalculada con el alcance nuevo: 220 horas-persona, 1,38
  mes-persona, 6.875 Bs, 27,5 días de equipo y cierre estimado el
  07/01/2027, con los dos caminos (flujo y Scrum) coincidiendo en 2,75
  ventanas.

### Base de datos

- Tabla nueva `paquete_itinerario` con PK (`id_paquete`, `dia`),
  título obligatorio y detalle (RN-PAQ-18); la columna
  `paquete.itinerario` se elimina y el disparador de publicación exige
  al menos un día.
- Tabla nueva `proveedor_servicio` con FK compuesta a los tipos
  declarados del proveedor y `ON DELETE CASCADE` (RN-PRV-08).
- Tabla nueva `salida_proveedor` con FK compuesta a los tipos
  declarados, sin costos (RN-SAL-23).
- La semilla de lugares suma diez atractivos con coordenadas reales:
  Casa de la Moneda, Torre de la Compañía, Convento de San Francisco,
  Cementerio de trenes, mercado artesanal de Uyuni, géiseres Sol de
  Mañana, termas de Polques, Laguna Verde, desierto de Siloli y Valle
  de las Rocas.
- Actualización `2026-11-25-ficha-salida-detalles-proveedores.sql`,
  aplicada a la base viva y re-aplicada sin errores junto con toda la
  cadena; la actualización del 20/11/2020 quedó condicional para
  convivir con la columna eliminada.
- Pruebas SQL nuevas: 14 a 16 de `reglas-paquetes.sql` (publicación con
  itinerario por días, detalles con tipo declarado, asignaciones de la
  salida) y ajuste del dispositivo de la prueba 4 a la tabla por días.

### Web

- `GET /api/salidas/[id]` (nuevo): la ficha con paquete, paradas con
  coordenadas, itinerario, servicios, proveedores con sus detalles por
  servicio y asignaciones; cupo calculado como en la vista de
  disponibilidad y costos solo para `ADMIN` y `PERSONAL`.
- Paquetes: el cuerpo lleva `itinerario` como lista de días que el
  servidor renumera 1..n; la validación de publicación cuenta días.
- Proveedores: el cuerpo lleva `detalles` por tipo declarado, con
  reemplazo completo y validación de pertenencia (RN-PRV-08).
- Salidas: el cuerpo lleva `asignaciones`, con validación de proveedor
  activo y tipo declarado, y el listado y la consulta entregan las
  asignaciones guardadas.
- `BaseMapa`: prop `ruta` que dibuja la polilínea del recorrido entre
  las paradas ordenadas, con marcadores numerados.
- `FormularioPaquete`: el itinerario de texto libre da paso a la lista
  reordenable de días, con subir, bajar y quitar, y el mapa previo
  dibuja la ruta.
- `admin/proveedores.vue`: lista de detalles por servicio, con el tipo
  restringido a los declarados; al retirar un tipo se retiran sus
  detalles del formulario.
- `FormularioSalida`: lista de asignaciones con proveedor activo, uno
  de sus tipos declarados y detalle opcional; el mismo proveedor no se
  repite.
- `SalidasFichaSalida` (componente nuevo): encabezado con fechas,
  precio, cupo desglosado y punto de encuentro; mapa con ruta y lista
  de paradas; itinerario por días; incluye y excluye; proveedores con
  sus detalles; asignaciones de la salida; aviso de salida agotada y
  botón de edición solo para el personal.
- Las dos tarjetas de salida emiten `verDetalle` y la página de
  disponibilidad abre la ficha en los dos canales.
- Textos nuevos en español e inglés para itinerario, asignaciones,
  detalles y ficha.

### Documentación

- `sistema/reglas-negocio.md`: RN-PAQ-07 y RN-PAQ-18 (itinerario por
  días), RN-PRV-08, RN-SAL-23 y RN-SAL-24, con la trazabilidad de
  HU-01, HU-02, HU-10, HU-18 y HU-19 al día.
- `bd/diccionario-datos.md`: las tres tablas nuevas, el supuesto 15 y
  el supuesto 17 con la tabla por días.
- `sistema/estimacion/`: los datos de partida, la proyección, el costo
  y las hojas LaTeX recalculados con el alcance nuevo.
- `web/docs/componentes.md`: `FichaSalida`, `BaseMapa` con ruta y
  `FormularioSalida` con asignaciones.

## Validación realizada

- `npm run typecheck --workspace web`, `npm run build --workspace web`
  y `npm run db:check --workspace web` sin errores.
- `make db-probar`: paquetes (23 comprobaciones, con las tres nuevas),
  reservas (27) y pagos (15), sin fallos.
- `make db-actualizar` completo y repetido: la cadena de
  actualizaciones termina sin errores con la columna `itinerario`
  eliminada.
- Recarga de `bd/datos-prueba.sql` dos veces sobre la base viva: el
  borrado conserva las cuentas internas (2 de administrador, 2 de
  personal y la de sistema) y deja 3 paquetes publicados con 9 días de
  itinerario y 12 paradas, 6 proveedores con 13 detalles, 4 salidas con
  4 asignaciones, 3 reservas y 2 pagos.
- Ficha probada en vivo contra el servidor de desarrollo: la salida
  `SAL-2026-001-002` devuelve paradas con coordenadas, itinerario por
  días, servicios, tres detalles de guía y costos nulos para el
  visitante.
- `make tablero-validar` (54 tarjetas) y `make tablero-backlog` sin
  errores; hojas de estimación compiladas.

## Archivos modificados

Base: `bd/esquema.sql`,
`bd/actualizaciones/2026-11-25-ficha-salida-detalles-proveedores.sql`
(nuevo), `bd/actualizaciones/2026-11-20-lugares-servicios.sql`,
`bd/datos-prueba.sql`, `bd/pruebas/reglas-paquetes.sql`,
`bd/diccionario-datos.md`.
Web: `web/db/schema.ts`, `web/shared/types/api.ts`,
`web/server/api/salidas/[id].get.ts` (nuevo),
`web/server/api/admin/paquetes.get.ts`,
`web/server/api/admin/paquetes.post.ts`,
`web/server/api/admin/paquetes/[id].patch.ts`,
`web/server/api/admin/salidas.get.ts`,
`web/server/api/admin/salidas.post.ts`,
`web/server/api/admin/salidas/[id].patch.ts`,
`web/server/utils/{paquetes,proveedores,salidas}.ts`,
`web/app/components/base/BaseMapa.vue`,
`web/app/components/salidas/FichaSalida.vue` (nuevo),
`web/app/components/salidas/{FormularioSalida,Tarjeta}.vue`,
`web/app/components/disponibilidad/Tarjeta.vue`,
`web/app/components/paquetes/FormularioPaquete.vue`,
`web/app/pages/admin/proveedores.vue`, `web/app/pages/disponibilidad.vue`,
`web/app/i18n/locales/{es,en}.ts`, `web/docs/componentes.md`.
Planificación y documentación: `tablero/tablero.md`,
`sistema/historias-usuario/{historias-usuario.md,historias-usuario.csv,historias-scrum.md}`,
`sistema/reglas-negocio.md`,
`sistema/estimacion/{estimacion.md,resumen-estimacion.tex,scrum/resumen-scrum.tex}`,
`sistema/diagramas/uml/procesos/README.md`, `docs/changelog/`.

## Pendientes o decisiones para el siguiente trabajo

- Diagramas del sistema al día con las piezas nuevas (`FichaSalida` y
  las tres tablas) y el diagrama de secuencia de HU-17, que sigue sin
  representación.
- Informe: reflejar las dos historias nuevas si el alcance del
  documento se actualiza.
- Aviso al cliente cuando el personal valida su anticipo; hoy lo ve al
  reabrir «Pagos» o el diálogo de pago.
- Ejecución y registro de las devoluciones (RN-PAG-07) y pasarela real.
- Correo: verificación y avisos de HU-16.
