# winconf.ps1 — Main entry point
# Usage: .\winconf.ps1 [-DryRun] [-Verbose] [-Rollback] [-Module <name>]
#
# Requires: Run as Administrator

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [switch] $DryRun,
    [switch] $Rollback,
    [string] $Module = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Paths ────────────────────────────────────────────────────────────────────
$dataDir      = "C:\ProgramData\WinConf"
$logFile      = "$dataDir\winconf.log"
$snapshotFile = "$dataDir\snapshot.json"
$scriptRoot   = $PSScriptRoot

# ── Dot-source libs ──────────────────────────────────────────────────────────
. "$scriptRoot\lib\Logger.ps1"
. "$scriptRoot\lib\Snapshot.ps1"
. "$scriptRoot\lib\Registry.ps1"
. "$scriptRoot\lib\Service.ps1"

# ── Init ─────────────────────────────────────────────────────────────────────
Initialize-Logger -LogPath $logFile -Verbose:($PSBoundParameters['Verbose'] -eq $true)
Initialize-Snapshot -Path $snapshotFile

Write-Log -Level INFO -Module MAIN -Message "winconf started (DryRun=$DryRun, Rollback=$Rollback, Module='$Module')"

# ── Rollback branch ──────────────────────────────────────────────────────────
if ($Rollback) {
    Write-Log -Level INFO -Module MAIN -Message "Rollback requested"
    Restore-Snapshot -DryRun:$DryRun
    Write-Log -Level INFO -Module MAIN -Message "Rollback complete"
    exit 0
}

# ── Load modules ─────────────────────────────────────────────────────────────
$allModules = @(
    @{ Name = "Power";         File = "Power.ps1";         Fn = "Invoke-Power" },
    @{ Name = "ScreenLock";    File = "ScreenLock.ps1";    Fn = "Invoke-ScreenLock" },
    @{ Name = "WindowsUpdate"; File = "WindowsUpdate.ps1"; Fn = "Invoke-WindowsUpdate" },
    @{ Name = "WindowsRestore"; File = "WindowsRestore.ps1"; Fn = "Invoke-WindowsRestore" },
    @{ Name = "Cortana";       File = "Cortana.ps1";       Fn = "Invoke-Cortana" },
    @{ Name = "Notifications"; File = "Notifications.ps1"; Fn = "Invoke-Notifications" },
    @{ Name = "Privacy";       File = "Privacy.ps1";       Fn = "Invoke-Privacy" },
    @{ Name = "UI";            File = "UI.ps1";            Fn = "Invoke-UI" }
)

# Filter to requested module if specified
if ($Module -ne "") {
    $selected = $allModules | Where-Object { $_.Name -eq $Module }
    if (-not $selected) {
        Write-Log -Level ERROR -Module MAIN -Message "Unknown module '$Module'. Valid: $($allModules.Name -join ', ')"
        exit 1
    }
    $allModules = @($selected)
}

foreach ($m in $allModules) {
    . "$scriptRoot\modules\$($m.File)"
}

# ── Run ───────────────────────────────────────────────────────────────────────
$failed = @()

foreach ($m in $allModules) {
    try {
        & $m.Fn -DryRun:$DryRun
    } catch {
        Write-Log -Level ERROR -Module $m.Name -Message "Module failed: $_"
        $failed += $m.Name
    }
}

# ── Summary ───────────────────────────────────────────────────────────────────
if ($failed.Count -gt 0) {
    Write-Log -Level WARN -Module MAIN -Message "Completed with errors in: $($failed -join ', ')"
    exit 1
} else {
    Write-Log -Level INFO -Module MAIN -Message "All modules completed successfully"
    exit 0
}
