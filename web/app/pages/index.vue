<template>
  <div>
    <h1>Gestión de paquetes turísticos y reservas</h1>
    <p class="intro">
      Sistema web para la agencia Vizcacha Tours, en Potosí. Atiende a dos
      canales con el mismo proceso validado: la atención del personal de
      agencia y el acceso directo del cliente.
    </p>

    <section>
      <h2>Qué se puede hacer</h2>
      <ul>
        <li>Registrar y mantener los paquetes turísticos y sus proveedores.</li>
        <li>Programar salidas con fecha, cupo y precio.</li>
        <li>Consultar la disponibilidad y registrar reservas con validación de cupos.</li>
        <li>Registrar clientes y pasajeros, cotizaciones, anticipos y saldos.</li>
        <li>Confirmar solicitudes, consultar reportes y auditar los cambios.</li>
      </ul>
    </section>

    <section>
      <h2>Estado del sistema</h2>
      <p>
        <button type="button" :disabled="pendiente" @click="comprobar">
          {{ pendiente ? 'Comprobando…' : 'Comprobar la conexión con la base' }}
        </button>
      </p>
      <p v-if="error" class="error">{{ error }}</p>
      <dl v-else-if="estado" class="estado">
        <div><dt>Conexión</dt><dd>{{ estado.base.conectado ? 'correcta' : 'fallida' }}</dd></div>
        <div><dt>Paquetes</dt><dd>{{ estado.base.paquetes }}</dd></div>
        <div><dt>Salidas</dt><dd>{{ estado.base.salidas }}</dd></div>
        <div><dt>Reservas</dt><dd>{{ estado.base.reservas }}</dd></div>
      </dl>
    </section>
  </div>
</template>

<script setup lang="ts">
interface Estado {
  estado: string
  base: { conectado: boolean; paquetes: number; salidas: number; reservas: number }
}

const pendiente = ref(false)
const estado = ref<Estado | null>(null)
const error = ref('')

async function comprobar() {
  pendiente.value = true
  error.value = ''
  try {
    estado.value = await $fetch<Estado>('/api/health')
  } catch (fallo) {
    error.value = `No se pudo comprobar: ${(fallo as Error).message}`
  } finally {
    pendiente.value = false
  }
}
</script>

<style scoped>
.intro {
  max-width: 46rem;
  font-size: 1.05rem;
}

.error {
  color: #b3261e;
}

.estado {
  display: flex;
  flex-wrap: wrap;
  gap: 1.5rem;
}

.estado div {
  border-left: 2px solid color-mix(in srgb, currentColor 25%, transparent);
  padding-left: 0.75rem;
}

.estado dt {
  font-size: 0.85rem;
  color: color-mix(in srgb, currentColor 60%, transparent);
}

.estado dd {
  margin: 0;
  font-size: 1.25rem;
}
</style>
