#Requires -Modules Pester

Describe 'ScreenLock.ps1 spec alignment' {
    It 'writes the SPEC-defined idle lock policy path and value' {
        $content = Get-Content -Path "$PSScriptRoot\..\scripts\modules\ScreenLock.ps1" -Raw

        $content | Should Match 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System'
        $content | Should Match 'InactivityTimeoutSecs'
        $content | Should Not Match 'NoLockScreen'
    }

    It 'wires all expected ScreenLock settings through Set-RegValue' {
        $content = Get-Content -Path "$PSScriptRoot\..\scripts\modules\ScreenLock.ps1" -Raw

        $content | Should Match 'Set-RegValue -Path \$desktopPath -Name "ScreenSaveActive" -Value "0"'
        $content | Should Match 'Set-RegValue -Path \$desktopPath -Name "ScreenSaveTimeOut" -Value "0"'
        $content | Should Match 'Set-RegValue -Path \$desktopPath -Name "ScreenSaverIsSecure" -Value "0"'
        $content | Should Match 'Set-RegValue -Path \$systemPolicyPath -Name "InactivityTimeoutSecs" -Value 0'
    }
}
