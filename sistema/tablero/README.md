# Tablero kanban de las tareas

Vista de ejecución de las 39 tareas del backlog, en cuatro columnas:

| Columna | Significado |
|---|---|
| `Pendiente` | Todavía no se empezó |
| `En curso` | Se está trabajando en ella |
| `En revisión` | Terminada, a la espera de comprobación |
| `Hecho` | Cumple los criterios de su historia |

El tablero **no es la fuente del contenido**: las tareas, su texto y su
responsable salen de `sistema/historias-usuario/historias-usuario.md`, y la
prioridad, el riesgo y la estimación, de `historias-usuario.csv`. El tablero
solo guarda el **estado**: la columna en la que está cada tarjeta.

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
python3 sistema/tablero/generar.py
python3 sistema/tablero/generar.py --check
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
muestran como cuatro listas. Las extensiones solo agregan la vista de
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
   o usar el comando `Kanban: View as Board`.

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
  documento y el CSV; al regenerar aparece en `Pendiente`.
- **No se renombran las columnas.** El generador reconoce exactamente
  `Pendiente`, `En curso`, `En revisión` y `Hecho`.
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
- el texto de una tarjeta quedó viejo porque el documento cambió y no se
  regeneró.
