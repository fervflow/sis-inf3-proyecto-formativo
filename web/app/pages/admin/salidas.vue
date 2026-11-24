<script setup lang="ts">
/**
 * Página movida.
 *
 * La gestión de salidas vive ahora en «Próximas salidas»
 * (`/disponibilidad`), donde el administrador alterna entre la vista de
 * cliente y la de gestión. Esta ruta se conserva para redirigir.
 */
await navigateTo('/disponibilidad', { replace: true })
</script>

<template>
  <div />
</template>
