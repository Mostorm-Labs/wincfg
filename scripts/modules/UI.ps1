# UI.ps1 — Taskbar and shell UI cleanup
# Depends on: Logger.ps1, Registry.ps1, Snapshot.ps1

function Invoke-UI {
    param(
        [switch] $DryRun,
        [switch] $AutoHideTaskbar  # optional, off by default
    )

    $module      = "UI"
    $advancedPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $feedsPath    = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds"
    $taskbarPath  = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3"
    Write-Log -Level INFO -Module $module -Message "=== Starting UI module ==="

    # 1. Hide Task View button
    Set-RegValue -Path $advancedPath -Name "ShowTaskViewButton" -Value 0 `
        -Module $module -DryRun:$DryRun

    # 2. Disable News and Interests (Windows 10)
    Set-RegValue -Path $advancedPath -Name "TaskbarDa" -Value 0 `
        -Module $module -DryRun:$DryRun

    Set-RegValue -Path $feedsPath -Name "ShellFeedsTaskbarViewMode" -Value 2 `
        -Module $module -DryRun:$DryRun

    # 3. Hide Meet Now button
    Set-RegValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
        -Name "HideSCAMeetNow" -Value 1 `
        -Module $module -DryRun:$DryRun

    # 4. Auto-hide taskbar (optional)
    if ($AutoHideTaskbar) {
        Set-RegValue -Path $advancedPath -Name "AutoHideTaskbar" -Value 1 `
            -Module $module -DryRun:$DryRun
    }

    Write-Log -Level INFO -Module $module -Message "=== UI module complete ==="
}
