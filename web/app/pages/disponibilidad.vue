<template>
  <div>
    <h1>Disponibilidad</h1>
    <p class="intro">
      Salidas programadas y lugares disponibles. El cupo se calcula en la
      base de datos a partir de las reservas vigentes.
    </p>

    <p v-if="pendiente">Cargando…</p>
    <p v-else-if="error" class="error">{{ error }}</p>
    <p v-else-if="salidas.length === 0">
      No hay salidas programadas desde hoy.
    </p>

    <table v-else>
      <thead>
        <tr>
          <th>Paquete</th>
          <th>Salida</th>
          <th>Retorno</th>
          <th class="num">Cupo</th>
          <th class="num">Ocupados</th>
          <th class="num">Disponibles</th>
          <th class="num">Precio</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="salida in salidas" :key="salida.id_salida">
          <td>{{ salida.paquete }} <span class="codigo">{{ salida.codigo_paquete }}</span></td>
          <td>{{ salida.fecha_salida }}</td>
          <td>{{ salida.fecha_retorno }}</td>
          <td class="num">{{ salida.cupo_maximo }}</td>
          <td class="num">{{ salida.pasajeros_ocupados }}</td>
          <td class="num">{{ salida.cupo_disponible }}</td>
          <td class="num">{{ salida.precio }}</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup lang="ts">
interface Salida {
  id_salida: number
  codigo_paquete: string
  paquete: string
  fecha_salida: string
  fecha_retorno: string
  cupo_maximo: number
  pasajeros_ocupados: number
  cupo_disponible: number
  precio: string
}

const { data, error, pending } = await useFetch<{ salidas: Salida[] }>(
  '/api/disponibilidad',
)
const pendiente = computed(() => pending.value)
const salidas = computed(() => data.value?.salidas ?? [])
</script>

<style scoped>
.intro {
  max-width: 46rem;
  color: color-mix(in srgb, currentColor 70%, transparent);
}

.error {
  color: #b3261e;
}

table {
  border-collapse: collapse;
  width: 100%;
}

th,
td {
  text-align: left;
  padding: 0.4rem 0.6rem;
  border-bottom: 1px solid color-mix(in srgb, currentColor 15%, transparent);
}

.num {
  text-align: right;
}

.codigo {
  font-size: 0.8rem;
  color: color-mix(in srgb, currentColor 55%, transparent);
}
</style>
