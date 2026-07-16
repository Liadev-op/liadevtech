function Invoke-WPFSelectedCheckboxesUpdate ($type, $checkboxName) {
    $listName = switch -Regex ($checkboxName) {
        '^WPFInstall' { 'selectedApps' }
        '^WPFTweaks'  { 'selectedTweaks' }
        '^WPFToggle'  { 'selectedToggles' }
        '^WPFFeature' { 'selectedFeatures' }
        '^WPFAppx'    { 'selectedAppx' }
    }

    if ($type -eq "Add") {
        if (-not $sync.$listName.Contains($checkboxName)) {
            $sync.$listName.Add($checkboxName)
        }
    } else {
        $sync.$listName.Remove($checkboxName)
    }

    Update-WinUtilSelectionCounters -ListName $listName
}

function Update-WinUtilSelectionCounters {
    <#
    .SYNOPSIS
        Actualiza los contadores "(N)" en los botones de accion segun la seleccion actual.
    #>
    param([string]$ListName)

    $targets = switch ($ListName) {
        'selectedApps'   { @(@{Button = 'WPFInstall'; Base = 'Instalar seleccionadas'}, @{Button = 'WPFUninstall'; Base = 'Desinstalar seleccionadas'}) }
        'selectedTweaks' { @(@{Button = 'WPFTweaksbutton'; Base = 'Aplicar tweaks'}) }
        'selectedAppx'   { @(@{Button = 'WPFRemoveSelectedAppx'; Base = 'Quitar seleccionadas'}) }
        default          { @() }
    }

    if ($targets.Count -eq 0) { return }

    $count = $sync.$ListName.Count
    foreach ($target in $targets) {
        $button = $sync[$target.Button]
        if ($null -eq $button) { continue }
        $newContent = if ($count -gt 0) { "$($target.Base) ($count)" } else { $target.Base }
        try {
            $button.Dispatcher.Invoke([action]{ $button.Content = $newContent })
        } catch {
            # UI no disponible (modo CLI/preset): se ignora
        }
    }
}
