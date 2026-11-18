# Refactorización de la documentación del proyecto

- **Fecha:** 17 de noviembre de 2026, 14:05 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios)
- **Alcance:** depuración de la redundancia entre los documentos del
  proyecto y división del `AGENTS.md` en un punto de entrada breve con
  referencias condicionales.

## Antecedente

El `AGENTS.md` había crecido hasta las 536 líneas y 22 KB, y la
documentación del proyecto sumaba 1 658 líneas en cuatro archivos que
compartían contenido. La medición del solapamiento reveló un problema
peor que la duplicación literal: el árbol de estructura del proyecto
estaba copiado en tres documentos y las tres versiones **habían divergido**,
de modo que ninguna era fiable. Solo coincidían tres de sus entradas.

## Cambios de contenido

No hubo cambios en el contenido del informe.

## Cambios de formato

Ninguno en el documento.

## Cambios de proceso

### Fundamento

La práctica recomendada para el archivo de instrucciones de un repositorio
es que sea breve y funcione como punto de entrada, con referencias
condicionales hacia los documentos que contienen el detalle. Las mediciones
publicadas sitúan el objetivo entre 50 y 120 líneas, y fijan límites que
varios agentes no superan: Codex deja de leer al llegar a 32 KiB
combinados y Devin lee solo los primeros 16 KiB de cada archivo. Con 22 KB,
el archivo anterior habría sido truncado.

Un hallazgo relevante condicionó la decisión: una medición de Vercel
comparó un índice de rutas de documentación **dentro** del archivo de
instrucciones, que pasó todas sus evaluaciones, con los mismos documentos
empaquetados como *skill*, que pasaron el 53 %, «lo mismo que no tenerlos».
Por eso la solución se resolvió con enlaces condicionales, sin skills ni
subagentes.

### El `AGENTS.md` nuevo

Quedó en **83 líneas y 3,8 KB**, con cinco bloques: qué es el proyecto, los
datos que no se cambian sin instrucción, los comandos exactos, las fronteras
y el índice de qué leer según la tarea, más el checklist de cierre.

| Sección anterior | Destino |
|---|---|
| Reglas editoriales, formato del documento, orden de las secciones y flujo de trabajo | `informe/README.md` (nuevo) |
| Los 106 líneas de los diagramas: estereotipos, reglas del modelo, verificación y ejemplos | `sistema/diagramas/README.md` (nuevo) |
| Esquema y reglas de la base de datos | `sistema/base-de-datos/diccionario-datos.md`, que ahora se declara referencia canónica |
| Convenciones del backlog | `sistema/historias-usuario/historias-usuario.md`, con una sección nueva |
| Convención de la bitácora | `documentacion/registro-cambios/README.md`, que ya la contenía |
| Detalle de la compilación en Windows y en Linux | `documentacion/INSTALACION-WINDOWS.md` y `documentacion/GUIA-LATEX.md` |
| Árbol completo del proyecto | `README.md`, como única copia |

### Los documentos que se existent

- `README.md` perdió los fragmentos de LaTeX y la sección «Cómo editar el
  informe», que ahora están en los documentos de referencia, y ganó la
  tabla «Qué archivo se edita», que antes vivía en la guía de LaTeX.
- `documentacion/GUIA-LATEX.md` dejó de repetir el árbol completo, que
  estaba desactualizado, y conserva una vista reducida de los archivos de
  LaTeX con la referencia al árbol canónico.
- `documentacion/INSTALACION-WINDOWS.md` no requirió cambios: su propósito
  ya era distinto de los demás.

### Un tercer control automático

`sistema/verificar-rutas.py` incorporó una comprobación nueva: **el árbol
del `README.md` debe coincidir con las carpetas reales del disco**. Es la
defensa directa contra el problema que originó la divergencia.

La comprobación se puso a prueba de inmediato y encontró dos fallos
reales: un bloque `informe/` duplicado que había quedado en el `README.md`
por una edición parcial, y dos entradas del árbol separadas por un solo
espacio en lugar de dos. Se corrigieron ambos.

## Archivos modificados

- `AGENTS.md`
- `README.md`
- `documentacion/GUIA-LATEX.md`
- `documentacion/registro-cambios/README.md`
- `sistema/base-de-datos/diccionario-datos.md`
- `sistema/historias-usuario/historias-usuario.md`
- `sistema/verificar-rutas.py`
- `informe/README.md` (nuevo)
- `sistema/diagramas/README.md` (nuevo)

## Validación

| Medida | Antes | Después |
|---|---|---|
| `AGENTS.md` | 536 líneas · 22 KB | 83 líneas · 3,8 KB |
| Bloques duplicados de tres o más líneas | 23 | 0 |
| Copias del árbol de estructura | 3 divergentes | 1 |
| Documentación total | 1 658 líneas | 1 407 líneas |

- `make verificar` terminó con cero problemas: 22 diagramas, 20 rutas
  LaTeX, 0 referencias a rutas antiguas y 24 entradas del árbol del
  `README.md` comprobadas contra el disco.
- Los ocho documentos que señala el índice del `AGENTS.md` existen; se
  comprobó uno por uno.
- `make pdf` terminó correctamente: 21 páginas, 5 379 palabras y 0 avisos
  de caja.
- El contenido del informe no se modificó: `git diff --stat` sobre los
  archivos `.tex`, `.cls` y `.sty` sale vacío.

## Pendientes

- Revisar con el docente el nivel de detalle de cada sección del informe,
  que no cambia con esta entrega.
