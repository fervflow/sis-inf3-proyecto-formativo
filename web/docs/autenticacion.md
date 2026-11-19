# Autenticación y acceso

## Better Auth

Better Auth es una **biblioteca**, no un servicio: las tablas `session`,
`account` y `verification` viven en la base del negocio. La tabla `user` se
llama `usuario`, porque `user` es palabra reservada en SQL.

La configuración está en `server/utils/auth.ts` y el manejador en
`server/api/auth/[...all].ts`.

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

## Proteger una ruta

```ts
export default defineEventHandler(async (event) => {
  const sesion = event.context.session
  if (!sesion?.user) {
    throw createError({ statusCode: 401, statusMessage: 'No autorizado' })
  }
  if (sesion.user.idRol !== 1 /* ADMIN */) {
    throw createError({ statusCode: 403, statusMessage: 'Sin permisos' })
  }
  // …
})
```

- **401**: no hay sesión. **403**: la sesión no alcanza.
- La comprobación va en el servidor: ocultar un botón no es un permiso.

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

## Lo que no se automatiza

| Acción | Quién la ejecuta |
|---|---|
| Confirmar una solicitud pendiente | El personal, dentro del plazo |
| Validar un pago registrado | El personal |

El sistema no las hace solo, aunque la cuenta sea del cliente: es lo que
sostiene el «mismo proceso validado» en los dos canales.

## Pendientes

- [ ] Correo de verificación y restablecimiento de contraseña.
- [ ] Crear la primera cuenta de administrador y asignarle el rol.
- [ ] Proteger las vistas por rol en el cliente, como complemento del
      servidor.
