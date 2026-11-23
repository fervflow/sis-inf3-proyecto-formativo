# Topes del canal web y desglose público de cupos

- **Fecha:** 23 de noviembre de 2026, 17:46 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios; el trabajo no modifica el informe)
- **Alcance:** corrección del vacío de bloqueo de cupos por solicitudes web
  (RN-RES-15 y RN-RES-16), desglose público de confirmados y pendientes en
  la tarjeta de disponibilidad, y corrección del alcance de una prueba SQL.

## Antecedente

Cualquier visitante podía solicitar todos los cupos disponibles de una
salida con un formulario anónimo y retenerlos 48 horas: nadie más podía
solicitar cupo y la interfaz no distinguía la venta hecha de las
solicitudes que están en revisión. Además, la prueba de confirmación de
reservas buscaba «cualquier pendiente» de toda la tabla y tomaba la reserva
real pendiente de una prueba manual del usuario dentro de su transacción.

## Decisiones aplicadas

1. **Tope por solicitud web (RN-RES-15).** Una solicitud del canal web
   admite como máximo 4 pasajeros; los grupos mayores se atienden por la
   oficina. El canal personal no tiene ese tope.
2. **Tope global de retención (RN-RES-16).** Las solicitudes web
   pendientes vigentes de una misma salida no retienen en conjunto más de
   la mitad del cupo máximo; alcanzado el tope, las nuevas solicitudes web
   se rechazan hasta que el personal confirme o venza alguna. Las
   pendientes del canal personal no cuentan para el tope.
3. **Desglose público.** La disponibilidad entrega a todos los pasajeros
   confirmados y pendientes (antes era solo del personal) y la tarjeta
   muestra la ocupación en una barra de dos segmentos: la parte confirmada
   en el color de marca y la retenida por pendientes en ámbar, sobre la
   misma barra.
4. **Máquina de estados sin cambios.** El cupo sigue ocupándose al crear
   la solicitud; los topes limitan cuánto cupo puede quedar retenido sin
   confirmación, no quién lo retiene.
5. **Prueba con alcance correcto.** La prueba de confirmación ahora busca
   la pendiente de la salida de la prueba; la reserva real del usuario
   quedó intacta (pendiente, con su vencimiento y su historial original).

## Cambios de formato

No hubo cambios de formato en el informe: no se modificó ningún archivo
LaTeX y el PDF conserva sus 21 páginas.

## Cambios de contenido

### Reglas y criterios

- `RN-RES-15` y `RN-RES-16` nuevas en el catálogo y criterios nuevos en
  la historia HU-06 (tope web, retención limitada y desglose público).

### Esquema y migración

- `fn_crear_reserva` agrega las dos verificaciones para `origen = 'web'`.
- `bd/actualizaciones/2026-11-23-tope-solicitudes-web.sql` (nuevo),
  aplicado en la base de producción. La primera aplicación creó una copia
  de la función en el esquema `public` por falta de `search_path`; se
  eliminó.

### Web

- `web/shared/reservas.ts` (nuevo): constantes `SOLICITUD_WEB_
  MAXIMO_PASAJEROS` y `RETENCION_WEB_PORCENTAJE`, compartidas por el
  servidor y la interfaz.
- `web/server/utils/reservas.ts`: tope en Zod (`solicitud_grande`) y
  mapeo de los códigos nuevos.
- `web/app/components/solicitudes/FormularioPublico.vue`: máximo del
  campo de pasajeros fijado por `min(cupo_disponible, 4)`.
- `web/app/components/disponibilidad/Tarjeta.vue`: barra de ocupación de
  dos segmentos (confirmados y pendientes) con desglose en el texto.
- `web/server/api/disponibilidad.get.ts`: el desglose de pendientes y
  confirmados es público; ya no se oculta al cliente.
- Textos y códigos de error nuevos en español e inglés.

### Pruebas

- `bd/pruebas/reglas-reservas.sql`: dos casos nuevos (tope por solicitud
  web y tope global de retención) y corrección del alcance de la
  confirmación; 12 casos en total, todos en verde.
- `bd/pruebas/reglas-paquetes.sql`: sigue pasando sin regresiones.

## Archivos modificados

- **Reglas y datos:** `sistema/reglas-negocio.md`,
  `sistema/historias-usuario/historias-usuario.md`, `bd/esquema.sql`,
  `bd/actualizaciones/2026-11-23-tope-solicitudes-web.sql` (nuevo) y
  `bd/pruebas/reglas-reservas.sql`.
- **Tipos y servidor:** `web/shared/reservas.ts` (nuevo),
  `web/shared/types/api.ts` (desglose público),
  `web/server/utils/reservas.ts` y
  `web/server/api/disponibilidad.get.ts`.
- **Interfaz:** `web/app/components/solicitudes/FormularioPublico.vue`,
  `web/app/components/disponibilidad/Tarjeta.vue` y los archivos de
  textos.
- **Registro:** este archivo y la tabla de `docs/changelog/README.md`.

## Validación realizada

- `npm run typecheck --workspace web`: sin errores.
- `npm run build --workspace web`: compila.
- `bd/pruebas/reglas-reservas.sql`: 12 casos en verde, incluidos el tope
  por solicitud, la avalancha limitada a la mitad del cupo y la venta del
  personal con la retención al tope.
- Pruebas de API en desarrollo: solicitud web de 5 pasajeros rechazada
  (`solicitud_grande`); dos solicitudes web de 4 pasajeros aceptadas y una
  tercera rechazada (`solicitudes_excedidas`). Los datos de prueba se
  eliminaron después.
- Comprobación del desglose público: la salida con 2 confirmados y 4
  pendientes los entrega a un cliente anónimo.
- La base quedó con los datos reales de la prueba del usuario (una reserva
  confirmada y una pendiente) sin residuos.

## Pendientes o decisiones

- HU-13 (cancelaciones) permitirá al personal liberar cupos de inmediato
  ante solicitudes espurias, complementando los topes automáticos.
- El informe no se modifica en esta iteración.
