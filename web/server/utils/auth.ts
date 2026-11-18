import { betterAuth } from 'better-auth'
import { drizzleAdapter } from 'better-auth/adapters/drizzle'
import { useDb } from './db'
import * as schema from '../../db/schema'

/**
 * Autenticación con Better Auth.
 *
 * Better Auth es una biblioteca, no un servicio: las tablas de sesión,
 * cuentas y verificaciones viven en la misma base de datos que los datos
 * del negocio. La tabla `user` de la biblioteca se llama `usuario` aquí
 * (`user` es palabra reservada en SQL) y los campos del dominio se
 * declaran como campos adicionales.
 */
function crearAuth() {
  const config = configServidor()

  return betterAuth({
    baseURL: config.betterAuthUrl,
    secret: config.betterAuthSecret,

    database: drizzleAdapter(useDb(), { provider: 'pg', schema }),

    emailAndPassword: { enabled: true },

    user: {
      modelName: 'usuario',
      // Campos del dominio. `input: false` porque la aplicación los
      // controla, no el formulario de registro.
      additionalFields: {
        idRol: { type: 'number', required: false, input: false },
        nombres: { type: 'string', required: true },
        apellidos: { type: 'string', required: true },
        telefono: { type: 'string', required: false },
        estado: { type: 'string', required: false, defaultValue: 'activo', input: false },
      },
    },

    hooks: {
      // Trazabilidad de los ingresos: el criterio de HU-08 pide registrar
      // cada acceso con usuario, fecha y hora.
      after: async (ctx) => {
        const contexto = ctx as unknown as {
          path?: string
          context?: { newSession?: { session?: { userId?: string } } }
          request?: { headers?: { get?: (nombre: string) => string | null } }
        }

        // El gancho corre en cada ruta de la biblioteca: solo interesan
        // el alta de la cuenta y el inicio de sesión.
        const esAcceso =
          contexto.path?.startsWith('/sign-in') ||
          contexto.path?.startsWith('/sign-up')

        if (!esAcceso) {
          return {}
        }

        try {
          const db = useDb()
          const sesion = contexto.context?.newSession?.session
          await db.insert(schema.acceso).values({
            idUsuario: sesion?.userId ?? null,
            tipo: 'ingreso',
            resultado: sesion ? 'permitido' : 'denegado',
            direccionIp: contexto.request?.headers?.get?.('x-forwarded-for') ?? null,
          })
        } catch (error) {
          console.error('No se pudo registrar el acceso:', error)
        }

        // El gancho debe devolver un objeto: la biblioteca lee de él las
        // cabeceras de la respuesta.
        return {}
      },
    },
  })
}

let instancia: ReturnType<typeof crearAuth> | undefined

export function useAuth() {
  if (!instancia) {
    instancia = crearAuth()
  }
  return instancia
}
