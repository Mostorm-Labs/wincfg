# WindowsUpdate.ps1 — Disable Windows Update
# Depends on: Logger.ps1, Registry.ps1, Service.ps1, Snapshot.ps1

function Invoke-WindowsUpdate {
    param([switch] $DryRun)

    $module = "WindowsUpdate"
    $auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    $doPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
    Write-Log -Level INFO -Module $module -Message "=== Starting WindowsUpdate module ==="

    # 1. Disable automatic updates via policy
    Set-RegValue -Path $auPath -Name "NoAutoUpdate" -Value 1 `
        -Module $module -DryRun:$DryRun

    Set-RegValue -Path $auPath -Name "AUOptions" -Value 1 `
        -Module $module -DryRun:$DryRun

    # 2. Disable Windows Update service (wuauserv)
    Stop-ServiceIfRunning -Name "wuauserv" -Module $module -DryRun:$DryRun
    Set-ServiceStartType  -Name "wuauserv" -StartType Disabled -Module $module -DryRun:$DryRun

    # 3. Disable Update Orchestrator service (UsoSvc)
    Stop-ServiceIfRunning -Name "UsoSvc" -Module $module -DryRun:$DryRun
    Set-ServiceStartType  -Name "UsoSvc" -StartType Disabled -Module $module -DryRun:$DryRun

    # 4. Disable Delivery Optimization
    Set-RegValue -Path $doPath -Name "DODownloadMode" -Value 0 `
        -Module $module -DryRun:$DryRun

    Write-Log -Level INFO -Module $module -Message "=== WindowsUpdate module complete ==="
}
