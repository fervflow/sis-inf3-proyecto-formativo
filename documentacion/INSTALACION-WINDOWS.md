# Instalación en Windows 11

Guía para un Windows 11 casi limpio. Todo se instala con **winget**; para
PlantUML se usa **Scoop** como segunda opción (winget no lo publica).

```
winget  →  MiKTeX · Git · VS Code · Java (Temurin) · Inkscape
Scoop   →  PlantUML
        ↓
.\build.ps1  →  entregables\Informe de Proyecto Formativo - ....pdf
```

Tiempo estimado: 20–30 minutos (la primera compilación descarga paquetes de
MiKTeX y puede tardar más).

---

## 0. Antes de empezar

- Windows 11 con `winget` disponible. Verifique en PowerShell:
  ```powershell
  winget --version
  ```
- Unos 3 GB libres.
- **Recomendación:** copie el proyecto en una ruta corta y sin espacios,
  fuera de OneDrive, por ejemplo:
  ```
  C:\UPDS\proyecto-formativo
  ```
  OneDrive puede bloquear archivos mientras LaTeX los escribe.
- Arial ya viene incluida en Windows, así que la fuente del informe
  funcionará sin instalar nada extra.

---

## 1. Instalación base con winget

Abra **PowerShell** y ejecute:

```powershell
winget install -e --id MiKTeX.MiKTeX
winget install -e --id Git.Git
winget install -e --id Microsoft.VisualStudioCode
winget install -e --id EclipseAdoptium.Temurin.21.JRE
winget install -e --id Inkscape.Inkscape
```

| Paquete | Para qué |
|---|---|
| `MiKTeX.MiKTeX` | XeLaTeX, biber y todos los paquetes LaTeX |
| `Git.Git` | Control de versiones y Git Bash (opcional) |
| `Microsoft.VisualStudioCode` | Editor con LaTeX Workshop y PlantUML |
| `EclipseAdoptium.Temurin.21.JRE` | Java, necesario para PlantUML |
| `Inkscape.Inkscape` | Convierte SVG a PDF con fuentes embebidas |

Opcional, solo si algún diagrama se queja de Graphviz:

```powershell
winget install -e --id Graphviz.Graphviz
```

**Cierre y vuelva a abrir PowerShell** para que se actualice el `PATH`.
Compruebe:

```powershell
xelatex --version
biber --version
java -version
inkscape --version
```

Si `xelatex` no aparece, abra **MiKTeX Console** y verifique que la opción
“Add MiKTeX to PATH” esté activa, o reinstale MiKTeX.

---

## 2. PlantUML

winget no tiene un paquete oficial de PlantUML. Elija una opción.

### Opción A — Scoop (recomendada)

Scoop es un gestor de paquetes para Windows; el paquete `plantuml` está en
su bucket `extras`.

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
irm get.scoop.sh | iex
scoop bucket add extras
scoop install extras/plantuml
plantuml -version
```

El comando `plantuml` queda disponible y usa el Java que ya instaló
Temurin. Con esta opción, `build.ps1` lo detecta automáticamente.

### Opción B — JAR manual (sin Scoop)

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\tools\plantuml" | Out-Null
Invoke-WebRequest `
  "https://sourceforge.net/projects/plantuml/files/plantuml.jar/download" `
  -OutFile "$env:USERPROFILE\tools\plantuml\plantuml.jar"
java -jar "$env:USERPROFILE\tools\plantuml\plantuml.jar" -version
```

Esta es la ruta que `build.ps1` usa por defecto:
`%USERPROFILE%\tools\plantuml\plantuml.jar`.

---

## 3. Configurar MiKTeX

1. Abra **MiKTeX Console**.
2. Vaya a **Settings**.
3. En *Package installation*, elija:
   **“Always install missing packages on the fly”** → **Yes**.

Esto permite que XeLaTeX descargue automáticamente `biblatex-apa`,
`babel-spanish`, `titlesec`, etc. la primera vez que compile.

Opcional, para actualizar el catálogo de paquetes:

```powershell
mpm --update-db
```

---

## 4. Extensiones de VS Code

```powershell
code --install-extension James-Yu.latex-workshop
code --install-extension jebbs.plantuml
```

Opcional, para la interfaz en español:

```powershell
code --install-extension ms-ceintl.vscode-language-pack-es
```

---

## 5. Ajustar el proyecto

Abra el proyecto en VS Code:

```powershell
cd C:\UPDS\proyecto-formativo
code .
```

Edite `.vscode/settings.json` y cambie la ruta de `plantuml.jar` por una de
estas (use barras normales `/`):

```json
"plantuml.jar": "C:/Users/TU_USUARIO/tools/plantuml/plantuml.jar"
```

o, si instaló PlantUML con Scoop:

```json
"plantuml.jar": "C:/Users/TU_USUARIO/scoop/apps/plantuml/current/plantuml.jar"
```

En VS Code puede usar la receta **“XeLaTeX + biber + XeLaTeX ×2”**, que no
depende de `latexmk`. Si `latexmk` funciona en su MiKTeX, use
**“latexmk (XeLaTeX)”**.

### Dónde está cada cosa

| Carpeta | Contenido |
|---|---|
| `informe/` | El contenido del documento: `capitulos/`, `finales/`, `preliminares/`, `anexos/`, `configuracion/`, `bibliografia/`, `figuras/` |
| `sistema/` | El sistema que se diseña: `diagramas/`, `base-de-datos/`, `historias-usuario/` |
| `documentacion/` | Las guías y la bitácora de cambios |
| `entregables/` | El PDF final y los PDF y PNG de los diagramas. No se versiona |
| `_build/` | Los archivos auxiliares del compilador. Se borra sola |

Las fuentes de los diagramas están en `sistema\diagramas\uml\` y los
generados salen en `entregables\diagramas\`.

---

## 6. Compilar

Desde PowerShell, en la carpeta del proyecto:

```powershell
.\build.ps1
```

| Comando | Qué hace |
|---|---|
| `.\build.ps1` | Compila y publica el PDF en `entregables\` |
| `.\build.ps1 -Diagramas` | Regenera los UML y luego compila |
| `.\build.ps1 -Png` | Exporta los diagramas a PNG en `entregables\diagramas\png\` |
| `.\build.ps1 -Ver` | Compila y muestra páginas, tamaño y fuentes |
| `.\build.ps1 -Limpiar` | Borra `_build` |
| `.\build.ps1 -LimpiarTodo` | Borra `_build` y los diagramas generados |

El script ejecuta: `xelatex → biber → xelatex → xelatex`, igual que el
`Makefile` en Linux. Al terminar copia el PDF a `entregables\` con el nombre
definitivo **Informe de Proyecto Formativo - Sistema de Gestión de Paquetes
Turísticos y Reservas.pdf**. Ese PDF intermedio queda en `_build\main.pdf`,
junto a los archivos auxiliares. La carpeta `entregables\` no se versiona: se
reconstruye con un solo `.\build.ps1`.

Si Windows bloquea la ejecución de scripts:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

o ejecute una vez:

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1
```

La primera compilación puede tardar varios minutos porque MiKTeX descarga
paquetes. Las siguientes son rápidas.

---

## 7. Problemas frecuentes

| Síntoma | Solución |
|---|---|
| `xelatex no se reconoce...` | Cierre y reabra PowerShell; revise el PATH en MiKTeX Console |
| MiKTeX pregunta si instalar paquetes | Responda **Install** o active la instalación automática |
| `biber no se reconoce` | Instale los componentes completos de MiKTeX o revise el PATH |
| `No se encontró PlantUML` | `scoop install extras/plantuml` o descargue el JAR (paso 2) |
| `java no se reconoce` | Reabra PowerShell; verifique `winget list Temurin` |
| `Inkscape no encontrado` | Use `-InkscapeRuta "C:\Program Files\Inkscape\bin\inkscape.exe"` |
| `No se puede cargar el archivo...` al compilar | Cierre el PDF abierto: Windows lo tiene bloqueado |
| El proyecto está en OneDrive y falla | Muévalo a `C:\UPDS\...` |
| Error de “execution policy” con Scoop | Ejecute el `Set-ExecutionPolicy` del paso 2 |
| `File 'biblatex-apa.sty' not found` | Active la instalación automática de MiKTeX y recompile |

---

## 8. Alternativa: WSL2

Si prefiere el mismo entorno que Linux (y usar `make` tal cual):

```powershell
wsl --install -d Ubuntu
```

Dentro de Ubuntu:

```bash
sudo apt update
sudo apt install -y texlive-full latexmk biber plantuml librsvg2-bin make
```

Luego copie el proyecto dentro de su carpeta personal de WSL
(`~/proyecto-formativo`, no en `/mnt/c`, que es más lento) y ejecute:

```bash
make
```

---

## 9. Verificación final

```powershell
xelatex --version     # XeTeX
biber --version       # biber
java -version         # Java 21
plantuml -version     # PlantUML
inkscape --version    # Inkscape
```

Y después:

```powershell
.\build.ps1 -Diagramas -Ver
```

Debe terminar con `Listo: ...\entregables\Informe de Proyecto Formativo -
....pdf` y mostrar las fuentes Arial embebidas.
