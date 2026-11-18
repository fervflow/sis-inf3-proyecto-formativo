# Documentación de la web

Guías de trabajo de la aplicación. La entrada para agentes y modelos es
[`web/AGENTS.md`](../AGENTS.md).

| Documento | De qué trata |
|---|---|
| [`arquitectura.md`](arquitectura.md) | Capas, carpetas, flujo de datos y reglas de dependencia |
| [`convenciones.md`](convenciones.md) | Cómo se escribe el código: nombres, tipos, imports, comentarios |
| [`design-system.md`](design-system.md) | Tokens, componentes base y cómo se reestiliza la aplicación |
| [`componentes.md`](componentes.md) | Cómo se crean y se usan los componentes reutilizables |
| [`tipos-y-datos.md`](tipos-y-datos.md) | TypeScript, tipos del dominio, esquemas y contratos de la API |
| [`i18n.md`](i18n.md) | Textos centralizados, idiomas y claves |
| [`base-de-datos.md`](base-de-datos.md) | El esquema, las funciones de negocio y cómo se consulta |
| [`autenticacion.md`](autenticacion.md) | Better Auth, roles, sesión y registro de accesos |
| [`pruebas.md`](pruebas.md) | Qué se prueba, con qué herramientas y cómo se ejecuta |
| [`seguridad.md`](seguridad.md) | Validación, permisos, secretos y los riesgos del sistema |
| [`flujo-de-trabajo.md`](flujo-de-trabajo.md) | Relación con el tablero kanban, ramas y definición de terminado |

## Cómo se leen

Cada documento es autónomo: se puede leer sin los demás. Los que se cruzan
enlazados entre sí, y todos remiten a la fuente canónica cuando existe:
el esquema de la base vive en `bd/`, el backlog en
`sistema/historias-usuario/` y el tablero en `tablero/`.

## Tres cosas que no cambian

1. **El SQL manda.** `bd/esquema.sql` es la fuente del esquema;
   `web/db/schema.ts` lo refleja.
2. **Los textos son centralizados.** Ninguna plantilla escribe texto que la
   persona usuaria lea.
3. **Los tokens mandan sobre la biblioteca.** Nuxt UI es la implementación;
   la identidad visual vive en `app/design/tokens.css`.
