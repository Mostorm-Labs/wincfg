# Notifications.ps1 — Disable Windows notifications
# Depends on: Logger.ps1, Registry.ps1, Snapshot.ps1

function Invoke-Notifications {
    param([switch] $DryRun)

    $module = "Notifications"
    $pushPath   = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications"
    $policyPath = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"
    Write-Log -Level INFO -Module $module -Message "=== Starting Notifications module ==="

    # 1. Disable Action Center (notification panel)
    Set-RegValue -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" `
        -Name "DisableNotificationCenter" -Value 1 `
        -Module $module -DryRun:$DryRun

    # 2. Disable toast notifications
    Set-RegValue -Path $pushPath -Name "ToastEnabled" -Value 0 `
        -Module $module -DryRun:$DryRun

    Set-RegValue -Path $policyPath -Name "NoToastApplicationNotification" -Value 1 `
        -Module $module -DryRun:$DryRun

    # 3. Disable lock screen notifications
    Set-RegValue -Path $pushPath -Name "LockScreenToastEnabled" -Value 0 `
        -Module $module -DryRun:$DryRun

    Write-Log -Level INFO -Module $module -Message "=== Notifications module complete ==="
}
