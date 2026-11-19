/**
 * Validación de la entrada de las rutas.
 *
 * Zod describe la forma del cuerpo; este ayudante convierte un error de
 * validación en un 400 con un código traducible. La interfaz decide el
 * texto: el servidor no devuelve mensajes en un idioma.
 */
import type { H3Event } from 'h3'
import type { z } from 'zod'

/** Lee y valida el cuerpo de la petición. */
export async function leerCuerpo<T extends z.ZodType>(
  event: H3Event,
  esquema: T,
): Promise<z.infer<T>> {
  try {
    return esquema.parse(await readBody(event)) as z.infer<T>
  } catch {
    throw createError({ statusCode: 400, statusMessage: 'datos_invalidos' })
  }
}
