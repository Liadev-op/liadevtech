Function Install-WinUtilProgramWinget {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Install", "Uninstall")]
        [string]$Action,

        [Parameter(Mandatory=$true)]
        [string[]]$Programs
    )

    # Exit codes de winget que no son fallos reales de instalacion:
    # 0 = OK, -1978335189 = sin actualizacion aplicable, -1978335135 = ya instalado
    $successExitCodes = @(0, -1978335189, -1978335135)
    $failedPrograms = [System.Collections.Generic.List[string]]::new()

    $validPrograms = @($Programs | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and $_ -ne "na" })
    $actionLabel = if ($Action -eq 'Install') { "Instalando" } else { "Desinstalando" }
    $current = 0

    foreach ($program in $Programs) {
        if ([string]::IsNullOrWhiteSpace($program) -or $program -eq "na") {
            continue
        }

        $current++
        try {
            Set-WinUtilProgressbar -Label "$actionLabel $program ($current de $($validPrograms.Count))" -Percent ([int](($current - 1) * 100 / [Math]::Max($validPrograms.Count, 1)))
        } catch {}

        $originalProgram = $program
        $source = "winget"
        if ($program.StartsWith("msstore:", [System.StringComparison]::OrdinalIgnoreCase)) {
            $source = "msstore"
            $program = $program.Substring("msstore:".Length)
        }

        if ($Action -eq 'Install') {
            $arguments = @("install", "--id", $program, "--accept-package-agreements", "--accept-source-agreements", "--source", $source, "--silent")
        } else {
            $arguments = @("uninstall", "--id", $program, "--source", $source, "--silent")
        }

        Write-WinUtilLog -Component "Package" -Message "$Action winget package: $program (source: $source)"
        $process = Start-Process -FilePath winget -ArgumentList $arguments -NoNewWindow -Wait -PassThru
        Write-WinUtilLog -Component "Package" -Message "$Action winget package completed: $program (exit code: $($process.ExitCode))"

        if ($Action -eq 'Install' -and $process.ExitCode -notin $successExitCodes) {
            $failedPrograms.Add($originalProgram)
        }
    }

    return ,$failedPrograms
}
