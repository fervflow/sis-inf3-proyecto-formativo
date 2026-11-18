/**
 * Cliente de la API.
 *
 * Envuelve `$fetch` para que las vistas manejen los estados de la misma
 * manera: mientras carga, con error, y con el dato.
 */
export interface EstadoPeticion<T> {
  cargando: Ref<boolean>
  error: Ref<string | null>
  datos: Ref<T | null>
}

/**
 * Devuelve una función para pedir datos a la API de la aplicación.
 *
 * ```ts
 * const { cargando, error, datos, pedir } = useApi<RespuestaDisponibilidad>()
 * await pedir('/api/disponibilidad')
 * ```
 */
export function useApi<T>() {
  const cargando = ref(false)
  const error = ref<string | null>(null)
  const datos = ref<T | null>(null)

  /** Ejecuta la petición y guarda el resultado o el error. */
  async function pedir(url: string, opciones?: Parameters<typeof $fetch<T>>[1]) {
    cargando.value = true
    error.value = null
    try {
      datos.value = await $fetch<T>(url, opciones)
      return datos.value
    } catch (fallo) {
      error.value = (fallo as Error).message
      return null
    } finally {
      cargando.value = false
    }
  }

  return { cargando, error, datos, pedir }
}
