# WinConf.Gui.ps1 - Windows Forms desktop interface for WinConf.

[CmdletBinding()]
param(
    [switch] $SmokeTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-WinConfAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not $SmokeTest -and -not (Test-WinConfAdministrator)) {
    try {
        $arguments = "-NoProfile -ExecutionPolicy Bypass -STA -File `"$PSCommandPath`""
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $arguments | Out-Null
    } catch {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show('WinConf 需要管理员权限才能读取和修改系统配置。', 'WinConf', 'OK', 'Warning') | Out-Null
    }
    exit
}

$root = Split-Path $PSScriptRoot -Parent
$mainScript = Join-Path $PSScriptRoot 'winconf.ps1'
$logFile = 'C:\ProgramData\WinConf\winconf.log'

. "$PSScriptRoot\lib\Logger.ps1"
. "$PSScriptRoot\lib\Snapshot.ps1"
. "$PSScriptRoot\lib\Registry.ps1"
. "$PSScriptRoot\lib\Service.ps1"
. "$PSScriptRoot\WinConf.Catalog.ps1"

foreach ($moduleFile in @('Power.ps1', 'ScreenLock.ps1', 'WindowsUpdate.ps1', 'WindowsRestore.ps1', 'Cortana.ps1', 'Notifications.ps1', 'Privacy.ps1', 'UI.ps1')) {
    . "$PSScriptRoot\modules\$moduleFile"
}
. "$PSScriptRoot\lib\State.ps1"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:Language = 'en-US'
$script:Catalog = @(Get-WinConfModuleCatalog -Language $script:Language)
$script:SelectedModule = $null
$script:BeforeState = @()
$script:AfterState = @()
$script:ActiveProcess = $null
$script:RunStartedAt = $null
$script:RunMode = 'Apply'
$script:LastAppliedBeforeState = @{}
$script:ChangingLanguage = $false

$script:Strings = @{
    'en-US' = @{
        FormTitle='WinConf Windows Configuration Center'; HeaderTitle='WinConf Configuration Center'; Subtitle='Select a configuration, review current state, and compare verified before-and-after results'
        Admin='Administrator'; NavTitle='Configuration Areas'; Run='Run Configuration'; Restore='Restore Configuration'; Refresh='Refresh'; DryRun='Preview only (no changes)'
        StateTab='State Comparison'; LogTab='Run Log'; DetailPrompt='Select a row to view its description.'; SettingManaged='This setting is managed by the selected configuration module.'
        ColSetting='Setting'; ColBefore='Before'; ColAfter='After'; ColTarget='Target'; ColResult='Result'; Ready='Ready'; NoticePrefix='Note: '
        NotApplicable='Not applicable'; Compliant='Compliant'; Pending='Pending'; CompliantNoChange='Compliant (no change)'; NoChange='No change'; ReachedTarget='Target reached'; ChangedNotTarget='Changed, target not reached'
        RestoreNoChange='No change'; Restored='Original value restored'; RestoreMismatch='Changed, original value not restored'; RestoreTarget='Original value'
        NoLog='No run log is available yet.'; ReadLogFailed='Unable to read the log: {0}'; ReadStateFailed='Unable to read state: {0}'; Reading='Reading “{0}” system state…'; ReadCount='Read {0} state items'
        ConfirmApply='Run “{0}” and modify system configuration?'; ConfirmApplyTitle='Confirm configuration'; ConfirmRestore='Restore “{0}” to the values recorded immediately before it was run?'; ConfirmRestoreTitle='Confirm restore'
        PreviewMode='preview'; ApplyMode='configuration'; RestoreMode='restore'; Running='Running {0} for “{1}”…'; RunningElapsed='Running “{0}”… {1} seconds elapsed'
        StartFailed='Unable to start the configuration script: {0}'; RunFailedTitle='Run failed'; PreviewComplete='Preview complete. The system was not changed.'; ApplyComplete='Configuration complete. Before-and-after results are shown.'; RestoreComplete='Restore complete. Before-and-after results are shown.'; RestorePreviewComplete='Restore preview complete. The system was not changed.'
        ScriptError='The script returned exit code {0}. See the run log.'; RestoreUnavailable='No restorable snapshot is available for this configuration.'; RestoreUnavailableTitle='Restore unavailable'
        Closing='A configuration script is still running. Closing the window will not stop it. Close anyway?'; ClosingTitle='Script is running'
    }
    'zh-CN' = @{
        FormTitle='WinConf Windows 配置中心'; HeaderTitle='WinConf 配置中心'; Subtitle='选择配置项，核对当前状态，并查看执行前后的真实结果'
        Admin='管理员模式'; NavTitle='配置项目'; Run='运行此配置项'; Restore='恢复此配置项'; Refresh='刷新状态'; DryRun='仅预演（不修改系统）'
        StateTab='状态对比'; LogTab='运行日志'; DetailPrompt='选择表格中的设置可查看说明。'; SettingManaged='该设置由对应模块脚本统一管理。'
        ColSetting='配置设置'; ColBefore='运行前'; ColAfter='运行后'; ColTarget='目标值'; ColResult='结果'; Ready='就绪'; NoticePrefix='注意：'
        NotApplicable='不适用'; Compliant='已符合'; Pending='待配置'; CompliantNoChange='已符合（无变化）'; NoChange='未变化'; ReachedTarget='已达到目标'; ChangedNotTarget='已变化，未达到目标'
        RestoreNoChange='无变化'; Restored='已恢复原始值'; RestoreMismatch='已变化，但未恢复原始值'; RestoreTarget='原始值'
        NoLog='尚无运行日志。'; ReadLogFailed='读取日志失败：{0}'; ReadStateFailed='读取状态失败：{0}'; Reading='正在读取「{0}」的系统状态…'; ReadCount='已读取 {0} 项状态'
        ConfirmApply='即将运行「{0}」并修改系统配置，是否继续？'; ConfirmApplyTitle='确认运行配置'; ConfirmRestore='是否将「{0}」恢复到运行前记录的配置值？'; ConfirmRestoreTitle='确认恢复配置'
        PreviewMode='预演'; ApplyMode='配置'; RestoreMode='恢复'; Running='正在{0}「{1}」…'; RunningElapsed='正在运行「{0}」… 已用时 {1} 秒'
        StartFailed='无法启动配置脚本：{0}'; RunFailedTitle='运行失败'; PreviewComplete='预演完成，系统未被修改'; ApplyComplete='配置完成，已显示运行前后对比'; RestoreComplete='恢复完成，已显示恢复前后对比'; RestorePreviewComplete='恢复预演完成，系统未被修改'
        ScriptError='配置脚本返回错误（退出代码 {0}），请查看运行日志'; RestoreUnavailable='当前配置项没有可恢复的快照。'; RestoreUnavailableTitle='无法恢复'
        Closing='配置脚本仍在运行。关闭界面不会中断后台配置，是否关闭？'; ClosingTitle='脚本正在运行'
    }
}

function Get-WinConfText {
    param([string] $Key, [object[]] $Arguments = @())
    $value = [string]$script:Strings[$script:Language][$Key]
    if ($Arguments.Count -gt 0) { return ($value -f $Arguments) }
    return $value
}

$fontFamily = 'Microsoft YaHei UI'
$navy       = [Drawing.Color]::FromArgb(28, 52, 91)
$blue       = [Drawing.Color]::FromArgb(39, 105, 180)
$lightBlue  = [Drawing.Color]::FromArgb(234, 242, 252)
$pageGray   = [Drawing.Color]::FromArgb(245, 247, 250)
$borderGray = [Drawing.Color]::FromArgb(218, 223, 230)
$textGray   = [Drawing.Color]::FromArgb(78, 85, 96)
$success    = [Drawing.Color]::FromArgb(225, 244, 232)
$warning    = [Drawing.Color]::FromArgb(255, 244, 214)
$muted      = [Drawing.Color]::FromArgb(238, 240, 243)

$form = [Windows.Forms.Form]::new()
$form.Text = Get-WinConfText 'FormTitle'
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = [Drawing.Size]::new(1040, 680)
$form.Size = [Drawing.Size]::new(1240, 800)
$form.BackColor = $pageGray
$form.Font = [Drawing.Font]::new($fontFamily, 9)
$form.AutoScaleMode = 'Dpi'

$rootLayout = [Windows.Forms.TableLayoutPanel]::new()
$rootLayout.Dock = 'Fill'
$rootLayout.ColumnCount = 1
$rootLayout.RowCount = 3
[void]$rootLayout.ColumnStyles.Add([Windows.Forms.ColumnStyle]::new([Windows.Forms.SizeType]::Percent, 100))
[void]$rootLayout.RowStyles.Add([Windows.Forms.RowStyle]::new([Windows.Forms.SizeType]::Absolute, 78))
[void]$rootLayout.RowStyles.Add([Windows.Forms.RowStyle]::new([Windows.Forms.SizeType]::Percent, 100))
[void]$rootLayout.RowStyles.Add([Windows.Forms.RowStyle]::new([Windows.Forms.SizeType]::Absolute, 24))
$form.Controls.Add($rootLayout)

$header = [Windows.Forms.Panel]::new()
$header.Dock = 'Top'
$header.Height = 78
$header.BackColor = $navy
$header.Margin = [Windows.Forms.Padding]::new(0)
$rootLayout.Controls.Add($header, 0, 0)

$title = [Windows.Forms.Label]::new()
$title.AutoSize = $true
$title.Location = [Drawing.Point]::new(24, 13)
$title.Font = [Drawing.Font]::new($fontFamily, 20, [Drawing.FontStyle]::Bold)
$title.ForeColor = [Drawing.Color]::White
$title.Text = Get-WinConfText 'HeaderTitle'
$header.Controls.Add($title)

$subtitle = [Windows.Forms.Label]::new()
$subtitle.AutoSize = $true
$subtitle.Location = [Drawing.Point]::new(27, 50)
$subtitle.ForeColor = [Drawing.Color]::FromArgb(207, 220, 239)
$subtitle.Text = Get-WinConfText 'Subtitle'
$header.Controls.Add($subtitle)

$adminBadge = [Windows.Forms.Label]::new()
$adminBadge.AutoSize = $false
$adminBadge.Size = [Drawing.Size]::new(116, 30)
$adminBadge.Anchor = 'Top,Right'
$adminBadge.Location = [Drawing.Point]::new($form.ClientSize.Width - 260, 23)
$adminBadge.TextAlign = 'MiddleCenter'
$adminBadge.BackColor = [Drawing.Color]::FromArgb(48, 76, 120)
$adminBadge.ForeColor = [Drawing.Color]::White
$adminBadge.Text = Get-WinConfText 'Admin'
$header.Controls.Add($adminBadge)

$languageBox = [Windows.Forms.ComboBox]::new()
$languageBox.DropDownStyle = 'DropDownList'
$languageBox.Size = [Drawing.Size]::new(104, 30)
$languageBox.Anchor = 'Top,Right'
$languageBox.Location = [Drawing.Point]::new($form.ClientSize.Width - 128, 23)
$languageBox.Font = [Drawing.Font]::new($fontFamily, 9)
[void]$languageBox.Items.Add('English')
[void]$languageBox.Items.Add('中文')
$header.Controls.Add($languageBox)

$split = [Windows.Forms.SplitContainer]::new()
$split.Dock = 'Fill'
$split.FixedPanel = 'Panel1'
$split.SplitterDistance = 275
$split.SplitterWidth = 1
$split.BackColor = $borderGray
$split.Margin = [Windows.Forms.Padding]::new(0)
$rootLayout.Controls.Add($split, 0, 1)

$leftPanel = $split.Panel1
$leftPanel.BackColor = [Drawing.Color]::White
$leftPanel.Padding = [Windows.Forms.Padding]::new(14)

$leftLayout = [Windows.Forms.TableLayoutPanel]::new()
$leftLayout.Dock = 'Fill'
$leftLayout.ColumnCount = 1
$leftLayout.RowCount = 2
[void]$leftLayout.ColumnStyles.Add([Windows.Forms.ColumnStyle]::new([Windows.Forms.SizeType]::Percent, 100))
[void]$leftLayout.RowStyles.Add([Windows.Forms.RowStyle]::new([Windows.Forms.SizeType]::Absolute, 38))
[void]$leftLayout.RowStyles.Add([Windows.Forms.RowStyle]::new([Windows.Forms.SizeType]::Percent, 100))
$leftPanel.Controls.Add($leftLayout)

$navTitle = [Windows.Forms.Label]::new()
$navTitle.Dock = 'Top'
$navTitle.Height = 38
$navTitle.Font = [Drawing.Font]::new($fontFamily, 11, [Drawing.FontStyle]::Bold)
$navTitle.ForeColor = $navy
$navTitle.Text = Get-WinConfText 'NavTitle'
$navTitle.TextAlign = 'MiddleLeft'
$leftLayout.Controls.Add($navTitle, 0, 0)

$moduleList = [Windows.Forms.ListBox]::new()
$moduleList.Dock = 'Fill'
$moduleList.BorderStyle = 'None'
$moduleList.BackColor = [Drawing.Color]::White
$moduleList.ForeColor = $textGray
$moduleList.Font = [Drawing.Font]::new($fontFamily, 11)
$moduleList.IntegralHeight = $false
$moduleList.ItemHeight = 45
$moduleList.DisplayMember = 'DisplayName'
$leftLayout.Controls.Add($moduleList, 0, 1)

$rightPanel = $split.Panel2
$rightPanel.BackColor = $pageGray
$rightPanel.Padding = [Windows.Forms.Padding]::new(18, 14, 18, 10)

$contentLayout = [Windows.Forms.TableLayoutPanel]::new()
$contentLayout.Dock = 'Fill'
$contentLayout.ColumnCount = 1
$contentLayout.RowCount = 2
[void]$contentLayout.ColumnStyles.Add([Windows.Forms.ColumnStyle]::new([Windows.Forms.SizeType]::Percent, 100))
[void]$contentLayout.RowStyles.Add([Windows.Forms.RowStyle]::new([Windows.Forms.SizeType]::Absolute, 215))
[void]$contentLayout.RowStyles.Add([Windows.Forms.RowStyle]::new([Windows.Forms.SizeType]::Percent, 100))
$rightPanel.Controls.Add($contentLayout)

$infoPanel = [Windows.Forms.Panel]::new()
$infoPanel.Dock = 'Top'
$infoPanel.Height = 215
$infoPanel.BackColor = [Drawing.Color]::White
$infoPanel.Padding = [Windows.Forms.Padding]::new(18, 12, 18, 10)
$infoPanel.Margin = [Windows.Forms.Padding]::new(0, 0, 0, 10)
$contentLayout.Controls.Add($infoPanel, 0, 0)

$infoLayout = [Windows.Forms.TableLayoutPanel]::new()
$infoLayout.Dock = 'Fill'
$infoLayout.ColumnCount = 1
$infoLayout.RowCount = 4
[void]$infoLayout.ColumnStyles.Add([Windows.Forms.ColumnStyle]::new([Windows.Forms.SizeType]::Percent, 100))
[void]$infoLayout.RowStyles.Add([Windows.Forms.RowStyle]::new([Windows.Forms.SizeType]::Absolute, 34))
[void]$infoLayout.RowStyles.Add([Windows.Forms.RowStyle]::new([Windows.Forms.SizeType]::Absolute, 48))
[void]$infoLayout.RowStyles.Add([Windows.Forms.RowStyle]::new([Windows.Forms.SizeType]::Absolute, 32))
[void]$infoLayout.RowStyles.Add([Windows.Forms.RowStyle]::new([Windows.Forms.SizeType]::Percent, 100))
$infoPanel.Controls.Add($infoLayout)

$moduleTitle = [Windows.Forms.Label]::new()
$moduleTitle.Dock = 'Top'
$moduleTitle.Height = 34
$moduleTitle.Font = [Drawing.Font]::new($fontFamily, 16, [Drawing.FontStyle]::Bold)
$moduleTitle.ForeColor = $navy
$infoLayout.Controls.Add($moduleTitle, 0, 0)

$moduleDescription = [Windows.Forms.Label]::new()
$moduleDescription.Dock = 'Top'
$moduleDescription.Height = 48
$moduleDescription.ForeColor = $textGray
$moduleDescription.Font = [Drawing.Font]::new($fontFamily, 9.5)
$moduleDescription.Padding = [Windows.Forms.Padding]::new(0, 3, 0, 0)
$infoLayout.Controls.Add($moduleDescription, 0, 1)

$moduleNotice = [Windows.Forms.Label]::new()
$moduleNotice.Dock = 'Top'
$moduleNotice.Height = 32
$moduleNotice.BackColor = [Drawing.Color]::FromArgb(255, 247, 224)
$moduleNotice.ForeColor = [Drawing.Color]::FromArgb(122, 82, 18)
$moduleNotice.Padding = [Windows.Forms.Padding]::new(9, 7, 6, 5)
$infoLayout.Controls.Add($moduleNotice, 0, 2)

$actionPanel = [Windows.Forms.Panel]::new()
$actionPanel.Dock = 'Fill'
$infoLayout.Controls.Add($actionPanel, 0, 3)

$runButton = [Windows.Forms.Button]::new()
$runButton.Text = Get-WinConfText 'Run'
$runButton.Size = [Drawing.Size]::new(132, 34)
$runButton.Location = [Drawing.Point]::new(0, 4)
$runButton.FlatStyle = 'Flat'
$runButton.FlatAppearance.BorderSize = 0
$runButton.BackColor = $blue
$runButton.ForeColor = [Drawing.Color]::White
$runButton.Font = [Drawing.Font]::new($fontFamily, 9, [Drawing.FontStyle]::Bold)
$actionPanel.Controls.Add($runButton)

$restoreButton = [Windows.Forms.Button]::new()
$restoreButton.Text = Get-WinConfText 'Restore'
$restoreButton.Size = [Drawing.Size]::new(122, 34)
$restoreButton.Location = [Drawing.Point]::new(142, 4)
$restoreButton.FlatStyle = 'Flat'
$restoreButton.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(208, 151, 43)
$restoreButton.BackColor = [Drawing.Color]::FromArgb(255, 247, 224)
$restoreButton.ForeColor = [Drawing.Color]::FromArgb(122, 82, 18)
$restoreButton.Enabled = $false
$actionPanel.Controls.Add($restoreButton)

$refreshButton = [Windows.Forms.Button]::new()
$refreshButton.Text = Get-WinConfText 'Refresh'
$refreshButton.Size = [Drawing.Size]::new(96, 34)
$refreshButton.Location = [Drawing.Point]::new(274, 4)
$refreshButton.FlatStyle = 'Flat'
$refreshButton.FlatAppearance.BorderColor = $borderGray
$refreshButton.BackColor = [Drawing.Color]::White
$refreshButton.ForeColor = $textGray
$actionPanel.Controls.Add($refreshButton)

$dryRunCheck = [Windows.Forms.CheckBox]::new()
$dryRunCheck.AutoSize = $true
$dryRunCheck.Location = [Drawing.Point]::new(382, 13)
$dryRunCheck.Text = Get-WinConfText 'DryRun'
$dryRunCheck.ForeColor = $textGray
$actionPanel.Controls.Add($dryRunCheck)

$progress = [Windows.Forms.ProgressBar]::new()
$progress.Anchor = 'Top,Right'
$progress.Size = [Drawing.Size]::new(155, 8)
$progress.Location = [Drawing.Point]::new($infoPanel.ClientSize.Width - 191, 17)
$progress.Style = 'Marquee'
$progress.MarqueeAnimationSpeed = 30
$progress.Visible = $false
$actionPanel.Controls.Add($progress)

$tabs = [Windows.Forms.TabControl]::new()
$tabs.Dock = 'Fill'
$tabs.Font = [Drawing.Font]::new($fontFamily, 9.5)
$tabs.Padding = [Drawing.Point]::new(15, 6)
$tabs.Margin = [Windows.Forms.Padding]::new(0)
$contentLayout.Controls.Add($tabs, 0, 1)

$stateTab = [Windows.Forms.TabPage]::new((Get-WinConfText 'StateTab'))
$stateTab.BackColor = [Drawing.Color]::White
$stateTab.Padding = [Windows.Forms.Padding]::new(8)
$tabs.TabPages.Add($stateTab) | Out-Null

$logTab = [Windows.Forms.TabPage]::new((Get-WinConfText 'LogTab'))
$logTab.BackColor = [Drawing.Color]::White
$logTab.Padding = [Windows.Forms.Padding]::new(8)
$tabs.TabPages.Add($logTab) | Out-Null

$settingDetail = [Windows.Forms.Label]::new()
$settingDetail.Dock = 'Bottom'
$settingDetail.Height = 40
$settingDetail.BackColor = $lightBlue
$settingDetail.ForeColor = $textGray
$settingDetail.Padding = [Windows.Forms.Padding]::new(10, 10, 8, 6)
$settingDetail.Text = Get-WinConfText 'DetailPrompt'
$stateTab.Controls.Add($settingDetail)

$grid = [Windows.Forms.DataGridView]::new()
$grid.Dock = 'Fill'
$grid.BackgroundColor = [Drawing.Color]::White
$grid.BorderStyle = 'None'
$grid.AllowUserToAddRows = $false
$grid.AllowUserToDeleteRows = $false
$grid.AllowUserToResizeRows = $false
$grid.ReadOnly = $true
$grid.RowHeadersVisible = $false
$grid.SelectionMode = 'FullRowSelect'
$grid.MultiSelect = $false
$grid.AutoSizeColumnsMode = 'Fill'
$grid.EnableHeadersVisualStyles = $false
$grid.ColumnHeadersHeight = 38
$grid.ColumnHeadersDefaultCellStyle.BackColor = $navy
$grid.ColumnHeadersDefaultCellStyle.ForeColor = [Drawing.Color]::White
$grid.ColumnHeadersDefaultCellStyle.Font = [Drawing.Font]::new($fontFamily, 9, [Drawing.FontStyle]::Bold)
$grid.DefaultCellStyle.SelectionBackColor = [Drawing.Color]::FromArgb(210, 226, 247)
$grid.DefaultCellStyle.SelectionForeColor = $navy
$grid.DefaultCellStyle.Padding = [Windows.Forms.Padding]::new(4)
$grid.RowTemplate.Height = 34
$stateTab.Controls.Add($grid)
$grid.BringToFront()

$columns = @(
    @{ Name = 'Setting'; Header = (Get-WinConfText 'ColSetting'); Weight = 26 },
    @{ Name = 'Before'; Header = (Get-WinConfText 'ColBefore'); Weight = 20 },
    @{ Name = 'After'; Header = (Get-WinConfText 'ColAfter'); Weight = 20 },
    @{ Name = 'Target'; Header = (Get-WinConfText 'ColTarget'); Weight = 18 },
    @{ Name = 'Result'; Header = (Get-WinConfText 'ColResult'); Weight = 16 }
)
foreach ($column in $columns) {
    $index = $grid.Columns.Add($column.Name, $column.Header)
    $grid.Columns[$index].FillWeight = $column.Weight
    $grid.Columns[$index].SortMode = 'NotSortable'
}

$logBox = [Windows.Forms.RichTextBox]::new()
$logBox.Dock = 'Fill'
$logBox.ReadOnly = $true
$logBox.BorderStyle = 'None'
$logBox.BackColor = [Drawing.Color]::FromArgb(30, 34, 42)
$logBox.ForeColor = [Drawing.Color]::FromArgb(220, 225, 232)
$logBox.Font = [Drawing.Font]::new('Consolas', 9)
$logBox.WordWrap = $false
$logTab.Controls.Add($logBox)

$statusStrip = [Windows.Forms.StatusStrip]::new()
$statusStrip.SizingGrip = $false
$statusStrip.BackColor = [Drawing.Color]::White
$statusText = [Windows.Forms.ToolStripStatusLabel]::new()
$statusText.Spring = $true
$statusText.TextAlign = 'MiddleLeft'
$statusText.Text = Get-WinConfText 'Ready'
$statusStrip.Items.Add($statusText) | Out-Null
$statusStrip.Margin = [Windows.Forms.Padding]::new(0)
$rootLayout.Controls.Add($statusStrip, 0, 2)

function Set-WinConfBusy {
    param([bool] $Busy)
    $runButton.Enabled = -not $Busy
    $restoreButton.Enabled = (-not $Busy) -and ($script:SelectedModule -and (Test-SnapshotAvailable -Module $script:SelectedModule.Name))
    $refreshButton.Enabled = -not $Busy
    $moduleList.Enabled = -not $Busy
    $dryRunCheck.Enabled = -not $Busy
    $languageBox.Enabled = -not $Busy
    $progress.Visible = $Busy
}

function Update-WinConfRestoreAvailability {
    $restoreButton.Enabled = ($null -ne $script:SelectedModule) -and (Test-SnapshotAvailable -Module $script:SelectedModule.Name) -and ($null -eq $script:ActiveProcess)
}

function Set-WinConfSplitLayout {
    if ($split.Width -ge 800) {
        $split.Panel1MinSize = 240
        $split.Panel2MinSize = 520
        $desiredDistance = [math]::Min(300, [math]::Max(260, [int]($split.Width * 0.24)))
        if ($split.SplitterDistance -ne $desiredDistance) {
            $split.SplitterDistance = $desiredDistance
        }
    }
}

function Get-WinConfStateSafe {
    param([string] $Module)
    try {
        return @(Get-WinConfModuleState -Module $Module -Language $script:Language)
    } catch {
        $statusText.Text = Get-WinConfText 'ReadStateFailed' @($_.Exception.Message)
        return @()
    }
}

function Show-WinConfComparison {
    param(
        [object[]] $Before,
        [object[]] $After = @(),
        [ValidateSet('Apply', 'Restore')]
        [string] $Mode = 'Apply'
    )

    $grid.Rows.Clear()
    $afterByKey = @{}
    foreach ($item in $After) { $afterByKey[$item.Key] = $item }

    foreach ($beforeItem in $Before) {
        $afterItem = if ($afterByKey.ContainsKey($beforeItem.Key)) { $afterByKey[$beforeItem.Key] } else { $null }
        $afterValue = if ($afterItem) { $afterItem.Current } else { '—' }

        if (-not $afterItem) {
            $result = if ($beforeItem.NotApplicable) { Get-WinConfText 'NotApplicable' } elseif ($beforeItem.Compliant) { Get-WinConfText 'Compliant' } else { Get-WinConfText 'Pending' }
            $rowColor = if ($beforeItem.NotApplicable) { $muted } elseif ($beforeItem.Compliant) { $success } else { [Drawing.Color]::White }
        } elseif ($afterItem.NotApplicable) {
            $result = Get-WinConfText 'NotApplicable'
            $rowColor = $muted
        } elseif ([string]$beforeItem.Current -ceq [string]$afterItem.Current) {
            if ($Mode -eq 'Restore') {
                $result = if ($afterItem.Compliant) { Get-WinConfText 'Restored' } else { Get-WinConfText 'RestoreNoChange' }
            } else {
                $result = if ($afterItem.Compliant) { Get-WinConfText 'CompliantNoChange' } else { Get-WinConfText 'NoChange' }
            }
            $rowColor = if ($afterItem.Compliant) { $success } else { $warning }
        } elseif ($afterItem.Compliant) {
            $result = if ($Mode -eq 'Restore') { Get-WinConfText 'Restored' } else { Get-WinConfText 'ReachedTarget' }
            $rowColor = $success
        } else {
            $result = if ($Mode -eq 'Restore') { Get-WinConfText 'RestoreMismatch' } else { Get-WinConfText 'ChangedNotTarget' }
            $rowColor = $warning
        }

        $rowIndex = $grid.Rows.Add($beforeItem.Label, $beforeItem.Current, $afterValue, $beforeItem.Target, $result)
        $row = $grid.Rows[$rowIndex]
        $row.DefaultCellStyle.BackColor = $rowColor
        $row.Tag = $beforeItem.Description
        foreach ($cell in $row.Cells) { $cell.ToolTipText = $beforeItem.Description }
    }
}

function Refresh-WinConfLog {
    if (-not (Test-Path $logFile)) {
        $logBox.Text = Get-WinConfText 'NoLog'
        return
    }

    try {
        $lines = @(Get-Content -Path $logFile -Encoding UTF8 -Tail 250)
        $logBox.Text = $lines -join [Environment]::NewLine
        $logBox.SelectionStart = $logBox.TextLength
        $logBox.ScrollToCaret()
    } catch {
        $logBox.Text = Get-WinConfText 'ReadLogFailed' @($_.Exception.Message)
    }
}

function Get-WinConfRestoreComparisonBase {
    param([string] $Module)

    $current = @(Get-WinConfStateSafe -Module $Module)
    $previous = if ($script:LastAppliedBeforeState.ContainsKey($Module)) { @($script:LastAppliedBeforeState[$Module]) } else { @() }
    $previousByKey = @{}
    foreach ($item in $previous) { $previousByKey[$item.Key] = $item }

    if ($previousByKey.Count -gt 0) {
        $rows = [System.Collections.Generic.List[object]]::new()
        foreach ($item in $current) {
            if (-not $previousByKey.ContainsKey($item.Key)) { continue }
            $original = $previousByKey[$item.Key]
            $rows.Add((New-WinConfStateRow -Key $item.Key -Label $item.Label -Current $item.RawCurrent -Target $original.RawCurrent -Description $item.Description -Language $script:Language -NotApplicable:$item.NotApplicable))
        }
        return $rows
    }

    return @(Get-WinConfRestoreTargetState -Module $Module -Language $script:Language)
}

function Select-WinConfModule {
    param($Module)
    if ($null -eq $Module) { return }

    $script:SelectedModule = $Module
    $moduleTitle.Text = $Module.DisplayName
    $moduleDescription.Text = $Module.Description
    $moduleNotice.Text = "$(Get-WinConfText 'NoticePrefix')$($Module.Notice)"
    $statusText.Text = Get-WinConfText 'Reading' @($Module.DisplayName)
    [Windows.Forms.Application]::DoEvents()
    $script:BeforeState = @(Get-WinConfStateSafe -Module $Module.Name)
    $script:RunMode = 'Apply'
    Show-WinConfComparison -Before $script:BeforeState -Mode 'Apply'
    Update-WinConfRestoreAvailability
    $statusText.Text = Get-WinConfText 'ReadCount' @($script:BeforeState.Count)
}

function Start-WinConfProcess {
    param(
        [ValidateSet('Apply', 'Restore')]
        [string] $Mode = 'Apply'
    )

    if ($null -eq $script:SelectedModule -or $null -ne $script:ActiveProcess) { return }

    if ($Mode -eq 'Restore' -and -not (Test-SnapshotAvailable -Module $script:SelectedModule.Name)) {
        [Windows.Forms.MessageBox]::Show((Get-WinConfText 'RestoreUnavailable'), (Get-WinConfText 'RestoreUnavailableTitle'), 'OK', 'Information') | Out-Null
        return
    }

    if (-not $dryRunCheck.Checked) {
        $messageKey = if ($Mode -eq 'Restore') { 'ConfirmRestore' } else { 'ConfirmApply' }
        $titleKey = if ($Mode -eq 'Restore') { 'ConfirmRestoreTitle' } else { 'ConfirmApplyTitle' }
        $answer = [Windows.Forms.MessageBox]::Show(
            (Get-WinConfText $messageKey @($script:SelectedModule.DisplayName)),
            (Get-WinConfText $titleKey),
            [Windows.Forms.MessageBoxButtons]::YesNo,
            [Windows.Forms.MessageBoxIcon]::Warning,
            [Windows.Forms.MessageBoxDefaultButton]::Button2
        )
        if ($answer -ne [Windows.Forms.DialogResult]::Yes) { return }
    }

    $script:RunMode = $Mode
    $script:BeforeState = if ($Mode -eq 'Restore') { @(Get-WinConfRestoreComparisonBase -Module $script:SelectedModule.Name) } else { @(Get-WinConfStateSafe -Module $script:SelectedModule.Name) }
    Show-WinConfComparison -Before $script:BeforeState -Mode $Mode
    $tabs.SelectedTab = $stateTab

    if ($Mode -eq 'Restore') {
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$mainScript`" -Module $($script:SelectedModule.Name) -Rollback -Verbose"
    } else {
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$mainScript`" -Module $($script:SelectedModule.Name) -Verbose"
    }
    if ($dryRunCheck.Checked) { $arguments += ' -DryRun' }

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'powershell.exe'
    $startInfo.Arguments = $arguments
    $startInfo.WorkingDirectory = $root
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.WindowStyle = 'Hidden'

    try {
        $script:ActiveProcess = [Diagnostics.Process]::Start($startInfo)
        $script:RunStartedAt = Get-Date
        Set-WinConfBusy -Busy $true
        $modeText = if ($Mode -eq 'Restore') { Get-WinConfText 'RestoreMode' } elseif ($dryRunCheck.Checked) { Get-WinConfText 'PreviewMode' } else { Get-WinConfText 'ApplyMode' }
        $statusText.Text = Get-WinConfText 'Running' @($modeText, $script:SelectedModule.DisplayName)
    } catch {
        $script:ActiveProcess = $null
        Set-WinConfBusy -Busy $false
        [Windows.Forms.MessageBox]::Show((Get-WinConfText 'StartFailed' @($_.Exception.Message)), (Get-WinConfText 'RunFailedTitle'), 'OK', 'Error') | Out-Null
    }
}

function Start-WinConfModuleRun { Start-WinConfProcess -Mode 'Apply' }
function Start-WinConfRestore { Start-WinConfProcess -Mode 'Restore' }

function Set-WinConfLanguage {
    param([ValidateSet('en-US', 'zh-CN')][string] $Language)
    if ($script:ChangingLanguage -or $script:Language -eq $Language) { return }

    $selectedName = if ($script:SelectedModule) { $script:SelectedModule.Name } else { $null }
    $script:ChangingLanguage = $true
    try {
        $script:Language = $Language
        $script:Catalog = @(Get-WinConfModuleCatalog -Language $Language)
        $form.Text = Get-WinConfText 'FormTitle'
        $title.Text = Get-WinConfText 'HeaderTitle'
        $subtitle.Text = Get-WinConfText 'Subtitle'
        $adminBadge.Text = Get-WinConfText 'Admin'
        $navTitle.Text = Get-WinConfText 'NavTitle'
        $runButton.Text = Get-WinConfText 'Run'
        $restoreButton.Text = Get-WinConfText 'Restore'
        $refreshButton.Text = Get-WinConfText 'Refresh'
        $dryRunCheck.Text = Get-WinConfText 'DryRun'
        $stateTab.Text = Get-WinConfText 'StateTab'
        $logTab.Text = Get-WinConfText 'LogTab'
        $settingDetail.Text = Get-WinConfText 'DetailPrompt'
        $grid.Columns['Setting'].HeaderText = Get-WinConfText 'ColSetting'
        $grid.Columns['Before'].HeaderText = Get-WinConfText 'ColBefore'
        $grid.Columns['After'].HeaderText = Get-WinConfText 'ColAfter'
        $grid.Columns['Target'].HeaderText = Get-WinConfText 'ColTarget'
        $grid.Columns['Result'].HeaderText = Get-WinConfText 'ColResult'

        $moduleList.Items.Clear()
        foreach ($module in $script:Catalog) { [void]$moduleList.Items.Add($module) }
        if ($selectedName) {
            for ($i = 0; $i -lt $moduleList.Items.Count; $i++) {
                if ($moduleList.Items[$i].Name -eq $selectedName) { $moduleList.SelectedIndex = $i; break }
            }
        } elseif ($moduleList.Items.Count -gt 0) {
            $moduleList.SelectedIndex = 0
        }
        if ($moduleList.SelectedItem) {
            Select-WinConfModule -Module $moduleList.SelectedItem
        }
        Refresh-WinConfLog
    } finally {
        $script:ChangingLanguage = $false
    }
}

$processTimer = [Windows.Forms.Timer]::new()
$processTimer.Interval = 300
$processTimer.Add_Tick({
    if ($null -eq $script:ActiveProcess) { return }

    if (-not $script:ActiveProcess.HasExited) {
        $elapsed = [math]::Floor(((Get-Date) - $script:RunStartedAt).TotalSeconds)
        $statusText.Text = Get-WinConfText 'RunningElapsed' @($script:SelectedModule.DisplayName, $elapsed)
        return
    }

    $exitCode = $script:ActiveProcess.ExitCode
    $script:ActiveProcess.Dispose()
    $script:ActiveProcess = $null
    Set-WinConfBusy -Busy $false

    $afterState = @(Get-WinConfStateSafe -Module $script:SelectedModule.Name)
    $script:AfterState = $afterState
    Show-WinConfComparison -Before $script:BeforeState -After $afterState -Mode $script:RunMode
    Refresh-WinConfLog

    if ($exitCode -eq 0) {
        if ($script:RunMode -eq 'Apply' -and -not $dryRunCheck.Checked) {
            $script:LastAppliedBeforeState[$script:SelectedModule.Name] = @($script:BeforeState)
        }
        if ($script:RunMode -eq 'Restore' -and $dryRunCheck.Checked) {
            $statusText.Text = Get-WinConfText 'RestorePreviewComplete'
        } elseif ($script:RunMode -eq 'Restore') {
            $statusText.Text = Get-WinConfText 'RestoreComplete'
        } elseif ($dryRunCheck.Checked) {
            $statusText.Text = Get-WinConfText 'PreviewComplete'
        } else {
            $statusText.Text = Get-WinConfText 'ApplyComplete'
        }
        Update-WinConfRestoreAvailability
    } else {
        $statusText.Text = Get-WinConfText 'ScriptError' @($exitCode)
        $tabs.SelectedTab = $logTab
    }
})
$processTimer.Start()

$moduleList.Add_SelectedIndexChanged({
    if ($moduleList.SelectedItem -and $null -eq $script:ActiveProcess -and -not $script:ChangingLanguage) {
        Select-WinConfModule -Module $moduleList.SelectedItem
    }
})

$runButton.Add_Click({ Start-WinConfModuleRun })
$restoreButton.Add_Click({ Start-WinConfRestore })
$refreshButton.Add_Click({
    if ($script:SelectedModule) { Select-WinConfModule -Module $script:SelectedModule }
    Refresh-WinConfLog
})

$grid.Add_SelectionChanged({
    if ($grid.SelectedRows.Count -gt 0) {
        $description = [string]$grid.SelectedRows[0].Tag
        $settingDetail.Text = if ([string]::IsNullOrWhiteSpace($description)) { Get-WinConfText 'SettingManaged' } else { $description }
    }
})

$languageBox.Add_SelectedIndexChanged({
    if ($languageBox.SelectedIndex -eq 0) { Set-WinConfLanguage -Language 'en-US' }
    elseif ($languageBox.SelectedIndex -eq 1) { Set-WinConfLanguage -Language 'zh-CN' }
})

$form.Add_Resize({
    $adminBadge.Left = $header.ClientSize.Width - $adminBadge.Width - $languageBox.Width - 36
    $languageBox.Left = $header.ClientSize.Width - $languageBox.Width - 16
    $progress.Left = $actionPanel.ClientSize.Width - $progress.Width - 12
    Set-WinConfSplitLayout
})

$header.Add_Resize({
    $adminBadge.Left = $header.ClientSize.Width - $adminBadge.Width - $languageBox.Width - 36
    $languageBox.Left = $header.ClientSize.Width - $languageBox.Width - 16
})
$actionPanel.Add_Resize({ $progress.Left = $actionPanel.ClientSize.Width - $progress.Width - 12 })
$form.Add_Shown({ Set-WinConfSplitLayout })

$form.Add_FormClosing({
    if ($null -ne $script:ActiveProcess -and -not $script:ActiveProcess.HasExited) {
        $answer = [Windows.Forms.MessageBox]::Show((Get-WinConfText 'Closing'), (Get-WinConfText 'ClosingTitle'), 'YesNo', 'Warning')
        if ($answer -ne [Windows.Forms.DialogResult]::Yes) { $eventArgs.Cancel = $true }
    }
})

foreach ($module in $script:Catalog) { [void]$moduleList.Items.Add($module) }
Refresh-WinConfLog
if ($moduleList.Items.Count -gt 0) { $moduleList.SelectedIndex = 0 }
$languageBox.SelectedIndex = 0
$form.PerformLayout()
Set-WinConfSplitLayout

if ($SmokeTest) {
    $englishTitle = $moduleTitle.Text
    Set-WinConfLanguage -Language 'zh-CN'
    $chineseTitle = $moduleTitle.Text
    Set-WinConfLanguage -Language 'en-US'
    Write-Output "WinConf GUI smoke test passed: modules=$($moduleList.Items.Count), initial_rows=$($grid.Rows.Count), languages=$englishTitle/$chineseTitle, size=$($form.Width)x$($form.Height), root=$($rootLayout.Width), split=$($split.Width)/$($split.Panel1.Width), distance=$($split.SplitterDistance), info=$($infoPanel.Height), action=$($actionPanel.Height)"
} else {
    [void]$form.ShowDialog()
}
$processTimer.Stop()
$processTimer.Dispose()
$form.Dispose()
