<template>
  <div class="app">
    <NuxtRouteAnnouncer />
    <header class="app__cabecera">
      <NuxtLink to="/" class="app__marca">
        <strong>{{ appName }}</strong>
        <span>Gestión de paquetes turísticos y reservas</span>
      </NuxtLink>
      <nav class="app__menu">
        <NuxtLink to="/">Inicio</NuxtLink>
        <NuxtLink to="/disponibilidad">Disponibilidad</NuxtLink>
      </nav>
    </header>
    <main class="app__contenido">
      <NuxtPage />
    </main>
    <footer class="app__pie">
      <p>
        Sistema web de gestión de paquetes turísticos y reservas · Proyecto
        formativo de Sistemas de Información III · UPDS, sede Potosí.
      </p>
    </footer>
  </div>
</template>

<script setup lang="ts">
const appName = useRuntimeConfig().public.appName
</script>

<style>
:root {
  color-scheme: light dark;
  --borde: color-mix(in srgb, currentColor 15%, transparent);
  --tenue: color-mix(in srgb, currentColor 60%, transparent);
}

body {
  margin: 0;
  font-family: system-ui, -apple-system, 'Segoe UI', sans-serif;
  line-height: 1.6;
}

.app {
  max-width: 64rem;
  margin: 0 auto;
  padding: 1.5rem;
}

.app__cabecera {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  align-items: baseline;
  justify-content: space-between;
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--borde);
}

.app__marca {
  display: flex;
  flex-direction: column;
  text-decoration: none;
  color: inherit;
}

.app__marca span {
  font-size: 0.9rem;
  color: var(--tenue);
}

.app__menu {
  display: flex;
  gap: 1rem;
}

.app__menu a {
  color: inherit;
  text-decoration: none;
  border-bottom: 1px solid transparent;
}

.app__menu a:hover,
.app__menu a.router-link-active {
  border-bottom-color: currentColor;
}

.app__contenido {
  padding: 2rem 0;
}

.app__pie {
  padding-top: 1rem;
  border-top: 1px solid var(--borde);
  font-size: 0.85rem;
  color: var(--tenue);
}
</style>
