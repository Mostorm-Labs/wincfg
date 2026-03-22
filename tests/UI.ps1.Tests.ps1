#Requires -Modules Pester

Describe 'UI.ps1 Issue #1 behavior' {
    It 'marks ShellFeedsTaskbarViewMode as supported on Windows 10 builds' {
        . "$PSScriptRoot\..\scripts\modules\UI.ps1"

        Test-UISettingApplicable -Name 'ShellFeedsTaskbarViewMode' -Build 19045 | Should Be $true
    }

    It 'marks ShellFeedsTaskbarViewMode as unsupported on Windows 11 builds' {
        . "$PSScriptRoot\..\scripts\modules\UI.ps1"

        Test-UISettingApplicable -Name 'ShellFeedsTaskbarViewMode' -Build 22631 | Should Be $false
    }

    It 'marks TaskbarDa as supported on Windows 11 builds' {
        . "$PSScriptRoot\..\scripts\modules\UI.ps1"

        Test-UISettingApplicable -Name 'TaskbarDa' -Build 22631 | Should Be $true
    }

    It 'contains an explicit WARN skip path for unsupported OS-specific settings' {
        $content = Get-Content -Path "$PSScriptRoot\..\scripts\modules\UI.ps1" -Raw

        $content | Should Match "Write-Log -Level WARN"
        $content | Should Match "Skipping unsupported UI setting"
    }

    It 'wires Issue #1 registry settings through the expected helpers' {
        $content = Get-Content -Path "$PSScriptRoot\..\scripts\modules\UI.ps1" -Raw

        $content | Should Match 'Set-RegValue -Path \$advancedPath -Name ''ShowTaskViewButton'' -Value 0'
        $content | Should Match 'Set-RegValue -Path \$policyFeedsPath -Name ''EnableFeeds'' -Value 0'
        $content | Should Match 'Set-OptionalUIRegValue -Path \$advancedPath -Name ''TaskbarDa'' -Value 0'
        $content | Should Match 'Set-OptionalUIRegValue -Path \$feedsPath -Name ''ShellFeedsTaskbarViewMode'' -Value 2'
        $content | Should Match 'Set-RegValue -Path ''HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer'' -Name ''HideMeetNow'' -Value 1'
    }
}
