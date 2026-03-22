#Requires -Modules Pester

Describe 'UI.ps1 Issue #1 behavior' {
    It 'describes UI settings through shared descriptors' {
        . "$PSScriptRoot\..\scripts\lib\Registry.ps1"
        . "$PSScriptRoot\..\scripts\modules\UI.ps1"

        $settings = Get-UISettings
        $settings.Count | Should Be 5
        ($settings | Where-Object { $_.Name -eq 'TaskbarDa' }).Category | Should Be 'os_protected_optional'
        ($settings | Where-Object { $_.Name -eq 'EnableFeeds' }).Category | Should Be 'required_policy_backed'
    }

    It 'applies build rules through shared descriptor applicability' {
        . "$PSScriptRoot\..\scripts\lib\Registry.ps1"
        . "$PSScriptRoot\..\scripts\modules\UI.ps1"

        $taskbarDa = Get-UISettings | Where-Object { $_.Name -eq 'TaskbarDa' }
        $feeds = Get-UISettings | Where-Object { $_.Name -eq 'ShellFeedsTaskbarViewMode' }
        $meetNow = Get-UISettings | Where-Object { $_.Name -eq 'HideMeetNow' }

        (Test-RegSettingApplicable -Descriptor $taskbarDa -Build 22631) | Should Be $true
        (Test-RegSettingApplicable -Descriptor $feeds -Build 19045) | Should Be $true
        (Test-RegSettingApplicable -Descriptor $feeds -Build 22631) | Should Be $false
        (Test-RegSettingApplicable -Descriptor $meetNow -Build 19045) | Should Be $true
        (Test-RegSettingApplicable -Descriptor $meetNow -Build 22631) | Should Be $false
    }

    It 'executes UI settings through descriptor-based invocation' {
        $content = Get-Content -Path "$PSScriptRoot\..\scripts\modules\UI.ps1" -Raw

        $content | Should Match 'function Get-UISettings'
        $content | Should Match 'New-RegSettingDescriptor -Name ''TaskbarDa'''
        $content | Should Match 'New-RegSettingDescriptor -Name ''ShellFeedsTaskbarViewMode'''
        $content | Should Match 'foreach \(\$setting in Get-UISettings\)'
        $content | Should Match 'Invoke-RegSettingDescriptor -Descriptor \$setting -Module \$module -DryRun:\$DryRun -Build \$build'
    }
}
