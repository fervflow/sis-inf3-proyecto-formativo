<template>
  <div class="space-y-6">
    <BaseEncabezadoPagina
      :titulo="t('paquetes.titulo')"
      :descripcion="t('paquetes.introduccion')"
    >
      <template #acciones>
        <UButton
          color="primary"
          :label="t('paquetes.crear')"
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
        :texto-vacio="t('paquetes.vacio')"
      >
        <template #celda="{ columna, fila, valor }">
          <UBadge
            v-if="columna.clave === 'estado'"
            :color="colorEstado(fila.estado)"
            variant="subtle"
            :label="etiquetaEstado(fila.estado)"
          />

          <span v-else-if="columna.clave === 'precioBase'" class="tabular-nums">
            {{ formatearPrecio(fila.precioBase) }}
          </span>

          <div
            v-else-if="columna.clave === 'acciones'"
            class="flex justify-end"
          >
            <UButton
              size="xs"
              variant="soft"
              color="neutral"
              :label="t('paquetes.acciones.editar')"
              @click="abrirEdicion(fila)"
            />
          </div>

          <span v-else>{{ valor }}</span>
        </template>
      </BaseTablaDatos>
    </BaseTarjeta>

    <UModal v-model:open="formularioAbierto" :title="tituloFormulario">
      <template #body>
        <form id="form-paquete" class="space-y-4" @submit.prevent="guardar">
          <div class="grid gap-4 sm:grid-cols-2">
            <UFormField
              :label="t('paquetes.form.codigo')"
              name="codigo"
              :help="t('paquetes.ayudaCodigo')"
            >
              <UInput
                v-model="formulario.codigo"
                autocapitalize="characters"
                spellcheck="false"
                class="w-full"
                required
              />
            </UFormField>

            <UFormField :label="t('paquetes.form.estado')" name="estado">
              <USelect
                v-model="formulario.estado"
                :items="estados"
                class="w-full"
              />
            </UFormField>
          </div>

          <UFormField :label="t('paquetes.form.nombre')" name="nombre">
            <UInput v-model="formulario.nombre" class="w-full" required />
          </UFormField>

          <UFormField
            :label="t('paquetes.form.descripcion')"
            name="descripcion"
          >
            <UTextarea v-model="formulario.descripcion" :rows="2" class="w-full" />
          </UFormField>

          <div class="grid gap-4 sm:grid-cols-2">
            <UFormField :label="t('paquetes.form.duracion')" name="duracion">
              <UInput
                v-model="formulario.duracionDias"
                type="number"
                min="1"
                max="365"
                class="w-full"
                required
              />
            </UFormField>

            <UFormField
              :label="t('paquetes.form.precio')"
              name="precio"
              :help="t('paquetes.ayudaPrecio')"
            >
              <UInput
                v-model="formulario.precioBase"
                type="number"
                min="0"
                step="0.01"
                class="w-full"
                required
              />
            </UFormField>
          </div>

          <UFormField :label="t('paquetes.form.itinerario')" name="itinerario">
            <UTextarea v-model="formulario.itinerario" :rows="3" class="w-full" />
          </UFormField>

          <UFormField :label="t('paquetes.form.servicios')" name="servicios">
            <UTextarea
              v-model="formulario.serviciosIncluidos"
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
            form="form-paquete"
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
import type { PaqueteAdmin, RespuestaPaquetes } from '#shared/types/api'
import type { EstadoPaquete } from '#shared/types/domain'
import type { ColumnaTabla } from '#shared/types/ui'
import type { ClaveMensaje } from '~/i18n'

/** La tabla necesita una clave para la columna de acciones. */
type FilaPaquete = PaqueteAdmin & { acciones?: string }

const RUTA: string = '/api/admin/paquetes'

const { t } = useTexto()
const mensajeDeError = useMensajeError()

const {
  data,
  pending: pendiente,
  error: errorConsulta,
  refresh,
} = await useAsyncData<RespuestaPaquetes>('paquetes-admin', () =>
  $fetch<RespuestaPaquetes>(RUTA),
)

const filas = computed<FilaPaquete[]>(() => data.value?.paquetes ?? [])
const error = computed<string | null>(() =>
  errorConsulta.value ? mensajeDeError(errorConsulta.value) : null,
)

const aviso = ref<string | null>(null)
const errorAccion = ref<string | null>(null)

const columnas = computed<ColumnaTabla<FilaPaquete>[]>(() => [
  { clave: 'codigo', etiqueta: t('paquetes.columnas.codigo') },
  { clave: 'nombre', etiqueta: t('paquetes.columnas.nombre') },
  {
    clave: 'duracionDias',
    etiqueta: t('paquetes.columnas.dias'),
    alineacion: 'derecha',
  },
  {
    clave: 'precioBase',
    etiqueta: t('paquetes.columnas.precio'),
    alineacion: 'derecha',
  },
  { clave: 'estado', etiqueta: t('paquetes.columnas.estado') },
  {
    clave: 'acciones',
    etiqueta: t('paquetes.columnas.acciones'),
    alineacion: 'derecha',
  },
])

function etiquetaEstado(estado: EstadoPaquete): string {
  return t(`paquetes.estados.${estado}` as ClaveMensaje)
}

function colorEstado(
  estado: EstadoPaquete,
): 'success' | 'warning' | 'neutral' {
  if (estado === 'activo') return 'success'
  if (estado === 'borrador') return 'warning'
  return 'neutral'
}

function formatearPrecio(valor: string): string {
  return new Intl.NumberFormat('es-BO', {
    style: 'currency',
    currency: 'BOB',
  }).format(Number(valor))
}

// --- Alta y edición -----------------------------------------------------

const formularioAbierto = ref(false)
const guardando = ref(false)
const errorFormulario = ref<string | null>(null)
const editando = ref<PaqueteAdmin | null>(null)

const formulario = reactive({
  codigo: '',
  nombre: '',
  descripcion: '',
  duracionDias: '1',
  precioBase: '0',
  itinerario: '',
  serviciosIncluidos: '',
  estado: 'borrador' as EstadoPaquete,
})

const estados = computed<{ label: string; value: EstadoPaquete }[]>(() => [
  { label: t('paquetes.estados.borrador'), value: 'borrador' },
  { label: t('paquetes.estados.activo'), value: 'activo' },
  { label: t('paquetes.estados.inactivo'), value: 'inactivo' },
])

const tituloFormulario = computed(() =>
  editando.value ? t('paquetes.editar') : t('paquetes.crear'),
)

function abrirAlta() {
  editando.value = null
  formulario.codigo = ''
  formulario.nombre = ''
  formulario.descripcion = ''
  formulario.duracionDias = '1'
  formulario.precioBase = '0'
  formulario.itinerario = ''
  formulario.serviciosIncluidos = ''
  formulario.estado = 'borrador'
  errorFormulario.value = null
  formularioAbierto.value = true
}

function abrirEdicion(paquete: PaqueteAdmin) {
  editando.value = paquete
  formulario.codigo = paquete.codigo
  formulario.nombre = paquete.nombre
  formulario.descripcion = paquete.descripcion ?? ''
  formulario.duracionDias = String(paquete.duracionDias)
  formulario.precioBase = paquete.precioBase
  formulario.itinerario = paquete.itinerario ?? ''
  formulario.serviciosIncluidos = paquete.serviciosIncluidos ?? ''
  formulario.estado = paquete.estado
  errorFormulario.value = null
  formularioAbierto.value = true
}

async function guardar() {
  errorFormulario.value = null
  guardando.value = true

  const cuerpo = {
    codigo: formulario.codigo,
    nombre: formulario.nombre,
    descripcion: formulario.descripcion,
    duracionDias: Number(formulario.duracionDias),
    precioBase: Number(formulario.precioBase),
    itinerario: formulario.itinerario,
    serviciosIncluidos: formulario.serviciosIncluidos,
    estado: formulario.estado,
  }

  try {
    const guardado = await $fetch<PaqueteAdmin>(
      editando.value ? rutaPaquete(editando.value.idPaquete) : RUTA,
      {
        method: editando.value ? 'PATCH' : 'POST',
        body: cuerpo,
      },
    )

    formularioAbierto.value = false
    aviso.value = t(
      editando.value ? 'paquetes.actualizado' : 'paquetes.creado',
      { codigo: guardado.codigo },
    )
    await refresh()
  } catch (fallo) {
    errorFormulario.value = mensajeDeError(fallo)
  } finally {
    guardando.value = false
  }
}

/** Ruta de un paquete. Devuelve `string` para no expandir los tipos de ruta. */
function rutaPaquete(id: number): string {
  return `/api/admin/paquetes/${id}`
}
</script>
