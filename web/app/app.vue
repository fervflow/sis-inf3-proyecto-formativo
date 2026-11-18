<template>
  <UApp>
    <div class="flex min-h-screen flex-col">
      <header class="border-b border-(--vt-color-borde) bg-(--vt-color-superficie)">
        <div
          class="mx-auto flex w-full max-w-6xl flex-wrap items-center justify-between gap-4 px-4 py-3"
        >
          <NuxtLink to="/" class="flex flex-col text-inherit no-underline">
            <span class="text-(--vt-texto-lg) font-(--vt-texto-peso-fuerte)">
              {{ t('app.nombre') }}
            </span>
            <span class="text-xs text-(--vt-color-texto-suave)">
              {{ t('app.subtitulo') }}
            </span>
          </NuxtLink>

          <nav class="flex items-center gap-1">
            <UButton
              to="/"
              variant="ghost"
              color="neutral"
              :label="t('nav.inicio')"
            />
            <UButton
              to="/disponibilidad"
              variant="ghost"
              color="neutral"
              :label="t('nav.disponibilidad')"
            />
            <USelect
              v-model="idioma"
              :items="idiomasDisponibles"
              value-key="valor"
              class="w-32"
              :aria-label="t('app.idioma')"
            />
          </nav>
        </div>
      </header>

      <main class="mx-auto w-full max-w-6xl flex-1 px-4 py-8">
        <NuxtPage />
      </main>

      <footer class="border-t border-(--vt-color-borde) py-6">
        <p
          class="mx-auto w-full max-w-6xl px-4 text-xs text-(--vt-color-texto-suave)"
        >
          {{ t('app.pie') }}
        </p>
      </footer>
    </div>
  </UApp>
</template>

<script setup lang="ts">
import { idiomas } from '~/i18n'

const { t, idioma } = useTexto()

const idiomasDisponibles = [
  { valor: 'es', etiqueta: 'Español' },
  { valor: 'en', etiqueta: 'English' },
]
</script>
