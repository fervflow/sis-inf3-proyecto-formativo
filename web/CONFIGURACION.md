# Lo que falta configurar en los servicios

> **Documento provisional.** Es una lista de trabajo: cuando todo esté
> configurado se puede borrar sin más. No forma parte del informe ni de la
> documentación permanente de la web.

Lista de lo que falta para tener el sistema desplegado y funcionando. Está
en el orden en que conviene hacerlo.

## Neon

La base de datos del sistema. Plan gratuito suficiente para el proyecto.

**Hecho:**

- [x] **Proyecto creado**: `wandering-base-66944645`, organización
      `org-shiny-hat-62410919`, rama `production`, región **AWS South
      America (São Paulo)** (`sa-east-1`), PostgreSQL 18. La región es
      fija: si alguna vez hay que cambiarla, se crea otro proyecto y se
      migra.
- [x] **Configuración en el repositorio**: `neon.ts` (la política de la
      rama) y `.neon` (el puntero local a la rama, que no se versiona).
- [x] **Variables descargadas**: `neon env pull` dejó en `.env.local`
      `DATABASE_URL` (pooled), `DATABASE_URL_UNPOOLED` (directa) y los
      identificadores de la rama. La aplicación las carga sola.
- [x] **Esquema creado**: 18 tablas, 3 vistas, 10 funciones y 5
      disparadores, con los tres roles sembrados.

**Falta:**

- [ ] **Secretos de la aplicación**, que la CLI no trae: añadirlos a
      `.env.local` y al panel de Vercel.
      - `BETTER_AUTH_SECRET`, con `openssl rand -base64 32`.
      - `BETTER_AUTH_URL`, con el dominio del proyecto.
      - `CRON_SECRET`, para proteger el barrido diario.
- [ ] **Rol de la aplicación** con menos privilegios que el dueño de la
      base, y usar ese rol en `DATABASE_URL`. Hoy se usa el dueño.
- [ ] **Ramas de base por rama de Git.** `neon branches create --parent
      main` da una base completa y gratis (10 por proyecto). Sugerencia:
      `main` = producción, `develop` = desarrollo, una por previsualización
      de Vercel.
- [ ] **Vigilar los límites del plan gratuito:** 100 CU-horas al mes, 1 GB
      de Postgres, 5 GB de egreso y 5 GB de transferencia pública. El
      cómputo se pausa a los 5 minutos sin uso: el arranque en frío son
      unos cientos de milisegundos.
- [ ] **Saber que el plan gratuito da 6 horas de historial** y un snapshot
      manual: la recuperación ante un error se hace con una rama restaurada
      desde ese historial.
- [ ] *Opcional:* activar `pg_stat_statements` para ver las consultas
      lentas cuando haga falta.

Decisión: **no** se usa el «Managed Better Auth» de Neon, porque la
identidad vive en la aplicación y así el esquema queda bajo control.

## Vercel

- [ ] **Importar el repositorio** y fijar **Root Directory = `web`**. Nuxt
      se detecta solo; no hay que elegir el framework a mano.
- [ ] **Declarar las variables de entorno**, en producción y en
      previsualización: `DATABASE_URL`, `BETTER_AUTH_SECRET`,
      `BETTER_AUTH_URL` (el dominio del proyecto) y `CRON_SECRET`.
      `DATABASE_URL` es la cadena *pooled* de Neon.
- [ ] **Barrido diario**: ya está declarado en `web/vercel.json`. El plan
      Hobby permite una ejecución al día, que es la que necesita el
      vencimiento de las solicitudes; más frecuencia exigiría Pro.
- [ ] **Deployment Protection**, para que las previsualizaciones no sean
      públicas.
- [ ] **Dominio:** añadirlo en Vercel, con los nameservers de Vercel o con
      los registros que indique el panel.
- [ ] **Producción desde `main`** y previsualización desde cada rama.

## Correo

Falta para el correo de verificación y para los avisos de HU-16.

- [ ] **Elegir proveedor.** Candidatos gratuitos: Resend (3.000 correos al
      mes), Postmark o Brevo. Se usa el mismo para ambos menesteres.
- [ ] **Declarar las variables** del proveedor y conectarlas al gancho
      `sendVerificationEmail` de Better Auth, en `server/utils/auth.ts`.
- [ ] **Decidir si la verificación de correo es obligatoria** para usar la
      cuenta, y si se manda en producción (en desarrollo puede quedar
      desactivada).

## Imágenes

Fotos de paquetes, proveedores o documentos.

- [ ] **Elegir dónde se guardan.** Neon Object Storage no está disponible
      en São Paulo (solo en cuatro regiones), así que las opciones son
      **Vercel Blob** o **Cloudflare R2** (compatible con S3).
- [ ] Declarar las variables delbucket y añadir el permiso de escritura
      correspondiente al rol de la aplicación.

## Entorno local

- [x] **Node.js 22 o superior**, fijado con mise (`mise.toml`).
- [x] **Dependencias instaladas** desde la raíz del repositorio:
      `npm install` (instala el espacio de trabajo completo).
- [x] **`.env.local` en la raíz** con las variables de la rama de Neon.
- [ ] **PostgreSQL local** con Podman o Docker, para el desarrollo y las
      pruebas cuando no se quiera usar la base de Neon:
      `podman run -d --name vizcacha -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres:18`
      y `psql -h 127.0.0.1 -U postgres -f bd/esquema.sql`.

## Git y automatización

- [ ] **Versionar `package-lock.json`**, que ahora existe en la raíz.
- [ ] **Proteger la rama principal**: no se integrates directo, todo pasa
      por una pull request con revisión.
- [ ] **Automatización (GitHub Actions)**, con tres pasos: `make
      verificar`, `npm run typecheck --workspace web` y `npm run build
      --workspace web`.
- [ ] **Convención de mensajes de commit**, ya documentada en
      `web/docs/convenciones.md`.

## Secretos

- [ ] Los secretos viven en el panel de Vercel y en Neon. Nunca en el
      repositorio ni en un archivo versionado.
- [ ] `BETTER_AUTH_SECRET` y `CRON_SECRET` distintos en producción.
- [ ] Rotación: cuando alguien sale del proyecto, se rotan los secretos y
      se desactivan sus cuentas.

## Decisiones que faltan tomar

| Decisión | Opciones |
|---|---|
| Correo | Resend, Postmark o Brevo |
| Imágenes | Vercel Blob o Cloudflare R2 |
| Avisos de HU-16 | Solo dentro de la web, o también por correo |
| Verificación de correo | Obligatoria o recomendada |
| Rol de la base | Dedicado con menos privilegios, o el dueño |
| Idioma de la interfaz | Solo español, o español e inglés (ya está preparado) |
| Previsualizaciones | Una rama de Neon por previsualización, o solo en `develop` |
