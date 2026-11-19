# Documentación de la web

Guías de trabajo de la aplicación. La entrada para agentes y modelos es
`../AGENTS.md`.

| Documento | Contenido |
|---|---|
| `arquitectura.md` | Capas, carpetas, flujo de datos y dependencias |
| `convenciones.md` | Nombres, tipos, imports y estilo |
| `design-system.md` | Tokens y sistema visual |
| `componentes.md` | Componentes base y de módulo |
| `tipos-y-datos.md` | Tipos, contratos y validación |
| `i18n.md` | Textos centralizados e idiomas |
| `base-de-datos.md` | Esquema, funciones y consultas |
| `autenticacion.md` | Better Auth, roles y sesión |
| `pruebas.md` | Qué se prueba y cómo |
| `seguridad.md` | Validación, permisos y secretos |
| `flujo-de-trabajo.md` | Backlog, ramas y definición de terminado |

Tres reglas se repiten en todos: **el SQL manda** (`bd/esquema.sql`),
**los textos se centralizan** (`app/i18n/`) y **los tokens mandan** sobre
Nuxt UI (`app/design/tokens.css`).
