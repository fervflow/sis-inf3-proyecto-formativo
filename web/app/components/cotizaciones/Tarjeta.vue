<script setup lang="ts">
/**
 * Tarjeta de una cotización.
 *
 * Resume el cliente, la salida, los pasajeros, el total y las condiciones.
 * La apertura y el origen de la reserva se delegan a la vista; la tarjeta
 * no llama a la API.
 */
import type { CotizacionAdmin } from '#shared/types/api'
import type { ClaveMensaje } from '~/i18n'

const props = defineProps<{
  cotizacion: CotizacionAdmin
  /** La vista está originando la reserva de esta tarjeta. */
  originando?: boolean
}>()

const emit = defineEmits<{
  abrir: [cotizacion: CotizacionAdmin]
  reservar: [cotizacion: CotizacionAdmin]
}>()

const { t } = useTexto()
const { moneda, fecha } = useFormato()

const estadoEtiqueta = computed(() =>
  t(`cotizaciones.estados.${props.cotizacion.estado}` as ClaveMensaje),
)

const colorEstado = computed<
  'success' | 'warning' | 'error' | 'info' | 'neutral'
>(() => {
  if (props.cotizacion.estado === 'aceptada') return 'success'
  if (props.cotizacion.estado === 'enviada') return 'info'
  if (props.cotizacion.estado === 'rechazada') return 'error'
  if (props.cotizacion.estado === 'vencida') return 'neutral'
  return 'warning'
})

const terminal = computed(() =>
  ['aceptada', 'rechazada', 'vencida'].includes(props.cotizacion.estado),
)

const descuento = computed(() => Number(props.cotizacion.descuento))
</script>

<template>
  <BaseTarjeta
    :titulo="cotizacion.numero"
    :descripcion="`${cotizacion.cliente} · ${cotizacion.documento}`"
  >
    <template #acciones>
      <UBadge
        :color="colorEstado"
        variant="subtle"
        :label="estadoEtiqueta"
      />
    </template>

    <div class="space-y-4">
      <div>
        <p class="text-(length:--vt-texto-sm) font-(--vt-texto-peso-medio)">
          {{ cotizacion.paquete }}
          <span class="text-(length:--vt-texto-xs) text-(--vt-color-texto-suave)">
            · {{ cotizacion.codigoPaquete }}
          </span>
        </p>
        <p class="text-(length:--vt-texto-xs) text-(--vt-color-texto-suave)">
          {{ fecha(cotizacion.fechaSalida) }} →
          {{ fecha(cotizacion.fechaRetorno) }}
        </p>
      </div>

      <div class="grid grid-cols-2 gap-3">
        <div>
          <p
            class="text-xs uppercase tracking-wide text-(--vt-color-texto-suave)"
          >
            {{ t('cotizaciones.columnas.pasajeros') }}
          </p>
          <p class="text-(length:--vt-texto-sm)">
            {{ cotizacion.cantidadPasajeros }}
          </p>
        </div>
        <div>
          <p
            class="text-xs uppercase tracking-wide text-(--vt-color-texto-suave)"
          >
            {{ t('cotizaciones.columnas.validez') }}
          </p>
          <p class="text-(length:--vt-texto-sm)">
            {{ fecha(cotizacion.fechaValidez) }}
          </p>
        </div>
      </div>

      <div class="grid grid-cols-2 gap-3">
        <div class="min-w-0">
          <p
            class="text-xs uppercase tracking-wide text-(--vt-color-texto-suave)"
          >
            {{ t('cotizaciones.columnas.total') }}
          </p>
          <p class="text-(length:--vt-texto-lg) font-(--vt-texto-peso-fuerte) tabular-nums">
            {{ moneda(cotizacion.total) }}
          </p>
          <p
            v-if="descuento > 0"
            class="text-(length:--vt-texto-xs) text-(--vt-color-texto-suave)"
          >
            {{ t('cotizaciones.form.descuento') }}:
            {{ moneda(cotizacion.descuento) }}
          </p>
        </div>

        <div class="min-w-0 text-right">
          <p
            class="text-xs uppercase tracking-wide text-(--vt-color-texto-suave)"
          >
            {{ t('cotizaciones.tarjeta.precio') }}
          </p>
          <p class="text-(length:--vt-texto-sm) tabular-nums">
            {{ moneda(cotizacion.precioUnitario) }}
          </p>
        </div>
      </div>

      <div v-if="cotizacion.condiciones">
        <p
          class="text-xs uppercase tracking-wide text-(--vt-color-texto-suave)"
        >
          {{ t('cotizaciones.form.condiciones') }}
        </p>
        <p class="line-clamp-2 text-(length:--vt-texto-sm)">
          {{ cotizacion.condiciones }}
        </p>
      </div>
    </div>

    <template #pie>
      <div class="flex flex-wrap items-center justify-between gap-2">
        <p class="text-xs text-(--vt-color-texto-suave)">
          {{
            t('cotizaciones.tarjeta.creadaEl', {
              fecha: fecha(cotizacion.fechaCreacion),
            })
          }}
        </p>
        <div class="flex flex-wrap items-center justify-end gap-1.5">
          <UBadge
            v-if="cotizacion.idReservaOriginada"
            color="success"
            variant="subtle"
            icon="i-lucide-check"
            :label="t('cotizaciones.tarjeta.reservaCreada')"
          />
          <UButton
            v-else-if="cotizacion.estado === 'aceptada'"
            size="xs"
            variant="soft"
            color="primary"
            :label="t('cotizaciones.acciones.reservar')"
            :loading="originando"
            @click="emit('reservar', cotizacion)"
          />
          <UButton
            size="xs"
            variant="soft"
            color="neutral"
            :label="
              terminal
                ? t('cotizaciones.acciones.ver')
                : t('cotizaciones.acciones.editar')
            "
            @click="emit('abrir', cotizacion)"
          />
        </div>
      </div>
    </template>
  </BaseTarjeta>
</template>
