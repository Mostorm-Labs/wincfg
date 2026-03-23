#Requires -Modules Pester

Describe 'WindowsRestore.ps1 module alignment' {
    It 'defines dedicated restore disable and enable commands' {
        $content = Get-Content -Path "$PSScriptRoot\..\scripts\modules\WindowsRestore.ps1" -Raw

        $content | Should Match 'function Get-WindowsRestoreAvailabilityState'
        $content | Should Match 'function Invoke-WindowsRestoreDisable'
        $content | Should Match 'function Invoke-WindowsRestoreEnable'
        $content | Should Match 'Invoke-WindowsRestoreCommand -Command ''reagentc /disable'''
        $content | Should Match 'Invoke-WindowsRestoreCommand -Command ''reagentc /enable'''
        $content | Should Match 'function Invoke-WindowsRestore'
        $content | Should Match '\[switch\] \$Enable'
        $content | Should Match 'if \(\$Enable\) \{'
        $content | Should Match 'Invoke-WindowsRestoreEnable -DryRun:\$DryRun'
    }

    It 'keeps WindowsRestore separate from WindowsUpdate in the main module registry' {
        $content = Get-Content -Path "$PSScriptRoot\..\scripts\winconf.ps1" -Raw

        $content | Should Match '@\{ Name = "WindowsUpdate"; File = "WindowsUpdate.ps1"; Fn = "Invoke-WindowsUpdate" \}'
        $content | Should Match '@\{ Name = "WindowsRestore"; File = "WindowsRestore.ps1"; Fn = "Invoke-WindowsRestore" \}'
    }

    It 'logs and executes restore commands through a dedicated helper' {
        $content = Get-Content -Path "$PSScriptRoot\..\scripts\modules\WindowsRestore.ps1" -Raw

        $content | Should Match 'function Invoke-WindowsRestoreCommand'
        $content | Should Match 'reagentc /info'
        $content | Should Match 'already disabled'
        $content | Should Match 'already enabled'
        $content | Should Match 'Would execute command='
        $content | Should Match 'Executed command='
    }

    It 'implements the reverse path in WindowsRestore rather than rollback-only behavior' {
        $restoreContent = Get-Content -Path "$PSScriptRoot\..\scripts\modules\WindowsRestore.ps1" -Raw
        $mainContent = Get-Content -Path "$PSScriptRoot\..\scripts\winconf.ps1" -Raw

        $restoreContent | Should Match 'function Invoke-WindowsRestoreEnable'
        $restoreContent | Should Match 'Skipping command=''reagentc /enable'' because restore availability is already enabled'
        $mainContent | Should Not Match 'reagentc /enable'
    }
}
