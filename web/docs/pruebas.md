# Pruebas

## Qué se prueba

| Nivel | Qué cubre | Herramienta |
|---|---|---|
| Unidad | Una función o un composable, sin base de datos | Vitest |
| Integración | Una ruta de la API contra una base de verdad | Vitest + PostgreSQL |
| Extremo a extremo | Un flujo de la interfaz, como lo recorre una persona | Playwright |

La prioridad es la **integración**: casi toda la lógica del sistema está
en la base de datos, y probarla contra una base real es lo que verifica de
verdad las reglas de cupos, vencimientos y pagos.

## Base de datos para las pruebas

Las pruebas de integración necesitan un PostgreSQL con el esquema creado.
La forma más simple es un contenedor:

```bash
podman run -d --name vizcacha-test -p 55432:5432 \
  -e POSTGRES_PASSWORD=postgres postgres:18

export DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:55432/postgres
psql "$DATABASE_URL" -f bd/esquema.sql
```

Cada prueba corre contra una base propia. Las pruebas que escriben datos
usan una transacción que se revierte al terminar, o borran lo que crearon.

## Pruebas de las reglas del negocio

Cada función de la base necesita, por lo menos, estos casos:

| Regla | Casos |
|---|---|
| Cupo | Cabe, no cabe, y dos reservas simultáneas sobre el mismo cupo |
| Solicitud activa | Una por cliente y salida; la segunda se rechaza |
| Confirmación | Dentro del plazo, fuera del plazo, sobre una reserva ya confirmada |
| Vencimiento | La solicitud vencida no ocupa cupo; el barrido la pasa a `vencida` |
| Capacidad | No baja por debajo de lo reservado; el cambio queda auditado |
| Cancelación | La solicitud no cambia el estado; la ejecución sí, con motivo y fecha |
| Pago | El pago registrado no cuenta como abonado hasta que el personal lo valida |

Ejemplo de prueba de integración:

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

## Pruebas de la interfaz

- Un componente base se prueba por su contrato: props, eventos y slots.
- Una vista se prueba por lo que muestra: texto, estados de carga, vacío y
  error.
- Los textos se comprueban contra las claves de `es.ts`, no contra
  cadenas escritas a mano.

## Qué se ejecuta

```bash
npm run typecheck --workspace web     # tipos
npm run build --workspace web         # compila
npm run test --workspace web          # pruebas
```

La suite completa se ejecuta antes de dar por terminado un trabajo que
tocó la base de datos o la autenticación.

## Antes de integrar

- [ ] Las reglas nuevas tienen sus casos de éxito y de error.
- [ ] La prueba falla si la regla falla: no se prueba el resultado, se
      prueba el comportamiento.
- [ ] No hay datos reales en las pruebas: todo es ficticio.
