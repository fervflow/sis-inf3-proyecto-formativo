# Pruebas

## Qué se prueba

| Nivel | Qué cubre | Herramienta |
|---|---|---|
| Unidad | Una función o composable, sin base | Vitest |
| Integración | Una ruta contra una base real | Vitest + PostgreSQL |
| Extremo a extremo | Un flujo de la interfaz | Playwright |

La prioridad es la **integración**: casi toda la lógica está en la base, y
probar contra una base real es lo que verifica cupos, vencimientos y pagos.

## Base para las pruebas

```bash
podman run -d --name vizcacha-test -p 55432:5432 \
  -e POSTGRES_PASSWORD=postgres postgres:18

export DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:55432/postgres
psql "$DATABASE_URL" -f bd/esquema.sql
```

Cada prueba corre contra una base propia. Las que escriben usan una
transacción que se revierte o borran lo que crearon.

## Reglas del negocio

| Regla | Casos |
|---|---|
| Paquete publicado | Activar con destino, descripción, itinerario y servicios; rechazar si falta uno |
| Paquete borrador | Guardar incompleto; no se ofrece al cliente |
| Precio y código | Precio cero; código duplicado; código en minúsculas |
| Actividades | Marcar y desmarcar; no repetir la misma actividad |
| Salida | Paquete inactivo; fecha pasada; retorno anterior; duración incoherente; duplicado por fecha |
| Estado de salida | Transiciones válidas; cancelar sin motivo; editar una salida realizada |
| Cupo | Cabe, no cabe y dos reservas simultáneas |
| Solicitud activa | Una por cliente y salida; la segunda se rechaza |
| Confirmación | Dentro del plazo, fuera y sobre una ya confirmada |
| Vencimiento | La vencida no ocupa cupo; el barrido la marca |
| Capacidad | No baja de lo reservado; el cambio se audita |
| Cancelación | La solicitud no cambia el estado; la ejecución sí |
| Pago | El registrado no cuenta hasta que se valida |

Ejemplo:

```ts
import { describe, expect, it } from 'vitest'

describe('fn_crear_reserva', () => {
  it('rechaza una reserva que excede el cupo', async () => {
    await crearSalida({ cupoMaximo: 10 })
    await crearReserva({ cantidad: 8 })

    await expect(
      crearReserva({ cantidad: 5 }),
    ).rejects.toThrow(/cupo suficiente/)
  })
})
```

## Pruebas de interfaz

- Un componente base se prueba por su contrato: props, eventos y slots.
- Una vista se prueba por lo que muestra: texto, carga, vacío y error.
- Los textos se comprueban contra las claves de `es.ts`, no contra cadenas
  escritas a mano.

## Pruebas SQL de reglas

Las reglas de paquetes y salidas tienen una prueba de integración que corre
contra una base creada con `bd/esquema.sql`:

```bash
make db-probar
```

La prueba abre una transacción, comprueba los casos de éxito y de error y
termina con `ROLLBACK`: no deja datos.

## Qué se ejecuta

```bash
npm run typecheck --workspace web     # tipos
npm run build --workspace web         # compila
make db-probar                          # reglas SQL
```

La suite de Vitest todavía no está configurada; las pruebas de interfaz y de
API se incorporarán en una tarea aparte. La validación de esta iteración se
hizo con la prueba SQL anterior y con comprobaciones manuales.

## Antes de integrar

- [ ] Las reglas nuevas tienen casos de éxito y de error.
- [ ] La prueba falla si la regla falla.
- [ ] No hay datos reales: todo es ficticio.
