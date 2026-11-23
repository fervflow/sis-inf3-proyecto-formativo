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

    <BaseTarjeta>
      <div
        v-if="pendiente || salidas.length > 0"
        class="overflow-x-auto"
      >
        <BaseTablaDatos
          class="min-w-[64rem]"
          :columnas="columnas"
          :filas="salidas"
          :cargando="pendiente"
          :texto-vacio="t('disponibilidad.vacia')"
        >
        <template #celda="{ columna, fila, valor }">
          <span v-if="columna.clave === 'paquete'">
            {{ fila.paquete }}
            <span class="text-xs text-(--vt-color-texto-suave)">
              {{ fila.codigo_paquete }}
            </span>
          </span>

          <span
            v-else-if="
              columna.clave === 'fecha_salida' ||
              columna.clave === 'fecha_retorno'
            "
          >
            {{ fecha(String(valor)) }}
          </span>

          <UBadge
            v-else-if="
              columna.clave === 'cupo_disponible' && fila.cupo_disponible <= 0
            "
            color="error"
            variant="subtle"
            :label="t('disponibilidad.agotada')"
          />

          <span
            v-else-if="
              columna.clave === 'pasajeros_pendientes' ||
              columna.clave === 'pasajeros_confirmados'
            "
            class="tabular-nums"
          >
            {{ valor ?? '—' }}
          </span>

          <span
            v-else-if="columna.clave === 'precio'"
            class="tabular-nums"
          >
            {{ moneda(String(valor)) }}
          </span>

          <span
            v-else-if="columna.clave === 'acciones'"
            class="flex justify-center"
          >
            <UButton
              v-if="fila.cupo_disponible > 0"
              size="xs"
              color="primary"
              variant="soft"
              :label="t('disponibilidad.solicitar')"
              @click="solicitar(fila)"
            />
          </span>

          <span v-else class="tabular-nums">{{ valor }}</span>
          </template>
        </BaseTablaDatos>
      </div>

      <BaseEstadoVacio
        v-else-if="!error"
        :titulo="t('disponibilidad.vacia')"
      />

      <p v-if="error" class="text-(--vt-texto-sm) text-(--vt-color-error-600)">
        {{ error }}
      </p>

      <p
        v-if="esPersonal && salidas.length > 0"
        class="mt-3 text-(--vt-texto-xs) text-(--vt-color-texto-suave)"
      >
        {{ t('disponibilidad.desglosePersonal') }}
      </p>
    </BaseTarjeta>

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
import type { ColumnaTabla } from '#shared/types/ui'

const { t } = useTexto()
const mensajeDeError = useMensajeError()
const { moneda, fecha, fechaHora } = useFormato()
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

/** Fila de la tabla de disponibilidad con la columna de acción. */
type FilaDisponibilidad = SalidaDisponible & { acciones: number }

const salidas = computed<FilaDisponibilidad[]>(() =>
  (data.value?.salidas ?? []).map((salida) => ({
    ...salida,
    acciones: salida.id_salida,
  })),
)
const error = computed<string | null>(() =>
  errorConsulta.value ? mensajeDeError(errorConsulta.value) : null,
)

// Las etiquetas se calculan de nuevo cuando cambia el idioma.
const columnas = computed<ColumnaTabla<FilaDisponibilidad>[]>(() => {
  const lista: ColumnaTabla<FilaDisponibilidad>[] = [
    { clave: 'paquete', etiqueta: t('disponibilidad.columnas.paquete') },
    { clave: 'fecha_salida', etiqueta: t('disponibilidad.columnas.salida') },
    { clave: 'fecha_retorno', etiqueta: t('disponibilidad.columnas.retorno') },
    {
      clave: 'cupo_maximo',
      etiqueta: t('disponibilidad.columnas.cupo'),
      alineacion: 'derecha',
    },
    {
      clave: 'pasajeros_ocupados',
      etiqueta: t('disponibilidad.columnas.ocupados'),
      alineacion: 'derecha',
    },
  ]

  if (esPersonal.value) {
    lista.push(
      {
        clave: 'pasajeros_pendientes',
        etiqueta: t('disponibilidad.columnas.pendientes'),
        alineacion: 'derecha',
      },
      {
        clave: 'pasajeros_confirmados',
        etiqueta: t('disponibilidad.columnas.confirmados'),
        alineacion: 'derecha',
      },
    )
  }

  lista.push(
    {
      clave: 'cupo_disponible',
      etiqueta: t('disponibilidad.columnas.disponibles'),
      alineacion: 'derecha',
    },
    {
      clave: 'precio',
      etiqueta: t('disponibilidad.columnas.precio'),
      alineacion: 'derecha',
    },
  )

  // Solo una salida con cupo admite la solicitud.
  lista.push({
    clave: 'acciones',
    etiqueta: t('disponibilidad.columnas.acciones'),
    alineacion: 'centro',
  })

  return lista
})

// --- Solicitud de reserva por el canal web -------------------------------

const solicitudAbierta = ref(false)
const salidaSolicitada = ref<FilaDisponibilidad | null>(null)
const formularioPublico = useTemplateRef<{
  reiniciar: () => void
}>('formulario-publico')

const avisoSolicitud = ref<string | null>(null)

function solicitar(salida: FilaDisponibilidad) {
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
