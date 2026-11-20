<script setup lang="ts">
/**
 * Mapa de OpenStreetMap con marcadores.
 *
 * Se usa para previsualizar el lugar de un paquete y, si `interactivo`,
 * para elegir un punto con un clic. Leaflet se carga solo en el cliente:
 * toca `window` y no puede ejecutarse durante el renderizado del servidor.
 */
import 'leaflet/dist/leaflet.css'
import type { Map as MapaLeaflet, LayerGroup } from 'leaflet'

interface MarcadorMapa {
  latitud: number
  longitud: number
  etiqueta?: string
  arrastrable?: boolean
}

const props = withDefaults(
  defineProps<{
    marcadores?: MarcadorMapa[]
    altura?: string
    interactivo?: boolean
    zoom?: number
  }>(),
  {
    marcadores: () => [],
    altura: '220px',
    interactivo: false,
    zoom: 13,
  },
)

const emit = defineEmits<{
  seleccionar: [punto: { latitud: number; longitud: number }]
}>()

const { t } = useTexto()
const contenedor = ref<HTMLDivElement | null>(null)

let mapa: MapaLeaflet | undefined
let capa: LayerGroup | undefined
let L: typeof import('leaflet') | undefined

const CENTRO = { latitud: -19.5836, longitud: -65.7531 }

/** Icono propio: evita los recursos por defecto de Leaflet. */
function crearIcono() {
  if (!L) return undefined
  return L.divIcon({
    className: '',
    html: '<span style="display:block;width:16px;height:16px;border-radius:9999px;background:var(--vt-color-marca-600);border:2px solid white;box-shadow:0 1px 4px rgba(0,0,0,.35)"></span>',
    iconSize: [16, 16],
    iconAnchor: [8, 8],
  })
}

/** Dibuja los marcadores y encuadra el mapa. */
function dibujar() {
  if (!mapa || !capa || !L) return

  capa.clearLayers()

  for (const marcador of props.marcadores) {
    const icono = crearIcono()
    if (!icono) continue

    const punto = L.marker([marcador.latitud, marcador.longitud], {
      icon: icono,
      draggable: marcador.arrastrable === true,
    })

    if (marcador.etiqueta) {
      punto.bindTooltip(marcador.etiqueta, { direction: 'top' })
    }

    punto.on('dragend', () => {
      const posicion = punto.getLatLng()
      emit('seleccionar', {
        latitud: posicion.lat,
        longitud: posicion.lng,
      })
    })

    punto.addTo(capa)
  }

  const primero = props.marcadores[0]
  if (props.marcadores.length > 1) {
    const limites = L.latLngBounds(
      props.marcadores.map((marcador) => [marcador.latitud, marcador.longitud]),
    )
    mapa.fitBounds(limites, { padding: [28, 28], maxZoom: 12 })
  } else if (primero) {
    mapa.setView([primero.latitud, primero.longitud], props.zoom)
  } else {
    mapa.setView([CENTRO.latitud, CENTRO.longitud], 12)
  }

  requestAnimationFrame(() => mapa?.invalidateSize())
}

onMounted(async () => {
  if (!contenedor.value) return

  const modulo = await import('leaflet')
  L =
    (modulo as unknown as { default?: typeof import('leaflet') }).default ??
    modulo

  mapa = L.map(contenedor.value, {
    zoomControl: false,
    attributionControl: true,
    scrollWheelZoom: false,
  }).setView([CENTRO.latitud, CENTRO.longitud], 12)

  L.control
    .zoom({
      zoomInTitle: t('paquetes.mapa.acercar'),
      zoomOutTitle: t('paquetes.mapa.alejar'),
    })
    .addTo(mapa)

  L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution:
      '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
  }).addTo(mapa)

  capa = L.layerGroup().addTo(mapa)

  if (props.interactivo) {
    mapa.on('click', (evento) => {
      emit('seleccionar', {
        latitud: evento.latlng.lat,
        longitud: evento.latlng.lng,
      })
    })
  }

  dibujar()
})

watch(
  () => props.marcadores,
  () => dibujar(),
  { deep: true },
)

onBeforeUnmount(() => {
  mapa?.remove()
  mapa = undefined
  capa = undefined
})
</script>

<template>
  <div
    ref="contenedor"
    class="z-0 w-full overflow-hidden rounded-(--vt-radio-md) ring-1 ring-(--vt-color-borde)"
    :style="{ height: altura }"
    role="region"
    :aria-label="
      marcadores.length > 0
        ? t('paquetes.mapa.ariaConUbicacion')
        : t('paquetes.mapa.ariaSinUbicacion')
    "
  />
</template>
