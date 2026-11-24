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
          class="min-w-[78rem]"
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

            <span v-else-if="columna.clave === 'acciones'">
              <div class="flex justify-end gap-1.5">
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
                  size="xs"
                  color="neutral"
                  variant="soft"
                  :label="t('solicitudes.pagos.abrir')"
                  @click="abrirPagos(fila)"
                />
              </div>
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

    <!--
      Pagos de una reserva (HU-14): resumen del saldo, historial con
      validar y anular, y el registro de un pago de oficina. La
      confirmación exige el anticipo validado (RN-RES-18).
    -->
    <UModal
      v-model:open="pagosAbierto"
      :title="t('pagos.titulo')"
      :ui="{ content: 'max-w-3xl' }"
    >
      <template #body>
        <div v-if="consultando" class="space-y-5">
          <PagosResumenPagos
            ref="panel-pagos"
            :id-reserva="consultando.idReserva"
            editable
            @cambio="recargar()"
          />

          <div
            v-if="['pendiente', 'confirmada'].includes(consultando.estado)"
            class="rounded-(--vt-radio-md) px-3 py-3 ring-1 ring-(--vt-color-borde)"
          >
            <form id="form-pago-oficina" class="space-y-3" @submit.prevent="registrarPago">
              <p class="font-(--vt-texto-peso-medio) text-(--vt-texto-sm)">
                {{ t('pagos.registrarTitulo') }}
              </p>

              <div class="grid gap-3 sm:grid-cols-2">
                <UFormField :label="t('pagos.form.tipo')" name="tipo">
                  <USelect v-model="pagoFormulario.tipo" :items="tiposPago" class="w-full" />
                </UFormField>
                <UFormField :label="t('pagos.form.metodo')" name="metodo">
                  <USelect v-model="pagoFormulario.metodo" :items="metodosPago" class="w-full" />
                </UFormField>
              </div>

              <div class="grid gap-3 sm:grid-cols-2">
                <UFormField
                  :label="t('pagos.form.monto')"
                  name="monto"
                  :help="
                    pagoFormulario.tipo === 'saldo'
                      ? t('pagos.ayudaSaldo')
                      : t('pagos.ayudaMinimo', { porcentaje: ANTICIPO_MINIMO_PORCENTAJE })
                  "
                >
                  <UInputNumber
                    v-model="pagoFormulario.monto"
                    :min="1"
                    :step="10"
                    :increment="false"
                    :decrement="false"
                    class="w-full"
                  />
                </UFormField>
                <UFormField :label="t('pagos.form.referencia')" name="referencia">
                  <UInput v-model="pagoFormulario.referencia" class="w-full" />
                </UFormField>
              </div>

              <UAlert
                color="neutral"
                variant="subtle"
                icon="i-lucide-rotate-ccw"
                :title="t('pagos.lineamientosTitulo')"
                :description="t('pagos.lineamientos')"
              />

              <div class="flex justify-end">
                <UButton
                  type="submit"
                  form="form-pago-oficina"
                  color="primary"
                  size="sm"
                  :label="t('pagos.registrar')"
                  :loading="registrandoPago"
                />
              </div>
            </form>
          </div>
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
import type { TipoPago } from '#shared/types/domain'
import {
  ANTICIPO_MINIMO_PORCENTAJE,
  METODOS_OFICINA,
  montoMinimoAnticipo,
} from '#shared/pagos'

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

// --- Pagos de una reserva ----------------------------------------------

const pagosAbierto = ref(false)
const consultando = ref<ReservaResumen | null>(null)
const registrandoPago = ref(false)
const panelPagos = useTemplateRef<{ recargar: () => Promise<void> }>('panel-pagos')

const pagoFormulario = reactive({
  tipo: 'anticipo' as TipoPago,
  metodo: 'efectivo' as (typeof METODOS_OFICINA)[number],
  monto: 0,
  referencia: '',
})

const tiposPago = computed(() => [
  { label: t('pagos.tipos.anticipo'), value: 'anticipo' as const },
  { label: t('pagos.tipos.saldo'), value: 'saldo' as const },
])

const metodosPago = computed(() =>
  METODOS_OFICINA.map((metodo) => ({
    label: t(`pagos.metodos.${metodo}` as ClaveMensaje),
    value: metodo,
  })),
)

function abrirPagos(reserva: ReservaResumen) {
  aviso.value = null
  errorOperacion.value = null
  consultando.value = reserva
  pagoFormulario.tipo = 'anticipo'
  pagoFormulario.metodo = 'efectivo'
  pagoFormulario.monto =
    reserva.anticipo && reserva.anticipo !== 'anulado'
      ? Number(reserva.saldoPendiente)
      : montoMinimoAnticipo(reserva.montoTotal)
  pagoFormulario.referencia = ''
  pagosAbierto.value = true
}

async function registrarPago() {
  if (!consultando.value) return
  registrandoPago.value = true
  errorOperacion.value = null
  try {
    await peticion('/api/pagos', {
      method: 'POST',
      body: {
        idReserva: consultando.value.idReserva,
        tipo: pagoFormulario.tipo,
        monto: pagoFormulario.monto,
        metodo: pagoFormulario.metodo,
        referencia: pagoFormulario.referencia.trim() || undefined,
      },
    })
    aviso.value = t('pagos.registradoOk')
    await panelPagos.value?.recargar()
    await recargar()
  } catch (fallo) {
    errorOperacion.value = mensajeDeError(fallo)
  } finally {
    registrandoPago.value = false
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
