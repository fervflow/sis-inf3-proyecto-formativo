# AGENTS.md

Guía operativa para cualquier agente o modelo que trabaje en este
repositorio. **No forma parte del informe compilado**: es documentación de
trabajo.

Última actualización: 2026-11-17.

## 1. Qué es este proyecto

Repositorio del informe de **Sistemas de Información III**, Carrera de
Ingeniería de Sistemas, Universidad Privada Domingo Savio (UPDS), Sede
Potosí.

El informe analiza y propone un **sistema web de gestión de paquetes
turísticos y reservas** para **Vizcacha Tours**, una agencia ficticia de la
ciudad de Potosí. El documento se escribe en español, en tercera persona, con
formato APA 7 adaptado por la cátedra.

Además del informe LaTeX, el repositorio contiene:

- Diagramas PlantUML de los casos de uso del sistema.
- Un esquema temporal de base de datos PostgreSQL.
- Un backlog de historias de usuario.
- Una bitácora de cambios por iteración.

## 2. Datos fijos del proyecto

| Dato | Valor |
|---|---|
| Materia | Sistemas de Información III |
| Carrera | Ingeniería de Sistemas |
| Universidad | Universidad Privada Domingo Savio (UPDS) |
| Sede | Potosí, Bolivia |
| Agencia de estudio | **Vizcacha Tours** (ficticia) |
| Tipo de sistema | Sistema de información transaccional (TPS) |
| Periodo de población | Tercer trimestre de 2026 |
| Población | 8 trabajadores + 50 clientes = 58 personas |
| Muestra | Censo, por ser una población menor o igual a 60 |
| Documento maestro | `main.tex` |
| PDF final | `_build/main.pdf` |

### Problema científico vigente

> ¿Cómo mejorar la consistencia del proceso de reservas de paquetes
> turísticos en Vizcacha Tours de la ciudad de Potosí durante la gestión
> 2026?

### Objetivo general vigente

> Desarrollar un sistema web de gestión de reservas que mejore la
> consistencia del proceso de venta y reserva de paquetes turísticos en
> Vizcacha Tours de la ciudad de Potosí.

No cambiar estas formulaciones sin una instrucción explícita. Cualquier
cambio debe mantener la coherencia entre problema, objeto, campo de acción,
objetivo general y objetivos específicos.

## 3. Reglas editoriales obligatorias

1. Escribir en **español** y en **tercera persona**.
2. Evitar “nuestro proyecto”, “consideramos”, “creemos”, “podemos” y otras
   formas de primera persona del plural.
3. Usar siempre el nombre **Vizcacha Tours** cuando se mencione la agencia.
4. No incluir la solución tecnológica dentro del problema científico.
5. No convertir el informe en una descripción técnica del sistema: primero
   debe leerse como un informe académico.
6. Citar con `\textcite{...}` o `\parencite{...}`; no escribir autores y años
   manualmente.
7. Toda entrada de `bibliografia/referencias.bib` debe tener `year`. Evitar
   citas con “s. f.”; si una fuente no tiene fecha, buscar una fuente
   equivalente con año.
8. No reintroducir la dedicatoria, los agradecimientos ni el abstract: fueron
   retirados del documento. Los archivos existen como respaldo, pero no se
   incluyen en `main.tex`.
9. No reintroducir `capitulos/06-variables.tex`: la variable dependiente está
   en el problema científico y la variable independiente en el objetivo
   general.
10. Mantener la coherencia con las historias de usuario y los diagramas.

## 4. Formato del documento

La clase `si3apa7.cls` es la fuente de verdad del formato global. No cambiar
el formato desde los capítulos.

### Formato general

| Elemento | Definición actual |
|---|---|
| Papel | Carta |
| Márgenes | Superior 2,54 cm; inferior 2,54 cm; izquierdo 3 cm; derecho 2 cm |
| Fuente | Arial 11 pt; Liberation Sans como respaldo |
| Interlineado | 2 |
| Alineación | Justificada |
| Sangría | Primera línea 1,27 cm, incluido el primer párrafo |
| Paginación | Inferior derecha; preliminares en romanos y cuerpo en árabes |
| Fuente monoespaciada | Liberation Mono → DejaVu Sans Mono → Consolas → Courier New |

### Títulos

- Las **secciones de contenido 1 a 10** usan `\chapter{...}` pero se comportan
  como subtítulos: van a la izquierda, en negrita, numerados y **sin la
  palabra “Capítulo”**.
- Las secciones de contenido **no comienzan en página nueva**: el texto
  continúa en la misma hoja.
- **Referencias, glosario y anexos** sí comienzan en página nueva y sus títulos
  van **centrados**.
- El **resumen** va centrado.
- Los títulos de sección y subsección se numeran con punto: `2.1.`, `5.2.`,
  etc.
- El índice usa la misma numeración con punto.

### Detalles de implementación

- `\chapter` está parcheado en `si3apa7.cls` para no ejecutar `\clearpage`;
  se reemplaza por `\par`. No revertir este parche sin revisar los saltos de
  página.
- `\iniciarSeccionesFinales` cambia el formato de `\chapter` a centrado antes
  de referencias, glosario y anexos.
- `\preliminar` genera títulos centrados para resumen y glosario.
- `\RaggedRightParindent` está fijado en 1,27 cm aunque la alineación actual
  sea justificada; sirve si se vuelve a alineación izquierda.
- Las tablas y figuras se numeran de forma consecutiva con `tablaapa` y
  `figuraapa`.

## 5. Estructura del repositorio

```text
.
├── main.tex                     Documento maestro y orden de inclusión
├── si3apa7.cls                  Clase: formato, fuentes, márgenes, títulos
├── entornos-apa.sty             Entornos APA: tablas, figuras, notas
├── build.ps1                    Compilación y diagramas en Windows
├── Makefile                     Compilación y diagramas en Linux
├── latexmkrc                    Configuración de latexmk
├── README.md                    Documentación general para personas
├── GUIA-LATEX.md                Guía de LaTeX y de la plantilla
├── INSTALACION-WINDOWS.md       Instalación en Windows 11
├── AGENTS.md                    Esta guía para agentes
├── config/
│   ├── metadatos.tex            Título, autor, docente, gestión
│   └── portada.tex              Portada institucional y portada APA
├── preliminares/
│   ├── resumen.tex              Único preliminar incluido
│   ├── dedicatoria.tex          No incluido; conservado como respaldo
│   ├── agradecimientos.tex      No incluido; conservado como respaldo
│   └── abstract.tex             No incluido; conservado como respaldo
├── capitulos/                   Secciones 01 a 11 (06 no incluida)
├── finales/
│   ├── referencias.tex          Bibliografía
│   ├── glosario.tex             Glosario y acrónimos
│   └── anexos.tex               Activación de anexos
├── anexos/
│   └── A-arbol-problemas.tex    Anexo A
├── bibliografia/
│   └── referencias.bib          Base BibLaTeX
├── diagramas/
│   ├── fuentes/uml/             Fuentes PlantUML
│   ├── fuentes/tikz/            Diagramas TikZ
│   ├── generados/               PDF generados (no editar)
│   ├── otros/                   DER, arquitectura, mockups
│   └── estilos/tema-apa.puml    Tema visual PlantUML
├── tablas/
│   ├── historias-usuario.csv    Backlog en CSV
│   └── historias-usuario.md     Backlog legible y observaciones
├── codigo/base-datos/
│   ├── esquema-temporal.sql     Esquema PostgreSQL temporal
│   └── diccionario-datos.md     Diccionario y reglas
├── registro-cambios/
│   ├── README.md                Convención de la bitácora
│   └── YYYY-MM-DDTHHMMSS_...md  Registros por iteración
├── imagenes/                    Logos y capturas
└── _build/                      Salida del compilador (no editar)
```

## 6. Orden actual del documento

`main.tex` incluye, en este orden:

| # | Sección | Archivo |
|---|---|---|
| 1 | Introducción | `capitulos/01-introduccion.tex` |
| 2 | Antecedentes | `capitulos/02-antecedentes.tex` |
| 3 | Situación problemática | `capitulos/03-situacion-problematica.tex` |
| 4 | Problema científico | `capitulos/04-problema-cientifico.tex` |
| 5 | Objeto de estudio y campo de acción | `capitulos/05-objeto-estudio.tex` |
| 6 | Objetivos | `capitulos/07-objetivos.tex` |
| 7 | Población y muestra | `capitulos/08-poblacion-muestra.tex` |
| 8 | Justificación social | `capitulos/09-justificacion-social.tex` |
| 9 | Alcances del sistema | `capitulos/10-alcances-sistema.tex` |
| 10 | Límites del proyecto | `capitulos/11-limites-proyecto.tex` |

`capitulos/06-variables.tex` no se incluye. Su contenido fue retirado y el
archivo solo conserva un comentario de referencia.

Después de las secciones de contenido se incluyen:

1. `finales/referencias.tex`
2. `finales/glosario.tex`
3. `finales/anexos.tex` → `anexos/A-arbol-problemas.tex`

## 7. Flujo de trabajo para contenido

### Editar una sección

1. Abrir el archivo correspondiente en `capitulos/`.
2. Mantener el `\chapter{...}` y `\label{...}` existentes.
3. Escribir en tercera persona y con citas.
4. Compilar y revisar el PDF.

### Agregar una sección nueva

1. Crear `capitulos/NN-nombre.tex` con `\chapter{...}`.
2. Agregar `\input{capitulos/NN-nombre}` en `main.tex`, en el orden correcto.
3. Actualizar la tabla de secciones de este archivo y de `README.md`.

### Tablas y figuras

Usar los entornos existentes:

```latex
\begin{tablaapa}{tab:etiqueta}{Título de la tabla}
  \begin{tabular}{@{}lcc@{}}
  \toprule
  Encabezado & A & B \\
  \midrule
  Dato & 1 & 2 \\
  \bottomrule
  \end{tabular}
  \nota{Elaboración propia.}
\end{tablaapa}
```

```latex
\begin{figuraapa}{fig:etiqueta}{Título de la figura}
  \incluirDiagrama[0.95\linewidth]{secuencia/hu-03-consultar-disponibilidad}
  \nota{Fuente: elaboración propia.}
\end{figuraapa}
```

- `\incluirDiagrama` busca un **PDF** en `diagramas/generados/`, con ruta
  relativa y sin extensión.
- `\incluirImagen` se usa para PNG/JPG y requiere extensión.
- No reemplazar los PDF vectoriales por imágenes raster sin una razón
  justificada.

### Citas y bibliografía

- Agregar la entrada en `bibliografia/referencias.bib` con `year`.
- Usar `\textcite{clave}` o `\parencite{clave}`.
- No escribir “(Autor, año)” manualmente.
- Verificar que no aparezcan “s. f.” en el PDF.

## 8. Diagramas

### Diagramas del sistema turístico

- `diagramas/fuentes/uml/secuencia/`: 7 diagramas completos de las HU-03,
  HU-05, HU-06, HU-07, HU-09, HU-13 y HU-14.
- `diagramas/fuentes/uml/secuencia-light/`: versiones resumidas de esos 7.
- `diagramas/fuentes/uml/secuencia-comunes/`: 5 subflujos reutilizables.
- `diagramas/fuentes/uml/secuencia-fusionados/`: 2 variantes que combinan
  HU-03 + HU-05 y HU-07 + HU-13.
- `diagramas/fuentes/uml/procesos/mapa-procesos.puml`: mapa de actividades
  con carriles.

Los diagramas de secuencia deben conservar los estereotipos:

- `<<interfaz>>`
- `<<control>>`
- `<<entidad>>`
- `<<tabla>>`

Los diagramas comunes pueden omitir interfaz y actor porque son fragmentos
técnicos.

### Diagramas de ejemplo de la plantilla

Estos archivos son ejemplos heredados y **no representan el sistema
turístico**:

- `diagramas/fuentes/uml/casos-uso/general.puml`
- `diagramas/fuentes/uml/clases/modelo-dominio.puml`
- `diagramas/fuentes/uml/actividades/proceso-evaluacion.puml`
- `diagramas/fuentes/uml/despliegue/arquitectura.puml`
- `diagramas/fuentes/uml/secuencia/registrar-proyecto.puml`

No usarlos como base para el proyecto sin reemplazarlos por completo.

### Generación

Windows:

```powershell
.\build.ps1 -Diagramas
```

Linux:

```bash
make diagramas
```

Los PDF se generan en `diagramas/generados/<tipo>/`. No editar manualmente
esos PDF: se regeneran desde los `.puml`.

## 9. Base de datos temporal

Archivo: `codigo/base-datos/esquema-temporal.sql`.

- Motor: PostgreSQL 14 o superior.
- Esquema: `turismo`.
- Contiene 14 tablas, 3 vistas, restricciones, índices y una semilla de roles.
- Es temporal: se esperan cambios cuando avance el desarrollo.

Reglas importantes:

- El cupo disponible se calcula con `vista_disponibilidad_salida`; no se
  almacena un cupo duplicado.
- La validación de cupos se hace dentro de una transacción con
  `SELECT ... FOR UPDATE` sobre `salida`.
- La cancelación es lógica: la reserva pasa a `cancelada` y el cupo se libera
  por cálculo.
- Se permite un `anticipo` y un `saldo` por reserva.
- `historial_reserva` e `historial_salida` registran auditoría.
- Hay dos canales de ingreso: la atención del personal (`origen = 'personal'`)
  y la solicitud directa del cliente (`origen = 'web'`). Ambos siguen el
  mismo flujo: la reserva nace `pendiente` y la confirma el personal.
- Toda reserva pendiente tiene `fecha_expiracion` (48 horas por omisión). Si
  no se confirma a tiempo, pasa a `vencida` y libera el cupo de forma
  automática mediante `fn_vencer_solicitudes_pendientes()`.
- El índice único parcial `ux_reserva_solicitud_activa` admite una sola
  solicitud pendiente por cliente y salida.

Diccionario y reglas: `codigo/base-datos/diccionario-datos.md`.

## 10. Historias de usuario

- `tablas/historias-usuario.csv`: fuente tabular, UTF-8 con BOM y separador
  `;`.
- `tablas/historias-usuario.md`: versión legible, totales y observaciones.
- 14 historias, 38 puntos, 31 tareas.
- El orden actual comienza en HU-08 y no sigue el orden de los ID; se
  conservó porque parece reflejar priorización.
- Hay observaciones pendientes, por ejemplo el posible solapamiento entre
  HU-04 y HU-12.
- **No incluir estas historias en `main.tex`** sin una instrucción explícita.
- No corregir los datos del backlog sin que el usuario lo solicite.

## 11. Registro de cambios

Carpeta: `registro-cambios/`.

- `README.md` explica la convención.
- Cada iteración crea un archivo nuevo:
  `YYYY-MM-DDTHHMMSS_descripcion-breve.md`.
- No se editan registros anteriores.
- Cada registro debe incluir: fecha, alcance, formato, contenido, archivos
  modificados, validación y pendientes.
- Al crear un registro nuevo, agregarlo a la tabla de iteraciones del
  `README.md` de esa carpeta.

## 12. Compilación

### Windows

```powershell
.\build.ps1              # compila el informe
.\build.ps1 -Diagramas   # genera diagramas y compila
.\build.ps1 -Ver         # compila y muestra información del PDF
.\build.ps1 -Limpiar     # borra _build
```

### Linux

```bash
make            # diagramas + informe
make pdf        # solo informe
make diagramas  # solo diagramas
make ver        # información del PDF
make clean      # auxiliares
make distclean  # auxiliares + diagramas generados
```

- Usar **XeLaTeX** o **LuaLaTeX**. No usar `pdflatex`.
- La bibliografía usa **biber**, no BibTeX.
- El PDF final queda en `_build/main.pdf`.
- `_build/` y `diagramas/generados/` son salidas: no editarlas a mano.

### Avisos normales

- MiKTeX puede avisar que no encuentra Liberation Mono o DejaVu Sans Mono:
  está probando la cadena de respaldo antes de usar Consolas.
- Inkscape puede mostrar avisos sobre propiedades CSS: no afectan el PDF.
- Los avisos `Underfull \hbox` o `Overfull \hbox` son de maquetación y deben
  revisarse solo si afectan visiblemente el texto.

## 13. Checklist antes de terminar una tarea

1. Compilar con `.\build.ps1` o `make pdf`.
2. Confirmar que `_build/main.pdf` se genera.
3. Revisar que no haya referencias o citas indefinidas.
4. Confirmar que no aparezcan “s. f.”.
5. Buscar primeras personas del plural en los `.tex`.
6. Verificar que la agencia se llame Vizcacha Tours.
7. Revisar que las secciones 1 a 10 sigan a la izquierda y numeradas.
8. Revisar que referencias, glosario y anexos sigan centrados.
9. Revisar tablas, figuras y el árbol de problemas.
10. Registrar la iteración en `registro-cambios/` si hubo cambios de formato
    o contenido.

## 14. Cosas que no se deben hacer

- No editar `_build/` ni los PDF de `diagramas/generados/` a mano.
- No cambiar `si3apa7.cls` para corregir contenido; usarlo solo para formato
  global.
- No reintroducir dedicatoria, agradecimientos o abstract.
- No reintroducir la sección de variables.
- No cambiar el nombre de la agencia ni inventar otra.
- No escribir en primera persona del plural.
- No usar citas sin año.
- No poner las historias de usuario ni la base de datos dentro de `main.tex`
  sin instrucción.
- No reemplazar los diagramas PDF vectoriales por imágenes raster sin
  justificarlo.
- No borrar ni reescribir registros antiguos de `registro-cambios/`.

## 15. Documentos de referencia

- `README.md`: propósito, estructura general y uso de la plantilla.
- `GUIA-LATEX.md`: conceptos de LaTeX y edición del proyecto.
- `INSTALACION-WINDOWS.md`: instalación en Windows 11.
- `registro-cambios/README.md`: convención de la bitácora.
- `codigo/base-datos/diccionario-datos.md`: esquema y reglas de la base de
  datos.
- `tablas/historias-usuario.md`: backlog y observaciones.

Si una decisión de formato o contenido cambia, actualizar este archivo y
registrar la iteración correspondiente.
