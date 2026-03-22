# UI.ps1 - Taskbar and shell UI cleanup
# Depends on: Logger.ps1, Registry.ps1, Snapshot.ps1

function Get-WindowsBuildNumber {
    return [System.Environment]::OSVersion.Version.Build
}

function Get-UISettings {
    $advancedPath    = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    $feedsPath       = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds'
    $policyFeedsPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds'
    $meetNowPath     = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'

    return @(
        (New-RegSettingDescriptor -Name 'ShowTaskViewButton' -Path $advancedPath -Value 0 -Category 'stable_user_preference'),
        (New-RegSettingDescriptor -Name 'EnableFeeds' -Path $policyFeedsPath -Value 0 -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'TaskbarDa' -Path $advancedPath -Value 0 -Required $false -Category 'os_protected_optional' -MinBuild 22000 -SkipOnUnauthorized $true -UnsupportedWarningPrefix 'Skipping unsupported UI setting' -WarningPrefix 'Skipping OS-protected optional UI setting'),
        (New-RegSettingDescriptor -Name 'ShellFeedsTaskbarViewMode' -Path $feedsPath -Value 2 -Required $false -Category 'optional_os_dependent' -MaxBuild 21999 -UnsupportedWarningPrefix 'Skipping unsupported UI setting'),
        (New-RegSettingDescriptor -Name 'HideMeetNow' -Path $meetNowPath -Value 1 -Required $false -Category 'os_protected_optional' -MaxBuild 21999 -SkipOnUnauthorized $true -UnsupportedWarningPrefix 'Skipping unsupported UI setting' -WarningPrefix 'Skipping OS-protected optional UI setting')
    )
}

function Invoke-UI {
    param(
        [switch] $DryRun,
        [switch] $AutoHideTaskbar
    )

    $module          = 'UI'
    $advancedPath    = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    $build           = Get-WindowsBuildNumber

    Write-Log -Level INFO -Module $module -Message '=== Starting UI module ==='

    foreach ($setting in Get-UISettings) {
        Invoke-RegSettingDescriptor -Descriptor $setting -Module $module -DryRun:$DryRun -Build $build
    }

    if ($AutoHideTaskbar) {
        Set-RegValue -Path $advancedPath -Name 'AutoHideTaskbar' -Value 1 -Module $module -DryRun:$DryRun
    }

    Write-Log -Level INFO -Module $module -Message '=== UI module complete ==='
}
