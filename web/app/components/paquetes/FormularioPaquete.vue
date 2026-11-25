<script setup lang="ts">
/**
 * Alta y edición de un paquete turístico.
 *
 * El código no se escribe: lo genera la base. El destino y las paradas son
 * lugares del catálogo. Los servicios marcados son la lista de lo que
 * cubre el precio y el itinerario es el relato día por día.
 */
import { CalendarDate } from '@internationalized/date'
import type {
  LugarResumen,
  PaqueteAdmin,
  RespuestaServicios,
} from '#shared/types/api'
import type { EstadoPaquete, TipoRecorrido } from '#shared/types/domain'
import type { ClaveMensaje } from '~/i18n'

interface RangoFechas {
  start: CalendarDate
  end: CalendarDate
}

/** Un día del itinerario en el formulario, con textos editables. */
interface DiaItinerario {
  titulo: string
  detalle: string
}

interface Formulario {
  nombre: string
  destino: LugarResumen | null
  origen: LugarResumen | null
  tipoRecorrido: TipoRecorrido
  descripcion: string
  duracionDias: number | null
  precioBase: number | null
  itinerario: DiaItinerario[]
  serviciosDetalle: string
  serviciosExcluidos: string
  paradas: LugarResumen[]
  servicios: number[]
  proveedores: PaqueteAdmin['proveedores']
  estado: EstadoPaquete
}

const props = defineProps<{
  abierto: boolean
  paquete: PaqueteAdmin | null
}>()

const emit = defineEmits<{
  'update:abierto': [valor: boolean]
  guardado: [paquete: PaqueteAdmin]
}>()

const { t } = useTexto()
const mensajeDeError = useMensajeError()
const { moneda } = useFormato()

const abierto = computed({
  get: () => props.abierto,
  set: (valor: boolean) => emit('update:abierto', valor),
})

const peticion = useRequestFetch()

const { data: dataServicios } = await useAsyncData<RespuestaServicios>(
  'servicios-admin',
  () => peticion<RespuestaServicios>('/api/admin/servicios'),
)

const serviciosDisponibles = computed(() => dataServicios.value?.servicios ?? [])

const formulario = reactive<Formulario>({
  nombre: '',
  destino: null,
  origen: null,
  tipoRecorrido: 'sencillo',
  descripcion: '',
  duracionDias: null,
  precioBase: null,
  itinerario: [],
  serviciosDetalle: '',
  serviciosExcluidos: '',
  paradas: [],
  servicios: [],
  proveedores: [],
  estado: 'borrador',
})

const guardando = ref(false)
const errorFormulario = ref<string | null>(null)
const mensajeValidacion = ref<string | null>(null)
const intentoPublicar = ref(false)
const rango = shallowRef<RangoFechas | null>(null)
const claveSelectorParada = ref(0)
const erroresCampo = reactive<Record<string, string | undefined>>({})

const editando = computed(() => props.paquete !== null)

const titulo = computed(() =>
  editando.value ? t('paquetes.editar') : t('paquetes.crear'),
)

const codigoMostrado = computed(
  () => props.paquete?.codigo ?? t('paquetes.form.codigoPendiente'),
)

const tiposRecorrido = computed<{ label: string; value: TipoRecorrido }[]>(() => [
  { label: t('paquetes.recorrido.sencillo'), value: 'sencillo' },
  { label: t('paquetes.recorrido.circuito'), value: 'circuito' },
])

const estadoEtiqueta = computed(() =>
  t(`paquetes.estados.${formulario.estado}` as ClaveMensaje),
)

const estadoColor = computed<'success' | 'warning' | 'neutral'>(() => {
  if (formulario.estado === 'activo') return 'success'
  if (formulario.estado === 'borrador') return 'warning'
  return 'neutral'
})

/** Días y noches que representa la duración actual. */
const duracionTexto = computed(() => {
  const dias = formulario.duracionDias ?? 0
  if (dias < 1) return ''
  return `${t('paquetes.duracion.dias', { dias })} · ${t(
    'paquetes.duracion.noches',
    { noches: Math.max(0, dias - 1) },
  )}`
})

/** Puntos del recorrido que se muestran en el mapa de resumen. */
const marcadoresRecorrido = computed(() => {
  const lista: Array<{ latitud: number; longitud: number; etiqueta: string }> = []
  const vistos = new Set<number>()

  const agregar = (lugar: LugarResumen | null) => {
    if (
      !lugar ||
      lugar.latitud === null ||
      lugar.longitud === null ||
      vistos.has(lugar.idLugar)
    ) {
      return
    }
    vistos.add(lugar.idLugar)
    lista.push({
      latitud: lugar.latitud,
      longitud: lugar.longitud,
      etiqueta: lugar.nombre,
    })
  }

  agregar(formulario.origen)
  formulario.paradas.forEach(agregar)
  agregar(formulario.destino)

  return lista
})

/** Campos que faltan para publicar, en el orden del formulario. */
const publicacionFaltantes = computed<ClaveMensaje[]>(() => {
  const faltantes: ClaveMensaje[] = []
  if (!formulario.destino) faltantes.push('paquetes.faltantes.destino')
  if (!formulario.descripcion.trim()) {
    faltantes.push('paquetes.faltantes.descripcion')
  }
  if (formulario.itinerario.length === 0) {
    faltantes.push('paquetes.faltantes.itinerario')
  }
  if (formulario.servicios.length === 0) {
    faltantes.push('paquetes.faltantes.servicios')
  }
  return faltantes
})

const mostrarFaltantes = computed(
  () =>
    (formulario.estado === 'activo' || intentoPublicar.value) &&
    publicacionFaltantes.value.length > 0,
)

const accionPrincipal = computed<{ label: string; estado: EstadoPaquete }>(() => {
  if (formulario.estado === 'activo') {
    return {
      label: t('paquetes.acciones.guardarCambios'),
      estado: 'activo',
    }
  }
  if (formulario.estado === 'inactivo') {
    return {
      label: t('paquetes.acciones.guardarCambios'),
      estado: 'inactivo',
    }
  }
  return {
    label: t('paquetes.acciones.guardarBorrador'),
    estado: 'borrador',
  }
})

const accionSecundaria = computed<{ label: string; estado: EstadoPaquete }>(() => {
  if (formulario.estado === 'activo') {
    return { label: t('paquetes.acciones.retirar'), estado: 'inactivo' }
  }
  if (formulario.estado === 'inactivo') {
    return { label: t('paquetes.acciones.reactivar'), estado: 'activo' }
  }
  return { label: t('paquetes.acciones.publicar'), estado: 'activo' }
})

/** Reinicia el formulario con el paquete en edición o uno vacío. */
function inicializar() {
  const paquete = props.paquete
  formulario.nombre = paquete?.nombre ?? ''
  formulario.destino = paquete?.destino ?? null
  formulario.origen = paquete?.origen ?? null
  formulario.tipoRecorrido = paquete?.tipoRecorrido ?? 'sencillo'
  formulario.descripcion = paquete?.descripcion ?? ''
  formulario.duracionDias = paquete?.duracionDias ?? null
  formulario.precioBase = paquete ? Number(paquete.precioBase) : null
  formulario.itinerario = (paquete?.itinerario ?? []).map((dia) => ({
    titulo: dia.titulo,
    detalle: dia.detalle ?? '',
  }))
  formulario.serviciosDetalle = paquete?.serviciosDetalle ?? ''
  formulario.serviciosExcluidos = paquete?.serviciosExcluidos ?? ''
  formulario.paradas = [...(paquete?.paradas ?? [])]
  formulario.servicios = (paquete?.servicios ?? []).map(
    (servicio) => servicio.idServicio,
  )
  formulario.proveedores = [...(paquete?.proveedores ?? [])]
  formulario.estado = paquete?.estado ?? 'borrador'
  rango.value = null
  intentoPublicar.value = false
  errorFormulario.value = null
  mensajeValidacion.value = null
  claveSelectorParada.value += 1
  limpiarErrores()
}

watch(
  () => props.abierto,
  (valor) => {
    if (valor) inicializar()
  },
)

watch(rango, () => {
  calcularDesdeRango()
})

function limpiarErrores() {
  for (const clave of Object.keys(erroresCampo)) {
    delete erroresCampo[clave]
  }
}

function alternarServicio(idServicio: number, valor: boolean | 'indeterminate') {
  if (valor === true && !formulario.servicios.includes(idServicio)) {
    formulario.servicios = [...formulario.servicios, idServicio]
  } else if (valor !== true) {
    formulario.servicios = formulario.servicios.filter(
      (id) => id !== idServicio,
    )
  }
}

function agregarParada(lugar: LugarResumen | null) {
  if (!lugar) return

  if (formulario.paradas.some((parada) => parada.idLugar === lugar.idLugar)) {
    erroresCampo.paradas = t('paquetes.errores.paradas')
    return
  }

  erroresCampo.paradas = undefined
  formulario.paradas.push(lugar)
  claveSelectorParada.value += 1
}

function quitarParada(indice: number) {
  formulario.paradas.splice(indice, 1)
}

/** Calcula la duración inclusiva a partir del rango elegido. */
function calcularDesdeRango() {
  if (!rango.value?.start || !rango.value.end) return

  const inicio = rango.value.start.toDate('UTC').getTime()
  const fin = rango.value.end.toDate('UTC').getTime()
  const dias = Math.round((fin - inicio) / 86_400_000) + 1

  if (dias >= 1 && dias <= 365) {
    formulario.duracionDias = dias
  }
}

function limpiarRango() {
  rango.value = null
}

function validar(estadoObjetivo: EstadoPaquete): boolean {
  limpiarErrores()
  let valido = true
  const nombre = formulario.nombre.trim()

  if (nombre.length < 3 || nombre.length > 150) {
    erroresCampo.nombre = t('paquetes.errores.nombre')
    valido = false
  }

  if (
    !formulario.duracionDias ||
    formulario.duracionDias < 1 ||
    formulario.duracionDias > 365
  ) {
    erroresCampo.duracion = t('paquetes.errores.duracion')
    valido = false
  }

  if (!formulario.precioBase || formulario.precioBase <= 0) {
    erroresCampo.precio = t('paquetes.errores.precio')
    valido = false
  }

  if (formulario.tipoRecorrido === 'circuito' && !formulario.origen) {
    erroresCampo.origen = t('paquetes.errores.origen')
    valido = false
  }

  const ids = formulario.paradas.map((parada) => parada.idLugar)
  if (new Set(ids).size !== ids.length) {
    erroresCampo.paradas = t('paquetes.errores.paradas')
    valido = false
  }

  if (estadoObjetivo === 'activo') {
    if (!formulario.destino) {
      erroresCampo.destino = t('paquetes.errores.destino')
      valido = false
    }
    if (!formulario.descripcion.trim()) {
      erroresCampo.descripcion = t('paquetes.errores.descripcion')
      valido = false
    }
    if (formulario.itinerario.length === 0) {
      erroresCampo.itinerario = t('paquetes.errores.itinerario')
      valido = false
    }
    if (formulario.servicios.length === 0) {
      erroresCampo.servicios = t('paquetes.errores.servicios')
      valido = false
    }
  }

  mensajeValidacion.value = valido ? null : t('paquetes.errores.revisar')
  return valido
}

/** Agrega, quita y reordena los días del itinerario (RN-PAQ-18). */
function agregarDia() {
  formulario.itinerario.push({ titulo: '', detalle: '' })
}

function quitarDia(indice: number) {
  formulario.itinerario.splice(indice, 1)
}

function moverDia(desde: number, hasta: number) {
  if (hasta < 0 || hasta >= formulario.itinerario.length) return
  const dia = formulario.itinerario[desde]
  if (!dia) return
  formulario.itinerario.splice(desde, 1)
  formulario.itinerario.splice(hasta, 0, dia)
}

const subirDia = (indice: number) => moverDia(indice, indice - 1)
const bajarDia = (indice: number) => moverDia(indice, indice + 1)

async function guardar(estadoObjetivo: EstadoPaquete) {
  errorFormulario.value = null
  intentoPublicar.value = estadoObjetivo === 'activo'

  if (!validar(estadoObjetivo)) return

  guardando.value = true

  const cuerpo = {
    nombre: formulario.nombre.trim(),
    idLugarDestino: formulario.destino?.idLugar ?? null,
    idLugarOrigen: formulario.origen?.idLugar ?? null,
    tipoRecorrido: formulario.tipoRecorrido,
    descripcion: formulario.descripcion,
    duracionDias: formulario.duracionDias,
    precioBase: formulario.precioBase,
    itinerario: formulario.itinerario.map((dia) => ({
      titulo: dia.titulo.trim(),
      detalle: dia.detalle.trim() || null,
    })),
    serviciosDetalle: formulario.serviciosDetalle,
    serviciosExcluidos: formulario.serviciosExcluidos,
    paradas: formulario.paradas.map((parada) => parada.idLugar),
    servicios: formulario.servicios,
    estado: estadoObjetivo,
  }

  try {
    const guardado = await $fetch<PaqueteAdmin>(
      editando.value
        ? `/api/admin/paquetes/${props.paquete!.idPaquete}`
        : '/api/admin/paquetes',
      {
        method: editando.value ? 'PATCH' : 'POST',
        body: cuerpo,
      },
    )

    emit('guardado', guardado)
    abierto.value = false
  } catch (fallo) {
    errorFormulario.value = mensajeDeError(fallo)
  } finally {
    guardando.value = false
  }
}
</script>

<template>
  <UModal
    v-model:open="abierto"
    :title="titulo"
    :ui="{ content: 'max-w-5xl' }"
  >
    <template #body>
      <form
        id="form-paquete"
        class="space-y-6"
        @submit.prevent="guardar(accionPrincipal.estado)"
      >
        <!-- Identidad -->
        <section class="space-y-4">
          <div class="flex flex-wrap items-center gap-2">
            <h3 class="text-(--vt-texto-base) font-(--vt-texto-peso-fuerte)">
              {{ t('paquetes.secciones.identidad') }}
            </h3>
            <UBadge
              :color="estadoColor"
              variant="subtle"
              :label="estadoEtiqueta"
            />
          </div>

          <div class="grid gap-4 sm:grid-cols-2">
            <UFormField
              :label="t('paquetes.form.nombre')"
              name="nombre"
              :error="erroresCampo.nombre"
              required
            >
              <UInput
                v-model="formulario.nombre"
                maxlength="150"
                class="w-full"
              />
            </UFormField>

            <UFormField
              :label="t('paquetes.form.codigo')"
              name="codigo"
              :help="t('paquetes.ayudaCodigo')"
            >
              <UInput :model-value="codigoMostrado" disabled class="w-full" />
            </UFormField>
          </div>
        </section>

        <USeparator />

        <!-- Ubicación y recorrido -->
        <section class="space-y-4">
          <h3 class="text-(--vt-texto-base) font-(--vt-texto-peso-fuerte)">
            {{ t('paquetes.secciones.ubicacion') }}
          </h3>

          <div class="grid gap-4 lg:grid-cols-2">
            <UFormField
              :label="t('paquetes.form.destino')"
              name="destino"
              :help="t('paquetes.ayudaDestino')"
              :error="erroresCampo.destino"
              :required="formulario.estado === 'activo'"
            >
              <PaquetesSelectorLugar v-model="formulario.destino" />
            </UFormField>

            <div class="space-y-4">
              <UFormField
                :label="t('paquetes.form.origen')"
                name="origen"
                :help="t('paquetes.ayudaOrigen')"
                :error="erroresCampo.origen"
              >
                <PaquetesSelectorLugar
                  v-model="formulario.origen"
                  :con-mapa="false"
                />
              </UFormField>

              <UFormField
                :label="t('paquetes.form.tipoRecorrido')"
                name="tipoRecorrido"
              >
                <USelect
                  v-model="formulario.tipoRecorrido"
                  :items="tiposRecorrido"
                  class="w-full"
                />
              </UFormField>
            </div>
          </div>

          <div class="space-y-2">
            <div class="flex flex-wrap items-center justify-between gap-2">
              <div>
                <p class="text-(--vt-texto-sm) font-(--vt-texto-peso-medio)">
                  {{ t('paquetes.form.paradas') }}
                </p>
                <p class="text-(--vt-texto-xs) text-(--vt-color-texto-suave)">
                  {{ t('paquetes.ayudaParadas') }}
                </p>
              </div>
            </div>

            <p
              v-if="formulario.paradas.length === 0"
              class="text-(--vt-texto-sm) text-(--vt-color-texto-suave)"
            >
              {{ t('paquetes.paradas.vacio') }}
            </p>

            <div
              v-for="(parada, indice) in formulario.paradas"
              :key="parada.idLugar"
              class="flex items-center justify-between gap-3 rounded-(--vt-radio-md) px-3 py-2 ring-1 ring-(--vt-color-borde)"
            >
              <span class="text-(--vt-texto-sm)">
                {{ indice + 1 }}. {{ parada.nombre }}
              </span>
              <UButton
                type="button"
                size="xs"
                variant="ghost"
                color="error"
                icon="i-lucide-trash-2"
                :aria-label="t('paquetes.paradas.quitar')"
                @click="quitarParada(indice)"
              />
            </div>

            <PaquetesSelectorLugar
              :key="claveSelectorParada"
              :model-value="null"
              :con-mapa="false"
              @update:model-value="agregarParada"
            />

            <p
              v-if="erroresCampo.paradas"
              class="text-(--vt-texto-sm) text-(--vt-color-error-600)"
            >
              {{ erroresCampo.paradas }}
            </p>
          </div>

          <div v-if="marcadoresRecorrido.length > 0" class="space-y-2">
            <p class="text-(--vt-texto-sm) font-(--vt-texto-peso-medio)">
              {{ t('paquetes.columnas.recorrido') }}
            </p>
            <BaseMapa
              :marcadores="marcadoresRecorrido"
              :ruta="marcadoresRecorrido"
              altura="180px"
            />
          </div>
        </section>

        <USeparator />

        <!-- Contenido -->
        <section class="space-y-4">
          <h3 class="text-(--vt-texto-base) font-(--vt-texto-peso-fuerte)">
            {{ t('paquetes.secciones.contenido') }}
          </h3>

          <UFormField
            :label="t('paquetes.form.descripcion')"
            name="descripcion"
            :error="erroresCampo.descripcion"
            :hint="`${formulario.descripcion.length}/2000`"
            :required="formulario.estado === 'activo'"
          >
            <UTextarea
              v-model="formulario.descripcion"
              :rows="3"
              maxlength="2000"
              class="w-full"
            />
          </UFormField>

          <div class="space-y-2">
            <div class="flex flex-wrap items-center justify-between gap-2">
              <div>
                <p class="text-(--vt-texto-sm) font-(--vt-texto-peso-medio)">
                  {{ t('paquetes.form.itinerario') }}
                </p>
                <p class="text-(--vt-texto-xs) text-(--vt-color-texto-suave)">
                  {{ t('paquetes.ayudaItinerario') }}
                </p>
              </div>
              <UButton
                type="button"
                size="xs"
                color="neutral"
                variant="soft"
                icon="i-lucide-plus"
                :label="t('paquetes.itinerario.agregar')"
                @click="agregarDia"
              />
            </div>

            <p
              v-if="formulario.itinerario.length === 0"
              class="text-(--vt-texto-sm) text-(--vt-color-texto-suave)"
            >
              {{ t('paquetes.itinerario.vacio') }}
            </p>

            <div
              v-for="(dia, indice) in formulario.itinerario"
              :key="indice"
              class="rounded-(--vt-radio-md) px-3 py-2 ring-1 ring-(--vt-color-borde)"
            >
              <div class="flex items-start gap-2">
                <div class="flex flex-col gap-0.5 pt-1">
                  <UButton
                    type="button"
                    size="xs"
                    variant="ghost"
                    color="neutral"
                    icon="i-lucide-chevron-up"
                    :disabled="indice === 0"
                    :aria-label="t('paquetes.itinerario.subir')"
                    @click="subirDia(indice)"
                  />
                  <UButton
                    type="button"
                    size="xs"
                    variant="ghost"
                    color="neutral"
                    icon="i-lucide-chevron-down"
                    :disabled="indice === formulario.itinerario.length - 1"
                    :aria-label="t('paquetes.itinerario.bajar')"
                    @click="bajarDia(indice)"
                  />
                </div>

                <div class="flex-1 space-y-1.5">
                  <div class="flex items-center gap-2">
                    <span
                      class="flex size-6 shrink-0 items-center justify-center rounded-full bg-(--vt-color-marca-100) text-xs font-(--vt-texto-peso-medio) text-(--vt-color-marca-800)"
                    >
                      {{ indice + 1 }}
                    </span>
                    <UInput
                      v-model="dia.titulo"
                      :placeholder="t('paquetes.itinerario.titulo')"
                      maxlength="150"
                      size="sm"
                      class="w-full"
                      :required="formulario.estado === 'activo'"
                    />
                  </div>
                  <UTextarea
                    v-model="dia.detalle"
                    :placeholder="t('paquetes.itinerario.detalle')"
                    :rows="2"
                    maxlength="4000"
                    size="sm"
                    class="w-full"
                  />
                </div>

                <UButton
                  type="button"
                  size="xs"
                  variant="ghost"
                  color="error"
                  icon="i-lucide-trash-2"
                  class="mt-1"
                  :aria-label="t('paquetes.itinerario.quitar')"
                  @click="quitarDia(indice)"
                />
              </div>
            </div>

            <p
              v-if="erroresCampo.itinerario"
              class="text-(--vt-texto-sm) text-(--vt-color-error-600)"
            >
              {{ erroresCampo.itinerario }}
            </p>
          </div>

          <UFormField
            :label="t('paquetes.form.servicios')"
            name="servicios"
            :help="t('paquetes.ayudaServicios')"
            :error="erroresCampo.servicios"
            :required="formulario.estado === 'activo'"
          >
            <div class="grid gap-2 sm:grid-cols-2">
              <UCheckbox
                v-for="servicio in serviciosDisponibles"
                :key="servicio.idServicio"
                :id="`paquete-servicio-${servicio.idServicio}`"
                :name="`paquete-servicio-${servicio.idServicio}`"
                :model-value="formulario.servicios.includes(servicio.idServicio)"
                :label="servicio.nombre"
                @update:model-value="
                  (valor) => alternarServicio(servicio.idServicio, valor)
                "
              />
            </div>
          </UFormField>

          <div class="grid gap-4 sm:grid-cols-2">
            <UFormField
              :label="t('paquetes.form.serviciosDetalle')"
              name="serviciosDetalle"
              :help="t('paquetes.ayudaServiciosDetalle')"
            >
              <UTextarea
                v-model="formulario.serviciosDetalle"
                :rows="2"
                maxlength="2000"
                class="w-full"
              />
            </UFormField>

            <UFormField
              :label="t('paquetes.form.serviciosExcluidos')"
              name="serviciosExcluidos"
              :help="t('paquetes.ayudaServiciosExcluidos')"
            >
              <UTextarea
                v-model="formulario.serviciosExcluidos"
                :rows="2"
                maxlength="2000"
                class="w-full"
              />
            </UFormField>
          </div>
        </section>

        <USeparator />

        <!-- Datos comerciales -->
        <section class="space-y-4">
          <h3 class="text-(--vt-texto-base) font-(--vt-texto-peso-fuerte)">
            {{ t('paquetes.secciones.comercial') }}
          </h3>

          <div class="grid gap-4 sm:grid-cols-2">
            <UFormField
              :label="t('paquetes.form.duracion')"
              name="duracion"
              :help="t('paquetes.ayudaDuracion')"
              :error="erroresCampo.duracion"
              :hint="duracionTexto"
              required
            >
              <UInputNumber
                v-model="formulario.duracionDias"
                :min="1"
                :max="365"
                :step="1"
                :increment="false"
                :decrement="false"
                class="w-full"
              />
            </UFormField>

            <UFormField
              :label="t('paquetes.form.precio')"
              name="precio"
              :help="t('paquetes.ayudaPrecio')"
              :error="erroresCampo.precio"
              required
            >
              <BaseCampoMoneda v-model="formulario.precioBase" />
            </UFormField>
          </div>

          <UFormField
            :label="t('paquetes.form.rangoFechas')"
            name="rango"
            :help="t('paquetes.duracion.inclusivos')"
          >
            <div class="flex flex-col gap-2 sm:flex-row">
              <UInputDate v-model="rango" range class="flex-1" />
              <UButton
                type="button"
                variant="soft"
                color="neutral"
                :label="t('paquetes.duracion.limpiar')"
                :disabled="!rango"
                @click="limpiarRango"
              />
            </div>
          </UFormField>
        </section>

        <USeparator />

        <!-- Proveedores -->
        <section class="space-y-3">
          <h3 class="text-(--vt-texto-base) font-(--vt-texto-peso-fuerte)">
            {{ t('paquetes.form.proveedores') }}
          </h3>
          <p class="text-(--vt-texto-sm) text-(--vt-color-texto-suave)">
            {{ t('paquetes.ayudaProveedores') }}
          </p>

          <p
            v-if="formulario.proveedores.length === 0"
            class="text-(--vt-texto-sm) text-(--vt-color-texto-suave)"
          >
            {{ t('paquetes.sinProveedores') }}
          </p>

          <ul v-else class="space-y-2">
            <li
              v-for="proveedor in formulario.proveedores"
              :key="proveedor.idProveedor"
              class="flex flex-wrap items-baseline justify-between gap-2 rounded-(--vt-radio-md) px-3 py-2 ring-1 ring-(--vt-color-borde)"
            >
              <div>
                <p class="text-(--vt-texto-sm) font-(--vt-texto-peso-medio)">
                  {{ proveedor.nombre }}
                </p>
                <p class="text-(--vt-texto-xs) text-(--vt-color-texto-suave)">
                  {{ t(`paquetes.proveedores.tipos.${proveedor.tipo}` as ClaveMensaje) }}
                  <span v-if="proveedor.detalle"> · {{ proveedor.detalle }}</span>
                </p>
              </div>
              <span class="text-(--vt-texto-sm) tabular-nums">
                {{ moneda(proveedor.costo) }}
              </span>
            </li>
          </ul>
        </section>

        <USeparator />

        <!-- Publicación -->
        <section
          v-if="mostrarFaltantes || formulario.estado === 'activo'"
          class="space-y-3"
        >
          <h3 class="text-(--vt-texto-base) font-(--vt-texto-peso-fuerte)">
            {{ t('paquetes.secciones.publicacion') }}
          </h3>

          <UAlert
            v-if="
              formulario.estado === 'activo' &&
              publicacionFaltantes.length === 0
            "
            color="success"
            variant="soft"
            :title="t('paquetes.publicacion.completo')"
          />

          <UAlert
            v-if="mostrarFaltantes"
            color="warning"
            variant="soft"
            :title="t('paquetes.faltantes.titulo')"
            :description="
              publicacionFaltantes.map((clave) => t(clave)).join(', ')
            "
          />
        </section>
      </form>
    </template>

    <template #footer>
      <div class="flex flex-wrap items-center justify-end gap-2">
        <p
          v-if="errorFormulario || mensajeValidacion"
          class="me-auto text-(--vt-texto-sm) text-(--vt-color-error-600)"
        >
          {{ errorFormulario ?? mensajeValidacion }}
        </p>
        <UButton
          type="button"
          variant="ghost"
          color="neutral"
          :label="t('comun.cancelar')"
          @click="abierto = false"
        />
        <UButton
          type="button"
          variant="soft"
          color="neutral"
          :label="accionSecundaria.label"
          :loading="guardando"
          @click="guardar(accionSecundaria.estado)"
        />
        <UButton
          type="submit"
          form="form-paquete"
          color="primary"
          :loading="guardando"
          :label="accionPrincipal.label"
        />
      </div>
    </template>
  </UModal>
</template>
