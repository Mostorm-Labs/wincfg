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

    It 'uses the shared optional registry helper for ShowCortanaButton' {
        $content = Get-Content -Path "$PSScriptRoot\..\scripts\modules\Cortana.ps1" -Raw

        $content | Should Match 'Skipping OS-protected optional Cortana setting'
        $content | Should Match 'Set-OptionalRegValue -Path \$taskbarPath -Name "ShowCortanaButton" -Value 0'
        $content | Should Match 'SkipOnUnauthorized'
    }
}
