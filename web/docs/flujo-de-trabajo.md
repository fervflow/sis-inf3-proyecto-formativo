# Flujo de trabajo

## De la historia al código

El trabajo sale del backlog:

```text
sistema/historias-usuario/historias-usuario.md   Historias, criterios y tareas
                    ↓
tablero/tablero.md                                Estado de cada tarea
                    ↓
web/                                               El código
```

- La **tarea** (`T-HU-06.2`) es la unidad de trabajo: una tarea, una rama,
  una entrega.
- Los **criterios de aceptación** de la historia son la definición de
  terminado.
- La tarjeta se mueve de columna cuando la tarea termina.

## Columnas del tablero

| Columna | Significado |
|---|---|
| `Por hacer` | Listo para tomar trabajo |
| `En curso` | Se está trabajando (con límite de WIP) |
| `En pruebas / QA` | Terminada, a la espera de comprobación |
| `Listo para producción` | Comprobada y validada, pendiente de publicación |
| `Hecho` | Publicada y con los criterios cumplidos |

Los límites de WIP están en el encabezado de cada columna.

## Antes de escribir código

1. Leer los criterios de aceptación y el texto de la tarea.
2. Revisar en `bd/esquema.sql` si la regla ya existe como función.
3. Si necesita bloquear una fila, escribirla en PL/pgSQL, no en TypeScript.
4. Si agrega texto, crear la clave en `es.ts` primero.
5. Si agrega tabla o columna, cambiar `bd/esquema.sql` y `web/db/schema.ts`
   juntos.

## Mientras se trabaja

- La rama se llama `tipo/descripcion-corta`: `feat/barrido-solicitudes`.
- Los commits son pequeños y verificables.
- Si cambia una regla de negocio, se cambia en la base y se actualiza el
  diccionario; el código solo la llama.

## Antes de integrar

- [ ] `npm run typecheck --workspace web` sin errores.
- [ ] `npm run build --workspace web` compila.
- [ ] Las pruebas del área tocada pasan.
- [ ] Los textos nuevos existen en todos los idiomas.
- [ ] Ningún color escrito a mano.
- [ ] Las entradas que cruzan la red están validadas.
- [ ] `web/docs/` está al día si cambió una regla.

## Al terminar

- La tarjeta pasa a `En pruebas / QA` y luego a `Listo para producción`.
- El trabajo se registra en `docs/changelog/` cuando el usuario lo acepta.
- La estimación se recalcula: sale del tablero.

## Las tres fuentes de verdad

| Fuente | Qué manda |
|---|---|
| `bd/esquema.sql` | El esquema y las reglas de la base |
| `sistema/historias-usuario/` | El alcance |
| `tablero/tablero.md` | El estado |

Cuando dos se contradicen, **gana el backlog**: el tablero y el esquema se
actualizan para reflejarlo.
