import { sql } from 'drizzle-orm'
import { z } from 'zod'
import { exigirPersonal } from '../../../utils/autorizacion'
import { consultar } from '../../../utils/db'
import { codigoErrorPago } from '../../../utils/pagos'
import { leerCuerpo } from '../../../utils/validacion'

/** Cuerpo de la validación: por omisión valida; con `anular`, anula. */
const cuerpo = z.object({
  anular: z.boolean().optional(),
})

/**
 * Validación o anulación de un pago (HU-14).
 *
 * Solo el personal lo ejecuta, con su usuario y fecha (RN-PAG-04). Solo
 * un pago `registrado` puede validarse o anularse; la base lo comprueba.
 */
export default defineEventHandler(async (event): Promise<{ ok: true }> => {
  const sesion = exigirPersonal(event)
  const id = Number(getRouterParam(event, 'id'))

  if (!Number.isInteger(id) || id < 1) {
    throw createError({ statusCode: 400, statusMessage: 'datos_invalidos' })
  }

  const { anular } = await leerCuerpo(event, cuerpo)

  try {
    await consultar(sql`
      select turismo.fn_validar_pago(
        ${id}::bigint,
        ${sesion.user.id}::text,
        ${anular ?? false}::boolean
      ) as ok
    `)
  } catch (error) {
    if ((error as { statusCode?: number }).statusCode) throw error
    throw createError({
      statusCode: 400,
      statusMessage: codigoErrorPago(error),
    })
  }

  return { ok: true }
})
