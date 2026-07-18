#Requires -Modules Pester

Describe 'WinConf desktop interface' {
    It 'lists every configuration module with user-facing metadata' {
        . "$PSScriptRoot\..\scripts\WinConf.Catalog.ps1"
        $catalog = @(Get-WinConfModuleCatalog)
        $catalogZh = @(Get-WinConfModuleCatalog -Language 'zh-CN')

        $catalog.Count | Should Be 8
        $catalog.Name | Should Be @('Power', 'ScreenLock', 'WindowsUpdate', 'WindowsRestore', 'Cortana', 'Notifications', 'Privacy', 'UI')
        @($catalog | Where-Object { [string]::IsNullOrWhiteSpace($_.Description) }).Count | Should Be 0
        @($catalog | Where-Object { [string]::IsNullOrWhiteSpace($_.Notice) }).Count | Should Be 0
        $catalog[0].DisplayName | Should Be 'Power Management'
        $catalogZh[0].DisplayName | Should Be '电源管理'
    }

    It 'runs the selected module through the existing main script' {
        $content = Get-Content -Path "$PSScriptRoot\..\scripts\WinConf.Gui.ps1" -Raw

        $content | Should Match 'winconf\.ps1'
        $content | Should Match '-Module \$\(\$script:SelectedModule\.Name\)'
        $content | Should Match 'Get-WinConfModuleState'
        $content | Should Match 'Show-WinConfComparison'
        $content | Should Match 'Set-WinConfSplitLayout'
        $content | Should Match 'SizeType\]::Absolute, 215'
    }

    It 'builds an administrator launcher and explicitly tracks its artifact' {
        $manifest = Get-Content -Path "$PSScriptRoot\..\build\WinConf.exe.manifest" -Raw
        $ignore = Get-Content -Path "$PSScriptRoot\..\.gitignore" -Raw

        $manifest | Should Match 'requestedExecutionLevel level="requireAdministrator"'
        $ignore | Should Match '!WinConf\.exe'
        Test-Path "$PSScriptRoot\..\WinConf.exe" | Should Be $true
    }

    It 'exposes restore and localized state entry points' {
        $state = Get-Content -Path "$PSScriptRoot\..\scripts\lib\State.ps1" -Raw
        $snapshot = Get-Content -Path "$PSScriptRoot\..\scripts\lib\Snapshot.ps1" -Raw
        $power = Get-Content -Path "$PSScriptRoot\..\scripts\modules\Power.ps1" -Raw

        $state | Should Match 'function Get-WinConfRestoreTargetState'
        $state | Should Match "Language = 'en-US'"
        $snapshot | Should Match 'function Test-SnapshotAvailable'
        $power | Should Match 'function Save-PowerSnapshot'
    }
}
