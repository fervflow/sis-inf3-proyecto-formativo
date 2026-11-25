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
const esCliente = computed(() => props.cuenta?.rol === 'CLIENTE')

const idiomaSeleccionado = computed<CodigoIdioma>({
  get: () => idioma.value,
  set: (valor) => establecerIdioma(valor),
})

const idiomasDisponibles = computed<{ label: string; value: CodigoIdioma; icon: string }[]>(
  () => [
    // Español latinoamericano: bandera de Bolivia, sede de la agencia.
    { label: t('idioma.es'), value: 'es', icon: 'i-circle-flags:bo' },
    { label: t('idioma.en'), value: 'en', icon: 'i-circle-flags:us' },
  ],
)

/** El modo de color en uso: la preferencia puede ser la del sistema. */
const colorMode = useColorMode()

/** El botón muestra un solo ícono: el del tema resuelto en pantalla. */
const iconoTema = computed(() =>
  colorMode.value === 'dark' ? 'i-lucide-moon' : 'i-lucide-sun',
)

const menuTema = computed<DropdownMenuItem[][]>(() => [
  [
    {
      label: t('tema.claro'),
      icon: 'i-lucide-sun',
      onSelect: () => {
        colorMode.preference = 'light'
      },
    },
    {
      label: t('tema.oscuro'),
      icon: 'i-lucide-moon',
      onSelect: () => {
        colorMode.preference = 'dark'
      },
    },
    {
      label: t('tema.sistema'),
      icon: 'i-lucide-monitor',
      onSelect: () => {
        colorMode.preference = 'system'
      },
    },
  ],
])

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
  // La gestión de salidas vive en «Próximas salidas»; el desplegable agrupa
  // lo exclusivamente administrativo.
  const items: DropdownMenuItem[] = [
    {
      label: t('nav.paquetes'),
      icon: 'i-lucide-map',
      to: '/admin/paquetes',
    },
    {
      label: t('nav.proveedores'),
      icon: 'i-lucide-handshake',
      to: '/admin/proveedores',
    },
    {
      label: t('nav.usuarios'),
      icon: 'i-lucide-users',
      to: '/admin/usuarios',
    },
  ]

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
    {
      label: t('nav.disponibilidad'),
      icon: 'i-lucide-calendar-days',
      to: '/disponibilidad',
    },
  ]

  if (esCliente.value) {
    principal.push({
      label: t('nav.misReservas'),
      icon: 'i-lucide-ticket',
      to: '/mis-reservas',
    })
  }

  if (esPersonal.value) {
    principal.push(
      {
        label: t('nav.clientes'),
        icon: 'i-lucide-contact',
        to: '/clientes',
      },
      {
        label: t('nav.cotizaciones'),
        icon: 'i-lucide-file-text',
        to: '/cotizaciones',
      },
      {
        label: t('nav.solicitudes'),
        icon: 'i-lucide-inbox',
        to: '/solicitudes',
      },
      {
        label: t('nav.reportes'),
        icon: 'i-lucide-chart-bar',
        to: '/reportes',
      },
    )
  }
  if (esAdmin.value) {
    principal.push(
      {
        label: t('nav.paquetes'),
        icon: 'i-lucide-map',
        to: '/admin/paquetes',
      },
      {
        label: t('nav.proveedores'),
        icon: 'i-lucide-handshake',
        to: '/admin/proveedores',
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
            class="truncate text-(length:--vt-texto-base) font-(--vt-texto-peso-fuerte)"
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
          to="/disponibilidad"
          :variant="variante('/disponibilidad')"
          :color="colorDe('/disponibilidad')"
          :label="t('nav.disponibilidad')"
        />

        <UButton
          v-if="esCliente"
          to="/mis-reservas"
          :variant="variante('/mis-reservas')"
          :color="colorDe('/mis-reservas')"
          :label="t('nav.misReservas')"
        />

        <!--
          Los enlaces de operación del personal van directos; solo lo
          exclusivamente administrativo queda en el desplegable «Gestión».
        -->
        <template v-if="esPersonal">
          <UButton
            to="/clientes"
            :variant="variante('/clientes')"
            :color="colorDe('/clientes')"
            :label="t('nav.clientes')"
          />
          <UButton
            to="/cotizaciones"
            :variant="variante('/cotizaciones')"
            :color="colorDe('/cotizaciones')"
            :label="t('nav.cotizaciones')"
          />
          <UButton
            to="/solicitudes"
            :variant="variante('/solicitudes')"
            :color="colorDe('/solicitudes')"
            :label="t('nav.solicitudes')"
          />
          <UButton
            to="/reportes"
            :variant="variante('/reportes')"
            :color="colorDe('/reportes')"
            :label="t('nav.reportes')"
          />
        </template>

        <UDropdownMenu v-if="esAdmin" :items="menuGestion">
          <UButton
            variant="ghost"
            color="neutral"
            :label="t('nav.gestion')"
            trailing-icon="i-lucide-chevron-down"
          />
        </UDropdownMenu>
      </nav>

      <div class="ml-auto flex items-center gap-1.5">
        <UDropdownMenu :items="menuTema" :content="{ align: 'end' }">
          <UButton
            variant="ghost"
            color="neutral"
            :icon="iconoTema"
            :aria-label="t('tema.titulo')"
          />
        </UDropdownMenu>

        <USelect
          v-model="idiomaSeleccionado"
          :items="idiomasDisponibles"
          class="w-36"
          :aria-label="t('app.idioma')"
        >
          <!-- La bandera del idioma en uso, junto a su nombre. -->
          <template #leading="{ item }">
            <UIcon
              v-if="item && 'icon' in item && item.icon"
              :name="item.icon"
              class="size-4 shrink-0"
            />
          </template>
        </USelect>

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
