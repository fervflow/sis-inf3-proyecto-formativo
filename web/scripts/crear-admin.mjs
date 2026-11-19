/**
 * Crea la primera cuenta administradora.
 *
 * El registro público está cerrado y la contraseña inicial es el nombre
 * de usuario, así que la primera cuenta no puede crearse desde la web:
 * este script la deja lista en la base.
 *
 * Uso (desde `web/`):
 *
 *   node scripts/crear-admin.mjs [usuario] [nombres] [apellidos]
 *
 * Por omisión: administrador / Administrador / Vizcacha.
 *
 * Lee las variables de entorno igual que la aplicación: `web/.env`, el
 * `.env` de la raíz y `.env.local` de la raíz, en ese orden.
 */
import { randomUUID } from 'node:crypto'
import { existsSync } from 'node:fs'
import { loadEnvFile } from 'node:process'
import { fileURLToPath } from 'node:url'
import { hashPassword } from 'better-auth/crypto'
import pg from 'pg'

for (const archivo of ['../.env', '../../.env', '../../.env.local']) {
  const ruta = fileURLToPath(new URL(archivo, import.meta.url))
  if (existsSync(ruta)) {
    loadEnvFile(ruta)
  }
}

const usuario = (process.argv[2] ?? 'administrador').trim().toLowerCase()
const nombres = (process.argv[3] ?? 'Administrador').trim()
const apellidos = (process.argv[4] ?? 'Vizcacha').trim()

if (usuario.length < 8) {
  console.error('El usuario debe tener al menos 8 caracteres.')
  process.exit(1)
}

const conexion = process.env.DATABASE_URL_UNPOOLED ?? process.env.DATABASE_URL
if (!conexion) {
  console.error(
    'Falta DATABASE_URL_UNPOOLED. Ejecutá «neon env pull» en la raíz.',
  )
  process.exit(1)
}

const correo = `${usuario}@vizcacha.tours`
const nombre = `${nombres} ${apellidos}`
const clave = await hashPassword(usuario)

const cliente = new pg.Client({ connectionString: conexion })
await cliente.connect()

try {
  await cliente.query('begin')

  const { rows: existentes } = await cliente.query(
    'select id from turismo.usuario where email = $1',
    [correo],
  )

  if (existentes.length > 0) {
    await cliente.query(
      `update turismo.usuario
          set id_rol = (select id_rol from turismo.rol where codigo = 'ADMIN'),
              estado = 'activo',
              updated_at = now()
        where email = $1`,
      [correo],
    )
    console.log(`La cuenta ${usuario} ya existía: quedó como administradora.`)
  } else {
    const id = randomUUID()

    await cliente.query(
      `insert into turismo.usuario
         (id, name, email, nombres, apellidos, id_rol, estado,
          debe_cambiar_password)
       values ($1, $2, $3, $4, $5,
               (select id_rol from turismo.rol where codigo = 'ADMIN'),
               'activo', true)`,
      [id, nombre, correo, nombres, apellidos],
    )

    await cliente.query(
      `insert into turismo.account
         (id, user_id, account_id, provider_id, password)
       values ($1, $2, $3, 'credential', $4)`,
      [randomUUID(), id, id, clave],
    )

    console.log(`Cuenta administradora creada: ${usuario}`)
    console.log(`Contraseña inicial: ${usuario} (se cambia al ingresar).`)
  }

  await cliente.query('commit')
} catch (error) {
  await cliente.query('rollback')
  throw error
} finally {
  await cliente.end()
}
