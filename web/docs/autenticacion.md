# Autenticación y acceso

## Better Auth

Better Auth es una **biblioteca**, no un servicio: las tablas `session`,
`account` y `verification` viven en la base del negocio. La tabla `user` se
llama `usuario`, porque `user` es palabra reservada en SQL.

La configuración está en `server/utils/auth.ts` y el manejador en
`server/api/auth/[...all].ts`.

## Dos clases de cuentas (MVP)

El MVP no envía correo. Para que la identidad funcione sin proveedor:

- **Las cuentas del personal (`ADMIN` y `PERSONAL`) son internas.** El
  nombre de usuario es el identificador: Better Auth exige un correo y se
  guarda uno interno, `usuario@vizcacha.tours`, que no recibe ni envía
  mensajes. La regla vive en `shared/usuarios.ts`.
- **La contraseña inicial del personal es el nombre de usuario.** Al
  primer ingreso, el middleware obliga a cambiarla
  (`usuario.debe_cambiar_password`).
- **El restablecimiento lo hace un administrador**, que la devuelve al
  nombre de usuario y cierra las sesiones abiertas.
- **Las cuentas de cliente se registran ellos mismos.** La página
  `/crear-cuenta` llama a `/api/registro`, que crea la cuenta de Better
  Auth y la ficha del cliente en un solo paso, con el correo real
  obligatorio y único (RN-USU-03 y RN-USU-05). Si el documento ya tiene
  ficha, la cuenta se vincula a ella. El rol nace `CLIENTE` y la
  contraseña la elige la persona.
- **El sign-up de Better Auth sigue cerrado.** Cualquier llamada a
  `/api/auth/sign-up/*` responde 404: el registro propio va por
  `/api/registro`, que controla los datos de la ficha y el rol. El
  dominio interno `vizcacha.tours` queda reservado al personal.

El nombre de usuario no se guarda en una columna aparte: se deriva del
correo interno. Así la unicidad la garantiza una sola columna.

## Alta de la primera cuenta

```bash
node web/scripts/crear-admin.mjs administrador
```

Crea la cuenta con rol `ADMIN` y contraseña inicial igual al usuario. El
script lee las variables de entorno igual que la aplicación.

## Los tres roles

| Código | Rol | Qué hace |
|---|---|---|
| `ADMIN` | Administrador | Usuarios, paquetes, salidas, proveedores y reportes |
| `PERSONAL` | Personal | Atiende, cotiza, registra reservas, confirma y valida pagos |
| `CLIENTE` | Cliente | Consulta, solicita reservas, registra pagos y sigue sus reservas |

El rol vive en `usuario.id_rol`, que apunta a `rol`. Es un campo adicional
de Better Auth: lo controla la aplicación, no el formulario de registro.

## La sesión

```ts
// El middleware adjunta la sesión a la petición.
const session = await useAuth().api.getSession({ headers: event.headers })
event.context = { ...event.context, session }
```

- `server/middleware/sesion.ts` corre en cada petición y no consulta la base
  si no hay cookie.
- `event.context.session` es `null` cuando no hay sesión.
- Cookie, expiración y revocación las maneja Better Auth.

Además, el middleware aplica las reglas que no pueden quedar en la
interfaz:

| Situación | Qué pasa |
|---|---|
| `usuario.estado` no es `activo` | Se borran sus sesiones y se corta la petición |
| `debe_cambiar_password` es true | Solo se puede llegar a `/cambiar-password` |
| Ruta `/admin` o `/api/admin` sin rol `ADMIN` | Redirección o 403 |
| Ruta `/clientes` o `/api/clientes` sin rol `ADMIN` ni `PERSONAL` | Redirección o 403 |

## Proteger una ruta

```ts
import { exigirAdmin, exigirSesion } from '../utils/autorizacion'

export default defineEventHandler(async (event) => {
  const sesion = exigirSesion(event) // 401 si no hay sesión
  exigirAdmin(event) // 403 si el rol no alcanza
  // …
})
```

- **401**: no hay sesión. **403**: la sesión no alcanza.
- La comprobación va en el servidor: ocultar un botón no es un permiso.
- El rol `ADMIN` es el identificador 1 de la semilla de `rol`.

## Panel de usuarios

`/admin/usuarios` permite crear cuentas de `ADMIN` y `PERSONAL`, cambiar el
rol, bloquear o activar y restablecer la contraseña (RN-USU-04). Reglas:

- nadie puede modificar su propia cuenta desde el panel;
- al bloquear, se cierran las sesiones abiertas;
- al restablecer, la contraseña vuelve a ser el nombre de usuario y se
  obliga el cambio en el siguiente ingreso.

## Registro de accesos

La trazabilidad de ingresos es una regla de HU-08, no una función de la
sesión. Por eso existe la tabla `acceso`:

| Columna | Qué guarda |
|---|---|
| `id_usuario` | Quién ingresó |
| `fecha_hora` | Cuándo |
| `tipo` | `ingreso`, `salida` o `intento` |
| `direccion_ip` | Desde dónde |
| `resultado` | `permitido` o `denegado` |

Lo escribe el gancho `after` de Better Auth, en `server/utils/auth.ts`.

## Cuentas de cliente

- Toda cuenta `CLIENTE` tiene exactamente una ficha vinculada
  (`cliente.id_usuario`), creada junto con la cuenta por el registro
  público (RN-USU-02).
- La ficha puede existir sin cuenta: el personal sigue atendiendo a quien
  no se registra; la cuenta la vincula el propio cliente al registrarse.
- El documento es único en la ficha y el correo también lo es
  (`ux_cliente_correo`): el correo es la identidad del registro y el canal
  de contacto (RN-USU-05).
- Una cuenta puede bloquearse (`usuario.estado`) sin borrar su historial.
- El cliente solo ve sus reservas, sus pagos y sus solicitudes: las API
  filtran por la ficha de su cuenta y `/mis-reservas` es la vista propia.

## Lo que no se automatiza

| Acción | Quién la ejecuta |
|---|---|
| Confirmar una solicitud pendiente | El personal, dentro del plazo |
| Validar un pago registrado | El personal |

El sistema no las hace solo, aunque la cuenta sea del cliente: es lo que
sostiene el «mismo proceso validado» en los dos canales.

## Límites conocidos del MVP

- Sin verificación de correo ni recuperación por correo.
- La contraseña inicial del personal es adivinable; se compensa con
  cambio obligatorio y el límite de intentos de Better Auth.
- No hay verificación del correo en el registro de cliente: se acepta el
  correo como dato y el envío real queda fuera del MVP.

## Pendientes

- [ ] Correo real: verificación del registro y avisos de HU-16.
- [ ] Aprobación previa del registro, si la operación la pide: hoy la
      cuenta y la ficha quedan activas al crearlas.
