<script setup lang="ts">
/**
 * Ficha de una salida (HU-18).
 *
 * Presenta el paquete, el mapa del recorrido con la línea de ruta y las
 * paradas ordenadas, el itinerario día por día, los servicios que cubre
 * el precio con sus detalles y exclusiones, y los proveedores con los
 * detalles de su servicio. Para el personal añade los costos internos y
 * las asignaciones operativas; el visitante y el cliente nunca ven
 * costos (RN-SAL-24).
 */
import type { FichaSalida, ProveedorFicha } from '#shared/types/api'
import type { TipoProveedor } from '#shared/types/domain'
import type { ClaveMensaje } from '~/i18n'

const props = defineProps<{
  /** La ficha cargada de la API. */
  ficha: FichaSalida
}>()

const emit = defineEmits<{
  /** La persona cerró la ficha. */
  cerrar: []
  /** El administrador quiere editar la salida. */
  editar: []
}>()

const { t } = useTexto()
const { moneda, fecha, fechaHora } = useFormato()
const cuenta = useNuxtData<import('#shared/types/api').RespuestaCuenta>('cuenta')

/** El personal ve los costos internos; el cliente no (RN-SAL-24). */
const esPersonal = computed(
  () =>
    cuenta.data.value?.usuario?.rol === 'ADMIN' ||
    cuenta.data.value?.usuario?.rol === 'PERSONAL',
)

/** La ruta del mapa: origen, paradas y destino con coordenadas. */
const puntosRuta = computed(() => {
  const lista = [...props.ficha.paradas]
    .filter((p) => p.latitud !== null && p.longitud !== null)
    .map((p) => ({
      latitud: p.latitud as number,
      longitud: p.longitud as number,
      etiqueta: p.nombre,
    }))
  if (lista.length === 0) return lista

  // El mapa une la ruta; los nombres repetidos se presentan una vez.
  const vistos = new Set<string>()
  return lista.filter((punto) => {
    const nombre = punto.etiqueta ?? ''
    if (vistos.has(nombre)) return false
    vistos.add(nombre)
    return true
  })
})

const marcadoresConNumero = computed(() =>
  puntosRuta.value.map((punto, indice) => ({
    ...punto,
    etiqueta: `${indice + 1}. ${punto.etiqueta ?? ''}`,
  })),
)

const disponible = computed(() => props.ficha.cupoDisponible > 0)

const colorEstado = computed(() => {
  switch (props.ficha.estado) {
    case 'programada':
      return 'warning'
    case 'confirmada':
      return 'success'
    case 'cancelada':
      return 'error'
    default:
      return 'neutral'
  }
})

function etiquetaTipo(tipo: TipoProveedor): string {
  return t(`proveedores.tipos.${tipo}` as ClaveMensaje)
}

/** Agrupa los detalles del proveedor bajo su servicio, ya filtrados. */
function detallesDe(proveedor: ProveedorFicha) {
  return proveedor.detallesServicio
}
</script>

<template>
  <div class="space-y-5">
    <!-- Encabezado -->
    <div class="flex flex-wrap items-start justify-between gap-3">
      <div>
        <p class="text-(--vt-texto-sm) text-(--vt-color-texto-suave)">
          {{ ficha.codigoSalida }}
        </p>
        <h3 class="text-(--vt-texto-xl) font-(--vt-texto-peso-fuerte)">
          {{ ficha.paquete }}
        </h3>
        <p v-if="ficha.descripcion" class="mt-1 max-w-prose text-(--vt-texto-sm)">
          {{ ficha.descripcion }}
        </p>
      </div>
      <UBadge
        :color="colorEstado"
        variant="subtle"
        :label="t(`salidas.estados.${ficha.estado}` as ClaveMensaje)"
      />
    </div>

    <dl class="grid grid-cols-2 gap-3 text-(--vt-texto-sm) sm:grid-cols-4">
      <div class="rounded-(--vt-radio-md) px-3 py-2 ring-1 ring-(--vt-color-borde)">
        <dt class="text-xs text-(--vt-color-texto-suave)">
          {{ t('salidas.ficha.fechas') }}
        </dt>
        <dd>{{ fecha(ficha.fechaSalida) }} → {{ fecha(ficha.fechaRetorno) }}</dd>
      </div>
      <div class="rounded-(--vt-radio-md) px-3 py-2 ring-1 ring-(--vt-color-borde)">
        <dt class="text-xs text-(--vt-color-texto-suave)">
          {{ t('salidas.ficha.precio') }}
        </dt>
        <dd class="tabular-nums">
          {{ moneda(ficha.precio) }}
          <span
            v-if="ficha.precioBase !== ficha.precio"
            class="text-xs text-(--vt-color-texto-suave)"
          >
            {{ t('salidas.ficha.precioBase', { precio: moneda(ficha.precioBase) }) }}
          </span>
        </dd>
      </div>
      <div class="rounded-(--vt-radio-md) px-3 py-2 ring-1 ring-(--vt-color-borde)">
        <dt class="text-xs text-(--vt-color-texto-suave)">
          {{ t('salidas.ficha.cupo') }}
        </dt>
        <dd class="tabular-nums">
          {{ ficha.cupoDisponible }}
          {{ t('salidas.ficha.disponibles') }}
          <span class="text-xs text-(--vt-color-texto-suave)">
            {{ t('salidas.ficha.desglose', {
              confirmados: ficha.pasajerosConfirmados,
              pendientes: ficha.pasajerosPendientes,
            }) }}
          </span>
        </dd>
      </div>
      <div class="rounded-(--vt-radio-md) px-3 py-2 ring-1 ring-(--vt-color-borde)">
        <dt class="text-xs text-(--vt-color-texto-suave)">
          {{ t('salidas.ficha.punto') }}
        </dt>
        <dd>{{ ficha.puntoEncuentro ?? '—' }}</dd>
      </div>
    </dl>

    <!-- Mapa del recorrido (HU-18) -->
    <div class="space-y-2">
      <p class="text-(--vt-texto-sm) font-(--vt-texto-peso-medio)">
        {{ t('salidas.ficha.recorrido') }}
        <span class="text-(--vt-texto-xs) font-(--vt-texto-peso-normal) text-(--vt-color-texto-suave)">
          {{
            t('salidas.ficha.recorridoTexto', {
              recorrido: [ficha.origen, ...ficha.paradas.map((p) => p.nombre), ficha.destino]
                .filter((nombre, indice, todos) => nombre && todos.indexOf(nombre) === indice)
                .join(' → '),
            })
          }}
        </span>
      </p>
      <BaseMapa
        :marcadores="marcadoresConNumero"
        :ruta="puntosRuta"
        altura="260px"
      />
      <ul class="grid gap-1 text-(--vt-texto-sm) sm:grid-cols-2">
        <li
          v-for="(parada, indice) in ficha.paradas"
          :key="parada.idLugar"
        >
          <span class="text-(--vt-color-texto-suave)">{{ indice + 1 }}.</span>
          {{ parada.nombre }}
        </li>
      </ul>
    </div>

    <!-- Itinerario día por día (RN-PAQ-18) -->
    <div class="space-y-2">
      <p class="text-(--vt-texto-sm) font-(--vt-texto-peso-medio)">
        {{ t('salidas.ficha.itinerario') }}
      </p>
      <ol v-if="ficha.itinerario.length > 0" class="space-y-2">
        <li
          v-for="dia in ficha.itinerario"
          :key="dia.dia"
          class="rounded-(--vt-radio-md) px-3 py-2 ring-1 ring-(--vt-color-borde)"
        >
          <p class="text-(--vt-texto-sm) font-(--vt-texto-peso-medio)">
            <span
              class="mr-2 inline-flex size-6 items-center justify-center rounded-full bg-(--vt-color-marca-100) text-xs text-(--vt-color-marca-800)"
            >
              {{ dia.dia }}
            </span>
            {{ dia.titulo }}
          </p>
          <p
            v-if="dia.detalle"
            class="mt-1 whitespace-pre-line text-(--vt-texto-sm) text-(--vt-color-texto-suave)"
          >
            {{ dia.detalle }}
          </p>
        </li>
      </ol>
      <p v-else class="text-(--vt-texto-sm) text-(--vt-color-texto-suave)">
        {{ t('salidas.ficha.sinItinerario') }}
      </p>
    </div>

    <!-- Servicios incluidos y exclusiones (RN-SER-04) -->
    <div class="grid gap-4 sm:grid-cols-2">
      <div class="space-y-2">
        <p class="text-(--vt-texto-sm) font-(--vt-texto-peso-medio)">
          {{ t('salidas.ficha.incluye') }}
        </p>
        <div class="flex flex-wrap gap-1.5">
          <UBadge
            v-for="servicio in ficha.servicios"
            :key="servicio.idServicio"
            color="primary"
            variant="subtle"
            :label="servicio.nombre"
          />
        </div>
        <p
          v-if="ficha.serviciosDetalle"
          class="whitespace-pre-line text-(--vt-texto-sm) text-(--vt-color-texto-suave)"
        >
          {{ ficha.serviciosDetalle }}
        </p>
      </div>
      <div class="space-y-2">
        <p class="text-(--vt-texto-sm) font-(--vt-texto-peso-medio)">
          {{ t('salidas.ficha.excluye') }}
        </p>
        <p
          v-if="ficha.serviciosExcluidos"
          class="whitespace-pre-line text-(--vt-texto-sm) text-(--vt-color-texto-suave)"
        >
          {{ ficha.serviciosExcluidos }}
        </p>
        <p v-else class="text-(--vt-texto-sm) text-(--vt-color-texto-suave)">
          {{ t('salidas.ficha.sinExcluidos') }}
        </p>
      </div>
    </div>

    <!-- Proveedores y sus detalles por servicio (RN-PRV-08) -->
    <div class="space-y-2">
      <p class="text-(--vt-texto-sm) font-(--vt-texto-peso-medio)">
        {{ t('salidas.ficha.proveedores') }}
      </p>
      <div
        v-for="proveedor in ficha.proveedores"
        :key="proveedor.idProveedor"
        class="rounded-(--vt-radio-md) px-3 py-2 ring-1 ring-(--vt-color-borde)"
      >
        <div class="flex flex-wrap items-center justify-between gap-2">
          <p class="text-(--vt-texto-sm) font-(--vt-texto-peso-medio)">
            {{ proveedor.nombre }}
            <UBadge
              class="ml-1"
              color="neutral"
              variant="subtle"
              :label="etiquetaTipo(proveedor.servicio)"
            />
          </p>
          <p
            v-if="esPersonal && proveedor.costo"
            class="tabular-nums text-(--vt-texto-xs) text-(--vt-color-texto-suave)"
          >
            {{ t('salidas.ficha.costo', { costo: moneda(proveedor.costo) }) }}
          </p>
        </div>
        <p v-if="proveedor.detalle" class="text-(--vt-texto-sm)">
          {{ proveedor.detalle }}
        </p>
        <ul v-if="detallesDe(proveedor).length > 0" class="mt-2 space-y-1.5">
          <li
            v-for="detalle in detallesDe(proveedor)"
            :key="detalle.titulo"
            class="border-t border-(--vt-color-borde) pt-1.5 first:border-0 first:pt-0"
          >
            <p class="text-(--vt-texto-sm) font-(--vt-texto-peso-medio)">
              {{ detalle.titulo }}
            </p>
            <p
              v-if="detalle.detalle"
              class="whitespace-pre-line text-(--vt-texto-xs) text-(--vt-color-texto-suave)"
            >
              {{ detalle.detalle }}
            </p>
          </li>
        </ul>
      </div>
      <p
        v-if="ficha.proveedores.length === 0"
        class="text-(--vt-texto-sm) text-(--vt-color-texto-suave)"
      >
        {{ t('salidas.ficha.sinProveedores') }}
      </p>
    </div>

    <!--
      Asignaciones operativas (RN-SAL-23): el guía titular y la unidad
      concreta. Se muestran a todos; los costos quedan internos.
    -->
    <div v-if="ficha.asignaciones.length > 0" class="space-y-2">
      <p class="text-(--vt-texto-sm) font-(--vt-texto-peso-medio)">
        {{ t('salidas.ficha.asignaciones') }}
      </p>
      <ul class="space-y-1.5">
        <li
          v-for="asignacion in ficha.asignaciones"
          :key="asignacion.idProveedor"
          class="text-(--vt-texto-sm)"
        >
          <span class="font-(--vt-texto-peso-medio)">{{ asignacion.nombre }}</span>
          <UBadge
            class="ml-1"
            color="neutral"
            variant="subtle"
            :label="etiquetaTipo(asignacion.servicio)"
          />
          <span v-if="asignacion.detalle" class="text-(--vt-color-texto-suave)">
            · {{ asignacion.detalle }}
          </span>
        </li>
      </ul>
    </div>

    <UAlert
      v-if="!disponible"
      color="warning"
      variant="soft"
      icon="i-lucide-users"
      :title="t('salidas.ficha.sinCupo')"
    />

    <div class="flex justify-end gap-2">
      <UButton
        color="neutral"
        variant="ghost"
        :label="t('comun.cerrar')"
        @click="emit('cerrar')"
      />
      <UButton
        v-if="esPersonal"
        color="primary"
        :label="t('salidas.ficha.editar')"
        @click="emit('editar')"
      />
    </div>
  </div>
</template>
