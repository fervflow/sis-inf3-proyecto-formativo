<script setup lang="ts">
/**
 * Tarjeta con título.
 *
 * Envuelve a la tarjeta de Nuxt UI para que el encabezado, el cuerpo y
 * el pie tengan siempre la misma forma en toda la aplicación.
 */
defineProps<{
  titulo?: string
  descripcion?: string
}>()
</script>

<template>
  <UCard>
    <template v-if="titulo" #header>
      <div class="flex flex-wrap items-baseline justify-between gap-2">
        <div>
          <h2 class="text-(--vt-texto-lg) font-(--vt-texto-peso-fuerte)">
            {{ titulo }}
          </h2>
          <p
            v-if="descripcion"
            class="text-(--vt-texto-sm) text-(--vt-color-texto-suave)"
          >
            {{ descripcion }}
          </p>
        </div>
        <slot name="acciones" />
      </div>
    </template>

    <slot />

    <template v-if="$slots.pie" #footer>
      <slot name="pie" />
    </template>
  </UCard>
</template>
