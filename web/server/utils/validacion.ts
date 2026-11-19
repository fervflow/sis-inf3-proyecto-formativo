/**
 * Validación de la entrada de las rutas.
 *
 * Zod describe la forma del cuerpo; este ayudante convierte un error de
 * validación en un 400 con un código traducible. La interfaz decide el
 * texto: el servidor no devuelve mensajes en un idioma.
 */
import type { H3Event } from 'h3'
import { z } from 'zod'

/** Lee y valida el cuerpo de la petición. */
export async function leerCuerpo<T extends z.ZodType>(
  event: H3Event,
  esquema: T,
): Promise<z.infer<T>> {
  try {
    return esquema.parse(await readBody(event)) as z.infer<T>
  } catch (error) {
    throw createError({
      statusCode: 400,
      statusMessage: primerCodigo(error) ?? 'datos_invalidos',
    })
  }
}

/** Lee y valida la consulta de la URL. */
export function leerConsulta<T extends z.ZodType>(
  event: H3Event,
  esquema: T,
): z.infer<T> {
  try {
    return esquema.parse(getQuery(event)) as z.infer<T>
  } catch (error) {
    throw createError({
      statusCode: 400,
      statusMessage: primerCodigo(error) ?? 'datos_invalidos',
    })
  }
}

/**
 * Código propio del primer problema de validación.
 *
 * Un mensaje de Zod que sea solo minúsculas y guion bajo se usa como
 * código traducible; los mensajes largos caen en `datos_invalidos`.
 */
function primerCodigo(error: unknown): string | undefined {
  if (!(error instanceof z.ZodError)) {
    return undefined
  }
  return error.issues.find((problema) => /^[a-z_]+$/.test(problema.message))
    ?.message
}

/** Indica si el error de PostgreSQL es una violación de unicidad. */
export function esDuplicado(error: unknown): boolean {
  return (error as { code?: string }).code === '23505'
}
