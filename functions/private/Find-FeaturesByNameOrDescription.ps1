function Find-FeaturesByNameOrDescription {
    <#
        .SYNOPSIS
            Filtra las entradas de la pestana Configuracion (features, reparaciones, paneles)
            ocultando las que no coinciden con el texto de busqueda.

        .DESCRIPTION
            Recorre el featurespanel (mismo layout que tweakspanel: Border > DockPanel >
            ItemsControl). Muestra u oculta banners de categoria (Border), botones (Button)
            y checkboxes (DockPanel con CheckBox + Label). Coincidencia literal, sin comodines.
            Un banner de categoria solo se muestra si al menos una de sus entradas coincide.

        .PARAMETER SearchString
            Texto a buscar. Los comodines se tratan como caracteres literales.
    #>
    param(
        [Parameter(Mandatory = $false)]
        [string]$SearchString = ""
    )

    if ($null -eq $Sync) {
        $Sync = $global:sync
        if ($null -eq $Sync) { $Sync = $script:sync }
    }
    if ($null -eq $Sync -or $null -eq $Sync.Form) { return }

    $panel = $null
    try { $panel = $Sync.Form.FindName("featurespanel") } catch { return }
    if ($null -eq $panel) { return }

    $term = $SearchString
    if ($null -eq $term) { $term = "" }
    $term = $term.Trim()

    try {
        foreach ($categoryBorder in $panel.Children) {
            if ($categoryBorder -isnot [Windows.Controls.Border]) { continue }
            $dockPanel = $categoryBorder.Child
            if ($dockPanel -isnot [Windows.Controls.DockPanel]) { continue }

            $itemsControl = $dockPanel.Children | Where-Object { $_ -is [Windows.Controls.ItemsControl] } | Select-Object -First 1
            if ($null -eq $itemsControl) { continue }

            $currentBanner = $null
            $bannerHasMatch = $false

            foreach ($item in $itemsControl.Items) {
                if ($null -eq $item) { continue }

                # Banner de categoria (Border con Label adentro)
                if ($item -is [Windows.Controls.Border]) {
                    # Aplicar el resultado del banner anterior antes de pasar al siguiente
                    if ($null -ne $currentBanner) {
                        $currentBanner.Visibility = if ($bannerHasMatch -or $term -eq "") { "Visible" } else { "Collapsed" }
                    }
                    $currentBanner = $item
                    $bannerHasMatch = $false
                    continue
                }

                # Determinar el texto de la entrada segun su tipo de contenedor
                $text = ""
                if ($item -is [Windows.Controls.Button]) {
                    # Boton (reparaciones, paneles, ISO/activacion)
                    $text = [string]$item.Content
                } elseif ($item -is [Windows.Controls.StackPanel]) {
                    # Checkbox de caracteristica (CheckBox dentro de un StackPanel horizontal)
                    $checkbox = $item.Children | Where-Object { $_ -is [Windows.Controls.CheckBox] } | Select-Object -First 1
                    if ($null -ne $checkbox) {
                        $text = "$([string]$checkbox.Content) $([string]$checkbox.ToolTip)"
                    }
                } elseif ($item -is [Windows.Controls.DockPanel]) {
                    # Toggle (CheckBox + Label en un DockPanel)
                    $label = $item.Children | Where-Object { $_ -is [Windows.Controls.Label] } | Select-Object -First 1
                    if ($null -ne $label) {
                        $text = "$([string]$label.Content) $([string]$label.ToolTip)"
                    }
                } else {
                    continue
                }

                $matches = ($term -eq "") -or ($text.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase) -ge 0)
                $item.Visibility = if ($matches) { "Visible" } else { "Collapsed" }
                if ($matches) { $bannerHasMatch = $true }
            }

            # Aplicar el resultado del ultimo banner de la categoria
            if ($null -ne $currentBanner) {
                $currentBanner.Visibility = if ($bannerHasMatch -or $term -eq "") { "Visible" } else { "Collapsed" }
            }
        }
    } catch {
        $null = $_
    }
}
