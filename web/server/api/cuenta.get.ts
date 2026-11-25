import { eq } from 'drizzle-orm'
import * as schema from '../../db/schema'
import { usuarioDeCorreo } from '#shared/usuarios'
import type {
  FichaCliente,
  RespuestaCuenta,
} from '#shared/types/api'
import type { EstadoUsuario, Rol } from '#shared/types/domain'
import { sesionActual } from '../utils/autorizacion'

/**
 * Cuenta de la sesión en curso.
 *
 * La interfaz la usa para el encabezado y para decidir si muestra el
 * panel de administración. Devuelve `null` cuando no hay sesión: una
 * visita pública no es un error. Para las cuentas de cliente añade la
 * ficha propia, de modo que el manifiesto pueda agregarse como
 * pasajero (HU-12).
 */
export default defineEventHandler(async (event): Promise<RespuestaCuenta> => {
  const sesion = sesionActual(event)

  if (!sesion?.user) {
    return { usuario: null }
  }

  const [fila] = await useDb()
    .select({ codigo: schema.rol.codigo })
    .from(schema.rol)
    .where(eq(schema.rol.idRol, sesion.user.idRol ?? 0))
    .limit(1)

  const rol = (fila?.codigo ?? 'CLIENTE') as Rol

  // La ficha solo interesa en el canal web: es la del cliente en sesión.
  let ficha: FichaCliente | null = null
  if (rol === 'CLIENTE') {
    const [registro] = await useDb()
      .select({
        tipoDocumento: schema.cliente.tipoDocumento,
        numeroDocumento: schema.cliente.numeroDocumento,
        nombres: schema.cliente.nombres,
        apellidos: schema.cliente.apellidos,
        fechaNacimiento: schema.cliente.fechaNacimiento,
      })
      .from(schema.cliente)
      .where(eq(schema.cliente.idUsuario, sesion.user.id))
      .limit(1)

    if (registro) {
      ficha = {
        ...registro,
        // Drizzle entrega la fecha `date` como cadena 'YYYY-MM-DD'.
        fechaNacimiento: registro.fechaNacimiento ?? null,
        tipoDocumento: registro.tipoDocumento as FichaCliente['tipoDocumento'],
      }
    }
  }

  return {
    usuario: {
      id: sesion.user.id,
      usuario: usuarioDeCorreo(sesion.user.email),
      nombres: sesion.user.nombres,
      apellidos: sesion.user.apellidos,
      rol,
      estado: sesion.user.estado as EstadoUsuario,
      debeCambiarPassword: sesion.user.debeCambiarPassword,
      ficha,
    },
  }
})
