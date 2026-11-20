# Lo que falta configurar en los servicios

> **Documento provisional.** Es una lista de trabajo: cuando todo esté
> configurado se puede borrar. No forma parte del informe ni de la
> documentación permanente.

## Neon

**Hecho:**

- [x] **Proyecto creado**: `wandering-base-66944645`, organización
      `org-shiny-hat-62410919`, rama `production`, región **AWS South
      America (São Paulo)** (`sa-east-1`), PostgreSQL 18.
- [x] **Configuración en el repositorio**: `neon.ts` y `.neon` (este último
      no se versiona).
- [x] **Variables descargadas** en `.env.local`: `DATABASE_URL` (pooled),
      `DATABASE_URL_UNPOOLED` (directa) y los identificadores de la rama.
- [x] **Esquema creado**: 22 tablas, 3 vistas, 15 funciones y 7
      disparadores, con los tres roles sembrados.
- [x] **Actualización 2026-11-20**: aplicada sobre la base existente
      (lugares, recorrido, servicios, rol `CLIENTE` y reglas de salidas).

**Falta:**

- [x] **Secretos de la aplicación**, en `.env.local` y en Vercel:
      `BETTER_AUTH_SECRET` (`openssl rand -base64 32`), `BETTER_AUTH_URL` y
      `CRON_SECRET`.
- [x] **Rol de la aplicación** con menos privilegios que el dueño de la
      base (`vizcacha_app`, `read_write` sobre `turismo`), usado en
      `DATABASE_URL`.
- [ ] **Ramas de base por rama de Git**: `main` para producción, `develop`
      para desarrollo y una por previsualización.
- [ ] **Vigilar el plan gratuito**: 100 CU-horas, 1 GB de Postgres, 5 GB de
      egreso y 6 horas de historial. El cómputo se pausa a los 5 minutos
      sin uso.
- [x] *Opcional:* activar `pg_stat_statements` para ver consultas lentas.

No se usa el «Managed Better Auth» de Neon: la identidad vive en la
aplicación y el esquema queda bajo control.

**Usuarios del MVP:** el registro público está cerrado y el correo queda
fuera de alcance. Las cuentas se crean desde `/admin/usuarios`; el nombre de
usuario es el identificador y la contraseña inicial. Ver
`docs/autenticacion.md`.

## Vercel

- [x] **Importar el repositorio** y fijar **Root Directory = `web`**.
- [x] **Declarar las variables** en producción:
      `DATABASE_URL` (pooled), `BETTER_AUTH_SECRET`, `BETTER_AUTH_URL` y
      `CRON_SECRET`.
- [ ] **Barrido diario**: ya está en `web/vercel.json`; el plan Hobby
      permite una ejecución al día.
- [ ] **Deployment Protection** para las previsualizaciones.
- [ ] **Dominio** y nameservers o registros DNS.
- [ ] **Producción desde `main`** y previsualización desde cada rama.

## Correo (post-MVP)

**Fuera del MVP.** Las cuentas son internas y no se envía correo; ver
`docs/autenticacion.md`. Queda pendiente para la etapa siguiente.

- [ ] **Elegir proveedor**: Resend (3.000 correos al mes), Postmark o
      Brevo.
- [ ] **Declarar las variables** y conectarlas al gancho
      `sendVerificationEmail` de Better Auth, en `server/utils/auth.ts`.
- [ ] **Decidir si la verificación de correo es obligatoria**.

## Imágenes

Neon Object Storage no está disponible en São Paulo, así que las opciones
son **Vercel Blob** o **Cloudflare R2** (compatible con S3).

- [ ] **Elegir dónde se guardan.**
- [ ] **Declarar las variables del bucket** y dar permiso de escritura al
      rol de la aplicación.

## Entorno local

- [x] **Node.js 22 o superior**, fijado con `mise.toml`.
- [x] **Dependencias instaladas** con `npm install` desde la raíz.
- [x] **`.env.local` en la raíz** con las variables de Neon.
- [ ] **PostgreSQL local** opcional con Podman o Docker:
      `podman run -d --name vizcacha -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres:18`
      y `psql -h 127.0.0.1 -U postgres -f bd/esquema.sql`.

## Git y automatización

- [ ] **Versionar `package-lock.json`**, que ya existe en la raíz.
- [ ] **Proteger la rama principal**: todo pasa por pull request.
- [ ] **GitHub Actions** con `make verificar`, el typecheck y el build.
- [ ] **Convención de commits**, documentada en `web/docs/convenciones.md`.

## Secretos

- [ ] Los secretos viven en Vercel y en Neon, nunca en el repositorio.
- [ ] `BETTER_AUTH_SECRET` y `CRON_SECRET` son distintos en producción.
- [ ] Al salir alguien del proyecto, se rotan los secretos y se desactivan
      sus cuentas.

## Decisiones pendientes

| Decisión | Opciones |
|---|---|
| Correo | Resend, Postmark o Brevo |
| Imágenes | Vercel Blob o Cloudflare R2 |
| Avisos de HU-16 | Solo en la web o también por correo |
| Verificación de correo | Obligatoria o recomendada |
| Rol de la base | Dedicado o el dueño |
| Idioma de la interfaz | Solo español o español e inglés |
| Previsualizaciones | Una rama de Neon por previsualización o solo en `develop` |
