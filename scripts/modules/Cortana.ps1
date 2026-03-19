# Cortana.ps1 — Disable Cortana and web search
# Depends on: Logger.ps1, Registry.ps1, Snapshot.ps1

function Invoke-Cortana {
    param([switch] $DryRun)

    $module = "Cortana"
    $cortanaPath  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    $searchPath   = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
    $taskbarPath  = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Write-Log -Level INFO -Module $module -Message "=== Starting Cortana module ==="

    # 1. Disable Cortana via policy
    Set-RegValue -Path $cortanaPath -Name "AllowCortana" -Value 0 `
        -Module $module -DryRun:$DryRun

    # 2. Disable web search suggestions in Start
    Set-RegValue -Path $searchPath -Name "BingSearchEnabled" -Value 0 `
        -Module $module -DryRun:$DryRun

    Set-RegValue -Path $searchPath -Name "DisableSearchBoxSuggestions" -Value 1 `
        -Module $module -DryRun:$DryRun

    # 3. Hide Cortana button on taskbar
    Set-RegValue -Path $taskbarPath -Name "ShowCortanaButton" -Value 0 `
        -Module $module -DryRun:$DryRun

    Write-Log -Level INFO -Module $module -Message "=== Cortana module complete ==="
}
