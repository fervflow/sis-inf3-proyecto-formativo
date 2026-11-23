<template>
  <div class="space-y-6">
    <BaseEncabezadoPagina
      :titulo="t('cotizaciones.titulo')"
      :descripcion="t('cotizaciones.introduccion')"
    >
      <template #acciones>
        <UButton
          color="primary"
          :label="t('cotizaciones.crear')"
          @click="abrirAlta"
        />
      </template>
    </BaseEncabezadoPagina>

    <UAlert v-if="aviso" color="success" variant="soft" :title="aviso" />
    <UAlert v-if="error" color="error" variant="soft" :title="error" />

    <div
      v-if="pendiente"
      class="grid gap-4 md:grid-cols-2 xl:grid-cols-3"
    >
      <USkeleton v-for="n in 3" :key="n" class="h-64 w-full" />
    </div>

    <BaseEstadoVacio
      v-else-if="cotizaciones.length === 0"
      :titulo="t('cotizaciones.vacio')"
      :descripcion="t('cotizaciones.vacioDescripcion')"
    >
      <template #accion>
        <UButton
          color="primary"
          :label="t('cotizaciones.crear')"
          @click="abrirAlta"
        />
      </template>
    </BaseEstadoVacio>

    <div v-else class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
      <CotizacionesTarjeta
        v-for="cotizacion in cotizaciones"
        :key="cotizacion.idCotizacion"
        :cotizacion="cotizacion"
        @abrir="abrirEdicion"
      />
    </div>

    <UModal
      v-model:open="formularioAbierto"
      :title="tituloFormulario"
      :ui="{ content: 'max-w-3xl' }"
    >
      <template #body>
        <form id="form-cotizacion" class="space-y-4" @submit.prevent="guardar">
          <div class="grid gap-4 sm:grid-cols-2">
            <UFormField :label="t('cotizaciones.form.numero')" name="numero">
              <UInput
                :model-value="
                  editando?.numero ?? t('cotizaciones.ayudaNumero')
                "
                disabled
                class="w-full"
              />
            </UFormField>

            <UFormField :label="t('cotizaciones.form.estado')" name="estado">
              <USelect
                v-model="formulario.estado"
                :items="estados"
                class="w-full"
                :disabled="soloLectura"
              />
            </UFormField>
          </div>

          <div class="grid gap-4 sm:grid-cols-2">
            <UFormField :label="t('cotizaciones.form.cliente')" name="cliente">
              <USelect
                v-model="formulario.idCliente"
                :items="clientesDisponibles"
                :placeholder="t('cotizaciones.sinClientes')"
                class="w-full"
                :disabled="soloLectura || Boolean(editando)"
              />
            </UFormField>

            <UFormField :label="t('cotizaciones.form.salida')" name="salida">
              <USelect
                v-model="formulario.idSalida"
                :items="salidasDisponibles"
                :placeholder="t('cotizaciones.sinSalidas')"
                class="w-full"
                :disabled="soloLectura || Boolean(editando)"
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
              {{ t('cotizaciones.form.disponibles') }}
            </p>
          </div>

          <div class="grid gap-4 sm:grid-cols-2">
            <UFormField
              :label="t('cotizaciones.form.cantidad')"
              name="cantidad"
            >
              <UInputNumber
                v-model="formulario.cantidadPasajeros"
                :min="1"
                :max="32767"
                :step="1"
                :increment="false"
                :decrement="false"
                :disabled="soloLectura"
                class="w-full"
              />
            </UFormField>

            <UFormField
              :label="t('cotizaciones.form.precio')"
              name="precio"
              :help="t('cotizaciones.ayudaPrecio')"
            >
              <BaseCampoMoneda
                v-model="formulario.precioUnitario"
                :disabled="soloLectura"
              />
            </UFormField>
          </div>

          <div class="grid gap-4 sm:grid-cols-2">
            <UFormField
              :label="t('cotizaciones.form.descuento')"
              name="descuento"
              :help="t('cotizaciones.ayudaDescuento')"
            >
              <BaseCampoMoneda
                v-model="formulario.descuento"
                :min="0"
                :disabled="soloLectura"
              />
            </UFormField>

            <UFormField
              :label="t('cotizaciones.form.validez')"
              name="validez"
              :help="t('cotizaciones.ayudaValidez')"
            >
              <UInput
                v-model="formulario.fechaValidez"
                type="date"
                class="w-full"
                :disabled="soloLectura"
              />
            </UFormField>
          </div>

          <UFormField
            :label="t('cotizaciones.form.condiciones')"
            name="condiciones"
            :help="t('cotizaciones.ayudaCondiciones')"
          >
            <UTextarea
              v-model="formulario.condiciones"
              :rows="3"
              maxlength="2000"
              :disabled="soloLectura"
              class="w-full"
            />
          </UFormField>

          <UFormField
            :label="t('cotizaciones.form.observaciones')"
            name="observaciones"
          >
            <UTextarea
              v-model="formulario.observaciones"
              :rows="2"
              maxlength="1000"
              :disabled="soloLectura"
              class="w-full"
            />
          </UFormField>

          <div class="flex justify-end">
            <div class="grid grid-cols-2 gap-x-8 gap-y-1 text-right">
              <span class="text-(--vt-texto-sm) text-(--vt-color-texto-suave)">
                {{ t('cotizaciones.resumen.subtotal') }}
              </span>
              <span class="tabular-nums">{{ moneda(subtotal) }}</span>
              <span class="text-(--vt-texto-sm) text-(--vt-color-texto-suave)">
                {{ t('cotizaciones.resumen.descuento') }}
              </span>
              <span class="tabular-nums">{{ moneda(formulario.descuento ?? 0) }}</span>
              <span class="font-(--vt-texto-peso-fuerte)">
                {{ t('cotizaciones.resumen.total') }}
              </span>
              <span class="font-(--vt-texto-peso-fuerte) tabular-nums">
                {{ moneda(total) }}
              </span>
            </div>
          </div>
        </form>
      </template>

      <template #footer>
        <div class="flex flex-wrap items-center justify-end gap-2">
          <p
            v-if="errorFormulario"
            class="me-auto text-(--vt-texto-sm) text-(--vt-color-error-600)"
          >
            {{ errorFormulario }}
          </p>
          <UButton
            type="button"
            variant="ghost"
            color="neutral"
            :label="soloLectura ? t('comun.cerrar') : t('comun.cancelar')"
            @click="formularioAbierto = false"
          />
          <UButton
            v-if="!soloLectura"
            type="submit"
            form="form-cotizacion"
            color="primary"
            :loading="guardando"
            :label="t('comun.guardar')"
          />
        </div>
      </template>
    </UModal>
  </div>
</template>

<script setup lang="ts">
import type {
  ClienteResumen,
  CotizacionAdmin,
  RespuestaClientes,
  RespuestaCotizaciones,
  RespuestaDisponibilidad,
  SalidaDisponible,
} from '#shared/types/api'
import type { EstadoCotizacion } from '#shared/types/domain'
import type { ClaveMensaje } from '~/i18n'

const peticion = useRequestFetch()
const { t } = useTexto()
const { moneda, fecha } = useFormato()
const mensajeDeError = useMensajeError()

const {
  data,
  pending: pendiente,
  error: errorConsulta,
  refresh,
} = await useAsyncData<RespuestaCotizaciones>('cotizaciones', () =>
  peticion<RespuestaCotizaciones>('/api/cotizaciones'),
)

const { data: dataClientes } = await useAsyncData<RespuestaClientes>(
  'clientes-cotizaciones',
  () => peticion<RespuestaClientes>('/api/clientes'),
)

const { data: dataSalidas } = await useAsyncData<RespuestaDisponibilidad>(
  'salidas-cotizaciones',
  () => peticion<RespuestaDisponibilidad>('/api/disponibilidad'),
)

const cotizaciones = computed<CotizacionAdmin[]>(
  () => data.value?.cotizaciones ?? [],
)
const clientes = computed<ClienteResumen[]>(
  () => dataClientes.value?.clientes ?? [],
)
const salidas = computed<SalidaDisponible[]>(
  () => dataSalidas.value?.salidas ?? [],
)

const error = computed<string | null>(() =>
  errorConsulta.value ? mensajeDeError(errorConsulta.value) : null,
)
const aviso = ref<string | null>(null)

function esTerminal(estado: EstadoCotizacion): boolean {
  return ['aceptada', 'rechazada', 'vencida'].includes(estado)
}

// --- Alta y edición -----------------------------------------------------

const formularioAbierto = ref(false)
const guardando = ref(false)
const errorFormulario = ref<string | null>(null)
const editando = ref<CotizacionAdmin | null>(null)
const soloLectura = ref(false)

const formulario = reactive({
  idCliente: undefined as number | undefined,
  idSalida: undefined as number | undefined,
  cantidadPasajeros: 1 as number | null,
  precioUnitario: null as number | null,
  descuento: 0 as number | null,
  fechaValidez: '',
  condiciones: '',
  observaciones: '',
  estado: 'borrador' as EstadoCotizacion,
})

const tituloFormulario = computed(() => {
  if (soloLectura.value) return t('cotizaciones.ver')
  return editando.value
    ? t('cotizaciones.editar')
    : t('cotizaciones.crear')
})

const clientesDisponibles = computed<{ label: string; value: number }[]>(() =>
  clientes.value.map((cliente) => ({
    label: `${cliente.tipoDocumento} ${cliente.numeroDocumento} · ${cliente.nombres} ${cliente.apellidos}`,
    value: cliente.idCliente,
  })),
)

const salidasDisponibles = computed<{ label: string; value: number }[]>(() =>
  salidas.value.map((salida) => ({
    label: `${salida.codigo_paquete} · ${salida.paquete} · ${fecha(salida.fecha_salida)}`,
    value: Number(salida.id_salida),
  })),
)

const salidaSeleccionada = computed(() =>
  salidas.value.find(
    (salida) => Number(salida.id_salida) === formulario.idSalida,
  ),
)

const estados = computed<{ label: string; value: EstadoCotizacion }[]>(() => {
  const actual = editando.value?.estado
  const valores: EstadoCotizacion[] = actual
    ? actual === 'borrador'
      ? ['borrador', 'enviada', 'aceptada', 'rechazada']
      : actual === 'enviada'
        ? ['enviada', 'aceptada', 'rechazada']
        : [actual]
    : ['borrador', 'enviada']

  return valores.map((valor) => ({
    label: t(`cotizaciones.estados.${valor}` as ClaveMensaje),
    value: valor,
  }))
})

const subtotal = computed(
  () =>
    (formulario.cantidadPasajeros ?? 0) *
    (formulario.precioUnitario ?? 0),
)

const total = computed(
  () => subtotal.value - (formulario.descuento ?? 0),
)

function hoy(): string {
  return new Date().toISOString().slice(0, 10)
}

function sumarDias(dias: number): string {
  const fecha = new Date()
  fecha.setUTCDate(fecha.getUTCDate() + dias)
  return fecha.toISOString().slice(0, 10)
}

function aplicarSalida() {
  const salida = salidaSeleccionada.value
  if (salida) formulario.precioUnitario = Number(salida.precio)
}

function abrirAlta() {
  editando.value = null
  soloLectura.value = false
  formulario.idCliente = clientes.value[0]?.idCliente
  formulario.idSalida = salidas.value[0]
    ? Number(salidas.value[0].id_salida)
    : undefined
  formulario.cantidadPasajeros = 1
  formulario.precioUnitario = salidas.value[0]
    ? Number(salidas.value[0].precio)
    : null
  formulario.descuento = 0
  formulario.fechaValidez = sumarDias(15)
  formulario.condiciones = ''
  formulario.observaciones = ''
  formulario.estado = 'borrador'
  errorFormulario.value = null
  formularioAbierto.value = true
  aplicarSalida()
}

function abrirEdicion(cotizacion: CotizacionAdmin) {
  editando.value = cotizacion
  soloLectura.value = esTerminal(cotizacion.estado)
  formulario.idCliente = cotizacion.idCliente
  formulario.idSalida = cotizacion.idSalida
  formulario.cantidadPasajeros = cotizacion.cantidadPasajeros
  formulario.precioUnitario = Number(cotizacion.precioUnitario)
  formulario.descuento = Number(cotizacion.descuento)
  formulario.fechaValidez = cotizacion.fechaValidez
  formulario.condiciones = cotizacion.condiciones ?? ''
  formulario.observaciones = cotizacion.observaciones ?? ''
  formulario.estado = cotizacion.estado
  errorFormulario.value = null
  formularioAbierto.value = true
}

watch(
  () => formulario.idSalida,
  () => {
    if (editando.value) return
    aplicarSalida()
  },
)

async function guardar() {
  errorFormulario.value = null

  const idCliente = formulario.idCliente
  const idSalida = formulario.idSalida
  const cantidad = formulario.cantidadPasajeros
  const precio = formulario.precioUnitario

  if (
    !idCliente ||
    !idSalida ||
    !cantidad ||
    !precio ||
    !formulario.fechaValidez
  ) {
    errorFormulario.value = t('cotizaciones.errores.revisar')
    return
  }

  if ((formulario.descuento ?? 0) > subtotal.value) {
    errorFormulario.value = t('cotizaciones.errores.descuento')
    return
  }

  if (formulario.fechaValidez < hoy()) {
    errorFormulario.value = t('cotizaciones.errores.validez')
    return
  }

  guardando.value = true

  const cuerpo = {
    idCliente,
    idSalida,
    cantidadPasajeros: cantidad,
    precioUnitario: precio,
    descuento: formulario.descuento ?? 0,
    fechaValidez: formulario.fechaValidez,
    condiciones: formulario.condiciones,
    observaciones: formulario.observaciones,
    estado: formulario.estado,
  }

  try {
    const guardada = await $fetch<CotizacionAdmin>(
      editando.value
        ? `/api/cotizaciones/${editando.value.idCotizacion}`
        : '/api/cotizaciones',
      {
        method: editando.value ? 'PATCH' : 'POST',
        body: cuerpo,
      },
    )

    formularioAbierto.value = false
    aviso.value = t(
      editando.value ? 'cotizaciones.actualizado' : 'cotizaciones.creado',
      { numero: guardada.numero },
    )
    await refresh()
  } catch (fallo) {
    errorFormulario.value = mensajeDeError(fallo)
  } finally {
    guardando.value = false
  }
}
</script>
