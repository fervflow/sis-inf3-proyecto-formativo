<template>
  <UApp>
    <NuxtLoadingIndicator
      color="var(--vt-color-marca-600)"
      :height="3"
      :duration="1500"
    />

    <div class="flex min-h-screen flex-col">
      <BarraNavegacion :cuenta="cuenta?.usuario ?? null" @salir="salir" />

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

const { t } = useTexto()

const { data: cuenta } = await useFetch<RespuestaCuenta>('/api/cuenta', {
  key: 'cuenta',
})

/** Cierra la sesión y vuelve al ingreso. */
async function salir() {
  await $fetch('/api/auth/sign-out', { method: 'POST' })
  await refreshNuxtData('cuenta')
  await navigateTo('/ingresar')
}
</script>
