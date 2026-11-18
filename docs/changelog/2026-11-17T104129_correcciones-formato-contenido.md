# Correcciones de formato y contenido

- **Fecha:** 17 de noviembre de 2026, 10:41 (hora local)
- **Documento:** `_build/main.pdf`
- **Páginas:** 19
- **Alcance:** formato general y correcciones de contenido de las secciones 1 a 10.

## Cambios de formato

- Los títulos de las secciones de contenido (1 a 10) son subtítulos
  izquierdos, en negrita y numerados, sin la palabra “Capítulo”.
- Las secciones de contenido ya no comienzan en una página nueva: el texto
  continúa en la misma hoja.
- Referencias, glosario y anexos conservan títulos centrados y comienzan en
  página nueva.
- Todos los párrafos tienen sangría de primera línea de 1,27 cm, incluido el
  primero después de cada título.
- El interlineado se cambió a 2.
- La alineación se cambió a justificada.
- El índice muestra la numeración con punto: `1. Introducción`,
  `2.1. Relación con sistemas similares`, etc.
- El resumen quedó centrado.
- Se retiraron del documento la dedicatoria, los agradecimientos y el
  abstract. Los archivos fuente se conservan como respaldo, pero ya no se
  incluyen en `main.tex`.
- El Anexo A quedó en una página horizontal con título centrado, figura y
  nota. El árbol se escaló al 85 % para que la nota permanezca en la misma
  página.
- La fuente monoespaciada usa la cadena de respaldo: Liberation Mono →
  DejaVu Sans Mono → Consolas → Courier New.

## Cambios de contenido

### Introducción

- Se eliminó el párrafo que planteaba el problema y el párrafo que proponía
  el sistema web.
- Se agregó el contexto general del turismo en Potosí y la evolución de las
  ventas hacia canales digitales.
- Se incorporó una comparación con Amadeus, Booking.com, Ezus y trabajos
  regionales.

### Antecedentes

- Se eliminó el subtítulo “Evolución de la gestión de reservas y paquetes
  turísticos”; el texto fluye de forma continua.
- Se reemplazaron las citas sin fecha por fuentes con año.
- Se eliminó el párrafo sobre la variable del proyecto.
- Se consolidó la relación con sistemas similares en tercera persona.
- Se reescribió el flujo de información de la agencia con un enfoque general
  sobre la información ofrecida y los canales de venta y reserva.

### Situación problemática y problema científico

- Se eliminó la oración final que justificaba estudiar primero el proceso.
- Se retiró la referencia a la Figura 1 del cuerpo; el árbol de problemas
  quedó únicamente en el Anexo A.
- El problema científico se reformuló sin mencionar la solución tecnológica y
  con la agencia identificada:
  “¿Cómo mejorar la consistencia del proceso de reservas de paquetes
  turísticos en Vizcacha Tours de la ciudad de Potosí durante la gestión
  2026?”.

### Objeto de estudio y campo de acción

- El objeto de estudio se definió como un sistema de información transaccional
  (TPS) orientado a la operación comercial.
- El campo de acción se concentró en el control de disponibilidad y la
  confirmación de reservas de Vizcacha Tours.

### Variables y objetivos

- Se eliminó la sección independiente de variables.
- La variable dependiente se integró en el problema científico y la variable
  independiente en el objetivo general.
- El objetivo general quedó como: “Desarrollar un sistema web de gestión de
  reservas que mejore la consistencia del proceso de venta y reserva de
  paquetes turísticos en Vizcacha Tours de la ciudad de Potosí”.
- En el objetivo específico 3 se reemplazó “desarrollar” por “Diseñar y
  elaborar los diferentes componentes de un sistema web…”.

### Población y muestra

- Se eliminó el tercer grupo de población y la mención a los proveedores.
- Se definió Vizcacha Tours como agencia de estudio.
- Se establecieron 8 trabajadores y 50 clientes durante el tercer trimestre
  de 2026, con una población total de 58 personas.
- Por ser una población menor o igual a 60, se aplicó un criterio censal.
- Se actualizó la Tabla 1 con la población, la muestra y el periodo.

### Alcances y límites

- Se eliminaron la mención al diseño de la base de datos y las herramientas
  técnicas.
- Se describieron las funcionalidades concretas del sistema.
- Se retiró la oración sobre la realización de pruebas.
- Se incorporó el registro de pagos en efectivo y la simulación de banca
  móvil o código QR, sin pasarelas bancarias reales.
- Se eliminó el párrafo sobre la dependencia del diagnóstico y se conservó la
  referencia a OWASP.

### Estilo general

- Se eliminaron las expresiones en primera persona del plural.
- Se usó “Vizcacha Tours” en el problema, objeto, campo de acción, objetivos,
  población, muestra, portada, resumen y árbol de problemas.
- Todas las referencias bibliográficas incluyen año de publicación o
  actualización; no quedan citas con “s. f.”.

## Archivos modificados

- `main.tex`
- `si3apa7.cls`
- `entornos-apa.sty`
- `capitulos/01-introduccion.tex`
- `capitulos/02-antecedentes.tex`
- `capitulos/03-situacion-problematica.tex`
- `capitulos/04-problema-cientifico.tex`
- `capitulos/05-objeto-estudio.tex`
- `capitulos/06-variables.tex` (sección retirada; archivo conservado como referencia)
- `capitulos/07-objetivos.tex`
- `capitulos/08-poblacion-muestra.tex`
- `capitulos/09-justificacion-social.tex`
- `capitulos/10-alcances-sistema.tex`
- `capitulos/11-limites-proyecto.tex`
- `preliminares/resumen.tex`
- `config/metadatos.tex`
- `bibliografia/referencias.bib`
- `anexos/A-arbol-problemas.tex`
- `diagramas/fuentes/tikz/arbol-problemas.tex`
- `finales/glosario.tex`
- `finales/anexos.tex`
- `README.md`
- `GUIA-LATEX.md`

## Validación

- `.\build.ps1` terminó correctamente.
- El PDF final tiene 19 páginas.
- El índice muestra las secciones 1 a 10 con numeración y punto.
- Referencias, glosario y anexos tienen títulos centrados.
- No se encontraron citas con “s. f.” en el texto extraído.
- No se encontraron expresiones en primera persona del plural en los archivos
  `.tex`.
- La Tabla 1 y el Anexo A se revisaron visualmente.

## Pendientes

- Revisar la redacción con el docente y ajustar el nivel de detalle de cada
  sección.
- Decidir si los diagramas de secuencia se incorporan al cuerpo o a los
  anexos.
- Verificar que la justificación sea la opción definitiva; APA recomienda
  alineación a la izquierda, pero con Arial la justificación se evaluó como
  visualmente aceptable.
