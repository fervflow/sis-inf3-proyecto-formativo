/**
 * Recorrido resumido de un paquete.
 *
 * Une origen, paradas y destino en una sola línea: «Potosí → Uyuni →
 * Potosí». Cada punto es un nombre o un lugar con `nombre`; los que
 * repiten un punto ya listado no se repiten y un circuito vuelve a
 * mencionar el origen al final.
 */
type PuntoRecorrido = string | { nombre: string }

function nombreDe(punto: PuntoRecorrido): string {
  return typeof punto === 'string' ? punto : punto.nombre
}

export function useRecorrido() {
  function armar({
    origen,
    destino,
    paradas,
    circuito,
  }: {
    origen?: PuntoRecorrido | null
    destino?: PuntoRecorrido | null
    paradas?: PuntoRecorrido[] | null
    circuito?: boolean
  }): string {
    const partes: string[] = []
    if (origen) partes.push(nombreDe(origen))
    for (const parada of paradas ?? []) {
      const nombre = nombreDe(parada)
      if (!partes.includes(nombre)) partes.push(nombre)
    }
    if (destino && !partes.includes(nombreDe(destino))) {
      partes.push(nombreDe(destino))
    }
    if (circuito && origen && !partes.includes(nombreDe(origen))) {
      partes.push(nombreDe(origen))
    }

    return partes.join(' → ')
  }

  return { armar }
}
