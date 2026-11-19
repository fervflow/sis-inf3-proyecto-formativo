# Autenticación y acceso

## Better Auth

Better Auth es una **biblioteca**, no un servicio: las tablas `session`,
`account` y `verification` viven en la base del negocio. La tabla `user` se
llama `usuario`, porque `user` es palabra reservada en SQL.

La configuración está en `server/utils/auth.ts` y el manejador en
`server/api/auth/[...all].ts`.

## Cuentas internas (MVP)

El MVP no envía correo. Para que la identidad funcione sin proveedor:

- **El nombre de usuario es el identificador.** Better Auth exige un
  correo; se guarda uno interno, `usuario@vizcacha.tours`, que no recibe
  ni envía mensajes. La regla vive en `shared/usuarios.ts`.
- **El registro público está cerrado.** Cualquier llamada a
  `/api/auth/sign-up/*` responde 404; las cuentas las crea únicamente el
  administrador desde `/admin/usuarios`.
- **La contraseña inicial es el nombre de usuario.** Al primer ingreso, el
  middleware obliga a cambiarla (`usuario.debe_cambiar_password`).
- **El usuario no puede recuperar la contraseña solo.** El
  restablecimiento lo hace un administrador, que la devuelve al nombre de
  usuario y cierra las sesiones abiertas.

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
| `TURISTA` | Cliente | Consulta, solicita reservas, registra pagos y sigue sus reservas |

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

`/admin/usuarios` permite crear cuentas, cambiar el rol, bloquear o
activar y restablecer la contraseña. Reglas:

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

- La cuenta es opcional: `cliente.id_usuario` admite nulo.
- El documento es único en la ficha; la cuenta se vincula a una ficha como
  máximo.
- Una cuenta puede bloquearse (`usuario.estado`) sin borrar su historial.
- El correo real del cliente, si lo da, va en `cliente.correo`; el de
  `usuario` es interno.

## Lo que no se automatiza

| Acción | Quién la ejecuta |
|---|---|
| Confirmar una solicitud pendiente | El personal, dentro del plazo |
| Validar un pago registrado | El personal |

El sistema no las hace solo, aunque la cuenta sea del cliente: es lo que
sostiene el «mismo proceso validado» en los dos canales.

## Límites conocidos del MVP

- Sin verificación de correo ni recuperación por correo.
- La contraseña inicial es adivinable; se compensa con registro cerrado,
  cambio obligatorio y el límite de intentos de Better Auth.
- No hay solicitud pública de acceso: el administrador crea todas las
  cuentas.

## Pendientes

- [ ] Formulario público de solicitud y bandeja de aprobación.
- [ ] Correo real: verificación y avisos de HU-16.
- [ ] Proteger las vistas por rol en el cliente, como complemento del
      servidor.
