# CAPÍTULO III de la propuesta y alineación con el borrador

## Fecha y alcance

25 de noviembre de 2026. Alineación del informe LaTeX con el borrador
externo (`informe/informe.pdf`) y con la estructura exigida por la cátedra
(`informe/estructura.pdf`): se incorpora el capítulo de la propuesta con el
rótulo «CAPÍTULO III» y subsecciones 3.1 a 3.4, las secciones preliminares
quedan sin número y se corrigen las inconsistencias del borrador contra las
fuentes reales del proyecto (backlog, tablero, reglas de negocio,
estimación). Se actualizan los diagramas desactualizados y se crean los que
faltaban.

## Documento generado

«Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos
y Reservas.pdf» con 51 páginas (antes 21): 15 tablas y 12 figuras.

## Cambios de formato

- Secciones preliminares sin numerar, mediante el nuevo
  `\capituloSinNumero` (`entornos-apa.sty`) y `\section*`; sus entradas en
  el índice quedan sin número, como en el borrador.
- La propuesta es el único capítulo numerado: `CAPÍTULO III` con
  subsecciones `3.1` a `3.4` (el contador se fija en `main.tex`).
- El árbol de problemas se movió del Anexo a la sección Situación
  problemática como figura 1, en página horizontal.
- El glosario dejó de incluirse (archivo como respaldo); el Anexo A pasa a
  ser el resumen de estimación de costos.
- Corrección en `build.ps1`: el envoltorio TikZ recibía una ruta absoluta
  con barras invertidas dentro de `\input{...}` y por eso
  `.\build.ps1 -Png` fallaba siempre al rasterizar el árbol.

## Cambios de contenido

### Secciones preliminares

- Objetivo general reformulado como «...mejore la consistencia del proceso
  de venta de paquetes turísticos...» (antes «venta y reserva»), por
  indicación del usuario; aplicado al resumen, a los objetivos, a la
  situación problemática, a los alcances y a la tabla de datos protegidos
  de `AGENTS.md`. El problema científico no cambió.
- Nueva sección «Métodos de investigación» (métodos teóricos y empíricos,
  enfoque mixto, tipo descriptivo-propositivo, diseño de campo).
- Retirada la cita de Miranda Ayala et al. (2022): la tesis no pudo
  verificarse en ninguna fuente pública y figuraba como provisional.
  Huaman Quispe (2017) queda como único antecedente académico regional.

### Capítulo III (nuevo, `informe/capitulos/12-propuesta.tex`)

- 3.1 Marco referencial (TPS, gestión de reservas, Kanban y STATIK, UML,
  estimación, seguridad y usabilidad) y tabla de herramientas del stack
  real (Nuxt 4/Nitro, Node.js 22, PostgreSQL en Neon, PlantUML, GitHub).
- 3.2 Estimación con los dos enfoques acordados: COCOMO básico como
  hipótesis de planificación (3 KLOC, 4.000 Bs por mes-persona) y
  estimación ágil con datos reales (19 historias, 55 puntos, 54 tareas;
  ritmo medido de 4,00 horas-persona por punto; 1,38 mes-persona;
  6.875 Bs; MVP de la primera ventana 2.500 Bs). Las tareas de corrección
  detectadas en las pruebas quedan explicadas dentro del alcance, sin
  estimación separada.
- 3.3 Proceso de negocio: diagrama de entrada-proceso-salida nuevo,
  actividades con calles y las cinco reglas principales (sin sobreventa,
  una sola fuente de disponibilidad, bloqueo transaccional, el pago no
  confirma, trazabilidad).
- 3.4 Kanban: roles, actores, políticas con los límites reales (WIP 4/2/1
  y columnas reales del tablero), las 19 historias con 55 puntos y 54
  tareas, criterios de aceptación reales condensados, 15 casos de uso que
  agrupan las 19 historias, backlog en bloques con HU-18 y HU-19 más la
  nota del MVP realmente construido (HU-08, HU-01, HU-04), tablero real al
  25/11 (45 tareas en «Hecho», 9 en «Por hacer»), STATIK aplicado,
  diagramas de clases y objetos, secuencias de HU-06 y HU-17, estados de
  la reserva, componentes, despliegue y validación ya ejecutada (pruebas
  de reglas sobre la base) con HU-18/HU-19 pendientes.

### Anexo A (nuevo, `informe/anexos/A-estimacion.tex`)

- COCOMO básico (7,61 persona-mes; 5,40 meses; 1,41 personas;
  30.426,26 Bs) junto a la estimación ágil real (220 h; 1,38 mes-persona;
  6.875 Bs; cierre estimado 07/01/2027), con la nota de que los modelos no
  son equivalentes y se adopta el ágil como presupuesto preliminar.

### Diagramas (`sistema/diagramas/`)

- Nuevos: `procesos/negocio-entrada-proceso-salida.puml`,
  `secuencia/hu-17-confirmar-solicitudes.puml` (pendiente antiguo del
  backlog) y `procesos/estados-reserva.puml`.
- Actualizados contra el esquema: `diagrama-clases.puml` y su versión
  simplificada (PaqueteItinerario, ProveedorTipo, ProveedorServicio,
  SalidaProveedor, código de la salida, métodos `banca_movil`/`qr`,
  multiplicidad de pagos corregida), `diagrama-objetos.puml` (pago web con
  QR simulado y código de salida), `mapa-procesos.puml` (ficha de la
  salida y HU-19), `casos-uso.puml` (15 casos de las 19 historias) y
  `estimacion-entrada-proceso-salida.puml` (cifras de la re-estimación).

### Bibliografía

- Entradas nuevas: Boehm (1981), Object Management Group (2017) y Kanban
  University (2026, guía v2.1, con año real en lugar de «s. f.»).

### Documentación

- `informe/README.md` (orden del documento y correspondencia con el
  reglamento), `sistema/diagramas/README.md`,
  `sistema/historias-usuario/historias-usuario.md` (pendiente del diagrama
  de HU-17 cerrado) y `AGENTS.md`.

## Validación realizada

- `sistema/verificar-uml.py`: 42 archivos revisados, 0 problemas.
- `sistema/verificar-rutas.py`: 0 problemas.
- `.\build.ps1`: tres pasadas XeLaTeX y biber sin errores; sin referencias
  sin definir, sin «s. f.», sin primera persona del plural y sin
  marcadores de diagrama pendiente.
- PNG regenerados a 300 DPI, incluido el del árbol, que fallaba antes de
  la corrección de `build.ps1`.

## Pendientes o decisiones para el siguiente trabajo

- El usuario indicó que hay aspectos del capítulo nuevo por corregir:
  queda una revisión pendiente del PDF publicado.
- Validar HU-18 y HU-19 al cerrar su implementación en el tablero.
- La referencia de Miranda Ayala et al. (2022) se retiró; se reincorpora
  con datos completos si aparece la fuente.
