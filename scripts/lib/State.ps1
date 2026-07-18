# State.ps1 - Read-only state probes used by the desktop interface.
# Depends on: Registry.ps1 and all module scripts.

function ConvertTo-WinConfDisplayValue {
    param(
        $Value,
        [ValidateSet('en-US', 'zh-CN')]
        [string] $Language = 'en-US'
    )

    if ($null -eq $Value) { return $(if ($Language -eq 'zh-CN') { '未设置' } else { 'Not set' }) }
    if ($Value -is [bool]) {
        if ($Value) { return $(if ($Language -eq 'zh-CN') { '是' } else { 'Yes' }) }
        return $(if ($Language -eq 'zh-CN') { '否' } else { 'No' })
    }
    if ($Value -eq '未安装') { return $(if ($Language -eq 'zh-CN') { '未安装' } else { 'Not installed' }) }
    switch (([string]$Value).ToLowerInvariant()) {
        'enabled'  { return $(if ($Language -eq 'zh-CN') { '启用' } else { 'Enabled' }) }
        'disabled' { return $(if ($Language -eq 'zh-CN') { '禁用' } else { 'Disabled' }) }
        'running'  { return $(if ($Language -eq 'zh-CN') { '运行中' } else { 'Running' }) }
        'stopped'  { return $(if ($Language -eq 'zh-CN') { '已停止' } else { 'Stopped' }) }
    }
    return [string] $Value
}

function New-WinConfStateRow {
    param(
        [string] $Key,
        [string] $Label,
        $Current,
        $Target,
        [string] $Description = '',
        [ValidateSet('en-US', 'zh-CN')]
        [string] $Language = 'en-US',
        [switch] $NotApplicable
    )

    $currentDisplay = ConvertTo-WinConfDisplayValue -Value $Current -Language $Language
    $targetDisplay  = ConvertTo-WinConfDisplayValue -Value $Target -Language $Language
    $compliant = if ($NotApplicable) { $true } else { [string] $Current -ceq [string] $Target }
    $notApplicableText = if ($Language -eq 'zh-CN') { '不适用' } else { 'Not applicable' }

    return [PSCustomObject]@{
        Key           = $Key
        Label         = $Label
        RawCurrent    = $Current
        RawTarget     = $Target
        Current       = if ($NotApplicable) { $notApplicableText } else { $currentDisplay }
        Target        = if ($NotApplicable) { $notApplicableText } else { $targetDisplay }
        Compliant     = $compliant
        Description   = $Description
        NotApplicable = $NotApplicable.IsPresent
    }
}

function New-WinConfRegistryDefinition {
    param(
        [string] $Path,
        [string] $Name,
        $Value,
        [string] $Label,
        [string] $Description = '',
        $MinBuild = $null,
        $MaxBuild = $null
    )

    return [PSCustomObject]@{
        Path        = $Path
        Name        = $Name
        Value       = $Value
        Label       = $Label
        Description = $Description
        MinBuild    = $MinBuild
        MaxBuild    = $MaxBuild
    }
}

function Get-WinConfSettingLabel {
    param(
        [string] $Name,
        [ValidateSet('en-US', 'zh-CN')]
        [string] $Language = 'en-US'
    )

    $labelsZh = @{
        AllowCortana                       = '允许 Cortana'
        DisableSearchBoxSuggestions        = '搜索框在线建议'
        ShowCortanaButton                  = '任务栏 Cortana 按钮'
        ShowTaskViewButton                 = '任务视图按钮'
        EnableFeeds                        = '资讯和兴趣策略'
        TaskbarDa                          = 'Windows 11 小组件按钮'
        ShellFeedsTaskbarViewMode          = 'Windows 10 资讯入口'
        HideMeetNow                        = '隐藏“立即开会”'
        NoAutoUpdate                       = '自动更新'
        AUOptions                          = '自动更新模式'
        NoAUShutdownOption                 = '关机菜单安装更新'
        NoAUAsDefaultShutdownOption        = '默认关机更新选项'
        NoAutoRebootWithLoggedOnUsers      = '登录用户自动重启'
        SetAutoRestartNotificationDisable  = '自动重启通知'
        SetUpdateNotificationLevel         = '更新通知级别'
        ExcludeWUDriversInQualityUpdate     = '质量更新包含驱动'
        DisableOSUpgrade                   = '系统版本升级'
        RemoveWindowsStore                 = 'Microsoft Store 可用性'
        AutoDownload                       = 'Store 自动下载策略'
        SettingsPageVisibility             = '更新设置页面可见性'
        RestartNotificationsAllowed2       = '重启提醒'
        HideWUXMessages                    = 'Windows Update 消息'
        AllowAutoUpdate                    = '设备自动更新策略'
        DoNotShowUpdateNotifications       = '设备更新通知'
        HideUpdatePowerOption              = '更新电源选项'
        AllowStore                         = '允许 Microsoft Store'
        ScreenSaveActive                   = '屏幕保护程序'
        ScreenSaveTimeOut                  = '屏幕保护等待时间'
        ScreenSaverIsSecure                = '屏保恢复时锁定'
        InactivityTimeoutSecs              = '系统空闲锁定时间'
        DisableNotificationCenter          = '通知中心'
        NoToastApplicationNotification     = '应用横幅通知'
        DisableLockScreenAppNotifications  = '锁屏通知'
        AllowTelemetry                     = '遥测级别'
        PublishUserActivities              = '发布活动历史'
        UploadUserActivities               = '上传活动历史'
        HiberbootEnabled                   = '快速启动'
    }

    $labelsEn = @{
        AllowCortana                       = 'Allow Cortana'
        DisableSearchBoxSuggestions        = 'Web suggestions in Search'
        ShowCortanaButton                  = 'Cortana taskbar button'
        ShowTaskViewButton                 = 'Task View button'
        EnableFeeds                        = 'News and interests policy'
        TaskbarDa                          = 'Windows 11 Widgets button'
        ShellFeedsTaskbarViewMode          = 'Windows 10 news entry'
        HideMeetNow                        = 'Hide Meet Now'
        NoAutoUpdate                       = 'Automatic updates'
        AUOptions                          = 'Automatic update mode'
        NoAUShutdownOption                 = 'Install updates on shutdown'
        NoAUAsDefaultShutdownOption        = 'Default update shutdown option'
        NoAutoRebootWithLoggedOnUsers      = 'Automatic restart with signed-in users'
        SetAutoRestartNotificationDisable  = 'Automatic restart notifications'
        SetUpdateNotificationLevel         = 'Update notification level'
        ExcludeWUDriversInQualityUpdate     = 'Drivers in quality updates'
        DisableOSUpgrade                   = 'Windows version upgrades'
        RemoveWindowsStore                 = 'Microsoft Store availability'
        AutoDownload                       = 'Store automatic download policy'
        SettingsPageVisibility             = 'Update Settings page visibility'
        RestartNotificationsAllowed2       = 'Restart reminders'
        HideWUXMessages                    = 'Windows Update messages'
        AllowAutoUpdate                    = 'Device automatic update policy'
        DoNotShowUpdateNotifications       = 'Device update notifications'
        HideUpdatePowerOption              = 'Update power options'
        AllowStore                         = 'Allow Microsoft Store'
        ScreenSaveActive                   = 'Screen saver'
        ScreenSaveTimeOut                  = 'Screen saver timeout'
        ScreenSaverIsSecure                = 'Lock when screen saver resumes'
        InactivityTimeoutSecs              = 'System idle lock timeout'
        DisableNotificationCenter          = 'Notification Center'
        NoToastApplicationNotification     = 'Application toast notifications'
        DisableLockScreenAppNotifications  = 'Lock-screen notifications'
        AllowTelemetry                     = 'Telemetry level'
        PublishUserActivities              = 'Publish activity history'
        UploadUserActivities               = 'Upload activity history'
        HiberbootEnabled                   = 'Fast Startup'
    }

    $labels = if ($Language -eq 'zh-CN') { $labelsZh } else { $labelsEn }
    if ($labels.ContainsKey($Name)) { return $labels[$Name] }
    return $Name
}

function Get-WinConfSettingDescription {
    param(
        [string] $Label,
        [ValidateSet('en-US', 'zh-CN')]
        [string] $Language = 'en-US'
    )

    if ($Language -eq 'zh-CN') { return "由当前配置模块管理「$Label」。" }
    return "Managed by the selected configuration module: $Label."
}

function Get-WinConfRegistryDefinitions {
    param(
        [Parameter(Mandatory)][string] $Module,
        [ValidateSet('en-US', 'zh-CN')]
        [string] $Language = 'en-US'
    )

    switch ($Module) {
        'Power' {
            $label = Get-WinConfSettingLabel -Name 'HiberbootEnabled' -Language $Language
            return @(
                (New-WinConfRegistryDefinition -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -Value 0 -Label $label -Description (Get-WinConfSettingDescription -Label $label -Language $Language))
            )
        }
        'ScreenLock' {
            $desktop = 'HKCU:\Control Panel\Desktop'
            $policy  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
            return @(
                (New-WinConfRegistryDefinition -Path $desktop -Name 'ScreenSaveActive' -Value '0' -Label (Get-WinConfSettingLabel 'ScreenSaveActive' $Language)),
                (New-WinConfRegistryDefinition -Path $desktop -Name 'ScreenSaveTimeOut' -Value '0' -Label (Get-WinConfSettingLabel 'ScreenSaveTimeOut' $Language)),
                (New-WinConfRegistryDefinition -Path $desktop -Name 'ScreenSaverIsSecure' -Value '0' -Label (Get-WinConfSettingLabel 'ScreenSaverIsSecure' $Language)),
                (New-WinConfRegistryDefinition -Path $policy -Name 'InactivityTimeoutSecs' -Value 0 -Label (Get-WinConfSettingLabel 'InactivityTimeoutSecs' $Language))
            )
        }
        'Notifications' {
            return @(
                (New-WinConfRegistryDefinition -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'DisableNotificationCenter' -Value 1 -Label (Get-WinConfSettingLabel 'DisableNotificationCenter' $Language)),
                (New-WinConfRegistryDefinition -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications' -Name 'NoToastApplicationNotification' -Value 1 -Label (Get-WinConfSettingLabel 'NoToastApplicationNotification' $Language)),
                (New-WinConfRegistryDefinition -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'DisableLockScreenAppNotifications' -Value 1 -Label (Get-WinConfSettingLabel 'DisableLockScreenAppNotifications' $Language))
            )
        }
        'Privacy' {
            return @(
                (New-WinConfRegistryDefinition -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Value 0 -Label (Get-WinConfSettingLabel 'AllowTelemetry' $Language)),
                (New-WinConfRegistryDefinition -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'PublishUserActivities' -Value 0 -Label (Get-WinConfSettingLabel 'PublishUserActivities' $Language)),
                (New-WinConfRegistryDefinition -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'UploadUserActivities' -Value 0 -Label (Get-WinConfSettingLabel 'UploadUserActivities' $Language))
            )
        }
        'Cortana' {
            return @(Get-CortanaSettings | ForEach-Object {
                $label = Get-WinConfSettingLabel $_.Name $Language
                New-WinConfRegistryDefinition -Path $_.Path -Name $_.Name -Value $_.Value -Label $label -Description (Get-WinConfSettingDescription $label $Language) -MinBuild $_.MinBuild -MaxBuild $_.MaxBuild
            })
        }
        'UI' {
            return @(Get-UISettings | ForEach-Object {
                $label = Get-WinConfSettingLabel $_.Name $Language
                New-WinConfRegistryDefinition -Path $_.Path -Name $_.Name -Value $_.Value -Label $label -Description (Get-WinConfSettingDescription $label $Language) -MinBuild $_.MinBuild -MaxBuild $_.MaxBuild
            })
        }
        'WindowsUpdate' {
            return @(Get-WindowsUpdateSettings | ForEach-Object {
                $label = Get-WinConfSettingLabel $_.Name $Language
                New-WinConfRegistryDefinition -Path $_.Path -Name $_.Name -Value $_.Value -Label $label -Description (Get-WinConfSettingDescription $label $Language) -MinBuild $_.MinBuild -MaxBuild $_.MaxBuild
            })
        }
    }

    return @()
}

function Get-WinConfRegistryState {
    param(
        [Parameter(Mandatory)][string] $Module,
        [ValidateSet('en-US', 'zh-CN')]
        [string] $Language = 'en-US'
    )

    $build = [System.Environment]::OSVersion.Version.Build
    $rows = [System.Collections.Generic.List[object]]::new()

    foreach ($definition in Get-WinConfRegistryDefinitions -Module $Module -Language $Language) {
        $notApplicable = (
            ($null -ne $definition.MinBuild -and $build -lt [int]$definition.MinBuild) -or
            ($null -ne $definition.MaxBuild -and $build -gt [int]$definition.MaxBuild)
        )
        $current = if ($notApplicable) { $null } else { Get-RegValue -Path $definition.Path -Name $definition.Name }
        $description = if ([string]::IsNullOrWhiteSpace($definition.Description)) { Get-WinConfSettingDescription -Label $definition.Label -Language $Language } else { $definition.Description }
        $rows.Add((New-WinConfStateRow -Key "$($definition.Path)\$($definition.Name)" -Label $definition.Label -Current $current -Target $definition.Value -Description $description -Language $Language -NotApplicable:$notApplicable))
    }

    return $rows
}

function Get-WinConfPowerCfgAcValue {
    param([string] $SubGroup, [string] $Setting)

    try {
        $output = (& powercfg /query SCHEME_CURRENT $SubGroup $Setting 2>&1 | Out-String)
        $match = [regex]::Match($output, '(?im)(?:Current AC Power Setting Index|当前交流电源设置索引)\s*:\s*0x(?<Value>[0-9a-f]+)')
        if ($match.Success) { return [Convert]::ToInt64($match.Groups['Value'].Value, 16) }
    } catch { }
    return $null
}

function Get-WinConfPowerState {
    param(
        [ValidateSet('en-US', 'zh-CN')]
        [string] $Language = 'en-US'
    )

    $rows = [System.Collections.Generic.List[object]]::new()
    $highPerformanceGuid = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'

    $activeGuid = $null
    try {
        $activeOutput = (& powercfg /getactivescheme 2>&1 | Out-String)
        $guidMatch = [regex]::Match($activeOutput, '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}')
        if ($guidMatch.Success) { $activeGuid = $guidMatch.Value.ToLowerInvariant() }
    } catch { }

    $powerLabels = if ($Language -eq 'zh-CN') {
        @('活动电源方案', '交流供电睡眠超时（秒）', '交流供电屏幕超时（秒）', '休眠功能')
    } else {
        @('Active power plan', 'AC sleep timeout (seconds)', 'AC display timeout (seconds)', 'Hibernation')
    }
    $powerDescriptions = if ($Language -eq 'zh-CN') {
        @('使用 Windows 高性能电源方案。', '0 表示从不自动睡眠。', '0 表示从不自动关闭显示器。', '关闭系统休眠及休眠文件。')
    } else {
        @('Use the Windows High Performance power plan.', '0 means the device never sleeps automatically on AC power.', '0 means the display never turns off automatically on AC power.', 'Disable system hibernation and the hibernation file.')
    }

    $rows.Add((New-WinConfStateRow -Key 'PowerCfg:ActiveScheme' -Label $powerLabels[0] -Current $activeGuid -Target $highPerformanceGuid -Description $powerDescriptions[0] -Language $Language))
    $rows.Add((New-WinConfStateRow -Key 'PowerCfg:StandbyAC' -Label $powerLabels[1] -Current (Get-WinConfPowerCfgAcValue -SubGroup 'SUB_SLEEP' -Setting 'STANDBYIDLE') -Target 0 -Description $powerDescriptions[1] -Language $Language))
    $rows.Add((New-WinConfStateRow -Key 'PowerCfg:MonitorAC' -Label $powerLabels[2] -Current (Get-WinConfPowerCfgAcValue -SubGroup 'SUB_VIDEO' -Setting 'VIDEOIDLE') -Target 0 -Description $powerDescriptions[2] -Language $Language))

    $hibernate = Get-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name 'HibernateEnabled'
    $rows.Add((New-WinConfStateRow -Key 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\HibernateEnabled' -Label $powerLabels[3] -Current $hibernate -Target 0 -Description $powerDescriptions[3] -Language $Language))

    foreach ($row in Get-WinConfRegistryState -Module 'Power' -Language $Language) { $rows.Add($row) }
    return $rows
}

function Get-WinConfPrivacyState {
    param(
        [ValidateSet('en-US', 'zh-CN')]
        [string] $Language = 'en-US'
    )

    $rows = [System.Collections.Generic.List[object]]::new()
    foreach ($row in Get-WinConfRegistryState -Module 'Privacy' -Language $Language) { $rows.Add($row) }

    $service = Get-Service -Name 'DiagTrack' -ErrorAction SilentlyContinue
    $startType = if ($service) { $service.StartType.ToString() } else { '未安装' }
    $status = if ($service) { $service.Status.ToString() } else { '未安装' }
    $startLabel = if ($Language -eq 'zh-CN') { '遥测服务启动类型' } else { 'Telemetry service startup type' }
    $statusLabel = if ($Language -eq 'zh-CN') { '遥测服务运行状态' } else { 'Telemetry service status' }
    $startDescription = if ($Language -eq 'zh-CN') { '禁止遥测服务随系统启动。' } else { 'Prevent the telemetry service from starting with Windows.' }
    $statusDescription = if ($Language -eq 'zh-CN') { '停止当前正在运行的遥测服务。' } else { 'Stop the currently running telemetry service.' }
    $rows.Add((New-WinConfStateRow -Key 'Service:DiagTrack:StartType' -Label $startLabel -Current $startType -Target 'Disabled' -Description $startDescription -Language $Language))
    $rows.Add((New-WinConfStateRow -Key 'Service:DiagTrack:Status' -Label $statusLabel -Current $status -Target 'Stopped' -Description $statusDescription -Language $Language))
    return $rows
}

function Get-WinConfModuleState {
    param(
        [Parameter(Mandatory)][string] $Module,
        [ValidateSet('en-US', 'zh-CN')]
        [string] $Language = 'en-US'
    )

    switch ($Module) {
        'Power' { return @(Get-WinConfPowerState -Language $Language) }
        'Privacy' { return @(Get-WinConfPrivacyState -Language $Language) }
        'WindowsRestore' {
            $label = if ($Language -eq 'zh-CN') { 'Windows 恢复环境' } else { 'Windows Recovery Environment' }
            $description = if ($Language -eq 'zh-CN') { '关闭本机 Windows 恢复环境。' } else { 'Disable the local Windows Recovery Environment.' }
            return @(
                (New-WinConfStateRow -Key 'WindowsRE:Status' -Label $label -Current (Get-WindowsRestoreAvailabilityState) -Target 'disabled' -Description $description -Language $Language)
            )
        }
        default { return @(Get-WinConfRegistryState -Module $Module -Language $Language) }
    }
}

function Get-WinConfRestoreTargetState {
    param(
        [Parameter(Mandatory)][string] $Module,
        [ValidateSet('en-US', 'zh-CN')]
        [string] $Language = 'en-US'
    )

    $currentState = @(Get-WinConfModuleState -Module $Module -Language $Language)
    $snapshotByKey = @{}
    foreach ($entry in Get-SnapshotEntries -Module $Module) {
        $snapshotByKey[[string]$entry.Key] = $entry
    }

    $rows = [System.Collections.Generic.List[object]]::new()
    foreach ($item in $currentState) {
        if (-not $snapshotByKey.ContainsKey($item.Key)) { continue }
        $entry = $snapshotByKey[$item.Key]
        $rows.Add((New-WinConfStateRow -Key $item.Key -Label $item.Label -Current $item.RawCurrent -Target $entry.Value -Description $item.Description -Language $Language -NotApplicable:$item.NotApplicable))
    }
    return $rows
}
