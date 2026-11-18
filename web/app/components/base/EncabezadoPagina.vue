<script setup lang="ts">
/**
 * Encabezado de una página: título, descripción y acciones.
 *
 * Es el primer bloque de toda vista. La descripción explica de qué se
 * trata la página en una línea.
 */
defineProps<{
  titulo: string
  descripcion?: string
}>()
</script>

<template>
  <header class="flex flex-wrap items-start justify-between gap-4">
    <div class="min-w-0">
      <h1 class="text-(--vt-texto-3xl) font-(--vt-texto-peso-fuerte) tracking-tight">
        {{ titulo }}
      </h1>
      <p
        v-if="descripcion"
        class="mt-1 max-w-3xl text-(--vt-texto-sm) text-(--vt-color-texto-suave)"
      >
        {{ descripcion }}
      </p>
    </div>
    <div v-if="$slots.acciones" class="flex shrink-0 items-center gap-2">
      <slot name="acciones" />
    </div>
  </header>
</template>
