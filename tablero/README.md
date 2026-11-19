# Tablero kanban de las tareas

Vista de ejecución de las 39 tareas del backlog, en cinco columnas. El
contenido sale de `sistema/historias-usuario/historias-usuario.md` y de
`historias-usuario.csv`; el tablero solo guarda el estado de cada tarjeta.

| Columna | Significado | WIP |
|---|---|---|
| `Por hacer` | Cola de entrada | — |
| `En curso` | Se está trabajando en ella | **4** |
| `En pruebas / QA` | Terminada, a la espera de comprobación | **2** |
| `Listo para producción` | Comprobada, pendiente de publicación | **1** |
| `Hecho` | Publicada y con los criterios de su historia cumplidos | — |

## Límites de trabajo en curso

El límite de WIP es el número máximo de tarjetas en una columna. Se cuenta
en tarjetas, no en puntos, y se escribe en el encabezado:

```markdown
## En curso (WIP 4)
```

`make tablero-verificar` falla si una columna supera su límite, y
`make tablero` se niega a escribir mientras eso ocurra.

## Archivos y comandos

| Archivo | Rol |
|---|---|
| `tablero.md` | El tablero; solo se edita para mover tarjetas |
| `generar.py` | Regenera el tablero desde el backlog y conserva las columnas |
| `README.md` | Este documento |

```bash
make tablero            # regenera el tablero
make tablero-verificar  # comprueba que esté al día, sin escribir
```

Sin `make`: `python3 tablero/generar.py` y `python3 tablero/generar.py --check`.

`generar.py` comprueba que el documento y el CSV coincidan (historias,
tareas por historia y total). Si algo no cuadra, muestra el detalle y no
toca el tablero.

## Cómo mover una tarjeta

Cortar la línea completa y pegarla bajo el encabezado de la otra columna.
La columna es el estado; la casilla `[ ]` la escriben los visores y el
generador la deja siempre vacía. No se usa para marcar terminado.

## Requisitos para verlo

El archivo es Markdown: cualquier editor lo abre y GitHub o GitLab lo
muestran como cinco listas. Las extensiones solo agregan la vista de
tablero.

### VS Code (recomendado)

1. Instalar **Unified Kanban** (`divisionseven.unified-kanban`), desde el
   Marketplace o Open VSX. Requiere VS Code 1.85 o superior.
2. Abrir `tablero.md` con clic derecho → **Open With…** → **Kanban Board**,
   o ejecutar **Kanban: View as Board**.

### Obsidian (opcional)

1. Instalar Obsidian desde <https://obsidian.md/download> y abrir la
   carpeta del repositorio como bóveda.
2. Ajustes → **Complementos de la comunidad** → desactivar el modo
   restringido.
3. **Examinar** → buscar **Boardwalk** → **Instalar** → **Activar**.
   Boardwalk está mantenido y usa el mismo formato que el Kanban original.
4. Abrir `tablero.md`: el encabezado `kanban-plugin: basic` lo abre como
   tablero.

### Sin extensión

Cualquier editor de texto o la vista del repositorio: las columnas se ven
como listas y las tarjetas como casillas.

## Reglas

- No se edita el texto de una tarjeta en el tablero: se cambia en
  `historias-usuario.md` y se regenera.
- No se agregan tareas solo en el tablero: entran por el documento y el
  CSV.
- No se renombran las columnas ni se quita el encabezado
  `kanban-plugin: basic`.
- No se usa la casilla como estado ni se archivan tarjetas desde el
  complemento.
- Cada tarjeta tiene un solo responsable (`A` o `B`), indicado en ella.

## Verificación

`make tablero-verificar` devuelve 0 y «El tablero está al día» cuando el
contenido coincide con el backlog. Devuelve 1 si el documento y el CSV no
cuadran, si falta o sobra una tarjeta, si una columna supera su WIP o si el
texto de una tarjeta quedó viejo.

## Regla de cierre de historia

Las tareas miden el flujo; los puntos, el alcance. Una historia está
**Hecho** cuando todas sus tareas están en `Hecho`; suma sus puntos una
sola vez, en la ventana en que cierra su última tarea.
