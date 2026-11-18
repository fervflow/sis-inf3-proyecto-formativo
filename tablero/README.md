# Tablero kanban de las tareas

Vista de ejecución de las 39 tareas del backlog, en cinco columnas:

| Columna | Significado | Límite de WIP |
|---|---|---|
| `Por hacer` | Cola de entrada: todavía no se empezó | — |
| `En curso` | Se está trabajando en ella | **4** |
| `En pruebas / QA` | Terminada, a la espera de comprobación | **2** |
| `Listo para producción` | Comprobada y validada, pendiente de publicación | **1** |
| `Hecho` | Publicada y cumple los criterios de su historia | — |

El tablero **no es la fuente del contenido**: las tareas, su texto y su
responsable salen de `sistema/historias-usuario/historias-usuario.md`, y la
prioridad, el riesgo y la estimación, de `historias-usuario.csv`. El tablero
solo guarda el **estado**: la columna en la que está cada tarjeta.

## Límites de trabajo en curso

Un **límite de WIP** es el número máximo de tarjetas que pueden estar
simultáneamente en una columna. Se cuenta en **tarjetas, no en puntos**: el
límite restringe la concurrencia, no el tamaño de cada tarjeta.

Los límites se escriben en el encabezado de la columna, para que se lean sin
ninguna extensión:

```markdown
## En curso (WIP 4)
```

`make tablero-verificar` **falla si una columna supera su límite**, y
`make tablero` se niega a escribir el tablero mientras eso ocurra. El límite
es política, no decoración: obliga a terminar antes de tomar trabajo nuevo.

### Por qué estos valores

Los límites se apoyan en la ley de Little, `WIP = Throughput × Cycle Time`:
si no se limita el trabajo en curso, el tiempo de ciclo crece sin techo. Con
el ritmo observado en la primera ventana (1,75 tareas por día de equipo), un
límite de 4 implica un tiempo de ciclo de 2,3 días por tarjeta.

| Columna | Límite | Razón |
|---|---|---|
| `Por hacer` | — | Es la cola de entrada. Limitarla solo produciría un cuello de botella invisible. |
| `En curso` | 4 | Dos por desarrollador: uno en código y otro bloqueado. Es el límite que más manda, porque fija el throughput máximo. |
| `En pruebas / QA` | 2 | La cola de revisión no debe crecer. Si se llena, el equipo deja de tomar trabajo y el problema aparece en el tablero, no en la fecha de entrega. |
| `Listo para producción` | 1 | Un solo candidato a publicación a la vez. Evita la «release gorda» con cambios mezclados. |
| `Hecho` | — | Es el histórico. |

Una regla de dedo para otros equipos: **el límite de la columna de trabajo es
el tamaño del equipo multiplicado por uno más el paralelismo queAdmite cada
persona**. Con 2 personas y 2 tareas por persona, sale 4.

### Alternativas válidas

| Variante | Cuándo tiene sentido |
|---|---|
| `En curso = 2` | Muy estricta: expone los bloqueos antes, pero parte el throughput a la mitad si el trabajo se fragmenta. |
| `En curso = 3` | Punto medio: 1,5 por desarrollador. |
| `En pruebas / QA = 1` | Solo si el QA lo hace una sola persona. |

## Regla de cierre de historia

El tablero mueve **tareas**, pero el alcance se cuenta en **puntos de
historia**. La regla que une las dos cosas es:

> - Una historia está **Por hacer** si ninguna de sus tareas está en
>   `En curso`, `En pruebas / QA` ni `Hecho`.
> - Está **En curso** si tiene al menos una tarea en `En curso` o
>   `En pruebas / QA` y le queda alguna en `Por hacer`.
> - Está **Hecho** cuando **todas** sus tareas están en `Hecho`.
>
> **Una historia suma sus puntos a la ventana en que su última tarea pasa a
> `Hecho`, y cuenta una sola vez.**

Con esa regla conviven dos métricas que no se contradicen: las **tareas**
miden el flujo (throughput, tiempo de ciclo) y los **puntos** miden el
alcance (qué historias quedaron listas).

Los estados de una historia no se escriben en el tablero: se deducen de sus
tareas. El tablero solo guarda el estado de cada **tarea**.

## Archivos

| Archivo | Rol |
|---|---|
| `tablero.md` | El tablero. Solo se edita para mover tarjetas de columna |
| `generar.py` | Regenera el tablero desde el backlog y conserva las columnas |
| `README.md` | Este documento |

## Comandos

```bash
make tablero            # regenera el tablero
make tablero-verificar  # comprueba que esté al día, sin escribir
```

Equivalentes directos, sin `make`:

```bash
python3 tablero/generar.py
python3 tablero/generar.py --check
```

`generar.py` comprueba antes de escribir que el documento y el CSV
coincidan: las mismas historias, el mismo número de tareas por historia y el
total del CSV. Si algo no cuadra, muestra el detalle y no toca el tablero.

## Cómo mover una tarjeta

Cortar la línea de la tarjeta y pegarla bajo el encabezado de la otra
columna. La línea completa es la tarjeta:

```markdown
- [ ] **T-HU-06.1** Crear una reserva desde la atención del personal o como solicitud del cliente, con su origen, el cliente, la salida y la cantidad de pasajeros. · HU-06 · A · Alta/Alto
```

La columna es el estado. La casilla `[ ]` **no** se usa como estado: la
escriben los visores para reconocer la tarjeta y el generador siempre la deja
vacía. No la marques para indicar que terminaste: mové la tarjeta a `Hecho`.

## Requisitos para verlo

El archivo es Markdown: **no hace falta ninguna extensión para leerlo ni
para editarlo**. Cualquier editor de texto lo abre, y GitHub o GitLab lo
muestran como cinco listas. Las extensiones solo agregan la vista de
tablero, con columnas y arrastrar y soltar.

### Obsidian (gratis para uso personal)

1. Descargar Obsidian desde <https://obsidian.md/download> e instalarlo
   (Windows, macOS o Linux). No hace falta cuenta para trabajar con archivos
   locales.
2. Abrir la carpeta del repositorio como bóveda, o solo `sistema/`.
3. Ajustes → **Complementos de la comunidad** → desactivar el modo
   restringido.
4. **Examinar** → buscar **Boardwalk** → **Instalar** → **Activar**.
   Boardwalk lee y escribe el mismo formato que el complemento Kanban
   original y sigue mantenido. El original (buscar **Kanban**) también
   funciona, pero está sin mantenimiento desde 2024 y puede que ya no
   aparezca en el buscador.
5. Abrir `tablero.md`: el encabezado `kanban-plugin: basic` hace que se abra
   como tablero.

Boardwalk es solo para escritorio por ahora; el Kanban original también
funciona en móvil. Al regenerar el tablero se conservan los ajustes visuales
de ambos complementos y el historial de movimientos de Boardwalk.

### VS Code (gratis)

1. Instalar la extensión **Unified Kanban**
   (`divisionseven.unified-kanban`) desde el Marketplace o desde Open VSX.
   Requiere VS Code 1.85 o superior.
2. Abrir `tablero.md` con clic derecho → **Open With…** → **Kanban Board**,
   o usar el comando **Kanban: View as Board**.

Unified Kanban usa el mismo formato que Obsidian, así que el tablero se ve
igual en los dos. Otras extensiones de Kanban para VS Code (Kanban.md,
Kanban Markdown) usan formatos propios y no leen este archivo.

### Sin extensión

Cualquier editor de texto (VS Code, Kate, Vim) o la vista del repositorio en
GitHub/GitLab: las columnas se ven como listas y las tarjetas como casillas.

## Reglas

- **No se edita el texto de una tarjeta en el tablero.** Se cambia en
  `historias-usuario.md` y se regenera; el tablero se sobrescribe.
- **No se agregan tareas solo en el tablero.** Una tarea nueva entra por el
  documento y el CSV; al regenerar aparece en `Por hacer`.
- **No se renombran las columnas.** El generador reconoce exactamente
  `Por hacer`, `En curso`, `En pruebas / QA`, `Listo para producción` y
  `Hecho`. El sufijo `(WIP n)` del encabezado es opcional y no forma parte
  del nombre de la columna.
- **No se quita el encabezado `kanban-plugin: basic`.** Es lo que identifica
  el archivo como tablero.
- **No se usa la casilla como estado.** El estado es la columna.
- **No se archivan tarjetas desde el complemento.** Una tarjeta archivada
  queda fuera de las columnas conocidas y el generador detiene la
  actualización para no perderla.
- Si una tarjeta desaparece del backlog, la regeneración avisa y la
  descarta.
- Cada tarjeta tiene un solo responsable (`A` o `B`), indicado en la propia
  tarjeta.

## Verificación

`make tablero-verificar` devuelve código 0 y «El tablero está al día» cuando
el contenido coincide con el backlog. Devuelve 1 si:

- el documento y el CSV no coinciden en el número de tareas;
- el tablero tiene una tarjeta repetida, una tarjeta fuera de las columnas
  conocidas o le falta una tarjeta del backlog;
- una columna supera su límite de trabajo en curso;
- el texto de una tarjeta quedó viejo porque el documento cambió y no se
  regeneró.
