<script setup lang="ts">
/**
 * Tarjeta de una salida programada.
 *
 * Resume el paquete, el recorrido, las fechas, la ocupación y el precio
 * para que una salida se entienda de un vistazo. La edición se delega a la
 * vista; la tarjeta no llama a la API.
 */
import type { SalidaAdmin } from '#shared/types/api'
import type { ClaveMensaje } from '~/i18n'

const props = defineProps<{
  salida: SalidaAdmin
  /** Recorrido resumido del paquete, si la vista lo conoce. */
  recorrido?: string
}>()

const emit = defineEmits<{
  editar: [salida: SalidaAdmin]
  /** La persona quiere ver la ficha completa de la salida (HU-18). */
  verDetalle: [salida: SalidaAdmin]
}>()

const { t } = useTexto()
const { moneda, fecha } = useFormato()

const estadoEtiqueta = computed(() =>
  t(`salidas.estados.${props.salida.estado}` as ClaveMensaje),
)

const estadoColor = computed<'success' | 'warning' | 'neutral' | 'error'>(() => {
  if (props.salida.estado === 'confirmada') return 'success'
  if (props.salida.estado === 'programada') return 'warning'
  if (props.salida.estado === 'cancelada') return 'error'
  return 'neutral'
})

const recorridoMostrado = computed(
  () =>
    props.recorrido ||
    props.salida.destino ||
    t('salidas.tarjeta.sinDestino'),
)

const agotada = computed(() => props.salida.cupoDisponible <= 0)

const precioDistinto = computed(
  () => Number(props.salida.precio) !== Number(props.salida.precioBase),
)

/** Desglose de confirmados y pendientes, igual que en la vista pública. */
const desglose = computed(() =>
  t('disponibilidad.desgloseLinea', {
    confirmados: props.salida.pasajerosConfirmados,
    pendientes: props.salida.pasajerosPendientes,
  }),
)
</script>

<template>
  <BaseTarjeta :titulo="salida.paquete" :descripcion="salida.codigoSalida">
    <template #acciones>
      <div class="flex flex-wrap items-center justify-end gap-2">
        <UBadge
          v-if="salida.estadoPaquete !== 'activo'"
          color="warning"
          variant="subtle"
          :label="t('salidas.tarjeta.paqueteInactivo')"
        />
        <UBadge
          :color="estadoColor"
          variant="subtle"
          :label="estadoEtiqueta"
        />
      </div>
    </template>

    <div class="space-y-4">
      <div class="flex items-start gap-2">
        <UIcon
          name="i-lucide-map-pin"
          class="mt-0.5 size-4 shrink-0 text-(--vt-color-marca-600)"
        />
        <p class="text-(length:--vt-texto-sm)">{{ recorridoMostrado }}</p>
      </div>

      <div class="grid gap-3 sm:grid-cols-3">
        <div class="sm:col-span-2">
          <p
            class="text-xs uppercase tracking-wide text-(--vt-color-texto-suave)"
          >
            {{ t('salidas.tarjeta.fechas') }}
          </p>
          <p class="text-(length:--vt-texto-sm)">
            {{ fecha(salida.fechaSalida) }} →
            {{ fecha(salida.fechaRetorno) }}
          </p>
        </div>

        <div>
          <p
            class="text-xs uppercase tracking-wide text-(--vt-color-texto-suave)"
          >
            {{ t('salidas.tarjeta.duracion') }}
          </p>
          <p class="text-(length:--vt-texto-sm)">
            {{ t('salidas.tarjeta.dias', { dias: salida.duracionDias }) }}
          </p>
        </div>
      </div>

      <div class="space-y-1">
        <div
          class="flex items-center justify-between gap-2 text-(length:--vt-texto-sm)"
        >
          <span>{{ t('salidas.tarjeta.cupo') }}</span>
          <span class="tabular-nums">
            {{
              t('salidas.tarjeta.ocupacion', {
                ocupados: salida.pasajerosOcupados,
                maximo: salida.cupoMaximo,
              })
            }}
          </span>
        </div>
        <!--
          Barra de ocupación en dos segmentos: la venta hecha y las
          solicitudes en revisión.
        -->
        <BaseBarraCupo
          :maximo="salida.cupoMaximo"
          :confirmados="salida.pasajerosConfirmados"
          :pendientes="salida.pasajerosPendientes"
          :etiqueta="desglose"
        />
        <p class="text-xs text-(--vt-color-texto-suave)">
          {{ desglose }}
        </p>
        <p
          class="text-xs"
          :class="
            agotada
              ? 'text-(--vt-color-error-600)'
              : 'text-(--vt-color-texto-suave)'
          "
        >
          {{
            agotada
              ? t('salidas.tarjeta.agotada')
              : t('salidas.tarjeta.disponibles', {
                  disponibles: salida.cupoDisponible,
                })
          }}
        </p>
      </div>

      <div class="flex items-end justify-between gap-3">
        <div>
          <p
            class="text-xs uppercase tracking-wide text-(--vt-color-texto-suave)"
          >
            {{ t('salidas.tarjeta.precio') }}
          </p>
          <p class="text-(length:--vt-texto-lg) font-(--vt-texto-peso-fuerte) tabular-nums">
            {{ moneda(salida.precio) }}
          </p>
          <p
            v-if="precioDistinto"
            class="text-xs text-(--vt-color-texto-suave)"
          >
            {{
              t('salidas.tarjeta.precioBase', {
                precio: moneda(salida.precioBase),
              })
            }}
          </p>
        </div>

        <div v-if="salida.puntoEncuentro" class="max-w-40 text-right">
          <p
            class="text-xs uppercase tracking-wide text-(--vt-color-texto-suave)"
          >
            {{ t('salidas.tarjeta.puntoEncuentro') }}
          </p>
          <p class="text-(length:--vt-texto-sm)">{{ salida.puntoEncuentro }}</p>
        </div>
      </div>

      <div v-if="salida.observaciones">
        <p
          class="text-xs uppercase tracking-wide text-(--vt-color-texto-suave)"
        >
          {{ t('salidas.tarjeta.observaciones') }}
        </p>
        <p class="line-clamp-2 text-(length:--vt-texto-sm)">
          {{ salida.observaciones }}
        </p>
      </div>
    </div>

    <template #pie>
      <div class="flex flex-wrap items-center justify-between gap-2">
        <p class="text-xs text-(--vt-color-texto-suave)">
          {{
            t('salidas.tarjeta.actualizada', {
              fecha: fecha(salida.fechaActualizacion),
            })
          }}
        </p>
        <div class="flex items-center gap-2">
          <UButton
            size="xs"
            variant="soft"
            color="neutral"
            icon="i-lucide-eye"
            :label="t('salidas.ficha.ver')"
            @click="emit('verDetalle', salida)"
          />
          <UButton
            size="xs"
            variant="soft"
            color="primary"
            :label="t('salidas.acciones.editar')"
            @click="emit('editar', salida)"
          />
        </div>
      </div>
    </template>
  </BaseTarjeta>
</template>
