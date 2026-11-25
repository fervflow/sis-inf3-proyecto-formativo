<script setup lang="ts">
/**
 * Subtítulo de sección.
 *
 * Etiqueta corta en versalitas con un icono de la marca delante; da a
 * las secciones de una tarjeta o de una ficha el mismo encabezado en
 * toda la aplicación.
 */
defineProps<{
  /** Icono de la sección, en la forma `i-lucide-*`. */
  icono?: string
}>()
</script>

<template>
  <p
    class="flex items-center gap-1.5 text-xs font-(--vt-texto-peso-medio) uppercase tracking-wide text-(--vt-color-texto-suave)"
  >
    <UIcon v-if="icono" :name="icono" class="size-4 text-(--vt-color-marca-600)" />
    <slot />
  </p>
</template>
