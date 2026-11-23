<template>
  <div class="space-y-8">
    <BaseEncabezadoPagina
      :titulo="t('disponibilidad.titulo')"
      :descripcion="t('disponibilidad.introduccion')"
    />

    <UAlert
      v-if="avisoSolicitud"
      color="success"
      variant="soft"
      :title="avisoSolicitud"
    />

    <div
      v-if="pendiente"
      class="grid gap-4 md:grid-cols-2 xl:grid-cols-3"
    >
      <USkeleton v-for="n in 3" :key="n" class="h-64 w-full" />
    </div>

    <BaseEstadoVacio
      v-else-if="salidas.length === 0"
      :titulo="t('disponibilidad.vacia')"
    />

    <div v-else class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
      <DisponibilidadTarjeta
        v-for="salida in salidas"
        :key="salida.id_salida"
        :salida="salida"
        :desglose="desgloseDe(salida)"
        @solicitar="solicitar"
      />
    </div>

    <p v-if="error" class="text-(--vt-texto-sm) text-(--vt-color-error-600)">
      {{ error }}
    </p>

    <UModal
      v-model:open="solicitudAbierta"
      :title="t('solicitudes.publico.titulo')"
      :ui="{ content: 'max-w-2xl' }"
    >
      <template #body>
        <SolicitudesFormularioPublico
          v-if="salidaSolicitada"
          ref="formulario-publico"
          :salida="salidaSolicitada"
          @registrada="registrada"
          @cancelar="solicitudAbierta = false"
        />
      </template>
    </UModal>
  </div>
</template>

<script setup lang="ts">
import type {
  RespuestaCuenta,
  RespuestaDisponibilidad,
  ReservaResumen,
  SalidaDisponible,
} from '#shared/types/api'

const { t } = useTexto()
const mensajeDeError = useMensajeError()
const { fecha, fechaHora } = useFormato()
const peticion = useRequestFetch()

const {
  data,
  pending: pendiente,
  error: errorConsulta,
  refresh: recargar,
} = await useAsyncData<RespuestaDisponibilidad>('disponibilidad', () =>
  peticion<RespuestaDisponibilidad>('/api/disponibilidad'),
)

const { data: cuenta } = useNuxtData<RespuestaCuenta>('cuenta')

const esPersonal = computed(
  () =>
    cuenta.value?.usuario?.rol === 'ADMIN' ||
    cuenta.value?.usuario?.rol === 'PERSONAL',
)

const salidas = computed<SalidaDisponible[]>(() => data.value?.salidas ?? [])
const error = computed<string | null>(() =>
  errorConsulta.value ? mensajeDeError(errorConsulta.value) : null,
)

/** Desglose de pendientes y confirmados, solo para el personal. */
function desgloseDe(salida: SalidaDisponible): string {
  if (!esPersonal.value) return ''
  return t('disponibilidad.desgloseLinea', {
    pendientes: salida.pasajeros_pendientes ?? 0,
    confirmados: salida.pasajeros_confirmados ?? 0,
  })
}

// --- Solicitud de reserva por el canal web -------------------------------

const solicitudAbierta = ref(false)
const salidaSolicitada = ref<SalidaDisponible | null>(null)
const formularioPublico = useTemplateRef<{
  reiniciar: () => void
}>('formulario-publico')

const avisoSolicitud = ref<string | null>(null)

function solicitar(salida: SalidaDisponible) {
  avisoSolicitud.value = null
  salidaSolicitada.value = salida
  formularioPublico.value?.reiniciar()
  solicitudAbierta.value = true
}

/** La solicitud quedó registrada: se muestra su código y su vencimiento. */
function registrada(reserva: ReservaResumen) {
  solicitudAbierta.value = false
  avisoSolicitud.value = t('solicitudes.registrada', {
    codigo: reserva.codigo,
    vencimiento: reserva.fechaExpiracion
      ? fechaHora(reserva.fechaExpiracion)
      : '—',
  })
  salidaSolicitada.value = null
  recargar()
}
</script>
