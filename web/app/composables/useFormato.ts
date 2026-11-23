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

  /** Fecha ISO corta en el idioma de la aplicación. */
  function fecha(valor: string): string {
    if (!valor) return ''
    const [anio, mes, dia] = valor.slice(0, 10).split('-').map(Number)
    if (!anio || !mes || !dia) return valor

    return new Intl.DateTimeFormat(local.value, {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      timeZone: 'UTC',
    }).format(new Date(Date.UTC(anio, mes - 1, dia)))
  }

  /** Fecha y hora de un instante ISO, en el idioma de la aplicación. */
  function fechaHora(valor: string): string {
    if (!valor) return ''
    return new Intl.DateTimeFormat(local.value, {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(new Date(valor))
  }

  return { moneda, fecha, fechaHora }
}
