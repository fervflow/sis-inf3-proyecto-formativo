<script setup lang="ts">
/**
 * Tarjeta de un proveedor.
 *
 * Muestra los datos de contacto y los paquetes que atiende. Las acciones
 * se delegan a la vista: la tarjeta no llama a la API.
 */
import type { ProveedorAdmin } from '#shared/types/api'
import type { ClaveMensaje } from '~/i18n'

const props = defineProps<{
  proveedor: ProveedorAdmin
}>()

const emit = defineEmits<{
  editar: [proveedor: ProveedorAdmin]
  vincular: [proveedor: ProveedorAdmin]
  quitar: [proveedor: ProveedorAdmin, idPaquete: number]
}>()

const { t } = useTexto()
const { moneda } = useFormato()

const tiposEtiqueta = computed(() =>
  props.proveedor.tipos
    .map((tipo) => t(`proveedores.tipos.${tipo}` as ClaveMensaje))
    .join(' · '),
)

const estadoEtiqueta = computed(() =>
  t(`proveedores.estados.${props.proveedor.estado}` as ClaveMensaje),
)

const estadoColor = computed<'success' | 'neutral'>(() =>
  props.proveedor.estado === 'activo' ? 'success' : 'neutral',
)
</script>

<template>
  <BaseTarjeta :titulo="proveedor.nombre" :descripcion="tiposEtiqueta">
    <template #acciones>
      <div class="flex flex-wrap items-center justify-end gap-2">
        <UBadge
          :color="estadoColor"
          variant="subtle"
          :label="estadoEtiqueta"
        />
        <UButton
          size="xs"
          variant="soft"
          color="neutral"
          :label="t('proveedores.acciones.editar')"
          @click="emit('editar', proveedor)"
        />
      </div>
    </template>

    <div class="space-y-4">
      <div class="space-y-1 text-(--vt-texto-sm)">
        <p v-if="proveedor.nit" class="flex items-center gap-2">
          <UIcon name="i-lucide-badge-check" class="size-4 shrink-0 text-(--vt-color-texto-suave)" />
          <span>{{ proveedor.nit }}</span>
        </p>
        <p v-if="proveedor.telefono" class="flex items-center gap-2">
          <UIcon name="i-lucide-phone" class="size-4 shrink-0 text-(--vt-color-texto-suave)" />
          <span>{{ proveedor.telefono }}</span>
        </p>
        <p v-if="proveedor.correo" class="flex items-center gap-2">
          <UIcon name="i-lucide-mail" class="size-4 shrink-0 text-(--vt-color-texto-suave)" />
          <span class="truncate">{{ proveedor.correo }}</span>
        </p>
        <p v-if="proveedor.direccion" class="flex items-center gap-2">
          <UIcon name="i-lucide-map-pin" class="size-4 shrink-0 text-(--vt-color-texto-suave)" />
          <span>{{ proveedor.direccion }}</span>
        </p>
        <p
          v-if="
            !proveedor.nit &&
            !proveedor.telefono &&
            !proveedor.correo &&
            !proveedor.direccion
          "
          class="text-(--vt-color-texto-suave)"
        >
          {{ t('proveedores.sinContacto') }}
        </p>
      </div>

      <div class="space-y-2">
        <p class="text-xs uppercase tracking-wide text-(--vt-color-texto-suave)">
          {{ t('proveedores.paquetes') }}
        </p>

        <p
          v-if="proveedor.paquetes.length === 0"
          class="text-(--vt-texto-sm) text-(--vt-color-texto-suave)"
        >
          {{ t('proveedores.sinPaquetes') }}
        </p>

        <ul v-else class="space-y-2">
          <li
            v-for="vinculo in proveedor.paquetes"
            :key="vinculo.idPaquete"
            class="flex items-start justify-between gap-2 rounded-(--vt-radio-md) px-3 py-2 ring-1 ring-(--vt-color-borde)"
          >
            <div class="min-w-0">
              <p class="truncate text-(--vt-texto-sm)">
                {{ vinculo.paquete }}
                <span class="text-(--vt-texto-xs) text-(--vt-color-texto-suave)">
                  · {{ vinculo.codigoPaquete }}
                </span>
              </p>
              <p class="text-(--vt-texto-xs) text-(--vt-color-texto-suave)">
                {{
                  t(
                    `proveedores.tipos.${vinculo.servicio}` as ClaveMensaje,
                  )
                }}
                <span v-if="vinculo.detalle"> · {{ vinculo.detalle }}</span>
                · {{ moneda(vinculo.costo) }}
              </p>
            </div>
            <UButton
              size="xs"
              variant="ghost"
              color="error"
              icon="i-lucide-unlink"
              :aria-label="t('proveedores.acciones.quitar')"
              @click="emit('quitar', proveedor, vinculo.idPaquete)"
            />
          </li>
        </ul>
      </div>
    </div>

    <template #pie>
      <UButton
        size="xs"
        variant="soft"
        color="neutral"
        icon="i-lucide-plus"
        :label="t('proveedores.acciones.vincular')"
        @click="emit('vincular', proveedor)"
      />
    </template>
  </BaseTarjeta>
</template>
