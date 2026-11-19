# AGENTS.md

Guía operativa para agentes y modelos que trabajen en este repositorio.
**No forma parte del informe compilado**: es documentación de trabajo.

Este archivo es el punto de entrada. El detalle está en los documentos del
índice final.

Última actualización: 2026-11-19.

## Qué es este proyecto

Informe de proyecto de grado (Sistemas de Información III, UPDS, Sede
Potosí) que analiza y propone un **sistema web de gestión de paquetes
turísticos y reservas** para Vizcacha Tours, agencia ficticia de Potosí. El
documento LaTeX está en `informe/`; el diseño del sistema, en `sistema/`.

## Datos que no se cambian sin instrucción

| Dato | Valor |
|---|---|
| Agencia | **Vizcacha Tours**, Potosí (ficticia) |
| Problema científico | ¿Cómo mejorar la consistencia del proceso de reservas de paquetes turísticos en Vizcacha Tours de la ciudad de Potosí durante la gestión 2026? |
| Objetivo general | Desarrollar un sistema web de gestión de reservas que mejore la consistencia del proceso de venta y reserva de paquetes turísticos en Vizcacha Tours de la ciudad de Potosí. |
| Población | 8 trabajadores + 50 clientes = 58 personas; censo (población ≤ 60) |
| Entregable | `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf` |
| Documento maestro | `main.tex` |

Cualquier cambio debe mantener la coherencia entre problema, objeto, campo
de acción, objetivo general y objetivos específicos.

## Comandos

| Qué | Linux | Windows |
|---|---|---|
| Compilar y publicar el PDF | `make` | `.\build.ps1` |
| Compilar sin regenerar diagramas | `make pdf` | — |
| Regenerar los diagramas | `make diagramas` | `.\build.ps1 -Diagramas` |
| Exportar los diagramas a PNG | `make png` | `.\build.ps1 -Png` |
| Verificar diagramas y rutas | `make verificar` | — |
| Regenerar el tablero kanban | `make tablero` | `py tablero/generar.py` |
| Verificar el tablero kanban | `make tablero-verificar` | `py tablero/generar.py --check` |
| Instalar dependencias de la web | `make web-install` | `npm install` |
| Levantar la web en desarrollo | `make web-dev` | `npm run dev --workspace web` |
| Compilar la web | `make web-build` | `npm run build --workspace web` |
| Crear el esquema de la base | `make db-crear` | `psql "$DATABASE_URL_UNPOOLED" -f bd/esquema.sql` |
| Traer las variables de Neon | `make neon-env` | `neon env pull` |
| Compilar la hoja de estimación | `make estimacion` | `.\build.ps1 -Estimacion` |
| Compilar la hoja con Scrum | `make estimacion-scrum` | `.\build.ps1 -EstimacionScrum` |
| Volver a publicar el PDF | `make publicar` | — |
| Limpiar | `make clean` / `make distclean` | `.\build.ps1 -Limpiar` / `-LimpiarTodo` |

La bibliografía usa **biber**, no BibTeX. Usar **XeLaTeX** o **LuaLaTeX**;
nunca `pdflatex`.

## Fronteras

- `entregables/` y `_build/` son salidas: no se editan a mano.
- `tablero/tablero.md` es generado: solo se mueven tarjetas; el texto se
  cambia en el backlog y las fechas y costos en
  `tablero/planificacion.csv`, y se regenera.
- `bd/esquema.sql` es la fuente canónica del esquema; `web/db/schema.ts` lo
  refleja y cambian juntos.
- `node_modules/`, `_build/`, `entregables/` y las salidas de Nuxt no se
  versionan.
- El problema, el objetivo y los datos de la tabla anterior no se tocan sin
  instrucción explícita.
- No se reintroducen la dedicatoria, los agradecimientos ni la sección de
  variables: los archivos quedan como respaldo.
- La bitácora se escribe cuando el usuario acepta el trabajo. No se borran
  ni se reescriben los registros aceptados.

## Índice

| Vas a… | Lee |
|---|---|
| Editar el texto del informe | `informe/README.md` |
| Escribir tablas, figuras o citas | `docs/GUIA-LATEX.md` |
| Crear o corregir diagramas | `sistema/diagramas/README.md` |
| Tocar el esquema o las reglas de la base | `bd/diccionario-datos.md` |
| Tocar el backlog | `sistema/historias-usuario/historias-usuario.md` |
| Ver o mover el tablero kanban | `tablero/README.md` |
| Tocar la web del sistema | `web/README.md` |
| Ver o recalcular la estimación | `sistema/estimacion/README.md` |
| Registrar un trabajo aceptado | `docs/changelog/README.md` |
| Instalar el entorno en Windows | `docs/INSTALACION-WINDOWS.md` |
| Entender el árbol del proyecto | `README.md` |

## Antes de terminar

1. `make` compila sin errores y publica el PDF.
2. `make verificar` no reporta problemas.
3. El PDF conserva el número de páginas y no tiene citas sin definir,
   “s. f.” ni primera persona del plural.
4. Se revisan tablas y figuras si hubo cambios de contenido.
5. Con la aceptación del usuario, se registra en `docs/changelog/`.
