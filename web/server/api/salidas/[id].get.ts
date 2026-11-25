import { and, asc, eq, inArray, sql } from 'drizzle-orm'
import * as schema from '../../../db/schema'
import type {
  AsignacionSalidaResumen,
  DetalleServicioResumen,
  FichaSalida,
  ItinerarioDia,
  LugarResumen,
  ProveedorFicha,
  ServicioResumen,
} from '#shared/types/api'
import type {
  EstadoPaquete,
  EstadoSalida,
  TipoLugar,
  TipoProveedor,
  TipoRecorrido,
} from '#shared/types/domain'
import {
  ROL_ADMIN,
  ROL_PERSONAL,
  sesionActual,
} from '../../utils/autorizacion'

/**
 * Ficha de una salida (HU-18).
 *
 * El paquete, el mapa del recorrido, el itinerario por días, los
 * servicios incluidos con sus detalles y exclusiones, y los proveedores
 * con los detalles de su servicio (RN-SAL-24). Los costos internos de
 * los vínculos solo los ve el personal: el visitante y el cliente ven
 * la oferta sin números internos.
 *
 * Para el visitante y el cliente solo hay ficha de una salida
 * programada o confirmada de un paquete activo; el personal consulta
 * cualquier salida, con su estado. El cupo se calcula igual que en la
 * vista de disponibilidad: las solicitudes cuyo plazo venció dejan de
 * ocupar.
 */
export default defineEventHandler(async (event): Promise<FichaSalida> => {
  const id = Number(getRouterParam(event, 'id'))

  if (!Number.isInteger(id) || id < 1) {
    throw createError({ statusCode: 400, statusMessage: 'datos_invalidos' })
  }

  const sesion = sesionActual(event)
  const esPersonal =
    !!sesion?.user &&
    (sesion.user.idRol === ROL_ADMIN || sesion.user.idRol === ROL_PERSONAL)

  const filtros = esPersonal
    ? [eq(schema.salida.idSalida, id)]
    : [
        eq(schema.salida.idSalida, id),
        eq(schema.paquete.estado, 'activo'),
        eq(schema.salida.estado, 'programada'),
      ]

  const db = useDb()

  const [fila] = await db
    .select({
      idSalida: schema.salida.idSalida,
      codigo: schema.salida.codigo,
      fechaSalida: schema.salida.fechaSalida,
      fechaRetorno: schema.salida.fechaRetorno,
      cupoMaximo: schema.salida.cupoMaximo,
      precio: schema.salida.precio,
      puntoEncuentro: schema.salida.puntoEncuentro,
      estadoSalida: schema.salida.estado,
      idPaquete: schema.paquete.idPaquete,
      codigoPaquete: schema.paquete.codigo,
      paquete: schema.paquete.nombre,
      descripcion: schema.paquete.descripcion,
      tipoRecorrido: schema.paquete.tipoRecorrido,
      duracionDias: schema.paquete.duracionDias,
      precioBase: schema.paquete.precioBase,
      estadoPaquete: schema.paquete.estado,
      serviciosDetalle: schema.paquete.serviciosDetalle,
      serviciosExcluidos: schema.paquete.serviciosExcluidos,
      idLugarDestino: schema.paquete.idLugarDestino,
      idLugarOrigen: schema.paquete.idLugarOrigen,
      // El cupo sale de la misma cuenta de la vista de disponibilidad:
      // pendientes vigentes más confirmadas.
      pasajerosPendientes: sql<number>`(
        select coalesce(sum(r.cantidad_pasajeros), 0)::int
        from ${schema.reserva} r
        where r.id_salida = ${schema.salida.idSalida}
          and r.estado = 'pendiente'
          and (r.fecha_expiracion is null or r.fecha_expiracion > now())
      )`,
      pasajerosConfirmados: sql<number>`(
        select coalesce(sum(r.cantidad_pasajeros), 0)::int
        from ${schema.reserva} r
        where r.id_salida = ${schema.salida.idSalida}
          and r.estado = 'confirmada'
      )`,
    })
    .from(schema.salida)
    .innerJoin(
      schema.paquete,
      eq(schema.paquete.idPaquete, schema.salida.idPaquete),
    )
    .where(and(...filtros))
    .limit(1)

  if (!fila) {
    throw createError({ statusCode: 404, statusMessage: 'salida_inexistente' })
  }

  // Origen y destino comercial del paquete (RN-PAQ-14).
  const idsLugares = [fila.idLugarDestino, fila.idLugarOrigen].filter(
    (valor): valor is number => typeof valor === 'number',
  )
  const filasLugares = idsLugares.length
    ? await db
        .select({
          idLugar: schema.lugar.idLugar,
          nombre: schema.lugar.nombre,
        })
        .from(schema.lugar)
        .where(inArray(schema.lugar.idLugar, idsLugares))
    : []
  const destino = filasLugares.find((l) => l.idLugar === fila.idLugarDestino)
  const origen = filasLugares.find((l) => l.idLugar === fila.idLugarOrigen)

  // Paradas con coordenadas, en orden: el mapa de la ficha (RN-LUG-02).
  const filasParadas = await db
    .select({
      idLugar: schema.lugar.idLugar,
      codigo: schema.lugar.codigo,
      nombre: schema.lugar.nombre,
      tipo: schema.lugar.tipo,
      direccion: schema.lugar.direccion,
      latitud: schema.lugar.latitud,
      longitud: schema.lugar.longitud,
    })
    .from(schema.paqueteParada)
    .innerJoin(
      schema.lugar,
      eq(schema.lugar.idLugar, schema.paqueteParada.idLugar),
    )
    .where(eq(schema.paqueteParada.idPaquete, fila.idPaquete))
    .orderBy(asc(schema.paqueteParada.orden))

  const paradas: LugarResumen[] = filasParadas.map((p) => ({
    idLugar: p.idLugar,
    codigo: p.codigo,
    nombre: p.nombre,
    tipo: p.tipo as TipoLugar,
    direccion: p.direccion,
    latitud: p.latitud === null ? null : Number(p.latitud),
    longitud: p.longitud === null ? null : Number(p.longitud),
  }))

  // Itinerario por días (RN-PAQ-18).
  const filasItinerario = await db
    .select({
      dia: schema.paqueteItinerario.dia,
      titulo: schema.paqueteItinerario.titulo,
      detalle: schema.paqueteItinerario.detalle,
    })
    .from(schema.paqueteItinerario)
    .where(eq(schema.paqueteItinerario.idPaquete, fila.idPaquete))
    .orderBy(asc(schema.paqueteItinerario.dia))

  const itinerario: ItinerarioDia[] = filasItinerario.map((d) => ({
    dia: d.dia,
    titulo: d.titulo,
    detalle: d.detalle,
  }))

  // Servicios que cubre el precio (RN-SER-04).
  const servicios: ServicioResumen[] = await db
    .select({
      idServicio: schema.servicio.idServicio,
      codigo: schema.servicio.codigo,
      nombre: schema.servicio.nombre,
      orden: schema.servicio.orden,
    })
    .from(schema.paqueteServicio)
    .innerJoin(
      schema.servicio,
      eq(schema.servicio.idServicio, schema.paqueteServicio.idServicio),
    )
    .where(eq(schema.paqueteServicio.idPaquete, fila.idPaquete))
    .orderBy(asc(schema.servicio.orden), asc(schema.servicio.nombre))

  // Proveedores del paquete, con los detalles de su servicio
  // (RN-PRV-08). El costo interno solo viaja para el personal.
  const filasVinculos = await db
    .select({
      idProveedor: schema.proveedor.idProveedor,
      nombre: schema.proveedor.nombre,
      servicio: schema.paqueteProveedor.servicio,
      detalle: schema.paqueteProveedor.detalle,
      costo: schema.paqueteProveedor.costo,
    })
    .from(schema.paqueteProveedor)
    .innerJoin(
      schema.proveedor,
      eq(schema.proveedor.idProveedor, schema.paqueteProveedor.idProveedor),
    )
    .where(eq(schema.paqueteProveedor.idPaquete, fila.idPaquete))
    .orderBy(asc(schema.proveedor.nombre))

  const idsProveedores = filasVinculos.map((v) => v.idProveedor)
  const filasDetalles = idsProveedores.length
    ? await db
        .select({
          idProveedor: schema.proveedorServicio.idProveedor,
          tipo: schema.proveedorServicio.tipo,
          titulo: schema.proveedorServicio.titulo,
          detalle: schema.proveedorServicio.detalle,
        })
        .from(schema.proveedorServicio)
        .where(inArray(schema.proveedorServicio.idProveedor, idsProveedores))
        .orderBy(
          asc(schema.proveedorServicio.idProveedor),
          asc(schema.proveedorServicio.orden),
        )
    : []

  const proveedores: ProveedorFicha[] = filasVinculos.map((vinculo) => ({
    idProveedor: vinculo.idProveedor,
    nombre: vinculo.nombre,
    servicio: vinculo.servicio as TipoProveedor,
    detalle: vinculo.detalle,
    // El costo interno solo lo ve el personal (RN-SAL-24).
    costo: esPersonal ? vinculo.costo : null,
    detallesServicio: filasDetalles
      .filter(
        (d) =>
          d.idProveedor === vinculo.idProveedor &&
          d.tipo === vinculo.servicio,
      )
      .map((d) => ({
        tipo: d.tipo as TipoProveedor,
        titulo: d.titulo,
        detalle: d.detalle,
      })),
  }))

  // Asignaciones operativas de esta salida (RN-SAL-23).
  const filasAsignaciones = await db
    .select({
      idProveedor: schema.proveedor.idProveedor,
      nombre: schema.proveedor.nombre,
      servicio: schema.salidaProveedor.servicio,
      detalle: schema.salidaProveedor.detalle,
    })
    .from(schema.salidaProveedor)
    .innerJoin(
      schema.proveedor,
      eq(schema.proveedor.idProveedor, schema.salidaProveedor.idProveedor),
    )
    .where(eq(schema.salidaProveedor.idSalida, id))
    .orderBy(asc(schema.proveedor.nombre))

  const asignaciones: AsignacionSalidaResumen[] = filasAsignaciones.map(
    (a) => ({
      idProveedor: a.idProveedor,
      nombre: a.nombre,
      servicio: a.servicio as TipoProveedor,
      detalle: a.detalle,
    }),
  )

  const disponible = Math.max(
    fila.cupoMaximo - fila.pasajerosConfirmados - fila.pasajerosPendientes,
    0,
  )

  return {
    idSalida: fila.idSalida,
    codigoSalida: fila.codigo,
    codigoPaquete: fila.codigoPaquete,
    paquete: fila.paquete,
    descripcion: fila.descripcion,
    tipoRecorrido: fila.tipoRecorrido as TipoRecorrido,
    duracionDias: fila.duracionDias,
    destino: destino?.nombre ?? null,
    origen: origen?.nombre ?? null,
    paradas,
    itinerario,
    servicios,
    serviciosDetalle: fila.serviciosDetalle,
    serviciosExcluidos: fila.serviciosExcluidos,
    fechaSalida: fila.fechaSalida,
    fechaRetorno: fila.fechaRetorno,
    cupoMaximo: fila.cupoMaximo,
    pasajerosPendientes: fila.pasajerosPendientes,
    pasajerosConfirmados: fila.pasajerosConfirmados,
    cupoDisponible: disponible,
    precio: fila.precio,
    precioBase: fila.precioBase,
    puntoEncuentro: fila.puntoEncuentro,
    estado: fila.estadoSalida as EstadoSalida,
    estadoPaquete: fila.estadoPaquete as EstadoPaquete,
    proveedores,
    asignaciones,
  }
})
