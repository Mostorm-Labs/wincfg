# Power.ps1 — Power management configuration
# Depends on: Logger.ps1, Registry.ps1, Snapshot.ps1

function Invoke-Power {
    param([switch] $DryRun)

    $module = "Power"
    Write-Log -Level INFO -Module $module -Message "=== Starting Power module ==="

    # 1. Set High Performance power plan
    $hpGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
    if ($DryRun) {
        Write-Log -Level DRY -Module $module -Message "Would activate High Performance power plan ($hpGuid)"
    } else {
        powercfg /setactive $hpGuid 2>&1 | Out-Null
        Write-Log -Level INFO -Module $module -Message "Activated High Performance power plan"
    }

    # 2. Disable sleep (AC)
    if ($DryRun) {
        Write-Log -Level DRY -Module $module -Message "Would set sleep timeout (AC) = 0"
    } else {
        powercfg /change standby-timeout-ac 0
        Write-Log -Level INFO -Module $module -Message "Set sleep timeout (AC) = 0"
    }

    # 3. Disable display timeout (AC)
    if ($DryRun) {
        Write-Log -Level DRY -Module $module -Message "Would set display timeout (AC) = 0"
    } else {
        powercfg /change monitor-timeout-ac 0
        Write-Log -Level INFO -Module $module -Message "Set display timeout (AC) = 0"
    }

    # 4. Disable hibernate
    if ($DryRun) {
        Write-Log -Level DRY -Module $module -Message "Would disable hibernate"
    } else {
        powercfg /hibernate off
        Write-Log -Level INFO -Module $module -Message "Disabled hibernate"
    }

    # 5. Disable fast startup (HiberbootEnabled)
    Set-RegValue `
        -Path  "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" `
        -Name  "HiberbootEnabled" `
        -Value 0 `
        -Module $module `
        -DryRun:$DryRun

    Write-Log -Level INFO -Module $module -Message "=== Power module complete ==="
}
