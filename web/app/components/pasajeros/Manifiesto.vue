<script setup lang="ts">
/**
 * Manifiesto de pasajeros de una reserva (HU-12).
 *
 * Muestra los pasajeros registrados contra la cantidad declarada y
 * guarda la lista completa: la cantidad pasa a ser la del manifiesto y
 * la base revalida cupos, monto y pagos comprometidos (RN-RES-21). En el
 * canal web el manifiesto no declara más pasajeros que los solicitados;
 * el canal personal puede ampliarlo. La cuenta de cliente puede
 * agregarse con su propia ficha. El resultado se avisa con un aviso
 * flotante, igual que el resto de las acciones.
 */
import type { ClaveMensaje } from '~/i18n'
import type {
  RespuestaCuenta,
  RespuestaPasajeros,
  ReservaResumen,
} from '#shared/types/api'
import type { TipoDocumento } from '#shared/types/domain'

const props = defineProps<{
  /** La reserva cuyo manifiesto se edita. */
  reserva: ReservaResumen
}>()

const emit = defineEmits<{
  /** El manifiesto cambió; la vista recarga sus datos. */
  cambio: []
  /** La persona canceló; la vista cierra el formulario. */
  cancelar: []
}>()

const { t } = useTexto()
const mensajeDeError = useMensajeError()
const avisos = useAvisos()

const cargando = ref(true)
const guardando = ref(false)
const error = ref<string | null>(null)
const manifiesto = ref<RespuestaPasajeros | null>(null)
const cuenta = ref<RespuestaCuenta | null>(null)

/** Las filas editables del manifiesto. */
const filas = ref<
  Array<{
    tipoDocumento: TipoDocumento
    numeroDocumento: string
    nombres: string
    apellidos: string
    fechaNacimiento: string
  }>
>([])

const tiposDocumento = computed(() =>
  (['CI', 'NIT', 'PASAPORTE', 'OTRO'] as const).map((tipo) => ({
    label: t(`clientes.tipos.${tipo}` as ClaveMensaje),
    value: tipo,
  })),
)

/** La reserva admite manifiesto: pendiente o confirmada (RN-RES-20). */
const editable = computed(
  () =>
    props.reserva.estado === 'pendiente' || props.reserva.estado === 'confirmada',
)

const coinciden = computed(
  () => filas.value.length === (manifiesto.value?.cantidadDeclarada ?? 0),
)

/**
 * El canal web no declara más pasajeros que los solicitados
 * (RN-RES-21); el canal personal puede ampliar el grupo.
 */
const puedeAgregar = computed(
  () =>
    editable.value &&
    (props.reserva.origen !== 'web' ||
      filas.value.length < (manifiesto.value?.cantidadDeclarada ?? 0)),
)

/** La ficha del cliente en sesión, para agregarse como pasajero. */
const fichaPropia = computed(() => {
  const usuario = cuenta.value?.usuario
  if (!usuario || usuario.rol !== 'CLIENTE') return null
  return usuario.ficha
})

/** La ficha ya está en el manifiesto, por documento. */
const fichaAgregada = computed(() => {
  const ficha = fichaPropia.value
  if (!ficha) return false
  return filas.value.some(
    (fila) =>
      fila.tipoDocumento === ficha.tipoDocumento &&
      fila.numeroDocumento.trim().toUpperCase() ===
        ficha.numeroDocumento.toUpperCase(),
  )
})

async function cargar() {
  cargando.value = true
  error.value = null
  try {
    manifiesto.value = await $fetch<RespuestaPasajeros>(
      `/api/reservas/${props.reserva.idReserva}/pasajeros`,
    )
    filas.value = (manifiesto.value?.pasajeros ?? []).map((pasajero) => ({
      tipoDocumento: pasajero.tipoDocumento,
      numeroDocumento: pasajero.numeroDocumento,
      nombres: pasajero.nombres,
      apellidos: pasajero.apellidos,
      fechaNacimiento: pasajero.fechaNacimiento ?? '',
    }))
  } catch (fallo) {
    error.value = mensajeDeError(fallo)
  } finally {
    cargando.value = false
  }
}

function agregar() {
  filas.value.push({
    tipoDocumento: 'CI',
    numeroDocumento: '',
    nombres: '',
    apellidos: '',
    fechaNacimiento: '',
  })
}

/** Agrega la ficha del cliente en sesión como pasajero (HU-12). */
function agregarme() {
  const ficha = fichaPropia.value
  if (!ficha) return
  filas.value.push({
    tipoDocumento: ficha.tipoDocumento,
    numeroDocumento: ficha.numeroDocumento,
    nombres: ficha.nombres,
    apellidos: ficha.apellidos,
    fechaNacimiento: ficha.fechaNacimiento ?? '',
  })
}

function quitar(indice: number) {
  filas.value.splice(indice, 1)
}

async function guardar() {
  guardando.value = true
  error.value = null
  try {
    manifiesto.value = await $fetch<RespuestaPasajeros>(
      `/api/reservas/${props.reserva.idReserva}/pasajeros`,
      {
        method: 'PUT',
        body: {
          pasajeros: filas.value.map((fila) => ({
            tipoDocumento: fila.tipoDocumento,
            numeroDocumento: fila.numeroDocumento.trim(),
            nombres: fila.nombres.trim(),
            apellidos: fila.apellidos.trim(),
            fechaNacimiento: fila.fechaNacimiento || undefined,
          })),
        },
      },
    )
    filas.value = (manifiesto.value?.pasajeros ?? []).map((pasajero) => ({
      tipoDocumento: pasajero.tipoDocumento,
      numeroDocumento: pasajero.numeroDocumento,
      nombres: pasajero.nombres,
      apellidos: pasajero.apellidos,
      fechaNacimiento: pasajero.fechaNacimiento ?? '',
    }))
    avisos.exito('pasajeros.guardadoOk', {
      registrados: manifiesto.value?.pasajeros.length ?? 0,
      declarada: manifiesto.value?.cantidadDeclarada ?? 0,
    })
    emit('cambio')
  } catch (fallo) {
    error.value = mensajeDeError(fallo)
  } finally {
    guardando.value = false
  }
}

await cargar()

// La cuenta se consulta aparte: solo el canal web trae ficha propia.
$fetch<RespuestaCuenta>('/api/cuenta')
  .then((respuesta) => (cuenta.value = respuesta))
  .catch(() => (cuenta.value = null))

defineExpose({ recargar: cargar })
</script>

<template>
  <div class="space-y-4">
    <div
      class="rounded-(--vt-radio-md) px-3 py-2 text-(length:--vt-texto-sm) ring-1 ring-(--vt-color-borde)"
    >
      <p class="font-(--vt-texto-peso-medio)">
        {{ reserva.paquete }} · {{ reserva.codigo }}
      </p>
      <p
        class="text-(length:--vt-texto-xs)"
        :class="coinciden ? 'text-(--vt-color-texto-suave)' : 'text-(--vt-color-error-600)'"
      >
        {{
          t('pasajeros.conteoSobre', {
            registrados: filas.length,
            declarada: manifiesto?.cantidadDeclarada ?? reserva.cantidadPasajeros,
          })
        }}
        ·
        {{
          editable
            ? t('pasajeros.editable')
            : t('pasajeros.noEditable')
        }}
      </p>
    </div>

    <table v-if="filas.length > 0" class="w-full text-(length:--vt-texto-sm)">
      <thead class="text-left text-xs text-(--vt-color-texto-suave)">
        <tr>
          <th class="pb-2">{{ t('pasajeros.columnas.tipo') }}</th>
          <th class="pb-2">{{ t('pasajeros.columnas.documento') }}</th>
          <th class="pb-2">{{ t('pasajeros.columnas.nombres') }}</th>
          <th class="pb-2">{{ t('pasajeros.columnas.apellidos') }}</th>
          <th v-if="editable" class="pb-2"></th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="(fila, indice) in filas"
          :key="indice"
          class="border-t border-(--vt-color-borde)"
        >
          <td class="py-1.5 pr-2">
            <USelect
              v-if="editable"
              v-model="fila.tipoDocumento"
              :items="tiposDocumento"
              size="xs"
              class="w-28"
            />
            <span v-else>{{ fila.tipoDocumento }}</span>
          </td>
          <td class="py-1.5 pr-2">
            <UInput
              v-if="editable"
              v-model="fila.numeroDocumento"
              size="xs"
              class="w-36"
            />
            <span v-else class="tabular-nums">{{ fila.numeroDocumento }}</span>
          </td>
          <td class="py-1.5 pr-2">
            <UInput
              v-if="editable"
              v-model="fila.nombres"
              size="xs"
              class="w-36"
            />
            <span v-else>{{ fila.nombres }}</span>
          </td>
          <td class="py-1.5 pr-2">
            <UInput
              v-if="editable"
              v-model="fila.apellidos"
              size="xs"
              class="w-36"
            />
            <span v-else>{{ fila.apellidos }}</span>
          </td>
          <td v-if="editable" class="py-1.5 text-right">
            <UButton
              size="xs"
              color="error"
              variant="ghost"
              icon="i-lucide-trash-2"
              :aria-label="t('pasajeros.quitar')"
              @click="quitar(indice)"
            />
          </td>
        </tr>
      </tbody>
    </table>

    <p v-else class="text-(length:--vt-texto-sm) text-(--vt-color-texto-suave)">
      {{ t('pasajeros.vacio') }}
    </p>

    <div v-if="editable" class="flex flex-wrap items-center gap-2">
      <UButton
        size="xs"
        color="neutral"
        variant="soft"
        icon="i-lucide-user-plus"
        :label="t('pasajeros.agregar')"
        :disabled="!puedeAgregar"
        @click="agregar()"
      />
      <UButton
        v-if="fichaPropia"
        size="xs"
        color="neutral"
        variant="soft"
        icon="i-lucide-id-card"
        :label="t('pasajeros.agregarme')"
        :disabled="!puedeAgregar || fichaAgregada"
        @click="agregarme()"
      />
      <span
        v-if="reserva.origen === 'web'"
        class="text-(length:--vt-texto-xs) text-(--vt-color-texto-suave)"
      >
        {{
          t('pasajeros.topeSolicitado', {
            cantidad: manifiesto?.cantidadDeclarada ?? reserva.cantidadPasajeros,
          })
        }}
      </span>
    </div>

    <UAlert v-if="error" color="error" variant="soft" :title="error" />

    <div v-if="editable" class="flex justify-end gap-2">
      <UButton
        color="neutral"
        variant="ghost"
        :label="t('comun.cancelar')"
        @click="emit('cancelar')"
      />
      <UButton
        color="primary"
        icon="i-lucide-save"
        :label="t('pasajeros.guardar')"
        :loading="guardando"
        :disabled="filas.length === 0"
        @click="guardar"
      />
    </div>
  </div>
</template>
