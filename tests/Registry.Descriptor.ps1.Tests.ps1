#Requires -Modules Pester

Describe 'Registry.ps1 descriptor-driven execution' {
    BeforeEach {
        . "$PSScriptRoot\..\scripts\lib\Registry.ps1"
    }

    It 'represents a stable required setting descriptor correctly' {
        $descriptor = New-RegSettingDescriptor -Name 'AllowCortana' -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Value 0 -Category 'required_policy_backed'

        (Test-RegSettingDescriptor -Descriptor $descriptor) | Should Be $true
        (Test-RegSettingApplicable -Descriptor $descriptor -Build 22631) | Should Be $true
    }

    It 'represents an unsupported OS-dependent setting descriptor correctly' {
        $descriptor = New-RegSettingDescriptor -Name 'ShellFeedsTaskbarViewMode' -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds' -Value 2 -Required $false -Category 'optional_os_dependent' -MaxBuild 21999

        (Test-RegSettingApplicable -Descriptor $descriptor -Build 19045) | Should Be $true
        (Test-RegSettingApplicable -Descriptor $descriptor -Build 22631) | Should Be $false
    }

    It 'represents an OS-protected optional setting descriptor correctly' {
        $descriptor = New-RegSettingDescriptor -Name 'TaskbarDa' -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Value 0 -Required $false -Category 'os_protected_optional' -MinBuild 22000 -SkipOnUnauthorized $true

        $descriptor.SkipOnUnauthorized | Should Be $true
        (Test-RegSettingApplicable -Descriptor $descriptor -Build 22631) | Should Be $true
    }
}
