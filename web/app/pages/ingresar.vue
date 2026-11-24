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

    <p class="text-center text-(--vt-texto-sm)">
      {{ t('ingreso.sinCuenta') }}
      <UButton
        :to="rutaRegistro"
        variant="soft"
        color="primary"
        size="xs"
        :label="t('ingreso.crearCuenta')"
      />
    </p>
  </div>
</template>

<script setup lang="ts">
import { correoDeIngreso } from '#shared/usuarios'
import type { RespuestaCuenta } from '#shared/types/api'

const { t } = useTexto()
const mensajeDeError = useMensajeError()
const ruta = useRoute()

const usuario = ref('')
const contrasena = ref('')
const pendiente = ref(false)
const error = ref<string | null>(null)

/** El destino tras ingresar: el que pidió la reserva, o el inicio. */
const retorno = computed(() => {
  const destino = ruta.query.volver
  return typeof destino === 'string' && destino.startsWith('/')
    ? destino
    : '/'
})

const rutaRegistro = computed(() => {
  const volver = ruta.query.volver
  return typeof volver === 'string' && volver.startsWith('/')
    ? `/crear-cuenta?volver=${encodeURIComponent(volver)}`
    : '/crear-cuenta'
})

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
      cuenta.usuario?.debeCambiarPassword ? '/cambiar-password' : retorno.value,
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
