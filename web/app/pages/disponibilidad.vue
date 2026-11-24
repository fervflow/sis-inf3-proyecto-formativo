<template>
  <div class="space-y-8">
    <BaseEncabezadoPagina
      :titulo="t('disponibilidad.titulo')"
      :descripcion="t('disponibilidad.introduccion')"
    >
      <template #acciones>
        <UButton
          v-if="esAdmin && vista === 'gestion'"
          color="primary"
          :label="t('salidas.crear')"
          @click="abrirAlta"
        />
      </template>
    </BaseEncabezadoPagina>

    <!--
      La misma página atiende los dos canales: el cliente ve las salidas
      disponibles y solicita su reserva; el administrador ve además la vista
      de gestión. El rol lo exige el servidor: ocultar las acciones es solo
      parte de la interfaz.
    -->
    <UTabs
      v-if="esAdmin"
      v-model="vista"
      :items="vistas"
      color="neutral"
      class="w-fit"
    />

    <UAlert
      v-if="avisoSolicitud"
      color="success"
      variant="soft"
      :title="avisoSolicitud"
    />
    <UAlert v-if="avisoGestion" color="success" variant="soft" :title="avisoGestion" />

    <!-- Vista de cliente: salidas disponibles para solicitar una reserva -->
    <template v-if="vista === 'publica'">
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
          :recorrido="recorridoPublico(salida)"
          :desglose="desgloseDe(salida)"
          @solicitar="solicitar"
        />
      </div>

      <p
        v-if="error"
        class="text-(--vt-texto-sm) text-(--vt-color-error-600)"
      >
        {{ error }}
      </p>
    </template>

    <!-- Vista de gestión: todas las salidas, con alta y edición -->
    <template v-else>
      <div
        v-if="pendienteGestion"
        class="grid gap-4 md:grid-cols-2 xl:grid-cols-3"
      >
        <USkeleton v-for="n in 3" :key="n" class="h-64 w-full" />
      </div>

      <BaseEstadoVacio
        v-else-if="salidasAdmin.length === 0"
        :titulo="t('salidas.vacio')"
        :descripcion="t('salidas.vacioDescripcion')"
      >
        <template #accion>
          <UButton
            color="primary"
            :label="t('salidas.crear')"
            @click="abrirAlta"
          />
        </template>
      </BaseEstadoVacio>

      <div v-else class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        <SalidasTarjeta
          v-for="salida in salidasAdmin"
          :key="salida.idSalida"
          :salida="salida"
          :recorrido="recorridoDeSalida(salida)"
          @editar="abrirEdicion"
        />
      </div>

      <p
        v-if="errorGestion"
        class="text-(--vt-texto-sm) text-(--vt-color-error-600)"
      >
        {{ errorGestion }}
      </p>
    </template>

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

    <SalidasFormularioSalida
      v-model:open="formularioAbierto"
      :salida="editando"
      :paquetes="paquetes"
      @guardada="guardada"
    />
  </div>
</template>

<script setup lang="ts">
import type { Ref } from 'vue'
import type { NuxtError } from '#app'
import type {
  PaqueteAdmin,
  RespuestaCuenta,
  RespuestaDisponibilidad,
  RespuestaPaquetes,
  RespuestaSalidas,
  ReservaResumen,
  SalidaAdmin,
  SalidaDisponible,
} from '#shared/types/api'

const { t } = useTexto()
const mensajeDeError = useMensajeError()
const { fechaHora } = useFormato()
const { armar: armarRecorrido } = useRecorrido()
const peticion = useRequestFetch()

/** La cuenta de la sesión decide si aparece la vista de gestión. */
const { data: cuenta } = useNuxtData<RespuestaCuenta>('cuenta')
const esAdmin = computed(() => cuenta.value?.usuario?.rol === 'ADMIN')

// --- Vista --------------------------------------------------------------

const vista = ref<string>(esAdmin.value ? 'gestion' : 'publica')

const vistas = computed(() => [
  { label: t('disponibilidad.vistaCliente'), value: 'publica' },
  { label: t('disponibilidad.vistaGestion'), value: 'gestion' },
])

// --- Disponibilidad pública (todos los visitantes) -----------------------

const { data, pending: pendiente, error: errorConsulta, refresh: recargar } =
  await useAsyncData<RespuestaDisponibilidad>('disponibilidad', () =>
    peticion<RespuestaDisponibilidad>('/api/disponibilidad'),
  )

const salidas = computed<SalidaDisponible[]>(() => data.value?.salidas ?? [])
const error = computed<string | null>(() =>
  errorConsulta.value ? mensajeDeError(errorConsulta.value) : null,
)

/** Desglose de confirmados y pendientes, visible para todos. */
function desgloseDe(salida: SalidaDisponible): string {
  return t('disponibilidad.desgloseLinea', {
    confirmados: salida.pasajeros_confirmados,
    pendientes: salida.pasajeros_pendientes,
  })
}

/** Recorrido resumido del paquete de una salida disponible. */
function recorridoPublico(salida: SalidaDisponible): string {
  return armarRecorrido({
    origen: salida.origen,
    destino: salida.destino,
    paradas: salida.paradas ?? [],
    circuito: salida.tipo_recorrido === 'circuito',
  })
}

// --- Gestión de salidas (solo administrador) -----------------------------

interface EstadoAdmin {
  data: Ref<RespuestaSalidas | undefined>
  error: Ref<NuxtError | undefined>
  pending: Ref<boolean>
}

/** Estado de la vista de gestión; vacío si la sesión no es de admin. */
let estadoAdmin: Partial<EstadoAdmin> = {}

if (esAdmin.value) {
  const { data, error, pending } = await useAsyncData<RespuestaSalidas>(
    'salidas-admin',
    () => peticion<RespuestaSalidas>('/api/admin/salidas'),
  )
  estadoAdmin = { data, error, pending }

  await useAsyncData<RespuestaPaquetes>('paquetes-admin-salidas', () =>
    peticion<RespuestaPaquetes>('/api/admin/paquetes'),
  )
}

const { data: dataPaquetes } = useNuxtData<RespuestaPaquetes>(
  'paquetes-admin-salidas',
)

const salidasAdmin = computed<SalidaAdmin[]>(
  () => estadoAdmin.data?.value?.salidas ?? [],
)
const paquetes = computed<PaqueteAdmin[]>(
  () => dataPaquetes.value?.paquetes ?? [],
)
const pendienteGestion = computed(() => estadoAdmin.pending?.value ?? false)
const errorGestion = computed<string | null>(() =>
  estadoAdmin.error?.value ? mensajeDeError(estadoAdmin.error.value) : null,
)

/** Resume el recorrido del paquete para la tarjeta. */
function recorridoDeSalida(salida: SalidaAdmin): string {
  const paquete = paquetes.value.find(
    (item) => item.idPaquete === salida.idPaquete,
  )
  if (!paquete) return salida.destino ?? ''

  return armarRecorrido({
    origen: paquete.origen,
    destino: paquete.destino,
    paradas: paquete.paradas,
    circuito: paquete.tipoRecorrido === 'circuito',
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

// --- Alta y edición de salidas (administrador) ---------------------------

const formularioAbierto = ref(false)
const editando = ref<SalidaAdmin | null>(null)
const avisoGestion = ref<string | null>(null)

function abrirAlta() {
  avisoGestion.value = null
  editando.value = null
  formularioAbierto.value = true
}

function abrirEdicion(salida: SalidaAdmin) {
  avisoGestion.value = null
  editando.value = salida
  formularioAbierto.value = true
}

/** La salida quedó guardada: se avisa y se recargan ambas vistas. */
async function guardada(salida: SalidaAdmin) {
  avisoGestion.value = t(
    editando.value ? 'salidas.actualizado' : 'salidas.creado',
    { paquete: salida.paquete },
  )
  editando.value = null

  await Promise.all([
    recargar(),
    refreshNuxtData('salidas-admin'),
  ])
}
</script>
