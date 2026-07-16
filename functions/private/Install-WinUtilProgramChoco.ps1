function Install-WinUtilProgramChoco {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Install", "Uninstall")]
        [string]$Action,

        [Parameter(Mandatory=$true)]
        [string[]]$Programs
    )

    if ($Action -eq 'Install') {
        $arguments = "install $Programs -y"
        try { Set-WinUtilProgressbar -Label "Instalando con Chocolatey: $($Programs -join ', ')" -Percent 50 } catch {}
    } else {
        $arguments = "uninstall $Programs -y"
        try { Set-WinUtilProgressbar -Label "Desinstalando con Chocolatey: $($Programs -join ', ')" -Percent 50 } catch {}
    }

    Write-WinUtilLog -Component "Package" -Message "$Action choco package(s): $($Programs -join ', ')"
    $process = Start-Process -FilePath choco -ArgumentList $arguments -NoNewWindow -Wait -PassThru
    Write-WinUtilLog -Component "Package" -Message "$Action choco package(s) completed: $($Programs -join ', ') (exit code: $($process.ExitCode))"
}
