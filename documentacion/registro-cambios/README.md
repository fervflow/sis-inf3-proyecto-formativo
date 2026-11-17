# Registro de cambios

Bitácora de las correcciones de formato y contenido aplicadas al informe a lo
largo de las iteraciones. **No forma parte de `main.tex`** ni del PDF final.

## Convención de nombres

Cada iteración se guarda en un archivo independiente:

```text
YYYY-MM-DDTHHMMSS_descripcion-breve.md
```

Ejemplo:

```text
2026-11-17T104129_correcciones-formato-contenido.md
```

La hora es la hora local del equipo. El nombre descriptivo debe resumir el
alcance principal de la iteración.

## Estructura de cada registro

Cada archivo debe incluir, como mínimo:

1. **Fecha y alcance** de la iteración.
2. **Documento generado** y número de páginas.
3. **Cambios de formato**.
4. **Cambios de contenido**, organizados por sección.
5. **Archivos modificados**.
6. **Validación realizada**.
7. **Pendientes o decisiones** para la siguiente iteración.

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
| 2026-11-17 13:16 | `2026-11-17T131626_reorganizacion-del-proyecto.md` | Reagrupación de carpetas, publicación del PDF final y regla del registro de cambios. |
