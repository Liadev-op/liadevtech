function Get-DaikinFile {
    <#
    .SYNOPSIS
        Busca un archivo dentro de la carpeta Daikin por patron (recursivo).
        Usa patrones y no nombres fijos para que los cambios de version no rompan nada.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Pattern
    )

    if ([string]::IsNullOrWhiteSpace($sync.daikinPath) -or -not (Test-Path $sync.daikinPath)) {
        return $null
    }

    return Get-ChildItem -Path $sync.daikinPath -Filter $Pattern -Recurse -File -ErrorAction SilentlyContinue |
           Sort-Object LastWriteTime -Descending |
           Select-Object -First 1
}

function Show-DaikinPathError {
    $msg = "No se encontro la carpeta de instaladores Daikin.`n`n" +
           "Ruta buscada:`n$($sync.daikinPath)`n`n" +
           "Copia ahi la carpeta Daikin (con Halcyon, CrowdStrike, Tanium y Zscaler), " +
           "o define la variable de entorno LIADEV_DAIKIN_PATH apuntando al recurso de red."
    [System.Windows.MessageBox]::Show($msg, "Liadev Tech - Daikin", "OK", "Warning") | Out-Null
}

function Invoke-DaikinAgent {
    <#
    .SYNOPSIS
        Ejecuta el instalador o el chequeo de estado de un agente corporativo de Daikin.

    .DESCRIPTION
        Los instaladores NO se distribuyen con la app: se leen de la carpeta indicada por
        $sync.daikinPath (por defecto, la carpeta 'Daikin' junto al script, o la ruta de red
        definida en la variable de entorno LIADEV_DAIKIN_PATH).

        La app ya corre como administrador, asi que los procesos hijos heredan la elevacion.

    .PARAMETER Agent
        El agente a instalar o verificar.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Halcyon", "CrowdStrike", "Tanium", "Zscaler", "CrowdStrikeStatus", "TaniumStatus", "OpenFolder")]
        [string]$Agent
    )

    if ([string]::IsNullOrWhiteSpace($sync.daikinPath) -or -not (Test-Path $sync.daikinPath)) {
        Show-DaikinPathError
        return
    }

    switch ($Agent) {

        "Halcyon" {
            # Halcyon pide la clave de forma interactiva: la copiamos al portapapeles
            # para pegarla, en vez de exponerla en la linea de comandos o en el log.
            $installer = Get-DaikinFile -Pattern "Halcyon*Setup*.exe"
            if (-not $installer) {
                [System.Windows.MessageBox]::Show("No se encontro el instalador de Halcyon (Halcyon*Setup*.exe) en $($sync.daikinPath).", "Liadev Tech - Daikin", "OK", "Warning") | Out-Null
                return
            }

            $tokenFile = Get-DaikinFile -Pattern "token.txt"
            $token = $null
            if ($tokenFile) {
                $token = (Get-Content -Path $tokenFile.FullName -Raw -ErrorAction SilentlyContinue).Trim()
            }

            if ($token) {
                try { Set-Clipboard -Value $token } catch { }
                $preview = if ($token.Length -gt 8) { "$($token.Substring(0,4))...$($token.Substring($token.Length-4))" } else { "(oculta)" }
                Write-WinUtilLog -Component "Daikin" -Message "Halcyon: instalador lanzado, clave copiada al portapapeles ($preview)"
                [System.Windows.MessageBox]::Show(
                    "La clave de Halcyon se copio al portapapeles.`n`nPegala (Ctrl+V) cuando el instalador la pida.`n`nClave: $preview",
                    "Liadev Tech - Halcyon", "OK", "Information") | Out-Null
            } else {
                Write-WinUtilLog -Level "WARN" -Component "Daikin" -Message "Halcyon: no se encontro token.txt"
                [System.Windows.MessageBox]::Show(
                    "No se encontro token.txt junto al instalador.`n`nVas a tener que ingresar la clave de Halcyon a mano.",
                    "Liadev Tech - Halcyon", "OK", "Warning") | Out-Null
            }

            Set-WinUtilProgressbar -Label "Instalando Halcyon Anti-Ransomware..." -Percent 50
            Start-Process -FilePath $installer.FullName
        }

        "CrowdStrike" {
            # El .vbe es un wrapper cifrado (VBScript.Encode) que ya trae el CID y llama al sensor.
            $vbe = Get-DaikinFile -Pattern "CrowdStrike*inst*.vbe"
            if (-not $vbe) {
                [System.Windows.MessageBox]::Show("No se encontro el script de CrowdStrike (CrowdStrike*inst*.vbe) en $($sync.daikinPath).", "Liadev Tech - Daikin", "OK", "Warning") | Out-Null
                return
            }
            Write-WinUtilLog -Component "Daikin" -Message "CrowdStrike: ejecutando $($vbe.Name)"
            Set-WinUtilProgressbar -Label "Instalando CrowdStrike Falcon (puede tardar varios minutos)..." -Percent 50
            Start-Process -FilePath "wscript.exe" -ArgumentList "`"$($vbe.FullName)`"" -WorkingDirectory $vbe.DirectoryName
        }

        "Tanium" {
            # El .vbe es un wrapper cifrado que usa inst\SetupClient.exe + tanium-init.dat.
            $vbe = Get-DaikinFile -Pattern "Tanium*inst*.vbe"
            if (-not $vbe) {
                [System.Windows.MessageBox]::Show("No se encontro el script de Tanium (Tanium*inst*.vbe) en $($sync.daikinPath).", "Liadev Tech - Daikin", "OK", "Warning") | Out-Null
                return
            }
            Write-WinUtilLog -Component "Daikin" -Message "Tanium: ejecutando $($vbe.Name)"
            Set-WinUtilProgressbar -Label "Instalando Tanium Client..." -Percent 50
            Start-Process -FilePath "wscript.exe" -ArgumentList "`"$($vbe.FullName)`"" -WorkingDirectory $vbe.DirectoryName
        }

        "Zscaler" {
            $installer = Get-DaikinFile -Pattern "Zscaler*installer*.exe"
            if (-not $installer) {
                [System.Windows.MessageBox]::Show("No se encontro el instalador de Zscaler (Zscaler*installer*.exe) en $($sync.daikinPath).", "Liadev Tech - Daikin", "OK", "Warning") | Out-Null
                return
            }
            Write-WinUtilLog -Component "Daikin" -Message "Zscaler: ejecutando $($installer.Name)"
            Set-WinUtilProgressbar -Label "Instalando Zscaler Client Connector..." -Percent 50
            Start-Process -FilePath $installer.FullName
        }

        "CrowdStrikeStatus" {
            $svc = Get-Service -Name "csagent" -ErrorAction SilentlyContinue
            if ($svc) {
                $estado = "CrowdStrike Falcon (csagent)`n`nEstado: $($svc.Status)`nInicio: $($svc.StartType)"
                [System.Windows.MessageBox]::Show($estado, "Liadev Tech - Estado de CrowdStrike", "OK", "Information") | Out-Null
            } else {
                [System.Windows.MessageBox]::Show("El servicio csagent no existe: CrowdStrike Falcon no esta instalado.", "Liadev Tech - Estado de CrowdStrike", "OK", "Warning") | Out-Null
            }
        }

        "TaniumStatus" {
            $svc = Get-Service -Name "Tanium Client" -ErrorAction SilentlyContinue
            if (-not $svc) {
                [System.Windows.MessageBox]::Show("El servicio Tanium Client no existe: Tanium no esta instalado.", "Liadev Tech - Estado de Tanium", "OK", "Warning") | Out-Null
                return
            }

            $estado = "Tanium Client`n`nEstado: $($svc.Status)`nInicio: $($svc.StartType)"

            # Ultima conexion con Tanium Cloud
            $regPath = "HKLM:\SOFTWARE\WOW6432Node\Tanium\Tanium Client\Status"
            $lastReg = (Get-ItemProperty -Path $regPath -Name "LastRegistrationTime" -ErrorAction SilentlyContinue).LastRegistrationTime
            if ($lastReg) {
                $estado += "`nUltima conexion: $lastReg (UTC)"
            } else {
                $estado += "`nUltima conexion: sin registro (no conecto al cloud)"
            }

            $icono = if ($svc.Status -eq "Running" -and $lastReg) { "Information" } else { "Warning" }
            [System.Windows.MessageBox]::Show($estado, "Liadev Tech - Estado de Tanium", "OK", $icono) | Out-Null
        }

        "OpenFolder" {
            Start-Process explorer.exe -ArgumentList $sync.daikinPath
        }
    }
}
