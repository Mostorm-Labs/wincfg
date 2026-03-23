# WindowsUpdate.ps1 - Policy-driven Windows Update control
# Depends on: Logger.ps1, Registry.ps1, Snapshot.ps1

function Get-WindowsBuildNumber {
    return [System.Environment]::OSVersion.Version.Build
}

function Get-WindowsUpdateSettings {
    $auPath                 = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
    $wuPath                 = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
    $storePath              = 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore'
    $explorerPath           = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
    $uxPath                 = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
    $policyManagerUpdate    = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update'
    $policyManagerStore     = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Store'
    $policyManagerSettings  = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Settings'

    return @(
        (New-RegSettingDescriptor -Name 'NoAutoUpdate' -Path $auPath -Value 1 -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'AUOptions' -Path $auPath -Value 1 -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'NoAUShutdownOption' -Path $auPath -Value 1 -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'NoAUAsDefaultShutdownOption' -Path $auPath -Value 1 -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'NoAutoRebootWithLoggedOnUsers' -Path $auPath -Value 1 -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'SetAutoRestartNotificationDisable' -Path $wuPath -Value 1 -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'SetUpdateNotificationLevel' -Path $wuPath -Value 2 -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'ExcludeWUDriversInQualityUpdate' -Path $wuPath -Value 1 -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'DisableOSUpgrade' -Path $wuPath -Value 1 -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'RemoveWindowsStore' -Path $storePath -Value 0 -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'AutoDownload' -Path $storePath -Value 4 -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'SettingsPageVisibility' -Path $explorerPath -Value 'hide:windowsupdate-action' -Type String -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'RestartNotificationsAllowed2' -Path $uxPath -Value 0 -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'HideWUXMessages' -Path $uxPath -Value 1 -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'AllowAutoUpdate' -Path $policyManagerUpdate -Value 0 -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'DoNotShowUpdateNotifications' -Path $policyManagerUpdate -Value 1 -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'HideUpdatePowerOption' -Path $policyManagerUpdate -Value 1 -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'ExcludeWUDriversInQualityUpdate' -Path $policyManagerUpdate -Value 1 -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'AllowStore' -Path $policyManagerStore -Value 1 -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'AutoDownload' -Path $policyManagerStore -Value 4 -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'SettingsPageVisibility' -Path $policyManagerSettings -Value 'hide:windowsupdate-action' -Type String -Category 'required_policy_backed')
    )
}

function Invoke-WindowsUpdatePolicyRefresh {
    param(
        [switch] $DryRun
    )

    $module = 'WindowsUpdate'

    if ($DryRun) {
        Write-Log -Level DRY -Module $module -Message 'Would execute command=''gpupdate /force'''
        return
    }

    & gpupdate /force | Out-Null

    if ($LASTEXITCODE -ne 0) {
        $message = "Command failed: 'gpupdate /force' exit_code='$LASTEXITCODE'"
        Write-Log -Level ERROR -Module $module -Message $message
        throw [System.InvalidOperationException]::new($message)
    }

    Write-Log -Level INFO -Module $module -Message "Executed command='gpupdate /force'"
}

function Invoke-WindowsUpdate {
    param([switch] $DryRun)

    $module = 'WindowsUpdate'
    $build  = Get-WindowsBuildNumber

    Write-Log -Level INFO -Module $module -Message '=== Starting WindowsUpdate module ==='

    foreach ($setting in Get-WindowsUpdateSettings) {
        Invoke-RegSettingDescriptor -Descriptor $setting -Module $module -DryRun:$DryRun -Build $build
    }

    Invoke-WindowsUpdatePolicyRefresh -DryRun:$DryRun

    Write-Log -Level INFO -Module $module -Message '=== WindowsUpdate module complete ==='
}
