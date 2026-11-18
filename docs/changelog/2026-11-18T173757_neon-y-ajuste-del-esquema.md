# Base de datos en Neon y ajuste del esquema para el pooler

- **Fecha:** 18 de noviembre de 2026, 17:37 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios; el trabajo no modifica el informe)
- **Alcance:** la base de datos del sistema se crea en Neon, el esquema se
  aplica allí y la aplicación se conecta a ella. Sobre la marcha aparecieron
  tres incompatibilidades con el pooler de Neon que obligaron a cambiar el
  esquema, las funciones y la forma de leer las variables de entorno.

## Antecedente

El sistema necesitaba una base de datos real para poder probarlo de extremo
a extremo. Se eligió Neon (PostgreSQL sin estado) con la región **AWS South
America (São Paulo)**, la más cercana a Bolivia, y el plan gratuito.

Se descartó el «Managed Better Auth» de Neon: la identidad vive en la
aplicación, con el esquema bajo control y el registro de accesos que exige
el criterio de HU-08.

## Cambios de formato

No hubo cambios de formato en el informe: no se modificó ningún archivo
LaTeX y el PDF conserva sus 21 páginas.

## Cambios de contenido

### La base en Neon

| Dato | Valor |
|---|---|
| Organización | `org-shiny-hat-62410919` |
| Proyecto | `wandering-base-66944645` |
| Rama | `production` (`br-purple-firefly-b6gyzaq8`) |
| Región | `sa-east-1` (São Paulo), PostgreSQL 18 |
| Servicios | Postgres |

En la raíz del repositorio quedaron `neon.ts`, que es la política de la
rama y sí se versiona, y `.neon`, que es el puntero local a la rama y queda
ignorado. La CLI dejó las variables de la rama en `.env.local`:
`DATABASE_URL` (pooled, para la aplicación) y `DATABASE_URL_UNPOOLED`
(directa, para las migraciones).

El esquema se aplicó con el script de creación: 18 tablas, 3 vistas, 10
funciones, 5 disparadores y los tres roles sembrados.

### El esquema va calificado

El pooler de Neon **no acepta el parámetro `search_path` en el arranque de
la conexión**, de modo que la aplicación no puede confiar en el
`search_path` de la sesión. Por eso:

- Las 18 tablas se declaran dentro del esquema con `pgSchema('turismo')` en
  `web/db/schema.ts`, y el SQL crudo lleva `turismo.` delante.
- Las tres vistas siguen funcionando sin cambios: al crearlas, PostgreSQL
  guarda la dependencia con el identificador de la tabla y no con el nombre.

### Cada función fija su propio `search_path`

Las funciones PL/pgSQL heredaban el `search_path` de quien las llamaba. Sin
él, fallaban con «relation "reserva" does not exist». Ahora las diez
funciones declaran:

```sql
SET search_path = turismo, public
```

Así se comportan igual se llame desde la aplicación, desde `psql` o desde
otra herramienta, y un `search_path` manipulado no cambia su comportamiento.

### Las variables se leen en tiempo de ejecución

El servidor compilado no lee archivos `.env`: en producción los inyecta el
panel de despliegue. Para que las credenciales no quedaran escritas dentro
del paquete, la configuración se lee en el servidor, en `server/utils/config.ts`,
con dos formas aceptadas: `DATABASE_URL` (la que deja la CLI de Neon) y
`NUXT_DATABASE_URL` (la propia de Nuxt), que tiene prioridad.

En desarrollo, la aplicación carga sola los archivos de entorno: el de la
aplicación y los de la raíz del repositorio, donde la CLI deja los de la
rama. Como en Node **gana el primer valor**, el orden es `web/.env`, el
`.env` de la raíz y el `.env.local` de la raíz.

En Nuxt 4 la opción `dotenv` es privada, así que la carga se hace con el
`loadEnvFile` nativo de Node, resolviendo las rutas contra la ubicación
del propio `nuxt.config.ts`.

### Comandos

- `make neon-env` (o `neon env pull`): trae las variables de la rama.
- `make db-crear`: aplica el esquema con la conexión **directa**, porque
  las migraciones necesitan operaciones de sesión que el pooler no admite.

### Documentación

- `web/README.md`: la puesta en marcha, con el proyecto ya creado y el
  orden de carga de los archivos de entorno.
- `web/docs/base-de-datos.md`: la conexión pooled y directa, por qué el
  esquema va calificado, por qué las funciones fijan su `search_path` y
  qué variable sirve para qué.
- `web/AGENTS.md`: los comandos y el orden de precedencia de las variables.
- `web/CONFIGURACION.md`: la lista de lo que falta, con lo hecho hasta
  ahora marcado.
- `web/.env.example`: pasa a ser una plantilla; explica que los valores
  reales los deja la CLI de Neon.

## Archivos modificados

- `neon.ts` (nuevo): la política de la rama de Neon.
- `bd/esquema.sql`: las diez funciones fijan su `search_path`.
- `web/db/schema.ts`: las tablas pasan a `pgSchema('turismo')`.
- `web/server/utils/config.ts` (nuevo): la configuración en tiempo de
  ejecución.
- `web/server/utils/db.ts`, `web/server/utils/auth.ts`,
  `web/server/api/health.get.ts`, `web/server/api/disponibilidad.get.ts`,
  `web/server/api/vencer-solicitudes.post.ts`: la configuración nueva y el
  SQL calificado.
- `web/nuxt.config.ts`: carga de los archivos de entorno.
- `web/.env.example`, `web/README.md`, `web/AGENTS.md`,
  `web/docs/base-de-datos.md`, `web/CONFIGURACION.md`, `AGENTS.md`,
  `Makefile`: el flujo de variables, la región y los comandos.
- `.gitignore`: `.neon`, que es estado local de la CLI.

## Validación

- `npm run build --workspace web` compiló, y una búsqueda en el paquete
  generado no encuentra la cadena de conexión: el secreto no queda escrito.
- `npx nuxt typecheck` terminó sin errores.
- Con el servidor levantado contra Neon:
  - `/api/health` respondió `conectado: true`.
  - `/api/disponibilidad` devolvió las salidas de la vista de la base.
  - El alta de cuenta creó el usuario con sus campos del dominio, la fila
    de `account` con el hash y la fila de `acceso` con tipo `ingreso` y
    resultado `permitido`.
  - La sesión se recuperó con la cookie.
  - El barrido diario respondió `{"vencidas":0}` con el secreto y `401`
    sin él.
- Las reglas de negocio se probaron sobre la base real: la reserva de 8
  pasajeros sobre un cupo de 10 se aceptó, una segunda reserva de 5 se
  rechazó por cupo insuficiente y la vista calculó 2 lugares disponibles.
- El servidor de desarrollo levanta la aplicación y se conecta a Neon sin
  exportar variables a mano.
- Después de la prueba se borraron los datos de prueba: la base tiene el
  esquema y los tres roles, sin filas de prueba.
- `make verificar` terminó con cero problemas: 29 archivos revisados, 20
  rutas LaTeX y 29 entradas del árbol del README.
- El PDF sigue en 21 páginas.

## Pendientes

- Declarar `BETTER_AUTH_SECRET`, `BETTER_AUTH_URL` y `CRON_SECRET` en
  `.env.local` y en el panel de Vercel: la CLI de Neon solo trae los de la
  base de datos.
- Crear un rol de la aplicación con menos privilegios que el dueño de la
  base y usarlo en `DATABASE_URL`.
- Crear las ramas de Neon por rama de Git, para las previsualizaciones.
- Publicar la primera versión en Vercel, con Root Directory `web`.
- Escribir la semilla de datos de prueba, que hoy no existe.
