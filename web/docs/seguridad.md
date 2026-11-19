# Seguridad

El sistema sigue las recomendaciones de OWASP que menciona el informe. Esta
es la lista corta de lo que aplica.

## Validación de la entrada

- **Todo lo que cruza la red se valida con Zod** en el servidor, antes de
  tocar la base.
- Los identificadores son enteros positivos; los textos tienen longitud
  máxima; los correos se validan como correo.
- Los parámetros se mandan como parámetros, nunca concatenados.

## Consultas

- Drizzle parametriza: no se concatena SQL con datos de la persona usuaria.
- Las reglas con bloqueo de fila se ejecutan dentro de la base, en una
  transacción: la aplicación no puede saltarse el bloqueo.
- El filtro por cliente se aplica en la consulta, no en la plantilla.

## Contraseñas y sesiones

- Better Auth guarda el hash; la aplicación nunca ve la contraseña en claro.
- La sesión es una cookie `httpOnly` con expiración; la biblioteca la
  invalida al cerrar sesión o cambiar la contraseña.
- El token no se guarda en el almacenamiento del navegador.

## Secretos

| Secreto | Dónde vive |
|---|---|
| `DATABASE_URL` | Variable de entorno; nunca en el repositorio |
| `BETTER_AUTH_SECRET` | Variable de entorno (`openssl rand -base64 32`) |
| `CRON_SECRET` | Variable de entorno; protege el barrido diario |
| Contraseña de la base | La de Neon; en producción, de mínimos privilegios |

- `.env.example` documenta las variables **sin valores**. Los valores reales
  viven en Vercel y en el `.env` local, que está ignorado.
- Un secreto no se escribe en el código, no se imprime en los registros y no
  se manda a terceros sin decidirlo antes.

## Rutas de la API

- Las rutas que modifican datos exigen sesión y, cuando corresponde, rol.
- El barrido diario exige `CRON_SECRET` en `Authorization`.
- Las rutas que devuelven datos de un cliente filtran por su identificador:
  un `id` en la URL no da acceso a otra ficha.

## Errores

El cliente recibe un mensaje útil y un código; el detalle va al registro del
servidor. Los mensajes de la base se traducen en la interfaz.

## Pendientes

- **Límites de tasa** en ingreso y envío de mensajes; Better Auth trae uno
  que hay que configurar.
- **CORS:** la aplicación y la API comparten origen; si aparece otro
  dominio, se define explícitamente.
- **Cabeceras de seguridad** en Vercel o en un middleware de Nitro.
- **Auditoría** de operaciones sensibles, además de la tabla `acceso`.

## Antes de publicar

- [ ] Los secretos están en Vercel, no en el repositorio.
- [ ] `BETTER_AUTH_SECRET` es distinto del de desarrollo.
- [ ] El barrido diario está protegido.
- [ ] Las rutas de clientes filtran por cliente.
- [ ] Las entradas están validadas con Zod.
- [ ] No se registran contraseñas ni datos sensibles.
