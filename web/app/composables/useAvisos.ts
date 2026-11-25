import type { ClaveMensaje } from '~/i18n'

/**
 * Avisos flotantes del resultado de una acción.
 *
 * El sistema de diseño muestra el resultado de una acción con un aviso
 * flotante (toast): no interrumpen el trabajo y se leen sin recorrer la
 * página buscando el mensaje. Aquí se centraliza la forma del aviso para
 * que todas las vistas avisen igual: éxito, error de la API o aviso de
 * atención.
 */
export function useAvisos() {
  const { t } = useTexto()
  const mensajeDeError = useMensajeError()

  /** Aviso de éxito con el texto de la acción completada. */
  function exito(
    clave: ClaveMensaje,
    valores?: Record<string, string | number>,
  ) {
    useToast().add({
      title: t(clave, valores),
      color: 'success',
      icon: 'i-lucide-circle-check',
    })
  }

  /** Aviso de error con el texto del código que devolvió la API. */
  function fallo(fallo: unknown) {
    useToast().add({
      title: mensajeDeError(fallo),
      color: 'error',
      icon: 'i-lucide-circle-alert',
    })
  }

  /** Aviso de atención: la acción no falló, pero algo falta. */
  function atencion(
    clave: ClaveMensaje,
    valores?: Record<string, string | number>,
  ) {
    useToast().add({
      title: t(clave, valores),
      color: 'warning',
      icon: 'i-lucide-triangle-alert',
      duration: 0,
    })
  }

  return { exito, fallo, atencion }
}
