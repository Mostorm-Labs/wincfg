# Privacy.ps1 — Disable telemetry and activity tracking
# Depends on: Logger.ps1, Registry.ps1, Service.ps1, Snapshot.ps1

function Invoke-Privacy {
    param([switch] $DryRun)

    $module = "Privacy"
    $telemetryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    $activityPath  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
    Write-Log -Level INFO -Module $module -Message "=== Starting Privacy module ==="

    # 1. Set telemetry level to Security (0)
    Set-RegValue -Path $telemetryPath -Name "AllowTelemetry" -Value 0 `
        -Module $module -DryRun:$DryRun

    # 2. Disable Connected User Experiences and Telemetry service (DiagTrack)
    Stop-ServiceIfRunning -Name "DiagTrack" -Module $module -DryRun:$DryRun
    Set-ServiceStartType  -Name "DiagTrack" -StartType Disabled -Module $module -DryRun:$DryRun

    # 3. Disable activity history
    Set-RegValue -Path $activityPath -Name "PublishUserActivities" -Value 0 `
        -Module $module -DryRun:$DryRun

    Set-RegValue -Path $activityPath -Name "UploadUserActivities" -Value 0 `
        -Module $module -DryRun:$DryRun

    Write-Log -Level INFO -Module $module -Message "=== Privacy module complete ==="
}
