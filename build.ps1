#requires -Version 5.1
<#
.SYNOPSIS
    Compila el informe LaTeX en Windows sin necesidad de make.

.DESCRIPTION
    Ejecuta la cadena XeLaTeX -> Biber -> XeLaTeX (x2), y opcionalmente
    convierte los diagramas PlantUML (.puml) a PDF usando Inkscape.

.EXAMPLE
    .\build.ps1
    Compila el PDF en _build\main.pdf.

.EXAMPLE
    .\build.ps1 -Diagramas
    Regenera los diagramas y luego compila.

.EXAMPLE
    .\build.ps1 -Ver
    Compila y muestra páginas, tamaño y fuentes del PDF.

.EXAMPLE
    .\build.ps1 -Limpiar
    Borra la carpeta _build.

.EXAMPLE
    .\build.ps1 -LimpiarTodo
    Borra _build y los PDF generados de los diagramas.
#>
[CmdletBinding()]
param(
    [switch]$Diagramas,
    [switch]$Ver,
    [switch]$Limpiar,
    [switch]$LimpiarTodo,

    # Ruta al plantuml.jar si no usa el comando "plantuml" de Scoop.
    [string]$PlantUmlJar = "",

    # Ruta a inkscape.exe si no está en el PATH.
    [string]$InkscapeRuta = ""
)

$ErrorActionPreference = "Stop"

$Raiz         = $PSScriptRoot
$Compilacion  = Join-Path $Raiz "_build"
$Principal    = "main"
$TemaPuml     = Join-Path $Raiz "diagramas/estilos/tema-apa.puml"
$FuentesUml   = Join-Path $Raiz "diagramas/fuentes/uml"
$Generados    = Join-Path $Raiz "diagramas/generados"

if (-not $PlantUmlJar) {
    $perfil = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
    $PlantUmlJar = [System.IO.Path]::Combine($perfil, "tools", "plantuml", "plantuml.jar")
}

Set-Location $Raiz

function Paso([string]$mensaje) {
    Write-Host ">> $mensaje" -ForegroundColor Cyan
}

function ErrorFatal([string]$mensaje) {
    Write-Host "ERROR: $mensaje" -ForegroundColor Red
    exit 1
}

function Limpiar-Salida {
    if (Test-Path $Compilacion) {
        Remove-Item $Compilacion -Recurse -Force
        Paso "Carpeta _build eliminada."
    }
    if ($LimpiarTodo -and (Test-Path $Generados)) {
        Get-ChildItem $Generados -Recurse -Filter *.pdf -File |
            Remove-Item -Force
        Paso "Diagramas generados eliminados."
    }
}

function Convertir-Diagramas {
    if (-not (Test-Path $FuentesUml)) {
        ErrorFatal "No existe la carpeta $FuentesUml"
    }

    # --- Motor PlantUML: comando "plantuml" (Scoop) o java -jar ---------
    $pumlExe  = $null
    $pumlArgs = @()

    $comandoPuml = Get-Command plantuml -ErrorAction SilentlyContinue
    if ($comandoPuml) {
        $pumlExe = $comandoPuml.Source
    }
    elseif (Test-Path $PlantUmlJar) {
        $java = Get-Command java -ErrorAction SilentlyContinue
        if (-not $java) {
            ErrorFatal "Java no encontrado. Instale Eclipse Temurin JRE 21 o agregue java al PATH."
        }
        $pumlExe  = $java.Source
        $pumlArgs = @("-jar", $PlantUmlJar)
    }
    else {
        ErrorFatal ("No se encontró PlantUML. Use 'scoop install extras/plantuml' " +
                    "o descargue plantuml.jar en $PlantUmlJar")
    }

    # --- Inkscape (opcional, para fuentes embebidas) -------------------
    $inkscape = $null
    if ($InkscapeRuta) {
        if (-not (Test-Path $InkscapeRuta)) {
            ErrorFatal "No existe la ruta de Inkscape indicada: $InkscapeRuta"
        }
        $inkscape = $InkscapeRuta
    }
    elseif (Get-Command inkscape -ErrorAction SilentlyContinue) {
        $inkscape = (Get-Command inkscape).Source
    }
    elseif (Test-Path "C:\Program Files\Inkscape\bin\inkscape.exe") {
        $inkscape = "C:\Program Files\Inkscape\bin\inkscape.exe"
    }

    $archivos = Get-ChildItem $FuentesUml -Filter *.puml -Recurse -File
    if (-not $archivos) {
        Paso "No hay archivos .puml para convertir."
        return
    }

    foreach ($archivo in $archivos) {
        $relativa   = $archivo.FullName.Substring($FuentesUml.Length).TrimStart('\', '/')
        $subcarpeta = Split-Path $relativa -Parent
        $destino    = if ($subcarpeta) { Join-Path $Generados $subcarpeta } else { $Generados }

        New-Item -ItemType Directory -Force -Path $destino | Out-Null
        Paso "Diagrama: $relativa"

        if ($inkscape) {
            & $pumlExe @pumlArgs -tsvg -charset UTF-8 -config $TemaPuml -o $destino $archivo.FullName
            if ($LASTEXITCODE -ne 0) {
                ErrorFatal "PlantUML falló al procesar $relativa"
            }

            $svg = Join-Path $destino ($archivo.BaseName + ".svg")
            $pdf = Join-Path $destino ($archivo.BaseName + ".pdf")

            & $inkscape $svg --export-type=pdf "--export-filename=$pdf" | Out-Null
            if ($LASTEXITCODE -ne 0) {
                ErrorFatal "Inkscape falló al convertir $svg"
            }
            Remove-Item $svg -Force -ErrorAction SilentlyContinue
        }
        else {
            & $pumlExe @pumlArgs -tpdf -charset UTF-8 -config $TemaPuml -o $destino $archivo.FullName
            if ($LASTEXITCODE -ne 0) {
                ErrorFatal "PlantUML falló al procesar $relativa"
            }
        }
    }

    if (-not $inkscape) {
        Write-Host ("AVISO: Inkscape no encontrado. Los PDF se generaron de forma " +
                    "directa y podrían no tener las fuentes embebidas.") -ForegroundColor Yellow
    }
}

function Invoke-XeLaTeX {
    & xelatex -interaction=nonstopmode -halt-on-error -file-line-error `
        "-output-directory=$Compilacion" "$Principal.tex"
    if ($LASTEXITCODE -ne 0) {
        ErrorFatal "XeLaTeX falló. Revise $Compilacion\main.log"
    }
}

function Compilar-Informe {
    if (-not (Test-Path $Compilacion)) {
        New-Item -ItemType Directory -Force -Path $Compilacion | Out-Null
    }

    if (-not (Get-Command xelatex -ErrorAction SilentlyContinue)) {
        ErrorFatal "xelatex no está en el PATH. Abra una terminal nueva o revise la instalación de MiKTeX."
    }

    Paso "XeLaTeX (1.ª pasada)"
    Invoke-XeLaTeX

    $bcf = Join-Path $Compilacion "$Principal.bcf"
    if (Test-Path $bcf) {
        if (-not (Get-Command biber -ErrorAction SilentlyContinue)) {
            ErrorFatal "biber no está en el PATH. Instale MiKTeX completo o agregue biber."
        }
        Paso "Biber"
        & biber (Join-Path $Compilacion $Principal)
        if ($LASTEXITCODE -ne 0) {
            ErrorFatal "Biber falló. Revise $Compilacion\main.blg"
        }
    }

    Paso "XeLaTeX (2.ª pasada)"
    Invoke-XeLaTeX

    Paso "XeLaTeX (3.ª pasada)"
    Invoke-XeLaTeX
}

function Mostrar-Verificacion {
    $pdf = Join-Path $Compilacion "$Principal.pdf"
    if (-not (Test-Path $pdf)) {
        ErrorFatal "No existe el PDF: $pdf"
    }

    $info = Get-Item $pdf
    Paso "PDF generado: $($info.FullName)"
    Write-Host ("Tamaño: {0:N0} KB" -f ($info.Length / 1KB))

    if (Get-Command pdfinfo -ErrorAction SilentlyContinue) {
        & pdfinfo $pdf | Select-String "Pages|Page size"
    }
    else {
        Write-Host "Sugerencia: instale Poppler para ver páginas y fuentes (opcional)."
    }

    if (Get-Command pdffonts -ErrorAction SilentlyContinue) {
        Write-Host "--- Fuentes ---"
        & pdffonts $pdf
    }
}

# ---------------------------------------------------------------------------
# Flujo principal
# ---------------------------------------------------------------------------
if ($Limpiar -or $LimpiarTodo) {
    Limpiar-Salida
    if (-not $Diagramas -and -not $Ver) { exit 0 }
}

if ($Diagramas) {
    Convertir-Diagramas
}

Compilar-Informe

if ($Ver) {
    Mostrar-Verificacion
}

Paso "Listo: $Compilacion\$Principal.pdf"
