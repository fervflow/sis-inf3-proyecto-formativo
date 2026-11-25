<script setup lang="ts">
/**
 * Formulario de alta y edición de una salida programada.
 *
 * Vive en el modal de «Próximas salidas». Recibe la salida a editar, o
 * `null` para el alta, y el catálogo de paquetes para elegir, completar el
 * precio base y ajustar el retorno a la duración. Guarda contra la API y
 * emite la salida guardada; la vista recarga y avisa. Las asignaciones
 * operativas de proveedores de la salida se editan en una lista propia
 * (RN-SAL-23).
 */
import type {
  PaqueteAdmin,
  ProveedorAdmin,
  SalidaAdmin,
} from '#shared/types/api'
import type { EstadoSalida, TipoProveedor } from '#shared/types/domain'
import type { ClaveMensaje } from '~/i18n'

const props = defineProps<{
  /** Abre el modal. */
  open: boolean
  /** Salida a editar, o `null` para programar una salida nueva. */
  salida: SalidaAdmin | null
  /** Catálogo de paquetes del administrador. */
  paquetes: PaqueteAdmin[]
}>()

const emit = defineEmits<{
  'update:open': [valor: boolean]
  /** La salida quedó guardada. */
  guardada: [salida: SalidaAdmin]
}>()

const peticion = useRequestFetch()
const { t } = useTexto()
const mensajeDeError = useMensajeError()
const { moneda } = useFormato()

const editando = computed(() => props.salida !== null)

const guardando = ref(false)
const errorFormulario = ref<string | null>(null)
const cargandoProveedores = ref(false)
const proveedores = ref<ProveedorAdmin[]>([])

/** Una asignación en edición, con los textos del formulario. */
interface AsignacionFormulario {
  idProveedor: number
  servicio: TipoProveedor
  detalle: string
}

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
  asignaciones: [] as AsignacionFormulario[],
})

const paqueteSeleccionado = computed(() =>
  props.paquetes.find((paquete) => paquete.idPaquete === formulario.idPaquete),
)

/** El precio de la salida parte del precio base del paquete. */
const ayudaPrecio = computed(() => {
  const base = paqueteSeleccionado.value?.precioBase
  return base
    ? t('salidas.ayudaPrecio', { precio: moneda(base) })
    : t('salidas.ayudaPrecioVacio')
})

const estados = computed<{ label: string; value: EstadoSalida }[]>(() => {
  const actual = props.salida?.estado
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
  props.paquetes
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

/** Cada vez que se abre, el formulario arranca limpio con los datos dados. */
watch(
  () => props.open,
  (abierto) => {
    if (!abierto) return
    errorFormulario.value = null

    cargarProveedores()

    if (props.salida) {
      formulario.idPaquete = props.salida.idPaquete
      formulario.fechaSalida = props.salida.fechaSalida
      formulario.fechaRetorno = props.salida.fechaRetorno
      formulario.cupoMaximo = props.salida.cupoMaximo
      formulario.precio = Number(props.salida.precio)
      formulario.puntoEncuentro = props.salida.puntoEncuentro ?? ''
      formulario.estado = props.salida.estado
      formulario.observaciones = props.salida.observaciones ?? ''
      formulario.motivo = ''
      formulario.asignaciones = props.salida.asignaciones.map((asignacion) => ({
        idProveedor: asignacion.idProveedor,
        servicio: asignacion.servicio,
        detalle: asignacion.detalle ?? '',
      }))
      return
    }

    const inicial = props.paquetes.find(
      (paquete) => paquete.estado === 'activo',
    )
    formulario.idPaquete = inicial?.idPaquete ?? 0
    formulario.fechaSalida = hoy()
    formulario.fechaRetorno = hoy()
    formulario.cupoMaximo = 10
    formulario.precio = inicial ? Number(inicial.precioBase) : null
    formulario.puntoEncuentro = ''
    formulario.estado = 'programada'
    formulario.observaciones = ''
    formulario.motivo = ''
    formulario.asignaciones = []
    ajustarRetorno()
  },
  { immediate: true },
)

/** Los proveedores activos para las asignaciones (RN-SAL-23). */
async function cargarProveedores() {
  cargandoProveedores.value = true
  try {
    const respuesta = await peticion<{ proveedores: ProveedorAdmin[] }>(
      '/api/admin/proveedores',
    )
    proveedores.value = respuesta.proveedores.filter(
      (proveedor) => proveedor.estado === 'activo',
    )
  } catch {
    proveedores.value = []
  } finally {
    cargandoProveedores.value = false
  }
}

const proveedoresDisponibles = computed(() =>
  proveedores.value.map((proveedor) => ({
    label: proveedor.nombre,
    value: proveedor.idProveedor,
  })),
)

/** Los tipos declarados del proveedor de una asignación (RN-PRV-02). */
function tiposDe(idProveedor: number): TipoProveedor[] {
  return (
    proveedores.value.find((proveedor) => proveedor.idProveedor === idProveedor)
      ?.tipos ?? []
  )
}

const tiposDeAsignacion = (asignacion: AsignacionFormulario) =>
  tiposDe(asignacion.idProveedor).map((tipo) => ({
    label: t(`proveedores.tipos.${tipo}` as ClaveMensaje),
    value: tipo,
  }))

function agregarAsignacion() {
  const primero = proveedores.value.find(
    (proveedor) =>
      !formulario.asignaciones.some(
        (asignacion) => asignacion.idProveedor === proveedor.idProveedor,
      ),
  )
  const servicio = primero?.tipos[0]
  if (!primero || !servicio) return
  formulario.asignaciones.push({
    idProveedor: primero.idProveedor,
    servicio,
    detalle: '',
  })
}

function quitarAsignacion(indice: number) {
  formulario.asignaciones.splice(indice, 1)
}

/** Al cambiar el proveedor, el servicio pasa a uno de sus declarados. */
function cambiarProveedor(indice: number, idProveedor: number) {
  const asignacion = formulario.asignaciones[indice]
  if (!asignacion) return
  asignacion.idProveedor = idProveedor
  const tipos = tiposDe(idProveedor)
  const servicio = tipos[0]
  if (!tipos.includes(asignacion.servicio) && servicio) {
    asignacion.servicio = servicio
  }
}

/** El mismo proveedor no se repite en la salida (RN-SAL-23). */
const asignacionesRepetidas = computed(
  () =>
    new Set(formulario.asignaciones.map((a) => a.idProveedor)).size !==
    formulario.asignaciones.length,
)

const asignacionesInvalidas = computed(
  () =>
    formulario.asignaciones.some(
      (asignacion) => !asignacion.idProveedor || !asignacion.servicio,
    ),
)

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
  if (asignacionesRepetidas.value || asignacionesInvalidas.value) {
    errorFormulario.value = t('salidas.errores.asignaciones')
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
    asignaciones: formulario.asignaciones.map((asignacion) => ({
      idProveedor: asignacion.idProveedor,
      servicio: asignacion.servicio,
      detalle: asignacion.detalle.trim() || null,
    })),
  }

  try {
    const guardada = await $fetch<SalidaAdmin>(
      editando.value
        ? `/api/admin/salidas/${props.salida?.idSalida}`
        : '/api/admin/salidas',
      {
        method: editando.value ? 'PATCH' : 'POST',
        body: cuerpo,
      },
    )

    emit('guardada', guardada)
    emit('update:open', false)
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
</script>

<template>
  <UModal
    :open="open"
    :title="tituloFormulario"
    :ui="{ content: 'max-w-3xl' }"
    @update:open="emit('update:open', $event)"
  >
    <template #body>
      <form id="form-salida" class="space-y-4" @submit.prevent="guardar">
        <UFormField :label="t('salidas.form.paquete')" name="paquete">
          <USelect
            v-model="formulario.idPaquete"
            :items="paquetesDisponibles"
            class="w-full"
            :disabled="editando"
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

        <!--
          Asignaciones operativas de proveedores (RN-SAL-23): el guía
          titular, la unidad concreta. Opcional, sin costos.
        -->
        <div class="space-y-2">
          <div class="flex flex-wrap items-center justify-between gap-2">
            <div>
              <p class="text-(--vt-texto-sm) font-(--vt-texto-peso-medio)">
                {{ t('salidas.asignaciones.titulo') }}
              </p>
              <p class="text-(--vt-texto-xs) text-(--vt-color-texto-suave)">
                {{ t('salidas.asignaciones.ayuda') }}
              </p>
            </div>
            <UButton
              type="button"
              size="xs"
              color="neutral"
              variant="soft"
              icon="i-lucide-plus"
              :label="t('salidas.asignaciones.agregar')"
              :disabled="cargandoProveedores || proveedores.length === 0"
              @click="agregarAsignacion"
            />
          </div>

          <p
            v-if="formulario.asignaciones.length === 0"
            class="text-(--vt-texto-sm) text-(--vt-color-texto-suave)"
          >
            {{ t('salidas.asignaciones.vacio') }}
          </p>

          <div
            v-for="(asignacion, indice) in formulario.asignaciones"
            :key="indice"
            class="grid items-center gap-2 rounded-(--vt-radio-md) px-3 py-2 ring-1 ring-(--vt-color-borde) sm:grid-cols-[1fr_auto_1fr_auto]"
          >
            <USelect
              :model-value="asignacion.idProveedor"
              :items="proveedoresDisponibles"
              size="sm"
              class="w-full"
              @update:model-value="
                (valor) => cambiarProveedor(indice, Number(valor))
              "
            />
            <USelect
              v-model="asignacion.servicio"
              :items="tiposDeAsignacion(asignacion)"
              size="sm"
              class="w-full sm:w-36"
            />
            <UInput
              v-model="asignacion.detalle"
              :placeholder="t('salidas.asignaciones.detalle')"
              maxlength="200"
              size="sm"
              class="w-full"
            />
            <UButton
              type="button"
              size="xs"
              variant="ghost"
              color="error"
              icon="i-lucide-trash-2"
              :aria-label="t('salidas.asignaciones.quitar')"
              @click="quitarAsignacion(indice)"
            />
          </div>

          <p
            v-if="asignacionesRepetidas"
            class="text-(--vt-texto-sm) text-(--vt-color-error-600)"
          >
            {{ t('salidas.errores.asignacionesRepetidas') }}
          </p>
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
          :label="t('comun.cancelar')"
          @click="emit('update:open', false)"
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
</template>
