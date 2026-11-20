<script setup lang="ts">
/**
 * Selector de un lugar con búsqueda y mapa.
 *
 * Busca en el catálogo local y en Photon (OpenStreetMap). El lugar
 * elegido se guarda en el catálogo antes de entregarlo, de modo que el
 * paquete guarde una referencia y no un resultado externo. También se
 * puede crear un lugar con un clic en el mapa.
 */
import type {
  LugarResumen,
  RespuestaGeocodificacion,
  RespuestaLugares,
  ResultadoGeocodificacion,
} from '#shared/types/api'
import type { ClaveMensaje } from '~/i18n'

interface ItemLugar {
  label: string
  description?: string
  value: string
  lugar?: LugarResumen
  resultado?: ResultadoGeocodificacion
}

const props = withDefaults(
  defineProps<{
    /** Lugar elegido. */
    modelValue: LugarResumen | null
    /** Altura del mapa. */
    alturaMapa?: string
    /** Si el selector muestra el mapa y permite crear puntos. */
    conMapa?: boolean
  }>(),
  { alturaMapa: '220px', conMapa: true },
)

const emit = defineEmits<{
  'update:modelValue': [lugar: LugarResumen | null]
}>()

const { t } = useTexto()
const mensajeDeError = useMensajeError()

const lugaresLocales = ref<LugarResumen[]>([])
const resultados = ref<ResultadoGeocodificacion[]>([])
const cargando = ref(false)
const error = ref<string | null>(null)

const pinTemporal = ref<{ latitud: number; longitud: number } | null>(null)
const nombreTemporal = ref('')
const guardandoLugar = ref(false)

let temporizador: ReturnType<typeof setTimeout> | undefined

/** Valor que muestra el combobox: el lugar elegido del catálogo. */
const seleccion = computed<string | null>(() =>
  props.modelValue ? `local:${props.modelValue.idLugar}` : null,
)

/** Descripción legible de un lugar: dirección o tipo traducido. */
function descripcionDe(lugar: {
  direccion: string | null
  tipo: string
}): string {
  return (
    lugar.direccion ??
    t(`paquetes.lugares.tipos.${lugar.tipo}` as ClaveMensaje)
  )
}

/** Opciones del combobox: catálogo local y resultados externos. */
const items = computed<ItemLugar[]>(() => {
  const locales: ItemLugar[] = lugaresLocales.value.map((lugar) => ({
    label: lugar.nombre,
    description: descripcionDe(lugar),
    value: `local:${lugar.idLugar}`,
    lugar,
  }))

  const externos: ItemLugar[] = resultados.value.map((resultado, indice) => ({
    label: resultado.nombre,
    description: descripcionDe(resultado),
    value: `osm:${resultado.osmTipo}:${resultado.osmId}:${indice}`,
    resultado,
  }))

  return [...locales, ...externos]
})

/** Marcadores del mapa: el lugar elegido y el punto temporal. */
const marcadores = computed(() => {
  const lista: Array<{
    latitud: number
    longitud: number
    etiqueta?: string
    arrastrable?: boolean
  }> = []

  if (
    props.modelValue &&
    props.modelValue.latitud !== null &&
    props.modelValue.longitud !== null
  ) {
    lista.push({
      latitud: props.modelValue.latitud,
      longitud: props.modelValue.longitud,
      etiqueta: props.modelValue.nombre,
    })
  }

  if (pinTemporal.value) {
    lista.push({
      latitud: pinTemporal.value.latitud,
      longitud: pinTemporal.value.longitud,
      etiqueta: t('paquetes.mapa.crearLugar'),
      arrastrable: true,
    })
  }

  return lista
})

/** Carga el catálogo local una vez. */
onMounted(async () => {
  try {
    const datos = await $fetch<RespuestaLugares>('/api/admin/lugares')
    lugaresLocales.value = datos.lugares
  } catch {
    lugaresLocales.value = []
  }
})

/** El lugar ya elegido tiene que estar en la lista para mostrar su nombre. */
watch(
  () => props.modelValue,
  (lugar) => {
    if (lugar && !lugaresLocales.value.some((item) => item.idLugar === lugar.idLugar)) {
      lugaresLocales.value = [lugar, ...lugaresLocales.value]
    }
  },
  { immediate: true },
)

/** Busca en Photon con una pausa para no escribir en cada tecla. */
function alBuscar(texto: string) {
  if (temporizador) clearTimeout(temporizador)

  const consulta = texto.trim()
  if (consulta.length < 3) {
    resultados.value = []
    return
  }

  temporizador = setTimeout(async () => {
    cargando.value = true
    try {
      const datos = await $fetch<RespuestaGeocodificacion>('/api/geocodificar', {
        query: { q: consulta },
      })
      resultados.value = datos.resultados
    } catch {
      resultados.value = []
    } finally {
      cargando.value = false
    }
  }, 300)
}

/** Elige una opción: un lugar del catálogo o un resultado externo. */
async function alElegir(valor: string | null) {
  error.value = null

  if (!valor) {
    emit('update:modelValue', null)
    return
  }

  const item = items.value.find((opcion) => opcion.value === valor)
  if (!item) return

  if (item.lugar) {
    resultados.value = []
    emit('update:modelValue', item.lugar)
    return
  }

  if (!item.resultado) return

  try {
    guardandoLugar.value = true
    const lugar = await $fetch<LugarResumen>('/api/admin/lugares', {
      method: 'POST',
      body: item.resultado,
    })
    lugaresLocales.value = [...lugaresLocales.value, lugar]
    resultados.value = []
    emit('update:modelValue', lugar)
  } catch (fallo) {
    error.value = mensajeDeError(fallo)
  } finally {
    guardandoLugar.value = false
  }
}

/** Un clic en el mapa propone un lugar nuevo. */
function alClicMapa(punto: { latitud: number; longitud: number }) {
  pinTemporal.value = punto
  nombreTemporal.value = ''
}

/** Guarda el punto elegido en el mapa. */
async function guardarPunto() {
  if (!pinTemporal.value || nombreTemporal.value.trim().length < 2) return

  error.value = null
  guardandoLugar.value = true

  try {
    const lugar = await $fetch<LugarResumen>('/api/admin/lugares', {
      method: 'POST',
      body: {
        nombre: nombreTemporal.value.trim(),
        tipo: 'otro',
        latitud: pinTemporal.value.latitud,
        longitud: pinTemporal.value.longitud,
      },
    })
    lugaresLocales.value = [...lugaresLocales.value, lugar]
    emit('update:modelValue', lugar)
    pinTemporal.value = null
    nombreTemporal.value = ''
  } catch (fallo) {
    error.value = mensajeDeError(fallo)
  } finally {
    guardandoLugar.value = false
  }
}

onBeforeUnmount(() => {
  if (temporizador) clearTimeout(temporizador)
})
</script>

<template>
  <div class="space-y-3">
    <UInputMenu
      :model-value="seleccion"
      :items="items"
      :loading="cargando || guardandoLugar"
      :clear="true"
      value-key="value"
      icon="i-lucide-search"
      :placeholder="t('paquetes.mapa.buscar')"
      class="w-full"
      @update:model-value="alElegir"
      @update:search-term="alBuscar"
    >
      <template #empty>
        <p class="px-3 py-2 text-(--vt-texto-sm) text-(--vt-color-texto-suave)">
          {{ t('paquetes.mapa.sinResultados') }}
        </p>
      </template>
    </UInputMenu>

    <template v-if="conMapa">
      <BaseMapa
        :marcadores="marcadores"
        :altura="alturaMapa"
        interactivo
        @seleccionar="alClicMapa"
      />

      <p class="text-(--vt-texto-xs) text-(--vt-color-texto-suave)">
        {{ t('paquetes.mapa.instruccion') }}
      </p>
    </template>

    <div
      v-if="conMapa && pinTemporal"
      class="space-y-2 rounded-(--vt-radio-md) p-3 ring-1 ring-(--vt-color-borde)"
    >
      <UInput
        v-model="nombreTemporal"
        :placeholder="t('paquetes.mapa.nombreLugar')"
        class="w-full"
      />
      <div class="flex flex-wrap gap-2">
        <UButton
          type="button"
          size="xs"
          :label="t('paquetes.mapa.guardarLugar')"
          :loading="guardandoLugar"
          :disabled="nombreTemporal.trim().length < 2"
          @click="guardarPunto"
        />
        <UButton
          type="button"
          size="xs"
          variant="ghost"
          color="neutral"
          :label="t('paquetes.mapa.cancelar')"
          @click="pinTemporal = null"
        />
      </div>
    </div>

    <p v-if="error" class="text-(--vt-texto-sm) text-(--vt-color-error-600)">
      {{ error }}
    </p>
  </div>
</template>
