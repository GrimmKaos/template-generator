<#
    MOCKUP 2: Left-side navigation list for the 3 sections.
    CLICK-THROUGH MOCKUP ONLY - dummy data, no real template engine yet.
#>

Add-Type -AssemblyName PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Template Generator - Mockup 2 (Left Nav)" Height="560" Width="780"
        WindowStartupLocation="CenterScreen">
    <Grid Margin="10">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="160"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <ListBox Name="NavList" Grid.Column="0" Margin="0,0,10,0" FontSize="14">
            <ListBoxItem Content="Tickets" Name="Nav_Tickets"/>
            <ListBoxItem Content="Deferrals" Name="Nav_Deferrals"/>
            <ListBoxItem Content="Requests" Name="Nav_Requests"/>
        </ListBox>

        <Grid Name="ContentArea" Grid.Column="1"/>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# ---------- Dummy data ----------
$TicketTemplates    = @("Password Reset", "Software Install Request", "Hardware Issue")
$DeferralTemplatesSingle  = @("Single Device - Standard Deferral", "Single Device - Extended Deferral")
$DeferralTemplatesMulti   = @("Multiple Device - Bulk Deferral", "Multiple Device - Department Deferral")
$RequestTemplatesSingle   = @("Single Device - New Equipment", "Single Device - Replacement")
$RequestTemplatesMulti    = @("Multiple Device - Bulk Order", "Multiple Device - Department Refresh")

function New-WizardPanel {
    param(
        [string]$SectionName,
        [bool]$HasDeviceCountStep
    )

    $panel = New-Object System.Windows.Controls.Grid
    $panel.Margin = "10"
    $row0 = New-Object System.Windows.Controls.RowDefinition; $row0.Height = "Auto"
    $row1 = New-Object System.Windows.Controls.RowDefinition; $row1.Height = "*"
    $row2 = New-Object System.Windows.Controls.RowDefinition; $row2.Height = "Auto"
    $panel.RowDefinitions.Add($row0)
    $panel.RowDefinitions.Add($row1)
    $panel.RowDefinitions.Add($row2)

    $stepLabel = New-Object System.Windows.Controls.TextBlock
    $stepLabel.FontWeight = "Bold"
    $stepLabel.FontSize = 14
    $stepLabel.Margin = "0,0,0,10"
    [System.Windows.Controls.Grid]::SetRow($stepLabel, 0)
    $panel.Children.Add($stepLabel) | Out-Null

    $contentHost = New-Object System.Windows.Controls.Grid
    [System.Windows.Controls.Grid]::SetRow($contentHost, 1)
    $panel.Children.Add($contentHost) | Out-Null

    $btnPanel = New-Object System.Windows.Controls.StackPanel
    $btnPanel.Orientation = "Horizontal"
    $btnPanel.HorizontalAlignment = "Right"
    [System.Windows.Controls.Grid]::SetRow($btnPanel, 2)

    $backBtn = New-Object System.Windows.Controls.Button
    $backBtn.Content = "< Back"; $backBtn.Width = 90; $backBtn.Margin = "0,10,10,0"

    $nextBtn = New-Object System.Windows.Controls.Button
    $nextBtn.Content = "Next >"; $nextBtn.Width = 90; $nextBtn.Margin = "0,10,0,0"

    $btnPanel.Children.Add($backBtn) | Out-Null
    $btnPanel.Children.Add($nextBtn) | Out-Null
    $panel.Children.Add($btnPanel) | Out-Null

    $state = [pscustomobject][ordered]@{
        Step = 0
        HasDeviceCountStep = $HasDeviceCountStep
        DeviceChoice = $null
        SelectedTemplate = $null
    }

    $buildStepContent = {
        param($stepIndex)
        $contentHost.Children.Clear()
        $effectiveStep = $stepIndex
        if (-not $state.HasDeviceCountStep) { $effectiveStep = $stepIndex + 1 }

        switch ($effectiveStep) {
            0 {
                $stepLabel.Text = "$SectionName - Step 1: Choose Device Count"
                $sp = New-Object System.Windows.Controls.StackPanel
                $rb1 = New-Object System.Windows.Controls.RadioButton
                $rb1.Content = "Single Device"; $rb1.GroupName = "DeviceCount"; $rb1.Margin = "0,5,0,5"
                $rb1.IsChecked = ($state.DeviceChoice -eq "Single")
                $rb1.Add_Checked({ $state.DeviceChoice = "Single" }.GetNewClosure())
                $rb2 = New-Object System.Windows.Controls.RadioButton
                $rb2.Content = "Multiple Devices"; $rb2.GroupName = "DeviceCount"; $rb2.Margin = "0,5,0,5"
                $rb2.IsChecked = ($state.DeviceChoice -eq "Multiple")
                $rb2.Add_Checked({ $state.DeviceChoice = "Multiple" }.GetNewClosure())
                $sp.Children.Add($rb1) | Out-Null
                $sp.Children.Add($rb2) | Out-Null
                $contentHost.Children.Add($sp) | Out-Null
            }
            1 {
                $stepLabel.Text = "$SectionName - Step 2: Choose Template"
                $sp = New-Object System.Windows.Controls.StackPanel
                $list = New-Object System.Windows.Controls.ListBox
                $list.Height = 200
                $templates = switch ($SectionName) {
                    "Tickets"   { $script:TicketTemplates }
                    "Deferrals" { if ($state.DeviceChoice -eq "Multiple") { $script:DeferralTemplatesMulti } else { $script:DeferralTemplatesSingle } }
                    "Requests"  { if ($state.DeviceChoice -eq "Multiple") { $script:RequestTemplatesMulti } else { $script:RequestTemplatesSingle } }
                }
                foreach ($t in $templates) { $list.Items.Add($t) | Out-Null }
                $list.Add_SelectionChanged({ $state.SelectedTemplate = $list.SelectedItem }.GetNewClosure())
                $sp.Children.Add($list) | Out-Null
                $contentHost.Children.Add($sp) | Out-Null
            }
            2 {
                $stepLabel.Text = "$SectionName - Step 3: Fill In Details (dummy fields)"
                $sp = New-Object System.Windows.Controls.StackPanel
                $lbl1 = New-Object System.Windows.Controls.TextBlock; $lbl1.Text = "Requestor Name:"
                $tb1 = New-Object System.Windows.Controls.TextBox; $tb1.Margin = "0,0,0,10"
                $lbl2 = New-Object System.Windows.Controls.TextBlock; $lbl2.Text = "Date:"
                $tb2 = New-Object System.Windows.Controls.TextBox; $tb2.Margin = "0,0,0,10"
                $lbl3 = New-Object System.Windows.Controls.TextBlock; $lbl3.Text = "Notes:"
                $tb3 = New-Object System.Windows.Controls.TextBox; $tb3.Height = 60; $tb3.TextWrapping = "Wrap"; $tb3.AcceptsReturn = $true
                $sp.Children.Add($lbl1) | Out-Null; $sp.Children.Add($tb1) | Out-Null
                $sp.Children.Add($lbl2) | Out-Null; $sp.Children.Add($tb2) | Out-Null
                $sp.Children.Add($lbl3) | Out-Null; $sp.Children.Add($tb3) | Out-Null
                $contentHost.Children.Add($sp) | Out-Null
            }
            3 {
                $stepLabel.Text = "$SectionName - Step 4: Generated Output"
                $sp = New-Object System.Windows.Controls.StackPanel
                $out = New-Object System.Windows.Controls.TextBox
                $out.IsReadOnly = $true; $out.Height = 220; $out.TextWrapping = "Wrap"; $out.AcceptsReturn = $true
                $deviceText = if ($state.HasDeviceCountStep) { " | Device Count: $($state.DeviceChoice)" } else { "" }
                $out.Text = "=== $SectionName Template Output (MOCKUP) ===`r`nTemplate: $($state.SelectedTemplate)$deviceText`r`n`r`n[Filled template content would render here]"
                $sp.Children.Add($out) | Out-Null
                $saveBtn = New-Object System.Windows.Controls.Button
                $saveBtn.Content = "Save to .txt (dummy)"; $saveBtn.Width = 160; $saveBtn.HorizontalAlignment = "Left"; $saveBtn.Margin = "0,10,0,0"
                $saveBtn.Add_Click({ [System.Windows.MessageBox]::Show("Mockup only - no file saved.") | Out-Null }.GetNewClosure())
                $sp.Children.Add($saveBtn) | Out-Null
                $contentHost.Children.Add($sp) | Out-Null
            }
        }
        $backBtn.IsEnabled = ($stepIndex -gt 0)
        $maxStep = if ($state.HasDeviceCountStep) { 3 } else { 2 }
        $nextBtn.Content = if ($stepIndex -ge $maxStep) { "Finish" } else { "Next >" }
    }.GetNewClosure()

    $backBtn.Add_Click({
        if ($state.Step -gt 0) { $state.Step--; & $buildStepContent -stepIndex $state.Step }
    }.GetNewClosure())

    $nextBtn.Add_Click({
        $maxStep = if ($state.HasDeviceCountStep) { 3 } else { 2 }
        if ($state.Step -lt $maxStep) { $state.Step++; & $buildStepContent -stepIndex $state.Step }
        else { [System.Windows.MessageBox]::Show("Mockup finished. In the real app this would close/reset the wizard.") | Out-Null }
    }.GetNewClosure())

    & $buildStepContent -stepIndex 0
    return $panel
}

$contentArea = $window.FindName("ContentArea")
$navList     = $window.FindName("NavList")

$wizards = @{
    "Tickets"   = New-WizardPanel -SectionName "Tickets"   -HasDeviceCountStep $false
    "Deferrals" = New-WizardPanel -SectionName "Deferrals" -HasDeviceCountStep $true
    "Requests"  = New-WizardPanel -SectionName "Requests"  -HasDeviceCountStep $true
}

$navList.Add_SelectionChanged({
    $selected = $navList.SelectedItem
    if ($selected) {
        $name = $selected.Content.ToString()
        $contentArea.Children.Clear()
        $contentArea.Children.Add($wizards[$name]) | Out-Null
    }
})

$navList.SelectedIndex = 0

$window.Add_Closed({ [System.Windows.Threading.Dispatcher]::CurrentDispatcher.InvokeShutdown() }.GetNewClosure())
$window.Show()
[System.Windows.Threading.Dispatcher]::Run()
