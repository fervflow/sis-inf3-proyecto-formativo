<template>
  <div class="space-y-6">
    <BaseEncabezadoPagina
      :titulo="t('proveedores.titulo')"
      :descripcion="t('proveedores.introduccion')"
    >
      <template #acciones>
        <UButton
          color="primary"
          :label="t('proveedores.crear')"
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

    <div
      v-if="pendiente"
      class="grid gap-4 md:grid-cols-2 xl:grid-cols-3"
    >
      <USkeleton v-for="n in 3" :key="n" class="h-64 w-full" />
    </div>

    <BaseEstadoVacio
      v-else-if="proveedores.length === 0"
      :titulo="t('proveedores.vacio')"
      :descripcion="t('proveedores.vacioDescripcion')"
    >
      <template #accion>
        <UButton
          color="primary"
          :label="t('proveedores.crear')"
          @click="abrirAlta"
        />
      </template>
    </BaseEstadoVacio>

    <div v-else class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
      <ProveedoresTarjeta
        v-for="proveedor in proveedores"
        :key="proveedor.idProveedor"
        :proveedor="proveedor"
        @editar="abrirEdicion"
        @vincular="abrirVinculo"
        @quitar="quitarVinculo"
      />
    </div>

    <UModal
      v-model:open="formularioAbierto"
      :title="tituloFormulario"
      :ui="{ content: 'max-w-2xl' }"
    >
      <template #body>
        <form id="form-proveedor" class="space-y-4" @submit.prevent="guardar">
          <div class="grid gap-4 sm:grid-cols-2">
            <UFormField
              :label="t('proveedores.form.nombre')"
              name="nombre"
              :help="t('proveedores.ayudaNombre')"
              required
            >
              <UInput
                v-model="formulario.nombre"
                maxlength="150"
                class="w-full"
              />
            </UFormField>

            <UFormField :label="t('proveedores.form.estado')" name="estado">
              <USelect
                v-model="formulario.estado"
                :items="estados"
                class="w-full"
              />
            </UFormField>
          </div>

          <UFormField
            :label="t('proveedores.form.tipos')"
            name="tipos"
            :help="t('proveedores.ayudaTipos')"
            :error="errorTipos ?? undefined"
            required
          >
            <div class="grid grid-cols-2 gap-2 sm:grid-cols-3">
              <UCheckbox
                v-for="tipo in tipos"
                :key="tipo.value"
                :id="`proveedor-tipo-${tipo.value}`"
                :name="`proveedor-tipo-${tipo.value}`"
                :model-value="formulario.tipos.includes(tipo.value)"
                :label="tipo.label"
                @update:model-value="(valor) => alternarTipo(tipo.value, valor === true)"
              />
            </div>
          </UFormField>

          <div class="grid gap-4 sm:grid-cols-2">
            <UFormField :label="t('proveedores.form.nit')" name="nit">
              <UInput
                v-model="formulario.nit"
                maxlength="30"
                class="w-full"
              />
            </UFormField>

            <UFormField :label="t('proveedores.form.telefono')" name="telefono">
              <UInput
                v-model="formulario.telefono"
                maxlength="30"
                class="w-full"
              />
            </UFormField>
          </div>

          <UFormField :label="t('proveedores.form.correo')" name="correo">
            <UInput
              v-model="formulario.correo"
              type="email"
              maxlength="150"
              class="w-full"
            />
          </UFormField>

          <UFormField :label="t('proveedores.form.direccion')" name="direccion">
            <UInput
              v-model="formulario.direccion"
              maxlength="200"
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
            form="form-proveedor"
            color="primary"
            :loading="guardando"
            :label="t('comun.guardar')"
          />
        </div>
      </template>
    </UModal>

    <UModal
      v-model:open="vinculoAbierto"
      :title="tituloVinculo"
      :ui="{ content: 'max-w-xl' }"
    >
      <template #body>
        <form
          id="form-vinculo"
          class="space-y-4"
          @submit.prevent="guardarVinculo"
        >
          <UFormField :label="t('proveedores.vinculo.paquete')" name="paquete">
            <USelect
              v-model="vinculo.idPaquete"
              :items="paquetesDisponibles"
              :placeholder="t('proveedores.vinculo.elegirPaquete')"
              class="w-full"
            />
          </UFormField>

          <UFormField
            :label="t('proveedores.vinculo.servicio')"
            name="servicio"
            :help="t('proveedores.vinculo.ayudaServicio')"
            required
          >
            <USelect
              v-model="vinculo.servicio"
              :items="tiposDelProveedor"
              :placeholder="t('proveedores.vinculo.elegirServicio')"
              class="w-full"
            />
          </UFormField>

          <UFormField
            :label="t('proveedores.vinculo.detalle')"
            name="detalle"
            :help="t('proveedores.vinculo.ayudaDetalle')"
          >
            <UInput
              v-model="vinculo.detalle"
              maxlength="200"
              class="w-full"
            />
          </UFormField>

          <UFormField
            :label="t('proveedores.vinculo.costo')"
            name="costo"
            :help="t('proveedores.vinculo.ayudaCosto')"
          >
            <BaseCampoMoneda v-model="vinculo.costo" :min="0" />
          </UFormField>
        </form>
      </template>

      <template #footer>
        <div class="flex flex-wrap items-center justify-end gap-2">
          <p
            v-if="errorVinculo"
            class="me-auto text-(--vt-texto-sm) text-(--vt-color-error-600)"
          >
            {{ errorVinculo }}
          </p>
          <UButton
            type="button"
            variant="ghost"
            color="neutral"
            :label="t('comun.cancelar')"
            @click="vinculoAbierto = false"
          />
          <UButton
            type="submit"
            form="form-vinculo"
            color="primary"
            :loading="guardandoVinculo"
            :label="t('proveedores.vinculo.guardar')"
          />
        </div>
      </template>
    </UModal>
  </div>
</template>

<script setup lang="ts">
import type {
  PaqueteAdmin,
  ProveedorAdmin,
  RespuestaPaquetes,
  RespuestaProveedores,
} from '#shared/types/api'
import type {
  EstadoProveedor,
  TipoProveedor,
} from '#shared/types/domain'

const peticion = useRequestFetch()
const { t } = useTexto()
const mensajeDeError = useMensajeError()

const {
  data,
  pending: pendiente,
  error: errorConsulta,
  refresh,
} = await useAsyncData<RespuestaProveedores>('proveedores-admin', () =>
  peticion<RespuestaProveedores>('/api/admin/proveedores'),
)

const { data: dataPaquetes } = await useAsyncData<RespuestaPaquetes>(
  'paquetes-proveedores',
  () => peticion<RespuestaPaquetes>('/api/admin/paquetes'),
)

const proveedores = computed<ProveedorAdmin[]>(
  () => data.value?.proveedores ?? [],
)
const paquetes = computed<PaqueteAdmin[]>(
  () => dataPaquetes.value?.paquetes ?? [],
)
const error = computed<string | null>(() =>
  errorConsulta.value ? mensajeDeError(errorConsulta.value) : null,
)

const aviso = ref<string | null>(null)
const errorAccion = ref<string | null>(null)

const tipos = computed<{ label: string; value: TipoProveedor }[]>(() => [
  { label: t('proveedores.tipos.transporte'), value: 'transporte' },
  { label: t('proveedores.tipos.hospedaje'), value: 'hospedaje' },
  { label: t('proveedores.tipos.guia'), value: 'guia' },
  { label: t('proveedores.tipos.alimentacion'), value: 'alimentacion' },
  { label: t('proveedores.tipos.otro'), value: 'otro' },
])

const estados = computed<{ label: string; value: EstadoProveedor }[]>(() => [
  { label: t('proveedores.estados.activo'), value: 'activo' },
  { label: t('proveedores.estados.inactivo'), value: 'inactivo' },
])

// --- Alta y edición del proveedor ---------------------------------------

const formularioAbierto = ref(false)
const guardando = ref(false)
const errorFormulario = ref<string | null>(null)
const editando = ref<ProveedorAdmin | null>(null)

const formulario = reactive({
  nombre: '',
  tipos: [] as TipoProveedor[],
  nit: '',
  telefono: '',
  correo: '',
  direccion: '',
  estado: 'activo' as EstadoProveedor,
})

const errorTipos = ref<string | null>(null)

const tituloFormulario = computed(() =>
  editando.value ? t('proveedores.editar') : t('proveedores.crear'),
)

function alternarTipo(tipo: TipoProveedor, valor: boolean) {
  errorTipos.value = null
  formulario.tipos = valor
    ? [...formulario.tipos, tipo]
    : formulario.tipos.filter((actual) => actual !== tipo)
}

function abrirAlta() {
  editando.value = null
  formulario.nombre = ''
  formulario.tipos = []
  formulario.nit = ''
  formulario.telefono = ''
  formulario.correo = ''
  formulario.direccion = ''
  formulario.estado = 'activo'
  errorTipos.value = null
  errorFormulario.value = null
  formularioAbierto.value = true
}

function abrirEdicion(proveedor: ProveedorAdmin) {
  editando.value = proveedor
  formulario.nombre = proveedor.nombre
  formulario.tipos = [...proveedor.tipos]
  formulario.nit = proveedor.nit ?? ''
  formulario.telefono = proveedor.telefono ?? ''
  formulario.correo = proveedor.correo ?? ''
  formulario.direccion = proveedor.direccion ?? ''
  formulario.estado = proveedor.estado
  errorTipos.value = null
  errorFormulario.value = null
  formularioAbierto.value = true
}

async function guardar() {
  errorFormulario.value = null

  if (formulario.nombre.trim().length < 3) {
    errorFormulario.value = t('proveedores.errores.nombre')
    return
  }

  if (formulario.tipos.length === 0) {
    errorTipos.value = t('proveedores.errores.tipos')
    return
  }

  guardando.value = true

  const cuerpo = {
    nombre: formulario.nombre,
    tipos: formulario.tipos,
    nit: formulario.nit,
    telefono: formulario.telefono,
    correo: formulario.correo,
    direccion: formulario.direccion,
    estado: formulario.estado,
  }

  try {
    const guardado = await $fetch<ProveedorAdmin>(
      editando.value
        ? `/api/admin/proveedores/${editando.value.idProveedor}`
        : '/api/admin/proveedores',
      {
        method: editando.value ? 'PATCH' : 'POST',
        body: cuerpo,
      },
    )

    formularioAbierto.value = false
    aviso.value = t(
      editando.value ? 'proveedores.actualizado' : 'proveedores.creado',
      { nombre: guardado.nombre },
    )
    await refresh()
  } catch (fallo) {
    errorFormulario.value = mensajeDeError(fallo)
  } finally {
    guardando.value = false
  }
}

// --- Vínculo con paquetes ------------------------------------------------

const vinculoAbierto = ref(false)
const guardandoVinculo = ref(false)
const errorVinculo = ref<string | null>(null)
const proveedorVinculo = ref<ProveedorAdmin | null>(null)

const vinculo = reactive({
  idPaquete: undefined as number | undefined,
  servicio: undefined as TipoProveedor | undefined,
  detalle: '',
  costo: null as number | null,
})

const tituloVinculo = computed(
  () =>
    `${t('proveedores.vinculo.titulo')} · ${
      proveedorVinculo.value?.nombre ?? ''
    }`,
)

/** Solo los tipos que el proveedor declaró (RN-PRV-06). */
const tiposDelProveedor = computed<{ label: string; value: TipoProveedor }[]>(
  () =>
    tipos.value.filter((tipo) =>
      proveedorVinculo.value?.tipos.includes(tipo.value),
    ),
)

const paquetesDisponibles = computed<{ label: string; value: number }[]>(() =>
  paquetes.value.map((paquete) => ({
    label: `${paquete.codigo} · ${paquete.nombre}`,
    value: paquete.idPaquete,
  })),
)

function abrirVinculo(proveedor: ProveedorAdmin) {
  proveedorVinculo.value = proveedor
  vinculo.idPaquete = undefined
  vinculo.servicio = undefined
  vinculo.detalle = ''
  vinculo.costo = null
  errorVinculo.value = null
  vinculoAbierto.value = true
}

watch(
  () => vinculo.idPaquete,
  (idPaquete) => {
    const existente = proveedorVinculo.value?.paquetes.find(
      (item) => item.idPaquete === idPaquete,
    )
    if (existente) {
      vinculo.servicio = existente.servicio
      vinculo.detalle = existente.detalle ?? ''
      vinculo.costo = Number(existente.costo)
    } else if (idPaquete) {
      vinculo.servicio = undefined
      vinculo.detalle = ''
      vinculo.costo = null
    }
  },
)

async function guardarVinculo() {
  errorVinculo.value = null

  if (
    !proveedorVinculo.value ||
    !vinculo.idPaquete ||
    !vinculo.servicio ||
    vinculo.costo === null
  ) {
    errorVinculo.value = t('proveedores.errores.vinculo')
    return
  }

  guardandoVinculo.value = true

  try {
    await $fetch<ProveedorAdmin>(
      `/api/admin/proveedores/${proveedorVinculo.value.idProveedor}/paquetes`,
      {
        method: 'POST',
        body: {
          idPaquete: vinculo.idPaquete,
          servicio: vinculo.servicio,
          detalle: vinculo.detalle.trim() || undefined,
          costo: vinculo.costo,
        },
      },
    )

    vinculoAbierto.value = false
    aviso.value = t('proveedores.vinculado', {
      nombre: proveedorVinculo.value.nombre,
    })
    await refresh()
  } catch (fallo) {
    errorVinculo.value = mensajeDeError(fallo)
  } finally {
    guardandoVinculo.value = false
  }
}

async function quitarVinculo(
  proveedor: ProveedorAdmin,
  idPaquete: number,
) {
  try {
    await $fetch<ProveedorAdmin>(
      `/api/admin/proveedores/${proveedor.idProveedor}/paquetes/${idPaquete}`,
      { method: 'DELETE' },
    )
    aviso.value = t('proveedores.desvinculado', {
      nombre: proveedor.nombre,
    })
    await refresh()
  } catch (fallo) {
    errorAccion.value = mensajeDeError(fallo)
  }
}
</script>
