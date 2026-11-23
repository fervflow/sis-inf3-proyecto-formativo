<script setup lang="ts">
/**
 * Solicitud de reserva para el canal web (HU-06).
 *
 * El cliente sin cuenta pide cupo desde la página de disponibilidad: se
 * identifica con su documento y, si no tiene ficha, se registra con los
 * datos de contacto que envía. La regla de cupos la valida la base con
 * `fn_crear_reserva`.
 */
import type { ClaveMensaje } from '~/i18n'
import type {
  ReservaResumen,
  SalidaDisponible,
} from '#shared/types/api'

const props = defineProps<{
  /** Salida a la que se pide cupo. */
  salida: SalidaDisponible
}>()

const emit = defineEmits<{
  /** La solicitud se registró; la vista cierra el formulario. */
  registrada: [reserva: ReservaResumen]
}>()

const { t } = useTexto()
const mensajeDeError = useMensajeError()
const { moneda, fecha } = useFormato()

const guardando = ref(false)
const error = ref<string | null>(null)

const formulario = reactive({
  tipoDocumento: 'CI' as 'CI' | 'NIT' | 'PASAPORTE' | 'OTRO',
  numeroDocumento: '',
  nombres: '',
  apellidos: '',
  correo: '',
  telefono: '',
  cantidadPasajeros: 1,
})

const tiposDocumento = computed(() =>
  (['CI', 'NIT', 'PASAPORTE', 'OTRO'] as const).map((tipo) => ({
    label: t(`clientes.tipos.${tipo}` as ClaveMensaje),
    value: tipo,
  })),
)

async function guardar() {
  guardando.value = true
  error.value = null
  try {
    const respuesta = await $fetch<ReservaResumen>('/api/reservas', {
      method: 'POST',
      body: {
        tipoDocumento: formulario.tipoDocumento,
        numeroDocumento: formulario.numeroDocumento.trim(),
        nombres: formulario.nombres.trim(),
        apellidos: formulario.apellidos.trim(),
        correo: formulario.correo.trim() || undefined,
        telefono: formulario.telefono.trim() || undefined,
        idSalida: props.salida.id_salida,
        cantidadPasajeros: formulario.cantidadPasajeros,
      },
    })
    emit('registrada', respuesta)
  } catch (fallo) {
    error.value = mensajeDeError(fallo)
  } finally {
    guardando.value = false
  }
}

defineExpose({
  reiniciar() {
    formulario.tipoDocumento = 'CI'
    formulario.numeroDocumento = ''
    formulario.nombres = ''
    formulario.apellidos = ''
    formulario.correo = ''
    formulario.telefono = ''
    formulario.cantidadPasajeros = 1
    error.value = null
  },
})
</script>

<template>
  <form id="form-solicitud" class="space-y-4" @submit.prevent="guardar">
    <div
      class="rounded-(--vt-radio-md) px-3 py-2 text-(--vt-texto-sm) ring-1 ring-(--vt-color-borde)"
    >
      <p class="font-(--vt-texto-peso-medio)">
        {{ salida.paquete }}
        <span class="text-(--vt-texto-xs) text-(--vt-color-texto-suave)">
          · {{ salida.codigo_paquete }}
        </span>
      </p>
      <p class="text-(--vt-texto-xs) text-(--vt-color-texto-suave)">
        {{ fecha(salida.fecha_salida) }} → {{ fecha(salida.fecha_retorno) }} ·
        {{ salida.cupo_disponible }} {{ t('solicitudes.disponibles') }} ·
        {{ moneda(salida.precio) }}
      </p>
    </div>

    <div class="grid gap-4 sm:grid-cols-2">
      <UFormField :label="t('solicitudes.form.tipoDocumento')" name="tipoDocumento">
        <USelect
          v-model="formulario.tipoDocumento"
          :items="tiposDocumento"
          class="w-full"
        />
      </UFormField>

      <UFormField
        :label="t('solicitudes.form.numeroDocumento')"
        name="numeroDocumento"
        required
      >
        <UInput
          v-model="formulario.numeroDocumento"
          class="w-full"
          maxlength="30"
          required
        />
      </UFormField>
    </div>

    <div class="grid gap-4 sm:grid-cols-2">
      <UFormField :label="t('solicitudes.form.nombres')" name="nombres" required>
        <UInput v-model="formulario.nombres" class="w-full" maxlength="100" required />
      </UFormField>

      <UFormField :label="t('solicitudes.form.apellidos')" name="apellidos" required>
        <UInput v-model="formulario.apellidos" class="w-full" maxlength="100" required />
      </UFormField>
    </div>

    <div class="grid gap-4 sm:grid-cols-2">
      <UFormField
        :label="t('solicitudes.form.correo')"
        name="correo"
        :help="t('solicitudes.ayudaCorreo')"
      >
        <UInput v-model="formulario.correo" type="email" class="w-full" maxlength="150" />
      </UFormField>

      <UFormField :label="t('solicitudes.form.telefono')" name="telefono">
        <UInput v-model="formulario.telefono" class="w-full" maxlength="30" />
      </UFormField>
    </div>

    <UFormField
      :label="t('solicitudes.form.cantidad')"
      name="cantidad"
      :help="t('solicitudes.ayudaCantidad')"
    >
      <UInputNumber
        v-model="formulario.cantidadPasajeros"
        :min="1"
        :max="Math.max(1, salida.cupo_disponible)"
        :step="1"
        :increment="false"
        :decrement="false"
        class="w-full"
      />
    </UFormField>

    <p class="text-(--vt-texto-xs) text-(--vt-color-texto-suave)">
      {{ t('solicitudes.ayudaVencimiento') }}
    </p>

    <UAlert v-if="error" color="error" variant="soft" :title="error" />
  </form>
</template>
