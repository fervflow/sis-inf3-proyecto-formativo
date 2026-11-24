/**
 * Límites y cálculos de los pagos de una reserva.
 *
 * El anticipo tiene un mínimo relativo al total y el saldo paga el resto
 * completo; la pasarela web es una simulación que genera la referencia.
 * Las reglas viven en `fn_registrar_pago` y `fn_confirmar_reserva`
 * (bd/esquema.sql, RN-PAG-01 y RN-RES-18); este archivo las refleja para
 * que la interfaz y Zod muestren los mismos límites.
 */

/** Porcentaje mínimo del total que debe cubrir el anticipo. */
export const ANTICIPO_MINIMO_PORCENTAJE = 30

/** Horas de vida de una solicitud pendiente (RN-RES-05). */
export const SOLICITUD_HORAS_VIGENCIA = 24

/** Métodos de pago de la pasarela simulada (canal web). */
export const METODOS_WEB = ['banca_movil', 'qr'] as const

/** Métodos de pago que registra el personal en la oficina. */
export const METODOS_OFICINA = ['efectivo', 'transferencia', 'tarjeta', 'otro'] as const

/** Monto mínimo del anticipo de una reserva, en el mismo formato del total. */
export function montoMinimoAnticipo(montoTotal: string): number {
  const total = Number(montoTotal) || 0
  return Math.round(total * (ANTICIPO_MINIMO_PORCENTAJE / 100) * 100) / 100
}

/** Saldo pendiente: total menos lo ya abonado validado. */
export function saldoPendienteDe(
  montoTotal: string,
  abonadoValidado: string | number,
): number {
  const total = Number(montoTotal) || 0
  const abonado = Number(abonadoValidado) || 0
  return Math.round((total - abonado) * 100) / 100
}

/** Referencia simulada de la pasarela (mock), p. ej. «MOCK-QR-4F7K2M». */
export function referenciaSimulada(tipo: string): string {
  const letras = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
  let sufijo = ''
  for (let i = 0; i < 6; i += 1) {
    sufijo += letras[Math.floor(Math.random() * letras.length)]
  }
  return `MOCK-${tipo.toUpperCase()}-${sufijo}`
}
