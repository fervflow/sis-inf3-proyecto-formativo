# Autenticación y acceso

## Better Auth

Better Auth es una **biblioteca**, no un servicio: las tablas `session`,
`account` y `verification` viven en la misma base de datos que los datos
del negocio. La tabla `user` de la biblioteca se llama `usuario` aquí,
porque `user` es palabra reservada en SQL.

La configuración está en `server/utils/auth.ts` y el manejador de rutas en
`server/api/auth/[...all].ts`.

## Los tres roles

| Código | Rol | Qué hace |
|---|---|---|
| `ADMIN` | Administrador | Gestiona usuarios, paquetes, salidas, proveedores y reportes |
| `PERSONAL` | Personal de agencia | Atiende, cotiza, registra reservas, confirma solicitudes y valida pagos |
| `TURISTA` | Cliente | Consulta disponibilidad, solicita reservas, registra pagos y sigue sus reservas |

El rol vive en `usuario.id_rol`, que apunta a la tabla `rol`. Es un campo
adicional de Better Auth: la aplicación lo controla, no el formulario de
registro.

## El rol determina la sesión

```ts
// El middleware adjunta la sesión a la petición.
const session = await useAuth().api.getSession({ headers: event.headers })
event.context = { ...event.context, session }
```

- El middleware `server/middleware/sesion.ts` corre en cada petición y no
  consulta la base si no hay cookie.
- `event.context.session` es `null` cuando no hay sesión.
- La sesión es de Better Auth: cookie, expiración y revocación las maneja
  la biblioteca.

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

- **401** es que no hay sesión; **403** es que la sesión no alcanza.
- La comprobación va en el servidor, nunca solo en la vista: hiding a
  button no es un permiso.

## El registro de accesos

La trazabilidad de los ingresos es una regla del negocio (criterio de
HU-08) y no una función de la sesión de Better Auth. Por eso existe la
tabla `acceso`:

| Columna | Qué guarda |
|---|---|
| `id_usuario` | Quién ingresó |
| `fecha_hora` | Cuándo |
| `tipo` | `ingreso`, `salida` o `intento` |
| `direccion_ip` | Desde dónde |
| `resultado` | `permitido` o `denegado` |

El registro lo escribe el gancho `after` de Better Auth, en
`server/utils/auth.ts`.

## Las cuentas de cliente

- Una cuenta es opcional: un cliente sin cuenta sigue siendo atendido por
  el personal (`cliente.id_usuario` admite valor nulo).
- El documento es único en la ficha del cliente; la cuenta se vincula a
  una ficha, como máximo una.
- Una cuenta puede bloquearse (`usuario.estado`) sin borrar su historial:
  nada se borra.

## Las dos acciones que no se automatizan

| Acción | Quién la ejecuta |
|---|---|
| Confirmar una solicitud pendiente | El personal, dentro del plazo |
| Validar un pago registrado por el cliente | El personal |

El sistema no las hace solo, aunque la cuenta sea del cliente. Son las
reglas que sostienen el criterio de «el mismo proceso validado» en los dos
canales.

## Pendientes

- [ ] Correo de verificación y restablecimiento de contraseña: requieren un
      proveedor de correo (decidir cuál).
- [ ] Crear la primera cuenta de administrador y asignarle el rol.
- [ ] Proteger las vistas por rol en el cliente, como complemento de la
      comprobación del servidor.
