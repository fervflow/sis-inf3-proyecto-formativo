/**
 * Formato de datos para la interfaz.
 *
 * El idioma manda sobre el formato: los números y la moneda se escriben
 * con las convenciones del idioma elegido, no con una fija.
 */
export function useFormato() {
  const { idioma } = useTexto()

  const local = computed(() => (idioma.value === 'en' ? 'en-US' : 'es-BO'))

  /** Importe en bolivianos. */
  function moneda(valor: string | number): string {
    return new Intl.NumberFormat(local.value, {
      style: 'currency',
      currency: 'BOB',
    }).format(Number(valor))
  }

  return { moneda }
}
