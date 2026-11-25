<script setup lang="ts">
/**
 * Modificación de la salida de una reserva (HU-07, T-HU-07.2).
 *
 * Cambia la salida; la cantidad la maneja el manifiesto (RN-RES-21). La
 * base revalida los cupos en una transacción que bloquea la salida,
 * recalcula el monto con el precio vigente y rechaza que los pagos
 * comprometidos queden por encima del nuevo total (RN-RES-20).
 */
import type {
  RespuestaDisponibilidad,
  ReservaResumen,
} from '#shared/types/api'

const props = defineProps<{
  /** La reserva que se modifica. */
  reserva: ReservaResumen
}>()

const emit = defineEmits<{
  /** La reserva quedó modificada; la vista recarga sus datos. */
  guardada: [reserva: ReservaResumen]
  /** La persona canceló; la vista cierra el formulario. */
  cancelar: []
}>()

const { t } = useTexto()
const mensajeDeError = useMensajeError()
const { moneda, fecha } = useFormato()
const peticion = useRequestFetch()

const guardando = ref(false)
const error = ref<string | null>(null)
const salidas = ref<RespuestaDisponibilidad | null>(null)

const formulario = reactive({
  idSalida: props.reserva.idSalida,
})

const { data: respuesta } = await useAsyncData<RespuestaDisponibilidad>(
  'salidas-modificar-reserva',
  () => peticion<RespuestaDisponibilidad>('/api/disponibilidad'),
)

salidas.value = respuesta.value ?? null

const opciones = computed(() =>
  (salidas.value?.salidas ?? [])
    .filter(
      (salida) =>
        salida.cupo_disponible > 0 ||
        salida.id_salida === props.reserva.idSalida,
    )
    .map((salida) => ({
      label: `${salida.paquete} · ${salida.fecha_salida} · ${salida.cupo_disponible} ${t('solicitudes.disponibles')}`,
      value: salida.id_salida,
    })),
)

const salidaSeleccionada = computed(() =>
  (salidas.value?.salidas ?? []).find(
    (salida) => salida.id_salida === formulario.idSalida,
  ),
)

/** Pasajeros que pueden ir a la salida elegida: los propios o los libres. */
const maximo = computed(() => {
  const libres = salidaSeleccionada.value
    ? salidaSeleccionada.value.cupo_disponible +
      (salidaSeleccionada.value.id_salida === props.reserva.idSalida
        ? props.reserva.cantidadPasajeros
        : 0)
    : props.reserva.cantidadPasajeros
  return Math.max(libres, props.reserva.cantidadPasajeros)
})

const montoNuevo = computed(() => {
  if (!salidaSeleccionada.value) return props.reserva.montoTotal
  const precio = Number(salidaSeleccionada.value.precio) || 0
  return (precio * props.reserva.cantidadPasajeros).toFixed(2)
})

const cambio = computed(
  () => formulario.idSalida !== props.reserva.idSalida,
)

async function guardar() {
  if (!cambio.value) return
  guardando.value = true
  error.value = null
  try {
    const reserva = await peticion<ReservaResumen>(
      `/api/reservas/${props.reserva.idReserva}`,
      {
        method: 'PATCH',
        body: { idSalida: formulario.idSalida },
      },
    )
    emit('guardada', reserva)
  } catch (fallo) {
    error.value = mensajeDeError(fallo)
  } finally {
    guardando.value = false
  }
}
</script>

<template>
  <form id="form-modificar-reserva" class="space-y-4" @submit.prevent="guardar">
    <div
      class="rounded-(--vt-radio-md) px-3 py-2 text-(length:--vt-texto-sm) ring-1 ring-(--vt-color-borde)"
    >
      <p class="font-(--vt-texto-peso-medio)">
        {{ reserva.paquete }} · {{ reserva.codigo }}
      </p>
      <p class="text-(length:--vt-texto-xs) text-(--vt-color-texto-suave)">
        {{ t('historial.cantidadActual', { cantidad: reserva.cantidadPasajeros }) }}
        · {{ t('historial.montoActual', { monto: moneda(reserva.montoTotal) }) }}
      </p>
    </div>

    <UFormField
      :label="t('solicitudes.form.salida')"
      name="salida"
      :help="t('historial.ayudaSalida')"
    >
      <USelect
        v-model="formulario.idSalida"
        :items="opciones"
        class="w-full"
      />
    </UFormField>

    <UAlert
      v-if="salidaSeleccionada"
      color="info"
      variant="soft"
      :title="t('historial.montoNuevo', {
        salida: `${salidaSeleccionada.paquete} (${fecha(salidaSeleccionada.fecha_salida)})`,
        monto: moneda(String(montoNuevo)),
      })"
    />

    <UAlert
      v-if="!cambio"
      color="neutral"
      variant="subtle"
      :title="t('historial.sinCambio')"
    />

    <UAlert v-if="error" color="error" variant="soft" :title="error" />

    <div class="flex justify-end gap-2">
      <UButton
        color="neutral"
        variant="ghost"
        :label="t('comun.cancelar')"
        @click="emit('cancelar')"
      />
      <UButton
        color="primary"
        :label="t('historial.guardar')"
        :disabled="!cambio"
        :loading="guardando"
        @click="guardar"
      />
    </div>
  </form>
</template>
