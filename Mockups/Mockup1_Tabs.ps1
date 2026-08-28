<#
    MOCKUP 1: Tabs across the top for the 3 sections.
    This is a CLICK-THROUGH MOCKUP ONLY - dummy data, no real template engine yet.
    Flow per section: Section Tab -> (Device Count if applicable) -> Template pick -> Fields -> Output
#>

Add-Type -AssemblyName PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Template Generator - Mockup 1 (Tabs)" Height="560" Width="760"
        WindowStartupLocation="CenterScreen">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <TabControl Name="MainTabs" Grid.Row="0" Grid.RowSpan="2">
            <TabItem Header="Tickets" Name="Tab_Tickets"/>
            <TabItem Header="Deferrals" Name="Tab_Deferrals"/>
            <TabItem Header="Requests" Name="Tab_Requests"/>
        </TabControl>
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

# ---------- Helper: builds a step-by-step wizard UserControl-like Grid for a given section ----------
function New-WizardPanel {
    param(
        [string]$SectionName,
        [bool]$HasDeviceCountStep
    )

    $panel = New-Object System.Windows.Controls.Grid
    $panel.Margin = "10"

    $row0 = New-Object System.Windows.Controls.RowDefinition
    $row0.Height = "Auto"
    $row1 = New-Object System.Windows.Controls.RowDefinition
    $row1.Height = "*"
    $row2 = New-Object System.Windows.Controls.RowDefinition
    $row2.Height = "Auto"
    $panel.RowDefinitions.Add($row0)
    $panel.RowDefinitions.Add($row1)
    $panel.RowDefinitions.Add($row2)

    # Step indicator
    $stepLabel = New-Object System.Windows.Controls.TextBlock
    $stepLabel.Name = "StepLabel"
    $stepLabel.FontWeight = "Bold"
    $stepLabel.FontSize = 14
    $stepLabel.Margin = "0,0,0,10"
    [System.Windows.Controls.Grid]::SetRow($stepLabel, 0)
    $panel.Children.Add($stepLabel) | Out-Null

    # Content host
    $contentHost = New-Object System.Windows.Controls.Grid
    $contentHost.Name = "ContentHost"
    [System.Windows.Controls.Grid]::SetRow($contentHost, 1)
    $panel.Children.Add($contentHost) | Out-Null

    # Nav buttons
    $btnPanel = New-Object System.Windows.Controls.StackPanel
    $btnPanel.Orientation = "Horizontal"
    $btnPanel.HorizontalAlignment = "Right"
    [System.Windows.Controls.Grid]::SetRow($btnPanel, 2)

    $backBtn = New-Object System.Windows.Controls.Button
    $backBtn.Content = "< Back"
    $backBtn.Width = 90
    $backBtn.Margin = "0,10,10,0"
    $backBtn.Name = "BackBtn"

    $nextBtn = New-Object System.Windows.Controls.Button
    $nextBtn.Content = "Next >"
    $nextBtn.Width = 90
    $nextBtn.Margin = "0,10,0,0"
    $nextBtn.Name = "NextBtn"

    $btnPanel.Children.Add($backBtn) | Out-Null
    $btnPanel.Children.Add($nextBtn) | Out-Null
    $panel.Children.Add($btnPanel) | Out-Null

    # ---- Build step definitions ----
    # step 0: Device count (only if HasDeviceCountStep)
    # step N: template pick
    # step N+1: fields
    # step N+2: output

    $state = @{
        Step = 0
        HasDeviceCountStep = $HasDeviceCountStep
        DeviceChoice = $null
        AssignmentKnown = $null
        SelectedTemplate = $null
        Fields = @{}
        SectionName = $SectionName
    }

    $buildStepContent = {
        param($stepIndex)

        $contentHost.Children.Clear()

        $effectiveStep = $stepIndex
        if (-not $state.HasDeviceCountStep -and $SectionName -ne "Tickets") {
            $effectiveStep = $stepIndex + 1
        }

        switch ($effectiveStep) {
            0 {
                if ($SectionName -eq "Tickets") {
                    $stepLabel.Text = "Tickets - Step 1: Are the assigned user and location known?"
                    $sp = New-Object System.Windows.Controls.StackPanel
                    $rb1 = New-Object System.Windows.Controls.RadioButton
                    $rb1.Content = "Yes - user and location are known"
                    $rb1.GroupName = "AssignmentKnown"
                    $rb1.Margin = "0,5,0,5"
                    $rb1.IsChecked = ($state.AssignmentKnown -eq $true)
                    $rb1.Tag = $state
                    $rb1.Add_Checked({ param($sender, $eventArgs) $sender.Tag['AssignmentKnown'] = $true })
                    $rb2 = New-Object System.Windows.Controls.RadioButton
                    $rb2.Content = "No - user and location are not known"
                    $rb2.GroupName = "AssignmentKnown"
                    $rb2.Margin = "0,5,0,5"
                    $rb2.IsChecked = ($state.AssignmentKnown -eq $false)
                    $rb2.Tag = $state
                    $rb2.Add_Checked({ param($sender, $eventArgs) $sender.Tag['AssignmentKnown'] = $false })
                    $sp.Children.Add($rb1) | Out-Null
                    $sp.Children.Add($rb2) | Out-Null
                    $contentHost.Children.Add($sp) | Out-Null
                    break
                }
                $stepLabel.Text = "$SectionName - Step 1: Choose Device Count"
                $sp = New-Object System.Windows.Controls.StackPanel
                $rb1 = New-Object System.Windows.Controls.RadioButton
                $rb1.Content = "Single Device"
                $rb1.GroupName = "DeviceCount"
                $rb1.Margin = "0,5,0,5"
                $rb1.IsChecked = ($state.DeviceChoice -eq "Single")
                $rb1.Tag = $state
                $rb1.Add_Checked({ param($sender, $eventArgs) $sender.Tag['DeviceChoice'] = "Single" })
                $rb2 = New-Object System.Windows.Controls.RadioButton
                $rb2.Content = "Multiple Devices"
                $rb2.GroupName = "DeviceCount"
                $rb2.Margin = "0,5,0,5"
                $rb2.IsChecked = ($state.DeviceChoice -eq "Multiple")
                $rb2.Tag = $state
                $rb2.Add_Checked({ param($sender, $eventArgs) $sender.Tag['DeviceChoice'] = "Multiple" })
                $sp.Children.Add($rb1) | Out-Null
                $sp.Children.Add($rb2) | Out-Null
                $contentHost.Children.Add($sp) | Out-Null
            }
            1 {
                $stepLabel.Text = "$SectionName - Step 2: Choose Template"
                $sp = New-Object System.Windows.Controls.StackPanel
                $list = New-Object System.Windows.Controls.ListBox
                $list.Name = "TemplateList"
                $list.Height = 200

                $templates = switch ($SectionName) {
                    "Tickets"   { $script:TicketTemplates }
                    "Deferrals" { if ($state.DeviceChoice -eq "Multiple") { $script:DeferralTemplatesMulti } else { $script:DeferralTemplatesSingle } }
                    "Requests"  { if ($state.DeviceChoice -eq "Multiple") { $script:RequestTemplatesMulti } else { $script:RequestTemplatesSingle } }
                }
                foreach ($t in $templates) { $list.Items.Add($t) | Out-Null }
                $list.Tag = $state
                $list.Add_SelectionChanged({ param($sender, $eventArgs) $sender.Tag['SelectedTemplate'] = $sender.SelectedItem })
                $sp.Children.Add($list) | Out-Null
                $contentHost.Children.Add($sp) | Out-Null
            }
            2 {
                $fieldStep = if ($SectionName -eq "Tickets") { 3 } else { 2 }
                $stepLabel.Text = "$SectionName - Step ${fieldStep}: Fill In Details"
                $sp = New-Object System.Windows.Controls.StackPanel

                if ($SectionName -eq "Tickets") {
                    $fields = if ($state.AssignmentKnown -eq $true) {
                        @("Summary (Vulnerability Remediation - {DeviceName})", "Issue(s):", "User:", "E/C Code:", "Phone:", "Device:", "Completion Date:", "Solution(s):")
                    } else {
                        @("Summary", "Issue(s):", "Device:", "Last Known Location:", "Completion Deadline:", "Solution(s):")
                    }
                    foreach ($field in $fields) {
                        $label = New-Object System.Windows.Controls.TextBlock
                        $label.Text = $field
                        $box = New-Object System.Windows.Controls.TextBox
                        $box.Margin = "0,0,0,8"
                        if ($field -eq "Summary" -or $field.StartsWith("Summary (")) { $box.Text = "Vulnerability Remediation - " }
                        if ($field -eq "Solution(s):") { $box.Height = 60; $box.TextWrapping = "Wrap"; $box.AcceptsReturn = $true; $box.Margin = "0,8,0,0" }
                        $box.Tag = @{ State = $state; Field = $field }
                        $box.Add_TextChanged({
                            param($sender, $eventArgs)
                            $sender.Tag.State.Fields[$sender.Tag.Field] = $sender.Text
                        })
                        $sp.Children.Add($label) | Out-Null
                        $sp.Children.Add($box) | Out-Null
                    }
                } else {
                    $lbl1 = New-Object System.Windows.Controls.TextBlock
                    $lbl1.Text = "Requestor Name:"
                    $tb1 = New-Object System.Windows.Controls.TextBox
                    $tb1.Margin = "0,0,0,10"
                    $lbl2 = New-Object System.Windows.Controls.TextBlock
                    $lbl2.Text = "Date:"
                    $tb2 = New-Object System.Windows.Controls.TextBox
                    $tb2.Margin = "0,0,0,10"
                    $lbl3 = New-Object System.Windows.Controls.TextBlock
                    $lbl3.Text = "Notes:"
                    $tb3 = New-Object System.Windows.Controls.TextBox
                    $tb3.Height = 60
                    $tb3.TextWrapping = "Wrap"
                    $tb3.AcceptsReturn = $true
                    $sp.Children.Add($lbl1) | Out-Null
                    $sp.Children.Add($tb1) | Out-Null
                    $sp.Children.Add($lbl2) | Out-Null
                    $sp.Children.Add($tb2) | Out-Null
                    $sp.Children.Add($lbl3) | Out-Null
                    $sp.Children.Add($tb3) | Out-Null
                }
                $contentHost.Children.Add($sp) | Out-Null
            }
            3 {
                $stepLabel.Text = "$SectionName - Step 4: Generated Output"
                $sp = New-Object System.Windows.Controls.StackPanel
                $out = New-Object System.Windows.Controls.TextBox
                $out.IsReadOnly = $true
                $out.Height = 220
                $out.TextWrapping = "Wrap"
                $out.AcceptsReturn = $true
                $deviceText = if ($state.HasDeviceCountStep) { " | Device Count: $($state.DeviceChoice)" } else { "" }
                $fieldText = ($state.Fields.GetEnumerator() | ForEach-Object { "$($_.Key) $($_.Value)" }) -join "`r`n"
                $out.Text = "=== $SectionName Template Output (MOCKUP) ===`r`nTemplate: $($state.SelectedTemplate)$deviceText`r`n`r`n$fieldText"
                $sp.Children.Add($out) | Out-Null

                $saveBtn = New-Object System.Windows.Controls.Button
                $saveBtn.Content = "Save to .txt (dummy)"
                $saveBtn.Width = 160
                $saveBtn.HorizontalAlignment = "Left"
                $saveBtn.Margin = "0,10,0,0"
                $saveBtn.Add_Click({ [System.Windows.MessageBox]::Show("Mockup only - no file saved.") | Out-Null }.GetNewClosure())
                $sp.Children.Add($saveBtn) | Out-Null

                $contentHost.Children.Add($sp) | Out-Null
            }
        }

        $backBtn.IsEnabled = ($stepIndex -gt 0)
        $maxStep = if ($SectionName -eq "Tickets") { 3 } elseif ($state.HasDeviceCountStep) { 3 } else { 2 }
        $nextBtn.Content = if ($stepIndex -ge $maxStep) { "Finish" } else { "Next >" }
    }.GetNewClosure()

    $backBtn.Add_Click({
        if ($state.Step -gt 0) {
            $state.Step--
            & $buildStepContent -stepIndex $state.Step
        }
    }.GetNewClosure())

    $nextBtn.Add_Click({
        $maxStep = if ($state.HasDeviceCountStep) { 3 } else { 2 }
        if ($state.Step -lt $maxStep) {
            $state.Step++
            & $buildStepContent -stepIndex $state.Step
        } else {
            [System.Windows.MessageBox]::Show("Mockup finished. In the real app this would close/reset the wizard.") | Out-Null
        }
    }.GetNewClosure())

    & $buildStepContent -stepIndex 0
    return $panel
}

$wizardTickets   = New-WizardPanel -SectionName "Tickets"   -HasDeviceCountStep $false
$wizardDeferrals = New-WizardPanel -SectionName "Deferrals" -HasDeviceCountStep $true
$wizardRequests  = New-WizardPanel -SectionName "Requests"  -HasDeviceCountStep $true

$tabTickets   = $window.FindName("Tab_Tickets")
$tabDeferrals = $window.FindName("Tab_Deferrals")
$tabRequests  = $window.FindName("Tab_Requests")

$tabTickets.Content   = $wizardTickets
$tabDeferrals.Content = $wizardDeferrals
$tabRequests.Content  = $wizardRequests

$window.ShowDialog() | Out-Null
