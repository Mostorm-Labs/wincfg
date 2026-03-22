# Cortana.ps1 - Disable Cortana and web search
# Depends on: Logger.ps1, Registry.ps1, Snapshot.ps1

function Invoke-Cortana {
    param([switch] $DryRun)

    $module = "Cortana"
    $cortanaPath  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    $explorerPolicyPath = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
    $taskbarPath  = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Write-Log -Level INFO -Module $module -Message "=== Starting Cortana module ==="

    # 1. Disable Cortana via policy
    Set-RegValue -Path $cortanaPath -Name "AllowCortana" -Value 0 `
        -Module $module -DryRun:$DryRun

    # 2. Disable web search suggestions in Start
    Set-RegValue -Path $explorerPolicyPath -Name "DisableSearchBoxSuggestions" -Value 1 `
        -Module $module -DryRun:$DryRun

    # 3. Hide Cortana button on taskbar
    Set-OptionalRegValue -Path $taskbarPath -Name "ShowCortanaButton" -Value 0 `
        -Module $module -DryRun:$DryRun -WarningPrefix 'Skipping OS-protected optional Cortana setting' -SkipOnUnauthorized

    Write-Log -Level INFO -Module $module -Message "=== Cortana module complete ==="
}
