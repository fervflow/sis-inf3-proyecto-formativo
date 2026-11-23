<template>
  <div class="space-y-6">
    <BaseEncabezadoPagina
      :titulo="t('salidas.titulo')"
      :descripcion="t('salidas.introduccion')"
    >
      <template #acciones>
        <UButton
          color="primary"
          :label="t('salidas.crear')"
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
      v-else-if="salidas.length === 0"
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
        v-for="salida in salidas"
        :key="salida.idSalida"
        :salida="salida"
        :recorrido="recorridoDeSalida(salida)"
        @editar="abrirEdicion"
      />
    </div>

    <UModal
      v-model:open="formularioAbierto"
      :title="tituloFormulario"
      :ui="{ content: 'max-w-3xl' }"
    >
      <template #body>
        <form id="form-salida" class="space-y-4" @submit.prevent="guardar">
          <UFormField :label="t('salidas.form.paquete')" name="paquete">
            <USelect
              v-model="formulario.idPaquete"
              :items="paquetesDisponibles"
              class="w-full"
              :disabled="Boolean(editando)"
            />
          </UFormField>

          <div class="grid gap-4 sm:grid-cols-2">
            <UFormField
              :label="t('salidas.form.fechaSalida')"
              name="fechaSalida"
            >
              <UInput
                v-model="formulario.fechaSalida"
                type="date"
                class="w-full"
                required
              />
            </UFormField>

            <UFormField
              :label="t('salidas.form.fechaRetorno')"
              name="fechaRetorno"
              :help="t('salidas.ayudaDuracion')"
            >
              <UInput
                v-model="formulario.fechaRetorno"
                type="date"
                class="w-full"
                required
              />
            </UFormField>
          </div>

          <div class="grid gap-4 sm:grid-cols-2">
            <UFormField
              :label="t('salidas.form.cupo')"
              name="cupo"
              :help="t('salidas.ayudaCupo')"
            >
              <UInputNumber
                v-model="formulario.cupoMaximo"
                :min="1"
                :max="32767"
                :step="1"
                :increment="false"
                :decrement="false"
                class="w-full"
              />
            </UFormField>

            <UFormField
              :label="t('salidas.form.precio')"
              name="precio"
              :help="ayudaPrecio"
            >
              <BaseCampoMoneda v-model="formulario.precio" required />
            </UFormField>
          </div>

          <div class="grid gap-4 sm:grid-cols-2">
            <UFormField
              :label="t('salidas.form.puntoEncuentro')"
              name="puntoEncuentro"
            >
              <UInput
                v-model="formulario.puntoEncuentro"
                maxlength="200"
                class="w-full"
              />
            </UFormField>

            <UFormField :label="t('salidas.form.estado')" name="estado">
              <USelect
                v-model="formulario.estado"
                :items="estados"
                class="w-full"
                :disabled="!editando"
              />
            </UFormField>
          </div>

          <UFormField
            v-if="editando"
            :label="t('salidas.form.motivo')"
            name="motivo"
            :help="t('salidas.motivoCancelacion')"
          >
            <UInput
              v-model="formulario.motivo"
              maxlength="200"
              class="w-full"
            />
          </UFormField>

          <UFormField
            :label="t('salidas.form.observaciones')"
            name="observaciones"
          >
            <UTextarea
              v-model="formulario.observaciones"
              :rows="2"
              maxlength="1000"
              class="w-full"
            />
          </UFormField>
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
            :label="t('comun.cancelar')"
            @click="formularioAbierto = false"
          />
          <UButton
            type="submit"
            form="form-salida"
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
  PaqueteAdmin,
  RespuestaPaquetes,
  RespuestaSalidas,
  SalidaAdmin,
} from '#shared/types/api'
import type { EstadoSalida } from '#shared/types/domain'
import type { ClaveMensaje } from '~/i18n'

const RUTA: string = '/api/admin/salidas'

const peticion = useRequestFetch()

const { t } = useTexto()
const mensajeDeError = useMensajeError()
const { moneda } = useFormato()

const {
  data,
  pending: pendiente,
  error: errorConsulta,
  refresh,
} = await useAsyncData<RespuestaSalidas>('salidas-admin', () =>
  peticion<RespuestaSalidas>(RUTA),
)

const { data: dataPaquetes } = await useAsyncData<RespuestaPaquetes>(
  'paquetes-admin-salidas',
  () => peticion<RespuestaPaquetes>('/api/admin/paquetes'),
)

const salidas = computed<SalidaAdmin[]>(() => data.value?.salidas ?? [])
const paquetes = computed<PaqueteAdmin[]>(
  () => dataPaquetes.value?.paquetes ?? [],
)
const error = computed<string | null>(() =>
  errorConsulta.value ? mensajeDeError(errorConsulta.value) : null,
)

const aviso = ref<string | null>(null)

// --- Alta y edición -----------------------------------------------------

const formularioAbierto = ref(false)
const guardando = ref(false)
const errorFormulario = ref<string | null>(null)
const editando = ref<SalidaAdmin | null>(null)

const formulario = reactive({
  idPaquete: 0,
  fechaSalida: '',
  fechaRetorno: '',
  cupoMaximo: null as number | null,
  precio: null as number | null,
  puntoEncuentro: '',
  estado: 'programada' as EstadoSalida,
  observaciones: '',
  motivo: '',
})

const paqueteSeleccionado = computed(() =>
  paquetes.value.find((paquete) => paquete.idPaquete === formulario.idPaquete),
)

/** El precio de la salida parte del precio base del paquete. */
const ayudaPrecio = computed(() => {
  const base = paqueteSeleccionado.value?.precioBase
  return base
    ? t('salidas.ayudaPrecio', { precio: moneda(base) })
    : t('salidas.ayudaPrecioVacio')
})

const estados = computed<{ label: string; value: EstadoSalida }[]>(() => {
  const actual = editando.value?.estado
  const valores: EstadoSalida[] = actual
    ? actual === 'programada'
      ? ['programada', 'confirmada', 'cancelada']
      : actual === 'confirmada'
        ? ['confirmada', 'realizada', 'cancelada']
        : [actual]
    : ['programada']

  return valores.map((valor) => ({
    label: t(`salidas.estados.${valor}` as ClaveMensaje),
    value: valor,
  }))
})

const paquetesDisponibles = computed<{ label: string; value: number }[]>(() =>
  paquetes.value
    .filter(
      (paquete) =>
        paquete.estado === 'activo' ||
        paquete.idPaquete === formulario.idPaquete,
    )
    .map((paquete) => ({
      label: `${paquete.codigo} · ${paquete.nombre}`,
      value: paquete.idPaquete,
    })),
)

const tituloFormulario = computed(() =>
  editando.value ? t('salidas.editar') : t('salidas.crear'),
)

/** Resume el recorrido del paquete para la tarjeta. */
function recorridoDeSalida(salida: SalidaAdmin): string {
  const paquete = paquetes.value.find(
    (item) => item.idPaquete === salida.idPaquete,
  )
  if (!paquete) return salida.destino ?? ''

  const partes: string[] = []
  if (paquete.origen) partes.push(paquete.origen.nombre)
  for (const parada of paquete.paradas) {
    if (!partes.includes(parada.nombre)) partes.push(parada.nombre)
  }
  if (paquete.destino && !partes.includes(paquete.destino.nombre)) {
    partes.push(paquete.destino.nombre)
  }
  if (paquete.tipoRecorrido === 'circuito' && paquete.origen) {
    partes.push(paquete.origen.nombre)
  }

  return partes.join(' → ')
}

function abrirAlta() {
  const inicial = paquetes.value.find((paquete) => paquete.estado === 'activo')

  editando.value = null
  formulario.idPaquete = inicial?.idPaquete ?? 0
  formulario.fechaSalida = hoy()
  formulario.fechaRetorno = hoy()
  formulario.cupoMaximo = 10
  formulario.precio = inicial ? Number(inicial.precioBase) : null
  formulario.puntoEncuentro = ''
  formulario.estado = 'programada'
  formulario.observaciones = ''
  formulario.motivo = ''
  errorFormulario.value = null
  formularioAbierto.value = true
  ajustarRetorno()
}

function abrirEdicion(salida: SalidaAdmin) {
  editando.value = salida
  formulario.idPaquete = salida.idPaquete
  formulario.fechaSalida = salida.fechaSalida
  formulario.fechaRetorno = salida.fechaRetorno
  formulario.cupoMaximo = salida.cupoMaximo
  formulario.precio = Number(salida.precio)
  formulario.puntoEncuentro = salida.puntoEncuentro ?? ''
  formulario.estado = salida.estado
  formulario.observaciones = salida.observaciones ?? ''
  formulario.motivo = ''
  errorFormulario.value = null
  formularioAbierto.value = true
}

async function guardar() {
  errorFormulario.value = null

  if (
    !formulario.idPaquete ||
    !formulario.fechaSalida ||
    !formulario.fechaRetorno ||
    !formulario.cupoMaximo ||
    !formulario.precio
  ) {
    errorFormulario.value = t('salidas.errores.revisar')
    return
  }

  guardando.value = true

  const cuerpo = {
    idPaquete: formulario.idPaquete,
    fechaSalida: formulario.fechaSalida,
    fechaRetorno: formulario.fechaRetorno,
    cupoMaximo: formulario.cupoMaximo,
    precio: formulario.precio,
    puntoEncuentro: formulario.puntoEncuentro,
    estado: formulario.estado,
    observaciones: formulario.observaciones,
    motivo: formulario.motivo,
  }

  try {
    const guardado = await $fetch<SalidaAdmin>(
      editando.value ? rutaSalida(editando.value.idSalida) : RUTA,
      {
        method: editando.value ? 'PATCH' : 'POST',
        body: cuerpo,
      },
    )

    formularioAbierto.value = false
    aviso.value = t(
      editando.value ? 'salidas.actualizado' : 'salidas.creado',
      { paquete: guardado.paquete },
    )
    await refresh()
  } catch (fallo) {
    errorFormulario.value = mensajeDeError(fallo)
  } finally {
    guardando.value = false
  }
}

/** Ajusta el retorno según la duración del paquete seleccionado. */
function ajustarRetorno() {
  const paquete = paqueteSeleccionado.value
  if (!paquete || !formulario.fechaSalida) return

  const inicio = new Date(`${formulario.fechaSalida}T00:00:00Z`)
  inicio.setUTCDate(inicio.getUTCDate() + paquete.duracionDias - 1)
  formulario.fechaRetorno = inicio.toISOString().slice(0, 10)
}

watch(
  () => [formulario.idPaquete, formulario.fechaSalida],
  () => ajustarRetorno(),
)

watch(
  () => formulario.idPaquete,
  () => {
    if (editando.value) return
    const paquete = paqueteSeleccionado.value
    formulario.precio = paquete ? Number(paquete.precioBase) : null
  },
)

function hoy(): string {
  return new Date().toISOString().slice(0, 10)
}

/** Ruta de una salida. Devuelve `string` para no expandir los tipos de ruta. */
function rutaSalida(id: number): string {
  return `/api/admin/salidas/${id}`
}
</script>
