# Flujo de trabajo

## De la historia al código

El trabajo sale del backlog, no de la cabeza:

```text
sistema/historias-usuario/historias-usuario.md   Historias, criterios y tareas
                    ↓
tablero/tablero.md                                Estado de cada tarea
                    ↓
web/                                               El código
```

- La **tarea** del tablero (`T-HU-06.2`) es la unidad de trabajo: una
  tarea, una rama, una entrega.
- Los **criterios de aceptación** de la historia son la definición de
  terminado. Una tarea está terminada cuando su parte está hecha **y** la
  historia cumple sus criterios.
- La tarjeta del tablero se mueve de columna cuando la tarea termina.

## Columnas del tablero

| Columna | Significado |
|---|---|
| `Por hacer` | Listo para tomar trabajo |
| `En curso` | Se está trabajando en él (con límite de trabajo en curso) |
| `En pruebas / QA` | Terminado, a la espera de comprobación |
| `Listo para producción` | Comprobado y desplegado |
| `Hecho` | Cerrado |

Los límites de trabajo en curso están escritos en el encabezado de la
columna, para que se lean sin ninguna extensión.

## Antes de escribir código

1. Leer los criterios de aceptación de la historia y el texto de la tarea.
2. Revisar en `bd/esquema.sql` si la regla ya existe como función.
3. Si la regla necesita bloquear una fila, escribir la función en
   PL/pgSQL, no en TypeScript.
4. Si la historia agrega texto, agregar la clave en `es.ts` primero.
5. Si la historia agrega tabla o columna, cambiar `bd/esquema.sql` y
   `web/db/schema.ts` juntos.

## Mientras se trabaja

- La rama se llama `tipo/descripcion-corta`: `feat/barrido-solicitudes`,
  `fix/cupo-disponible`.
- Los commits son pequeños y verificables: `npm run typecheck` pasa.
- Si la regla del negocio cambia, se cambia en la base y se actualiza el
  diccionario; el código solo la llama.

## Antes de integrar

- [ ] `npm run typecheck --workspace web` sin errores.
- [ ] `npm run build --workspace web` compila.
- [ ] Las pruebas del área tocada pasan.
- [ ] Los textos nuevos existen en todos los idiomas.
- [ ] Ningún color escrito a mano; los tokens siguen mandando.
- [ ] Las entradas que cruzan la red están validadas.
- [ ] La documentación de `web/docs/` está al día si cambió una regla.

## Al terminar

- La tarjeta pasa a `En pruebas / QA` y luego a `Listo para producción`.
- El trabajo se registra en `docs/changelog/`, una vez que el usuario lo
  acepta.
- La estimación se recalcula: sale del tablero, no de la cabeza.

## Las tres fuentes de verdad

| Fuente | Qué manda |
|---|---|
| `bd/esquema.sql` | El esquema y las reglas de la base |
| `sistema/historias-usuario/` | El alcance: historias, criterios, tareas |
| `tablero/tablero.md` | El estado: qué está hecho y qué no |

Cuando dos se contradicen, **gana el backlog**: el tablero y el esquema se
actualizan para reflejarlo.
