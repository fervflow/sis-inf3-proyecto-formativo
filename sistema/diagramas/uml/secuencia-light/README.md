# Versiones ligeras de los diagramas de secuencia

Carpeta paralela a `../secuencia/`. Cada archivo es una versión resumida del
diagrama completo correspondiente.

## Criterio

- Se conservan los estereotipos `<<interfaz>>`, `<<control>>`, `<<entidad>>` y
  `<<tabla>>`.
- Se muestra solo el **flujo principal exitoso**.
- Se reducen los participantes a un actor, una interfaz, un control, una
  entidad y una tabla.
- No incluyen fragmentos `alt`, `group`, `loop` ni notas.
- Las validaciones y excepciones quedan en la versión completa de
  `../secuencia/`.
- En HU-03, HU-06 y HU-14 el actor principal es el cliente, porque su
  consulta y su solicitud son el canal directo. En HU-13 se muestra la
  ejecución del personal, que es la que cambia el estado de la reserva.

## Generación

Los PDF se generan con el mismo comando del proyecto:

```powershell
.\build.ps1 -Diagramas
```

La salida queda en `entregables/diagramas/pdf/secuencia-light/`.
