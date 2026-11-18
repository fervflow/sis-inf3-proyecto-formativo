# La web del sistema

Aplicación web del sistema de gestión de paquetes turísticos y reservas de
Vizcacha Tours. Es el segundo módulo del repositorio: el primero es el
informe, que vive en la raíz.

- **Marco:** Nuxt 4 (Vue 3, Nitro) — el servidor de la aplicación y sus
  rutas de API viven en `server/`.
- **Base de datos:** PostgreSQL en Neon, con Drizzle ORM como capa de
  tipos.
- **Autenticación:** Better Auth, con las tablas de sesión y cuentas en la
  misma base de datos.
- **Interfaz:** Nuxt UI como implementación, con un sistema de diseño
  propio (`app/design/`) que manda sobre ella y textos centralizados
  (`app/i18n/`).
- **Despliegue:** Vercel, con la carpeta raíz del proyecto en `web/`.

## Documentación

| Documento | De qué trata |
|---|---|
| [`AGENTS.md`](AGENTS.md) | La guía operativa para agentes y modelos: reglas que no se negocian y a qué documento leer según la tarea |
| [`docs/`](docs/README.md) | Las guías de trabajo: arquitectura, convenciones, sistema de diseño, componentes, tipos, textos, base de datos, autenticación, pruebas, seguridad y flujo de trabajo |

## Requisitos

- Node.js 22 o superior. El repositorio usa [mise](https://mise.jdx.dev)
  para fijar la versión (`mise.toml`).
- Una base de datos PostgreSQL en Neon, con el plan gratuito alcanza.
- La CLI de Neon, para traer las variables de la rama:
  `npm i -g neon@latest`.

## Puesta en marcha

1. **La base de datos ya está creada** en Neon: proyecto
   `wandering-base-66944645`, rama `production`, región
   **AWS South America (São Paulo)**, la más cercana a Bolivia. La
   configuración está en `neon.ts`, en la raíz del repositorio.

2. **Traer las variables de la rama.** La CLI escribe `.env.local` en la
   raíz del repositorio, y la aplicación las carga sola:

   ```bash
   neon login        # la primera vez
   neon env pull    # o: make neon-env
   ```

   Quedan `DATABASE_URL` (pooled, para la aplicación) y
   `DATABASE_URL_UNPOOLED` (directa, para las migraciones).

3. **Declarar los secretos de la aplicación**, que la CLI no trae:

   ```bash
   echo 'BETTER_AUTH_SECRET=…' >> .env.local   # openssl rand -base64 32
   echo 'BETTER_AUTH_URL=http://localhost:3000' >> .env.local
   echo 'CRON_SECRET=…' >> .env.local
   ```

4. **Crear el esquema.** La fuente canónica es el script de la raíz del
   repositorio, y las migraciones van por la conexión **directa**:

   ```bash
   make db-crear
   ```

   El script crea el esquema `turismo` completo: tablas, vistas, funciones
   y disparadores. No hay migraciones porque la base se acaba de crear.

5. **Instalar y levantar.**

   ```bash
   npm install     # en la raíz del repositorio: instala el espacio de trabajo
   make web-dev
   ```

   La aplicación queda en `http://localhost:3000`.

> **Ojo con el orden de los archivos de entorno.** En Node gana el primer
> valor cargado, y la aplicación carga en este orden: `web/.env`, el
> `.env` de la raíz y el `.env.local` de la raíz. Si `web/.env` tiene
> valores de ejemplo, tapa los de Neon: ese archivo solo sirve para
> desvíos locales, y para eso se deja con los valores reales.

## Estructura

```text
web/
├── AGENTS.md              Guía operativa para agentes y modelos
├── docs/                  Documentación de la web
├── app/                   Interfaz (Nuxt 4 usa app/ como carpeta de origen)
│   ├── app.vue            Marco de la aplicación
│   ├── app.config.ts      Tema de Nuxt UI
│   ├── assets/css/        Estilos globales
│   ├── components/base/   Componentes reutilizables (BaseTarjeta, BaseTablaDatos…)
│   ├── composables/       Lógica reutilizable (useTexto, useApi)
│   ├── design/            Sistema de diseño: tokens y tema
│   ├── i18n/              Textos centralizados de la interfaz
│   └── pages/             Vistas
├── server/                Servidor Nitro
│   ├── api/               Rutas de la API
│   │   ├── auth/           Rutas de Better Auth
│   │   ├── disponibilidad.get.ts
│   │   ├── health.get.ts
│   │   └── vencer-solicitudes.post.ts   Barrido diario
│   ├── middleware/         Sesión de la petición
│   └── utils/              Conexión a la base y configuración de Better Auth
├── shared/types/          Tipos compartidos entre interfaz y servidor
└── db/schema.ts            El esquema en TypeScript (refleja bd/esquema.sql)
```

## Decisiones que conviene conocer

- **El cupo se valida en la base, no en la aplicación.** Las reglas que
  necesitan bloquear una fila —crear una reserva, cambiar la capacidad de
  una salida, confirmar una solicitud— están en funciones PL/pgSQL
  (`bd/esquema.sql`). La aplicación las llama con una sola sentencia: la
  atomicidad la garantiza la base, no el transporte.
- **Por eso alcanza el controlador sin estado de Neon.** No hace falta
  mantener conexiones abiertas ni usar el controlador por WebSocket, que
  complica el despliegue en un entorno sin estado.
- **El vencimiento de las 48 horas no depende de un proceso.** Una
  solicitud pendiente cuyo plazo venció deja de ocupar cupo en el momento
  en que expira, porque así lo calculan las vistas. El barrido diario solo
  limpia el estado guardado y deja la auditoría.
- **Better Auth es una biblioteca, no un servicio.** Las tablas
  `session`, `account` y `verification` viven en la base de datos del
  negocio. La tabla `user` de la biblioteca se llama `usuario` aquí, porque
  `user` es palabra reservada en SQL.

## Despliegue en Vercel

1. Importar el repositorio y fijar **Root Directory** en `app`.
2. Declarar las variables de entorno: `DATABASE_URL`, `BETTER_AUTH_SECRET`,
   `BETTER_AUTH_URL` (con el dominio del proyecto) y `CRON_SECRET`.
3. Vercel detecta Nuxt y compila solo. El plan gratuito permite el barrido
   diario declarado en `vercel.json`.

## Lo que falta

Esta carpeta es el arranque: el esqueleto de la aplicación, la conexión con
la base, la autenticación y dos páginas de ejemplo. Las 39 historias del
backlog (`sistema/historias-usuario/historias-usuario.md`) son el plan de
desarrollo, y el tablero (`tablero/tablero.md`) lleva el estado.

Pendientes de la puesta en marcha:

- [ ] Crear la primera cuenta de administrador y su rol.
- [ ] Formulario de ingreso y cierre de sesión en la interfaz.
- [ ] Páginas y rutas de la API de cada historia.
- [ ] Semilla de datos de prueba (paquetes, salidas y clientes ficticios).
