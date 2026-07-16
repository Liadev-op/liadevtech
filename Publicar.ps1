<#
.SYNOPSIS
    Compila, commitea, sube y publica una nueva version de Liadev Tech en GitHub.

.DESCRIPTION
    Automatiza el flujo de release:
      1. Compila liadevtech.ps1 con la fecha del dia (yy.MM.dd).
      2. Hace commit y push de los cambios pendientes.
      3. Crea un release en GitHub con el .ps1 compilado como asset.

    Requiere el CLI de GitHub (gh) autenticado: gh auth login

.PARAMETER Mensaje
    Mensaje del commit y notas del release. Si se omite, usa uno generico.

.EXAMPLE
    .\Publicar.ps1 -Mensaje "Agrego soporte para nuevas apps"
#>
param(
    [string]$Mensaje = "Actualizacion de Liadev Tech"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

# Resolver gh (puede no estar en el PATH si se instalo recien con winget)
$gh = (Get-Command gh -ErrorAction SilentlyContinue).Source
if (-not $gh) {
    $gh = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter gh.exe -ErrorAction SilentlyContinue |
          Select-Object -First 1 -ExpandProperty FullName
}
if (-not $gh) {
    Write-Host "No se encontro el CLI de GitHub (gh). Instalalo con: winget install GitHub.cli" -ForegroundColor Red
    return
}

# 1. Compilar
Write-Host "[1/4] Compilando..." -ForegroundColor Cyan
.\Compile.ps1
if (-not (Test-Path .\liadevtech.ps1)) {
    Write-Host "La compilacion no genero liadevtech.ps1" -ForegroundColor Red
    return
}

# Validar sintaxis del script generado antes de publicar
$errs = $null; $tokens = $null
[System.Management.Automation.Language.Parser]::ParseFile("$PWD\liadevtech.ps1", [ref]$tokens, [ref]$errs) | Out-Null
if ($errs.Count -gt 0) {
    Write-Host "El script compilado tiene $($errs.Count) error(es) de sintaxis. Se aborta la publicacion." -ForegroundColor Red
    $errs | Select-Object -First 5 | ForEach-Object { Write-Host "  $($_.Extent.StartLineNumber): $($_.Message)" -ForegroundColor Red }
    return
}

# 2. Commit + push
# git escribe informacion normal a stderr (avisos LF/CRLF, progreso de push).
# Con ErrorActionPreference=Stop eso abortaria el script, asi que lo bajamos a
# Continue mientras corremos git y volvemos a Stop despues.
Write-Host "[2/4] Commit y push..." -ForegroundColor Cyan
$prevEAP = $ErrorActionPreference
$ErrorActionPreference = "Continue"

git add -A 2>&1 | Out-Null
$hayCambios = (git status --porcelain 2>$null)
if ($hayCambios) {
    git commit -m $Mensaje 2>&1 | Out-Null
    git push 2>&1 | Out-Null
    $pushExit = $LASTEXITCODE
} else {
    Write-Host "  Sin cambios para commitear." -ForegroundColor DarkGray
    git push 2>&1 | Out-Null
    $pushExit = $LASTEXITCODE
}

$ErrorActionPreference = $prevEAP
if ($pushExit -ne 0) {
    Write-Host "  El push fallo (codigo $pushExit). Revisa tu conexion o autenticacion." -ForegroundColor Red
    return
}

# 3. Calcular version (misma logica que Compile.ps1)
$version = Get-Date -Format 'yy.MM.dd'
$tag = "v$version"

# Si el tag del dia ya existe, agregar un sufijo incremental (.1, .2, ...)
# Usamos salida JSON porque el formato de columnas de 'gh release list' no es estable.
$existentes = @(& $gh release list --limit 200 --json tagName --jq '.[].tagName' 2>$null)
if ($existentes -contains $tag) {
    $n = 1
    while ($existentes -contains "$tag.$n") { $n++ }
    $tag = "$tag.$n"
}

# 4. Crear release
Write-Host "[3/4] Creando release $tag..." -ForegroundColor Cyan
& $gh release create $tag liadevtech.ps1 --title "Liadev Tech $($tag.TrimStart('v'))" --notes $Mensaje

Write-Host "[4/4] Listo. Instalacion: irm https://github.com/Liadev-op/liadevtech/releases/latest/download/liadevtech.ps1 | iex" -ForegroundColor Green
