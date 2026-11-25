<script setup lang="ts">
/**
 * Un dato con su etiqueta: los indicadores de la página de estado.
 */
defineProps<{
  etiqueta: string
  valor: string | number | boolean
}>()
</script>

<template>
  <div class="border-l-2 border-(--vt-color-marca-300) pl-3">
    <dt class="text-xs uppercase tracking-wide text-(--vt-color-texto-suave)">
      {{ etiqueta }}
    </dt>
    <dd class="text-(length:--vt-texto-xl) font-(--vt-texto-peso-medio)">
      {{ valor }}
    </dd>
  </div>
</template>
