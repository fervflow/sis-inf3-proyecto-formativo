# Estimación de costos del sistema

Estimación del esfuerzo y del costo de construir el sistema web de gestión
de paquetes turísticos y reservas de Vizcacha Tours, con el método ágil que
usa el proyecto: **puntos de historia** como unidad de tamaño, el **tablero
Kanban** como forma de medir el flujo y una **tarifa por mes-persona** para
convertir el esfuerzo en dinero.

**No forma parte del informe compilado**: es documentación de trabajo.

- **Fecha:** 17 de noviembre de 2026
- **Alcance estimado:** las 17 historias de usuario del backlog (47 pts,
  39 tareas)
- **Fuentes:** `sistema/historias-usuario/historias-usuario.md` y su CSV,
  `tablero/tablero.md`, `sistema/estimacion/README.md`
- **Costo estimado del alcance completo:** **5.875 Bs**
- **Costo del MVP de la primera ventana:** **2.500 Bs**

---

## 1. Unidades y supuestos

Toda la estimación se apoya en estas seis unidades. Si alguna cambia, cambian
los resultados, y por eso se declaran explícitamente.

| Unidad | Valor | Justificación |
|---|---|---|
| Dedicación diaria | 4 h por persona y día hábil | Proyecto universitario: el trabajo es de tiempo parcial. |
| Días hábiles por mes | 20 | Calendario laboral habitual. |
| Día-persona | 4 h | Dedicación × 1 día hábil. |
| Mes-persona | 160 h | Mes de tiempo completo: 20 días × 8 h. |
| Tarifa | **5.000 Bs por mes-persona** | Equivale a 31,25 Bs por hora. Es la base para convertir esfuerzo en dinero. |
| Tamaño relativo | 1 punto de historia | Escala Fibonacci del backlog (valores 2, 3 y 5). |

**Sobre la tarifa.** Se toma como **mes-persona de tiempo completo**, no como
mes-persona de dedicación parcial. La razón es que un salario es un salario
de tiempo completo: si el proyecto ocupa la mitad del día, el **plazo** se
alarga, pero **la persona no se abarata**. Fijarla sobre el mes de tiempo
completo evita que la dedicación del equipo contamine el costo por hora.

**Sobre el alcance de la estimación.** Se estima la **construcción del
sistema**, no la redacción del informe. El informe es el resultado académico
del proyecto; el sistema es el objeto que se diseña y que se estima.

---

## 2. Datos de partida

Vienen del backlog y del tablero. No hay cifras escritas a mano: todas se
leen de esos archivos.

| Dato | Valor | Origen |
|---|---|---|
| Historias de usuario | 17 | Backlog |
| Puntos de historia | 47 | Columna «Estimación» del CSV |
| Tareas | 39 | Desglose de tareas |
| Puntos de riesgo alto | 22 de 47 (47 %) | Columna «Riesgo» del CSV |
| Reparto de trabajo | 20 tareas al programador A, 19 al B | Desglose de tareas |
| Tareas en `Hecho` | 7 | Tablero Kanban |
| Tareas en `En curso` | 4 (en el límite) | Tablero Kanban |
| Tareas en `Por hacer` | 28 | Tablero Kanban |

La estimación está **fechada**: refleja el estado del tablero el 17 de
noviembre de 2026, con HU-02, HU-03, HU-10 y HU-05 ya en curso. Las cuatro
historias están en curso porque cada una tiene al menos una tarea en
`En curso` y le queda alguna en `Por hacer`, que es la regla de cierre del
tablero.

---

## 3. La ventana 1: el MVP

| Dato | Valor |
|---|---|
| Inicio | jueves 12 de noviembre de 2026 |
| Cierre | miércoles 25 de noviembre de 2026 |
| Días naturales | 14 |
| Días hábiles | 10 (se pierden 4 de fin de semana) |
| Equipo | 2 desarrolladores |
| Capacidad | 2 × 10 × 4 h = **80 horas-persona** |

### Contenido de la ventana

Las tres historias del MVP, que son las que el tablero registra ya en
`Hecho`:

| Historia | Puntos | Tareas | Responsable |
|---|---|---|---|
| HU-08 · Iniciar sesión y acceder según el rol | 3 | 3 | A |
| HU-01 · Gestión de paquetes turísticos | 3 | 2 | A |
| HU-04 · Registro y actualización de la ficha del cliente | 2 | 2 | B |
| **Total** | **8** | **7** | |

Las tres historias elegidas son las que **permiten operar el sistema**:
sin autenticación no hay acceso por rol, sin paquetes no hay oferta y sin
clientes no hay contra quién reservar. Es un **producto mínimo viable**: lo
menor que se puede publicar y usar.

### Costo de la ventana

```
Capacidad     = 2 desarrolladores × 10 días hábiles × 4 h   =  80 horas-persona
Esfuerzo      = 80 h ÷ 160 h por mes-persona                 =  0,50 mes-persona
Costo         = 0,50 × 5.000 Bs                             =  2.500 Bs
```

---

## 4. Ritmo medido

Al 17 de noviembre de 2026, la ventana lleva **4 días hábiles** transcurridos
(12, 13, 16 y 17). El tablero registra 7 tareas en `Hecho` y 8 puntos.

```
Horas-persona      = 2 × 4 días × 4 h                   =  32 horas-persona
Throughput           = 7 tareas ÷ 4 días                  =  1,75 tareas por día de equipo
Throughput           = 8 puntos ÷ 4 días                  =  2,00 puntos por día de equipo
Esfuerzo por punto   = 32 h ÷ 8 puntos                    =  4,00 horas-persona por punto
Esfuerzo por tarea   = 32 h ÷ 7 tareas                    =  4,57 horas-persona por tarea
```

### El indicador que más importa

> **Un punto de historia cuesta 4,00 horas-persona.**

Es el único dato que hace falta para estimar alcance nuevo: si se agrega una
historia de 3 puntos, se agregan 12 horas-persona. No depende del calendario,
de la duración de la ventana ni de cuántos días se trabaje.

---

## 5. Proyección a alcance completo

### Esfuerzo

```
Lo ya gastado       =  32 horas-persona
Lo que falta        =  39 puntos × 4,00 h por punto = 156 horas-persona
Esfuerzo total      =  32 + 156                        = 188 horas-persona
En mes-persona      =  188 ÷ 160                       =   1,18 mes-persona
```

### Calendario

El equipo aporta **8 horas-persona por día hábil** (2 desarrolladores × 4 h).
Los dos trabajan en paralelo, así que el número de días de calendario es el
mismo para ambos: no se divide entre dos.

```
Días hábiles de calendario = 188 h ÷ 8 h por día de equipo = 23,5 días
Ventanas de 2 semanas       = 23,5 ÷ 10 días hábiles         =  2,35 ventanas
Cierre estimado             = 15 de diciembre de 2026
```

### El contraste con Scrum

La misma cifra se obtiene por un camino independiente. Un sprint de dos
semanas tiene la capacidad de la ventana: 10 días hábiles × 8 h = 80 h, que a
4,00 h por punto son **20 puntos por sprint**. Con 47 puntos:

```
47 ÷ 20 puntos por sprint = 2,35 sprints
```

Los dos métodos coinciden en **2,35 unidades de control**. No es casualidad:
las dos cuentas miden lo mismo —las horas que el equipo puede aportar— y solo
cambia la unidad con la que se agrupan. Es el mejor control de la estimación,
porque dos caminos independientes dan el mismo número.

### Costo

```
Costo = 1,18 mes-persona × 5.000 Bs = 5.875 Bs
```

| Reparto | Horas-persona | Mes-persona | Costo |
|---|---|---|---|
| Ya gastado (hasta el 17/11) | 32 | 0,20 | 1.000 Bs |
| Restante | 156 | 0,98 | 4.875 Bs |
| **Total** | **188** | **1,18** | **5.875 Bs** |

### Sensibilidad

Toda la estimación depende de un solo supuesto medido: las 4,00 horas-persona
por punto. Si el ritmo real fuera otro, el costo y el plazo se mueven así:

| h por punto | Esfuerzo total | Mes-persona | Costo | Días de equipo | Cierre |
|---|---|---|---|---|---|
| 3,00 (más rápido) | 149 h | 0,93 | 4.656 Bs | 18,6 | 08/12/2026 |
| **4,00 (el medido)** | **188 h** | **1,18** | **5.875 Bs** | **23,5** | **15/12/2026** |
| 5,00 (algo más lento) | 227 h | 1,42 | 7.094 Bs | 28,4 | 21/12/2026 |
| 6,00 (más lento) | 266 h | 1,66 | 8.313 Bs | 33,2 | 28/12/2026 |

El costo se mueve poco, porque la tarifa es baja; lo que cambia de verdad es
la fecha. En los cuatro escenarios el alcance completo cabe en un mes de
trabajo, muy por debajo de los catorce días del horizonte del MVP.

---

## 6. Coherencia entre el límite de WIP y el ritmo

La ley de Little relaciona las tres magnitudes del flujo:

```
WIP = Throughput × Tiempo de ciclo
```

Con el throughput medido de 1,75 tareas por día de equipo, cada límite de WIP
implica un tiempo de ciclo distinto:

| Límite de WIP en `En curso` | Tiempo de ciclo por tarjeta |
|---|---|
| 2 | 1,14 días |
| 3 | 1,71 días |
| **4 (el aplicado)** | **2,29 días** |

El límite de 4 es el que hace **sostenible** el ritmo observado: dos tareas
en curso por desarrollador, una de ellas en curso y la otra bloqueada. Con un
límite de 2, el tiempo de ciclo de 1,14 días sería demasiado ajustado para
trabajos que dependen de una revisión.

---

## 7. Riesgos de la estimación

La estimación se apoya en **cuatro días hábiles y tres historias**. Es una
muestra pequeña y hay que decirlo.

| Riesgo | Efecto | Mitigación |
|---|---|---|
| **Muestra mínima** | 4 días no representan el ritmo de todo el alcance. | Repetir la medición al cerrar la ventana, el 25/11, con las tareas de «En pruebas / QA» ya resueltas. |
| **WIP no medido** | El ritmo de 1,75 tareas/día pudo obtenerse con más de 4 tarjetas en curso. Desde el 17 de noviembre el límite está puesto y hay 4 tarjetas en curso, de modo que el rendimiento bajo el límite todavía no se ha observado. | Medir el flujo real con el límite aplicado y recalcular. Es el experimento que empieza el 25/11. |
| **Perfil de riesgo desigual** | 22 de los 47 puntos pendientes son de riesgo alto, frente a 8 puntos ya cerrados de riesgo mixto. | La estimación se recalcula al cierre de cada historia de riesgo alto. |
| **Alcance del MVP** | Si el MVP crece, crece el total. | El tablero y el backlog son la fuente; cualquier cambio se refleja al regenerarlos. |
| **Sin historial** | No hay datos de proyectos anteriores de la agencia que sirvan de contraste. | La estimación se contrasta con la velocidad observada en el propio tablero. |

---

## 8. Métricas que hay que medir desde el 25 de noviembre

El tablero ya tiene las columnas y los límites; falta registrar el flujo. Las
métricas se calculan sobre el historial de movimientos de cada tarjeta.

| Métrica | Definición | Para qué sirve |
|---|---|---|
| **Throughput** | Tareas que salen de `Hecho` por semana. | Cuántas tareas por semana sale el equipo de verdad. |
| **Tiempo de ciclo** | Días entre entrar en `En curso` y llegar a `Hecho`. | Cuánto tarda una tarjeta en el sistema. |
| **Tiempo de espera** | Días entre entrar en `En pruebas / QA` y salir de ella. | Señala si el cuello de botella está en la revisión. |
| **Trabajo en curso por columna** | Tarjetas por columna, frente a su límite. | Verifica que el límite se respeta. |
| **Puntos cerrados por ventana** | Suma de los puntos de las historias cerradas. | Convierte el ritmo en unidades de alcance. |

Con esas métricas, la estimación deja de ser una proyección y pasa a ser una
medición, y el esfuerzo por punto deja de ser un supuesto.

---

## 9. Qué no cubre esta estimación

- **El mantenimiento.** COCOMO tiene un término aparte para el mantenimiento
  posterior al despliegue; aquí no se estima.
- **El costo del hardware y del despliegue.** El alcance es la aplicación.
- **El esfuerzo de la documentación y de las pruebas como tareas aparte.**
  Las historias ya incluyen sus criterios de aceptación, que son las tareas
  de comprobación; no hay un multiplicador adicional.
- **La curva de aprendizaje.** Se asume que el equipo mantiene su ritmo.

---

## 10. Cómo se recalcula

La estimación depende de tres datos que cambian con el tablero:

1. **Tareas en `Hecho`** y **puntos cerrados**: `make tablero-verificar`.
2. **Throughput observado**: tareas cerradas por día hábil desde el inicio.
3. **Esfuerzo por punto**: horas-persona acumuladas ÷ puntos cerrados.

Al recalcular:

```
Esfuerzo restante = puntos pendientes × (horas-persona gastadas ÷ puntos cerrados)
Costo total       = (horas-persona gastadas + esfuerzo restante) ÷ 160 × 5.000 Bs
```
