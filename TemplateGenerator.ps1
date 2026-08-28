<#
    Live Template Generator. Run with Windows PowerShell -STA.
#>
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$templatePath = Join-Path $root "Templates\Tickets_UpdatePython.txt"
if (-not (Test-Path -LiteralPath $templatePath)) { throw "Missing template: $templatePath" }

$state = @{
    AssignmentKnown = $null
    Data = @{}
    Template = $null
    Additional = @{}
    Output = ""
}

$window = New-Object System.Windows.Window
$window.Title = "Template Generator"
$window.Width = 900
$window.Height = 720
$window.WindowStartupLocation = "CenterScreen"

$rootGrid = New-Object System.Windows.Controls.Grid
$rootGrid.Margin = "12"
$rootGrid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))
$rootGrid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "*" }))
$heading = New-Object System.Windows.Controls.TextBlock
$heading.Text = "Template Generator"
$heading.FontSize = 24
$heading.FontWeight = "Bold"
$heading.Margin = "0,0,0,10"
[System.Windows.Controls.Grid]::SetRow($heading, 0)
$rootGrid.Children.Add($heading) | Out-Null
$tabs = New-Object System.Windows.Controls.TabControl
[System.Windows.Controls.Grid]::SetRow($tabs, 1)
$rootGrid.Children.Add($tabs) | Out-Null
$window.Content = $rootGrid

$ticketTab = New-Object System.Windows.Controls.TabItem
$ticketTab.Header = "Tickets"
$tabs.Items.Add($ticketTab) | Out-Null
$deferralTab = New-Object System.Windows.Controls.TabItem
$deferralTab.Header = "Deferrals"
$tabs.Items.Add($deferralTab) | Out-Null
foreach ($name in @("Requests")) {
    $tab = New-Object System.Windows.Controls.TabItem
    $tab.Header = $name
    $tab.IsEnabled = $false
    $tabs.Items.Add($tab) | Out-Null
}

$layout = New-Object System.Windows.Controls.Grid
$layout.Margin = "12"
$layout.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "*" }))
$layout.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))
$content = New-Object System.Windows.Controls.StackPanel
$content.Margin = "0,0,0,10"
[System.Windows.Controls.Grid]::SetRow($content, 0)
$layout.Children.Add($content) | Out-Null
$buttons = New-Object System.Windows.Controls.StackPanel
$buttons.Orientation = "Horizontal"
$buttons.HorizontalAlignment = "Right"
[System.Windows.Controls.Grid]::SetRow($buttons, 1)
$back = New-Object System.Windows.Controls.Button
$back.Content = "< Back"
$back.Width = 90
$back.Margin = "0,0,8,0"
$next = New-Object System.Windows.Controls.Button
$next.Content = "Next >"
$next.Width = 90
$buttons.Children.Add($back) | Out-Null
$buttons.Children.Add($next) | Out-Null
$layout.Children.Add($buttons) | Out-Null
$ticketTab.Content = $layout

$state.Step = 0
$controls = @{}
$steps = @(
    "Known User or Location",
    "Data Input",
    "Template Selection",
    "Additional Input",
    "Output"
)

function Add-LabelAndBox {
    param([string]$key, [string]$label, [bool]$multiline = $false)
    $text = New-Object System.Windows.Controls.TextBlock
    $text.Text = $label
    $text.Margin = "0,3,0,2"
    $box = New-Object System.Windows.Controls.TextBox
    $box.Margin = "0,0,0,7"
    if ($multiline) { $box.Height = 70; $box.AcceptsReturn = $true; $box.TextWrapping = "Wrap" }
    $content.Children.Add($text) | Out-Null
    $content.Children.Add($box) | Out-Null
    $controls[$key] = $box
}

function Show-Step {
    $content.Children.Clear()
    $controls.Clear()
    $heading.Text = "Template Generator - Tickets - Step $($state.Step + 1) of $($steps.Count): $($steps[$state.Step])"

    switch ($state.Step) {
        0 {
            $yes = New-Object System.Windows.Controls.RadioButton
            $yes.Content = "Yes - assigned user and location are known"
            $yes.Margin = "0,8,0,8"
            $yes.IsChecked = ($state.AssignmentKnown -eq $true)
            $yes.Add_Checked({ $state.AssignmentKnown = $true })
            $no = New-Object System.Windows.Controls.RadioButton
            $no.Content = "No - assigned user and location are not known"
            $no.Margin = "0,8,0,8"
            $no.IsChecked = ($state.AssignmentKnown -eq $false)
            $no.Add_Checked({ $state.AssignmentKnown = $false })
            $content.Children.Add($yes) | Out-Null
            $content.Children.Add($no) | Out-Null
        }
        1 {
            Add-LabelAndBox "DeviceName" "Device:"
            if ($state.AssignmentKnown -eq $true) {
                Add-LabelAndBox "UserName" "User:"
                Add-LabelAndBox "ECCode" "E/C Code:"
                Add-LabelAndBox "PhoneNumber" "Phone:"
                Add-LabelAndBox "CompletionDeadDate" "Completion Deadline:"
            } else {
                Add-LabelAndBox "LastKnownLocation" "Last Known Location:"
                Add-LabelAndBox "CompletionDeadDate" "Completion Deadline:"
            }
            Add-LabelAndBox "Issues" "Issue(s):" $true
        }
        2 {
            $list = New-Object System.Windows.Controls.ListBox
            $list.Height = 150
            $list.Items.Add("Update Python") | Out-Null
            $list.SelectedIndex = 0
            $list.Add_SelectionChanged({ $state.Template = $list.SelectedItem.ToString() })
            $content.Children.Add($list) | Out-Null
            $state.Template = "Update Python"
        }
        3 {
            Add-LabelAndBox "InstalledPython" "Installed Python version(s): (example: 3.8.10, 3.9.13)"
            $action = New-Object System.Windows.Controls.ComboBox
            $action.Items.Add("Update to a target version") | Out-Null
            $action.Items.Add("Remove the affected version(s)") | Out-Null
            $action.SelectedIndex = 0
            $action.Margin = "0,0,0,8"
            $content.Children.Add((New-Object System.Windows.Controls.TextBlock -Property @{ Text = "Action:" })) | Out-Null
            $content.Children.Add($action) | Out-Null
            $controls["Action"] = $action
            Add-LabelAndBox "TargetVersion" "Target Python version (required for update):"
            Add-LabelAndBox "SolutionNotes" "Additional solution details (optional):" $true
        }
        4 {
            $output = New-Object System.Windows.Controls.TextBox
            $output.IsReadOnly = $true
            $output.AcceptsReturn = $true
            $output.TextWrapping = "Wrap"
            $output.VerticalScrollBarVisibility = "Auto"
            $output.Height = 390
            $output.Text = $state.Output
            $content.Children.Add($output) | Out-Null
            $copy = New-Object System.Windows.Controls.Button
            $copy.Content = "Copy Output"
            $copy.Width = 110
            $copy.Margin = "0,10,0,0"
            $copy.HorizontalAlignment = "Left"
            $copy.Add_Click({ [System.Windows.Clipboard]::SetText($state.Output); [System.Windows.MessageBox]::Show("Output copied to clipboard.") | Out-Null })
            $content.Children.Add($copy) | Out-Null
            $next.IsEnabled = $false
        }
    }
    $back.IsEnabled = ($state.Step -gt 0)
    if ($state.Step -lt 4) { $next.IsEnabled = $true }
    $next.Content = if ($state.Step -eq 3) { "Generate" } else { "Next >" }
}

function Read-CurrentControls {
    foreach ($key in $controls.Keys) { $state.Data[$key] = $controls[$key].Text }
    if ($controls.ContainsKey("Action")) { $state.Additional["Action"] = $controls["Action"].SelectedIndex }
}

$next.Add_Click({
    if ($state.Step -eq 0 -and $null -eq $state.AssignmentKnown) {
        [System.Windows.MessageBox]::Show("Choose whether the assigned user and location are known.", "Required", "OK", "Warning") | Out-Null
        return
    }
    if ($state.Step -eq 1) { Read-CurrentControls }
    if ($state.Step -eq 3) {
        Read-CurrentControls
        if ([string]::IsNullOrWhiteSpace($state.Data["InstalledPython"])) {
            [System.Windows.MessageBox]::Show("Enter the installed Python version(s).", "Required", "OK", "Warning") | Out-Null
            return
        }
        $isUpdate = $state.Additional["Action"] -eq 0
        if ($isUpdate -and [string]::IsNullOrWhiteSpace($state.Data["TargetVersion"])) {
            [System.Windows.MessageBox]::Show("Enter the target Python version, or choose removal.", "Required", "OK", "Warning") | Out-Null
            return
        }
        $installed = $state.Data["InstalledPython"].Trim()
        $device = $state.Data["DeviceName"].Trim()
        $solution = if ($isUpdate) { "Update Python version(s) $installed to $($state.Data["TargetVersion"].Trim()) on $device." } else { "Remove the affected Python version(s) $installed from $device." }
        if (-not [string]::IsNullOrWhiteSpace($state.Data["SolutionNotes"])) { $solution += " " + $state.Data["SolutionNotes"].Trim() }
        $output = Get-Content -LiteralPath $templatePath -Raw
        $replacements = @{
            "{DeviceName}" = $device
            "{Installed Python}" = $installed
            "{UserName}" = if ($state.Data.ContainsKey("UserName")) { $state.Data["UserName"] } else { "" }
            "{E_C-Code}" = if ($state.Data.ContainsKey("ECCode")) { $state.Data["ECCode"] } else { "" }
            "{PhoneNumber}" = if ($state.Data.ContainsKey("PhoneNumber")) { $state.Data["PhoneNumber"] } else { "" }
            "{CompletionDeadDate}" = $state.Data["CompletionDeadDate"]
            "{Solution}" = $solution
        }
        foreach ($placeholder in $replacements.Keys) { $output = $output.Replace($placeholder, [string]$replacements[$placeholder]) }
        $state.Output = $output
    }
    if ($state.Step -lt 4) { $state.Step++; Show-Step }
})

$back.Add_Click({ if ($state.Step -gt 0) { if ($state.Step -eq 2) { $state.Template = $null }; $state.Step--; Show-Step } })
Show-Step

# Deferrals workflow: device count -> template -> template-specific data -> output.
$deferralTemplatePath = Join-Path $root "Templates\Deferrals_SingleDevice_ReImaged.txt"
$deferralState = @{ Step = 0; DeviceCount = $null; Template = $null; Data = @{}; Output = "" }
$deferralLayout = New-Object System.Windows.Controls.Grid
$deferralLayout.Margin = "12"
$deferralLayout.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "*" }))
$deferralLayout.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))
$deferralContent = New-Object System.Windows.Controls.StackPanel
$deferralContent.Margin = "0,0,0,10"
[System.Windows.Controls.Grid]::SetRow($deferralContent, 0)
$deferralLayout.Children.Add($deferralContent) | Out-Null
$deferralButtons = New-Object System.Windows.Controls.StackPanel
$deferralButtons.Orientation = "Horizontal"
$deferralButtons.HorizontalAlignment = "Right"
[System.Windows.Controls.Grid]::SetRow($deferralButtons, 1)
$deferralBack = New-Object System.Windows.Controls.Button
$deferralBack.Content = "< Back"; $deferralBack.Width = 90; $deferralBack.Margin = "0,0,8,0"
$deferralNext = New-Object System.Windows.Controls.Button
$deferralNext.Content = "Next >"; $deferralNext.Width = 90
$deferralButtons.Children.Add($deferralBack) | Out-Null
$deferralButtons.Children.Add($deferralNext) | Out-Null
$deferralLayout.Children.Add($deferralButtons) | Out-Null
$deferralTab.Content = $deferralLayout
$deferralControls = @{}

function Add-DeferralField {
    param([string]$key, [string]$label)
    $labelControl = New-Object System.Windows.Controls.TextBlock -Property @{ Text = $label; Margin = "0,3,0,2" }
    $box = New-Object System.Windows.Controls.TextBox -Property @{ Margin = "0,0,0,8" }
    $deferralContent.Children.Add($labelControl) | Out-Null
    $deferralContent.Children.Add($box) | Out-Null
    $deferralControls[$key] = $box
}

function Show-DeferralStep {
    $deferralContent.Children.Clear()
    $deferralControls.Clear()
    $heading.Text = "Template Generator - Deferrals - Step $($deferralState.Step + 1) of 4"
    switch ($deferralState.Step) {
        0 {
            $single = New-Object System.Windows.Controls.RadioButton -Property @{ Content = "Single Device"; Margin = "0,8,0,8" }
            $single.IsChecked = ($deferralState.DeviceCount -eq "Single")
            $single.Add_Checked({ $deferralState.DeviceCount = "Single" })
            $multiple = New-Object System.Windows.Controls.RadioButton -Property @{ Content = "Multiple Devices"; Margin = "0,8,0,8" }
            $multiple.IsChecked = ($deferralState.DeviceCount -eq "Multiple")
            $multiple.Add_Checked({ $deferralState.DeviceCount = "Multiple" })
            $deferralContent.Children.Add($single) | Out-Null
            $deferralContent.Children.Add($multiple) | Out-Null
        }
        1 {
            $list = New-Object System.Windows.Controls.ListBox
            $list.Height = 100
            if ($deferralState.DeviceCount -eq "Single") { $list.Items.Add("Device Re-Imaged") | Out-Null }
            else { $list.Items.Add("Multiple Device Deferral (to be defined)") | Out-Null }
            $list.SelectedIndex = 0
            $list.Add_SelectionChanged({ $deferralState.Template = $list.SelectedItem.ToString() })
            $deferralContent.Children.Add($list) | Out-Null
            $deferralState.Template = $list.SelectedItem.ToString()
        }
        2 {
            if ($deferralState.DeviceCount -eq "Single" -and $deferralState.Template -eq "Device Re-Imaged") {
                Add-DeferralField "DeviceName" "Device Name:"
                Add-DeferralField "RequestNumber" "Request Number:"
            } else {
                $deferralContent.Children.Add((New-Object System.Windows.Controls.TextBlock -Property @{ Text = "This template's fields have not been defined yet." })) | Out-Null
            }
        }
        3 {
            $output = New-Object System.Windows.Controls.TextBox
            $output.IsReadOnly = $true; $output.TextWrapping = "Wrap"; $output.AcceptsReturn = $true; $output.Height = 300
            $output.Text = $deferralState.Output
            $deferralContent.Children.Add($output) | Out-Null
            $copy = New-Object System.Windows.Controls.Button -Property @{ Content = "Copy Output"; Width = 110; Margin = "0,10,0,0" }
            $copy.Add_Click({ [System.Windows.Clipboard]::SetText($deferralState.Output); [System.Windows.MessageBox]::Show("Output copied to clipboard.") | Out-Null })
            $deferralContent.Children.Add($copy) | Out-Null
            $deferralNext.IsEnabled = $false
        }
    }
    $deferralBack.IsEnabled = ($deferralState.Step -gt 0)
    if ($deferralState.Step -lt 3) { $deferralNext.IsEnabled = $true }
    $deferralNext.Content = if ($deferralState.Step -eq 2) { "Generate" } else { "Next >" }
}

$deferralNext.Add_Click({
    if ($deferralState.Step -eq 0 -and $null -eq $deferralState.DeviceCount) {
        [System.Windows.MessageBox]::Show("Choose Single Device or Multiple Devices.", "Required", "OK", "Warning") | Out-Null
        return
    }
    if ($deferralState.Step -eq 2) {
        foreach ($key in $deferralControls.Keys) { $deferralState.Data[$key] = $deferralControls[$key].Text }
        if ([string]::IsNullOrWhiteSpace($deferralState.Data["DeviceName"]) -or [string]::IsNullOrWhiteSpace($deferralState.Data["RequestNumber"])) {
            [System.Windows.MessageBox]::Show("Device Name and Request Number are required.", "Required", "OK", "Warning") | Out-Null
            return
        }
        $template = Get-Content -LiteralPath $deferralTemplatePath -Raw
        $deferralState.Output = $template.Replace("{Device Name}", $deferralState.Data["DeviceName"].Trim()).Replace("{Request Number}", $deferralState.Data["RequestNumber"].Trim())
    }
    if ($deferralState.Step -lt 3) { $deferralState.Step++; Show-DeferralStep }
})
$deferralBack.Add_Click({ if ($deferralState.Step -gt 0) { $deferralState.Step--; Show-DeferralStep } })
Show-DeferralStep

$window.ShowDialog() | Out-Null
