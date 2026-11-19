<template>
  <div class="mx-auto max-w-md space-y-6">
    <BaseEncabezadoPagina
      :titulo="t('cambio.titulo')"
      :descripcion="t('cambio.introduccion')"
    />

    <BaseTarjeta>
      <form class="space-y-4" @submit.prevent="cambiar">
        <UFormField :label="t('cambio.actual')" name="actual">
          <UInput
            v-model="actual"
            type="password"
            autocomplete="current-password"
            class="w-full"
            required
          />
        </UFormField>

        <UFormField :label="t('cambio.nueva')" name="nueva">
          <UInput
            v-model="nueva"
            type="password"
            autocomplete="new-password"
            class="w-full"
            required
          />
        </UFormField>

        <UFormField :label="t('cambio.repetir')" name="repetir">
          <UInput
            v-model="repetir"
            type="password"
            autocomplete="new-password"
            class="w-full"
            required
          />
        </UFormField>

        <UAlert v-if="error" color="error" variant="soft" :title="error" />
        <UAlert
          v-if="exito"
          color="success"
          variant="soft"
          :title="t('cambio.exito')"
        />

        <UButton
          type="submit"
          color="primary"
          block
          :loading="pendiente"
          :label="t('comun.guardar')"
        />
      </form>
    </BaseTarjeta>
  </div>
</template>

<script setup lang="ts">
import type { RespuestaCuenta, RespuestaOperacion } from '#shared/types/api'

const { t } = useTexto()
const mensajeDeError = useMensajeError()

const actual = ref('')
const nueva = ref('')
const repetir = ref('')
const pendiente = ref(false)
const error = ref<string | null>(null)
const exito = ref(false)

const { data: cuenta } = await useFetch<RespuestaCuenta>('/api/cuenta', {
  key: 'cuenta',
})

if (!cuenta.value?.usuario) {
  await navigateTo('/ingresar')
}

async function cambiar() {
  error.value = null
  exito.value = false

  if (nueva.value.length < 8) {
    error.value = t('cambio.corta')
    return
  }
  if (nueva.value !== repetir.value) {
    error.value = t('cambio.noCoinciden')
    return
  }
  if (nueva.value === actual.value) {
    error.value = t('cambio.igual')
    return
  }

  pendiente.value = true
  try {
    await $fetch<RespuestaOperacion>('/api/cuenta/cambiar-password', {
      method: 'POST',
      body: { actual: actual.value, nueva: nueva.value },
    })
    exito.value = true
    await refreshNuxtData('cuenta')
    await navigateTo('/')
  } catch (fallo) {
    error.value = mensajeDeError(fallo, 'cambio.error')
  } finally {
    pendiente.value = false
  }
}
</script>
