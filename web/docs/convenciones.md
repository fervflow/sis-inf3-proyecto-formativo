# Convenciones de código

## General

- **Idioma:** los textos, los comentarios y los nombres de dominio van en
  español. Las palabras del framework (`useFetch`, `defineProps`,
  `computed`) van en inglés, porque así los lee todo el mundo.
- **Tipos:** TypeScript estricto. `strict: true` está activo; `any` no se
  usa. Si el tipo no se puede expresar, se usa `unknown` y se estrecha.
- **Formato:** sin punto y coma, comillas simples, dos espacios de
  sangría, líneas de hasta 80 caracteres.
- **Comentarios:** explican el porqué, no el qué. Un comentario que repite
  la línea siguiente sobra.

## Nombres

| Elemento | Convención | Ejemplo |
|---|---|---|
| Componente | PascalCase, con prefijo del módulo | `BaseTarjeta`, `TablaReservas` |
| Archivo de componente | PascalCase | `TablaDatos.vue` |
| Composable | `use` + PascalCase | `useTexto`, `useApi` |
| Variable y función | camelCase | `cupoDisponible`, `crearReserva` |
| Constante | SCREAMING_SNAKE_CASE | `IDIOMA_POR_DEFECTO` |
| Tipo o interfaz | PascalCase | `EstadoReserva`, `ColumnaTabla` |
| Clave de texto | `area.elemento` en minúsculas | `disponibilidad.columnas.cupo` |
| Rama de git | `tipo/corta-descripcion` | `feat/barrido-solicitudes` |

## Tipos

- `interface` para objetos con forma conocida; `type` para uniones.
- Los tipos del dominio se declaran una vez, en `shared/types/domain.ts`,
  y se derivan de las restricciones de la base.
- Las respuestas de la API se declaran en `shared/types/api.ts`; la ruta y
  la vista usan el mismo tipo.
- `as const` en los objetos de constantes, para que TypeScript conserve
  los valores literales.
- Las enumeraciones de la base son uniones de cadenas literales, no
  enumeraciones de TypeScript.

## Imports

- Los alias del framework: `~/` apunta a `app/`, `#shared/` a `shared/`.
- Los imports de tipo usan `import type`.
- Los imports se ordenan: librerías externas, alias, rutas relativas.
- Un componente no importa con rutas relativas dentro de `app/components/`:
  se usa el nombre del componente, que Nuxt registra solo.

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

- Un componente declara sus props con tipos; nada de `props: {}` sin tipo.
- Los valores por omisión van en `withDefaults`.
- Los eventos se declaran en `defineEmits` con su carga útil.
- `defineModel` para el estado de dos vías.
- Un componente no pide datos ni llama a la API: recibe props y emite
  eventos.

## Composables

- Un composable devuelve un objeto con valores y funciones.
- Empieza por `use`.
- No guarda estado global sin motivo: `useState` solo para lo que se
  comparte entre vistas.
- No escribe texto de la interfaz: devuelve datos y la vista traduce.

## Servidor

- Una ruta por archivo, en `server/api/`.
- La entrada se valida con Zod antes de tocar la base.
- Las reglas de negocio con bloqueo de fila se llaman como funciones de la
  base, no se reimplementan.
- Los errores se propagan con `createError` y un código correcto.
- Nada de `console.log` en el servidor: se usa `console.error` con
  contexto cuando hay que registrar algo.

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

- El nombre del archivo es el verbo y el recurso.
- La respuesta es un objeto con una clave, nunca un arreglo suelto: así se
  puede ampliar sin romper a quien consume.

## Git

- Mensajes en español, en imperativo: `feat: agrega la consulta de
  disponibilidad`.
- Tipos: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.
- Una rama, un trabajo.
- Nada de archivos generados: `node_modules/`, `.nuxt/`, `.output/` y
  `dist/` están fuera del repositorio.

## Qué se revisa antes de dar por terminado

- [ ] `npm run typecheck --workspace web` sin errores.
- [ ] `npm run build --workspace web` compila.
- [ ] Los textos nuevos existen en todos los idiomas.
- [ ] Ningún color escrito a mano en una plantilla.
- [ ] Las entradas que cruzan la red están validadas.
- [ ] Si se tocó el esquema, `bd/esquema.sql` y `web/db/schema.ts` están
      alineados.
