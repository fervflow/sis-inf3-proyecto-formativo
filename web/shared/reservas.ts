/**
 * Límites de las solicitudes de reserva del canal web.
 *
 * El formulario anónimo no debe poder retener todo el cupo de una salida:
 * cada solicitud web admite pocos pasajeros y, en conjunto, las pendientes
 * vigentes de una salida no retienen más que una fracción del cupo. Los
 * grupos mayores se atienden por la oficina, en el canal personal.
 *
 * La regla vive en `fn_crear_reserva` (bd/esquema.sql, RN-RES-15 y
 * RN-RES-16); este archivo la refleja para que la interfaz y Zod muestren
 * los mismos límites.
 */

/** Máximo de pasajeros por solicitud del canal web. */
export const SOLICITUD_WEB_MAXIMO_PASAJEROS = 4

/**
 * Porcentaje del cupo máximo que las solicitudes web pendientes vigentes
 * pueden retener en una misma salida.
 */
export const RETENCION_WEB_PORCENTAJE = 50
