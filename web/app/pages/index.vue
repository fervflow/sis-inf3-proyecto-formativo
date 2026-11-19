<template>
  <div class="space-y-8">
    <section
      class="overflow-hidden rounded-(--vt-radio-lg) border border-(--vt-color-borde) bg-(--vt-color-superficie) p-6 sm:p-10"
    >
      <p
        class="flex items-center gap-2 text-xs uppercase tracking-wide text-(--vt-color-texto-suave)"
      >
        <span class="size-1.5 rounded-full bg-(--vt-color-marca-500)" />
        {{ t('inicio.etiqueta') }}
      </p>

      <h1
        class="mt-3 max-w-3xl text-(--vt-texto-3xl) font-(--vt-texto-peso-fuerte) tracking-tight sm:text-(--vt-texto-4xl)"
      >
        {{ t('inicio.titulo') }}
      </h1>

      <p
        class="mt-3 max-w-2xl text-(--vt-texto-base) text-(--vt-color-texto-suave)"
      >
        {{ t('inicio.introduccion') }}
      </p>

      <div class="mt-6 flex flex-wrap items-center gap-3">
        <UButton
          v-if="cuenta?.usuario"
          :to="destinoPanel"
          color="primary"
          size="lg"
          icon="i-lucide-arrow-right"
          :label="t('inicio.irAlPanel')"
        />
        <UButton
          v-else
          to="/ingresar"
          color="primary"
          size="lg"
          icon="i-lucide-log-in"
          :label="t('inicio.ingresar')"
        />

        <UButton
          to="/disponibilidad"
          variant="outline"
          color="neutral"
          size="lg"
          icon="i-lucide-calendar-days"
          :label="t('inicio.verDisponibilidad')"
        />
      </div>

      <p
        v-if="!cuenta?.usuario"
        class="mt-3 text-(--vt-texto-sm) text-(--vt-color-texto-suave)"
      >
        {{ t('inicio.cuentas') }}
      </p>
    </section>

    <div class="grid gap-4 md:grid-cols-3">
      <BaseTarjeta
        v-for="tarjeta in tarjetas"
        :key="tarjeta.clave"
        :titulo="t(`inicio.tarjetas.${tarjeta.clave}.titulo` as ClaveMensaje)"
      >
        <div class="flex items-start gap-3">
          <span
            class="grid size-9 shrink-0 place-items-center rounded-(--vt-radio-md) bg-(--vt-color-marca-100) text-(--vt-color-marca-800)"
          >
            <UIcon :name="tarjeta.icono" class="size-5" />
          </span>
          <p class="text-(--vt-texto-sm) text-(--vt-color-texto-suave)">
            {{ t(`inicio.tarjetas.${tarjeta.clave}.texto` as ClaveMensaje) }}
          </p>
        </div>
      </BaseTarjeta>
    </div>

    <BaseTarjeta :titulo="t('inicio.queSePuedeHacer')">
      <ul class="grid gap-2 sm:grid-cols-2">
        <li
          v-for="clave in capacidades"
          :key="clave"
          class="flex gap-2 text-(--vt-texto-sm)"
        >
          <UIcon
            name="i-lucide-check"
            class="mt-0.5 size-4 shrink-0 text-(--vt-color-marca-600)"
          />
          <span>{{ t(clave) }}</span>
        </li>
      </ul>
    </BaseTarjeta>
  </div>
</template>

<script setup lang="ts">
import type { RespuestaCuenta } from '#shared/types/api'
import type { ClaveMensaje } from '~/i18n'

const { t } = useTexto()

const { data: cuenta } = await useFetch<RespuestaCuenta>('/api/cuenta', {
  key: 'cuenta',
})

/** A dónde conviene llevar a cada rol después del ingreso. */
const destinoPanel = computed(() => {
  const rol = cuenta.value?.usuario?.rol

  if (rol === 'ADMIN') return '/admin/usuarios'
  if (rol === 'PERSONAL') return '/clientes'
  return '/disponibilidad'
})

const tarjetas = [
  { clave: 'paquetes', icono: 'i-lucide-map' },
  { clave: 'reservas', icono: 'i-lucide-calendar-check' },
  { clave: 'equipo', icono: 'i-lucide-users' },
] as const

const capacidades = [
  'inicio.capacidades.1',
  'inicio.capacidades.2',
  'inicio.capacidades.3',
  'inicio.capacidades.4',
  'inicio.capacidades.5',
] satisfies ClaveMensaje[]
</script>
