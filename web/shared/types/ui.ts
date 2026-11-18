/**
 * Tipos de los componentes de la interfaz.
 *
 * Los tipos que usan varias capas viven aquí, en `shared/`, para que el
 * servidor y la interfaz puedan compartirlos.
 */

/** Una columna de la tabla de datos. */
export interface ColumnaTabla<Fila = Record<string, unknown>> {
  /** Clave de la fila que se muestra. */
  clave: keyof Fila & string
  /** Texto de la cabecera. */
  etiqueta: string
  /** Alineación de la columna. */
  alineacion?: 'izquierda' | 'derecha' | 'centro'
}
