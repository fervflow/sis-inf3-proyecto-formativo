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
      v-if="error"
      color="error"
      variant="soft"
      :title="error"
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
            {{ moneda(fila.precioBase) }}
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

    <PaquetesFormularioPaquete
      v-model:abierto="formularioAbierto"
      :paquete="editando"
      @guardado="alGuardar"
    />
  </div>
</template>

<script setup lang="ts">
import type { PaqueteAdmin, RespuestaPaquetes } from '#shared/types/api'
import type { EstadoPaquete } from '#shared/types/domain'
import type { ColumnaTabla } from '#shared/types/ui'
import type { ClaveMensaje } from '~/i18n'

/** La tabla necesita una clave para la columna de acciones y el recorrido. */
type FilaPaquete = PaqueteAdmin & {
  acciones?: string
  recorrido?: string
}

const RUTA: string = '/api/admin/paquetes'

const { t } = useTexto()
const mensajeDeError = useMensajeError()
const { moneda } = useFormato()

const peticion = useRequestFetch()

const {
  data,
  pending: pendiente,
  error: errorConsulta,
  refresh,
} = await useAsyncData<RespuestaPaquetes>('paquetes-admin', () =>
  peticion<RespuestaPaquetes>(RUTA),
)

const error = computed<string | null>(() =>
  errorConsulta.value ? mensajeDeError(errorConsulta.value) : null,
)

const aviso = ref<string | null>(null)
const formularioAbierto = ref(false)
const editando = ref<PaqueteAdmin | null>(null)

/** Resume el recorrido: origen, paradas, destino y regreso. */
function recorridoDe(paquete: PaqueteAdmin): string {
  const origen = paquete.origen?.nombre
  const destino = paquete.destino?.nombre
  const partes: string[] = []

  if (origen) partes.push(origen)
  for (const parada of paquete.paradas) {
    if (!partes.includes(parada.nombre)) partes.push(parada.nombre)
  }
  if (destino && !partes.includes(destino)) partes.push(destino)
  if (paquete.tipoRecorrido === 'circuito' && origen) partes.push(origen)

  return partes.length > 0 ? partes.join(' → ') : '—'
}

const filas = computed<FilaPaquete[]>(() =>
  (data.value?.paquetes ?? []).map((paquete) => ({
    ...paquete,
    recorrido: recorridoDe(paquete),
  })),
)

const columnas = computed<ColumnaTabla<FilaPaquete>[]>(() => [
  { clave: 'codigo', etiqueta: t('paquetes.columnas.codigo') },
  { clave: 'nombre', etiqueta: t('paquetes.columnas.nombre') },
  { clave: 'recorrido', etiqueta: t('paquetes.columnas.recorrido') },
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

// --- Alta y edición -----------------------------------------------------

function abrirAlta() {
  aviso.value = null
  editando.value = null
  formularioAbierto.value = true
}

function abrirEdicion(paquete: PaqueteAdmin) {
  aviso.value = null
  editando.value = paquete
  formularioAbierto.value = true
}

async function alGuardar(guardado: PaqueteAdmin) {
  const eraEdicion = editando.value !== null
  aviso.value = t(
    eraEdicion ? 'paquetes.actualizado' : 'paquetes.creado',
    { codigo: guardado.codigo },
  )
  editando.value = null
  await refresh()
}
</script>
