<script setup lang="ts">
/**
 * Estado vacío.
 *
 * Cuando una lista no tiene nada que mostrar: el motivo, y opcionalmente
 * la acción que lo resuelve.
 */
defineProps<{
  titulo: string
  descripcion?: string
}>()
</script>

<template>
  <div class="flex flex-col items-center gap-2 px-6 py-10 text-center">
    <UIcon name="i-lucide-inbox" class="size-8 text-(--vt-color-texto-suave)" />
    <p class="text-(length:--vt-texto-base) font-(--vt-texto-peso-medio)">
      {{ titulo }}
    </p>
    <p
      v-if="descripcion"
      class="max-w-md text-(length:--vt-texto-sm) text-(--vt-color-texto-suave)"
    >
      {{ descripcion }}
    </p>
    <div v-if="$slots.accion" class="pt-2">
      <slot name="accion" />
    </div>
  </div>
</template>
