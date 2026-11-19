# Cuentas internas y gestión de usuarios

- **Fecha:** 19 de noviembre de 2026, 15:18 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios; el trabajo no modifica el informe)
- **Alcance:** el MVP deja de depender de un proveedor de correo. Las cuentas
  son internas, las crea un administrador y se identifican con un nombre de
  usuario. Se agrega el alta, el cambio obligatorio de contraseña, el bloqueo
  de cuentas y el panel de administración.

## Antecedente

El ingreso necesitaba verificación por correo, y eso obligaba a contratar un
dominio y un proveedor para enviar mensajes. Para el MVP se decidió lo
contrario: no se envía correo y la identidad se maneja dentro del sistema.

La decisión tiene un costo explícito: la contraseña inicial es el nombre de
usuario y no hay recuperación por correo. Se compensa con el registro
público cerrado, el cambio obligatorio en el primer ingreso y el límite de
intentos de Better Auth.

## Cambios de formato

No hubo cambios de formato en el informe: no se modificó ningún archivo
LaTeX y el PDF conserva sus 21 páginas.

## Cambios de contenido

### La cuenta sin correo

- El nombre de usuario es el identificador visible. Better Auth sigue
  exigiendo un correo, así que se guarda uno interno con el dominio
  `vizcacha.tours`, que no recibe ni envía mensajes.
- El nombre de usuario no tiene columna propia: se deriva del correo
  interno, de modo que la unicidad la garantiza una sola columna.
- El correo real del cliente, si lo da, va en `cliente.correo`; el de
  `usuario` es interno.
- Las reglas viven en `web/shared/usuarios.ts` y las usan la interfaz y el
  servidor: normalización, largo mínimo, patrón y nombres reservados.

### Base de datos

- `usuario.debe_cambiar_password BOOLEAN NOT NULL DEFAULT false`: indica
  que la cuenta usa la contraseña inicial. La columna se agregó a
  `bd/esquema.sql` y a `web/db/schema.ts`.
- Se aplicaron dos actualizaciones sobre la base de producción, en
  `bd/actualizaciones/`: la columna nueva y la corrección del disparador de
  fecha.
- **Defecto encontrado:** el disparador `tr_user_actualizacion` llamaba a la
  función que escribe `fecha_actualizacion`, columna que `usuario` no tiene
  porque es de Better Auth y usa `updated_at`. Cualquier `UPDATE` sobre una
  cuenta fallaba. Se agregó `fn_actualizar_fecha_usuario()` y el disparador
  ahora la usa.
- No se creó la tabla de solicitudes de acceso: se decidió que el
  administrador cree todas las cuentas en esta etapa.

### Autenticación

- El registro público está cerrado: `/api/auth/sign-up/*` responde 404. La
  comprobación se hace en `server/api/auth/[...all].ts`, antes del manejador
  de Better Auth, para que no alcance con llamar a la ruta directamente.
- `debeCambiarPassword` es un campo adicional de la sesión, con
  `input: false`.
- El middleware de sesión ahora aplica tres reglas que no pueden quedar solo
  en la interfaz:
  - una cuenta con `estado` distinto de `activo` pierde sus sesiones y la
    petición se corta;
  - una contraseña inicial sin cambiar solo permite llegar a
    `/cambiar-password`;
  - `/admin` y `/api/admin` exigen el rol `ADMIN`.
- El gancho de auditoría registra solo el inicio de sesión. El alta dejó de
  ser un acceso de la persona usuaria porque ahora la hace el administrador.

### API

| Ruta | Qué hace |
|---|---|
| `GET /api/cuenta` | Cuenta de la sesión, o `null` si no hay |
| `POST /api/cuenta/cambiar-password` | Verifica la actual y apaga el indicador |
| `GET /api/admin/usuarios` | Lista de cuentas |
| `POST /api/admin/usuarios` | Alta con rol y contraseña inicial |
| `PATCH /api/admin/usuarios/:id` | Cambia rol o estado |
| `POST /api/admin/usuarios/:id/password` | Restablece y cierra sesiones |

- La autorización se centralizó en `server/utils/autorizacion.ts`
  (`exigirSesion`, `exigirAdmin`).
- La validación del cuerpo se centralizó en `server/utils/validacion.ts`:
  un error de Zod responde 400 con un código traducible.
- El restablecimiento usa el mismo hasher de Better Auth
  (`better-auth/crypto`) y borra las sesiones abiertas.
- Nadie puede modificar su propia cuenta desde el panel: evita que un error
  deje el sistema sin administradores.
- Los errores se devuelven como códigos (`usuario_duplicado`,
  `password_incorrecta`, `propia_cuenta`, etc.), no como frases; la interfaz
  los traduce.

### Interfaz

- `/ingresar`: pide usuario y contraseña; arma el correo interno.
- `/cambiar-password`: contraseña actual, nueva y repetición; valida en el
  cliente y confirma en el servidor.
- `/admin/usuarios`: tabla de cuentas, alta en un diálogo, cambio de rol,
  bloqueo o activación y restablecimiento.
- El encabezado muestra el ingreso o el cierre de sesión y el acceso al panel
  solo para `ADMIN`.
- Todos los textos nuevos están en `es.ts` y `en.ts`.

### Primera cuenta

`web/scripts/crear-admin.mjs` crea la cuenta administradora inicial con rol
`ADMIN` y contraseña igual al usuario. Se ejecutó contra la base de
producción. El script lee los archivos de entorno igual que la aplicación.

### Documentación

- `web/docs/autenticacion.md`: cuentas internas, guardas del middleware,
  panel, límites del MVP y pendientes.
- `web/docs/seguridad.md` y `web/docs/arquitectura.md`: la regla del MVP sin
  correo y las rutas de administración.
- `web/README.md`: la creación de la cuenta administradora y los pendientes
  actualizados.
- `bd/diccionario-datos.md`: el campo nuevo y la diferencia entre el correo
  interno y el del cliente.
- `web/CONFIGURACION.md`: los secretos y el rol de la aplicación quedaron
  marcados como hechos, y el correo pasó a post-MVP.

## Archivos modificados

- `bd/esquema.sql`, `bd/diccionario-datos.md`.
- `bd/actualizaciones/2026-11-19-usuarios-internos.sql` (nuevo).
- `bd/actualizaciones/2026-11-19-fecha-usuario.sql` (nuevo).
- `web/db/schema.ts`.
- `web/shared/usuarios.ts` (nuevo).
- `web/shared/types/api.ts`.
- `web/server/utils/auth.ts`, `web/server/utils/autorizacion.ts` (nuevo),
  `web/server/utils/usuarios.ts` (nuevo), `web/server/utils/validacion.ts`
  (nuevo).
- `web/server/middleware/sesion.ts`.
- `web/server/api/auth/[...all].ts`.
- `web/server/api/cuenta.get.ts` (nuevo).
- `web/server/api/cuenta/cambiar-password.post.ts` (nuevo).
- `web/server/api/admin/usuarios.get.ts` (nuevo).
- `web/server/api/admin/usuarios.post.ts` (nuevo).
- `web/server/api/admin/usuarios/[id].patch.ts` (nuevo).
- `web/server/api/admin/usuarios/[id]/password.post.ts` (nuevo).
- `web/app/app.vue`.
- `web/app/composables/useMensajeError.ts` (nuevo).
- `web/app/pages/ingresar.vue` (nuevo).
- `web/app/pages/cambiar-password.vue` (nuevo).
- `web/app/pages/admin/usuarios.vue` (nuevo).
- `web/app/i18n/locales/es.ts`, `web/app/i18n/locales/en.ts`.
- `web/scripts/crear-admin.mjs` (nuevo).
- `web/README.md`, `web/CONFIGURACION.md`,
  `web/docs/autenticacion.md`, `web/docs/arquitectura.md`,
  `web/docs/seguridad.md`.

## Validación

- `npm run typecheck --workspace web` terminó sin errores.
- `npm run build --workspace web` compiló.
- `make verificar` terminó con cero problemas: 29 archivos revisados, 20
  rutas LaTeX y 9 entradas del árbol del README.
- Pruebas manuales contra la base de producción, con el servidor local:
  - el registro público responde 404;
  - el ingreso con usuario y contraseña inicial crea la sesión;
  - con la contraseña pendiente, `/` y `/admin` redirigen a
    `/cambiar-password`;
  - el cambio de contraseña apaga el indicador;
  - un turista recibe 403 en la API de administración y una redirección en
    la página;
  - el alta desde el panel crea la cuenta con rol y contraseña inicial;
  - el nombre de usuario repetido responde 409 y los datos incompletos 400;
  - el restablecimiento cierra la sesión anterior y permite entrar con la
    contraseña inicial;
  - el bloqueo cierra la sesión y la cuenta queda fuera;
  - un cuerpo inválido responde 400 con código.
- Se comprobó el defecto del disparador y se corrigió antes de seguir con
  las pruebas.
- Los usuarios de prueba se borraron: la base quedó con la cuenta
  administradora inicial y sin filas de prueba.

## Pendientes

- Versionar y desplegar el trabajo en Vercel.
- Corregir el barrido diario: Vercel lo invoca con GET y la ruta es
  `vencer-solicitudes.post.ts`.
- Solicitud pública de acceso y bandeja de aprobación.
- Correo real: verificación, avisos de HU-16 y recuperación de contraseña.
- Revisar si la contraseña inicial debe seguir siendo el nombre de usuario
  cuando exista el envío de correo.
- Escribir pruebas automatizadas del flujo de cuentas; hoy la validación es
  manual.
