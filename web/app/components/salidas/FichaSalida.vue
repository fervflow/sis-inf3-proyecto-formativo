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
  /** La persona quiere solicitar una reserva de esta salida. */
  solicitar: []
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

/** Línea de texto del recorrido: origen, paradas y destino en orden. */
const textoRecorrido = computed(() =>
  [props.ficha.origen, ...props.ficha.paradas.map((p) => p.nombre), props.ficha.destino]
    .filter((nombre, indice, todos) => nombre && todos.indexOf(nombre) === indice)
    .join(' → '),
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

/** Icono del tipo de servicio: para el chip del proveedor y las insignias. */
function iconoTipo(tipo: TipoProveedor): string {
  switch (tipo) {
    case 'transporte':
      return 'i-lucide-bus'
    case 'hospedaje':
      return 'i-lucide-bed'
    case 'guia':
      return 'i-lucide-user-check'
    case 'alimentacion':
      return 'i-lucide-utensils'
    default:
      return 'i-lucide-box'
  }
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

    <USeparator />

    <!--
      Detalles de un vistazo: fechas, duración, precio, cupo y punto de
      encuentro, en filas compactas con icono en lugar de mini-bloques.
    -->
    <dl class="grid gap-x-6 gap-y-3 text-(--vt-texto-sm) sm:grid-cols-3">
      <div class="flex items-start gap-2">
        <UIcon
          name="i-lucide-calendar-days"
          class="mt-0.5 size-4 shrink-0 text-(--vt-color-marca-600)"
        />
        <div class="min-w-0">
          <dt class="text-xs uppercase tracking-wide text-(--vt-color-texto-suave)">
            {{ t('salidas.ficha.fechas') }}
          </dt>
          <dd class="font-(--vt-texto-peso-medio) tabular-nums">
            {{ fecha(ficha.fechaSalida) }} → {{ fecha(ficha.fechaRetorno) }}
          </dd>
        </div>
      </div>

      <div class="flex items-start gap-2">
        <UIcon
          name="i-lucide-clock"
          class="mt-0.5 size-4 shrink-0 text-(--vt-color-marca-600)"
        />
        <div class="min-w-0">
          <dt class="text-xs uppercase tracking-wide text-(--vt-color-texto-suave)">
            {{ t('salidas.tarjeta.duracion') }}
          </dt>
          <dd class="font-(--vt-texto-peso-medio)">
            {{ t('salidas.tarjeta.dias', { dias: ficha.duracionDias }) }}
          </dd>
        </div>
      </div>

      <div class="flex items-start gap-2">
        <UIcon
          name="i-lucide-tag"
          class="mt-0.5 size-4 shrink-0 text-(--vt-color-marca-600)"
        />
        <div class="min-w-0">
          <dt class="text-xs uppercase tracking-wide text-(--vt-color-texto-suave)">
            {{ t('salidas.ficha.precio') }}
          </dt>
          <dd class="font-(--vt-texto-peso-fuerte) tabular-nums">
            {{ moneda(ficha.precio) }}
            <span
              v-if="ficha.precioBase !== ficha.precio"
              class="text-xs font-(--vt-texto-peso-normal) text-(--vt-color-texto-suave)"
            >
              {{ t('salidas.ficha.precioBase', { precio: moneda(ficha.precioBase) }) }}
            </span>
          </dd>
        </div>
      </div>

      <div class="flex items-start gap-2">
        <UIcon
          name="i-lucide-users"
          class="mt-0.5 size-4 shrink-0 text-(--vt-color-marca-600)"
        />
        <div class="min-w-0">
          <dt class="text-xs uppercase tracking-wide text-(--vt-color-texto-suave)">
            {{ t('salidas.ficha.cupo') }}
          </dt>
          <dd class="font-(--vt-texto-peso-medio) tabular-nums">
            <span
              :class="
                disponible
                  ? 'text-(--vt-color-exito-700) dark:text-(--vt-color-exito-400)'
                  : 'text-(--vt-color-error-600)'
              "
            >
              {{ ficha.cupoDisponible }}
            </span>
            {{ t('salidas.ficha.disponibles') }}
          </dd>
          <dd class="text-xs text-(--vt-color-texto-suave)">
            {{ t('salidas.ficha.desglose', {
              confirmados: ficha.pasajerosConfirmados,
              pendientes: ficha.pasajerosPendientes,
            }) }}
          </dd>
        </div>
      </div>

      <div class="flex items-start gap-2 sm:col-span-2">
        <UIcon
          name="i-lucide-flag"
          class="mt-0.5 size-4 shrink-0 text-(--vt-color-marca-600)"
        />
        <div class="min-w-0">
          <dt class="text-xs uppercase tracking-wide text-(--vt-color-texto-suave)">
            {{ t('salidas.ficha.punto') }}
          </dt>
          <dd class="font-(--vt-texto-peso-medio)">
            {{ ficha.puntoEncuentro ?? '—' }}
          </dd>
        </div>
      </div>
    </dl>

    <USeparator />

    <!-- Mapa del recorrido (HU-18): la ruta y las paradas al lado -->
    <section class="space-y-2">
      <BaseSubtitulo icono="i-lucide-map">
        {{ t('salidas.ficha.recorrido') }}
      </BaseSubtitulo>
      <p class="text-xs text-(--vt-color-texto-suave)">
        {{ t('salidas.ficha.recorridoTexto', { recorrido: textoRecorrido }) }}
      </p>

      <div v-if="puntosRuta.length > 0" class="grid gap-4 sm:grid-cols-5">
        <BaseMapa
          class="sm:col-span-3"
          :marcadores="marcadoresConNumero"
          :ruta="puntosRuta"
          altura="280px"
        />
        <ol
          class="flex flex-col justify-center gap-2 sm:col-span-2"
          :aria-label="t('salidas.ficha.recorrido')"
        >
          <li
            v-for="(parada, indice) in ficha.paradas"
            :key="parada.idLugar"
            class="flex items-center gap-2 text-(--vt-texto-sm)"
          >
            <span
              class="inline-flex size-5 shrink-0 items-center justify-center rounded-full bg-(--vt-color-marca-100) text-xs text-(--vt-color-marca-800)"
            >
              {{ indice + 1 }}
            </span>
            {{ parada.nombre }}
          </li>
        </ol>
      </div>

      <ul v-else class="grid gap-1 text-(--vt-texto-sm) sm:grid-cols-2">
        <li
          v-for="(parada, indice) in ficha.paradas"
          :key="parada.idLugar"
        >
          <span class="text-(--vt-color-texto-suave)">{{ indice + 1 }}.</span>
          {{ parada.nombre }}
        </li>
      </ul>
    </section>

    <!-- Itinerario día por día (RN-PAQ-18) -->
    <section class="space-y-2">
      <BaseSubtitulo icono="i-lucide-list-ordered">
        {{ t('salidas.ficha.itinerario') }}
      </BaseSubtitulo>
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
    </section>

    <USeparator />

    <!-- Servicios incluidos y exclusiones (RN-SER-04) -->
    <div class="grid gap-4 sm:grid-cols-2">
      <div class="space-y-2">
        <BaseSubtitulo icono="i-lucide-circle-check">
          {{ t('salidas.ficha.incluye') }}
        </BaseSubtitulo>
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
        <BaseSubtitulo icono="i-lucide-circle-x">
          {{ t('salidas.ficha.excluye') }}
        </BaseSubtitulo>
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
      <BaseSubtitulo icono="i-lucide-handshake">
        {{ t('salidas.ficha.proveedores') }}
      </BaseSubtitulo>
      <div class="grid items-start gap-3 sm:grid-cols-2">
        <div
          v-for="proveedor in ficha.proveedores"
          :key="proveedor.idProveedor"
          class="rounded-(--vt-radio-md) p-3 ring-1 ring-(--vt-color-borde)"
        >
          <div class="flex items-start gap-3">
            <span
              class="grid size-9 shrink-0 place-items-center rounded-(--vt-radio-md) bg-(--vt-color-marca-100) text-(--vt-color-marca-800)"
            >
              <UIcon :name="iconoTipo(proveedor.servicio)" class="size-5" />
            </span>

            <div class="min-w-0 flex-1">
              <p
                class="flex flex-wrap items-center gap-1.5 text-(--vt-texto-sm) font-(--vt-texto-peso-medio)"
              >
                {{ proveedor.nombre }}
                <UBadge
                  color="neutral"
                  variant="subtle"
                  :label="etiquetaTipo(proveedor.servicio)"
                />
              </p>
              <p
                v-if="proveedor.detalle"
                class="mt-0.5 whitespace-pre-line text-(--vt-texto-sm) text-(--vt-color-texto-suave)"
              >
                {{ proveedor.detalle }}
              </p>
            </div>

            <p
              v-if="esPersonal && proveedor.costo"
              class="shrink-0 tabular-nums text-(--vt-texto-xs) text-(--vt-color-texto-suave)"
            >
              {{ t('salidas.ficha.costo', { costo: moneda(proveedor.costo) }) }}
            </p>
          </div>

          <ul
            v-if="detallesDe(proveedor).length > 0"
            class="mt-3 space-y-2 border-t border-(--vt-color-borde) pt-2.5"
          >
            <li
              v-for="detalle in detallesDe(proveedor)"
              :key="detalle.titulo"
              class="flex items-start gap-2"
            >
              <UIcon
                name="i-lucide-chevron-right"
                class="mt-1 size-3.5 shrink-0 text-(--vt-color-marca-600)"
              />
              <div class="min-w-0">
                <p class="text-(--vt-texto-sm) font-(--vt-texto-peso-medio)">
                  {{ detalle.titulo }}
                </p>
                <p
                  v-if="detalle.detalle"
                  class="whitespace-pre-line text-(--vt-texto-xs) text-(--vt-color-texto-suave)"
                >
                  {{ detalle.detalle }}
                </p>
              </div>
            </li>
          </ul>
        </div>
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
      <BaseSubtitulo icono="i-lucide-clipboard-check">
        {{ t('salidas.ficha.asignaciones') }}
      </BaseSubtitulo>
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
            :icon="iconoTipo(asignacion.servicio)"
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
        v-if="disponible"
        color="primary"
        :label="t('disponibilidad.solicitar')"
        @click="emit('solicitar')"
      />
      <UButton
        v-if="esPersonal"
        color="primary"
        variant="soft"
        :label="t('salidas.ficha.editar')"
        @click="emit('editar')"
      />
    </div>
  </div>
</template>
