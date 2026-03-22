#Requires -Modules Pester

Describe 'Cortana.ps1 risk remediation alignment' {
    It 'uses the SPEC-defined Cortana and search policy settings' {
        $content = Get-Content -Path "$PSScriptRoot\..\scripts\modules\Cortana.ps1" -Raw

        $content | Should Match 'HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Windows Search'
        $content | Should Match 'AllowCortana'
        $content | Should Match 'HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer'
        $content | Should Match 'DisableSearchBoxSuggestions'
        $content | Should Match 'ShowCortanaButton'
        $content | Should Not Match 'BingSearchEnabled'
    }

    It 'marks ShowCortanaButton as an OS-protected optional shell setting' {
        $content = Get-Content -Path "$PSScriptRoot\..\scripts\modules\Cortana.ps1" -Raw

        $content | Should Match 'function Test-CortanaSettingOsProtectedOptional'
        $content | Should Match 'ShowCortanaButton'
        $content | Should Match 'Skipping OS-protected optional Cortana setting'
        $content | Should Match 'Set-OptionalCortanaRegValue -Path \$taskbarPath -Name "ShowCortanaButton" -Value 0'
    }
}
