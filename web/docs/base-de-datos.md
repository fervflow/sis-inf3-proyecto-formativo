# Base de datos

## La fuente canónica

`bd/esquema.sql` crea el esquema y describe las reglas. `web/db/schema.ts`
lo refleja para que TypeScript conozca los tipos. **Si cambia uno, cambian
los dos.**

| Necesito… | Miro… |
|---|---|
| Qué debe cumplirse y por qué | `sistema/reglas-negocio.md` |
| Tablas, columnas y restricciones | `bd/esquema.sql` |
| Cómo aplica el esquema cada regla | `bd/diccionario-datos.md` |
| Tipos en TypeScript | `web/db/schema.ts` |

## La conexión

`server/utils/db.ts` abre el *pool*:

```ts
pool = new Pool({
  connectionString: url,
  max: 5,
  idleTimeoutMillis: 10_000,
})
```

- En producción se usa la cadena **pooled** de Neon.
- Las **migraciones** usan la cadena directa (`DATABASE_URL_UNPOOLED`): el
  pooler no admite operaciones de sesión.

### El esquema va calificado

El pooler de Neon **no acepta `search_path` al arrancar la conexión**. Por
eso:

- Las tablas se declaran con `pgSchema('turismo')` en `db/schema.ts`, y el
  SQL crudo usa `turismo.` delante.
- Cada función PL/pgSQL fija su propio `search_path`:

  ```sql
  CREATE OR REPLACE FUNCTION fn_crear_reserva(...)
  RETURNS BIGINT
  SET search_path = turismo, public
  AS $$
  ```

  Así se comporta igual desde la aplicación, `psql` u otra herramienta.

Las vistas no lo necesitan: PostgreSQL guarda la dependencia con el
identificador de la tabla.

## Variables de entorno

| Variable | Para qué |
|---|---|
| `DATABASE_URL` | La aplicación: cadena pooled |
| `DATABASE_URL_UNPOOLED` | Migraciones y administración |
| `BETTER_AUTH_SECRET` | Secreto de sesión |
| `BETTER_AUTH_URL` | Origen permitido |
| `CRON_SECRET` | Protege el barrido diario |

Las deja la CLI de Neon en `.env.local`, en la raíz: `neon env pull` o
`make neon-env`. La aplicación las carga sola y las lee en tiempo de
ejecución, para que no queden dentro del paquete.

## Las reglas críticas están en la base

Las reglas que necesitan bloquear una fila son funciones PL/pgSQL:

| Función | Qué aplica |
|---|---|
| `fn_crear_reserva(...)` | Bloquea la salida, valida cupo y rechaza la segunda solicitud activa |
| `fn_confirmar_reserva(...)` | Confirma dentro del plazo, limpia el vencimiento y audita |
| `fn_crear_salida(...)` | Exige paquete activo, duración coherente y una sola salida por fecha |
| `fn_actualizar_salida(...)` | Bloquea la salida, no baja la capacidad, valida el estado y audita |
| `fn_solicitar_cancelacion(...)` | Registra la petición sin cambiar el estado |
| `fn_ejecutar_cancelacion(...)` | Cancela con motivo y fecha |
| `fn_registrar_pago(...)` | Registra el pago como `registrado` |
| `fn_validar_pago(...)` | Valida o anula el pago |
| `fn_vencer_solicitudes_pendientes()` | Barrido diario |

La aplicación las llama con una sentencia; **no se reimplementan en
TypeScript**.

```ts
const [resultado] = await consultar<{ id_reserva: number }>(
  sql`select fn_crear_reserva(${idCliente}, ${idSalida}, ${cantidad}, ${origen}, ${idUsuario}) as id_reserva`,
)
```

## Consultar

Las vistas son la forma de leer datos calculados:

```sql
SELECT * FROM turismo.vista_disponibilidad_salida WHERE fecha_salida >= CURRENT_DATE;
SELECT * FROM turismo.vista_saldo_reserva WHERE id_reserva = $1;
SELECT * FROM turismo.vista_reservas_por_fecha WHERE fecha_salida BETWEEN $1 AND $2;
```

```ts
import { consultar } from '../utils/db'

const salidas = await consultar<SalidaDisponible>(sql`
  SELECT id_salida, codigo_paquete, paquete, cupo_disponible
  FROM turismo.vista_disponibilidad_salida
  WHERE fecha_salida >= CURRENT_DATE
`)
```

## El estado derivado

Una solicitud vencida **ya no ocupa cupo**, aunque su estado guardado siga
siendo `pendiente`: así lo calculan las vistas. El barrido diario solo
limpia el estado y deja la auditoría. La aplicación no depende de que el
proceso se haya ejecutado a tiempo.

## Reglas de escritura

1. **Nunca se escribe una reserva, un pago o un cambio de estado sin pasar
   por su función.** Las funciones auditan y bloquean.
2. **No se copia el cupo a una columna:** se calcula desde las reservas
   vigentes.
3. **Se filtra en SQL**, no en memoria.
4. **Una consulta por vista**, no una por fila.
5. **El esquema va calificado** en el SQL crudo; no se depende del
   `search_path`.

## Agregar algo al esquema

1. Escribir el `CREATE` en `bd/esquema.sql`, en su sección.
2. Si es una regla con bloqueo, escribir la función y documentarla en el
   diccionario.
3. Reflejarlo en `web/db/schema.ts` con los mismos nombres.
4. Crear una base de prueba y ejecutar el script completo.
5. Si cambió un `CHECK`, actualizar el tipo en `shared/types/domain.ts`.
6. Probar el caso de error y el de éxito.

## Crear la base

```bash
# Neon (la rama es la que diga `.neon`):
make neon-env
make db-crear

# Base local:
podman run -d --name vizcacha -p 5432:5432 \
  -e POSTGRES_PASSWORD=postgres postgres:18
psql -h 127.0.0.1 -U postgres -f bd/esquema.sql
```

El script es idempotente en las inserciones de roles y se puede volver a
ejecutar sobre una base limpia.

## Actualizar una base existente

`bd/esquema.sql` crea una base nueva. Para una base que ya existe se aplican
los scripts de `bd/actualizaciones/` en orden:

```bash
make db-actualizar
```

Ese script agrega destino y actividades, cambia el rol `TURISTA` a
`CLIENTE`, crea las funciones de salidas y aplica las restricciones nuevas.
Es idempotente. Los paquetes activos que no tengan destino, descripción,
itinerario o servicios incluidos pasan a `borrador` para que se completen
antes de volver a publicarse.

Los objetivos `db-crear`, `db-actualizar` y `db-probar` cargan `.env.local`
cuando no encuentran las variables exportadas en el entorno.
