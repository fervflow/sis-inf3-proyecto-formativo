# Arquitectura

## Capas

La aplicación tiene cuatro capas. Cada una depende solo de la de abajo.

```text
Vista (app/pages, app/components)
   ↓ usa
Composables (app/composables) y tipos compartidos (shared/types)
   ↓ pide
API (server/api) — valida, aplica reglas y responde
   ↓ escribe
Base de datos (Drizzle ORM → PostgreSQL)
```

- **La vista** no habla con la base de datos. Pide datos a la API y dibuja.
- **El composable** es la forma de compartir lógica entre vistas: pedir
  datos, manejar carga y error, traducir textos.
- **La API** es la única capa que conoce Drizzle y las funciones de la base.
  Valida la entrada, llama a la función de negocio que corresponde y devuelve
  un tipo de `shared/types/api.ts`.
- **La base de datos** guarda el estado y aplica las reglas críticas.

## Carpetas y qué va en cada una

| Carpeta | Contenido | Regla |
|---|---|---|
| `app/pages/` | Una vista por archivo, una ruta por vista | Solo orquesta: pide datos y compone componentes |
| `app/components/base/` | Componentes reutilizables, sin datos | No piden datos ni conocen la API |
| `app/components/<módulo>/` | Componentes de una historia | Viven con su módulo: `reservas/`, `paquetes/` |
| `app/composables/` | Lógica reutilizable de la interfaz | Sin efectos colaterales; reciben lo que necesitan |
| `app/design/` | Tokens y tema | No se editan al cambiar una vista |
| `app/i18n/` | Textos de la interfaz | Toda clave nueva se agrega primero en `es.ts` |
| `app/assets/css/` | Estilos globales | Solo lo que no pertenece a un componente |
| `server/api/` | Rutas de la API | Una ruta por archivo; el nombre es el verbo y el recurso |
| `server/utils/` | Conexión y autenticación | Se inicializan una sola vez |
| `server/middleware/` | Control de sesión y de acceso | Corre antes de las rutas |
| `shared/types/` | Tipos compartidos | Sin lógica; solo tipos |
| `db/schema.ts` | El esquema en TypeScript | Refleja `bd/esquema.sql`; no se edita a mano |

## Flujo de una consulta

```text
1. La vista llama a un composable:          useApi<T>()
2. El composable pide la ruta:              $fetch('/api/disponibilidad')
3. La ruta consulta la base:                db.execute(sql`...`)
4. La ruta responde con un tipo:            RespuestaDisponibilidad
5. La vista dibuja con los componentes:     <BaseTablaDatos :filas="salidas" />
```

## Reglas de dependencia

- Un componente de `app/components/` **no** importa nada de `server/`. La
  frontera va por la API.
- Un componente de `app/components/` **no** llama a `$fetch` directamente:
  lo hace un composable. Así el estado de carga y el error se manejan igual
  en todas partes.
- `shared/types/` no importa nada. Solo declara tipos.
- `app/composables/` no importa de `app/components/`.
- `server/api/` no importa de `app/`. La API no sabe qué hay en pantalla.

## Dónde vive cada cosa

| Pregunta | Respuesta |
|---|---|
| ¿Una tabla, una columna, una función? | `bd/esquema.sql` (canónico) y `web/db/schema.ts` (reflejo) |
| ¿Un tipo del dominio? | `shared/types/domain.ts` |
| ¿La forma de una respuesta de la API? | `shared/types/api.ts` |
| ¿Un texto de la interfaz? | `app/i18n/locales/es.ts` |
| ¿Un color, un radio, un espaciado? | `app/design/tokens.css` |
| ¿Un patrón que se repite en las vistas? | `app/components/base/` |
| ¿Una regla de negocio con bloqueo de fila? | Una función PL/pgSQL en `bd/esquema.sql` |
| ¿Quién puede ver qué? | `docs/autenticacion.md` |

## Nombres de las rutas de la API

| Patrón | Ejemplo | Qué hace |
|---|---|---|
| `GET /api/<recurso>` | `/api/disponibilidad` | Consulta |
| `POST /api/<recurso>` | `/api/vencer-solicitudes` | Acción |
| `GET /api/auth/*` | — | Lo maneja Better Auth |

Los nombres son en español y en plural, salvo las acciones que son un
verbo: `vencer-solicitudes`.

## Servidor y cliente

Nuxt renderiza en el servidor y envía la página lista. Las reglas:

- Los datos se piden en el servidor con `await useFetch(...)` cuando la
  vista depende de ellos; en el cliente, con `useApi()`.
- Un componente que se usa en el servidor no abre una conexión: la base se
  toca solo en `server/`.
- El estado que se comparte entre vistas vive en `useState`, no en un
  módulo suelto.
