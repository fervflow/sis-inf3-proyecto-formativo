<script setup lang="ts">
/**
 * Historial de una reserva (HU-07, T-HU-07.3).
 *
 * Cada cambio de estado y de datos, con usuario, fecha y observación; la
 * modificación de salida, cantidad y monto queda con los valores anterior
 * y nuevo (RN-RES-20). Solo consulta.
 */
import type { RespuestaHistorial } from '#shared/types/api'

const props = defineProps<{
  /** La reserva cuyo historial se consulta. */
  idReserva: number
}>()

const { t } = useTexto()
const mensajeDeError = useMensajeError()
const { fechaHora } = useFormato()

const cargando = ref(true)
const error = ref<string | null>(null)
const historial = ref<RespuestaHistorial | null>(null)

async function cargar() {
  cargando.value = true
  try {
    historial.value = await $fetch<RespuestaHistorial>(
      `/api/reservas/${props.idReserva}/historial`,
    )
  } catch (fallo) {
    error.value = mensajeDeError(fallo)
  } finally {
    cargando.value = false
  }
}

await cargar()
</script>

<template>
  <div class="space-y-3">
    <p
      v-if="!cargando && (historial?.historial ?? []).length === 0 && !error"
      class="text-(length:--vt-texto-sm) text-(--vt-color-texto-suave)"
    >
      {{ t('historial.vacio') }}
    </p>

    <ol v-else class="space-y-2">
      <li
        v-for="entrada in historial?.historial ?? []"
        :key="entrada.idHistorial"
        class="rounded-(--vt-radio-md) px-3 py-2 ring-1 ring-(--vt-color-borde)"
      >
        <p class="text-(length:--vt-texto-sm)">
          <span class="font-(--vt-texto-peso-medio)">
            {{ t('historial.deA', { anterior: entrada.estadoAnterior ?? '—', nuevo: entrada.estadoNuevo }) }}
          </span>
          <span class="text-(length:--vt-texto-xs) text-(--vt-color-texto-suave)">
            · {{ fechaHora(entrada.fechaCambio) }}
            <template v-if="entrada.usuario">· {{ entrada.usuario }}</template>
          </span>
        </p>
        <p v-if="entrada.observacion" class="text-(length:--vt-texto-xs) text-(--vt-color-texto-suave)">
          {{ entrada.observacion }}
        </p>
      </li>
    </ol>

    <UAlert v-if="error" color="error" variant="soft" :title="error" />
  </div>
</template>
