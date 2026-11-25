# Corrección de la vinculación ficha–cuenta en el registro público

## Fecha y alcance

25 de noviembre de 2026. Corrección en la web del sistema: el registro
público de cuentas de cliente vinculaba la cuenta nueva a una ficha de
cliente existente por documento (RN-USU-03), pero la ficha conservaba
los nombres de su captura original. El personal veía entonces en las
solicitudes pendientes el nombre de otra persona. No cambió el informe,
el esquema ni los textos de la interfaz.

## Documento generado

El informe no cambió en este trabajo; no se regeneró el PDF.

## Diagnóstico

La consulta de reservas del personal resuelve el nombre del cliente
desde la ficha (`cliente`) unida por `id_cliente`; la unión era correcta
y el defecto no estaba allí. En el registro público
(`web/server/api/registro.post.ts`), cuando el documento declarado ya
tenía ficha, la cuenta se vinculaba a ella actualizando únicamente el
correo y el identificador de la cuenta: los nombres, apellidos y
teléfono de la ficha quedaban con los valores de una captura anterior.

Con los datos de demostración, el documento de prueba del registro
coincidió con una ficha precargada sin cuenta. Las reservas creadas
después desde la cuenta nueva mostraron en la bandeja del personal el
nombre de la ficha precargada, distinto del titular real de la cuenta.
La ficha y la cuenta quedaban además con identidades distintas, porque
la cuenta sí guarda los nombres declarados en el registro.

## Decisión adoptada

Al vincular una cuenta a una ficha existente, la ficha adopta también
los datos declarados en el registro: nombres, apellidos, tipo y número
de documento (normalizado) y teléfono. El vínculo sigue siendo el de la
regla (la ficha no se duplica) y la ficha conserva su historial de
reservas y cotizaciones; lo que cambia es que sus datos personales
pasan a ser los de la persona que reclama el documento.

El dato ya dañado en la base se reparó con la misma equivalencia que
aplica el código: la ficha afectada tomó los nombres de la cuenta
vinculada. No hubo cambio de esquema ni de funciones de la base.

## Cambios de contenido

### Web

- `web/server/api/registro.post.ts`: la actualización de la ficha
  vinculada incluye ahora nombres, apellidos, documento y teléfono,
  con comentario del motivo.

### Base de datos

- Reparación de datos: la ficha afectada se alineó con la cuenta
  vinculada (solo filas, sin cambio de `bd/esquema.sql`).

### Documentación

- `docs/changelog/`: este registro.

## Validación realizada

- `npm run typecheck --workspace web` sin errores.
- `npm run build --workspace web` compila sin errores.
- Consulta sobre la base: las reservas pendientes emparejan ahora cada
  cuenta con los nombres de su propia ficha; el caso reproducido
  muestra el nombre del titular de la cuenta.

## Archivos modificados

Web: `web/server/api/registro.post.ts`. Base de datos: reparación de
una fila de `cliente`. Documentación: `docs/changelog/`.

## Pendientes o decisiones para el siguiente trabajo

- Quedó observada una vinculación legítima de otra naturaleza: una
  cuenta interna con una ficha de grupo (origen `personal`). No se
  tocó; conviene revisar que el panel de clientes edite esos datos con
  aviso cuando la ficha ya tiene historial.
- Si se desea que la ficha conserve su ortografía original cuando solo
  cambian mayúsculas o acentos, habría que comparar normalizada y no
  sobreescribir en ese caso.
