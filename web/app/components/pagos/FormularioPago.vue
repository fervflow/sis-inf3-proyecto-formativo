<script setup lang="ts">
/**
 * Pago del cliente por la pasarela simulada (HU-14).
 *
 * Emula el cobro por banca móvil o código QR: el servidor genera la
 * referencia y el pago nace `registrado`, a la espera de la validación
 * del personal (RN-PAG-03 y RN-PAG-04). El mínimo del anticipo y el tope
 * del saldo los aplica `fn_registrar_pago`; la interfaz muestra los
 * mismos límites con los datos de la consulta de pagos.
 */
import type { ClaveMensaje } from '~/i18n'
import type {
  RespuestaPagos,
  ReservaResumen,
} from '#shared/types/api'
import {
  ANTICIPO_MINIMO_PORCENTAJE,
  METODOS_WEB,
  montoMinimoAnticipo,
} from '#shared/pagos'

const props = defineProps<{
  /** La reserva a la que se abona. */
  reserva: ReservaResumen
}>()

const emit = defineEmits<{
  /** El pago quedó registrado; la vista muestra la confirmación. */
  pagado: [respuesta: RespuestaPagos]
  /** La persona canceló; la vista cierra el formulario. */
  cancelar: []
}>()

const { t } = useTexto()
const mensajeDeError = useMensajeError()
const { moneda } = useFormato()

const cargando = ref(false)
const error = ref<string | null>(null)
const pagos = ref<RespuestaPagos | null>(null)

/** Todo lo no anulado: un pago registrado también compromete el total. */
const comprometido = computed(() => {
  if (!pagos.value) return 0
  const total = Number(pagos.value.resumen.montoTotal) || 0
  return Math.round((total - Number(pagos.value.resumen.saldoPendiente)) * 100) / 100
})

const tieneAnticipo = computed(
  () =>
    pagos.value?.pagos.some(
      (pago) => pago.tipo === 'anticipo' && pago.estado !== 'anulado',
    ) ?? false,
)

/** El saldo solo existe si ya hay anticipo, y paga el resto exacto. */
const disponible = computed(() => {
  const total = Number(props.reserva.montoTotal) || 0
  return Math.round((total - comprometido.value) * 100) / 100
})

const minimo = computed(() => montoMinimoAnticipo(props.reserva.montoTotal))

const puedeSaldo = computed(() => tieneAnticipo.value && disponible.value > 0)

const formulario = reactive({
  tipo: 'anticipo' as 'anticipo' | 'saldo',
  metodo: 'banca_movil' as (typeof METODOS_WEB)[number],
  monto: minimo.value,
})

/** Al cargar los pagos, el monto se ajusta al mínimo o al resto. */
async function cargarPagos() {
  try {
    pagos.value = await $fetch<RespuestaPagos>('/api/pagos', {
      query: { reserva: props.reserva.idReserva },
    })
    ajustar()
  } catch (fallo) {
    error.value = mensajeDeError(fallo)
  }
}

function ajustar() {
  formulario.monto = formulario.tipo === 'saldo' ? disponible.value : minimo.value
}

watch(
  () => formulario.tipo,
  ajustar,
)

const metodos = computed(() =>
  METODOS_WEB.map((metodo) => ({
    label: t(`pagos.metodos.${metodo}` as ClaveMensaje),
    value: metodo,
  })),
)

const tipos = computed(() => [
  { label: t('pagos.tipos.anticipo'), value: 'anticipo' as const },
  ...(puedeSaldo.value
    ? [{ label: t('pagos.tipos.saldo'), value: 'saldo' as const }]
    : []),
])

const montoInvalido = computed(() => {
  if (formulario.tipo === 'saldo') {
    return Math.abs(formulario.monto - disponible.value) > 0.005
  }
  return (
    formulario.monto < minimo.value - 0.005 || formulario.monto > disponible.value + 0.005
  )
})

async function pagar() {
  if (montoInvalido.value) return
  cargando.value = true
  error.value = null
  try {
    const respuesta = await $fetch<RespuestaPagos>('/api/pagos', {
      method: 'POST',
      body: {
        idReserva: props.reserva.idReserva,
        tipo: formulario.tipo,
        monto: formulario.monto,
        metodo: formulario.metodo,
        observacion: t('pasarela.observacion'),
      },
    })
    emit('pagado', respuesta)
  } catch (fallo) {
    error.value = mensajeDeError(fallo)
  } finally {
    cargando.value = false
  }
}

await cargarPagos()

defineExpose({ ajustar })
</script>

<template>
  <form id="form-pago" class="space-y-4" @submit.prevent="pagar">
    <UAlert
      color="info"
      variant="soft"
      icon="i-lucide-credit-card"
      :title="t('pasarela.introduccion')"
    />

    <div
      class="rounded-(--vt-radio-md) px-3 py-2 text-(--vt-texto-sm) ring-1 ring-(--vt-color-borde)"
    >
      <p class="font-(--vt-texto-peso-medio)">
        {{ reserva.paquete }} · {{ reserva.codigo }}
      </p>
      <p class="text-(--vt-texto-xs) text-(--vt-color-texto-suave)">
        {{ t('pagos.total') }}: {{ moneda(reserva.montoTotal) }}
        <template v-if="comprometido > 0">
          · {{ t('pagos.comprometido') }}: {{ moneda(String(comprometido)) }}
        </template>
      </p>
    </div>

    <div class="grid gap-4 sm:grid-cols-2">
      <UFormField :label="t('pagos.form.tipo')" name="tipo">
        <USelect v-model="formulario.tipo" :items="tipos" class="w-full" />
      </UFormField>

      <UFormField :label="t('pagos.form.metodo')" name="metodo">
        <USelect v-model="formulario.metodo" :items="metodos" class="w-full" />
      </UFormField>
    </div>

    <UFormField
      :label="t('pagos.form.monto')"
      name="monto"
      :help="
        formulario.tipo === 'saldo'
          ? t('pagos.ayudaSaldo')
          : t('pagos.ayudaMinimo', { porcentaje: ANTICIPO_MINIMO_PORCENTAJE })
      "
    >
      <UInputNumber
        v-model="formulario.monto"
        :min="formulario.tipo === 'saldo' ? disponible : minimo"
        :max="disponible"
        :step="10"
        :disabled="formulario.tipo === 'saldo'"
        class="w-full"
      />
      <p class="mt-1 text-(--vt-texto-xs) text-(--vt-color-texto-suave)">
        {{ t('pasarela.minimo', { monto: moneda(String(minimo)) }) }}
      </p>
    </UFormField>

    <UAlert
      color="neutral"
      variant="subtle"
      icon="i-lucide-rotate-ccw"
      :title="t('pagos.lineamientosTitulo')"
      :description="t('pagos.lineamientos')"
    />

    <UAlert v-if="error" color="error" variant="soft" :title="error" />

    <div class="flex justify-end gap-2">
      <UButton
        color="neutral"
        variant="ghost"
        :label="t('pasarela.tarde')"
        @click="emit('cancelar')"
      />
      <UButton
        type="submit"
        form="form-pago"
        color="primary"
        icon="i-lucide-banknote"
        :label="t('pasarela.pagar', { monto: moneda(String(formulario.monto)) })"
        :disabled="montoInvalido"
        :loading="cargando"
      />
    </div>
  </form>
</template>
