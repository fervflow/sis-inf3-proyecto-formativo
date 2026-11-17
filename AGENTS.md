# AGENTS.md

Guía operativa para cualquier agente o modelo que trabaje en este
repositorio. **No forma parte del informe compilado**: es documentación de
trabajo.

Este archivo es el **punto de entrada**: contiene lo que aplica a toda tarea
y un índice con lo que hay que leer según la tarea. El detalle está en los
documentos que ese índice señala, y no aquí.

Última actualización: 2026-11-17.

## Qué es este proyecto

Informe de proyecto de grado (Sistemas de Información III, UPDS, Sede
Potosí) que analiza y propone un **sistema web de gestión de paquetes
turísticos y reservas** para Vizcacha Tours, una agencia ficticia de la
ciudad de Potosí. El documento LaTeX está en `informe/`; el material de
diseño del sistema, en `sistema/`.

## Datos que no se cambian sin instrucción

| Dato | Valor |
|---|---|
| Agencia | **Vizcacha Tours**, Potosí (ficticia) |
| Problema científico | ¿Cómo mejorar la consistencia del proceso de reservas de paquetes turísticos en Vizcacha Tours de la ciudad de Potosí durante la gestión 2026? |
| Objetivo general | Desarrollar un sistema web de gestión de reservas que mejore la consistencia del proceso de venta y reserva de paquetes turísticos en Vizcacha Tours de la ciudad de Potosí. |
| Población | 8 trabajadores + 50 clientes = 58 personas; censo (población ≤ 60) |
| Entregable | `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf` |
| Documento maestro | `main.tex` |

Cualquier cambio debe mantener la coherencia entre problema, objeto, campo de
acción, objetivo general y objetivos específicos.

## Comandos

| Qué | Linux | Windows |
|---|---|---|
| Compilar y publicar el PDF | `make` | `.\build.ps1` |
| Solo compilar | `make pdf` | `.\build.ps1 -Ver` |
| Regenerar los diagramas | `make diagramas` | `.\build.ps1 -Diagramas` |
| Exportar los diagramas a PNG | `make png` | `.\build.ps1 -Png` |
| Verificar diagramas y rutas | `make verificar` | — |
| Regenerar el tablero kanban | `make tablero` | `py sistema/tablero/generar.py` |
| Verificar el tablero kanban | `make tablero-verificar` | `py sistema/tablero/generar.py --check` |
| Compilar la hoja de resumen de la estimación | `make estimacion` | `.\build.ps1 -Estimacion` |
| Compilar la hoja de resumen con metodología Scrum | `make estimacion-scrum` | `.\build.ps1 -EstimacionScrum` |
| Republish el PDF | `make publicar` | — |
| Limpiar | `make clean` / `make distclean` | `.\build.ps1 -Limpiar` / `-LimpiarTodo` |

La bibliografía usa **biber**, no BibTeX. Usar **XeLaTeX** o **LuaLaTeX**;
nunca `pdflatex`.

## Fronteras

- `entregables/` y `_build/` son salidas: no se editan a mano.
- `sistema/tablero/tablero.md` es una salida generada: solo se mueven las
  tarjetas de columna; el texto se cambia en el backlog y se regenera.
- El problema, el objetivo y los datos de la tabla anterior no se tocan sin
  instrucción explícita del usuario.
- No se reintroducen la dedicatoria, los agradecimientos ni la sección de
  variables: los archivos quedan como respaldo.
- No se versiona nada de `entregables/`.
- La bitácora se escribe cuando el usuario acepta el trabajo, no al cerrar
  cada iteración. Un trabajo aceptado genera un registro.
- No se borran ni se reescriben los registros ya aceptados.

## Índice: qué leer según la tarea

| Vas a… | Lee |
|---|---|
| Editar el texto del informe | `informe/README.md` |
| Escribir tablas, figuras o citas | `documentacion/GUIA-LATEX.md` |
| Crear o corregir diagramas | `sistema/diagramas/README.md` |
| Tocar el esquema o las reglas de la base de datos | `sistema/base-de-datos/diccionario-datos.md` |
| Tocar el backlog de historias de usuario | `sistema/historias-usuario/historias-usuario.md` |
| Ver o mover el tablero kanban | `sistema/tablero/README.md` |
| Ver o recalcular la estimación de costos | `sistema/estimacion/README.md` |
| Registrar un trabajo aceptado | `documentacion/registro-cambios/README.md` |
| Instalar el entorno en Windows | `documentacion/INSTALACION-WINDOWS.md` |
| Entender el árbol completo del proyecto | `README.md` |

## Antes de terminar

1. `make` compila sin errores y publica el PDF en `entregables/`.
2. `make verificar` no reporta problemas.
3. El PDF conserva el número de páginas esperado y no tiene citas sin
   definir, "s. f." ni primeras personas del plural.
4. Se revisan las tablas y las figuras si hubo cambios de contenido.
5. Con la aceptación del usuario, el trabajo se registra en
   `documentacion/registro-cambios/`.
