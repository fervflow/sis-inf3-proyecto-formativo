# Subflujos comunes

Fragmentos reutilizables extraídos de los diagramas completos de
`../secuencia/`. No repiten actor ni interfaz porque no son casos de uso
completos: muestran solo la interacción entre control, entidad y tabla.

| Archivo | Contenido | Se usa en |
|---|---|---|
| `comun-disponibilidad.puml` | Ocupación, cupo y disponibilidad | HU-03, HU-05, HU-06, HU-09 |
| `comun-cliente.puml` | Búsqueda y validación de cliente | HU-05, HU-06 |
| `comun-reserva.puml` | Carga de reserva y estado | HU-07, HU-13, HU-14 |
| `comun-saldo.puml` | Anticipo, saldo y pendiente | HU-07, HU-14 |
| `comun-cambio-estado.puml` | Bloqueo, cambio de estado y auditoría | HU-07, HU-13 |

## Uso en el informe

Los diagramas completos siguen siendo autocontenidos. Estos archivos quedan
como anexo o material de apoyo y pueden referenciarse con un fragmento:

```plantuml
ref over CTRL, E_SALIDA, E_RESERVA, T_SALIDA, T_RESERVA
  «Común · Calcular disponibilidad»
```

## Generación

```powershell
.\build.ps1 -Diagramas
```

Los PDF quedan en `diagramas/generados/secuencia-comunes/`.
