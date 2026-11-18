# Seguridad

## El Referencia

El sistema sigue las recomendaciones de OWASP Foundation que el informe
menciona. Esta es la lista corta de lo que aplica a esta aplicación.

## Validación de la entrada

- **Todo lo que cruza la red se valida con Zod** en el servidor, antes de
  tocar la base. La validación no es opcional en un campo de formulario.
- Los identificadores son números enteros positivos; los textos tienen
  longitud máxima; los correos se validan como correo.
- Los parámetros de las consultas se mandan como parámetros, nunca
  concatenados: Drizzle los escapa.

## Consultas

- Drizzle parametriza: no se concatena SQL con datos que venga de la
  persona usuaria.
- Las reglas con bloqueo de fila se ejecutan dentro de la base, en una
  transacción: la aplicación no puede saltarse el bloqueo.
- Una persona usuaria solo ve lo que le corresponde: el filtro por cliente
  se aplica en la consulta, no en la plantilla.

## Contraseñas y sesiones

- Better Auth guarda el hash de la contraseña; la aplicación nunca ve la
  contraseña en claro ni la compara.
- La sesión es una cookie `httpOnly` con expiración; la biblioteca la
  invalida al cerrar sesión o al cambiar la contraseña.
- El token de sesión no se guarda en el almacenamiento del navegador.

## Secretos

| Secreto | Dónde vive |
|---|---|
| `DATABASE_URL` | Variable de entorno; nunca en el repositorio |
| `BETTER_AUTH_SECRET` | Variable de entorno, generada con `openssl rand -base64 32` |
| `CRON_SECRET` | Variable de entorno; protege el barrido diario |
| Contraseña de la base | La de Neon; la de producción es de mínimo privileges |

- `.env.example` documenta las variables **sin valores**: los valores
  reales viven en el panel de Vercel y en el archivo local `.env`, que
  está ignorado.
- Un secreto no se escribe en el código, no se imprime en los registros y
  no se manda a un servicio de terceros sin decidirlo antes.

## Rutas de la API

- Las rutas que modifican datos exigen sesión y, cuando corresponde, un
  rol.
- El barrido diario exige `CRON_SECRET` en la cabecera `Authorization`.
- Las rutas que devuelven datos de una persona cliente filtran por su
  identificador: un `id` en la URL no da acceso a otra ficha.

## Errores

- El cliente recibe un mensaje útil y un código; el detalle va al
  registro del servidor.
- Los mensajes de la base no se muestran tal cual: se traducen en la
  interfaz.

## Lo que falta decidir

- **Límites de tasa:** las rutas de ingreso y las que envían mensajes
  necesitan un límite por IP. Better Auth trae un límite incorporado que
  hay que configurar.
- **Cors:** la aplicación y la API comparten origen, así que no hace falta
  abrir nada. Si algún día hay otro dominio, se define de forma explícita.
- **Cabeceras de seguridad:** se añaden en la configuración de Vercel o en
  un middleware de Nitro.
- **Auditoría de las operaciones sensibles:** además del `acceso`, queda
  decidir si las reservas canceladas o los pagos validados necesitan un
  registro propio.

## Lista antes de publicar

- [ ] Los secretos están en el panel de Vercel, no en el repositorio.
- [ ] `BETTER_AUTH_SECRET` es distinto del de desarrollo.
- [ ] El barrido diario está protegido.
- [ ] Las rutas que devuelven datos de clientes filtran por cliente.
- [ ] Las entradas están validadas con Zod.
- [ ] No se registran contraseñas ni datos sensibles en el servidor.
