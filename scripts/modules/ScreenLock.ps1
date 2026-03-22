# ScreenLock.ps1 — Screen lock / auto-lock configuration
# Depends on: Logger.ps1, Registry.ps1, Snapshot.ps1

function Invoke-ScreenLock {
    param([switch] $DryRun)

    $module = "ScreenLock"
    $desktopPath = "HKCU:\Control Panel\Desktop"
    $systemPolicyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    Write-Log -Level INFO -Module $module -Message "=== Starting ScreenLock module ==="

    # 1. Disable screen saver
    Set-RegValue -Path $desktopPath -Name "ScreenSaveActive" -Value "0" `
        -Type String -Module $module -DryRun:$DryRun

    # 2. Screen saver timeout = 0
    Set-RegValue -Path $desktopPath -Name "ScreenSaveTimeOut" -Value "0" `
        -Type String -Module $module -DryRun:$DryRun

    # 3. Disable lock on screen saver resume
    Set-RegValue -Path $desktopPath -Name "ScreenSaverIsSecure" -Value "0" `
        -Type String -Module $module -DryRun:$DryRun

    # 4. Disable idle lock via policy (InactivityTimeoutSecs = 0)
    Set-RegValue -Path $systemPolicyPath -Name "InactivityTimeoutSecs" -Value 0 `
        -Module $module -DryRun:$DryRun

    Write-Log -Level INFO -Module $module -Message "=== ScreenLock module complete ==="
}
