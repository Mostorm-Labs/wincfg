# Notifications.ps1 — Disable Windows notifications
# Depends on: Logger.ps1, Registry.ps1, Snapshot.ps1

function Invoke-Notifications {
    param([switch] $DryRun)

    $module = "Notifications"
    $explorerPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
    $pushPolicyPath     = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"
    $systemPolicyPath   = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
    Write-Log -Level INFO -Module $module -Message "=== Starting Notifications module ==="

    # Metadata migration is intentionally deferred for Notifications because the
    # module currently contains only stable policy-backed settings after risk
    # remediation, so explicit calls remain clearer than introducing descriptors
    # before mixed stability categories reappear.

    # 1. Disable Action Center (notification panel)
    Set-RegValue -Path $explorerPolicyPath `
        -Name "DisableNotificationCenter" -Value 1 `
        -Module $module -DryRun:$DryRun

    # 2. Disable toast notifications
    Set-RegValue -Path $pushPolicyPath -Name "NoToastApplicationNotification" -Value 1 `
        -Module $module -DryRun:$DryRun

    # 3. Disable lock screen notifications
    Set-RegValue -Path $systemPolicyPath -Name "DisableLockScreenAppNotifications" -Value 1 `
        -Module $module -DryRun:$DryRun

    Write-Log -Level INFO -Module $module -Message "=== Notifications module complete ==="
}
