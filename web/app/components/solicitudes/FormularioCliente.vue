<script setup lang="ts">
/**
 * Solicitud de reserva del canal web (HU-06).
 *
 * El cliente con sesión pide cupo sobre su propia ficha: la firma su
 * cuenta (RN-RES-10) y la cantidad no supera el tope del canal
 * (RN-RES-15). La regla de cupos la valida la base con `fn_crear_reserva`.
 * Tras registrarla, la vista abre el pago del anticipo (HU-14).
 */
import type { ClaveMensaje } from '~/i18n'
import type { ReservaResumen, SalidaSolicitud } from '#shared/types/api'
import { SOLICITUD_WEB_MAXIMO_PASAJEROS } from '#shared/reservas'

const props = defineProps<{
  /** Salida a la que se pide cupo. */
  salida: SalidaSolicitud
}>()

const emit = defineEmits<{
  /** La solicitud se registró; la vista continúa con el pago. */
  registrada: [reserva: ReservaResumen]
  /** La persona canceló; la vista cierra el formulario. */
  cancelar: []
}>()

const { t } = useTexto()
const mensajeDeError = useMensajeError()
const { moneda, fecha } = useFormato()

const guardando = ref(false)
const error = ref<string | null>(null)

const formulario = reactive({
  cantidadPasajeros: 1,
})

async function guardar() {
  guardando.value = true
  error.value = null
  try {
    const respuesta = await $fetch<ReservaResumen>('/api/reservas', {
      method: 'POST',
      body: {
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
    formulario.cantidadPasajeros = 1
    error.value = null
  },
})
</script>

<template>
  <form id="form-solicitud-cliente" class="space-y-4" @submit.prevent="guardar">
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
        {{ moneda(salida.precio) }} {{ t('solicitudes.porPasajero') }}
      </p>
    </div>

    <UFormField
      :label="t('solicitudes.form.cantidad')"
      name="cantidad"
      :help="t('solicitudes.ayudaCantidad')"
    >
      <UInputNumber
        v-model="formulario.cantidadPasajeros"
        :min="1"
        :max="Math.min(SOLICITUD_WEB_MAXIMO_PASAJEROS, salida.cupo_disponible)"
        :step="1"
        :increment="false"
        :decrement="false"
        class="w-full"
      />
    </UFormField>

    <UAlert
      v-if="error"
      color="error"
      variant="soft"
      :title="error"
    />

    <div class="flex justify-end gap-2">
      <UButton
        color="neutral"
        variant="ghost"
        :label="t('comun.cancelar')"
        @click="emit('cancelar')"
      />
      <UButton
        type="submit"
        form="form-solicitud-cliente"
        color="primary"
        :label="t('solicitudes.cliente.enviar')"
        :loading="guardando"
      />
    </div>
  </form>
</template>
