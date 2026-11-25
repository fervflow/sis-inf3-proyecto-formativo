<script setup lang="ts">
/**
 * Pagos de una reserva con su resumen (HU-14).
 *
 * Muestra el total, lo abonado validado, lo que espera validación y el
 * saldo pendiente, con el historial de pagos. Para el personal añade las
 * acciones de validar y anular y el registro de un pago de oficina; el
 * cliente ve solo consulta. La regla de pagos vive en la base: aquí solo
 * se llama a la API.
 *
 * El formulario reacciona al estado de los pagos (RN-PAG-01, RN-PAG-02 y
 * RN-PAG-05): sin anticipo propone el mínimo del 30%; con anticipo pasa
 * al saldo y propone el pendiente, que puede abonarse por partes. El
 * monto que el usuario tecleó se respeta: los valores automáticos solo
 * se reponen mientras el formulario no se toque.
 */
import type { ClaveMensaje } from '~/i18n'
import type {
  RespuestaPagos,
  ReservaResumen,
} from '#shared/types/api'
import type { MetodoPago, TipoPago } from '#shared/types/domain'
import {
  ANTICIPO_MINIMO_PORCENTAJE,
  METODOS_OFICINA,
  montoMinimoAnticipo,
} from '#shared/pagos'

const props = defineProps<{
  /** Reserva cuyos pagos se muestran. */
  idReserva: number
  /** El personal puede validar, anular y registrar pagos. */
  editable?: boolean
  /** La reserva, para saber si el formulario de oficina procede. */
  reserva?: ReservaResumen
}>()

const emit = defineEmits<{
  /** Los pagos cambiaron; la vista que contiene recarga sus datos. */
  cambio: []
}>()

const { t } = useTexto()
const mensajeDeError = useMensajeError()
const avisos = useAvisos()
const { moneda, fechaHora } = useFormato()

const pagos = ref<RespuestaPagos | null>(null)
const error = ref<string | null>(null)
const operando = ref<number | null>(null)

const filas = computed(() => pagos.value?.pagos ?? [])
const resumen = computed(() => pagos.value?.resumen)

/** El pendiente real para un pago nuevo: el saldo menos lo en revisión. */
const disponible = computed(() => {
  if (!resumen.value) return 0
  return (
    Math.round(
      (Number(resumen.value.saldoPendiente) - Number(resumen.value.enRevision)) * 100,
    ) / 100
  )
})

const minimo = computed(() => montoMinimoAnticipo(resumen.value?.montoTotal ?? '0'))

/** Un anticipo no anulado ya compromete parte del total (RN-PAG-05). */
const tieneAnticipo = computed(() =>
  filas.value.some((pago) => pago.tipo === 'anticipo' && pago.estado !== 'anulado'),
)

// --- Formulario de pago de oficina ---------------------------------------

const formularioAbierto = computed(
  () =>
    !!props.editable &&
    !!props.reserva &&
    ['pendiente', 'confirmada'].includes(props.reserva.estado),
)

const formularioTocado = ref(false)
const registrando = ref(false)

const formulario = reactive({
  tipo: 'anticipo' as TipoPago,
  metodo: 'efectivo' as (typeof METODOS_OFICINA)[number],
  monto: 0,
  referencia: '',
})

/** Repone los valores sugeridos según el estado de los pagos. */
function ajustarFormulario() {
  if (tieneAnticipo.value) {
    formulario.tipo = 'saldo'
    formulario.monto = disponible.value
  } else {
    formulario.tipo = 'anticipo'
    formulario.monto = minimo.value
  }
}

/** Al registrar o validar un pago cambia lo pendiente: se reponen las
    sugerencias solo si la persona no escribió su propio monto. */
watch([tieneAnticipo, disponible], () => {
  if (!formularioTocado.value) ajustarFormulario()
})

const tiposPago = computed(() => [
  { label: t('pagos.tipos.anticipo'), value: 'anticipo' as const },
  { label: t('pagos.tipos.saldo'), value: 'saldo' as const },
])

const metodosPago = computed(() =>
  METODOS_OFICINA.map((metodo) => ({
    label: t(`pagos.metodos.${metodo}` as ClaveMensaje),
    value: metodo,
  })),
)

/** El tope del monto: el saldo pendiente para ambos tipos (RN-PAG-05). */
const montoMaximo = computed(() => disponible.value)

const montoInvalido = computed(() => {
  if (formulario.tipo === 'anticipo') {
    return (
      formulario.monto < minimo.value - 0.005 ||
      formulario.monto > montoMaximo.value + 0.005
    )
  }
  return formulario.monto < 0.01 || formulario.monto > montoMaximo.value + 0.005
})

async function registrarPago() {
  if (montoInvalido.value) return
  registrando.value = true
  error.value = null
  try {
    await $fetch('/api/pagos', {
      method: 'POST',
      body: {
        idReserva: props.idReserva,
        tipo: formulario.tipo,
        monto: formulario.monto,
        metodo: formulario.metodo,
        referencia: formulario.referencia.trim() || undefined,
      },
    })
    avisos.exito('pagos.registradoOk')
    formularioTocado.value = false
    await cargar()
    emit('cambio')
  } catch (fallo) {
    avisos.fallo(fallo)
  } finally {
    registrando.value = false
  }
}

// --- Resumen e historial -------------------------------------------------

async function cargar() {
  error.value = null
  try {
    pagos.value = await $fetch<RespuestaPagos>('/api/pagos', {
      query: { reserva: props.idReserva },
    })
    if (!formularioTocado.value) ajustarFormulario()
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
    avisos.exito(anular ? 'pagos.anuladoOk' : 'pagos.validadoOk')
    await cargar()
    emit('cambio')
  } catch (fallo) {
    avisos.fallo(fallo)
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
      class="grid grid-cols-2 gap-3 text-(length:--vt-texto-sm) sm:grid-cols-4"
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
      class="text-(length:--vt-texto-sm) text-(--vt-color-texto-suave)"
    >
      {{ t('pagos.sinPagos') }}
    </p>

    <table v-else class="w-full text-(length:--vt-texto-sm)">
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

    <!--
      Registro de un pago de oficina (HU-14): el tipo y el monto se
      sugieren según los pagos ya registrados, y el monto admite
      abonar el saldo por partes (RN-PAG-02 y RN-PAG-05).
    -->
    <form
      v-if="formularioAbierto"
      id="form-pago-oficina"
      class="space-y-3 rounded-(--vt-radio-md) px-3 py-3 ring-1 ring-(--vt-color-borde)"
      @submit.prevent="registrarPago"
    >
      <p class="font-(--vt-texto-peso-medio) text-(length:--vt-texto-sm)">
        {{ t('pagos.registrarTitulo') }}
      </p>

      <div class="grid gap-3 sm:grid-cols-2">
        <UFormField :label="t('pagos.form.tipo')" name="tipo">
          <USelect
            v-model="formulario.tipo"
            :items="tiposPago"
            class="w-full"
            @update:model-value="formularioTocado = true"
          />
        </UFormField>
        <UFormField :label="t('pagos.form.metodo')" name="metodo">
          <USelect v-model="formulario.metodo" :items="metodosPago" class="w-full" />
        </UFormField>
      </div>

      <div class="grid gap-3 sm:grid-cols-2">
        <UFormField
          :label="t('pagos.form.monto')"
          name="monto"
          :help="
            formulario.tipo === 'saldo'
              ? t('pagos.ayudaSaldo')
              : t('pagos.ayudaMinimo', { porcentaje: ANTICIPO_MINIMO_PORCENTAJE })
          "
        >
          <BaseCampoMoneda
            :model-value="formulario.monto"
            :min="formulario.tipo === 'anticipo' ? minimo : 0.01"
            :max="Math.max(montoMaximo, 0.01)"
            :disabled="montoMaximo <= 0"
            required
            @update:model-value="
              (valor) => {
                formulario.monto = valor ?? 0
                formularioTocado = true
              }
            "
          />
        </UFormField>
        <UFormField :label="t('pagos.form.referencia')" name="referencia">
          <UInput v-model="formulario.referencia" class="w-full" />
        </UFormField>
      </div>

      <UAlert
        color="neutral"
        variant="subtle"
        icon="i-lucide-rotate-ccw"
        :title="t('pagos.lineamientosTitulo')"
        :description="t('pagos.lineamientos')"
      />

      <div class="flex justify-end">
        <UButton
          type="submit"
          form="form-pago-oficina"
          color="primary"
          size="sm"
          :label="t('pagos.registrar')"
          :disabled="montoInvalido"
          :loading="registrando"
        />
      </div>
    </form>

    <UAlert v-if="error" color="error" variant="soft" :title="error" />
  </div>
</template>
