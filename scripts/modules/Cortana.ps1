# Cortana.ps1 - Disable Cortana and web search
# Depends on: Logger.ps1, Registry.ps1, Snapshot.ps1

function Get-CortanaSettings {
    $cortanaPath        = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    $explorerPolicyPath = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
    $taskbarPath        = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

    return @(
        (New-RegSettingDescriptor -Name 'AllowCortana' -Path $cortanaPath -Value 0 -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'DisableSearchBoxSuggestions' -Path $explorerPolicyPath -Value 1 -Category 'required_policy_backed'),
        (New-RegSettingDescriptor -Name 'ShowCortanaButton' -Path $taskbarPath -Value 0 -Required $false -Category 'os_protected_optional' -SkipOnUnauthorized $true -WarningPrefix 'Skipping OS-protected optional Cortana setting')
    )
}

function Invoke-Cortana {
    param([switch] $DryRun)

    $module = "Cortana"
    Write-Log -Level INFO -Module $module -Message "=== Starting Cortana module ==="

    foreach ($setting in Get-CortanaSettings) {
        Invoke-RegSettingDescriptor -Descriptor $setting -Module $module -DryRun:$DryRun
    }

    Write-Log -Level INFO -Module $module -Message "=== Cortana module complete ==="
}
