/**
 * Ficha del cliente.
 *
 * El documento y su tipo forman la clave de negocio: no se repiten. El
 * correo es obligatorio y único (RN-USU-05): es el canal de contacto y la
 * identidad del registro de la cuenta. La validación se comparte entre el
 * alta y la edición.
 */
import { and, eq, sql } from 'drizzle-orm'
import { z } from 'zod'
import * as schema from '../../db/schema'
import type { ClienteResumen } from '#shared/types/api'
import type {
  EstadoCliente,
  EstadoUsuario,
  TipoDocumento,
} from '#shared/types/domain'

const hoy = () => new Date().toISOString().slice(0, 10)

/** Cuerpo del alta y de la edición de un cliente. */
export const esquemaCliente = z.object({
  tipoDocumento: z.enum(['CI', 'NIT', 'PASAPORTE', 'OTRO']),
  numeroDocumento: z.string().trim().min(3).max(30),
  nombres: z.string().trim().min(2).max(100),
  apellidos: z.string().trim().min(2).max(100),
  correo: z.string().trim().email('correo_invalido').max(150),
  telefono: z.string().trim().max(30).optional(),
  direccion: z.string().trim().max(200).optional(),
  fechaNacimiento: z
    .string()
    .trim()
    .regex(/^\d{4}-\d{2}-\d{2}$/)
    .optional()
    .or(z.literal(''))
    .refine((valor) => !valor || valor <= hoy(), {
      message: 'fecha_futura',
    }),
  estado: z.enum(['activo', 'inactivo']),
})

/** El documento se guarda en mayúsculas, sin espacios. */
export function normalizarDocumento(valor: string): string {
  return valor.trim().toUpperCase()
}

/** Fila de la consulta de clientes, con su cuenta resuelta. */
export interface FilaCliente {
  idCliente: number
  tipoDocumento: string
  numeroDocumento: string
  nombres: string
  apellidos: string
  correo: string
  telefono: string | null
  direccion: string | null
  fechaNacimiento: string | null
  estado: string
  fechaRegistro: Date
  /** Correo de la cuenta vinculada, cuando la ficha la tiene. */
  usuarioCuenta: string | null
  /** Estado de la cuenta vinculada: activo, inactivo o bloqueado. */
  estadoCuenta: string | null
}

/** Lo que devuelve la tabla `cliente` sola, sin la cuenta. */
export type FilaClienteBase = Omit<FilaCliente, 'usuarioCuenta' | 'estadoCuenta'>

/** Convierte la fila de la base en lo que consume la interfaz. */
export function aClienteResumen(
  fila: FilaClienteBase & Partial<Pick<FilaCliente, 'usuarioCuenta' | 'estadoCuenta'>>,
): ClienteResumen {
  const usuarioCuenta = fila.usuarioCuenta ?? null
  return {
    idCliente: fila.idCliente,
    tipoDocumento: fila.tipoDocumento as TipoDocumento,
    numeroDocumento: fila.numeroDocumento,
    nombres: fila.nombres,
    apellidos: fila.apellidos,
    correo: fila.correo,
    telefono: fila.telefono,
    direccion: fila.direccion,
    fechaNacimiento: fila.fechaNacimiento,
    estado: fila.estado as EstadoCliente,
    fechaRegistro: fila.fechaRegistro.toISOString(),
    cuenta: usuarioCuenta
      ? {
          usuario: usuarioCuenta,
          estado: (fila.estadoCuenta ?? 'activo') as EstadoUsuario,
        }
      : null,
  }
}

/** Busca la ficha por su documento; devuelve su identificador o `null`. */
export async function buscarFichaPorDocumento(
  tipoDocumento: string,
  numeroDocumento: string,
): Promise<number | null> {
  const [fila] = await useDb()
    .select({ idCliente: schema.cliente.idCliente })
    .from(schema.cliente)
    .where(
      and(
        eq(schema.cliente.tipoDocumento, tipoDocumento),
        sql`upper(${schema.cliente.numeroDocumento}) = ${numeroDocumento.toUpperCase()}`,
      ),
    )
    .limit(1)

  return fila?.idCliente ?? null
}

/**
 * Clasifica la violación de unicidad de una ficha.
 *
 * Devuelve el código de la interfaz, o `null` si el error no es de
 * duplicado. El correo y el documento tienen mensajes distintos.
 */
export function codigoDuplicadoCliente(
  error: unknown,
): 'cliente_duplicado' | 'correo_duplicado' | null {
  const envuelto = error as {
    code?: string
    constraint?: string
    cause?: { code?: string; constraint?: string }
  }
  const codigo = envuelto.code ?? envuelto.cause?.code
  if (codigo !== '23505') {
    return null
  }

  const restriccion =
    envuelto.cause?.constraint ?? envuelto.constraint ?? ''
  return restriccion.includes('correo')
    ? 'correo_duplicado'
    : 'cliente_duplicado'
}
