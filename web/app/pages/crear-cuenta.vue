<script setup lang="ts">
/**
 * Registro público de una cuenta de cliente (HU-15).
 *
 * Crea la cuenta y la ficha del cliente en un solo paso (RN-USU-03), con
 * el correo obligatorio y único (RN-USU-05). Al terminar, la sesión está
 * abierta: el cliente vuelve al destino que pidió, por ejemplo a terminar
 * su reserva.
 */
import type { RespuestaCuenta } from '#shared/types/api'
import type { TipoDocumento } from '#shared/types/domain'
import type { ClaveMensaje } from '~/i18n'

const { t } = useTexto()
const mensajeDeError = useMensajeError()
const ruta = useRoute()

const pendiente = ref(false)
const error = ref<string | null>(null)

const formulario = reactive({
  correo: '',
  contrasena: '',
  nombres: '',
  apellidos: '',
  tipoDocumento: 'CI' as TipoDocumento,
  numeroDocumento: '',
  telefono: '',
})

/** El destino tras crear la cuenta: el que pidió, o el inicio. */
const retorno = computed(() => {
  const destino = ruta.query.volver
  return typeof destino === 'string' && destino.startsWith('/')
    ? destino
    : '/'
})

const rutaIngreso = computed(() => {
  const volver = ruta.query.volver
  return typeof volver === 'string' && volver.startsWith('/')
    ? `/ingresar?volver=${encodeURIComponent(volver)}`
    : '/ingresar'
})

const tiposDocumento = computed(() =>
  (['CI', 'NIT', 'PASAPORTE', 'OTRO'] as const).map((tipo) => ({
    label: t(`clientes.tipos.${tipo}` as ClaveMensaje),
    value: tipo,
  })),
)

async function crear() {
  pendiente.value = true
  error.value = null

  try {
    await $fetch('/api/registro', {
      method: 'POST',
      body: {
        correo: formulario.correo.trim(),
        contrasena: formulario.contrasena,
        nombres: formulario.nombres.trim(),
        apellidos: formulario.apellidos.trim(),
        tipoDocumento: formulario.tipoDocumento,
        numeroDocumento: formulario.numeroDocumento.trim(),
        telefono: formulario.telefono.trim() || undefined,
      },
    })

    // El registro abre la sesión con su cookie; la cuenta queda lista.
    await $fetch<RespuestaCuenta>('/api/cuenta')
    await refreshNuxtData('cuenta')

    await navigateTo(retorno.value)
  } catch (fallo) {
    error.value = mensajeDeError(fallo)
  } finally {
    pendiente.value = false
  }
}
</script>

<template>
  <div class="mx-auto max-w-xl space-y-6">
    <BaseEncabezadoPagina
      :titulo="t('registro.titulo')"
      :descripcion="t('registro.introduccion')"
    />

    <BaseTarjeta>
      <form class="space-y-4" @submit.prevent="crear">
        <div class="grid gap-4 sm:grid-cols-2">
          <UFormField
            :label="t('registro.form.correo')"
            name="correo"
            :help="t('registro.ayudaCorreo')"
          >
            <UInput
              v-model="formulario.correo"
              type="email"
              autocomplete="email"
              class="w-full"
              required
            />
          </UFormField>

          <UFormField
            :label="t('registro.form.contrasena')"
            name="contrasena"
            :help="t('registro.ayudaContrasena')"
          >
            <UInput
              v-model="formulario.contrasena"
              type="password"
              autocomplete="new-password"
              class="w-full"
              required
              minlength="8"
            />
          </UFormField>
        </div>

        <div class="grid gap-4 sm:grid-cols-2">
          <UFormField :label="t('registro.form.nombres')" name="nombres">
            <UInput v-model="formulario.nombres" class="w-full" required />
          </UFormField>
          <UFormField :label="t('registro.form.apellidos')" name="apellidos">
            <UInput v-model="formulario.apellidos" class="w-full" required />
          </UFormField>
        </div>

        <div class="grid gap-4 sm:grid-cols-2">
          <UFormField
            :label="t('registro.form.tipoDocumento')"
            name="tipoDocumento"
          >
            <USelect
              v-model="formulario.tipoDocumento"
              :items="tiposDocumento"
              class="w-full"
            />
          </UFormField>
          <UFormField
            :label="t('registro.form.numeroDocumento')"
            name="numeroDocumento"
          >
            <UInput
              v-model="formulario.numeroDocumento"
              autocapitalize="characters"
              class="w-full"
              required
            />
          </UFormField>
        </div>

        <UFormField :label="t('registro.form.telefono')" name="telefono">
          <UInput
            v-model="formulario.telefono"
            type="tel"
            class="w-full"
          />
        </UFormField>

        <UAlert v-if="error" color="error" variant="soft" :title="error" />

        <UButton
          type="submit"
          color="primary"
          block
          :loading="pendiente"
          :label="t('registro.enviar')"
        />
      </form>
    </BaseTarjeta>

    <p class="text-center text-(length:--vt-texto-sm)">
      {{ t('registro.tengoCuenta') }}
      <UButton
        :to="rutaIngreso"
        variant="soft"
        color="primary"
        size="xs"
        :label="t('registro.ingresar')"
      />
    </p>
  </div>
</template>
