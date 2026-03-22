#Requires -Modules Pester

Describe 'Cortana.ps1 risk remediation alignment' {
    It 'describes Cortana settings through shared descriptors' {
        . "$PSScriptRoot\..\scripts\lib\Registry.ps1"
        . "$PSScriptRoot\..\scripts\modules\Cortana.ps1"

        $settings = Get-CortanaSettings
        $settings.Count | Should Be 3
        ($settings | Where-Object { $_.Name -eq 'AllowCortana' }).Category | Should Be 'required_policy_backed'
        ($settings | Where-Object { $_.Name -eq 'ShowCortanaButton' }).Category | Should Be 'os_protected_optional'
    }

    It 'executes Cortana settings through descriptor-based invocation' {
        $content = Get-Content -Path "$PSScriptRoot\..\scripts\modules\Cortana.ps1" -Raw

        $content | Should Match 'function Get-CortanaSettings'
        $content | Should Match 'New-RegSettingDescriptor -Name ''AllowCortana'''
        $content | Should Match 'New-RegSettingDescriptor -Name ''DisableSearchBoxSuggestions'''
        $content | Should Match 'New-RegSettingDescriptor -Name ''ShowCortanaButton'''
        $content | Should Match 'Skipping OS-protected optional Cortana setting'
        $content | Should Match 'foreach \(\$setting in Get-CortanaSettings\)'
        $content | Should Match 'Invoke-RegSettingDescriptor -Descriptor \$setting -Module \$module -DryRun:\$DryRun'
    }
}
