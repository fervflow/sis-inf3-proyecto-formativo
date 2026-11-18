# Tipos y datos

## Dónde vive cada tipo

| Tipo | Archivo | Quién lo usa |
|---|---|---|
| Valores del dominio | `shared/types/domain.ts` | Interfaz y servidor |
| Respuestas de la API | `shared/types/api.ts` | La ruta que responde y la vista que pide |
| Tipos de los componentes | `shared/types/ui.ts` | Componentes y vistas |

`shared/` es la carpeta que Nuxt comparte entre la interfaz y el servidor:
se importa con el alias `#shared/`.

## Los tipos del dominio son el reflejo de la base

Cada restricción `CHECK` del esquema tiene su tipo:

```ts
// bd/esquema.sql
CONSTRAINT ck_reserva_estado CHECK
    (estado IN ('pendiente', 'confirmada', 'vencida', 'cancelada', 'finalizada'))

// shared/types/domain.ts
export type EstadoReserva =
  | 'pendiente'
  | 'confirmada'
  | 'vencida'
  | 'cancelada'
  | 'finalizada'
```

Cuando cambia la base, cambian los dos archivos.

## Contratos de la API

Una ruta declara lo que devuelve; la vista declara lo que espera. Es el
mismo tipo.

```ts
// shared/types/api.ts
export interface RespuestaDisponibilidad {
  salidas: SalidaDisponible[]
}
```

La respuesta siempre es un objeto con una clave, nunca un arreglo suelto:
así se puede ampliar el contrato sin romper a quien lo consume.

## Validación con Zod

Todo lo que entra por la red se valida en el servidor, antes de tocar la
base:

```ts
import { z } from 'zod'

const cuerpo = z.object({
  id_cliente: z.number().int().positive(),
  cantidad: z.number().int().min(1).max(20),
})

export default defineEventHandler(async (event) => {
  const datos = cuerpo.parse(await readBody(event))
  // …
})
```

- El esquema de Zod es la frontera: lo que no está en el esquema no pasa.
- Los mensajes de error de validación se traducen en la interfaz, no se
  muestran en crudo.

## Genéricos en los componentes

Un componente que trabaja con cualquier forma de dato declara un genérico:

```vue
<script setup lang="ts" generic="Fila extends object">
import type { ColumnaTabla } from '#shared/types/ui'

defineProps<{
  columnas: ColumnaTabla<Fila>[]
  filas: Fila[]
}>()
</script>
```

## En el servidor

- `unknown` cuando el tipo aún no se conoce; se estrecha con `typeof`,
  `in` o un esquema de Zod.
- `any` no se usa. Si hace falta, el tipo se define en `shared/types/`.
- Los parámetros de las funciones PL/pgSQL se llaman con el mismo nombre
  que en el SQL: `p_cantidad`, `p_id_usuario`.

## En la interfaz

- Los datos de la API se tipan al pedir: `useApi<RespuestaDisponibilidad>()`.
- Los `ref` que guardan datos de la API llevan el tipo:
  `ref<SalidaDisponible[]>([])`.
- Los valores derivados se calculan en `computed`, no en la plantilla.

## Reglas

1. El tipo vive donde lo usan más de dos archivos; si lo usa uno, se
   declara ahí.
2. Los tipos del dominio no se redeclaran en la interfaz: se importan.
3. Un tipo que aparece en la base y en la aplicación tiene una sola
   definición, en `shared/types/domain.ts`.
4. Cuando un tipo cambia, cambia el archivo de tipos y el que lo consume:
   el compilador avisa.
