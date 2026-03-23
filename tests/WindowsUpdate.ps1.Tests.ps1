#Requires -Modules Pester

Describe 'WindowsUpdate.ps1 policy metadata alignment' {
    It 'describes Windows Update settings through shared descriptors' {
        . "$PSScriptRoot\..\scripts\lib\Registry.ps1"
        . "$PSScriptRoot\..\scripts\modules\WindowsUpdate.ps1"

        $settings = Get-WindowsUpdateSettings
        $settings.Count | Should Be 21
        ($settings | Where-Object { $_.Name -eq 'NoAutoUpdate' -and $_.Path -match 'WindowsUpdate\\AU$' }).Category | Should Be 'required_policy_backed'
        ($settings | Where-Object { $_.Name -eq 'SettingsPageVisibility' -and $_.Path -match 'Policies\\Explorer$' }).Type | Should Be ([Microsoft.Win32.RegistryValueKind]::String)
        ($settings | Where-Object { $_.Name -eq 'AllowStore' -and $_.Path -match 'PolicyManager\\current\\device\\Store$' }).Value | Should Be 1
    }

    It 'covers the full revised Windows Update policy contract' {
        . "$PSScriptRoot\..\scripts\lib\Registry.ps1"
        . "$PSScriptRoot\..\scripts\modules\WindowsUpdate.ps1"

        $actual = Get-WindowsUpdateSettings | ForEach-Object { "$($_.Path)|$($_.Name)|$($_.Value)|$($_.Type)" }
        $expected = @(
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU|NoAutoUpdate|1|DWord",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU|AUOptions|1|DWord",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU|NoAUShutdownOption|1|DWord",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU|NoAUAsDefaultShutdownOption|1|DWord",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU|NoAutoRebootWithLoggedOnUsers|1|DWord",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate|SetAutoRestartNotificationDisable|1|DWord",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate|SetUpdateNotificationLevel|2|DWord",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate|ExcludeWUDriversInQualityUpdate|1|DWord",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate|DisableOSUpgrade|1|DWord",
            "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore|RemoveWindowsStore|0|DWord",
            "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore|AutoDownload|4|DWord",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer|SettingsPageVisibility|hide:windowsupdate-action|String",
            "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings|RestartNotificationsAllowed2|0|DWord",
            "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings|HideWUXMessages|1|DWord",
            "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update|AllowAutoUpdate|0|DWord",
            "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update|DoNotShowUpdateNotifications|1|DWord",
            "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update|HideUpdatePowerOption|1|DWord",
            "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update|ExcludeWUDriversInQualityUpdate|1|DWord",
            "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Store|AllowStore|1|DWord",
            "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Store|AutoDownload|4|DWord",
            "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Settings|SettingsPageVisibility|hide:windowsupdate-action|String"
        )

        $actual | Should Be $expected
    }

    It 'executes Windows Update settings through descriptor-based invocation and refreshes policy' {
        $content = Get-Content -Path "$PSScriptRoot\..\scripts\modules\WindowsUpdate.ps1" -Raw

        $content | Should Match 'function Get-WindowsUpdateSettings'
        $content | Should Match 'New-RegSettingDescriptor -Name ''NoAutoUpdate'''
        $content | Should Match 'New-RegSettingDescriptor -Name ''SettingsPageVisibility'''
        $content | Should Match 'foreach \(\$setting in Get-WindowsUpdateSettings\)'
        $content | Should Match 'Invoke-RegSettingDescriptor -Descriptor \$setting -Module \$module -DryRun:\$DryRun -Build \$build'
        $content | Should Match 'function Invoke-WindowsUpdatePolicyRefresh'
        $content | Should Match '& gpupdate /force \| Out-Null'
        $content | Should Match 'Command failed: ''gpupdate /force'' exit_code='
    }

    It 'does not disable Windows Update services in the module flow' {
        $content = Get-Content -Path "$PSScriptRoot\..\scripts\modules\WindowsUpdate.ps1" -Raw

        $content | Should Not Match 'wuauserv'
        $content | Should Not Match 'UsoSvc'
        $content | Should Not Match 'Set-ServiceStartType'
        $content | Should Not Match 'Stop-ServiceIfRunning'
    }
}
