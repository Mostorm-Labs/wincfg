#Requires -Modules Pester

Describe 'Registry.ps1 optional-setting helper' {
    It 'contains a shared helper for optional unauthorized registry writes' {
        $content = Get-Content -Path "$PSScriptRoot\..\scripts\lib\Registry.ps1" -Raw

        $content | Should Match 'function Test-RegUnauthorizedFailure'
        $content | Should Match 'function Set-OptionalRegValue'
        $content | Should Match 'function Set-ApplicableOptionalRegValue'
        $content | Should Match 'SkipOnUnauthorized'
        $content | Should Match 'Direct registry write was rejected by the OS'
    }
}
