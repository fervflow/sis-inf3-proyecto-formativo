import type { LugarResumen } from '#shared/types/api'
import { exigirAdmin } from '../../utils/autorizacion'
import { crearLugar, esquemaLugar } from '../../utils/lugares'
import { leerCuerpo } from '../../utils/validacion'

/**
 * Alta de un lugar del catálogo. Si ya existe por identificador de
 * OpenStreetMap o por nombre, devuelve el existente.
 */
export default defineEventHandler(async (event): Promise<LugarResumen> => {
  exigirAdmin(event)
  const datos = await leerCuerpo(event, esquemaLugar)
  return crearLugar(datos)
})
