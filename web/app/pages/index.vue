<template>
  <div class="space-y-8">
    <BaseEncabezadoPagina
      :titulo="t('inicio.titulo')"
      :descripcion="t('inicio.introduccion')"
    />

    <BaseTarjeta :titulo="t('inicio.queSePuedeHacer')">
      <ul class="list-disc space-y-1 pl-5 text-(--vt-texto-sm)">
        <li v-for="clave in capacidades" :key="clave">
          {{ t(clave) }}
        </li>
      </ul>
    </BaseTarjeta>

    <BaseTarjeta :titulo="t('salud.titulo')">
      <template #acciones>
        <UButton
          :label="pendiente ? t('salud.comprobando') : t('salud.comprobar')"
          :loading="pendiente"
          color="primary"
          variant="outline"
          @click="comprobar"
        />
      </template>

      <p v-if="error" class="text-(--vt-texto-sm) text-(--vt-color-error-600)">
        {{ t('errores.conexion', { detalle: error }) }}
      </p>

      <dl v-else-if="estado" class="flex flex-wrap gap-6">
        <BaseDato
          :etiqueta="t('salud.conexion')"
          :valor="estado.base.conectado ? t('salud.conectada') : t('salud.fallida')"
        />
        <BaseDato :etiqueta="t('salud.paquetes')" :valor="estado.base.paquetes" />
        <BaseDato :etiqueta="t('salud.salidas')" :valor="estado.base.salidas" />
        <BaseDato :etiqueta="t('salud.reservas')" :valor="estado.base.reservas" />
      </dl>
    </BaseTarjeta>
  </div>
</template>

<script setup lang="ts">
import type { EstadoSalud } from '#shared/types/api'
import type { ClaveMensaje } from '~/i18n'

const { t } = useTexto()
const { cargando: pendiente, error, datos: estado, pedir } = useApi<EstadoSalud>()

const capacidades = [
  'inicio.capacidades.1',
  'inicio.capacidades.2',
  'inicio.capacidades.3',
  'inicio.capacidades.4',
  'inicio.capacidades.5',
] satisfies ClaveMensaje[]

async function comprobar() {
  await pedir('/api/health')
}
</script>
