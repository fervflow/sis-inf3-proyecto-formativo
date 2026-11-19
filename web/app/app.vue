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

          <nav class="flex flex-wrap items-center gap-1">
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
            <UButton
              v-if="esPersonal"
              to="/clientes"
              variant="ghost"
              color="neutral"
              :label="t('nav.clientes')"
            />
            <UButton
              v-if="esAdmin"
              to="/admin/paquetes"
              variant="ghost"
              color="neutral"
              :label="t('nav.paquetes')"
            />
            <UButton
              v-if="esAdmin"
              to="/admin/usuarios"
              variant="ghost"
              color="neutral"
              :label="t('nav.usuarios')"
            />

            <template v-if="cuenta?.usuario">
              <span
                class="hidden px-2 text-(--vt-texto-sm) text-(--vt-color-texto-suave) sm:inline"
              >
                {{ cuenta.usuario.nombres }}
              </span>
              <UButton
                variant="ghost"
                color="neutral"
                :label="t('nav.salir')"
                @click="salir"
              />
            </template>
            <UButton
              v-else
              to="/ingresar"
              variant="ghost"
              color="neutral"
              :label="t('nav.ingresar')"
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
import type { RespuestaCuenta } from '#shared/types/api'
import { idiomas } from '~/i18n'

const { t, idioma } = useTexto()

const { data: cuenta } = await useFetch<RespuestaCuenta>('/api/cuenta', {
  key: 'cuenta',
})

const esAdmin = computed(() => cuenta.value?.usuario?.rol === 'ADMIN')
const esPersonal = computed(
  () =>
    cuenta.value?.usuario?.rol === 'ADMIN' ||
    cuenta.value?.usuario?.rol === 'PERSONAL',
)

/** Cierra la sesión y vuelve al ingreso. */
async function salir() {
  await $fetch('/api/auth/sign-out', { method: 'POST' })
  await refreshNuxtData('cuenta')
  await navigateTo('/ingresar')
}

const idiomasDisponibles = [
  { valor: 'es', etiqueta: 'Español' },
  { valor: 'en', etiqueta: 'English' },
]
</script>
