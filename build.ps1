#requires -Version 5.1
<#
.SYNOPSIS
    Compila el informe LaTeX en Windows sin necesidad de make.

.DESCRIPTION
    Ejecuta la cadena XeLaTeX -> Biber -> XeLaTeX (x2), y opcionalmente
    convierte los diagramas PlantUML (.puml) a PDF usando Inkscape.
    Al terminar, copia el PDF a entregables\ con el nombre definitivo.

.EXAMPLE
    .\build.ps1
    Compila el informe y publica el entregable.

.EXAMPLE
    .\build.ps1 -Diagramas
    Regenera los diagramas y luego compila.

.EXAMPLE
    .\build.ps1 -Png
    Exporta los diagramas a PNG en entregables\diagramas\png\ y compila.

.EXAMPLE
    .\build.ps1 -Estimacion
    Compila la hoja de resumen de la estimación de dos páginas.

.EXAMPLE
    .\build.ps1 -EstimacionScrum
    Compila la hoja de resumen de una página con metodología Scrum.

.EXAMPLE
    .\build.ps1 -Ver
    Compila y muestra páginas, tamaño y fuentes del PDF.

.EXAMPLE
    .\build.ps1 -Limpiar
    Borra la carpeta _build.

.EXAMPLE
    .\build.ps1 -LimpiarTodo
    Borra _build y los diagramas generados.
#>
[CmdletBinding()]
param(
    [switch]$Diagramas,
    [switch]$Png,
    [switch]$Estimacion,
    [switch]$EstimacionScrum,
    [switch]$Ver,
    [switch]$Limpiar,
    [switch]$LimpiarTodo,

    # Ruta al plantuml.jar si no usa el comando "plantuml" de Scoop.
    [string]$PlantUmlJar = "",

    # Ruta a inkscape.exe si no está en el PATH.
    [string]$InkscapeRuta = "",

    # Resolución de los PNG exportados, en DPI.
    [int]$Dpi = 300
)

$ErrorActionPreference = "Stop"

$Raiz         = $PSScriptRoot
$Compilacion  = Join-Path $Raiz "_build"
$Principal    = "main"
$TemaPuml     = Join-Path $Raiz "sistema/diagramas/estilos/tema-apa.puml"
$FuentesUml   = Join-Path $Raiz "sistema/diagramas/uml"
$Generados    = Join-Path $Raiz "entregables/diagramas/pdf"
$GeneradosPng = Join-Path $Raiz "entregables/diagramas/png"
$FuentesTikz  = Join-Path $Raiz "sistema/diagramas/tikz"
$Entregas     = Join-Path $Raiz "entregables"
$PdfEntrega   = Join-Path $Entregas "Informe de Proyecto Formativo - Sistema de Gestión de Paquetes Turísticos y Reservas.pdf"

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
        Remove-Item $Generados -Recurse -Force
        Paso "PDF de diagramas eliminados."
    }
    if ($LimpiarTodo -and (Test-Path $GeneradosPng)) {
        Remove-Item $GeneradosPng -Recurse -Force
        Paso "PNG de diagramas eliminados."
    }
}

function Publicar-Entregable {
    # Copia el PDF compilado a entregables/ con el nombre definitivo.
    $pdf = Join-Path $Compilacion "$Principal.pdf"
    if (-not (Test-Path $pdf)) {
        ErrorFatal "No existe el PDF compilado: $pdf"
    }
    New-Item -ItemType Directory -Force -Path $Entregas | Out-Null
    Copy-Item $pdf $PdfEntrega -Force
    Paso "Entregable: $PdfEntrega"
}

function Obtener-MotorPlantUml {
    $comandoPuml = Get-Command plantuml -ErrorAction SilentlyContinue
    if ($comandoPuml) {
        return @{ Exe = $comandoPuml.Source; Args = @() }
    }
    if (Test-Path $PlantUmlJar) {
        $java = Get-Command java -ErrorAction SilentlyContinue
        if (-not $java) {
            ErrorFatal "Java no encontrado. Instale Eclipse Temurin JRE 21 o agregue java al PATH."
        }
        return @{ Exe = $java.Source; Args = @("-jar", $PlantUmlJar) }
    }
    ErrorFatal ("No se encontró PlantUML. Use 'scoop install extras/plantuml' " +
                "o descargue plantuml.jar en $PlantUmlJar")
}

function Obtener-Inkscape {
    if ($InkscapeRuta) {
        if (-not (Test-Path $InkscapeRuta)) {
            ErrorFatal "No existe la ruta de Inkscape indicada: $InkscapeRuta"
        }
        return $InkscapeRuta
    }
    if (Get-Command inkscape -ErrorAction SilentlyContinue) {
        return (Get-Command inkscape).Source
    }
    if (Test-Path "C:\Program Files\Inkscape\bin\inkscape.exe") {
        return "C:\Program Files\Inkscape\bin\inkscape.exe"
    }
    return $null
}

function Convertir-Diagramas {
    if (-not (Test-Path $FuentesUml)) {
        ErrorFatal "No existe la carpeta $FuentesUml"
    }

    $motor = Obtener-MotorPlantUml
    $pumlExe  = $motor.Exe
    $pumlArgs = $motor.Args
    $inkscape = Obtener-Inkscape

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

function Convertir-DiagramasPng {
    # Copia rasterizada de cada diagrama, para revision rapida.
    # Material derivado: no se versiona.
    if (-not (Test-Path $FuentesUml)) {
        ErrorFatal "No existe la carpeta $FuentesUml"
    }

    $motor = Obtener-MotorPlantUml
    $pumlExe  = $motor.Exe
    $pumlArgs = $motor.Args
    $inkscape = Obtener-Inkscape

    New-Item -ItemType Directory -Force -Path $GeneradosPng | Out-Null

    $archivos = Get-ChildItem $FuentesUml -Filter *.puml -Recurse -File
    foreach ($archivo in $archivos) {
        $relativa   = $archivo.FullName.Substring($FuentesUml.Length).TrimStart('\', '/')
        $subcarpeta = Split-Path $relativa -Parent
        $destino    = if ($subcarpeta) { Join-Path $GeneradosPng $subcarpeta } else { $GeneradosPng }

        New-Item -ItemType Directory -Force -Path $destino | Out-Null
        Paso "PNG: $relativa"

        if ($inkscape) {
            & $pumlExe @pumlArgs -tsvg -charset UTF-8 -config $TemaPuml -o $destino $archivo.FullName
            if ($LASTEXITCODE -ne 0) {
                ErrorFatal "PlantUML falló al procesar $relativa"
            }

            $svg = Join-Path $destino ($archivo.BaseName + ".svg")
            $png = Join-Path $destino ($archivo.BaseName + ".png")

            & $inkscape $svg --export-type=png "--export-filename=$png" "--export-dpi=$Dpi" "--export-background=white" "--export-background-opacity=1" | Out-Null
            if ($LASTEXITCODE -ne 0) {
                ErrorFatal "Inkscape falló al convertir $svg"
            }
            Remove-Item $svg -Force -ErrorAction SilentlyContinue
        }
        else {
            & $pumlExe @pumlArgs -tpng -charset UTF-8 -config $TemaPuml -o $destino $archivo.FullName
            if ($LASTEXITCODE -ne 0) {
                ErrorFatal "PlantUML falló al procesar $relativa"
            }
        }
    }

    # El arbol de problemas es TikZ, no PlantUML: se compila aparte.
    $arbolTikz = Join-Path $FuentesTikz "arbol-problemas.tex"
    if (Test-Path $arbolTikz) {
        $carpetaTikz = Join-Path $Compilacion "tikz"
        New-Item -ItemType Directory -Force -Path $carpetaTikz | Out-Null

        $contenidoTikz = @(
            '\documentclass[tikz,border=6pt]{standalone}',
            '\usepackage{tikz}',
            '\usetikzlibrary{arrows.meta,positioning,calc}',
            '\begin{document}',
            "\input{$arbolTikz}",
            '\end{document}'
        ) -join "`n"

        $wrapper = Join-Path $carpetaTikz "arbol.tex"
        # ASCII para evitar la marca BOM que Windows PowerShell 5.1 escribe
        # con -Encoding UTF8 y que LaTeX no admite al inicio del archivo.
        Set-Content -Path $wrapper -Value $contenidoTikz -Encoding ASCII

        if (-not (Get-Command xelatex -ErrorAction SilentlyContinue)) {
            Write-Host ("AVISO: xelatex no encontrado. Se omite el arbol de problemas.") -ForegroundColor Yellow
        }
        else {
            Paso "PNG: arbol-problemas"
            & xelatex -interaction=nonstopmode -halt-on-error "-output-directory=$carpetaTikz" $wrapper | Out-Null
            if ($LASTEXITCODE -ne 0) {
                ErrorFatal "XeLaTeX falló al compilar el árbol de problemas."
            }

            $pdfTikz = Join-Path $carpetaTikz "arbol.pdf"
            $pngTikz = Join-Path $GeneradosPng "arbol-problemas.png"

            if ($inkscape) {
                & $inkscape $pdfTikz --export-type=png "--export-filename=$pngTikz" "--export-dpi=$Dpi" "--export-background=white" "--export-background-opacity=1" | Out-Null
            }
            elseif (Get-Command magick -ErrorAction SilentlyContinue) {
                & magick -density $Dpi $pdfTikz $pngTikz
            }
            else {
                Write-Host ("AVISO: no se encontró Inkscape ni ImageMagick. " +
                            "Se omite el PNG del árbol de problemas.") -ForegroundColor Yellow
            }
        }
    }

    Paso "PNG generados en $GeneradosPng ($Dpi DPI, fondo blanco). No se versionan."
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

function Compilar-Estimacion {
    if (-not (Get-Command xelatex -ErrorAction SilentlyContinue)) {
        ErrorFatal "xelatex no está en el PATH. Abra una terminal nueva o revise la instalación de MiKTeX."
    }

    $carpeta = Join-Path $Compilacion "estimacion"
    if (-not (Test-Path $carpeta)) {
        New-Item -ItemType Directory -Force -Path $carpeta | Out-Null
    }

    Paso "XeLaTeX (hoja de resumen de la estimación)"
    & xelatex -interaction=nonstopmode -halt-on-error -file-line-error `
        "-output-directory=$carpeta" `
        (Join-Path $Raiz "sistema/estimacion/resumen-estimacion.tex")
    if ($LASTEXITCODE -ne 0) {
        ErrorFatal "XeLaTeX falló. Revise $carpeta\resumen-estimacion.log"
    }

    $destino = Join-Path $Raiz "entregables/Estimacion de esfuerzo y costo.pdf"
    New-Item -ItemType Directory -Force -Path (Split-Path $destino) | Out-Null
    Copy-Item (Join-Path $carpeta "resumen-estimacion.pdf") $destino -Force
    Paso "Hoja de resumen: $destino"
}

function Compilar-EstimacionScrum {
    if (-not (Get-Command xelatex -ErrorAction SilentlyContinue)) {
        ErrorFatal "xelatex no está en el PATH. Abra una terminal nueva o revise la instalación de MiKTeX."
    }

    $carpeta = Join-Path $Compilacion "estimacion/scrum"
    if (-not (Test-Path $carpeta)) {
        New-Item -ItemType Directory -Force -Path $carpeta | Out-Null
    }

    Paso "XeLaTeX (hoja de resumen con metodología Scrum)"
    & xelatex -interaction=nonstopmode -halt-on-error -file-line-error `
        "-output-directory=$carpeta" `
        (Join-Path $Raiz "sistema/estimacion/scrum/resumen-scrum.tex")
    if ($LASTEXITCODE -ne 0) {
        ErrorFatal "XeLaTeX falló. Revise $carpeta\resumen-scrum.log"
    }

    $destino = Join-Path $Raiz "entregables/Estimacion Scrum de esfuerzo y costo.pdf"
    New-Item -ItemType Directory -Force -Path (Split-Path $destino) | Out-Null
    Copy-Item (Join-Path $carpeta "resumen-scrum.pdf") $destino -Force
    Paso "Hoja de resumen (Scrum): $destino"
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

    Write-Host ("Entregable: {0}" -f $PdfEntrega)
}

# ---------------------------------------------------------------------------
# Flujo principal
# ---------------------------------------------------------------------------
if ($Limpiar -or $LimpiarTodo) {
    Limpiar-Salida
    if (-not $Diagramas -and -not $Png -and -not $Ver) { exit 0 }
}

if ($Diagramas) {
    Convertir-Diagramas
}

if ($Png) {
    Convertir-DiagramasPng
}

Compilar-Informe

Publicar-Entregable

if ($Estimacion) {
    Compilar-Estimacion
}

if ($EstimacionScrum) {
    Compilar-EstimacionScrum
}

if ($Ver) {
    Mostrar-Verificacion
}

Paso "Listo: $PdfEntrega"
