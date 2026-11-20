<template>
  <div class="space-y-6">
    <BaseEncabezadoPagina
      :titulo="t('usuarios.titulo')"
      :descripcion="t('usuarios.introduccion')"
    >
      <template #acciones>
        <UButton
          color="primary"
          :label="t('usuarios.crear')"
          @click="abrirFormulario"
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
        :texto-vacio="t('usuarios.vacio')"
      >
        <template #celda="{ columna, fila, valor }">
          <template v-if="columna.clave === 'usuario'">
            <span class="font-(--vt-texto-peso-medio)">{{ fila.usuario }}</span>
            <UBadge
              v-if="fila.debeCambiarPassword"
              class="ml-2"
              color="warning"
              variant="subtle"
              :label="t('usuarios.pendiente')"
            />
          </template>

          <UBadge
            v-else-if="columna.clave === 'rol'"
            color="neutral"
            variant="subtle"
            :label="etiquetaRol(fila.rol)"
          />

          <UBadge
            v-else-if="columna.clave === 'estado'"
            :color="colorEstado(fila.estado)"
            variant="subtle"
            :label="etiquetaEstado(fila.estado)"
          />

          <div
            v-else-if="columna.clave === 'acciones'"
            class="flex justify-end gap-2"
          >
            <template v-if="fila.id !== idPropio">
              <UButton
                size="xs"
                variant="soft"
                color="neutral"
                :label="t('usuarios.acciones.restablecer')"
                @click="restablecer(fila)"
              />
              <UButton
                size="xs"
                variant="soft"
                :color="fila.estado === 'activo' ? 'error' : 'success'"
                :label="
                  fila.estado === 'activo'
                    ? t('usuarios.acciones.bloquear')
                    : t('usuarios.acciones.activar')
                "
                @click="cambiarEstado(fila)"
              />
            </template>
          </div>

          <span v-else>{{ valor }}</span>
        </template>
      </BaseTablaDatos>
    </BaseTarjeta>

    <UModal v-model:open="formularioAbierto" :title="t('usuarios.crear')">
      <template #body>
        <form id="form-usuario" class="space-y-4" @submit.prevent="crear">
          <UFormField
            :label="t('usuarios.form.usuario')"
            name="usuario"
            :help="t('usuarios.form.ayudaUsuario')"
          >
            <UInput
              v-model="formulario.usuario"
              autocapitalize="none"
              spellcheck="false"
              class="w-full"
              required
            />
          </UFormField>

          <div class="grid gap-4 sm:grid-cols-2">
            <UFormField :label="t('usuarios.form.nombres')" name="nombres">
              <UInput v-model="formulario.nombres" class="w-full" required />
            </UFormField>
            <UFormField :label="t('usuarios.form.apellidos')" name="apellidos">
              <UInput v-model="formulario.apellidos" class="w-full" required />
            </UFormField>
          </div>

          <UFormField
            :label="t('usuarios.form.telefono')"
            name="telefono"
          >
            <UInput v-model="formulario.telefono" class="w-full" />
          </UFormField>

          <UFormField :label="t('usuarios.form.rol')" name="rol">
            <USelect v-model="formulario.rol" :items="roles" class="w-full" />
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
            form="form-usuario"
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
  RespuestaCuenta,
  RespuestaOperacion,
  RespuestaUsuarios,
  UsuarioAdmin,
} from '#shared/types/api'
import type { EstadoUsuario, Rol } from '#shared/types/domain'
import type { ColumnaTabla } from '#shared/types/ui'
import type { ClaveMensaje } from '~/i18n'

/** La tabla necesita una clave para la columna de acciones. */
type FilaUsuario = UsuarioAdmin & { acciones?: string }

const { t } = useTexto()
const mensajeDeError = useMensajeError()

const { data: cuenta } = await useFetch<RespuestaCuenta>('/api/cuenta', {
  key: 'cuenta',
})
const idPropio = computed(() => cuenta.value?.usuario?.id ?? '')

const RUTA_USUARIOS: string = '/api/admin/usuarios'

const peticion = useRequestFetch()

const {
  data,
  pending: pendiente,
  error: errorConsulta,
  refresh,
} = await useAsyncData<RespuestaUsuarios>('usuarios-admin', () =>
  peticion<RespuestaUsuarios>(RUTA_USUARIOS),
)

const filas = computed<FilaUsuario[]>(() => data.value?.usuarios ?? [])
const error = computed<string | null>(() =>
  errorConsulta.value ? mensajeDeError(errorConsulta.value) : null,
)

const aviso = ref<string | null>(null)
const errorAccion = ref<string | null>(null)

const columnas = computed<ColumnaTabla<FilaUsuario>[]>(() => [
  { clave: 'usuario', etiqueta: t('usuarios.columnas.usuario') },
  { clave: 'nombres', etiqueta: t('usuarios.columnas.nombres') },
  { clave: 'apellidos', etiqueta: t('usuarios.columnas.apellidos') },
  { clave: 'rol', etiqueta: t('usuarios.columnas.rol') },
  { clave: 'estado', etiqueta: t('usuarios.columnas.estado') },
  {
    clave: 'acciones',
    etiqueta: t('usuarios.columnas.acciones'),
    alineacion: 'derecha',
  },
])

function etiquetaRol(rol: Rol): string {
  return t(`usuarios.roles.${rol}` as ClaveMensaje)
}

function etiquetaEstado(estado: EstadoUsuario): string {
  return t(`usuarios.estados.${estado}` as ClaveMensaje)
}

function colorEstado(estado: EstadoUsuario): 'success' | 'error' | 'neutral' {
  if (estado === 'activo') return 'success'
  if (estado === 'bloqueado') return 'error'
  return 'neutral'
}

// --- Alta ---------------------------------------------------------------

const formularioAbierto = ref(false)
const guardando = ref(false)
const errorFormulario = ref<string | null>(null)

const formulario = reactive({
  usuario: '',
  nombres: '',
  apellidos: '',
  telefono: '',
  rol: 'CLIENTE' as Rol,
})

const roles = computed<{ label: string; value: Rol }[]>(() => [
  { label: t('usuarios.roles.CLIENTE'), value: 'CLIENTE' },
  { label: t('usuarios.roles.PERSONAL'), value: 'PERSONAL' },
  { label: t('usuarios.roles.ADMIN'), value: 'ADMIN' },
])

function abrirFormulario() {
  formulario.usuario = ''
  formulario.nombres = ''
  formulario.apellidos = ''
  formulario.telefono = ''
  formulario.rol = 'CLIENTE'
  errorFormulario.value = null
  formularioAbierto.value = true
}

async function crear() {
  errorFormulario.value = null
  guardando.value = true

  try {
    const creado = await $fetch<UsuarioAdmin>(RUTA_USUARIOS, {
      method: 'POST',
      body: {
        usuario: formulario.usuario,
        nombres: formulario.nombres,
        apellidos: formulario.apellidos,
        telefono: formulario.telefono || undefined,
        rol: formulario.rol,
      },
    })
    formularioAbierto.value = false
    aviso.value = t('usuarios.creado', { usuario: creado.usuario })
    await refresh()
  } catch (fallo) {
    errorFormulario.value = mensajeDeError(fallo)
  } finally {
    guardando.value = false
  }
}

// --- Acciones -----------------------------------------------------------

async function restablecer(fila: UsuarioAdmin) {
  if (!confirm(t('usuarios.confirmarRestablecer', { usuario: fila.usuario }))) {
    return
  }

  aviso.value = null
  errorAccion.value = null
  try {
    await $fetch<RespuestaOperacion>(rutaUsuario(fila.id, '/password'), {
      method: 'POST',
    })
    aviso.value = t('usuarios.restablecer.hecho', { usuario: fila.usuario })
    await refresh()
  } catch (fallo) {
    errorAccion.value = mensajeDeError(fallo)
  }
}

async function cambiarEstado(fila: UsuarioAdmin) {
  const estado: EstadoUsuario = fila.estado === 'activo' ? 'bloqueado' : 'activo'

  aviso.value = null
  errorAccion.value = null
  try {
    await $fetch<RespuestaOperacion>(rutaUsuario(fila.id), {
      method: 'PATCH',
      body: { estado },
    })
    aviso.value = t('usuarios.actualizado')
    await refresh()
  } catch (fallo) {
    errorAccion.value = mensajeDeError(fallo)
  }
}

/** Ruta de una cuenta. Devuelve `string` para no expandir los tipos de ruta. */
function rutaUsuario(id: string, sufijo = ''): string {
  return `/api/admin/usuarios/${id}${sufijo}`
}
</script>