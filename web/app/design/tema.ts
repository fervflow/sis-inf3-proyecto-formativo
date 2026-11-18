/**
 * Tema de la aplicación.
 *
 * Nuxt UI es la implementación de la interfaz; este objeto decide qué
 * colores y qué variantes se usan. Los valores vienen de los tokens del
 * sistema de diseño (`app/design/tokens.css`), de modo que reestilizar la
 * aplicación es tocar los tokens y, si hace falta, este objeto.
 *
 * El detalle de los tokens está en `docs/design-system.md`.
 */
export const tema = {
  /** Colores semánticos de Nuxt UI. */
  colors: {
    primary: 'primary',
    secondary: 'neutral',
    neutral: 'neutral',
    success: 'success',
    info: 'info',
    warning: 'warning',
    error: 'error',
  },

  /** Variantes por defecto de los componentes. */
  button: {
    slots: {
      base: 'font-medium cursor-pointer',
    },
  },

  card: {
    slots: {
      base: 'ring-1 ring-(--vt-color-borde) shadow-(--vt-sombra-sm)',
      header: 'px-4 py-3',
      body: 'px-4 pb-4',
      footer: 'px-4 pb-4',
    },
  },

  table: {
    slots: {
      th: 'text-left text-xs uppercase tracking-wide text-(--vt-color-texto-suave)',
      td: 'text-sm',
    },
  },

  input: {
    slots: {
      base: 'w-full',
    },
  },
} as const

export type Tema = typeof tema
