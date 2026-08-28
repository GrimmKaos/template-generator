<#
    Live Template Generator. Run with Windows PowerShell -STA.
#>
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ticketTemplateDirectory = Join-Path $root "Templates\Tickets"
if (-not (Test-Path -LiteralPath $ticketTemplateDirectory)) { throw "Missing ticket template folder: $ticketTemplateDirectory" }
$issueCatalogPath = Join-Path $ticketTemplateDirectory "Issues.json"
if (-not (Test-Path -LiteralPath $issueCatalogPath)) { throw "Missing issue catalog: $issueCatalogPath" }
$issueCatalog = Get-Content -LiteralPath $issueCatalogPath -Raw | ConvertFrom-Json

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
$ticketTemplates = @()
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

function Add-DateField {
    param([string]$key, [string]$label)
    $text = New-Object System.Windows.Controls.TextBlock
    $text.Text = $label
    $text.Margin = "0,3,0,2"
    $picker = New-Object System.Windows.Controls.DatePicker
    $picker.Margin = "0,0,0,7"
    $picker.SelectedDateFormat = "Short"
    $content.Children.Add($text) | Out-Null
    $content.Children.Add($picker) | Out-Null
    $controls[$key] = $picker
}

function Add-IssueSelector {
    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = "Issue(s): Select all that apply"
    $label.Margin = "0,3,0,2"
    $scroll = New-Object System.Windows.Controls.ScrollViewer
    $scroll.Height = 145
    $scroll.VerticalScrollBarVisibility = "Auto"
    $issuePanel = New-Object System.Windows.Controls.StackPanel
    $checkboxes = @()
    foreach ($issue in @($issueCatalog.Items)) {
        $check = New-Object System.Windows.Controls.CheckBox
        $check.Content = [string]$issue
        $check.Margin = "2,2,2,2"
        if (($state.Data["Issues"] -split ", ") -contains [string]$issue) { $check.IsChecked = $true }
        $issuePanel.Children.Add($check) | Out-Null
        $checkboxes += $check
    }
    $other = New-Object System.Windows.Controls.TextBox
    $other.Margin = "2,8,2,2"
    $other.ToolTip = "Enter another issue. Separate multiple items with commas."
    $other.Text = [string]$state.Data["OtherIssue"]
    $issuePanel.Children.Add((New-Object System.Windows.Controls.TextBlock -Property @{ Text = "Other:"; Margin = "2,8,2,2" })) | Out-Null
    $issuePanel.Children.Add($other) | Out-Null
    $scroll.Content = $issuePanel
    $content.Children.Add($label) | Out-Null
    $content.Children.Add($scroll) | Out-Null
    $controls["IssueSelector"] = @{ Checkboxes = $checkboxes; Other = $other }
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
                Add-DateField "CompletionDeadDate" "Completion Deadline:"
            } else {
                Add-LabelAndBox "LastKnownLocation" "Last Known Location:"
                Add-DateField "CompletionDeadDate" "Completion Deadline:"
            }
            Add-IssueSelector
        }
        2 {
            $list = New-Object System.Windows.Controls.ListBox
            $list.Height = 150
            foreach ($template in $ticketTemplates) { [void]$list.Items.Add($template.Name) }
            $list.Tag = @{ State = $state; Templates = $ticketTemplates }
            $list.Add_SelectionChanged({
                param($sender, $eventArgs)
                if ($null -ne $sender.SelectedItem) {
                    $sender.Tag.State.Template = $sender.Tag.Templates | Where-Object { $_.Name -eq $sender.SelectedItem.ToString() } | Select-Object -First 1
                }
            })
            $content.Children.Add($list) | Out-Null
            if ($list.Items.Count -gt 0) {
                $list.SelectedIndex = 0
                $state.Template = $ticketTemplates[0]
            }
        }
        3 {
            if ($null -eq $state.Template) {
                $content.Children.Add((New-Object System.Windows.Controls.TextBlock -Property @{ Text = "Select a template before continuing." })) | Out-Null
            } elseif ($state.Template.RequiresAdditionalInput -eq $true) {
                foreach ($field in @($state.Template.AdditionalFields)) {
                    if ($field.Type -eq "Choice") {
                        $label = New-Object System.Windows.Controls.TextBlock -Property @{ Text = $field.Label; Margin = "0,3,0,2" }
                        $choice = New-Object System.Windows.Controls.ComboBox -Property @{ Margin = "0,0,0,7" }
                        foreach ($option in @($field.Options)) { [void]$choice.Items.Add($option) }
                        if ($choice.Items.Count -gt 0) { $choice.SelectedIndex = 0 }
                        $content.Children.Add($label) | Out-Null
                        $content.Children.Add($choice) | Out-Null
                        $controls[$field.Name] = $choice
                    } else {
                        Add-LabelAndBox $field.Name $field.Label ($field.Type -eq "Multiline")
                    }
                }
            } else {
                $content.Children.Add((New-Object System.Windows.Controls.TextBlock -Property @{ Text = "This template requires no additional input." })) | Out-Null
            }
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
            $startOver = New-Object System.Windows.Controls.Button
            $startOver.Content = "Start Over"
            $startOver.Width = 100
            $startOver.Margin = "0,10,0,0"
            $startOver.HorizontalAlignment = "Left"
            $startOver.Add_Click({
                $state.Step = 0
                $state.AssignmentKnown = $null
                $state.Data.Clear()
                $state.Additional.Clear()
                $state.Template = $null
                $state.Output = ""
                Show-Step
            })
            $content.Children.Add($startOver) | Out-Null
            $next.IsEnabled = $false
        }
    }
    $back.IsEnabled = ($state.Step -gt 0)
    if ($state.Step -lt 4) { $next.IsEnabled = $true }
    $next.Content = if ($state.Step -eq 3) { "Generate" } else { "Next >" }
}

function Read-CurrentControls {
    foreach ($key in $controls.Keys) {
        if ($key -eq "IssueSelector") {
            $selected = @($controls[$key].Checkboxes | Where-Object { $_.IsChecked -eq $true } | ForEach-Object { [string]$_.Content })
            $otherIssues = [string]$controls[$key].Other.Text
            if (-not [string]::IsNullOrWhiteSpace($otherIssues)) { $selected += @($otherIssues -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
            $state.Data["Issues"] = ($selected -join ", ")
            $state.Data["OtherIssue"] = $otherIssues
        } elseif ($controls[$key] -is [System.Windows.Controls.DatePicker]) {
            $selectedDate = $controls[$key].SelectedDate
            $state.Data[$key] = if ($null -ne $selectedDate) {
                ([datetime]$selectedDate).ToString("yyyy-MM-dd")
            } else { "" }
        } else {
            $state.Data[$key] = $controls[$key].Text
        }
    }
    if ($controls.ContainsKey("Action")) { $state.Additional["Action"] = $controls["Action"].SelectedIndex }
}

$next.Add_Click({
    if ($state.Step -eq 0 -and $null -eq $state.AssignmentKnown) {
        [System.Windows.MessageBox]::Show("Choose whether the assigned user and location are known.", "Required", "OK", "Warning") | Out-Null
        return
    }
    if ($state.Step -eq 1) { Read-CurrentControls }
    if ($state.Step -eq 2 -and $null -eq $state.Template) {
        [System.Windows.MessageBox]::Show("Select a ticket template before continuing.", "Required", "OK", "Warning") | Out-Null
        return
    }
    if ($state.Step -eq 3 -and $state.Template.RequiresAdditionalInput -eq $true) {
        Read-CurrentControls
        foreach ($field in @($state.Template.AdditionalFields)) {
            $value = [string]$state.Data[$field.Name]
            $required = $field.Required -eq $true
            if (-not $required -and $field.RequiredWhen) {
                $parts = $field.RequiredWhen -split "=", 2
                $required = ([string]$state.Data[$parts[0]] -eq $parts[1])
            }
            if ($required -and [string]::IsNullOrWhiteSpace($value)) {
                [System.Windows.MessageBox]::Show("Enter $($field.Label)", "Required", "OK", "Warning") | Out-Null
                return
            }
        }
    }
    if ($state.Step -eq 3 -and $state.Template.RequiresAdditionalInput -ne $true) { Read-CurrentControls }
    if ($state.Step -eq 3) {
        $output = [string]$state.Template.Content
        foreach ($key in $state.Data.Keys) { $output = $output.Replace("{$key}", [string]$state.Data[$key]) }
        $solution = ""
        if ($state.Template.Name -eq "Update Python") {
            $installedKey = ($state.Template.AdditionalFields | Where-Object { $_.Name -like "InstalledPython_*" } | Select-Object -First 1).Name
            $actionKey = ($state.Template.AdditionalFields | Where-Object { $_.Name -like "Action_*" } | Select-Object -First 1).Name
            $targetKey = ($state.Template.AdditionalFields | Where-Object { $_.Name -like "TargetVersion_*" } | Select-Object -First 1).Name
            $notesKey = ($state.Template.AdditionalFields | Where-Object { $_.Name -like "SolutionNotes_*" } | Select-Object -First 1).Name
            $installed = [string]$state.Data[$installedKey]
            $device = [string]$state.Data["DeviceName"]
            $solution = if ([string]$state.Data[$actionKey] -eq "Update to a target version") { "Update Python version(s) $installed to $($state.Data[$targetKey]) on $device." } else { "Remove the affected Python version(s) $installed from $device." }
            if (-not [string]::IsNullOrWhiteSpace([string]$state.Data[$notesKey])) { $solution += " " + $state.Data[$notesKey] }
        }
        $solutionPlaceholder = [regex]::Match($output, "\{Solution_[^}]+\}").Value
        if ($solutionPlaceholder) { $output = $output.Replace($solutionPlaceholder, $solution) }
        $state.Output = $output
    }
    if ($state.Step -lt 4) { $state.Step++; Show-Step }
})

$back.Add_Click({ if ($state.Step -gt 0) { if ($state.Step -eq 2) { $state.Template = $null }; $state.Step--; Show-Step } })
$ticketTemplates = @(Get-ChildItem -LiteralPath $ticketTemplateDirectory -Filter "*.json" | Where-Object { $_.Name -ne "Issues.json" } | ForEach-Object {
    try { Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json }
    catch { throw "Invalid ticket template JSON: $($_.Name). $($_.Exception.Message)" }
})
if ($ticketTemplates.Count -eq 0) { throw "No ticket JSON templates were found in $ticketTemplateDirectory" }
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
            $startOver = New-Object System.Windows.Controls.Button -Property @{ Content = "Start Over"; Width = 100; Margin = "0,10,0,0" }
            $startOver.Add_Click({
                $deferralState.Step = 0
                $deferralState.DeviceCount = $null
                $deferralState.Template = $null
                $deferralState.Data.Clear()
                $deferralState.Output = ""
                Show-DeferralStep
            })
            $deferralContent.Children.Add($startOver) | Out-Null
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
