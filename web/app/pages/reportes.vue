<script setup lang="ts">
/**
 * Reporte de ocupación y reservas por fecha (HU-11).
 *
 * Parten de la misma vista que la disponibilidad, de modo que las cifras
 * coinciden: capacidad, pasajeros pendientes y confirmados, cupos libres
 * y reservas por estado, con las vencidas y canceladas informadas sin
 * ocupar cupo, y el conteo por canal (RN-REP-01 a RN-REP-04).
 */
import type { ClaveMensaje } from '~/i18n'
import type {
  RespuestaPaquetes,
  RespuestaReportes,
  ReporteResumen,
} from '#shared/types/api'
import type { ColumnaTabla } from '#shared/types/ui'

const { t } = useTexto()
const mensajeDeError = useMensajeError()
const { fecha } = useFormato()
const peticion = useRequestFetch()

const desde = ref('')
const hasta = ref('')
const idPaquete = ref<number | undefined>(undefined)

const {
  data,
  pending: pendiente,
  error: errorConsulta,
  refresh: recargar,
} = useAsyncData<RespuestaReportes>(
  'reportes',
  () =>
    peticion<RespuestaReportes>('/api/reportes', {
      query: {
        desde: desde.value || undefined,
        hasta: hasta.value || undefined,
        idPaquete: idPaquete.value || undefined,
      },
    }),
  { watch: [desde, hasta, idPaquete] },
)

const salidas = computed<ReporteResumen[]>(() => data.value?.salidas ?? [])
const error = computed<string | null>(() =>
  errorConsulta.value ? mensajeDeError(errorConsulta.value) : null,
)

// El selector de paquete se arma del propio reporte: un filtro más.
const paquetes = computed(() => {
  const vistos = new Map<number, string>()
  for (const fila of salidas.value) {
    if (!vistos.has(fila.idPaquete)) {
      vistos.set(fila.idPaquete, `${fila.paquete} (${fila.codigoPaquete})`)
    }
  }
  return [
    { label: t('reportes.todoPaquete'), value: undefined },
    ...[...vistos.entries()].map(([valor, etiqueta]) => ({
      label: etiqueta,
      value: valor,
    })),
  ]
})

type FilaReporte = ReporteResumen & { salida: string }

const filas = computed<FilaReporte[]>(() =>
  salidas.value.map((fila) => ({
    ...fila,
    salida: `${fila.paquete} · ${fecha(fila.fechaSalida)}`,
  })),
)

const columnas = computed<ColumnaTabla<FilaReporte>[]>(() => [
  { clave: 'salida', etiqueta: t('reportes.columnas.salida') },
  {
    clave: 'cupoMaximo',
    etiqueta: t('reportes.columnas.capacidad'),
    alineacion: 'derecha',
  },
  {
    clave: 'pasajerosPendientes',
    etiqueta: t('reportes.columnas.pendientes'),
    alineacion: 'derecha',
  },
  {
    clave: 'pasajerosConfirmados',
    etiqueta: t('reportes.columnas.confirmados'),
    alineacion: 'derecha',
  },
  {
    clave: 'cupoDisponible',
    etiqueta: t('reportes.columnas.libres'),
    alineacion: 'derecha',
  },
  {
    clave: 'reservasWeb',
    etiqueta: t('reportes.columnas.web'),
    alineacion: 'derecha',
  },
  {
    clave: 'reservasPersonal',
    etiqueta: t('reportes.columnas.personal'),
    alineacion: 'derecha',
  },
  {
    clave: 'reservasVencidas',
    etiqueta: t('reportes.columnas.vencidas'),
    alineacion: 'derecha',
  },
  {
    clave: 'reservasCanceladas',
    etiqueta: t('reportes.columnas.canceladas'),
    alineacion: 'derecha',
  },
])
</script>

<template>
  <div class="space-y-6">
    <BaseEncabezadoPagina
      :titulo="t('reportes.titulo')"
      :descripcion="t('reportes.introduccion')"
    />

    <UAlert v-if="error" color="error" variant="soft" :title="error" />

    <BaseTarjeta>
      <div class="mb-3 flex flex-wrap items-center justify-end gap-2">
        <UInput
          v-model="desde"
          type="date"
          size="sm"
          class="w-40"
          :aria-label="t('reportes.desde')"
        />
        <UInput
          v-model="hasta"
          type="date"
          size="sm"
          class="w-40"
          :aria-label="t('reportes.hasta')"
        />
        <USelect
          v-model="idPaquete"
          :items="paquetes"
          size="sm"
          class="w-64"
          :aria-label="t('reportes.paquete')"
        />
      </div>

      <div v-if="pendiente || filas.length > 0" class="overflow-x-auto">
        <BaseTablaDatos
          class="min-w-[72rem]"
          :columnas="columnas"
          :filas="filas"
          :cargando="pendiente"
          :texto-vacio="t('reportes.vacia')"
        >
          <template #celda="{ columna, fila, valor }">
            <span v-if="columna.clave === 'salida'">
              <span class="font-(--vt-texto-peso-medio)">{{ fila.paquete }}</span>
              <span class="text-xs text-(--vt-color-texto-suave)">
                · {{ fila.codigoPaquete }} · {{ fecha(fila.fechaSalida) }}
              </span>
            </span>
            <span v-else class="tabular-nums">{{ valor }}</span>
          </template>
        </BaseTablaDatos>
      </div>

      <BaseEstadoVacio v-else :titulo="t('reportes.vacia')" />
    </BaseTarjeta>
  </div>
</template>
