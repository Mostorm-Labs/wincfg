#Requires -Modules Pester

Describe 'Registry.ps1 optional-setting helper' {
    It 'contains shared descriptor and execution helpers' {
        . "$PSScriptRoot\..\scripts\lib\Registry.ps1"

        $descriptor = New-RegSettingDescriptor -Name 'TaskbarDa' -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Value 0 -Required $false -Category 'os_protected_optional' -MinBuild 22000 -SkipOnUnauthorized $true

        (Test-RegSettingDescriptor -Descriptor $descriptor) | Should Be $true
        (Test-RegSettingApplicable -Descriptor $descriptor -Build 19045) | Should Be $false
        (Test-RegSettingApplicable -Descriptor $descriptor -Build 22631) | Should Be $true
    }

    It 'contains the shared metadata execution helpers in source' {
        $content = Get-Content -Path "$PSScriptRoot\..\scripts\lib\Registry.ps1" -Raw

        $content | Should Match 'function New-RegSettingDescriptor'
        $content | Should Match 'function Test-RegSettingDescriptor'
        $content | Should Match 'function Test-RegSettingApplicable'
        $content | Should Match 'function Invoke-RegSettingDescriptor'
    }
}
