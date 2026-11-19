<script setup lang="ts">
/**
 * Encabezado de la aplicación.
 *
 * Agrupa la navegación principal, el acceso a la gestión y la cuenta de la
 * sesión. No pide datos ni llama a la API: recibe la cuenta y emite el
 * cierre de sesión, para que la vista decida qué hacer.
 */
import type { DropdownMenuItem } from '@nuxt/ui'
import type { CuentaActual } from '#shared/types/api'
import type { ClaveMensaje, CodigoIdioma } from '~/i18n'

const props = defineProps<{
  /** Cuenta de la sesión, o `null` si no hay. */
  cuenta: CuentaActual | null
}>()

const emit = defineEmits<{
  /** La persona usuaria pidió cerrar la sesión. */
  salir: []
}>()

const { t, idioma, establecerIdioma } = useTexto()
const ruta = useRoute()

const esAdmin = computed(() => props.cuenta?.rol === 'ADMIN')
const esPersonal = computed(
  () => props.cuenta?.rol === 'ADMIN' || props.cuenta?.rol === 'PERSONAL',
)

const idiomaSeleccionado = computed<CodigoIdioma>({
  get: () => idioma.value,
  set: (valor) => establecerIdioma(valor),
})

const idiomasDisponibles = computed<{ label: string; value: CodigoIdioma }[]>(
  () => [
    { label: t('idioma.es'), value: 'es' },
    { label: t('idioma.en'), value: 'en' },
  ],
)

/** Resalta el enlace de la ruta en la que se está. */
function activa(destino: string): boolean {
  return ruta.path === destino
}

function variante(destino: string): 'soft' | 'ghost' {
  return activa(destino) ? 'soft' : 'ghost'
}

function colorDe(destino: string): 'primary' | 'neutral' {
  return activa(destino) ? 'primary' : 'neutral'
}

const nombreCuenta = computed(() =>
  props.cuenta
    ? `${props.cuenta.nombres} ${props.cuenta.apellidos}`.trim()
    : '',
)

const etiquetaRol = computed(() =>
  props.cuenta
    ? t(`usuarios.roles.${props.cuenta.rol}` as ClaveMensaje)
    : '',
)

const menuGestion = computed<DropdownMenuItem[][]>(() => {
  const items: DropdownMenuItem[] = [
    {
      label: t('nav.clientes'),
      icon: 'i-lucide-contact',
      to: '/clientes',
    },
  ]

  if (esAdmin.value) {
    items.push(
      {
        label: t('nav.paquetes'),
        icon: 'i-lucide-map',
        to: '/admin/paquetes',
      },
      {
        label: t('nav.usuarios'),
        icon: 'i-lucide-users',
        to: '/admin/usuarios',
      },
    )
  }

  return [items]
})

const menuCuenta = computed<DropdownMenuItem[][]>(() => [
  [
    {
      label: nombreCuenta.value,
      description: etiquetaRol.value,
      icon: 'i-lucide-circle-user',
      type: 'label',
    },
  ],
  [
    {
      label: t('nav.salir'),
      icon: 'i-lucide-log-out',
      onSelect: () => emit('salir'),
    },
  ],
])

const menuMovil = computed<DropdownMenuItem[][]>(() => {
  const principal: DropdownMenuItem[] = [
    { label: t('nav.inicio'), icon: 'i-lucide-home', to: '/' },
    {
      label: t('nav.disponibilidad'),
      icon: 'i-lucide-calendar-days',
      to: '/disponibilidad',
    },
  ]

  if (esPersonal.value) {
    principal.push({
      label: t('nav.clientes'),
      icon: 'i-lucide-contact',
      to: '/clientes',
    })
  }
  if (esAdmin.value) {
    principal.push(
      {
        label: t('nav.paquetes'),
        icon: 'i-lucide-map',
        to: '/admin/paquetes',
      },
      {
        label: t('nav.usuarios'),
        icon: 'i-lucide-users',
        to: '/admin/usuarios',
      },
    )
  }

  const cuenta: DropdownMenuItem[] = props.cuenta
    ? [
        {
          label: t('nav.salir'),
          icon: 'i-lucide-log-out',
          onSelect: () => emit('salir'),
        },
      ]
    : [{ label: t('nav.ingresar'), icon: 'i-lucide-log-in', to: '/ingresar' }]

  return [principal, cuenta]
})
</script>

<template>
  <header
    class="sticky top-0 z-40 border-b border-(--vt-color-borde) bg-(--vt-color-superficie)"
  >
    <div
      class="mx-auto flex w-full max-w-6xl items-center gap-3 px-4 py-3"
    >
      <NuxtLink
        to="/"
        class="flex min-w-0 items-center gap-2.5 text-inherit no-underline"
      >
        <span
          class="grid size-9 shrink-0 place-items-center rounded-(--vt-radio-md) bg-(--vt-color-marca-600) text-(--vt-color-superficie)"
        >
          <UIcon name="i-lucide-mountain" class="size-5" />
        </span>
        <span class="hidden min-w-0 flex-col leading-tight sm:flex">
          <span
            class="truncate text-(--vt-texto-base) font-(--vt-texto-peso-fuerte)"
          >
            {{ t('app.nombre') }}
          </span>
          <span class="truncate text-xs text-(--vt-color-texto-suave)">
            {{ t('app.subtitulo') }}
          </span>
        </span>
      </NuxtLink>

      <nav
        class="ml-2 hidden items-center gap-1 md:flex"
        :aria-label="t('nav.principal')"
      >
        <UButton
          to="/"
          :variant="variante('/')"
          :color="colorDe('/')"
          :label="t('nav.inicio')"
        />
        <UButton
          to="/disponibilidad"
          :variant="variante('/disponibilidad')"
          :color="colorDe('/disponibilidad')"
          :label="t('nav.disponibilidad')"
        />

        <UDropdownMenu v-if="esPersonal" :items="menuGestion">
          <UButton
            variant="ghost"
            color="neutral"
            :label="t('nav.gestion')"
            trailing-icon="i-lucide-chevron-down"
          />
        </UDropdownMenu>
      </nav>

      <div class="ml-auto flex items-center gap-1.5">
        <USelect
          v-model="idiomaSeleccionado"
          :items="idiomasDisponibles"
          class="w-28"
          :aria-label="t('app.idioma')"
        />

        <UDropdownMenu v-if="cuenta" :items="menuCuenta">
          <UButton variant="ghost" color="neutral">
            <UIcon name="i-lucide-circle-user" class="size-4" />
            <span class="hidden max-w-36 truncate sm:inline">
              {{ cuenta.nombres }}
            </span>
          </UButton>
        </UDropdownMenu>

        <UButton
          v-else
          to="/ingresar"
          color="primary"
          icon="i-lucide-log-in"
          :aria-label="t('nav.ingresar')"
        >
          <span class="hidden sm:inline">{{ t('nav.ingresar') }}</span>
        </UButton>

        <UDropdownMenu class="md:hidden" :items="menuMovil">
          <UButton
            variant="ghost"
            color="neutral"
            icon="i-lucide-menu"
            :aria-label="t('nav.menu')"
          />
        </UDropdownMenu>
      </div>
    </div>
  </header>
</template>
