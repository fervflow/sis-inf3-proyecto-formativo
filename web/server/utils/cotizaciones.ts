/**
 * Cotizaciones.
 *
 * Una cotización se prepara a partir de un cliente y una salida. No
 * descuenta cupo ni crea una reserva: es una propuesta económica. El
 * número se genera solo y la cotización guarda sus condiciones y su plazo
 * de validez.
 */
import { desc, eq, sql } from 'drizzle-orm'
import { z } from 'zod'
import * as schema from '../../db/schema'
import type { CotizacionAdmin } from '#shared/types/api'
import type { EstadoCotizacion } from '#shared/types/domain'
import { consultar } from './db'

const fecha = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'datos_invalidos')

/** Cuerpo del alta y de la edición de una cotización. */
export const esquemaCotizacion = z
  .object({
    idCliente: z.coerce.number().int().positive(),
    idSalida: z.coerce.number().int().positive(),
    cantidadPasajeros: z.coerce.number().int().min(1).max(32_767),
    precioUnitario: z.coerce.number().min(0.01).max(9_999_999.99),
    descuento: z.coerce.number().min(0).max(9_999_999.99).default(0),
    fechaValidez: fecha,
    condiciones: z.string().trim().max(2000).nullable().optional(),
    observaciones: z.string().trim().max(1000).nullable().optional(),
    estado: z
      .enum(['borrador', 'enviada', 'aceptada', 'rechazada', 'vencida'])
      .default('borrador'),
  })
  .refine(
    (datos) =>
      datos.descuento <= datos.cantidadPasajeros * datos.precioUnitario,
    { message: 'descuento_invalido', path: ['descuento'] },
  )

/** Fila de la cotización con cliente, salida y paquete resueltos. */
interface FilaCotizacion {
  idCotizacion: number
  numero: string
  idCliente: number
  cliente: string
  documento: string
  idSalida: number
  codigoPaquete: string
  paquete: string
  fechaSalida: string
  fechaRetorno: string
  cantidadPasajeros: number
  precioUnitario: string
  subtotal: string | null
  descuento: string
  total: string | null
  estado: string
  fechaEmision: string
  fechaValidez: string
  condiciones: string | null
  observaciones: string | null
  fechaCreacion: Date
  /** Reserva originada por la cotización, si existe (RN-COT-08). */
  idReservaOriginada: number | null
}

/** Convierte la fila de la base en lo que consume la interfaz. */
function aCotizacionAdmin(fila: FilaCotizacion): CotizacionAdmin {
  return {
    idCotizacion: fila.idCotizacion,
    numero: fila.numero,
    idCliente: fila.idCliente,
    cliente: fila.cliente,
    documento: fila.documento,
    idSalida: fila.idSalida,
    codigoPaquete: fila.codigoPaquete,
    paquete: fila.paquete,
    fechaSalida: fila.fechaSalida,
    fechaRetorno: fila.fechaRetorno,
    cantidadPasajeros: fila.cantidadPasajeros,
    precioUnitario: fila.precioUnitario,
    subtotal: fila.subtotal ?? '0.00',
    descuento: fila.descuento,
    total: fila.total ?? '0.00',
    estado: fila.estado as EstadoCotizacion,
    fechaEmision: fila.fechaEmision,
    fechaValidez: fila.fechaValidez,
    condiciones: fila.condiciones,
    observaciones: fila.observaciones,
    fechaCreacion: fila.fechaCreacion.toISOString(),
    idReservaOriginada:
      fila.idReservaOriginada === null ? null : Number(fila.idReservaOriginada),
  }
}

/** Fecha de hoy en formato ISO corto. */
function hoyIso(): string {
  return new Date().toISOString().slice(0, 10)
}

/** Marca como vencidas las cotizaciones fuera de plazo. */
export async function vencerCotizaciones(): Promise<void> {
  await consultar(sql`select turismo.fn_vencer_cotizaciones()`)
}

/** Consulta base de cotizaciones. */
function consultaCotizaciones() {
  return useDb()
    .select({
      idCotizacion: schema.cotizacion.idCotizacion,
      numero: schema.cotizacion.numero,
      idCliente: schema.cotizacion.idCliente,
      cliente: sql<string>`${schema.cliente.nombres} || ' ' || ${schema.cliente.apellidos}`,
      documento: sql<string>`${schema.cliente.tipoDocumento} || ' ' || ${schema.cliente.numeroDocumento}`,
      idSalida: schema.cotizacion.idSalida,
      codigoPaquete: schema.paquete.codigo,
      paquete: schema.paquete.nombre,
      fechaSalida: schema.salida.fechaSalida,
      fechaRetorno: schema.salida.fechaRetorno,
      cantidadPasajeros: schema.cotizacion.cantidadPasajeros,
      precioUnitario: schema.cotizacion.precioUnitario,
      subtotal: schema.cotizacion.subtotal,
      descuento: schema.cotizacion.descuento,
      total: schema.cotizacion.total,
      estado: schema.cotizacion.estado,
      fechaEmision: schema.cotizacion.fechaEmision,
      fechaValidez: schema.cotizacion.fechaValidez,
      condiciones: schema.cotizacion.condiciones,
      observaciones: schema.cotizacion.observaciones,
      fechaCreacion: schema.cotizacion.fechaCreacion,
      // La reserva originada por la cotización, para no repetirla desde
      // la bandeja (RN-COT-08: el vínculo es único).
      idReservaOriginada: sql<number | null>`(
        select r2.id_reserva
        from ${schema.reserva} r2
        where r2.id_cotizacion = ${schema.cotizacion.idCotizacion}
        order by r2.id_reserva
        limit 1
      )`,
    })
    .from(schema.cotizacion)
    .innerJoin(
      schema.cliente,
      eq(schema.cliente.idCliente, schema.cotizacion.idCliente),
    )
    .innerJoin(
      schema.salida,
      eq(schema.salida.idSalida, schema.cotizacion.idSalida),
    )
    .innerJoin(
      schema.paquete,
      eq(schema.paquete.idPaquete, schema.salida.idPaquete),
    )
}

/** Lista completa de cotizaciones. */
export async function listarCotizaciones(): Promise<CotizacionAdmin[]> {
  await vencerCotizaciones()

  const filas = await consultaCotizaciones().orderBy(
    desc(schema.cotizacion.fechaEmision),
    desc(schema.cotizacion.numero),
  )

  return filas.map(aCotizacionAdmin)
}

/** Una cotización por identificador. */
export async function obtenerCotizacion(
  id: number,
): Promise<CotizacionAdmin | null> {
  await vencerCotizaciones()

  const [fila] = await consultaCotizaciones()
    .where(eq(schema.cotizacion.idCotizacion, id))
    .limit(1)

  return fila ? aCotizacionAdmin(fila) : null
}

/** Comprueba cliente y salida antes de guardar. */
async function validarReferencias(
  datos: z.infer<typeof esquemaCotizacion>,
): Promise<void> {
  const db = useDb()

  const [cliente] = await db
    .select({ idCliente: schema.cliente.idCliente })
    .from(schema.cliente)
    .where(eq(schema.cliente.idCliente, datos.idCliente))
    .limit(1)

  if (!cliente) {
    throw createError({ statusCode: 404, statusMessage: 'cliente_inexistente' })
  }

  const [salida] = await db
    .select({
      estado: schema.salida.estado,
      fechaSalida: schema.salida.fechaSalida,
      estadoPaquete: schema.paquete.estado,
    })
    .from(schema.salida)
    .innerJoin(
      schema.paquete,
      eq(schema.paquete.idPaquete, schema.salida.idPaquete),
    )
    .where(eq(schema.salida.idSalida, datos.idSalida))
    .limit(1)

  if (!salida) {
    throw createError({ statusCode: 404, statusMessage: 'salida_inexistente' })
  }
  if (
    salida.estadoPaquete !== 'activo' ||
    !['programada', 'confirmada'].includes(salida.estado)
  ) {
    throw createError({
      statusCode: 400,
      statusMessage: 'salida_no_disponible',
    })
  }
  if (salida.fechaSalida < hoyIso()) {
    throw createError({ statusCode: 400, statusMessage: 'fecha_pasada' })
  }

  // La cotización no descuenta cupo, pero tampoco puede prometer más
  // pasajeros que los disponibles: sería una oferta imposible. La reserva
  // que nazca de ella vuelve a verificarlo dentro de la transacción.
  const [disponibilidad] = await consultar<{
    cupo_disponible: string | number
  }>(sql`
    select cupo_disponible
    from turismo.vista_disponibilidad_salida
    where id_salida = ${datos.idSalida}
  `)

  if (Number(disponibilidad?.cupo_disponible) < datos.cantidadPasajeros) {
    throw createError({ statusCode: 400, statusMessage: 'cupo_insuficiente' })
  }

  if (datos.fechaValidez < hoyIso()) {
    throw createError({ statusCode: 400, statusMessage: 'validez_invalida' })
  }
}

/** Alta de una cotización. */
export async function crearCotizacion(
  datos: z.infer<typeof esquemaCotizacion>,
  idUsuario: string,
): Promise<CotizacionAdmin> {
  if (!['borrador', 'enviada'].includes(datos.estado)) {
    throw createError({
      statusCode: 400,
      statusMessage: 'transicion_invalida',
    })
  }

  await validarReferencias(datos)

  const [codigo] = await consultar<{ numero: string }>(
    sql`select turismo.fn_generar_codigo_cotizacion() as numero`,
  )

  if (!codigo?.numero) {
    throw createError({ statusCode: 500, statusMessage: 'datos_invalidos' })
  }

  const [creada] = await useDb()
    .insert(schema.cotizacion)
    .values({
      numero: codigo.numero,
      idCliente: datos.idCliente,
      idSalida: datos.idSalida,
      idUsuario,
      cantidadPasajeros: datos.cantidadPasajeros,
      precioUnitario: datos.precioUnitario.toFixed(2),
      descuento: datos.descuento.toFixed(2),
      estado: datos.estado,
      fechaValidez: datos.fechaValidez,
      condiciones: datos.condiciones || null,
      observaciones: datos.observaciones || null,
    })
    .returning({ idCotizacion: schema.cotizacion.idCotizacion })

  if (!creada) {
    throw createError({ statusCode: 500, statusMessage: 'alta_incompleta' })
  }

  const cotizacion = await obtenerCotizacion(creada.idCotizacion)
  if (!cotizacion) {
    throw createError({ statusCode: 500, statusMessage: 'alta_incompleta' })
  }
  return cotizacion
}

/** Edición de una cotización mientras no sea terminal. */
export async function actualizarCotizacion(
  id: number,
  datos: z.infer<typeof esquemaCotizacion>,
): Promise<CotizacionAdmin> {
  const actual = await obtenerCotizacion(id)
  if (!actual) {
    throw createError({
      statusCode: 404,
      statusMessage: 'cotizacion_inexistente',
    })
  }

  if (['aceptada', 'rechazada', 'vencida'].includes(actual.estado)) {
    throw createError({
      statusCode: 400,
      statusMessage: 'cotizacion_no_editable',
    })
  }

  const permitidas: Record<string, string[]> = {
    borrador: ['borrador', 'enviada', 'aceptada', 'rechazada'],
    enviada: ['enviada', 'aceptada', 'rechazada'],
  }

  if (!permitidas[actual.estado]?.includes(datos.estado)) {
    throw createError({
      statusCode: 400,
      statusMessage: 'transicion_invalida',
    })
  }

  await validarReferencias(datos)

  await useDb()
    .update(schema.cotizacion)
    .set({
      idCliente: datos.idCliente,
      idSalida: datos.idSalida,
      cantidadPasajeros: datos.cantidadPasajeros,
      precioUnitario: datos.precioUnitario.toFixed(2),
      descuento: datos.descuento.toFixed(2),
      estado: datos.estado,
      fechaValidez: datos.fechaValidez,
      condiciones: datos.condiciones || null,
      observaciones: datos.observaciones || null,
    })
    .where(eq(schema.cotizacion.idCotizacion, id))

  const actualizada = await obtenerCotizacion(id)
  if (!actualizada) {
    throw createError({
      statusCode: 404,
      statusMessage: 'cotizacion_inexistente',
    })
  }
  return actualizada
}
