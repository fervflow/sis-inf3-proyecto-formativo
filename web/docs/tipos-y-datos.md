# Tipos y datos

## Dónde vive cada tipo

| Tipo | Archivo | Quién lo usa |
|---|---|---|
| Valores del dominio | `shared/types/domain.ts` | Interfaz y servidor |
| Respuestas de la API | `shared/types/api.ts` | Ruta y vista |
| Tipos de componentes | `shared/types/ui.ts` | Componentes y vistas |

`shared/` se importa con el alias `#shared/`.

## El dominio refleja la base

Cada restricción `CHECK` tiene su tipo:

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

La ruta declara lo que devuelve y la vista lo que espera: el mismo tipo.

```ts
// shared/types/api.ts
export interface RespuestaDisponibilidad {
  salidas: SalidaDisponible[]
}
```

La respuesta es un objeto con una clave, nunca un arreglo suelto: así se
puede ampliar sin romper a quien consume.

## Validación con Zod

Todo lo que entra por la red se valida en el servidor antes de tocar la
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

El esquema es la frontera: lo que no está en él no pasa. Los mensajes se
traducen en la interfaz, no se muestran en crudo.

## Genéricos en componentes

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

- `unknown` cuando el tipo no se conoce; se estrecha con `typeof`, `in` o
  Zod.
- `any` no se usa.
- Los parámetros de las funciones PL/pgSQL conservan su nombre:
  `p_cantidad`, `p_id_usuario`.

## En la interfaz

- Los datos se tipan al pedir: `useApi<RespuestaDisponibilidad>()`.
- Los `ref` llevan su tipo: `ref<SalidaDisponible[]>([])`.
- Los valores derivados se calculan en `computed`, no en la plantilla.

## Reglas

1. El tipo vive donde lo usan más de dos archivos; si lo usa uno, se declara
   ahí.
2. Los tipos del dominio no se redeclaran: se importan.
3. Un tipo presente en la base y en la aplicación tiene una sola
   definición, en `shared/types/domain.ts`.
4. Cuando cambia un tipo, cambia también quien lo consume.
