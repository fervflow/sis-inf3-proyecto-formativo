# Configuración multiplataforma y READMEs concisos

- **Fecha:** 19 de noviembre de 2026, 14:25 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios; el trabajo no modifica el informe)
- **Alcance:** el repositorio se prepara para ser compartido entre dos o tres
  desarrolladores. Se elimina la única ruta atada a una máquina, se corrige
  la documentación que la reproducía y se reducen los README y las guías de
  trabajo para que sean directos y sin duplicación.

## Antecedente

La configuración de VS Code fijaba `plantuml.jar` en una ruta de Windows con
el usuario de un desarrollador. Esa ruta no existe en Linux ni en las demás
máquinas, y la documentación indicaba editar el archivo versionado para
reemplazarla. Además, varios README habían acumulado explicaciones,
justificaciones y alternativas que no aportaban a la tarea.

## Cambios de formato

No hubo cambios de formato en el informe: no se modificó ningún archivo
LaTeX y el PDF conserva sus 21 páginas.

## Cambios de contenido

### Configuración del editor

- `.vscode/settings.json`: se quitó la clave `plantuml.jar` con la ruta de
  Windows. La extensión PlantUML usa el JAR que incluye; si un desarrollador
  necesita otro, lo configura en sus ajustes de usuario y no en el
  repositorio. Se dejó un comentario en el archivo para evitar que la ruta
  vuelva a fijarse.
- `.vscode/extensions.json`: la recomendación del paquete de idioma español
  quedó fuera; se conservan LaTeX Workshop, PlantUML y Unified Kanban.

### Documentación de la instalación y del editor

- `README.md`: la sección de VS Code ya no afirma que `settings.json` trae
  una ruta de Arch. Explica que la vista previa funciona sin configurar nada.
- `docs/INSTALACION-WINDOWS.md`: se dejó de mandar a editar
  `.vscode/settings.json`. Se documenta que `plantuml` del sistema solo lo
  usan `build.ps1` y `make`, y que `-PlantUmlJar` es opcional.
- `web/README.md`: el despliegue en Vercel fija **Root Directory = `web`**,
  no `app`.

### Corrección de rutas y contenidos desactualizados

- `sistema/diagramas/uml/estructural/README.md`:
  `sistema/base-de-datos/esquema-temporal.sql` pasa a `bd/esquema.sql`.
- `docs/INSTALACION-WINDOWS.md`: la carpeta `sistema/base-de-datos/` pasa a
  `bd/`.
- `web/docs/base-de-datos.md`: se corrigió la contradicción sobre
  `search_path`; el SQL crudo va calificado con `turismo.` y las funciones
  fijan su propio `search_path`.
- `web/docs/flujo-de-trabajo.md`: la columna `Listo para producción` se
  describe como comprobada y pendiente de publicación, igual que en el
  tablero.
- Se corrigieron las erratas `recalls`, `delbucket`, `se integrates`,
  `se detailan`, `queAdmite` y `El Referencia`.

### READMEs y guías más concisos

- `README.md`: de 441 a 178 líneas. Se conservaron requisitos, comandos,
  estructura, tabla de archivos editables, web, diagramas y problemas
  frecuentes. La correspondencia con el reglamento UPDS se movió a
  `informe/README.md`.
- `tablero/README.md`: de 197 a 104 líneas. Se quitaron las secciones “Por
  qué estos valores” y “Alternativas válidas”, y se comprimieron las reglas.
  En los requisitos, VS Code queda primero y Obsidian como opción.
- `docs/INSTALACION-WINDOWS.md`: de 285 a 209 líneas.
- `docs/GUIA-LATEX.md`: de 346 a 292 líneas; los detalles de implementación
  de la clase se movieron aquí desde `informe/README.md`.
- `informe/README.md`: de 176 a 136 líneas.
- `sistema/diagramas/README.md`: de 153 a 101 líneas, con el conteo de
  diagramas corregido a 29.
- `sistema/diagramas/uml/estructural/README.md`: de 182 a 133 líneas.
- `sistema/diagramas/uml/procesos/README.md`: de 97 a 75 líneas.
- `sistema/diagramas/uml/casos-uso/README.md`: de 74 a 70 líneas.
- `sistema/estimacion/README.md`: de 91 a 78 líneas.
- `web/README.md`: de 150 a 114 líneas.
- `web/AGENTS.md`: de 117 a 98 líneas.
- `web/CONFIGURACION.md`: de 134 a 100 líneas.
- `web/docs/*.md`: pasada de concisión en arquitectura, convenciones, diseño,
  componentes, tipos, textos, base de datos, autenticación, pruebas,
  seguridad y flujo de trabajo.

## Archivos modificados

- `.vscode/extensions.json`, `.vscode/settings.json`.
- `AGENTS.md`, `README.md`.
- `docs/GUIA-LATEX.md`, `docs/INSTALACION-WINDOWS.md`.
- `informe/README.md`.
- `sistema/diagramas/README.md` y los README de `casos-uso`, `estructural`,
  `procesos`, `secuencia-comunes`, `secuencia-fusionados` y
  `secuencia-light`.
- `sistema/estimacion/README.md`.
- `sistema/historias-usuario/historias-usuario.md` (una errata).
- `tablero/README.md`.
- `web/README.md`, `web/AGENTS.md`, `web/CONFIGURACION.md`,
  `web/.env.example`.
- `web/docs/`: `README.md`, `arquitectura.md`, `autenticacion.md`,
  `base-de-datos.md`, `componentes.md`, `convenciones.md`,
  `design-system.md`, `flujo-de-trabajo.md`, `i18n.md`, `pruebas.md`,
  `seguridad.md`, `tipos-y-datos.md`.

## Validación

- `make verificar` terminó con cero problemas: 29 archivos UML revisados, 20
  rutas LaTeX, 0 referencias a rutas antiguas y 9 entradas del árbol del
  README comprobadas.
- `make tablero-verificar` confirmó que el tablero está al día: 39 tarjetas,
  con los límites de WIP respetados.
- El JAR incluido en la extensión PlantUML (1.2024.3) renderizó los 29
  diagramas UML con `tema-apa.puml`.
- `settings.json` conserva un JSON válido al quitar los comentarios.
- Todos los enlaces locales y los bloques de código de los Markdown se
  comprobaron sin errores.
- `git diff --check` no reportó problemas.
- `make` publicó el PDF sin errores; el documento sigue en 21 páginas.

## Pendientes

- Si un desarrollador necesita un JAR de PlantUML distinto del incluido, debe
  configurarlo en sus ajustes de usuario de VS Code; el repositorio no lleva
  rutas locales.
- La documentación de `web/docs/` sigue siendo la fuente de las reglas de la
  aplicación y debe actualizarse cuando cambie una regla, no al revés.
