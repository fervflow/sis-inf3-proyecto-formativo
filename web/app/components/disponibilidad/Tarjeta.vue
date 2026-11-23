<script setup lang="ts">
/**
 * Tarjeta de una salida disponible.
 *
 * Espejo de la tarjeta de salidas del panel: resume el paquete, el
 * recorrido, las fechas, la ocupación y el precio. En lugar de editar, la
 * acción es solicitar una reserva; la vista maneja el formulario.
 */
import type { SalidaDisponible } from '#shared/types/api'
import type { ClaveMensaje } from '~/i18n'

const props = defineProps<{
  salida: SalidaDisponible
  /** Desglose de pendientes y confirmados, solo para el personal. */
  desglose?: string
}>()

const emit = defineEmits<{
  solicitar: [salida: SalidaDisponible]
}>()

const { t } = useTexto()
const { moneda, fecha } = useFormato()

const estadoEtiqueta = computed(() =>
  t(`salidas.estados.${props.salida.estado}` as ClaveMensaje),
)

const estadoColor = computed<'success' | 'warning' | 'neutral' | 'error'>(() => {
  if (props.salida.estado === 'confirmada') return 'success'
  if (props.salida.estado === 'programada') return 'warning'
  return 'neutral'
})

const recorridoMostrado = computed(
  () => props.salida.destino ?? t('salidas.tarjeta.sinDestino'),
)

const ocupacionPorcentaje = computed(() => {
  if (props.salida.cupo_maximo <= 0) return 0
  return Math.min(
    100,
    Math.round(
      (props.salida.pasajeros_ocupados / props.salida.cupo_maximo) * 100,
    ),
  )
})

/** Porcentaje del cupo que ya está vendido (confirmado). */
const porcentajeConfirmados = computed(() => {
  if (props.salida.cupo_maximo <= 0) return 0
  return Math.min(
    100,
    (props.salida.pasajeros_confirmados / props.salida.cupo_maximo) * 100,
  )
})

/**
 * Porcentaje del cupo retenido por solicitudes pendientes vigentes: se
 * muestra como un segundo segmento de la barra, en otro color, para que
 * se distinga la venta hecha de la que está en revisión.
 */
const porcentajePendientes = computed(() => {
  if (props.salida.cupo_maximo <= 0) return 0
  return Math.min(
    100 - porcentajeConfirmados.value,
    (props.salida.pasajeros_pendientes / props.salida.cupo_maximo) * 100,
  )
})

const agotada = computed(() => props.salida.cupo_disponible <= 0)

const precioDistinto = computed(
  () =>
    Number(props.salida.precio) !== Number(props.salida.precio_base) &&
    Number(props.salida.precio_base) > 0,
)
</script>

<template>
  <BaseTarjeta :titulo="salida.paquete" :descripcion="salida.codigo_paquete">
    <template #acciones>
      <UBadge
        :color="estadoColor"
        variant="subtle"
        :label="estadoEtiqueta"
      />
    </template>

    <div class="space-y-4">
      <div class="flex items-start gap-2">
        <UIcon
          name="i-lucide-map-pin"
          class="mt-0.5 size-4 shrink-0 text-(--vt-color-marca-600)"
        />
        <p class="text-(--vt-texto-sm)">{{ recorridoMostrado }}</p>
      </div>

      <div class="grid gap-3 sm:grid-cols-3">
        <div class="sm:col-span-2">
          <p
            class="text-xs uppercase tracking-wide text-(--vt-color-texto-suave)"
          >
            {{ t('salidas.tarjeta.fechas') }}
          </p>
          <p class="text-(--vt-texto-sm)">
            {{ fecha(salida.fecha_salida) }} →
            {{ fecha(salida.fecha_retorno) }}
          </p>
        </div>

        <div>
          <p
            class="text-xs uppercase tracking-wide text-(--vt-color-texto-suave)"
          >
            {{ t('salidas.tarjeta.duracion') }}
          </p>
          <p class="text-(--vt-texto-sm)">
            {{ t('salidas.tarjeta.dias', { dias: salida.duracion_dias }) }}
          </p>
        </div>
      </div>

      <div class="space-y-1">
        <div
          class="flex items-center justify-between gap-2 text-(--vt-texto-sm)"
        >
          <span>{{ t('salidas.tarjeta.cupo') }}</span>
          <span class="tabular-nums">
            {{
              t('salidas.tarjeta.ocupacion', {
                ocupados: salida.pasajeros_ocupados,
                maximo: salida.cupo_maximo,
              })
            }}
          </span>
        </div>

        <!--
          Barra de ocupación: la parte confirmada es sólida y la retenida
          por solicitudes pendientes se muestra en otro color sobre la
          misma barra.
        -->
        <div
          class="flex h-2 w-full overflow-hidden rounded-(--vt-radio-full) bg-(--vt-color-borde)"
          role="img"
          :aria-label="desglose || t('salidas.tarjeta.cupo')"
        >
          <div
            class="h-full bg-(--vt-color-marca-600)"
            :style="{ width: `${porcentajeConfirmados}%` }"
          />
          <div
            class="h-full bg-(--vt-color-advertencia-500)"
            :style="{ width: `${porcentajePendientes}%` }"
          />
        </div>

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
                  disponibles: salida.cupo_disponible,
                })
          }}
        </p>
        <p
          v-if="desglose"
          class="text-xs text-(--vt-color-texto-suave)"
        >
          {{ desglose }}
        </p>
      </div>

      <div class="flex items-end justify-between gap-3">
        <div>
          <p
            class="text-xs uppercase tracking-wide text-(--vt-color-texto-suave)"
          >
            {{ t('salidas.tarjeta.precio') }}
          </p>
          <p class="text-(--vt-texto-lg) font-(--vt-texto-peso-fuerte) tabular-nums">
            {{ moneda(salida.precio) }}
          </p>
          <p
            v-if="precioDistinto"
            class="text-xs text-(--vt-color-texto-suave)"
          >
            {{
              t('salidas.tarjeta.precioBase', {
                precio: moneda(salida.precio_base),
              })
            }}
          </p>
        </div>

        <div v-if="salida.punto_encuentro" class="max-w-40 text-right">
          <p
            class="text-xs uppercase tracking-wide text-(--vt-color-texto-suave)"
          >
            {{ t('salidas.tarjeta.puntoEncuentro') }}
          </p>
          <p class="text-(--vt-texto-sm)">{{ salida.punto_encuentro }}</p>
        </div>
      </div>
    </div>

    <template #pie>
      <div class="flex items-center justify-end gap-2">
        <UButton
          v-if="!agotada"
          size="xs"
          color="primary"
          variant="soft"
          :label="t('disponibilidad.solicitar')"
          @click="emit('solicitar', salida)"
        />
        <UBadge
          v-else
          color="error"
          variant="subtle"
          :label="t('disponibilidad.agotada')"
        />
      </div>
    </template>
  </BaseTarjeta>
</template>
