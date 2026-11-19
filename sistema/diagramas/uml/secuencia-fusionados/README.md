# Diagramas fusionados

Variantes que combinan dos historias con alto solapamiento. Son
**alternativas**: no reemplazan a los diagramas individuales de
`../secuencia/`.

| Archivo | Historias | Contenido |
|---|---|---|
| `hu-03-05-consulta-cotizacion.puml` | HU-03 + HU-05 | Consulta de disponibilidad y elaboración de la cotización |
| `hu-07-13-gestion-estado-reserva.puml` | HU-07 + HU-13 | Seguimiento, confirmación, finalización o cancelación |

## Diferencias con los originales

- HU-03 + HU-05 usa dos controles: disponibilidad y cotizaciones.
- HU-07 + HU-13 agrega `SELECT ... FOR UPDATE` antes de validar y cambiar
  el estado.
- La cancelación conserva motivo, historial y aviso; la solicitud del
  cliente se registra antes de que el personal la ejecute.
- El aviso se emite cuando cambia la fecha o la capacidad de una salida
  (HU-16).

## Generación

```powershell
.\build.ps1 -Diagramas
```

Los PDF quedan en `entregables/diagramas/pdf/secuencia-fusionados/`.
