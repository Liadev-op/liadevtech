<#
.SYNOPSIS
    Compara la configuracion de Liadev Tech con la version actual de WinUtil
    (Chris Titus Tech) y reporta que cambio, sin modificar nada.

.DESCRIPTION
    Liadev Tech es un fork muy personalizado de WinUtil (traducido al espanol,
    con diseno propio y funciones quitadas), por lo que NO se puede hacer un merge
    automatico sin romper esas personalizaciones.

    Este script descarga los JSON de configuracion de WinUtil y los compara con los
    tuyos, mostrando:
      - Apps nuevas en WinUtil que vos todavia no tenes.
      - Apps donde WinUtil cambio el ID de winget o choco (posibles arreglos).
      - Tweaks nuevos en WinUtil que vos no tenes.

    Con ese reporte decidis a mano que conviene incorporar. Nada se modifica.

.EXAMPLE
    .\Sincronizar-Upstream.ps1
#>
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$baseUpstream = "https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/config"

function Get-JsonFromUrl($url) {
    try {
        return (Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 20).Content | ConvertFrom-Json
    } catch {
        Write-Host "No se pudo descargar $url" -ForegroundColor Red
        return $null
    }
}

function ConvertTo-Map($obj) {
    $map = @{}
    if ($null -ne $obj) {
        $obj.PSObject.Properties | ForEach-Object { $map[$_.Name] = $_.Value }
    }
    return $map
}

Write-Host "Descargando configuracion de WinUtil (upstream)..." -ForegroundColor Cyan
$upApps    = ConvertTo-Map (Get-JsonFromUrl "$baseUpstream/applications.json")
$upTweaks  = ConvertTo-Map (Get-JsonFromUrl "$baseUpstream/tweaks.json")

$miApps   = ConvertTo-Map (Get-Content ".\config\applications.json" -Raw | ConvertFrom-Json)
$miTweaks = ConvertTo-Map (Get-Content ".\config\tweaks.json" -Raw | ConvertFrom-Json)

# --- Apps nuevas en upstream ---
Write-Host "`n=== APPS NUEVAS en WinUtil (no las tenes) ===" -ForegroundColor Yellow
$nuevasApps = $upApps.Keys | Where-Object { -not $miApps.ContainsKey($_) } | Sort-Object
if ($nuevasApps) {
    foreach ($k in $nuevasApps) {
        Write-Host ("  {0,-24} {1}" -f $k, $upApps[$k].content) -ForegroundColor Gray
    }
    Write-Host "  ($($nuevasApps.Count) apps nuevas disponibles para agregar a config\applications.json)" -ForegroundColor DarkGray
} else {
    Write-Host "  Ninguna. Estas al dia." -ForegroundColor DarkGray
}

# --- Apps con ID cambiado (posibles arreglos de winget/choco) ---
Write-Host "`n=== APPS con ID CAMBIADO en WinUtil (posibles arreglos) ===" -ForegroundColor Yellow
$cambios = 0
foreach ($k in ($miApps.Keys | Sort-Object)) {
    if (-not $upApps.ContainsKey($k)) { continue }
    $mio = $miApps[$k]; $up = $upApps[$k]
    if ("$($mio.winget)" -ne "$($up.winget)") {
        Write-Host ("  {0,-24} winget: '{1}' -> '{2}'" -f $k, $mio.winget, $up.winget) -ForegroundColor Gray
        $cambios++
    }
    if ("$($mio.choco)" -ne "$($up.choco)") {
        Write-Host ("  {0,-24} choco:  '{1}' -> '{2}'" -f $k, $mio.choco, $up.choco) -ForegroundColor Gray
        $cambios++
    }
}
if ($cambios -eq 0) { Write-Host "  Ningun cambio de ID." -ForegroundColor DarkGray }

# --- Tweaks nuevos en upstream ---
Write-Host "`n=== TWEAKS NUEVOS en WinUtil (no los tenes) ===" -ForegroundColor Yellow
$nuevosTweaks = $upTweaks.Keys | Where-Object { -not $miTweaks.ContainsKey($_) } | Sort-Object
if ($nuevosTweaks) {
    foreach ($k in $nuevosTweaks) {
        Write-Host ("  {0,-32} {1}" -f $k, $upTweaks[$k].Content) -ForegroundColor Gray
    }
    Write-Host "  ($($nuevosTweaks.Count) tweaks nuevos; recorda traducir Content/Description si los agregas)" -ForegroundColor DarkGray
} else {
    Write-Host "  Ninguno. Estas al dia." -ForegroundColor DarkGray
}

Write-Host "`nReporte terminado. No se modifico ningun archivo." -ForegroundColor Green
Write-Host "Agrega a mano lo que quieras a los JSON en config\ y luego corre .\Publicar.ps1" -ForegroundColor Green
