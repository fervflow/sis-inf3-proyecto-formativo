/**
 * Textos de la interfaz.
 *
 * El composable `useTexto()` es la única forma de obtener un texto en un
 * componente. Ninguna plantilla escribe cadenas literales que la persona
 * usuaria vaya a leer.
 */
import {
  IDIOMA_POR_DEFECTO,
  idiomas,
  type ClaveMensaje,
  type CodigoIdioma,
} from '~/i18n'

/**
 * Devuelve el traductor de textos y el idioma en uso.
 *
 * ```ts
 * const { t } = useTexto()
 * t('disponibilidad.columnas.cupo')
 * ```
 */
export function useTexto() {
  const idioma = useCookie<CodigoIdioma>('idioma', {
    default: () => IDIOMA_POR_DEFECTO,
    sameSite: 'lax',
  })

  const codigo = computed<CodigoIdioma>(() =>
    idioma.value in idiomas ? idioma.value : IDIOMA_POR_DEFECTO,
  )

  /**
   * Traduce una clave. Los marcadores `{nombre}` se sustituyen con los
   * valores recibidos.
   */
  function t(
    clave: ClaveMensaje,
    valores?: Record<string, string | number>,
  ): string {
    const plantilla = idiomas[codigo.value][clave] ?? idiomas.es[clave] ?? clave
    if (!valores) {
      return plantilla
    }
    return plantilla.replace(/\{(\w+)\}/g, (__, nombre: string) =>
      nombre in valores ? String(valores[nombre]) : `{${nombre}}`,
    )
  }

  /** Cambia el idioma de la interfaz. */
  function establecerIdioma(nuevo: CodigoIdioma) {
    idioma.value = nuevo
  }

  return { idioma: codigo, t, establecerIdioma }
}
