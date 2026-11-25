<script setup lang="ts">
/**
 * Pago del cliente por la pasarela simulada (HU-14).
 *
 * Emula el cobro por banca móvil o código QR: el servidor genera la
 * referencia y el pago nace `registrado`, a la espera de la validación
 * del personal (RN-PAG-03 y RN-PAG-04). La reserva manda: sin anticipo
 * se paga el anticipo (mínimo del 30%, RN-PAG-01); con el anticipo ya
 * validado se paga el saldo, que admite abonos parciales (RN-PAG-05);
 * si el anticipo aún espera validación, no se paga nada todavía.
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
const avisos = useAvisos()
const { moneda } = useFormato()

const cargando = ref(false)
const error = ref<string | null>(null)
const pagos = ref<RespuestaPagos | null>(null)

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

/** Lo comprometido: lo abonado validado más lo que espera validación. */
const comprometido = computed(() => {
  if (!resumen.value) return 0
  return (
    Math.round(
      (Number(resumen.value.abonado) + Number(resumen.value.enRevision)) * 100,
    ) / 100
  )
})

const tieneAnticipo = computed(() =>
  (pagos.value?.pagos ?? []).some(
    (pago) => pago.tipo === 'anticipo' && pago.estado !== 'anulado',
  ),
)

/** Lo registrado como anticipo: la suma de los anticipos no anulados. */
const anticipoRegistrado = computed(() =>
  (pagos.value?.pagos ?? [])
    .filter((pago) => pago.tipo === 'anticipo' && pago.estado !== 'anulado')
    .reduce((total, pago) => total + Number(pago.monto), 0),
)

const anticipoValidado = computed(() => resumen.value?.anticipoValidado ?? false)

/** El pago que sigue: anticipo si falta, saldo si el anticipo ya valida. */
const tipoPago = computed<'anticipo' | 'saldo'>(() =>
  tieneAnticipo.value ? 'saldo' : 'anticipo',
)

const minimo = computed(() => montoMinimoAnticipo(props.reserva.montoTotal))

const formulario = reactive({
  metodo: 'banca_movil' as (typeof METODOS_WEB)[number],
  monto: 0,
})

const metodos = computed(() =>
  METODOS_WEB.map((metodo) => ({
    label: t(`pagos.metodos.${metodo}` as ClaveMensaje),
    value: metodo,
  })),
)

const montoInvalido = computed(() => {
  if (tipoPago.value === 'saldo') {
    return formulario.monto < 0.01 || formulario.monto > disponible.value + 0.005
  }
  return (
    formulario.monto < minimo.value - 0.005 || formulario.monto > disponible.value + 0.005
  )
})

/** El anticipo está registrado pero el personal todavía no lo valida. */
const esperandoValidacion = computed(
  () => tieneAnticipo.value && !anticipoValidado.value,
)

async function cargarPagos() {
  error.value = null
  try {
    pagos.value = await $fetch<RespuestaPagos>('/api/pagos', {
      query: { reserva: props.reserva.idReserva },
    })
    formulario.monto = tipoPago.value === 'saldo' ? disponible.value : minimo.value
  } catch (fallo) {
    error.value = mensajeDeError(fallo)
  }
}

async function pagar() {
  if (montoInvalido.value) return
  cargando.value = true
  error.value = null
  try {
    const respuesta = await $fetch<RespuestaPagos>('/api/pagos', {
      method: 'POST',
      body: {
        idReserva: props.reserva.idReserva,
        tipo: tipoPago.value,
        monto: formulario.monto,
        metodo: formulario.metodo,
        observacion: t('pasarela.observacion'),
      },
    })
    emit('pagado', respuesta)
  } catch (fallo) {
    avisos.fallo(fallo)
  } finally {
    cargando.value = false
  }
}

await cargarPagos()
</script>

<template>
  <div class="space-y-4">
    <!--
      Anticipo registrado y sin validar: no se paga nada más todavía.
      El pago quedará en revisión junto al anticipo y no avanza la
      reserva; mejor esperar la validación.
    -->
    <template v-if="esperandoValidacion">
      <UAlert
        color="warning"
        variant="soft"
        icon="i-lucide-shield-alert"
        :title="t('pasarela.anticipoEnRevisionTitulo')"
        :description="
          t('pasarela.anticipoEnRevision', {
            monto: moneda(String(anticipoRegistrado)),
          })
        "
      />

      <UAlert v-if="error" color="error" variant="soft" :title="error" />

      <div class="flex justify-end">
        <UButton
          color="neutral"
          variant="ghost"
          :label="t('pasarela.tarde')"
          @click="emit('cancelar')"
        />
      </div>
    </template>

    <form v-else id="form-pago" class="space-y-4" @submit.prevent="pagar">
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
          <USelect
            :model-value="tipoPago"
            :items="[
              {
                label: t(`pagos.tipos.${tipoPago}` as ClaveMensaje),
                value: tipoPago,
              },
            ]"
            disabled
            class="w-full"
          />
        </UFormField>

        <UFormField :label="t('pagos.form.metodo')" name="metodo">
          <USelect v-model="formulario.metodo" :items="metodos" class="w-full" />
        </UFormField>
      </div>

      <UFormField
        :label="t('pagos.form.monto')"
        name="monto"
        :help="
          tipoPago === 'saldo'
            ? t('pagos.ayudaSaldo')
            : t('pagos.ayudaMinimo', { porcentaje: ANTICIPO_MINIMO_PORCENTAJE })
        "
      >
        <BaseCampoMoneda
          :model-value="formulario.monto"
          :min="tipoPago === 'saldo' ? 0.01 : minimo"
          :max="Math.max(disponible, 0.01)"
          :disabled="disponible <= 0"
          required
          @update:model-value="(valor) => (formulario.monto = valor ?? 0)"
        />
        <p class="mt-1 text-(--vt-texto-xs) text-(--vt-color-texto-suave)">
          {{
            tipoPago === 'saldo'
              ? t('pasarela.saldoRestante', { monto: moneda(String(disponible)) })
              : t('pasarela.minimo', { monto: moneda(String(minimo)) })
          }}
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
  </div>
</template>
