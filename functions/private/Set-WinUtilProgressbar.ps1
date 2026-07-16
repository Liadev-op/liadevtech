function Set-WinUtilProgressbar{
    <#
    .SYNOPSIS
        Actualiza la barra de progreso del overlay de instalacion y la barra de estado inferior.
        Se oculta automaticamente si el usuario hace clic y no hay ningun proceso corriendo.
    .PARAMETER Label
        El texto a mostrar sobre la barra de progreso y en la barra de estado
    .PARAMETER PERCENT
        Porcentaje de llenado de la barra (0-100)
    #>
    param(
        [string]$Label,
        [ValidateRange(0,100)]
        [int]$Percent
    )

    $progressLabel = $Label
    $statusPercent = $Percent

    Invoke-WPFUIThread -ScriptBlock {$sync.progressBarTextBlock.Text = $progressLabel}
    Invoke-WPFUIThread -ScriptBlock {$sync.progressBarTextBlock.ToolTip = $progressLabel}
    if ($Percent -lt 5 ) {
        $Percent = 5 # Ensure the progress bar is not empty, as it looks weird
    }
    Invoke-WPFUIThread -ScriptBlock { $sync.ProgressBar.Value = $Percent}

    # Barra de estado inferior (Liadev Tech)
    Invoke-WPFUIThread -ScriptBlock {
        if ($sync.StatusBarText) {
            $sync.StatusBarText.Text = if ([string]::IsNullOrWhiteSpace($progressLabel)) { "Listo" } else { $progressLabel }
        }
        if ($sync.StatusBarProgress) {
            if ([string]::IsNullOrWhiteSpace($progressLabel) -or $statusPercent -ge 100) {
                $sync.StatusBarProgress.Visibility = "Collapsed"
            } else {
                $sync.StatusBarProgress.Visibility = "Visible"
            }
            $sync.StatusBarProgress.Value = $statusPercent
        }
    }
}
