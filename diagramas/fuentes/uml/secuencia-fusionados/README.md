# Diagramas fusionados

Variantes que combinan dos historias de usuario con alto solapamiento. Se
agregan como **alternativas**, no reemplazan a los diagramas individuales de
`../secuencia/`.

| Archivo | Historias | Contenido |
|---|---|---|
| `hu-03-05-consulta-cotizacion.puml` | HU-03 + HU-05 | Consulta de disponibilidad y, si el cliente acepta, elaboración de la cotización. |
| `hu-07-13-gestion-estado-reserva.puml` | HU-07 + HU-13 | Seguimiento, confirmación, finalización o cancelación de una reserva. |

## Diferencias con los originales

- El diagrama de HU-03 + HU-05 usa dos controles: disponibilidad y
  cotizaciones.
- El diagrama de HU-07 + HU-13 agrega `SELECT ... FOR UPDATE` antes de
  validar y cambiar el estado. En el diagrama original de HU-07 ese bloqueo
  no estaba explícito.
- La cancelación conserva el motivo, el historial y el aviso al turista.

## Generación

```powershell
.\build.ps1 -Diagramas
```

Los PDF quedan en `diagramas/generados/secuencia-fusionados/`.
