<script setup lang="ts" generic="Fila extends object">
import type { ColumnaTabla } from '#shared/types/ui'

/**
 * Tabla de datos.
 *
 * Las columnas se declaran; el cuerpo dibuja la celda o, si no hay
 * plantilla, el valor de la fila. Todas las tablas de la aplicación usan
 * este componente, de modo que el formato es siempre el mismo.
 */
defineProps<{
  columnas: ColumnaTabla<Fila>[]
  filas: Fila[]
  cargando?: boolean
  textoVacio?: string
}>()

/** Valor de una celda, con el tipo genérico resuelto. */
function valorDe(fila: Fila, clave: keyof Fila & string): unknown {
  return fila[clave]
}
</script>

<template>
  <div>
    <div v-if="cargando" class="space-y-2 p-4">
      <USkeleton v-for="n in 4" :key="n" class="h-6 w-full" />
    </div>

    <p v-else-if="filas.length === 0" class="p-6 text-center text-(length:--vt-texto-sm) text-(--vt-color-texto-suave)">
      {{ textoVacio ?? ' ' }}
    </p>

    <table v-else class="w-full border-collapse text-left">
      <thead>
        <tr class="border-b border-(--vt-color-borde)">
          <th
            v-for="columna in columnas"
            :key="columna.clave"
            scope="col"
            class="px-3 py-2 text-xs font-(--vt-texto-peso-medio) uppercase tracking-wide text-(--vt-color-texto-suave)"
            :class="{
              'text-right': columna.alineacion === 'derecha',
              'text-center': columna.alineacion === 'centro',
            }"
          >
            {{ columna.etiqueta }}
          </th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="(fila, indice) in filas"
          :key="indice"
          class="border-b border-(--vt-color-borde) last:border-0"
        >
          <td
            v-for="columna in columnas"
            :key="columna.clave"
            class="px-3 py-2 text-(length:--vt-texto-sm)"
            :class="{
              'text-right': columna.alineacion === 'derecha',
              'text-center': columna.alineacion === 'centro',
            }"
          >
            <slot
              name="celda"
              :columna="columna"
              :fila="fila"
              :valor="valorDe(fila, columna.clave)"
            >
              {{ valorDe(fila, columna.clave) }}
            </slot>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
