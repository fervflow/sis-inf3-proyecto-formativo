# La web del sistema

Aplicación web del sistema de gestión de paquetes turísticos y reservas de
Vizcacha Tours. Es el segundo módulo del monorepo: el informe está en la
raíz.

- **Marco:** Nuxt 4 (Vue 3, Nitro), con Nuxt UI y un sistema de diseño
  propio (`app/design/`).
- **Base de datos:** PostgreSQL en Neon, con Drizzle ORM.
- **Identidad:** Better Auth, con las tablas de sesión en la misma base.
- **Despliegue:** Vercel, con la carpeta raíz en `web/`.

## Documentación

| Documento | Contenido |
|---|---|
| `AGENTS.md` | Reglas operativas y a qué documento leer según la tarea |
| `docs/README.md` | Arquitectura, convenciones, diseño, datos, auth y pruebas |
| `../sistema/reglas-negocio.md` | Catálogo canónico de reglas de negocio |

## Requisitos

- Node.js 22 o superior; el repositorio fija la versión con `mise.toml`.
- Una base PostgreSQL en Neon (alcanza el plan gratuito).
- La CLI de Neon: `npm i -g neon@latest`.

## Puesta en marcha

1. **La base ya está creada** en Neon: proyecto
   `wandering-base-66944645`, rama `production`, región **AWS South America
   (São Paulo)**. La configuración está en `neon.ts`, en la raíz.

2. **Traer las variables de la rama:**

   ```bash
   neon login        # la primera vez
   neon env pull     # o: make neon-env
   ```

   La CLI escribe `.env.local` en la raíz con `DATABASE_URL` (pooled) y
   `DATABASE_URL_UNPOOLED` (directa).

3. **Declarar los secretos** que la CLI no trae:

   ```bash
   echo 'BETTER_AUTH_SECRET=…' >> .env.local   # openssl rand -base64 32
   echo 'BETTER_AUTH_URL=http://localhost:3000' >> .env.local
   echo 'CRON_SECRET=…' >> .env.local
   ```

4. **Crear el esquema.** La fuente canónica es `bd/esquema.sql`:

   ```bash
   make db-crear
   ```

   Crea el esquema `turismo` completo: tablas, vistas, funciones y
   disparadores. Si la base ya existe, aplicar las actualizaciones con
   `make db-actualizar`.

5. **Instalar y levantar:**

   ```bash
   npm install     # en la raíz: instala el espacio de trabajo
   make web-dev
   ```

   La aplicación queda en `http://localhost:3000`.

6. **Crear la cuenta administradora.** El registro público está cerrado:

   ```bash
   node web/scripts/crear-admin.mjs administrador
   ```

   Entra con `administrador` / `administrador`; la aplicación obliga a
   cambiar la contraseña en el primer ingreso.

> **Orden de los archivos de entorno.** En Node gana el primer valor
> cargado. La aplicación carga `web/.env`, el `.env` de la raíz y
> `.env.local` de la raíz, en ese orden. Un `web/.env` con valores de
> ejemplo tapa los de Neon: ese archivo solo sirve para desvíos locales.

## Estructura

```text
web/
├── AGENTS.md              Guía operativa
├── docs/                  Documentación de la web
├── app/                   Interfaz: componentes, composables, diseño, i18n y páginas
├── server/                API, middleware y utilidades de Nitro
├── shared/types/          Tipos compartidos
└── db/schema.ts           Esquema en TypeScript (refleja bd/esquema.sql)
```

## Decisiones de diseño

- **El cupo se valida en la base.** Las reglas que bloquean filas (crear
  reserva, cambiar capacidad, confirmar) son funciones PL/pgSQL. La
  aplicación las llama con una sentencia.
- **El controlador sin estado de Neon alcanza.** No hacen falta conexiones
  abiertas ni WebSocket, lo que simplifica el despliegue.
- **El vencimiento no depende de un proceso.** Una solicitud vencida deja
  de ocupar cupo por cálculo de las vistas; el barrido diario solo limpia
  el estado y deja la auditoría.
- **Better Auth es una biblioteca.** Sus tablas viven en la base del
  negocio; `user` se llama `usuario` porque es palabra reservada en SQL.

## Despliegue en Vercel

1. Importar el repositorio y fijar **Root Directory = `web`**.
2. Declarar `DATABASE_URL`, `BETTER_AUTH_SECRET`, `BETTER_AUTH_URL` (con el
   dominio) y `CRON_SECRET`.
3. Vercel detecta Nuxt y compila solo. El plan gratuito permite el barrido
   diario de `vercel.json`.

## Pendientes

- [x] Cuentas internas, ingreso y administración de usuarios.
- [x] Crear la primera cuenta de administrador y su rol.
- [x] Paquetes turísticos y fichas de clientes.
- [x] Reglas de paquetes y salidas, con lugares, servicios incluidos e itinerario.
- [x] Salidas programadas: alta, edición, estados y control de duplicados.
- [x] Proveedores y vínculos con los paquetes.
- [x] Cotizaciones desde una salida, con número automático y condiciones.
- [x] Semilla de datos de prueba (clientes, proveedores y una cotización).
- [ ] Solicitud pública de acceso y bandeja de aprobación (post-MVP).
- [ ] Correo: verificación y avisos de HU-16 (post-MVP).
- [ ] Páginas y rutas de API del resto de las historias.

Las 17 historias y sus 40 tareas son el plan de desarrollo; el tablero
lleva el estado.
