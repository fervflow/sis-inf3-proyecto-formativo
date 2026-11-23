<template>
  <div class="space-y-6">
    <BaseEncabezadoPagina
      :titulo="t('solicitudes.titulo')"
      :descripcion="t('solicitudes.introduccion')"
    >
      <template #acciones>
        <UButton
          color="primary"
          :label="t('solicitudes.crear')"
          @click="abrirAlta"
        />
      </template>
    </BaseEncabezadoPagina>

    <UAlert v-if="aviso" color="success" variant="soft" :title="aviso" />
    <UAlert v-if="error" color="error" variant="soft" :title="error" />

    <BaseTarjeta>
      <div class="mb-3 flex items-center justify-end gap-2">
        <USelect
          v-model="estadoFiltro"
          :items="estadosFiltro"
          class="w-48"
          :aria-label="t('solicitudes.filtro')"
        />
      </div>

      <div
        v-if="pendiente || reservas.length > 0"
        class="overflow-x-auto"
      >
        <BaseTablaDatos
          class="min-w-[70rem]"
          :columnas="columnas"
          :filas="reservas"
          :cargando="pendiente"
          :texto-vacio="t('solicitudes.vacia')"
        >
          <template #celda="{ columna, fila, valor }">
            <span v-if="columna.clave === 'codigo'">
              <span class="font-(--vt-texto-peso-medio)">{{ fila.codigo }}</span>
              <UBadge
                class="ml-2"
                :color="fila.origen === 'web' ? 'info' : 'neutral'"
                variant="subtle"
                :label="t(`solicitudes.origenes.${fila.origen}` as ClaveMensaje)"
              />
            </span>

            <span v-else-if="columna.clave === 'paquete'">
              {{ fila.paquete }}
              <span class="text-xs text-(--vt-color-texto-suave)">
                {{ fecha(fila.fechaSalida) }}
              </span>
            </span>

            <UBadge
              v-else-if="columna.clave === 'estado'"
              :color="colorDeEstado(fila.estado)"
              variant="subtle"
              :label="t(`solicitudes.estados.${fila.estado}` as ClaveMensaje)"
            />

            <span
              v-else-if="columna.clave === 'montoTotal'"
              class="tabular-nums"
            >
              {{ moneda(String(valor)) }}
            </span>

            <span v-else-if="columna.clave === 'vencimiento'">
              <span
                v-if="fila.fechaExpiracion && fila.estado === 'pendiente'"
                :class="[
                  'tabular-nums',
                  expiraPronto(fila.fechaExpiracion)
                    ? 'text-(--vt-color-error-600) font-(--vt-texto-peso-medio)'
                    : '',
                ]"
              >
                {{ fechaHora(fila.fechaExpiracion) }}
              </span>
              <span v-else class="text-(--vt-color-texto-suave)">—</span>
            </span>

            <span v-else-if="columna.clave === 'acciones'">
              <UButton
                v-if="fila.estado === 'pendiente'"
                size="xs"
                color="primary"
                variant="soft"
                :label="t('solicitudes.confirmar')"
                :loading="confirmando === fila.idReserva"
                @click="confirmar(fila.idReserva)"
              />
              <span v-else class="text-(--vt-color-texto-suave)">—</span>
            </span>

            <span v-else class="tabular-nums">{{ valor }}</span>
          </template>
        </BaseTablaDatos>
      </div>

      <BaseEstadoVacio
        v-else-if="!errorConsulta"
        :titulo="t('solicitudes.vacia')"
        :descripcion="t('solicitudes.vacioDescripcion')"
      >
        <template #accion>
          <UButton
            color="primary"
            :label="t('solicitudes.crear')"
            @click="abrirAlta"
          />
        </template>
      </BaseEstadoVacio>
    </BaseTarjeta>

    <UModal
      v-model:open="formularioAbierto"
      :title="t('solicitudes.crear')"
      :ui="{ content: 'max-w-2xl' }"
    >
      <template #body>
        <form id="form-reserva" class="space-y-4" @submit.prevent="guardar">
          <div class="grid gap-4 sm:grid-cols-2">
            <UFormField :label="t('solicitudes.form.cliente')" name="cliente">
              <USelect
                v-model="formulario.idCliente"
                :items="clientesDisponibles"
                :placeholder="t('solicitudes.sinClientes')"
                class="w-full"
                required
              />
            </UFormField>

            <UFormField :label="t('solicitudes.form.salida')" name="salida">
              <USelect
                v-model="formulario.idSalida"
                :items="salidasDisponibles"
                :placeholder="t('solicitudes.sinSalidas')"
                class="w-full"
                required
              />
            </UFormField>
          </div>

          <div
            v-if="salidaSeleccionada"
            class="rounded-(--vt-radio-md) px-3 py-2 text-(--vt-texto-sm) ring-1 ring-(--vt-color-borde)"
          >
            <p class="font-(--vt-texto-peso-medio)">
              {{ salidaSeleccionada.paquete }}
              <span class="text-(--vt-texto-xs) text-(--vt-color-texto-suave)">
                · {{ salidaSeleccionada.codigo_paquete }}
              </span>
            </p>
            <p class="text-(--vt-texto-xs) text-(--vt-color-texto-suave)">
              {{ fecha(salidaSeleccionada.fecha_salida) }} →
              {{ fecha(salidaSeleccionada.fecha_retorno) }} ·
              {{ salidaSeleccionada.cupo_disponible }}
              {{ t('solicitudes.disponibles') }} ·
              {{ moneda(salidaSeleccionada.precio) }}
            </p>
          </div>

          <UFormField
            :label="t('solicitudes.form.cantidad')"
            name="cantidad"
            :help="t('solicitudes.ayudaCantidad')"
          >
            <UInputNumber
              v-model="formulario.cantidadPasajeros"
              :min="1"
              :max="32767"
              :step="1"
              :increment="false"
              :decrement="false"
              class="w-full"
            />
          </UFormField>
        </form>
      </template>

      <template #footer>
        <div class="flex justify-end gap-2">
          <UButton
            color="neutral"
            variant="ghost"
            :label="t('comun.cancelar')"
            @click="formularioAbierto = false"
          />
          <UButton
            color="primary"
            type="submit"
            form="form-reserva"
            :label="t('comun.guardar')"
            :loading="guardando"
          />
        </div>
      </template>
    </UModal>
  </div>
</template>

<script setup lang="ts">
import type { ClaveMensaje } from '~/i18n'
import type {
  RespuestaClientes,
  RespuestaDisponibilidad,
  RespuestaReservas,
  ReservaResumen,
} from '#shared/types/api'
import type { ColumnaTabla } from '#shared/types/ui'

const { t } = useTexto()
const mensajeDeError = useMensajeError()
const { moneda, fecha, fechaHora } = useFormato()

const peticion = useRequestFetch()

const estadoFiltro = ref<'pendiente' | 'todas'>('pendiente')

// La consulta depende de `estadoFiltro`: al cambiar el filtro se vuelve a
// pedir la lista.
const {
  data,
  pending: pendiente,
  error: errorConsulta,
  refresh: recargar,
} = useAsyncData<RespuestaReservas>('solicitudes', () =>
  peticion<RespuestaReservas>('/api/reservas', {
    query: { estado: estadoFiltro.value },
  }),
)

const estadosFiltro = computed(() => [
  { label: t('solicitudes.filtroPendientes'), value: 'pendiente' },
  { label: t('solicitudes.filtroTodas'), value: 'todas' },
])

const reservas = computed<FilaSolicitud[]>(() =>
  (data.value?.reservas ?? []).map((reserva) => ({
    ...reserva,
    vencimiento: reserva.fechaExpiracion,
    acciones: reserva.idReserva,
  })),
)

/** Fila de la tabla con las columnas derivadas de la vista. */
type FilaSolicitud = ReservaResumen & {
  vencimiento: string | null
  acciones: number
}

// El error de la lista y el de las operaciones comparten el aviso superior.
const errorOperacion = ref<string | null>(null)
const error = computed<string | null>(
  () => errorOperacion.value ?? (errorConsulta.value ? mensajeDeError(errorConsulta.value) : null),
)

const columnas = computed<ColumnaTabla<FilaSolicitud>[]>(() => [
  { clave: 'codigo', etiqueta: t('solicitudes.columnas.codigo') },
  { clave: 'cliente', etiqueta: t('solicitudes.columnas.cliente') },
  { clave: 'documento', etiqueta: t('solicitudes.columnas.documento') },
  { clave: 'paquete', etiqueta: t('solicitudes.columnas.salida') },
  {
    clave: 'cantidadPasajeros',
    etiqueta: t('solicitudes.columnas.pasajeros'),
    alineacion: 'derecha',
  },
  {
    clave: 'montoTotal',
    etiqueta: t('solicitudes.columnas.monto'),
    alineacion: 'derecha',
  },
  { clave: 'estado', etiqueta: t('solicitudes.columnas.estado') },
  { clave: 'vencimiento', etiqueta: t('solicitudes.columnas.vencimiento') },
  { clave: 'acciones', etiqueta: t('solicitudes.columnas.acciones') },
])

function colorDeEstado(
  estado: ReservaResumen['estado'],
): 'warning' | 'success' | 'neutral' | 'error' {
  switch (estado) {
    case 'pendiente':
      return 'warning'
    case 'confirmada':
      return 'success'
    case 'vencida':
      return 'error'
    default:
      return 'neutral'
  }
}

/** Una pendiente que vence en menos de doce horas se avisa en rojo. */
function expiraPronto(fechaExpiracion: string): boolean {
  return Date.parse(fechaExpiracion) - Date.now() < 12 * 3_600_000
}

// --- Confirmación -------------------------------------------------------

const confirmando = ref<number | null>(null)
const aviso = ref<string | null>(null)

async function confirmar(idReserva: number) {
  confirmando.value = idReserva
  errorOperacion.value = null
  try {
    const reserva = await peticion<ReservaResumen>(
      `/api/reservas/${idReserva}/confirmar`,
      { method: 'POST' },
    )
    aviso.value = t('solicitudes.confirmada', { codigo: reserva.codigo })
  } catch (fallo) {
    aviso.value = null
    // La lista se recarga igual: la fila pudo vencerse en el servidor.
    errorOperacion.value = mensajeDeError(fallo)
  } finally {
    confirmando.value = null
    await recargar()
  }
}

// --- Alta desde la atención del personal --------------------------------

const formularioAbierto = ref(false)
const guardando = ref(false)

const formulario = reactive({
  idCliente: undefined as number | undefined,
  idSalida: undefined as number | undefined,
  cantidadPasajeros: 1,
})

const { data: clientes } = useAsyncData<RespuestaClientes>(
  'clientes-solicitud',
  () => peticion<RespuestaClientes>('/api/clientes'),
)

const { data: salidas } = useAsyncData<RespuestaDisponibilidad>(
  'salidas-solicitud',
  () => peticion<RespuestaDisponibilidad>('/api/disponibilidad'),
)

const clientesDisponibles = computed(() =>
  (clientes.value?.clientes ?? [])
    .filter((cliente) => cliente.estado === 'activo')
    .map((cliente) => ({
      label: `${cliente.nombres} ${cliente.apellidos} · ${cliente.numeroDocumento}`,
      value: cliente.idCliente,
    })),
)

const salidasDisponibles = computed(() =>
  (salidas.value?.salidas ?? [])
    .filter((salida) => salida.cupo_disponible > 0)
    .map((salida) => ({
      label: `${salida.paquete} · ${salida.fecha_salida}`,
      value: salida.id_salida,
    })),
)

const salidaSeleccionada = computed(() =>
  (salidas.value?.salidas ?? []).find(
    (salida) => salida.id_salida === formulario.idSalida,
  ),
)

function abrirAlta() {
  formulario.idCliente = undefined
  formulario.idSalida = undefined
  formulario.cantidadPasajeros = 1
  errorOperacion.value = null
  formularioAbierto.value = true
}

async function guardar() {
  if (!formulario.idCliente || !formulario.idSalida) return
  guardando.value = true
  errorOperacion.value = null
  try {
    const reserva = await peticion<ReservaResumen>('/api/reservas', {
      method: 'POST',
      body: {
        idCliente: formulario.idCliente,
        idSalida: formulario.idSalida,
        cantidadPasajeros: formulario.cantidadPasajeros,
      },
    })
    formularioAbierto.value = false
    aviso.value = t('solicitudes.creada', { codigo: reserva.codigo })
    estadoFiltro.value = 'pendiente'
  } catch (fallo) {
    errorOperacion.value = mensajeDeError(fallo)
  } finally {
    guardando.value = false
    await recargar()
  }
}
</script>
