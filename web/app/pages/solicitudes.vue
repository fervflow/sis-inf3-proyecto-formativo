<template>
  <div class="space-y-6">
    <BaseEncabezadoPagina
      :titulo="t('solicitudes.titulo')"
      :descripcion="t('solicitudes.introduccion')"
    >
      <template #acciones>
        <UButton
          color="neutral"
          variant="soft"
          :label="t('solicitudes.barrido')"
          :loading="barrido"
          @click="ejecutarBarrido"
        />
        <UButton
          color="primary"
          :label="t('solicitudes.crear')"
          @click="abrirAlta"
        />
      </template>
    </BaseEncabezadoPagina>

    <UAlert v-if="error" color="error" variant="soft" :title="error" />

    <BaseTarjeta>
      <div class="mb-3 flex flex-wrap items-center justify-end gap-2">
        <UInput
          v-model="filtroDesde"
          type="date"
          size="sm"
          class="w-40"
          :aria-label="t('solicitudes.filtroDesde')"
        />
        <UInput
          v-model="filtroHasta"
          type="date"
          size="sm"
          class="w-40"
          :aria-label="t('solicitudes.filtroHasta')"
        />
        <USelect
          v-model="canalFiltro"
          :items="canalesFiltro"
          class="w-36"
          :aria-label="t('solicitudes.filtroCanal')"
        />
        <USelect
          v-model="estadoFiltro"
          :items="estadosFiltro"
          class="w-36"
          :aria-label="t('solicitudes.filtro')"
        />
      </div>

      <div
        v-if="pendiente || reservas.length > 0"
        class="overflow-x-auto"
      >
        <BaseTablaDatos
          class="min-w-[80rem]"
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
              <UBadge
                v-if="manifiestoPendiente(fila)"
                class="ml-2"
                color="warning"
                variant="subtle"
                icon="i-lucide-users"
                :label="t('solicitudes.manifiestoPendiente')"
              />
              <UBadge
                v-if="fila.fechaSolicitudCancelacion && fila.estado !== 'cancelada'"
                class="ml-2"
                color="error"
                variant="subtle"
                icon="i-lucide-undo-2"
                :label="t('solicitudes.cancelacionSolicitada')"
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

            <span v-else-if="columna.clave === 'anticipo'">
              <UBadge
                v-if="fila.anticipo"
                :color="fila.anticipo === 'validado' ? 'success' : 'warning'"
                variant="subtle"
                :label="t(`pagos.estados.${fila.anticipo}` as ClaveMensaje)"
              />
              <span v-else class="text-(--vt-color-texto-suave)">
                {{ t('solicitudes.sinAnticipo') }}
              </span>
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

            <span v-else-if="columna.clave === 'acciones'" class="flex flex-wrap justify-end gap-1.5">
              <UButton
                v-if="fila.estado === 'pendiente'"
                size="xs"
                color="primary"
                variant="soft"
                :label="t('solicitudes.confirmar')"
                :loading="confirmando === fila.idReserva"
                @click="confirmar(fila.idReserva)"
              />
              <UButton
                v-if="['pendiente', 'confirmada'].includes(fila.estado)"
                size="xs"
                color="neutral"
                variant="soft"
                :label="t('pasajeros.titulo')"
                @click="abrirManifiesto(fila)"
              />
              <UButton
                v-if="['pendiente', 'confirmada'].includes(fila.estado)"
                size="xs"
                color="neutral"
                variant="soft"
                :label="t('historial.editar')"
                @click="abrirModificacion(fila)"
              />
              <UButton
                v-if="fila.fechaSolicitudCancelacion && fila.estado !== 'cancelada'"
                size="xs"
                color="error"
                variant="soft"
                :label="t('solicitudes.ejecutarCancelacion')"
                @click="abrirCancelacion(fila)"
              />
              <UButton
                size="xs"
                color="neutral"
                variant="ghost"
                :label="t('historial.titulo')"
                @click="abrirHistorial(fila)"
              />
              <UButton
                size="xs"
                color="neutral"
                variant="soft"
                :label="t('solicitudes.pagos.abrir')"
                @click="abrirPagos(fila)"
              />
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
                · {{ salidaSeleccionada.codigo_salida }}
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

    <!--
      Manifiesto, historial, modificación y cancelación de una reserva
      (HU-07, HU-12, HU-13).
    -->
    <UModal
      v-model:open="manifiestoAbierto"
      :title="t('pasajeros.titulo')"
      :ui="{ content: 'max-w-3xl' }"
    >
      <template #body>
        <PasajerosManifiesto
          v-if="consultando"
          :reserva="consultando"
          @cambio="recargar()"
          @cancelar="manifiestoAbierto = false"
        />
      </template>
    </UModal>

    <UModal
      v-model:open="historialAbierto"
      :title="t('historial.titulo')"
      :ui="{ content: 'max-w-2xl' }"
    >
      <template #body>
        <SolicitudesHistorial v-if="consultando" :id-reserva="consultando.idReserva" />
      </template>
    </UModal>

    <UModal
      v-model:open="modificacionAbierta"
      :title="t('historial.editar')"
      :ui="{ content: 'max-w-2xl' }"
    >
      <template #body>
        <SolicitudesModificar
          v-if="consultando"
          :reserva="consultando"
          @guardada="modificada"
          @cancelar="modificacionAbierta = false"
        />
      </template>
    </UModal>

    <UModal
      v-model:open="cancelacionAbierta"
      :title="t('solicitudes.ejecutarCancelacion')"
      :ui="{ content: 'max-w-lg' }"
    >
      <template #body>
        <form id="form-cancelacion" class="space-y-4" @submit.prevent="ejecutarCancelacion">
          <UAlert
            color="warning"
            variant="subtle"
            icon="i-lucide-undo-2"
            :title="t('solicitudes.cancelacionAviso')"
            :description="t('solicitudes.cancelacionLibera')"
          />
          <UFormField :label="t('solicitudes.motivo')" name="motivo">
            <UTextarea
              v-model="motivoCancelacion"
              :rows="3"
              class="w-full"
              required
              minlength="3"
              maxlength="200"
            />
          </UFormField>
          <div class="flex justify-end gap-2">
            <UButton
              color="neutral"
              variant="ghost"
              :label="t('comun.cancelar')"
              @click="cancelacionAbierta = false"
            />
            <UButton
              color="error"
              type="submit"
              form="form-cancelacion"
              :label="t('solicitudes.cancelarDefinitivo')"
              :loading="cancelando"
            />
          </div>
        </form>
      </template>
    </UModal>

    <!--
      Pagos de una reserva (HU-14): resumen del saldo, historial con
      validar y anular, y el registro de un pago de oficina dentro del
      mismo panel. La confirmación exige el anticipo validado
      (RN-RES-18).
    -->
    <UModal
      v-model:open="pagosAbierto"
      :title="t('pagos.titulo')"
      :ui="{ content: 'max-w-3xl' }"
    >
      <template #body>
        <PagosResumenPagos
          v-if="consultando"
          :id-reserva="consultando.idReserva"
          :reserva="consultando"
          editable
          @cambio="recargar()"
        />
      </template>
    </UModal>
  </div>
</template>

<script setup lang="ts">
import type { ClaveMensaje } from '~/i18n'
import type {
  RespuestaBarrido,
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
const canalFiltro = ref<'todo' | 'personal' | 'web'>('todo')
const filtroDesde = ref('')
const filtroHasta = ref('')

// La consulta depende de los filtros: al cambiar uno se vuelve a pedir
// la lista (HU-07: filtros por fecha, estado y canal).
const {
  data,
  pending: pendiente,
  error: errorConsulta,
  refresh: recargar,
} = useAsyncData<RespuestaReservas>(
  'solicitudes',
  () =>
    peticion<RespuestaReservas>('/api/reservas', {
      query: {
        estado: estadoFiltro.value,
        canal: canalFiltro.value,
        desde: filtroDesde.value || undefined,
        hasta: filtroHasta.value || undefined,
      },
    }),
  { watch: [estadoFiltro, canalFiltro, filtroDesde, filtroHasta] },
)

const estadosFiltro = computed(() => [
  { label: t('solicitudes.filtroPendientes'), value: 'pendiente' },
  { label: t('solicitudes.filtroTodas'), value: 'todas' },
])

const canalesFiltro = computed(() => [
  { label: t('solicitudes.filtroCanalTodo'), value: 'todo' },
  { label: t('solicitudes.filtroCanalPersonal'), value: 'personal' },
  { label: t('solicitudes.filtroCanalWeb'), value: 'web' },
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

// El error de la lista queda en el aviso superior; los resultados de las
// operaciones se avisan con avisos flotantes.
const avisos = useAvisos()
const error = computed<string | null>(
  () => (errorConsulta.value ? mensajeDeError(errorConsulta.value) : null),
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
  { clave: 'anticipo', etiqueta: t('solicitudes.columnas.anticipo') },
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

/** Una pendiente que vence en menos de ocho horas se avisa en rojo. */
function expiraPronto(fechaExpiracion: string): boolean {
  return Date.parse(fechaExpiracion) - Date.now() < 8 * 3_600_000
}

// --- Confirmación -------------------------------------------------------

const confirmando = ref<number | null>(null)

/**
 * Confirmación de una solicitud (HU-17).
 *
 * La base la rechaza sin el anticipo validado (RN-RES-18) o con el
 * manifiesto incompleto (RN-RES-19): el aviso del error dice qué falta
 * para que la persona sepa a dónde ir, y el badge de la fila lo muestra
 * de antemano.
 */
async function confirmar(idReserva: number) {
  confirmando.value = idReserva
  try {
    const reserva = await peticion<ReservaResumen>(
      `/api/reservas/${idReserva}/confirmar`,
      { method: 'POST' },
    )
    avisos.exito('solicitudes.confirmada', { codigo: reserva.codigo })
  } catch (fallo) {
    // La lista se recarga igual: la fila pudo vencerse en el servidor.
    avisos.fallo(fallo)
  } finally {
    confirmando.value = null
    await recargar()
  }
}

/** El manifiesto falta o está incompleto (RN-RES-19): se avisa en la fila. */
function manifiestoPendiente(reserva: ReservaResumen): boolean {
  return (
    ['pendiente', 'confirmada'].includes(reserva.estado) &&
    reserva.pasajerosRegistrados < reserva.cantidadPasajeros
  )
}

// --- Manifiesto, historial, modificación y cancelación ------------------

const consultando = ref<ReservaResumen | null>(null)
const manifiestoAbierto = ref(false)
const historialAbierto = ref(false)
const modificacionAbierta = ref(false)
const cancelacionAbierta = ref(false)
const cancelando = ref(false)
const motivoCancelacion = ref('')

function abrirManifiesto(reserva: ReservaResumen) {
  consultando.value = reserva
  manifiestoAbierto.value = true
}

function abrirHistorial(reserva: ReservaResumen) {
  consultando.value = reserva
  historialAbierto.value = true
}

function abrirModificacion(reserva: ReservaResumen) {
  consultando.value = reserva
  modificacionAbierta.value = true
}

function abrirCancelacion(reserva: ReservaResumen) {
  consultando.value = reserva
  motivoCancelacion.value = ''
  cancelacionAbierta.value = true
}

async function ejecutarCancelacion() {
  if (!consultando.value) return
  cancelando.value = true
  try {
    const reserva = await peticion<ReservaResumen>(
      `/api/reservas/${consultando.value.idReserva}/ejecutar-cancelacion`,
      {
        method: 'POST',
        body: { motivo: motivoCancelacion.value.trim() },
      },
    )
    cancelacionAbierta.value = false
    avisos.exito('solicitudes.cancelada', { codigo: reserva.codigo })
  } catch (fallo) {
    avisos.fallo(fallo)
  } finally {
    cancelando.value = false
    await recargar()
  }
}

async function modificada(reserva: ReservaResumen) {
  modificacionAbierta.value = false
  avisos.exito('historial.modificada', {
    codigo: reserva.codigo,
    salida: reserva.paquete,
  })
  await recargar()
}

// --- Pagos de una reserva ----------------------------------------------

const pagosAbierto = ref(false)

function abrirPagos(reserva: ReservaResumen) {
  consultando.value = reserva
  pagosAbierto.value = true
}

// --- Barrido manual de vencidas (HU-17, T-HU-17.4) -----------------------

const barrido = ref(false)

async function ejecutarBarrido() {
  barrido.value = true
  try {
    const respuesta = await peticion<RespuestaBarrido>('/api/reservas/vencer', {
      method: 'POST',
    })
    avisos.exito(
      respuesta.vencidas > 0 ? 'solicitudes.barridoOk' : 'solicitudes.barridoNinguna',
      { cantidad: respuesta.vencidas },
    )
  } catch (fallo) {
    avisos.fallo(fallo)
  } finally {
    barrido.value = false
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
  formularioAbierto.value = true
}

async function guardar() {
  if (!formulario.idCliente || !formulario.idSalida) return
  guardando.value = true
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
    avisos.exito('solicitudes.creada', { codigo: reserva.codigo })
    estadoFiltro.value = 'pendiente'
  } catch (fallo) {
    avisos.fallo(fallo)
  } finally {
    guardando.value = false
    await recargar()
  }
}
</script>
