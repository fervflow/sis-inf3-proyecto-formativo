<template>
  <div class="space-y-6">
    <BaseEncabezadoPagina
      :titulo="t('clientes.titulo')"
      :descripcion="t('clientes.introduccion')"
    >
      <template #acciones>
        <UButton
          color="primary"
          :label="t('clientes.crear')"
          @click="abrirAlta"
        />
      </template>
    </BaseEncabezadoPagina>

    <UAlert v-if="aviso" color="success" variant="soft" :title="aviso" />
    <UAlert v-if="error" color="error" variant="soft" :title="error" />

    <BaseTarjeta>
      <form class="mb-4 flex flex-wrap gap-2" @submit.prevent="cargar">
        <UInput
          v-model="busqueda"
          :placeholder="t('clientes.buscar')"
          class="min-w-64 flex-1"
        />
        <UButton
          type="submit"
          variant="soft"
          color="neutral"
          :label="t('comun.buscar')"
          :loading="cargando"
        />
      </form>

      <BaseTablaDatos
        :columnas="columnas"
        :filas="filas"
        :cargando="cargando"
        :texto-vacio="
          busqueda ? t('clientes.sinResultados') : t('clientes.vacio')
        "
      >
        <template #celda="{ columna, fila, valor }">
          <span v-if="columna.clave === 'documento'" class="tabular-nums">
            {{ etiquetaTipo(fila.tipoDocumento) }} {{ fila.numeroDocumento }}
          </span>

          <span v-else-if="columna.clave === 'cuenta'" class="text-(length:--vt-texto-sm)">
            <template v-if="fila.cuenta">
              {{ fila.cuenta.usuario }}
              <UBadge
                v-if="fila.cuenta.estado !== 'activo'"
                class="ml-1"
                color="error"
                variant="subtle"
                :label="t(`usuarios.estados.${fila.cuenta.estado}` as ClaveMensaje)"
              />
            </template>
            <span v-else class="text-(--vt-color-texto-suave)">
              {{ t('clientes.sinCuenta') }}
            </span>
          </span>

          <UBadge
            v-else-if="columna.clave === 'estado'"
            :color="fila.estado === 'activo' ? 'success' : 'neutral'"
            variant="subtle"
            :label="etiquetaEstado(fila.estado)"
          />

          <div
            v-else-if="columna.clave === 'acciones'"
            class="flex justify-end"
          >
            <UButton
              size="xs"
              variant="soft"
              color="neutral"
              :label="t('clientes.acciones.editar')"
              @click="abrirEdicion(fila)"
            />
          </div>

          <span v-else>{{ valor }}</span>
        </template>
      </BaseTablaDatos>
    </BaseTarjeta>

    <UModal v-model:open="formularioAbierto" :title="tituloFormulario">
      <template #body>
        <form id="form-cliente" class="space-y-4" @submit.prevent="guardar">
          <div class="grid gap-4 sm:grid-cols-2">
            <UFormField
              :label="t('clientes.form.tipoDocumento')"
              name="tipoDocumento"
            >
              <USelect
                v-model="formulario.tipoDocumento"
                :items="tiposDocumento"
                class="w-full"
              />
            </UFormField>

            <UFormField
              :label="t('clientes.form.numeroDocumento')"
              name="numeroDocumento"
            >
              <UInput
                v-model="formulario.numeroDocumento"
                autocapitalize="characters"
                class="w-full"
                required
              />
            </UFormField>
          </div>

          <div class="grid gap-4 sm:grid-cols-2">
            <UFormField :label="t('clientes.form.nombres')" name="nombres">
              <UInput v-model="formulario.nombres" class="w-full" required />
            </UFormField>
            <UFormField :label="t('clientes.form.apellidos')" name="apellidos">
              <UInput v-model="formulario.apellidos" class="w-full" required />
            </UFormField>
          </div>

          <div class="grid gap-4 sm:grid-cols-2">
            <UFormField :label="t('clientes.form.telefono')" name="telefono">
              <UInput v-model="formulario.telefono" class="w-full" />
            </UFormField>
            <UFormField
              :label="t('clientes.form.correo')"
              name="correo"
              :help="t('clientes.ayudaCorreo')"
            >
              <UInput
                v-model="formulario.correo"
                type="email"
                class="w-full"
                required
              />
            </UFormField>
          </div>

          <div class="grid gap-4 sm:grid-cols-2">
            <UFormField
              :label="t('clientes.form.fechaNacimiento')"
              name="fechaNacimiento"
            >
              <UInput
                v-model="formulario.fechaNacimiento"
                type="date"
                class="w-full"
              />
            </UFormField>
            <UFormField :label="t('clientes.form.estado')" name="estado">
              <USelect
                v-model="formulario.estado"
                :items="estados"
                class="w-full"
              />
            </UFormField>
          </div>

          <UFormField :label="t('clientes.form.direccion')" name="direccion">
            <UInput v-model="formulario.direccion" class="w-full" />
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
            form="form-cliente"
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
import type { ClienteResumen, RespuestaClientes } from '#shared/types/api'
import type { EstadoCliente, TipoDocumento } from '#shared/types/domain'
import type { ColumnaTabla } from '#shared/types/ui'
import type { ClaveMensaje } from '~/i18n'

/** La tabla necesita una clave para el documento y para las acciones. */
type FilaCliente = ClienteResumen & { documento?: string; acciones?: string }

const RUTA: string = '/api/clientes'

const { t } = useTexto()
const mensajeDeError = useMensajeError()

const busqueda = ref('')
const clientes = ref<ClienteResumen[]>([])
const cargando = ref(false)
const error = ref<string | null>(null)
const aviso = ref<string | null>(null)

const filas = computed<FilaCliente[]>(() => clientes.value)

const columnas = computed<ColumnaTabla<FilaCliente>[]>(() => [
  { clave: 'documento', etiqueta: t('clientes.columnas.documento') },
  { clave: 'nombres', etiqueta: t('clientes.columnas.nombres') },
  { clave: 'apellidos', etiqueta: t('clientes.columnas.apellidos') },
  { clave: 'telefono', etiqueta: t('clientes.columnas.telefono') },
  { clave: 'cuenta', etiqueta: t('clientes.columnas.cuenta') },
  { clave: 'estado', etiqueta: t('clientes.columnas.estado') },
  {
    clave: 'acciones',
    etiqueta: t('clientes.columnas.acciones'),
    alineacion: 'derecha',
  },
])

function etiquetaEstado(estado: EstadoCliente): string {
  return t(`clientes.estados.${estado}` as ClaveMensaje)
}

function etiquetaTipo(tipo: TipoDocumento): string {
  return t(`clientes.tipos.${tipo}` as ClaveMensaje)
}

async function cargar() {
  cargando.value = true
  error.value = null

  try {
    const resultado = await $fetch<RespuestaClientes>(rutaClientes())
    clientes.value = resultado.clientes
  } catch (fallo) {
    error.value = mensajeDeError(fallo)
  } finally {
    cargando.value = false
  }
}

function rutaClientes(): string {
  const q = busqueda.value.trim()
  return q ? `${RUTA}?q=${encodeURIComponent(q)}` : RUTA
}

await cargar()

// --- Alta y edición -----------------------------------------------------

const formularioAbierto = ref(false)
const guardando = ref(false)
const errorFormulario = ref<string | null>(null)
const editando = ref<ClienteResumen | null>(null)

const formulario = reactive({
  tipoDocumento: 'CI' as TipoDocumento,
  numeroDocumento: '',
  nombres: '',
  apellidos: '',
  correo: '',
  telefono: '',
  direccion: '',
  fechaNacimiento: '',
  estado: 'activo' as EstadoCliente,
})

const tiposDocumento = computed<{ label: string; value: TipoDocumento }[]>(() => [
  { label: etiquetaTipo('CI'), value: 'CI' },
  { label: etiquetaTipo('NIT'), value: 'NIT' },
  { label: etiquetaTipo('PASAPORTE'), value: 'PASAPORTE' },
  { label: etiquetaTipo('OTRO'), value: 'OTRO' },
])

const estados = computed<{ label: string; value: EstadoCliente }[]>(() => [
  { label: t('clientes.estados.activo'), value: 'activo' },
  { label: t('clientes.estados.inactivo'), value: 'inactivo' },
])

const tituloFormulario = computed(() =>
  editando.value ? t('clientes.editar') : t('clientes.crear'),
)

function abrirAlta() {
  editando.value = null
  formulario.tipoDocumento = 'CI'
  formulario.numeroDocumento = ''
  formulario.nombres = ''
  formulario.apellidos = ''
  formulario.correo = ''
  formulario.telefono = ''
  formulario.direccion = ''
  formulario.fechaNacimiento = ''
  formulario.estado = 'activo'
  errorFormulario.value = null
  formularioAbierto.value = true
}

function abrirEdicion(cliente: ClienteResumen) {
  editando.value = cliente
  formulario.tipoDocumento = cliente.tipoDocumento
  formulario.numeroDocumento = cliente.numeroDocumento
  formulario.nombres = cliente.nombres
  formulario.apellidos = cliente.apellidos
  formulario.correo = cliente.correo
  formulario.telefono = cliente.telefono ?? ''
  formulario.direccion = cliente.direccion ?? ''
  formulario.fechaNacimiento = cliente.fechaNacimiento ?? ''
  formulario.estado = cliente.estado
  errorFormulario.value = null
  formularioAbierto.value = true
}

async function guardar() {
  errorFormulario.value = null
  guardando.value = true

  const cuerpo = {
    tipoDocumento: formulario.tipoDocumento,
    numeroDocumento: formulario.numeroDocumento,
    nombres: formulario.nombres,
    apellidos: formulario.apellidos,
    correo: formulario.correo,
    telefono: formulario.telefono,
    direccion: formulario.direccion,
    fechaNacimiento: formulario.fechaNacimiento,
    estado: formulario.estado,
  }

  try {
    const guardado = await $fetch<ClienteResumen>(
      editando.value ? rutaCliente(editando.value.idCliente) : RUTA,
      {
        method: editando.value ? 'PATCH' : 'POST',
        body: cuerpo,
      },
    )

    formularioAbierto.value = false
    aviso.value = t(
      editando.value ? 'clientes.actualizado' : 'clientes.creado',
      { nombre: `${guardado.nombres} ${guardado.apellidos}` },
    )
    await cargar()
  } catch (fallo) {
    errorFormulario.value = mensajeDeError(fallo)
  } finally {
    guardando.value = false
  }
}

/** Ruta de un cliente. Devuelve `string` para no expandir los tipos de ruta. */
function rutaCliente(id: number): string {
  return `/api/clientes/${id}`
}
</script>
