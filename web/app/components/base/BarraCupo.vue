<script setup lang="ts">
/**
 * Barra de ocupación de una salida, en dos segmentos.
 *
 * La parte confirmada es sólida y la retenida por solicitudes pendientes
 * vigentes se muestra en otro color sobre la misma barra, para distinguir
 * la venta hecha de la que está en revisión. Los cupos no se almacenan:
 * quien la usa entrega los totales que ya calculó la base.
 */
const props = defineProps<{
  /** Capacidad máxima de la salida. */
  maximo: number
  /** Pasajeros de reservas confirmadas. */
  confirmados: number
  /** Pasajeros de solicitudes pendientes vigentes. */
  pendientes: number
  /** Descripción de la barra para lectores de pantalla. */
  etiqueta?: string
}>()

/** Porcentaje del cupo que ya está vendido (confirmado). */
const porcentajeConfirmados = computed(() => {
  if (props.maximo <= 0) return 0
  return Math.min(100, (props.confirmados / props.maximo) * 100)
})

/**
 * Porcentaje del cupo retenido por solicitudes pendientes vigentes; no
 * pasa del espacio que deja libre la parte confirmada.
 */
const porcentajePendientes = computed(() => {
  if (props.maximo <= 0) return 0
  return Math.min(
    100 - porcentajeConfirmados.value,
    (props.pendientes / props.maximo) * 100,
  )
})
</script>

<template>
  <div
    class="flex h-2 w-full overflow-hidden rounded-(--vt-radio-full) bg-(--vt-color-borde)"
    role="img"
    :aria-label="etiqueta"
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
</template>
