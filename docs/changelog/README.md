# Registro de cambios

Bitácora de los trabajos aceptados en el proyecto: correcciones de formato y
de contenido aplicadas al informe. **No forma parte de `main.tex`** ni del
PDF final.

Este archivo es la **referencia canónica** de la convención.

## Convención de nombres

Cada trabajo aceptado se guarda en un archivo independiente:

```text
YYYY-MM-DDTHHMMSS_descripcion-breve.md
```

Ejemplo:

```text
2026-11-17T104129_correcciones-formato-contenido.md
```

La hora es la hora local del equipo. El nombre descriptivo debe resumir el
alcance principal del trabajo.

## Estructura de cada registro

Cada archivo debe incluir, como mínimo:

1. **Fecha y alcance** del trabajo.
2. **Documento generado** y número de páginas.
3. **Cambios de formato**.
4. **Cambios de contenido**, organizados por sección.
5. **Archivos modificados**.
6. **Validación realizada**.
7. **Pendientes o decisiones** para el siguiente trabajo.

## Reglas

- El registro se escribe **una vez que el usuario acepta el trabajo**, no al
  cerrar cada iteración técnica. Un trabajo aceptado genera **un** registro.
- Si un trabajo se corrige antes de ser aceptado, las correcciones quedan en
  el árbol de trabajo y no generan entradas adicionales.
- No se modifican los registros ya aceptados, salvo que el usuario pida
  explícitamente fusionarlos.
- Los cambios deben describirse en tercera persona y sin datos sensibles.
- Si un cambio se revierte, se registra la reversión en la iteración
  correspondiente, no se borra el registro anterior.
- Los archivos de esta carpeta no se incluyen en el informe LaTeX.

## Iteraciones

| Fecha | Archivo | Alcance |
|---|---|---|
| 2026-11-17 10:41 | `2026-11-17T104129_correcciones-formato-contenido.md` | Formato general y correcciones de contenido de las secciones 1 a 10. |
| 2026-11-17 11:23 | `2026-11-17T112357_canal-autoservicio-turista.md` | Canal de autoservicio del cliente en el informe y en la base de datos temporal. |
| 2026-11-17 11:44 | `2026-11-17T114408_backlog-y-diagramas-de-secuencia.md` | Backlog de historias de usuario revisado y diagramas de secuencia regenerados. |
| 2026-11-17 12:03 | `2026-11-17T120305_exportacion-png.md` | Exportación de diagramas a PNG y corrección de los diagramas de secuencia. |
| 2026-11-17 13:12 | `2026-11-17T131205_verificacion-y-correccion-de-la-documentacion.md` | Verificación de la reagrupación y corrección de la documentación que no había cambiado. |
| 2026-11-17 13:16 | `2026-11-17T131626_reorganizacion-del-proyecto.md` | Reagrupación de carpetas, publicación del PDF final y regla del registro de cambios. |
| 2026-11-17 14:05 | `2026-11-17T140522_refactorizacion-de-la-documentacion.md` | Refactorización de la documentación: `AGENTS.md` como punto de entrada breve y documentos de referencia. |
| 2026-11-17 14:28 | `2026-11-17T142834_titulo-en-los-diagramas.md` | Título de la historia de usuario en la parte superior de los diagramas. |
| 2026-11-17 15:04 | `2026-11-17T150433_colocacion-de-titulos-y-portada.md` | Colocación de los títulos sin huecos y portada con dos autores. |
| 2026-11-17 17:16 | `2026-11-17T171611_criterios-y-desglose-de-tareas.md` | Criterios de aceptación de las 17 historias y desglose de las 39 tareas del backlog. |
| 2026-11-17 17:53 | `2026-11-17T175303_tablero-kanban.md` | Tablero kanban generado desde el backlog, con comandos de regeneración, verificación y requisitos de visualización. |
| 2026-11-18 13:44 | `2026-11-18T134441_monorepo-y-web-del-sistema.md` | Monorepo: la web del sistema (Nuxt, Drizzle, Better Auth, Neon), el esquema con Better Auth y la reorganización del repositorio. |
| 2026-11-18 14:57 | `2026-11-18T145700_estructura-de-desarrollo-de-la-web.md` | Estructura de desarrollo agéntico de la web: sistema de diseño, textos centralizados, componentes base, tipos compartidos y documentación. |
| 2026-11-18 17:37 | `2026-11-18T173757_neon-y-ajuste-del-esquema.md` | Base de datos en Neon (São Paulo) y ajuste del esquema, las funciones y la configuración para el pooler. |
