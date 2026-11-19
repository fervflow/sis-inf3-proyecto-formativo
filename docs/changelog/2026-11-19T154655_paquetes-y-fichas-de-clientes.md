# Paquetes turísticos y fichas de clientes

- **Fecha:** 19 de noviembre de 2026, 15:46 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios; el trabajo no modifica el informe)
- **Alcance:** se implementan las dos historias que el tablero marcaba como
  hechas y todavía no existían en la aplicación: la gestión de paquetes
  turísticos (HU-01) y el registro y la actualización de la ficha del
  cliente (HU-04). Se agrega el permiso de personal para la ficha de
  clientes.

## Antecedente

La columna `Hecho` del tablero tenía tres historias. HU-08 (ingreso y
roles) se había implementado en el trabajo anterior; HU-01 y HU-04 seguían
solo en el papel. Este trabajo las lleva a la aplicación para que la
columna refleje lo que realmente existe.

## Cambios de formato

No hubo cambios de formato en el informe: no se modificó ningún archivo
LaTeX y el PDF conserva sus 21 páginas.

## Cambios de contenido

### Paquetes turísticos (HU-01)

- Página `/admin/paquetes`, solo para administradores.
- Listado ordenado por código, con alta y edición en un diálogo.
- Campos: código, nombre, descripción, duración en días, precio base,
  itinerario, servicios incluidos y estado (`borrador`, `activo`,
  `inactivo`).
- El código se normaliza a mayúsculas y no se repite; un duplicado responde
  409. El alta guarda el usuario creador.
- Validaciones: código de 3 a 20 caracteres con letras, números y guion;
  duración entre 1 y 365 días; precio no negativo; estado admitido.
- El precio se muestra formateado en bolivianos.

### Ficha del cliente (HU-04)

- Página `/clientes`, para administradores y personal de agencia.
- Listado con búsqueda por nombres, apellidos o número de documento; alta
  y edición en un diálogo.
- Campos: tipo y número de documento, nombres, apellidos, correo, teléfono,
  dirección, fecha de nacimiento y estado.
- El documento se guarda en mayúsculas y no se repite por tipo; un
  duplicado responde 409. La base también lo garantiza.
- Validaciones: correo con formato válido, fecha de nacimiento no futura y
  estados `activo` o `inactivo`.

### Permisos

- `exigirPersonal()` en `server/utils/autorizacion.ts`: acepta `ADMIN` y
  `PERSONAL`.
- El middleware de sesión protege `/clientes` y `/api/clientes`; un turista
  recibe 403 en la API y una redirección en la página.
- El encabezado muestra “Clientes” a administradores y personal, y
  “Paquetes” solo a administradores.

### Validación común

- `leerConsulta()` valida la cadena de búsqueda.
- `esDuplicado()` traduce la violación de unicidad de PostgreSQL a un
  conflicto, incluso si dos altas coinciden en el mismo instante.
- `leerCuerpo()` y `leerConsulta()` usan el primer mensaje de Zod que sea un
  código propio (`codigo_invalido`, `fecha_futura`); los mensajes largos
  caen en `datos_invalidos`. La interfaz traduce todos los códigos.

### Documentación

- `web/README.md`: los paquetes y las fichas de clientes quedan marcados
  como hechos.
- `web/docs/autenticacion.md`: la tabla de guardas incluye las rutas de
  clientes.
- `web/docs/arquitectura.md`: las rutas de administración ya estaban
  documentadas; no requirió cambios.

## Archivos modificados

- `web/server/utils/autorizacion.ts`: `ROL_PERSONAL` y `exigirPersonal`.
- `web/server/utils/validacion.ts`: `leerConsulta`, `esDuplicado` y el
  código del primer problema de validación.
- `web/server/utils/paquetes.ts` (nuevo).
- `web/server/utils/clientes.ts` (nuevo).
- `web/server/api/admin/paquetes.get.ts` (nuevo).
- `web/server/api/admin/paquetes.post.ts` (nuevo).
- `web/server/api/admin/paquetes/[id].patch.ts` (nuevo).
- `web/server/api/clientes.get.ts` (nuevo).
- `web/server/api/clientes.post.ts` (nuevo).
- `web/server/api/clientes/[id].patch.ts` (nuevo).
- `web/server/middleware/sesion.ts`: guarda de personal.
- `web/app/pages/admin/paquetes.vue` (nuevo).
- `web/app/pages/clientes.vue` (nuevo).
- `web/app/app.vue`: enlaces del encabezado.
- `web/app/composables/useMensajeError.ts`: códigos nuevos.
- `web/app/i18n/locales/es.ts`, `web/app/i18n/locales/en.ts`.
- `web/shared/types/api.ts`: tipos de paquete y cliente.
- `web/README.md`, `web/docs/autenticacion.md`.

## Validación

- `npm run typecheck --workspace web` terminó sin errores.
- `npm run build --workspace web` compiló.
- Pruebas manuales contra la base de producción, con un administrador
  temporal:
  - paquetes: listado vacío, alta, duplicado 409, código inválido 400,
    edición de nombre, duración, precio y estado;
  - clientes: alta, duplicado 409, correo inválido 400, fecha futura 400,
    edición y búsqueda por apellido y por documento;
  - personal: clientes 200, API de paquetes 403, página de paquetes
    redirigida;
  - turista: clientes 403 y página redirigida;
  - administrador: ambas páginas responden 200.
- Los datos de prueba se borraron: no quedaron paquetes ni clientes de
  prueba, y las cuentas temporales se eliminaron. Las cuentas reales del
  equipo no se modificaron.

## Pendientes

- Versionar y desplegar el trabajo en Vercel.
- Corregir el barrido diario: Vercel lo invoca con GET y la ruta es
  `vencer-solicitudes.post.ts`.
- Continuar con las historias que siguen en `Por hacer` y `En curso`.
- Agregar pruebas automatizadas de paquetes y clientes; hoy la validación
  es manual.
- Evaluar paginación en la lista de clientes cuando el volumen crezca.
- Definir si el código de un paquete debe poder cambiarse después de que
  tenga salidas asociadas.
