# Arquitectura

## Capas

Cada capa depende solo de la de abajo.

```text
Vista (app/pages, app/components)
   ↓ usa
Composables (app/composables) y tipos compartidos (shared/types)
   ↓ pide
API (server/api) — valida, aplica reglas y responde
   ↓ escribe
Base de datos (Drizzle ORM → PostgreSQL)
```

- **La vista** no habla con la base: pide datos a la API y dibuja.
- **El composable** comparte lógica entre vistas: datos, carga, error y
  textos.
- **La API** es la única capa que conoce Drizzle y las funciones de la base.
- **La base** guarda el estado y aplica las reglas críticas.

## Carpetas

| Carpeta | Contenido | Regla |
|---|---|---|
| `app/pages/` | Una vista por archivo | Solo orquesta |
| `app/components/base/` | Componentes reutilizables | Sin datos ni API |
| `app/components/<módulo>/` | Componentes de una historia | Viven con su módulo |
| `app/composables/` | Lógica reutilizable | Sin efectos colaterales |
| `app/design/` | Tokens y tema | No se editan al cambiar una vista |
| `app/i18n/` | Textos | Toda clave nueva empieza en `es.ts` |
| `app/assets/css/` | Estilos globales | Solo lo que no es de un componente |
| `server/api/` | Rutas de la API | Una ruta por archivo |
| `server/utils/` | Conexión y autenticación | Se inicializan una vez |
| `server/middleware/` | Sesión y acceso | Corre antes de las rutas |
| `shared/types/` | Tipos compartidos | Sin lógica |
| `db/schema.ts` | Esquema en TypeScript | Refleja `bd/esquema.sql` |

## Flujo de una consulta

```text
1. La vista llama a un composable:     useApi<T>()
2. El composable pide la ruta:         $fetch('/api/disponibilidad')
3. La ruta consulta la base:           db.execute(sql`...`)
4. La ruta responde con un tipo:       RespuestaDisponibilidad
5. La vista dibuja:                    <BaseTablaDatos :filas="salidas" />
```

## Reglas de dependencia

- Un componente de `app/components/` **no** importa nada de `server/`.
- Un componente **no** llama a `$fetch` directamente: lo hace un
  composable.
- `shared/types/` no importa nada.
- `app/composables/` no importa de `app/components/`.
- `server/api/` no importa de `app/`.

## Dónde vive cada cosa

| Pregunta | Respuesta |
|---|---|
| ¿Una tabla, columna o función? | `bd/esquema.sql` y `web/db/schema.ts` |
| ¿Un tipo del dominio? | `shared/types/domain.ts` |
| ¿La forma de una respuesta? | `shared/types/api.ts` |
| ¿Un texto? | `app/i18n/locales/es.ts` |
| ¿Un color, radio o espaciado? | `app/design/tokens.css` |
| ¿Un patrón repetido? | `app/components/base/` |
| ¿Una regla con bloqueo de fila? | Una función PL/pgSQL en `bd/esquema.sql` |
| ¿Quién puede ver qué? | `docs/autenticacion.md` |

## Rutas de la API

| Patrón | Ejemplo | Qué hace |
|---|---|---|
| `GET /api/<recurso>` | `/api/disponibilidad` | Consulta |
| `POST /api/<recurso>` | `/api/vencer-solicitudes` | Acción |
| `GET /api/cuenta` | — | Sesión en curso |
| `GET /api/admin/<recurso>` | `/api/admin/usuarios` | Solo rol `ADMIN` |
| `GET /api/auth/*` | — | Better Auth |

Los nombres son en español y en plural; las acciones usan verbo.

## Servidor y cliente

Nuxt renderiza en el servidor y envía la página lista.

- Los datos se piden con `await useFetch(...)` en el servidor o con
  `useApi()` en el cliente.
- La base se toca solo en `server/`.
- El estado compartido entre vistas vive en `useState`.
