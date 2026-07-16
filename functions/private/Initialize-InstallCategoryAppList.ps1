function Initialize-InstallCategoryAppList {
    <#
        .SYNOPSIS
            Clears the Target Element and sets up a "Loading" message. This is done, because loading of all apps can take a bit of time in some scenarios
            Iterates through all Categories and Apps and adds them to the UI
            Used to as part of the Install Tab UI generation
        .PARAMETER TargetElement
            The Element into which the Categories and Apps should be placed
        .PARAMETER Apps
            The Hashtable of Apps to be added to the UI
            The Categories are also extracted from the Apps Hashtable

    #>
        param(
            $TargetElement,
            $Apps
        )

        # Pre-group apps by category before creating WPF controls.
        $appsByCategory = @{}
        foreach ($appKey in $Apps.Keys) {
            $category = $Apps.$appKey.Category
            if (-not $appsByCategory.ContainsKey($category)) {
                $appsByCategory[$category] = @()
            }
            $appsByCategory[$category] += $appKey
        }
        $sync.InstallAppRenderQueue = [System.Collections.Queue]::new()

        foreach ($category in $($appsByCategory.Keys | Sort-Object)) {
            # Create a container for category label + apps
            $categoryContainer = New-Object Windows.Controls.StackPanel
            $categoryContainer.Orientation = "Vertical"
            $categoryContainer.Margin = New-Object Windows.Thickness(0, 0, 0, 0)
            $categoryContainer.HorizontalAlignment = [Windows.HorizontalAlignment]::Stretch
            [System.Windows.Automation.AutomationProperties]::SetName($categoryContainer, $Category)

            # Bind Width to the ItemsControl's ActualWidth to force full-row layout in WrapPanel
            $binding = New-Object Windows.Data.Binding
            $binding.Path = New-Object Windows.PropertyPath("ActualWidth")
            $binding.RelativeSource = New-Object Windows.Data.RelativeSource([Windows.Data.RelativeSourceMode]::FindAncestor, [Windows.Controls.ItemsControl], 1)
            [void][Windows.Data.BindingOperations]::SetBinding($categoryContainer, [Windows.FrameworkElement]::WidthProperty, $binding)

            # Encabezado de categoria estilo Liadev Tech: banner azul redondeado y colapsable
            $toggleButton = New-Object Windows.Controls.Border
            $toggleButton.SetResourceReference([Windows.Controls.Border]::BackgroundProperty, "GroupBorderBackgroundColor")
            $toggleButton.CornerRadius = New-Object Windows.CornerRadius(8)
            $toggleButton.Margin = New-Object Windows.Thickness(4, 10, 4, 6)
            $toggleButton.Padding = New-Object Windows.Thickness(10, 4, 12, 5)
            $toggleButton.Cursor = [System.Windows.Input.Cursors]::Hand
            $toggleButton.HorizontalAlignment = [Windows.HorizontalAlignment]::Stretch
            $sync.$Category = $toggleButton

            $headerDock = New-Object Windows.Controls.DockPanel
            $headerDock.LastChildFill = $true
            $headerDock.Background = [Windows.Media.Brushes]::Transparent

            # Chevron a la derecha (Segoe MDL2): 0xE70D = abierto, 0xE70E = cerrado
            $chevron = New-Object Windows.Controls.TextBlock
            $chevron.Text = [char]0xE70D
            $chevron.FontFamily = New-Object Windows.Media.FontFamily("Segoe MDL2 Assets")
            $chevron.FontSize = 12
            $chevron.Foreground = [Windows.Media.Brushes]::White
            $chevron.VerticalAlignment = "Center"
            $chevron.Background = [Windows.Media.Brushes]::Transparent
            [Windows.Controls.DockPanel]::SetDock($chevron, [Windows.Controls.Dock]::Right)
            $null = $headerDock.Children.Add($chevron)

            $headerText = New-Object Windows.Controls.TextBlock
            $headerText.Text = $Category
            $headerText.Foreground = [Windows.Media.Brushes]::White
            $headerText.FontWeight = [Windows.FontWeights]::SemiBold
            $headerText.Background = [Windows.Media.Brushes]::Transparent
            $headerText.VerticalAlignment = "Center"
            $headerText.SetResourceReference([Windows.Controls.TextBlock]::FontSizeProperty, "HeaderFontSize")
            $null = $headerDock.Children.Add($headerText)

            $toggleButton.Child = $headerDock

            # Guardar el chevron para poder cambiarlo al colapsar
            $toggleButton.Tag = $chevron

            # Click: alternar visibilidad del WrapPanel de apps
            $toggleButton.Add_MouseLeftButtonUp({
                param($categoryToggle)
                $categoryContainer = $categoryToggle.Parent
                if ($categoryContainer -and $categoryContainer.Children.Count -ge 2) {
                    $wrapPanel = $categoryContainer.Children[1]
                    $chevronTb = $categoryToggle.Tag
                    if ($wrapPanel.Visibility -eq [Windows.Visibility]::Visible) {
                        $wrapPanel.Visibility = [Windows.Visibility]::Collapsed
                        if ($chevronTb) { $chevronTb.Text = [char]0xE70E }
                    } else {
                        $wrapPanel.Visibility = [Windows.Visibility]::Visible
                        if ($chevronTb) { $chevronTb.Text = [char]0xE70D }
                    }
                }
            })

            $null = $categoryContainer.Children.Add($toggleButton)

            # Add wrap panel for apps to container
            $wrapPanel = New-Object Windows.Controls.WrapPanel
            $wrapPanel.Orientation = "Horizontal"
            $wrapPanel.HorizontalAlignment = "Left"
            $wrapPanel.VerticalAlignment = "Top"
            $wrapPanel.Margin = New-Object Windows.Thickness(0, 0, 0, 0)
            $wrapPanel.Visibility = [Windows.Visibility]::Visible
            $wrapPanel.Tag = "CategoryWrapPanel_$category"

            $null = $categoryContainer.Children.Add($wrapPanel)

            # Add the entire category container to the target element
            $null = $TargetElement.Items.Add($categoryContainer)

            $sync.InstallAppRenderQueue.Enqueue([pscustomobject]@{
                Category = $category
                TargetElement = $wrapPanel
                AppKeys = @($appsByCategory[$category] | Sort-Object)
            })
        }

        Start-WinUtilInstallAppRendering
    }
