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

- No se modifican los registros anteriores: cada iteración crea un archivo
  nuevo.
- Los cambios deben describirse en tercera persona y sin datos sensibles.
- Si un cambio se revierte, se registra la reversión en la iteración
  correspondiente, no se borra el registro anterior.
- Los archivos de esta carpeta no se incluyen en el informe LaTeX.

## Iteraciones

| Fecha | Archivo | Alcance |
|---|---|---|
| 2026-11-17 10:41 | `2026-11-17T104129_correcciones-formato-contenido.md` | Formato general y correcciones de contenido de las secciones 1 a 10. |
| 2026-11-17 11:23 | `2026-11-17T112357_canal-autoservicio-turista.md` | Canal de autoservicio del cliente en el informe y en la base de datos temporal. |
