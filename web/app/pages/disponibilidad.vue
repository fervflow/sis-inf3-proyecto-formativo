<template>
  <div class="space-y-8">
    <BaseEncabezadoPagina
      :titulo="t('disponibilidad.titulo')"
      :descripcion="t('disponibilidad.introduccion')"
    />

    <BaseTarjeta>
      <BaseTablaDatos
        v-if="salidas.length > 0"
        :columnas="columnas"
        :filas="salidas"
        :cargando="pendiente"
        :texto-vacio="t('disponibilidad.vacia')"
      >
        <template #celda="{ columna, fila, valor }">
          <span v-if="columna.clave === 'paquete'">
            {{ fila.paquete }}
            <span class="text-xs text-(--vt-color-texto-suave)">
              {{ fila.codigo_paquete }}
            </span>
          </span>
          <span v-else class="tabular-nums">{{ valor }}</span>
        </template>
      </BaseTablaDatos>

      <BaseEstadoVacio
        v-else-if="!pendiente && !error"
        :titulo="t('disponibilidad.vacia')"
      />

      <p v-if="error" class="text-(--vt-texto-sm) text-(--vt-color-error-600)">
        {{ t('errores.conexion', { detalle: error }) }}
      </p>
    </BaseTarjeta>
  </div>
</template>

<script setup lang="ts">
import type { RespuestaDisponibilidad, SalidaDisponible } from '#shared/types/api'
import type { ColumnaTabla } from '#shared/types/ui'

const { t } = useTexto()
const { cargando: pendiente, error, datos, pedir } = useApi<RespuestaDisponibilidad>()

const salidas = computed<SalidaDisponible[]>(() => datos.value?.salidas ?? [])

// Las etiquetas se calculan de nuevo cuando cambia el idioma.
const columnas = computed<ColumnaTabla<SalidaDisponible>[]>(() => [
  { clave: 'paquete', etiqueta: t('disponibilidad.columnas.paquete') },
  { clave: 'fecha_salida', etiqueta: t('disponibilidad.columnas.salida') },
  { clave: 'fecha_retorno', etiqueta: t('disponibilidad.columnas.retorno') },
  { clave: 'cupo_maximo', etiqueta: t('disponibilidad.columnas.cupo'), alineacion: 'derecha' },
  { clave: 'pasajeros_ocupados', etiqueta: t('disponibilidad.columnas.ocupados'), alineacion: 'derecha' },
  { clave: 'cupo_disponible', etiqueta: t('disponibilidad.columnas.disponibles'), alineacion: 'derecha' },
  { clave: 'precio', etiqueta: t('disponibilidad.columnas.precio'), alineacion: 'derecha' },
])

await pedir('/api/disponibilidad')
</script>
