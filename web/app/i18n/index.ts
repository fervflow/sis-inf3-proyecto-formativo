/**
 * Mensajes de la interfaz.
 *
 * Los textos viven centralizados: cada idioma es un objeto con las mismas
 * claves. `ClaveMensaje` es el tipo de esas claves, de modo que una clave
 * inexistente o mal escrita no compila.
 *
 * Para agregar un texto: primero la clave en `es.ts` (que define el tipo),
 * después el mismo texto en los demás idiomas.
 */

import { en } from './locales/en'
import { es } from './locales/es'

/** Clave de un texto de la interfaz. */
export type ClaveMensaje = keyof typeof es

/** Un idioma completo: todas las claves con su texto. */
export type Mensajes = Record<ClaveMensaje, string>

/** Los idiomas disponibles. */
export const idiomas = { es, en } satisfies Record<string, Mensajes>

/** Código de idioma. */
export type CodigoIdioma = keyof typeof idiomas

/** El idioma por defecto. */
export const IDIOMA_POR_DEFECTO: CodigoIdioma = 'es'

export { en, es }
