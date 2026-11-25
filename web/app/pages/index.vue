<template>
  <div class="space-y-12">
    <!-- Portada: un panel oscuro con el mensaje y las acciones del cliente. -->
    <section
      class="relative isolate overflow-hidden rounded-(--vt-radio-lg) bg-(--vt-color-marca-950) bg-linear-to-br from-(--vt-color-marca-950) via-(--vt-color-marca-900) to-(--vt-color-marca-800) p-8 sm:p-12"
    >
      <div
        aria-hidden="true"
        class="absolute -top-24 -right-24 size-96 rounded-full bg-[radial-gradient(closest-side,var(--vt-color-marca-400),transparent)] opacity-30 blur-2xl"
      />
      <div
        aria-hidden="true"
        class="absolute -bottom-32 -left-16 size-80 rounded-full bg-[radial-gradient(closest-side,var(--vt-color-advertencia-400),transparent)] opacity-20 blur-2xl"
      />

      <div class="relative">
        <p
          class="inline-flex items-center gap-2 rounded-(--vt-radio-full) bg-white/10 px-3 py-1 text-xs font-(--vt-texto-peso-medio) tracking-wide text-(--vt-color-marca-100) uppercase"
        >
          <UIcon name="i-lucide-mountain-snow" class="size-3.5" />
          {{ t('inicio.etiqueta') }}
        </p>

        <h1
          class="mt-4 max-w-2xl text-(--vt-texto-3xl) font-(--vt-texto-peso-fuerte) tracking-tight text-white sm:text-(--vt-texto-4xl)"
        >
          {{ t('inicio.titulo') }}
        </h1>

        <p class="mt-3 max-w-xl text-(--vt-texto-base) text-(--vt-color-marca-100)">
          {{ t('inicio.introduccion') }}
        </p>

        <div class="mt-6 flex flex-wrap items-center gap-3">
          <UButton
            :to="cuenta?.usuario ? destinoPanel : '/disponibilidad'"
            color="primary"
            size="lg"
            :icon="cuenta?.usuario ? 'i-lucide-layout-dashboard' : 'i-lucide-compass'"
            :label="cuenta?.usuario ? t('inicio.irAlPanel') : t('inicio.verDisponibilidad')"
          />
          <UButton
            v-if="!cuenta?.usuario"
            to="/crear-cuenta"
            color="primary"
            variant="soft"
            size="lg"
            icon="i-lucide-user-plus"
            :label="t('inicio.crearCuenta')"
          />
          <UButton
            v-else
            to="/disponibilidad"
            color="primary"
            variant="soft"
            size="lg"
            icon="i-lucide-compass"
            :label="t('inicio.verDisponibilidad')"
          />
        </div>
      </div>
    </section>

    <!-- Beneficios: lo que gana el cliente, sin instrucciones de uso. -->
    <section class="space-y-6">
      <h2
        class="text-(--vt-texto-2xl) font-(--vt-texto-peso-fuerte) tracking-tight"
      >
        {{ t('inicio.beneficios.titulo') }}
      </h2>

      <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <BaseTarjeta
          v-for="beneficio in beneficios"
          :key="beneficio.clave"
          :titulo="t(`inicio.beneficios.${beneficio.clave}.titulo` as ClaveMensaje)"
        >
          <div class="flex items-start gap-3">
            <span
              class="grid size-9 shrink-0 place-items-center rounded-(--vt-radio-md) bg-(--vt-color-marca-100) text-(--vt-color-marca-700)"
            >
              <UIcon :name="beneficio.icono" class="size-5" />
            </span>
            <p class="text-(--vt-texto-sm) text-(--vt-color-texto-suave)">
              {{ t(`inicio.beneficios.${beneficio.clave}.texto` as ClaveMensaje) }}
            </p>
          </div>
        </BaseTarjeta>
      </div>
    </section>

    <!-- Cómo se reserva: tres pasos, contados para el cliente. -->
    <section class="space-y-6">
      <h2
        class="text-(--vt-texto-2xl) font-(--vt-texto-peso-fuerte) tracking-tight"
      >
        {{ t('inicio.pasos.titulo') }}
      </h2>

      <div class="grid gap-4 md:grid-cols-3">
        <BaseTarjeta
          v-for="(paso, indice) in pasos"
          :key="paso.clave"
          :titulo="t(`inicio.pasos.${paso.clave}.titulo` as ClaveMensaje)"
        >
          <template #acciones>
            <span
              class="text-(--vt-texto-2xl) font-(--vt-texto-peso-fuerte) text-(--vt-color-marca-300)"
              aria-hidden="true"
            >
              {{ indice + 1 }}
            </span>
          </template>
          <p class="text-(--vt-texto-sm) text-(--vt-color-texto-suave)">
            {{ t(`inicio.pasos.${paso.clave}.texto` as ClaveMensaje) }}
          </p>
        </BaseTarjeta>
      </div>
    </section>

    <!-- Cierre: una última invitación a mirar las salidas. -->
    <section
      class="flex flex-wrap items-center justify-between gap-6 rounded-(--vt-radio-lg) bg-(--vt-color-marca-900) bg-linear-to-r from-(--vt-color-marca-800) to-(--vt-color-marca-600) p-8 sm:p-10"
    >
      <div class="max-w-lg">
        <h2
          class="text-(--vt-texto-2xl) font-(--vt-texto-peso-fuerte) tracking-tight text-white"
        >
          {{ t('inicio.cierre.titulo') }}
        </h2>
        <p class="mt-2 text-(--vt-texto-sm) text-(--vt-color-marca-100)">
          {{ t('inicio.cierre.texto') }}
        </p>
      </div>
      <UButton
        to="/disponibilidad"
        color="neutral"
        variant="solid"
        size="lg"
        icon="i-lucide-arrow-right"
        :label="t('inicio.cierre.accion')"
      />
    </section>
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

const beneficios = [
  { clave: 'cupos', icono: 'i-lucide-badge-check' },
  { clave: 'web', icono: 'i-lucide-monitor-smartphone' },
  { clave: 'pagos', icono: 'i-lucide-wallet' },
  { clave: 'equipo', icono: 'i-lucide-users' },
] as const

const pasos = [
  { clave: '1' },
  { clave: '2' },
  { clave: '3' },
] as const
</script>
