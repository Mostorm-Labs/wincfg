#Requires -Modules Pester

Describe 'Notifications.ps1 spec alignment' {
    It 'uses only the SPEC-defined notification policy settings' {
        $content = Get-Content -Path "$PSScriptRoot\..\scripts\modules\Notifications.ps1" -Raw

        $content | Should Match 'HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer'
        $content | Should Match 'DisableNotificationCenter'
        $content | Should Match 'HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CurrentVersion\\PushNotifications'
        $content | Should Match 'NoToastApplicationNotification'
        $content | Should Match 'HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System'
        $content | Should Match 'DisableLockScreenAppNotifications'
        $content | Should Not Match 'ToastEnabled'
        $content | Should Not Match 'LockScreenToastEnabled'
    }

    It 'wires the three SPEC-defined notification writes through Set-RegValue' {
        $content = Get-Content -Path "$PSScriptRoot\..\scripts\modules\Notifications.ps1" -Raw

        $content | Should Match 'Set-RegValue -Path \$explorerPolicyPath'
        $content | Should Match 'Set-RegValue -Path \$pushPolicyPath -Name "NoToastApplicationNotification" -Value 1'
        $content | Should Match 'Set-RegValue -Path \$systemPolicyPath -Name "DisableLockScreenAppNotifications" -Value 1'
    }
}
