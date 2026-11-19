<template>
  <div class="mx-auto max-w-md space-y-6">
    <BaseEncabezadoPagina
      :titulo="t('ingreso.titulo')"
      :descripcion="t('ingreso.introduccion')"
    />

    <BaseTarjeta>
      <form class="space-y-4" @submit.prevent="entrar">
        <UFormField :label="t('ingreso.usuario')" name="usuario">
          <UInput
            v-model="usuario"
            autocomplete="username"
            autocapitalize="none"
            spellcheck="false"
            class="w-full"
            required
          />
        </UFormField>

        <UFormField
          :label="t('ingreso.contrasena')"
          name="contrasena"
          :help="t('ingreso.pista')"
        >
          <UInput
            v-model="contrasena"
            type="password"
            autocomplete="current-password"
            class="w-full"
            required
          />
        </UFormField>

        <UAlert
          v-if="error"
          color="error"
          variant="soft"
          :title="error"
        />

        <UButton
          type="submit"
          color="primary"
          block
          :loading="pendiente"
          :label="t('comun.entrar')"
        />
      </form>
    </BaseTarjeta>
  </div>
</template>

<script setup lang="ts">
import { correoDeIngreso } from '#shared/usuarios'
import type { RespuestaCuenta } from '#shared/types/api'

const { t } = useTexto()
const mensajeDeError = useMensajeError()

const usuario = ref('')
const contrasena = ref('')
const pendiente = ref(false)
const error = ref<string | null>(null)

async function entrar() {
  error.value = null
  pendiente.value = true

  try {
    await $fetch('/api/auth/sign-in/email', {
      method: 'POST',
      body: {
        email: correoDeIngreso(usuario.value),
        password: contrasena.value,
      },
    })

    // La consulta de la cuenta pasa por el guard del servidor: si la
    // cuenta está bloqueada, la sesión se cierra acá mismo.
    const cuenta = await $fetch<RespuestaCuenta>('/api/cuenta')
    await refreshNuxtData('cuenta')

    await navigateTo(
      cuenta.usuario?.debeCambiarPassword ? '/cambiar-password' : '/',
    )
  } catch (fallo) {
    const codigo =
      (fallo as { statusCode?: number }).statusCode ??
      (fallo as { status?: number }).status
    error.value =
      codigo === 401
        ? t('ingreso.error')
        : mensajeDeError(fallo, 'ingreso.error')
  } finally {
    pendiente.value = false
  }
}
</script>
