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
    <UAlert
      v-if="error || errorAccion"
      color="error"
      variant="soft"
      :title="error ?? errorAccion ?? ''"
    />

    <BaseTarjeta>
      <BaseTablaDatos
        :columnas="columnas"
        :filas="filas"
        :cargando="pendiente"
        :texto-vacio="t('salidas.vacio')"
      >
        <template #celda="{ columna, fila, valor }">
          <span v-if="columna.clave === 'paquete'">
            {{ fila.paquete }}
            <span class="text-xs text-(--vt-color-texto-suave)">
              {{ fila.codigoPaquete }}
            </span>
          </span>

          <UBadge
            v-else-if="columna.clave === 'estado'"
            :color="colorEstado(fila.estado)"
            variant="subtle"
            :label="etiquetaEstado(fila.estado)"
          />

          <span v-else-if="columna.clave === 'precio'" class="tabular-nums">
            {{ moneda(fila.precio) }}
          </span>

          <div
            v-else-if="columna.clave === 'acciones'"
            class="flex justify-end"
          >
            <UButton
              size="xs"
              variant="soft"
              color="neutral"
              :label="t('salidas.acciones.editar')"
              @click="abrirEdicion(fila)"
            />
          </div>

          <span v-else>{{ valor }}</span>
        </template>
      </BaseTablaDatos>
    </BaseTarjeta>

    <UModal v-model:open="formularioAbierto" :title="tituloFormulario">
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
              <UInput
                v-model="formulario.cupoMaximo"
                type="number"
                min="1"
                max="32767"
                class="w-full"
                required
              />
            </UFormField>

            <UFormField :label="t('salidas.form.precio')" name="precio">
              <UInput
                v-model="formulario.precio"
                type="number"
                min="0.01"
                step="0.01"
                class="w-full"
                required
              />
            </UFormField>
          </div>

          <div class="grid gap-4 sm:grid-cols-2">
            <UFormField
              :label="t('salidas.form.puntoEncuentro')"
              name="puntoEncuentro"
            >
              <UInput v-model="formulario.puntoEncuentro" class="w-full" />
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
            <UInput v-model="formulario.motivo" class="w-full" />
          </UFormField>

          <UFormField
            :label="t('salidas.form.observaciones')"
            name="observaciones"
          >
            <UTextarea
              v-model="formulario.observaciones"
              :rows="2"
              class="w-full"
            />
          </UFormField>

          <UAlert
            v-if="errorFormulario"
            color="error"
            variant="soft"
            :title="errorFormulario"
          />
        </form>
      </template>

      <template #footer>
        <div class="flex justify-end gap-2">
          <UButton
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
import type { ColumnaTabla } from '#shared/types/ui'
import type { ClaveMensaje } from '~/i18n'

/** La tabla necesita una clave para la columna de acciones. */
type FilaSalida = SalidaAdmin & { acciones?: string }

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

const filas = computed<FilaSalida[]>(() => data.value?.salidas ?? [])
const paquetes = computed<PaqueteAdmin[]>(() => dataPaquetes.value?.paquetes ?? [])
const error = computed<string | null>(() =>
  errorConsulta.value ? mensajeDeError(errorConsulta.value) : null,
)

const aviso = ref<string | null>(null)
const errorAccion = ref<string | null>(null)

const columnas = computed<ColumnaTabla<FilaSalida>[]>(() => [
  { clave: 'paquete', etiqueta: t('salidas.columnas.paquete') },
  { clave: 'fechaSalida', etiqueta: t('salidas.columnas.salida') },
  { clave: 'fechaRetorno', etiqueta: t('salidas.columnas.retorno') },
  {
    clave: 'cupoMaximo',
    etiqueta: t('salidas.columnas.cupo'),
    alineacion: 'derecha',
  },
  {
    clave: 'precio',
    etiqueta: t('salidas.columnas.precio'),
    alineacion: 'derecha',
  },
  { clave: 'estado', etiqueta: t('salidas.columnas.estado') },
  {
    clave: 'acciones',
    etiqueta: t('salidas.columnas.acciones'),
    alineacion: 'derecha',
  },
])

function etiquetaEstado(estado: EstadoSalida): string {
  return t(`salidas.estados.${estado}` as ClaveMensaje)
}

function colorEstado(
  estado: EstadoSalida,
): 'success' | 'warning' | 'neutral' | 'error' {
  if (estado === 'confirmada') return 'success'
  if (estado === 'programada') return 'warning'
  if (estado === 'cancelada') return 'error'
  return 'neutral'
}

// --- Alta y edición -----------------------------------------------------

const formularioAbierto = ref(false)
const guardando = ref(false)
const errorFormulario = ref<string | null>(null)
const editando = ref<SalidaAdmin | null>(null)

const formulario = reactive({
  idPaquete: 0,
  fechaSalida: '',
  fechaRetorno: '',
  cupoMaximo: '10',
  precio: '1',
  puntoEncuentro: '',
  estado: 'programada' as EstadoSalida,
  observaciones: '',
  motivo: '',
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

function abrirAlta() {
  editando.value = null
  formulario.idPaquete = paquetes.value.find((p) => p.estado === 'activo')?.idPaquete ?? 0
  formulario.fechaSalida = hoy()
  formulario.fechaRetorno = hoy()
  formulario.cupoMaximo = '10'
  formulario.precio = '1'
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
  formulario.cupoMaximo = String(salida.cupoMaximo)
  formulario.precio = salida.precio
  formulario.puntoEncuentro = salida.puntoEncuentro ?? ''
  formulario.estado = salida.estado
  formulario.observaciones = salida.observaciones ?? ''
  formulario.motivo = ''
  errorFormulario.value = null
  formularioAbierto.value = true
}

async function guardar() {
  errorFormulario.value = null
  guardando.value = true

  const cuerpo = {
    idPaquete: formulario.idPaquete,
    fechaSalida: formulario.fechaSalida,
    fechaRetorno: formulario.fechaRetorno,
    cupoMaximo: Number(formulario.cupoMaximo),
    precio: Number(formulario.precio),
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
  const paquete = paquetes.value.find(
    (p) => p.idPaquete === formulario.idPaquete,
  )
  if (!paquete || !formulario.fechaSalida) return

  const inicio = new Date(`${formulario.fechaSalida}T00:00:00Z`)
  inicio.setUTCDate(inicio.getUTCDate() + paquete.duracionDias - 1)
  formulario.fechaRetorno = inicio.toISOString().slice(0, 10)
}

watch(
  () => [formulario.idPaquete, formulario.fechaSalida],
  () => ajustarRetorno(),
)

function hoy(): string {
  return new Date().toISOString().slice(0, 10)
}

/** Ruta de una salida. Devuelve `string` para no expandir los tipos de ruta. */
function rutaSalida(id: number): string {
  return `/api/admin/salidas/${id}`
}
</script>
