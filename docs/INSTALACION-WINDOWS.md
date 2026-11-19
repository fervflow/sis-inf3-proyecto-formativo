# Instalación en Windows 11

Guía para un Windows 11 casi limpio. Todo se instala con **winget**; para
PlantUML se usa **Scoop** o un JAR manual, porque winget no lo publica.

```text
winget  →  MiKTeX · Git · VS Code · Java (Temurin) · Inkscape
Scoop   →  PlantUML
        ↓
.\build.ps1  →  entregables\Informe de Proyecto Formativo - ....pdf
```

Tiempo estimado: 20–30 minutos. La primera compilación puede tardar más
porque MiKTeX descarga paquetes.

## 1. Antes de empezar

- Windows 11 con `winget` disponible:
  ```powershell
  winget --version
  ```
- Unos 3 GB libres.
- Copiar el proyecto a una ruta corta, sin espacios y fuera de OneDrive;
  por ejemplo, `C:\UPDS\proyecto-formativo`. OneDrive puede bloquear los
  archivos mientras LaTeX escribe.
- Arial ya viene en Windows, así que la fuente del informe funciona sin
  instalar nada extra.

## 2. Instalación base

```powershell
winget install -e --id MiKTeX.MiKTeX
winget install -e --id Git.Git
winget install -e --id Microsoft.VisualStudioCode
winget install -e --id EclipseAdoptium.Temurin.21.JRE
winget install -e --id Inkscape.Inkscape
```

| Paquete | Para qué |
|---|---|
| `MiKTeX.MiKTeX` | XeLaTeX, biber y los paquetes LaTeX |
| `Git.Git` | Control de versiones |
| `Microsoft.VisualStudioCode` | Editor con LaTeX Workshop y PlantUML |
| `EclipseAdoptium.Temurin.21.JRE` | Java, necesario para PlantUML |
| `Inkscape.Inkscape` | Convierte SVG a PDF con fuentes embebidas |

Si algún diagrama pide Graphviz:

```powershell
winget install -e --id Graphviz.Graphviz
```

Cerrar y volver a abrir PowerShell para actualizar el `PATH` y comprobar:

```powershell
xelatex --version
biber --version
java -version
inkscape --version
```

Si `xelatex` no aparece, revisar **MiKTeX Console** → opción “Add MiKTeX to
PATH”, o reinstalar MiKTeX.

## 3. PlantUML

### Opción A — Scoop (recomendada)

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
irm get.scoop.sh | iex
scoop bucket add extras
scoop install extras/plantuml
plantuml -version
```

El comando `plantuml` queda en el `PATH` y usa el Java de Temurin.
`build.ps1` lo detecta automáticamente.

### Opción B — JAR manual

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\tools\plantuml" | Out-Null
Invoke-WebRequest `
  "https://sourceforge.net/projects/plantuml/files/plantuml.jar/download" `
  -OutFile "$env:USERPROFILE\tools\plantuml\plantuml.jar"
java -jar "$env:USERPROFILE\tools\plantuml\plantuml.jar" -version
```

`build.ps1` usa esa ruta por omisión. Para otra ubicación, pasar
`-PlantUmlJar "C:\ruta\plantuml.jar"`.

## 4. Configurar MiKTeX

1. Abrir **MiKTeX Console** → **Settings**.
2. En *Package installation*, elegir
   **“Always install missing packages on the fly”** → **Yes**.

Así se descargan solos `biblatex-apa`, `babel-spanish`, `titlesec`, etc.
Para actualizar el catálogo: `mpm --update-db`.

## 5. Extensiones de VS Code

```powershell
code --install-extension James-Yu.latex-workshop
code --install-extension jebbs.plantuml
code --install-extension divisionseven.unified-kanban
```

La interfaz en español es opcional:

```powershell
code --install-extension ms-ceintl.vscode-language-pack-es
```

El proyecto **no necesita ajustes locales**. La vista previa de PlantUML
usa el JAR incluido en la extensión; si se quiere otro, se configura en los
ajustes de usuario de VS Code, no en `.vscode/settings.json`.

## 6. Carpetas del proyecto

| Carpeta | Contenido |
|---|---|
| `informe/` | `capitulos/`, `finales/`, `preliminares/`, `anexos/`, `configuracion/`, `bibliografia/`, `figuras/` |
| `sistema/` | `diagramas/`, `historias-usuario/`, `estimacion/` |
| `bd/` | `esquema.sql` y el diccionario de datos |
| `docs/` | Guías y bitácora |
| `web/` | La aplicación |
| `entregables/` | PDF final y diagramas generados; no se versiona |
| `_build/` | Auxiliares del compilador; se borra sola |

Las fuentes de los diagramas están en `sistema\diagramas\uml\` y los
generados salen en `entregables\diagramas\`.

## 7. Compilar

Desde PowerShell, en la carpeta del proyecto:

```powershell
.\build.ps1
```

| Comando | Qué hace |
|---|---|
| `.\build.ps1` | Compila y publica en `entregables\` |
| `.\build.ps1 -Diagramas` | Regenera los UML y compila |
| `.\build.ps1 -Png` | Exporta los diagramas a PNG |
| `.\build.ps1 -Ver` | Compila y muestra páginas, tamaño y fuentes |
| `.\build.ps1 -Limpiar` | Borra `_build` |
| `.\build.ps1 -LimpiarTodo` | Borra `_build` y los diagramas generados |

El script ejecuta `xelatex → biber → xelatex → xelatex` y copia el PDF a
`entregables\` con el nombre definitivo. Si Windows bloquea scripts:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

o ejecutar una vez:

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1
```

## 8. Problemas frecuentes

| Síntoma | Solución |
|---|---|
| `xelatex no se reconoce` | Cerrar y reabrir PowerShell; revisar el `PATH` en MiKTeX Console |
| MiKTeX pregunta si instalar paquetes | Responder **Install** o activar la instalación automática |
| `biber no se reconoce` | Instalar los componentes completos de MiKTeX o revisar el `PATH` |
| `No se encontró PlantUML` | `scoop install extras/plantuml` o descargar el JAR |
| `java no se reconoce` | Reabrir PowerShell; comprobar `winget list Temurin` |
| `Inkscape no encontrado` | Usar `-InkscapeRuta "C:\Program Files\Inkscape\bin\inkscape.exe"` |
| El PDF no se puede escribir | Cerrar el PDF abierto: Windows lo bloquea |
| El proyecto está en OneDrive y falla | Moverlo a una ruta local como `C:\UPDS\...` |
| Error de “execution policy” con Scoop | Ejecutar el `Set-ExecutionPolicy` del paso 3 |

## 9. Alternativa: WSL2

Para usar el mismo entorno que Linux y `make` tal cual:

```powershell
wsl --install -d Ubuntu
```

Dentro de Ubuntu:

```bash
sudo apt update
sudo apt install -y texlive-full latexmk biber plantuml librsvg2-bin make
```

Copiar el proyecto dentro de la carpeta personal de WSL (no en `/mnt/c`,
que es más lento) y ejecutar `make`.

## 10. Verificación final

```powershell
xelatex --version
biber --version
java -version
plantuml -version
inkscape --version
.\build.ps1 -Diagramas -Ver
```

Debe terminar con `Listo: ...\entregables\Informe de Proyecto Formativo -
....pdf` y mostrar las fuentes Arial embebidas.
