# Convenciones de código

## General

- **Idioma:** textos, comentarios y nombres de dominio en español; las
  palabras del framework (`useFetch`, `defineProps`, `computed`) en inglés.
- **Tipos:** TypeScript estricto, sin `any`. Si no se puede expresar, se usa
  `unknown` y se estrecha.
- **Formato:** sin punto y coma, comillas simples, dos espacios, líneas de
  hasta 80 caracteres.
- **Comentarios:** explican el porqué, no el qué.

## Nombres

| Elemento | Convención | Ejemplo |
|---|---|---|
| Componente | PascalCase con prefijo del módulo | `BaseTarjeta`, `TablaReservas` |
| Archivo de componente | PascalCase | `TablaDatos.vue` |
| Composable | `use` + PascalCase | `useTexto`, `useApi` |
| Variable y función | camelCase | `cupoDisponible`, `crearReserva` |
| Constante | SCREAMING_SNAKE_CASE | `IDIOMA_POR_DEFECTO` |
| Tipo o interfaz | PascalCase | `EstadoReserva` |
| Clave de texto | `area.elemento` en minúsculas | `disponibilidad.columnas.cupo` |
| Rama de git | `tipo/corta-descripcion` | `feat/barrido-solicitudes` |

## Tipos

- `interface` para objetos; `type` para uniones.
- Los tipos del dominio viven en `shared/types/domain.ts` y se derivan de la
  base.
- Las respuestas se declaran en `shared/types/api.ts`; la ruta y la vista
  usan el mismo tipo.
- `as const` en constantes para conservar valores literales.
- Las enumeraciones de la base son uniones de cadenas, no `enum`.

## Imports

- `~/` apunta a `app/`; `#shared/` a `shared/`.
- Los imports de tipo usan `import type`.
- Orden: librerías externas, alias, rutas relativas.
- Dentro de `app/components/` no se usan rutas relativas: Nuxt registra los
  componentes por nombre.

## Componentes

```vue
<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    titulo: string
    descripcion?: string
    compacto?: boolean
  }>(),
  { descripcion: undefined, compacto: false },
)

const emit = defineEmits<{
  seleccionar: [id: number]
}>()
</script>
```

- Props siempre tipadas; valores por omisión en `withDefaults`.
- Eventos declarados en `defineEmits` con su carga útil.
- `defineModel` para estado de dos vías.
- Un componente no pide datos ni llama a la API: recibe props y emite.

## Composables

- Empiezan por `use` y devuelven un objeto con valores y funciones.
- No guardan estado global sin motivo: `useState` solo para lo compartido.
- No escriben textos de interfaz: devuelven datos y la vista traduce.

## Servidor

- Una ruta por archivo en `server/api/`.
- La entrada se valida con Zod antes de tocar la base.
- Las reglas con bloqueo de fila se llaman como funciones de la base.
- Los errores se propagan con `createError`.
- Nada de `console.log`: se usa `console.error` con contexto.

## Rutas de la API

```ts
// server/api/disponibilidad.get.ts
import { z } from 'zod'

const consulta = z.object({ paquete: z.string().optional() })

export default defineEventHandler(async (event) => {
  const { paquete } = await getValidatedQuery(event, consulta.parse)
  const salidas = await consultar(sql`...`)
  return { salidas }
})
```

El nombre del archivo es el verbo y el recurso. La respuesta es un objeto con
una clave, nunca un arreglo suelto.

## Git

- Mensajes en español, en imperativo: `feat: agrega la consulta de
  disponibilidad`.
- Tipos: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.
- Una rama, un trabajo.
- No se versionan `node_modules/`, `.nuxt/`, `.output/` ni `dist/`.

## Antes de terminar

- [ ] `npm run typecheck --workspace web` sin errores.
- [ ] `npm run build --workspace web` compila.
- [ ] Los textos nuevos existen en todos los idiomas.
- [ ] Ningún color escrito a mano.
- [ ] Las entradas que cruzan la red están validadas.
- [ ] Si se tocó el esquema, `bd/esquema.sql` y `web/db/schema.ts` están
      alineados.
