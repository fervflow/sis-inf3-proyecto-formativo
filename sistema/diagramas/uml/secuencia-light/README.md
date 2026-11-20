# Versiones ligeras

Carpeta paralela a `../secuencia/`: cada archivo resume el diagrama completo
correspondiente.

## Criterio

- Se conservan los estereotipos `<<interfaz>>`, `<<control>>`, `<<entidad>>`
  y `<<tabla>>`.
- Se muestra solo el flujo principal exitoso.
- Se reduce a un actor, una interfaz, un control, una entidad y una tabla.
- No incluyen `alt`, `group`, `loop` ni notas.
- Las validaciones y excepciones quedan en la versión completa.
- En HU-03, HU-06 y HU-14 el actor es el cliente; en HU-13, el personal,
  que es quien cambia el estado; en HU-01, HU-02 y HU-09, el administrador.

## Generación

```powershell
.\build.ps1 -Diagramas
```

La salida queda en `entregables/diagramas/pdf/secuencia-light/`.
