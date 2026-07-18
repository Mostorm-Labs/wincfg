# Power.ps1 — Power management configuration
# Depends on: Logger.ps1, Registry.ps1, Snapshot.ps1

function Get-PowerActiveSchemeGuid {
    try {
        $output = powercfg /getactivescheme 2>&1 | Out-String
        $match = [regex]::Match($output, '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}')
        if ($match.Success) { return $match.Value.ToLowerInvariant() }
    } catch { }
    return $null
}

function Get-PowerAcSettingValue {
    param(
        [string] $Scheme = 'SCHEME_CURRENT',
        [string] $SubGroup,
        [string] $Setting
    )

    try {
        $output = powercfg /query $Scheme $SubGroup $Setting 2>&1 | Out-String
        $match = [regex]::Match($output, '(?im)(?:Current AC Power Setting Index|当前交流电源设置索引)\s*:\s*0x(?<Value>[0-9a-f]+)')
        if ($match.Success) { return [Convert]::ToInt64($match.Groups['Value'].Value, 16) }
    } catch { }
    return $null
}

function Save-PowerSnapshot {
    param([string] $Module = 'Power')

    $highPerformanceGuid = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
    Save-Snapshot -Module $Module -Key 'PowerCfg:ActiveScheme' -CurrentValue (Get-PowerActiveSchemeGuid) -Type 'PowerScheme'
    Save-Snapshot -Module $Module -Key 'PowerCfg:HighPerformance:StandbyAC' -CurrentValue (Get-PowerAcSettingValue -Scheme $highPerformanceGuid -SubGroup 'SUB_SLEEP' -Setting 'STANDBYIDLE') -Type 'PowerSettingAc'
    Save-Snapshot -Module $Module -Key 'PowerCfg:HighPerformance:MonitorAC' -CurrentValue (Get-PowerAcSettingValue -Scheme $highPerformanceGuid -SubGroup 'SUB_VIDEO' -Setting 'VIDEOIDLE') -Type 'PowerSettingAc'
    Save-Snapshot -Module $Module -Key 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power\HiberbootEnabled' -CurrentValue (Get-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled') -Type 'Registry'
    Save-Snapshot -Module $Module -Key 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\HibernateEnabled' -CurrentValue (Get-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name 'HibernateEnabled') -Type 'PowerHibernate'
}

function Invoke-Power {
    param([switch] $DryRun)

    $module = "Power"
    Write-Log -Level INFO -Module $module -Message "=== Starting Power module ==="

    if (-not $DryRun) {
        Save-PowerSnapshot -Module $module
    }

    # 1. Set High Performance power plan
    $hpGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
    if ($DryRun) {
        Write-Log -Level DRY -Module $module -Message "Would activate High Performance power plan ($hpGuid)"
    } else {
        powercfg /setactive $hpGuid 2>&1 | Out-Null
        Write-Log -Level INFO -Module $module -Message "Activated High Performance power plan"
    }

    # 2. Disable sleep (AC)
    if ($DryRun) {
        Write-Log -Level DRY -Module $module -Message "Would set sleep timeout (AC) = 0"
    } else {
        powercfg /change standby-timeout-ac 0
        Write-Log -Level INFO -Module $module -Message "Set sleep timeout (AC) = 0"
    }

    # 3. Disable display timeout (AC)
    if ($DryRun) {
        Write-Log -Level DRY -Module $module -Message "Would set display timeout (AC) = 0"
    } else {
        powercfg /change monitor-timeout-ac 0
        Write-Log -Level INFO -Module $module -Message "Set display timeout (AC) = 0"
    }

    # 4. Disable hibernate
    if ($DryRun) {
        Write-Log -Level DRY -Module $module -Message "Would disable hibernate"
    } else {
        powercfg /hibernate off
        Write-Log -Level INFO -Module $module -Message "Disabled hibernate"
    }

    # 5. Disable fast startup (HiberbootEnabled)
    Set-RegValue `
        -Path  "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" `
        -Name  "HiberbootEnabled" `
        -Value 0 `
        -Module $module `
        -DryRun:$DryRun

    Write-Log -Level INFO -Module $module -Message "=== Power module complete ==="
}
