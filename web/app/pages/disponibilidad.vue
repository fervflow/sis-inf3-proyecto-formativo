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
          @ver-detalle="abrirFicha"
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
          @ver-detalle="abrirFicha"
        />
      </div>

      <p
        v-if="errorGestion"
        class="text-(--vt-texto-sm) text-(--vt-color-error-600)"
      >
        {{ errorGestion }}
      </p>
    </template>

    <!--
      Dos pasos del mismo flujo: la solicitud del canal web (HU-06) y el
      pago del anticipo por la pasarela simulada (HU-14). Sin sesión, el
      botón lleva a ingresar o crear cuenta (RN-RES-17).
    -->
    <UModal
      v-model:open="solicitudAbierta"
      :title="tituloModal"
      :ui="{ content: 'max-w-2xl' }"
    >
      <template #body>
        <SolicitudesFormularioCliente
          v-if="paso === 'solicitud' && salidaSolicitada"
          ref="formulario-cliente"
          :salida="salidaSolicitada"
          @registrada="registrada"
          @cancelar="solicitudAbierta = false"
        />
        <PagosFormularioPago
          v-else-if="paso === 'pago' && reservaSolicitada"
          :reserva="reservaSolicitada"
          @pagado="pagado"
          @cancelar="solicitudAbierta = false"
        />
      </template>
    </UModal>

    <!--
      Ficha de una salida (HU-18): el paquete, el mapa del recorrido, el
      itinerario, los servicios y los proveedores. Abre desde las
      tarjetas de los dos canales; el administrador puede editar desde
      ella.
    -->
    <UModal
      v-model:open="fichaAbierta"
      :title="t('salidas.ficha.titulo')"
      :ui="{ content: 'max-w-5xl' }"
    >
      <template #body>
        <div v-if="cargandoFicha" class="space-y-3">
          <USkeleton class="h-16 w-full" />
          <USkeleton class="h-64 w-full" />
          <USkeleton class="h-24 w-full" />
        </div>
        <SalidasFichaSalida
          v-else-if="ficha"
          :ficha="ficha"
          @solicitar="solicitarDesdeFicha"
          @cerrar="fichaAbierta = false"
          @editar="editarDesdeFicha"
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
  FichaSalida,
  PaqueteAdmin,
  RespuestaCuenta,
  RespuestaDisponibilidad,
  RespuestaPagos,
  RespuestaPaquetes,
  RespuestaSalidas,
  ReservaResumen,
  SalidaAdmin,
  SalidaDisponible,
  SalidaSolicitud,
} from '#shared/types/api'
import type { ClaveMensaje } from '~/i18n'

const { t } = useTexto()
const mensajeDeError = useMensajeError()
const avisos = useAvisos()
const { moneda } = useFormato()
const { armar: armarRecorrido } = useRecorrido()
const peticion = useRequestFetch()

/** La cuenta de la sesión decide si aparece la vista de gestión. */
const { data: cuenta } = useNuxtData<RespuestaCuenta>('cuenta')
const esAdmin = computed(() => cuenta.value?.usuario?.rol === 'ADMIN')
const esCliente = computed(() => cuenta.value?.usuario?.rol === 'CLIENTE')

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

/**
 * Dos pasos: la solicitud y, si el cliente quiere, el pago del anticipo
 * en el mismo flujo. El pago también queda disponible para después, desde
 * «Mis reservas» (HU-14).
 */
type PasoSolicitud = 'solicitud' | 'pago'

const paso = ref<PasoSolicitud>('solicitud')
const salidaSolicitada = ref<SalidaSolicitud | null>(null)
const reservaSolicitada = ref<ReservaResumen | null>(null)
const formularioCliente = useTemplateRef<{
  reiniciar: () => void
}>('formulario-cliente')

const solicitudAbierta = ref(false)
const avisoSolicitud = ref<string | null>(null)

const tituloModal = computed(() =>
  paso.value === 'pago'
    ? t('pasarela.titulo')
    : t('solicitudes.cliente.titulo'),
)

function solicitar(salida: SalidaSolicitud) {
  avisoSolicitud.value = null

  // Sin sesión no hay solicitud: a ingresar o crear cuenta, con retorno.
  if (!cuenta.value?.usuario) {
    return navigateTo(
      `/ingresar?volver=${encodeURIComponent('/disponibilidad')}`,
    )
  }

  // El personal registra por su canal, en «Solicitudes».
  if (!esCliente.value) {
    return navigateTo('/solicitudes')
  }

  paso.value = 'solicitud'
  salidaSolicitada.value = salida
  formularioCliente.value?.reiniciar()
  solicitudAbierta.value = true
}

/** La solicitud quedó registrada: el siguiente paso es el pago. */
function registrada(reserva: ReservaResumen) {
  reservaSolicitada.value = reserva
  paso.value = 'pago'
  recargar()
}

/** El pago quedó registrado: se muestra su referencia y su estado. */
function pagado(respuesta: RespuestaPagos) {
  solicitudAbierta.value = false
  const pago = respuesta.pagos.at(-1)
  avisoSolicitud.value = t('pasarela.exito', {
    monto: moneda(pago?.monto ?? '0'),
    referencia: pago?.referencia ?? '—',
  })
  salidaSolicitada.value = null
  reservaSolicitada.value = null
  paso.value = 'solicitud'
  recargar()
}

// --- Ficha de una salida (HU-18) ------------------------------------------

const fichaAbierta = ref(false)
const ficha = ref<FichaSalida | null>(null)
const cargandoFicha = ref(false)

/** Carga y abre la ficha de una salida, desde cualquiera de los canales. */
async function abrirFicha(
  salida: SalidaDisponible | SalidaAdmin,
): Promise<void> {
  const id = 'idSalida' in salida ? salida.idSalida : salida.id_salida
  fichaAbierta.value = true
  cargandoFicha.value = true
  ficha.value = null
  try {
    ficha.value = await peticion<FichaSalida>(`/api/salidas/${id}`)
  } catch (fallo) {
    fichaAbierta.value = false
    avisos.fallo(fallo)
  } finally {
    cargandoFicha.value = false
  }
}

/** Desde la ficha, abre el formulario de edición de la salida. */
function editarDesdeFicha() {
  fichaAbierta.value = false
  const salida = salidasAdmin.value.find(
    (item) => item.idSalida === ficha.value?.idSalida,
  )
  if (salida) abrirEdicion(salida)
}

/**
 * Desde la ficha, sigue el mismo flujo de solicitud de las tarjetas:
 * la ficha ya trae los datos que el formulario de solicitud necesita.
 */
function solicitarDesdeFicha() {
  const cargada = ficha.value
  if (!cargada) return

  fichaAbierta.value = false
  solicitar({
    id_salida: cargada.idSalida,
    paquete: cargada.paquete,
    codigo_paquete: cargada.codigoPaquete,
    fecha_salida: cargada.fechaSalida,
    fecha_retorno: cargada.fechaRetorno,
    cupo_disponible: cargada.cupoDisponible,
    precio: cargada.precio,
  })
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
