<script setup lang="ts">
/**
 * Pagos de una reserva con su resumen (HU-14).
 *
 * Muestra el total, lo abonado validado, lo que espera validación y el
 * saldo pendiente, con el historial de pagos. Para el personal añade las
 * acciones de validar y anular; el cliente ve solo consulta. La regla de
 * pagos vive en la base: aquí solo se llama a la API.
 */
import type { ClaveMensaje } from '~/i18n'
import type { RespuestaPagos } from '#shared/types/api'

const props = defineProps<{
  /** Reserva cuyos pagos se muestran. */
  idReserva: number
  /** El personal puede validar o anular pagos registrados. */
  editable?: boolean
}>()

const emit = defineEmits<{
  /** Los pagos cambiaron; la vista que contiene recarga sus datos. */
  cambio: []
}>()

const { t } = useTexto()
const mensajeDeError = useMensajeError()
const { moneda, fechaHora } = useFormato()

const pagos = ref<RespuestaPagos | null>(null)
const error = ref<string | null>(null)
const operando = ref<number | null>(null)

const filas = computed(() => pagos.value?.pagos ?? [])
const resumen = computed(() => pagos.value?.resumen)

async function cargar() {
  error.value = null
  try {
    pagos.value = await $fetch<RespuestaPagos>('/api/pagos', {
      query: { reserva: props.idReserva },
    })
  } catch (fallo) {
    error.value = mensajeDeError(fallo)
  }
}

function colorDeEstado(estado: string): 'warning' | 'success' | 'error' {
  if (estado === 'validado') return 'success'
  if (estado === 'registrado') return 'warning'
  return 'error'
}

function etiquetaEstado(estado: string): string {
  return t(`pagos.estados.${estado}` as ClaveMensaje)
}

function etiquetaTipo(tipo: string): string {
  return t(`pagos.tipos.${tipo}` as ClaveMensaje)
}

function etiquetaMetodo(metodo: string): string {
  return t(`pagos.metodos.${metodo}` as ClaveMensaje)
}

async function validar(idPago: number, anular: boolean) {
  operando.value = idPago
  error.value = null
  try {
    await $fetch(`/api/pagos/${idPago}/validar`, {
      method: 'POST',
      body: { anular },
    })
    await cargar()
    emit('cambio')
  } catch (fallo) {
    error.value = mensajeDeError(fallo)
  } finally {
    operando.value = null
  }
}

await cargar()

defineExpose({ recargar: cargar })
</script>

<template>
  <div class="space-y-4">
    <dl
      v-if="resumen"
      class="grid grid-cols-2 gap-3 text-(--vt-texto-sm) sm:grid-cols-4"
    >
      <div
        v-for="dato in [
          { etiqueta: t('pagos.total'), valor: resumen.montoTotal },
          { etiqueta: t('pagos.abonado'), valor: resumen.abonado },
          { etiqueta: t('pagos.enRevision'), valor: resumen.enRevision },
          { etiqueta: t('pagos.saldoPendiente'), valor: resumen.saldoPendiente },
        ]"
        :key="dato.etiqueta"
        class="rounded-(--vt-radio-md) px-3 py-2 ring-1 ring-(--vt-color-borde)"
      >
        <dt class="text-xs text-(--vt-color-texto-suave)">
          {{ dato.etiqueta }}
        </dt>
        <dd class="tabular-nums">{{ moneda(dato.valor) }}</dd>
      </div>
    </dl>

    <UAlert
      v-if="resumen && !resumen.anticipoValidado && editable"
      color="warning"
      variant="soft"
      icon="i-lucide-shield-alert"
      :title="t('pagos.sinAnticipoValidado')"
    />

    <p
      v-if="filas.length === 0"
      class="text-(--vt-texto-sm) text-(--vt-color-texto-suave)"
    >
      {{ t('pagos.sinPagos') }}
    </p>

    <table v-else class="w-full text-(--vt-texto-sm)">
      <thead class="text-left text-xs text-(--vt-color-texto-suave)">
        <tr>
          <th class="pb-2">{{ t('pagos.columnas.fecha') }}</th>
          <th class="pb-2">{{ t('pagos.columnas.tipo') }}</th>
          <th class="pb-2">{{ t('pagos.columnas.metodo') }}</th>
          <th class="pb-2">{{ t('pagos.columnas.referencia') }}</th>
          <th class="pb-2 text-right">{{ t('pagos.columnas.monto') }}</th>
          <th class="pb-2">{{ t('pagos.columnas.estado') }}</th>
          <th v-if="editable" class="pb-2 text-right">
            {{ t('pagos.columnas.acciones') }}
          </th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="pago in filas"
          :key="pago.idPago"
          class="border-t border-(--vt-color-borde)"
        >
          <td class="py-2">{{ fechaHora(pago.fechaPago) }}</td>
          <td class="py-2">{{ etiquetaTipo(pago.tipo) }}</td>
          <td class="py-2">{{ etiquetaMetodo(pago.metodo) }}</td>
          <td class="py-2 tabular-nums">{{ pago.referencia ?? '—' }}</td>
          <td class="py-2 text-right tabular-nums">{{ moneda(pago.monto) }}</td>
          <td class="py-2">
            <UBadge
              :color="colorDeEstado(pago.estado)"
              variant="subtle"
              :label="etiquetaEstado(pago.estado)"
            />
          </td>
          <td v-if="editable" class="py-2 text-right">
            <UButton
              v-if="pago.estado === 'registrado'"
              size="xs"
              color="primary"
              variant="soft"
              :label="t('pagos.validar')"
              :loading="operando === pago.idPago"
              @click="validar(pago.idPago, false)"
            />
            <UButton
              v-else-if="pago.estado === 'validado'"
              size="xs"
              color="neutral"
              variant="soft"
              :label="t('pagos.anular')"
              :loading="operando === pago.idPago"
              @click="validar(pago.idPago, true)"
            />
          </td>
        </tr>
      </tbody>
    </table>

    <UAlert v-if="error" color="error" variant="soft" :title="error" />
  </div>
</template>
