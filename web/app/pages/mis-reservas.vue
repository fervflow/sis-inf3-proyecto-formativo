<script setup lang="ts">
/**
 * Reservas de la cuenta del cliente (HU-15).
 *
 * El cliente ve solo lo suyo: el servidor filtra por la ficha de su
 * cuenta (RN-RES-17). Desde aquí paga su anticipo o su saldo con la
 * pasarela simulada, llena el manifiesto de su reserva, solicita la
 * cancelación y recibe los avisos de cambios de su salida (HU-16).
 */
import type { ClaveMensaje } from '~/i18n'
import type {
  RespuestaAvisos,
  RespuestaPagos,
  RespuestaReservas,
  ReservaResumen,
} from '#shared/types/api'
import { SOLICITUD_HORAS_VIGENCIA } from '#shared/pagos'

const { t } = useTexto()
const mensajeDeError = useMensajeError()
const { moneda, fecha, fechaHora } = useFormato()
const peticion = useRequestFetch()

const {
  data,
  pending: pendiente,
  error: errorConsulta,
  refresh: recargar,
} = useAsyncData<RespuestaReservas>('mis-reservas', () =>
  peticion<RespuestaReservas>('/api/reservas', {
    query: { estado: 'todas' },
  }),
)

const reservas = computed<ReservaResumen[]>(() => data.value?.reservas ?? [])
const error = computed<string | null>(() =>
  errorConsulta.value ? mensajeDeError(errorConsulta.value) : null,
)

/** El manifiesto falta o está incompleto (RN-RES-19): badge en la fila. */
function manifiestoPendiente(reserva: ReservaResumen): boolean {
  return (
    ['pendiente', 'confirmada'].includes(reserva.estado) &&
    reserva.pasajerosRegistrados < reserva.cantidadPasajeros
  )
}

/** Con saldo por pagar y ya respaldada la reserva, el pago falta. */
function saldoPendiente(reserva: ReservaResumen): boolean {
  return (
    ['pendiente', 'confirmada'].includes(reserva.estado) &&
    Number(reserva.saldoPendiente) > 0
  )
}

// --- Avisos de cambios de salida (HU-16) --------------------------------

const {
  data: avisosSalida,
  error: errorAvisos,
} = useAsyncData<RespuestaAvisos>('avisos', () =>
  peticion<RespuestaAvisos>('/api/avisos'),
)

const listaAvisos = computed(() => avisosSalida.value?.avisos ?? [])

function textoCampo(campo: string): string {
  const clave = {
    fecha_salida: 'avisos.campos.fechaSalida',
    fecha_retorno: 'avisos.campos.fechaRetorno',
    cupo_maximo: 'avisos.campos.cupo',
  }[campo]
  return clave ? t(clave as ClaveMensaje) : campo
}

const columnas = computed<ColumnaTabla<FilaReserva>[]>(() => [
  { clave: 'codigo', etiqueta: t('misreservas.columnas.codigo') },
  { clave: 'paquete', etiqueta: t('misreservas.columnas.paquete') },
  { clave: 'salida', etiqueta: t('misreservas.columnas.salida') },
  {
    clave: 'cantidadPasajeros',
    etiqueta: t('misreservas.columnas.pasajeros'),
    alineacion: 'derecha',
  },
  {
    clave: 'montoTotal',
    etiqueta: t('misreservas.columnas.monto'),
    alineacion: 'derecha',
  },
  {
    clave: 'saldoPendiente',
    etiqueta: t('misreservas.columnas.saldo'),
    alineacion: 'derecha',
  },
  { clave: 'estado', etiqueta: t('misreservas.columnas.estado') },
  { clave: 'vencimiento', etiqueta: t('misreservas.columnas.vencimiento') },
  { clave: 'acciones', etiqueta: t('misreservas.columnas.acciones') },
])

type FilaReserva = ReservaResumen & {
  salida: string
  vencimiento: string | null
  acciones: number
}

const filas = computed<FilaReserva[]>(() =>
  reservas.value.map((reserva) => ({
    ...reserva,
    salida: `${fecha(reserva.fechaSalida)} → ${fecha(reserva.fechaRetorno)}`,
    vencimiento: reserva.fechaExpiracion,
    acciones: reserva.idReserva,
  })),
)

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

function etiquetaEstado(estado: ReservaResumen['estado']): string {
  return t(`solicitudes.estados.${estado}` as ClaveMensaje)
}

/** La reserva admite pagos del cliente: pendiente o confirmada (RN-PAG-06). */
function puedePagar(reserva: ReservaResumen): boolean {
  return (
    (reserva.estado === 'pendiente' || reserva.estado === 'confirmada') &&
    Number(reserva.saldoPendiente) > 0
  )
}

/** La reserva admite manifiesto y cancelación: pendiente o confirmada. */
function activa(reserva: ReservaResumen): boolean {
  return reserva.estado === 'pendiente' || reserva.estado === 'confirmada'
}

// --- Pago, manifiesto y cancelación -------------------------------------

const pagoAbierto = ref(false)
const pagosAbierto = ref(false)
const manifiestoAbierto = ref(false)
const pagando = ref<ReservaResumen | null>(null)
const consultando = ref<ReservaResumen | null>(null)
const avisos = useAvisos()
const solicitandoCancelacion = ref<number | null>(null)

function abrirPago(reserva: ReservaResumen) {
  pagando.value = reserva
  pagoAbierto.value = true
}

function abrirPagos(reserva: ReservaResumen) {
  consultando.value = reserva
  pagosAbierto.value = true
}

function abrirManifiesto(reserva: ReservaResumen) {
  consultando.value = reserva
  manifiestoAbierto.value = true
}

/** El pago quedó registrado: se muestra la referencia de la simulación. */
function pagado(respuesta: RespuestaPagos) {
  pagoAbierto.value = false
  const pago = respuesta.pagos.at(-1)
  avisos.exito('pasarela.exito', {
    monto: moneda(pago?.monto ?? '0'),
    referencia: pago?.referencia ?? '—',
  })
  pagando.value = null
  recargar()
}

/** El cliente pide la cancelación; el personal la ejecuta (HU-13). */
async function solicitarCancelacion(reserva: ReservaResumen) {
  solicitandoCancelacion.value = reserva.idReserva
  try {
    await peticion(
      `/api/reservas/${reserva.idReserva}/solicitar-cancelacion`,
      { method: 'POST' },
    )
    avisos.exito('misreservas.cancelacionSolicitada')
  } catch (fallo) {
    avisos.fallo(fallo)
  } finally {
    solicitandoCancelacion.value = null
    await recargar()
  }
}
</script>

<template>
  <div class="space-y-6">
    <BaseEncabezadoPagina
      :titulo="t('misreservas.titulo')"
      :descripcion="t('misreservas.introduccion')"
    />

    <UAlert v-if="error" color="error" variant="soft" :title="error" />

    <!-- Avisos de cambios de la salida (HU-16): solo los del cliente. -->
    <UAlert
      v-for="avisoSalida in listaAvisos"
      :key="`${avisoSalida.idReserva}-${avisoSalida.fechaCambio}`"
      color="info"
      variant="soft"
      icon="i-lucide-bell-ring"
      :title="t('avisos.titulo', {
        salida: `${avisoSalida.paquete} (${fecha(avisoSalida.fechaSalida)})`,
      })"
      :description="t('avisos.detalle', {
        campo: textoCampo(avisoSalida.campo),
        anterior: avisoSalida.valorAnterior ?? '—',
        nuevo: avisoSalida.valorNuevo ?? '—',
        fecha: fechaHora(avisoSalida.fechaCambio),
      })"
    />

    <BaseTarjeta>
      <div v-if="pendiente || filas.length > 0" class="overflow-x-auto">
        <BaseTablaDatos
          class="min-w-[64rem]"
          :columnas="columnas"
          :filas="filas"
          :cargando="pendiente"
          :texto-vacio="t('misreservas.vacia')"
        >
          <template #celda="{ columna, fila, valor }">
            <span v-if="columna.clave === 'codigo'" class="font-(--vt-texto-peso-medio)">
              {{ fila.codigo }}
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
                :label="t('misreservas.manifiestoPendiente')"
              />
              <UBadge
                v-else-if="saldoPendiente(fila)"
                class="ml-2"
                color="warning"
                variant="subtle"
                icon="i-lucide-banknote"
                :label="t('pagos.saldoPendiente')"
              />
              <UBadge
                v-if="fila.fechaSolicitudCancelacion && fila.estado !== 'cancelada'"
                class="ml-2"
                color="error"
                variant="subtle"
                :label="t('solicitudes.cancelacionSolicitada')"
              />
            </span>

            <UBadge
              v-else-if="columna.clave === 'estado'"
              :color="colorDeEstado(fila.estado)"
              variant="subtle"
              :label="etiquetaEstado(fila.estado)"
            />

            <span
              v-else-if="['montoTotal', 'saldoPendiente'].includes(columna.clave)"
              class="tabular-nums"
            >
              {{ moneda(String(valor)) }}
            </span>

            <span v-else-if="columna.clave === 'vencimiento'">
              <span
                v-if="fila.fechaExpiracion && fila.estado === 'pendiente'"
                class="tabular-nums"
              >
                {{ fechaHora(fila.fechaExpiracion) }}
              </span>
              <span v-else class="text-(--vt-color-texto-suave)">—</span>
            </span>

            <span v-else-if="columna.clave === 'acciones'" class="flex flex-wrap justify-end gap-1.5">
              <UButton
                v-if="puedePagar(fila)"
                size="xs"
                color="primary"
                variant="soft"
                icon="i-lucide-banknote"
                :label="t('misreservas.pagar')"
                @click="abrirPago(fila)"
              />
              <UButton
                v-if="activa(fila)"
                size="xs"
                color="neutral"
                variant="soft"
                :label="t('pasajeros.titulo')"
                @click="abrirManifiesto(fila)"
              />
              <UButton
                v-if="activa(fila) && !fila.fechaSolicitudCancelacion"
                size="xs"
                color="error"
                variant="soft"
                :loading="solicitandoCancelacion === fila.idReserva"
                :label="t('misreservas.solicitarCancelacion')"
                @click="solicitarCancelacion(fila)"
              />
              <UButton
                size="xs"
                color="neutral"
                variant="ghost"
                :label="t('misreservas.pagos')"
                @click="abrirPagos(fila)"
              />
            </span>

            <span v-else class="tabular-nums">{{ valor }}</span>
          </template>
        </BaseTablaDatos>
      </div>

      <BaseEstadoVacio
        v-else-if="!errorConsulta"
        :titulo="t('misreservas.vacia')"
        :descripcion="t('misreservas.vacioDescripcion')"
      >
        <template #accion>
          <UButton
            color="primary"
            :label="t('nav.disponibilidad')"
            to="/disponibilidad"
          />
        </template>
      </BaseEstadoVacio>
    </BaseTarjeta>

    <UAlert
      color="info"
      variant="subtle"
      icon="i-lucide-clock"
      :title="t('misreservas.plazo', { horas: SOLICITUD_HORAS_VIGENCIA })"
    />

    <UModal
      v-model:open="pagoAbierto"
      :title="t('pasarela.titulo')"
      :ui="{ content: 'max-w-2xl' }"
    >
      <template #body>
        <PagosFormularioPago
          v-if="pagando"
          :reserva="pagando"
          @pagado="pagado"
          @cancelar="pagoAbierto = false"
        />
      </template>
    </UModal>

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
      v-model:open="pagosAbierto"
      :title="t('pagos.titulo')"
      :ui="{ content: 'max-w-3xl' }"
    >
      <template #body>
        <PagosResumenPagos v-if="consultando" :id-reserva="consultando.idReserva" />
      </template>
    </UModal>
  </div>
</template>
