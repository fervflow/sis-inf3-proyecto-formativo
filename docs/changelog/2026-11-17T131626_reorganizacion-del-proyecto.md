# Reorganización del proyecto

- **Fecha:** 17 de noviembre de 2026, 13:16 (hora local)
- **Documento:** `entregables/Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf`
- **Páginas:** 21 (sin cambios)
- **Alcance:** reagrupación de la estructura de carpetas del repositorio,
  publicación del PDF final en una carpeta aislada y sacada del control de
  versiones, y cambio de la regla del registro de cambios.

## Antecedente

La revisión del proyecto mostrou tres problemas de estructura:

1. **El PDF final estaba atrapado en la carpeta de compilación.** `_build/`
   contenía el entregable junto a quince archivos auxiliares, con el nombre
   `main.pdf`, que no indica qué es, y en una carpeta ignorada por git: un
   clon nuevo no tenía nada que entregar. Además, aparecía citado en nueve
   lugares de cinco archivos.
2. **La raíz mezclaba cuatro cosas distintas.** Veinticuatro entradas, con
   los fragmentos del documento LaTeX junto al material del sistema, la
   documentación y las herramientas, sin que se distinguiera a simple vista
   qué era LaTeX y qué no.
3. **`diagramas/` mezclaba fuentes y artefactos.** Las fuentes sumaban 48 KB
   y los artefactos, 19 MB, en el mismo árbol, de modo que no se distinguía
   lo que se edita de lo que se regenera.

## Cambios de contenido

No hubo cambios en el contenido del informe. El texto, la maquetación, las
citas y el número de páginas son los mismos.

## Cambios de estructura

### Raíz del proyecto

De 24 entradas a 8 archivos y 5 carpetas:

```text
proyecto-formativo/
├── main.tex · si3apa7.cls · entornos-apa.sty · latexmkrc
├── Makefile · build.ps1 · README.md · AGENTS.md
├── informe/          El contenido del documento
├── sistema/          El sistema que se diseña
├── documentacion/    Guías y bitácora
├── entregables/      Lo que se entrega
└── _build/           Solo auxiliares de compilación
```

### Mapa de movimientos

Todos los movimientos se hicieron con `git mv`, de modo que el historial de
cada archivo se conserva.

| Anterior | Nuevo |
|---|---|
| `config/` | `informe/configuracion/` |
| `preliminares/` | `informe/preliminares/` |
| `capitulos/` | `informe/capitulos/` |
| `finales/` | `informe/finales/` |
| `anexos/` | `informe/anexos/` |
| `bibliografia/` | `informe/bibliografia/` |
| `imagenes/logos/`, `imagenes/capturas/` | `informe/figuras/logos/`, `informe/figuras/capturas/` |
| `diagramas/fuentes/uml/{secuencia,secuencia-light,secuencia-comunes,secuencia-fusionados,procesos}` | `sistema/diagramas/uml/…` |
| `diagramas/fuentes/tikz/` | `sistema/diagramas/tikz/` |
| `diagramas/estilos/` | `sistema/diagramas/estilos/` |
| `diagramas/otros/` | `sistema/diagramas/otros/` |
| `diagramas/fuentes/uml/{actividades,casos-uso,clases,despliegue}/` y `secuencia/registrar-proyecto.puml` | `sistema/diagramas/ejemplos-plantilla/` |
| `diagramas/verificar-uml.py` | `sistema/verificar-uml.py` |
| `codigo/base-datos/` | `sistema/base-de-datos/` |
| `tablas/` | `sistema/historias-usuario/` |
| `GUIA-LATEX.md`, `INSTALACION-WINDOWS.md` | `documentacion/` |
| `registro-cambios/` | `documentacion/registro-cambios/` |
| `diagramas/generados/` (salida) | `entregables/diagramas/pdf/` (salida) |
| `diagramas/png/` (salida) | `entregables/diagramas/png/` (salida) |

### Limpieza

- Se eliminaron las seis carpetas vacías que la plantilla preveía para tipos
  de diagrama que el proyecto no usa: `componentes/`, `comunicacion/`,
  `estados/`, `objetos/`, `paquetes/` y `tiempo/`.
- Se eliminaron dos `.gitkeep` redundantes, en `codigo/` y `tablas/`, que ya
  contenían archivos.
- Los cinco ejemplos heredados de la plantilla quedaron en
  `sistema/diagramas/ejemplos-plantilla/`, con un nombre que los identifica
  y ya no se exportan a PDF ni a PNG, porque no forman parte de los
  entregables.

### El PDF final

- `make` y `build.ps1` publican el PDF compilado en `entregables/` con el
  nombre **Informe de Proyecto Formativo - Sistema de Gestión de Paquetes
  Turísticos y Reservas.pdf**.
- Es una copia y no un enlace simbólico, para que sobreviva al traslado de
  la carpeta, al envío por correo y a los permisos de Windows.
- El objetivo `make publicar` permite republicarlo sin recompilar.
- El PDF intermedio continúa en `_build/main.pdf`, junto a los auxiliares.

### Control de versiones

- `entregables/` quedó completa en `.gitignore`: el PDF oficial, los PDF de
  los diagramas y los PNG son material generado y se reconstruyen con un
  solo `make`. Se descartó la opción de versionar el PDF oficial, que
  obligaría a registrar un binario en cada commit.

## Cambios de proceso

### Regla del registro de cambios

El registro se escribe **una vez que el usuario acepta el trabajo**, no al
cerrar cada iteración técnica. Un trabajo aceptado genera un solo registro;
las correcciones anteriores a la aceptación se quedan en el árbol de
trabajo. La regla quedó escrita en `AGENTS.md` (sección 11) y en el
`README.md` de la bitácora.

En aplicación de esa regla, se fusionaron en uno los dos registros que
habían separado la exportación a PNG y la corrección de los diagramas, y se
eliminó la entrada duplicada.

## Archivos modificados

### Con cambio de ubicación

68 archivos renombrados, entre ellos las 11 secciones del informe, los 5
fragmentos de la bitácora, las 22 fuentes de diagramas del proyecto, el
esquema de base de datos, el backlog de historias de usuario y las dos guías.

### Con cambio de contenido

- `main.tex`: doce rutas `\input` con el prefijo `informe/`.
- `informe/configuracion/metadatos.tex`: `\addbibresource` con la ruta
  nueva.
- `informe/configuracion/portada.tex`: ruta del logotipo y del mensaje de
  aviso.
- `informe/finales/anexos.tex`: `\input` del anexo A.
- `informe/anexos/A-arbol-problemas.tex`: `\input` del árbol de problemas.
- `si3apa7.cls`: `\graphicspath` con las rutas nuevas.
- `entornos-apa.sty`: `\incluirDiagrama` busca en `entregables/diagramas/pdf/`.
- `Makefile`: rutas de búsqueda y de salida, publicación del entregable y
  nuevo objetivo `publicar`.
- `build.ps1`: rutas, publicación del entregable y función
  `Publicar-Entregable`.
- `.vscode/settings.json`: carpeta de salida de PlantUML.
- `.gitignore`: `entregables/` completo.
- `README.md`, `AGENTS.md`, `documentacion/GUIA-LATEX.md` y
  `documentacion/INSTALACION-WINDOWS.md`: mapa del proyecto, rutas y reglas.

### Nuevos

- `sistema/verificar-uml.py` ya existía; solo cambió de ubicación.

## Validación

- `make clean` seguido de `make pdf` terminó correctamente: 21 páginas,
  sin errores de compilación.
- Con `_build/` y `entregables/` borrados, `make pdf` recreó las carpetas y
  generó el PDF final, 22 PDF de diagramas y 23 PNG.
- El contenido del informe es idéntico: 5 382 palabras, mismo índice, mismas
  secciones y mismo número de páginas.
- Se revisó visualmente la portada institucional con el logotipo.
- La portada muestra el logotipo UPDS en su lugar, lo que confirma la ruta
  nueva de la imagen.
- No hay avisos de caja `Overfull` ni `Underfull`, ni citas sin definir, ni
  apariciones de «s. f.» ni de primera persona del plural.
- Un comprobador de rutas revisó los 20 `\input`, `\addbibresource` e
  `\includegraphics` del proyecto: ninguno apunta a un archivo inexistente.
  Ese comprobador detectó un `\input` olvidado en `informe/finales/anexos.tex`,
  que habría roto la compilación.
- `make verificar` revisó los 22 diagramas y terminó con cero problemas.
- `git check-ignore` confirma que `entregables/` está excluido, y
  `git status --untracked-files=all` no lista ningún archivo suyo.
- El script de PowerShell se validó de forma estática: balance de llaves,
  paréntesis y corchetes, funciones definidas y llamadas, y parámetros
  declarados y usados.

## Pendientes

- Verificar `build.ps1 -Png` y `build.ps1` en un equipo con Windows,
  PowerShell 5.1 o superior e Inkscape instalado.
- Ejecutar el esquema SQL en un servidor PostgreSQL, que en este equipo no
  está disponible.
- Revisar el documento con el docente y ajustar el nivel de detalle de cada
  sección.
