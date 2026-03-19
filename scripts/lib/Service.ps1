# Service.ps1 — Windows service management helpers
# Depends on: Logger.ps1, Snapshot.ps1

function Set-ServiceStartType {
    param(
        [string] $Name,
        [ValidateSet("Automatic","Manual","Disabled")]
        [string] $StartType,
        [string] $Module = "Service",
        [switch] $DryRun
    )
    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $svc) {
        Write-Log -Level WARN -Module $Module -Message "Service '$Name' not found, skipping"
        return
    }

    $current = $svc.StartType.ToString()

    if ($DryRun) {
        Write-Log -Level DRY -Module $Module -Message "Would set service '$Name' StartType=$StartType (current: $current)"
        return
    }

    Save-Snapshot -Module $Module -Key "Service:$Name:StartType" -CurrentValue $current

    Set-Service -Name $Name -StartupType $StartType
    Write-Log -Level INFO -Module $Module -Message "Set service '$Name' StartType=$StartType (was: $current)"
}

function Stop-ServiceIfRunning {
    param(
        [string] $Name,
        [string] $Module = "Service",
        [switch] $DryRun
    )
    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $svc) { return }

    if ($svc.Status -eq "Running") {
        if ($DryRun) {
            Write-Log -Level DRY -Module $Module -Message "Would stop service '$Name'"
            return
        }
        Stop-Service -Name $Name -Force
        Write-Log -Level INFO -Module $Module -Message "Stopped service '$Name'"
    }
}
