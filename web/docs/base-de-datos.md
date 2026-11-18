# Base de datos

## La fuente canónica es el SQL

`bd/esquema.sql` es el script de creación del esquema y la descripción
exacta de las reglas. `web/db/schema.ts` lo refleja para que TypeScript
conozca los tipos. **Si cambia uno, cambian los dos.**

| Necesito… | Miro… |
|---|---|
| Las tablas, columnas y restricciones | `bd/esquema.sql` |
| Las reglas de negocio explicadas | `bd/diccionario-datos.md` |
| Los tipos en TypeScript | `web/db/schema.ts` |

## La conexión

`server/utils/db.ts` abre el *pool* de conexiones:

```ts
pool = new Pool({
  connectionString: url,
  max: 5,
  idleTimeoutMillis: 10_000,
})
```

- En producción se usa la cadena **pooled** de Neon: multiplexa las
  conexiones y evita agotarlas en un entorno sin estado.
- Las **migraciones** usan la cadena **directa** (`DATABASE_URL_UNPOOLED`):
  el pooler no admite operaciones de sesión.

### El esquema va calificado

El pooler de Neon **no acepta el parámetro `search_path` en el arranque de
la conexión**, de modo que no se puede confiar en el `search_path` de la
sesión. Por eso:

- Las tablas se declaran dentro del esquema con `pgSchema('turismo')` en
  `db/schema.ts`, y el SQL crudo usa `turismo.` delante.
- Cada función PL/pgSQL **fija su propio `search_path`**:

  ```sql
  CREATE OR REPLACE FUNCTION fn_crear_reserva(...)
  RETURNS BIGINT
  SET search_path = turismo, public
  AS $$
  ```

  Así la función se comporta igual se llame desde la aplicación, desde
  `psql` o desde otra herramienta.

Las vistas no necesitan nada de esto: al crearlas, PostgreSQL guarda la
dependencia con el identificador de la tabla, no con el nombre.

## Las variables de entorno

| Variable | Para qué |
|---|---|
| `DATABASE_URL` | La aplicación: cadena *pooled* |
| `DATABASE_URL_UNPOOLED` | Migraciones y tareas de administración |
| `BETTER_AUTH_SECRET` | Secreto de la sesión |
| `BETTER_AUTH_URL` | Origen permitido de la aplicación |
| `CRON_SECRET` | Protege el barrido diario |

Las deja la CLI de Neon en `.env.local`, en la raíz del repositorio:
`neon env pull` (o `make neon-env`). La aplicación las carga sola; ver
`nuxt.config.ts`.

Los valores se leen **en tiempo de ejecución**, no al compilar, para que las
credenciales no queden escritas dentro del paquete desplegado.

## Las reglas críticas están en la base

Las reglas que necesitan bloquear una fila son funciones PL/pgSQL:

| Función | Qué aplica |
|---|---|
| `fn_crear_reserva(...)` | Bloquea la salida, valida el cupo, rechaza la segunda solicitud activa |
| `fn_confirmar_reserva(...)` | Confirma dentro del plazo, limpia el vencimiento, audita |
| `fn_actualizar_salida(...)` | Bloquea la salida, no deja bajar la capacidad, audita |
| `fn_solicitar_cancelacion(...)` | Registra la petición del cliente sin cambiar el estado |
| `fn_ejecutar_cancelacion(...)` | Cancela con motivo y fecha |
| `fn_registrar_pago(...)` | Registra el pago en estado `registrado` |
| `fn_validar_pago(...)` | Valida o anula el pago |
| `fn_vencer_solicitudes_pendientes()` | Barrido diario de limpieza |

La aplicación las llama con una sentencia. **No se reimplementan en
TypeScript**: la atomicidad la garantiza la base, no el transporte.

```ts
const [resultado] = await consultar<{ id_reserva: number }>(
  sql`select fn_crear_reserva(${idCliente}, ${idSalida}, ${cantidad}, ${origen}, ${idUsuario}) as id_reserva`,
)
```

## Consultar

Las vistas son la forma de leer los datos calculados:

```sql
-- Cupo disponible de cada salida.
SELECT * FROM vista_disponibilidad_salida WHERE fecha_salida >= CURRENT_DATE;

-- Saldo pendiente de una reserva, sobre los pagos validados.
SELECT * FROM vista_saldo_reserva WHERE id_reserva = $1;

-- Ocupación por fecha, para los reportes.
SELECT * FROM vista_reservas_por_fecha WHERE fecha_salida BETWEEN $1 AND $2;
```

En la aplicación:

```ts
import { consultar } from '../utils/db'

const salidas = await consultar<SalidaDisponible>(sql`
  SELECT id_salida, codigo_paquete, paquete, cupo_disponible
  FROM vista_disponibilidad_salida
  WHERE fecha_salida >= CURRENT_DATE
`)
```

## El estado derivado

Una solicitud pendiente cuyo plazo venció **ya no ocupa cupo**, aunque su
estado guardado siga siendo `pendiente`: así lo calculan las vistas. El
barrido diario solo limpia el estado y deja la auditoría.

Por eso la aplicación no depende de que un proceso se haya ejecutado a
tiempo para respetar el plazo de 48 horas.

## Reglas de escritura

1. **Nunca se escribe una reserva, un pago o un cambio de estado desde la
   aplicación sin pasar por su función.** Las funciones auditan y bloquean.
2. **No se copia el cupo a una columna.** Se calcula siempre desde las
   reservas vigentes.
3. **Toda lectura que ordena o filtra en memoria, primero se filtra en
   SQL.**
4. **Una consulta por vista, no una por fila.** Si hace falta un dato
   related, se pide en la misma consulta con una unión.
5. **El `search_path` lo fija el pool**: las consultas no llevan el esquema
   delante.

## Agregar algo al esquema

1. Escribir el `CREATE` en `bd/esquema.sql`, en su sección.
2. Si es una regla con bloqueo de fila, escribir la función y añadirla a
   las reglas del diccionario.
3. Reflejarlo en `web/db/schema.ts`, con los mismos nombres de columna.
4. Crear la base de prueba y ejecutar el script completo: el esquema tiene
   que crear sin errores.
5. Si cambió una restricción `CHECK`, actualizar el tipo en
   `shared/types/domain.ts`.
6. Probar la regla con datos: el caso del error y el caso del éxito.

## Crear la base

```bash
# Con la de Neon (la rama es la que diga `.neon`):
make neon-env     # trae las variables a .env.local
make db-crear     # aplica el script con la conexión directa

# Con una base local (Docker o Podman):
podman run -d --name vizcacha -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres:18
psql -h 127.0.0.1 -U postgres -f bd/esquema.sql
```

El script es idempotente en las inserciones de roles y se puede volver a
ejecutar sobre una base limpia.
