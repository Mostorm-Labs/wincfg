# Snapshot.ps1 — Save and restore pre-change values
# Depends on: Logger.ps1

$script:SnapshotFile = "C:\ProgramData\WinConf\snapshot.json"
$script:SnapshotData = [System.Collections.Generic.List[object]]::new()

function Initialize-Snapshot {
    param([string] $Path = $script:SnapshotFile)
    $script:SnapshotFile = $Path
}

function Save-Snapshot {
    param(
        [string] $Module,
        [string] $Key,
        $CurrentValue
    )
    # Only save the first time we see this key (preserve original value)
    $exists = $script:SnapshotData | Where-Object { $_.Key -eq $Key }
    if ($exists) { return }

    $entry = [PSCustomObject]@{
        Module  = $Module
        Key     = $Key
        Value   = $CurrentValue
        SavedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
    $script:SnapshotData.Add($entry)

    # Persist to disk immediately
    $script:SnapshotData | ConvertTo-Json -Depth 5 | Set-Content -Path $script:SnapshotFile -Encoding UTF8
    Write-Log -Level INFO -Module $Module -Message "Snapshot saved: $Key = $CurrentValue"
}

function Restore-Snapshot {
    param([switch] $DryRun)

    if (-not (Test-Path $script:SnapshotFile)) {
        Write-Log -Level WARN -Module "Rollback" -Message "No snapshot file found at $($script:SnapshotFile)"
        return
    }

    $entries = Get-Content $script:SnapshotFile -Raw | ConvertFrom-Json
    # Restore in reverse order
    [array]::Reverse($entries)

    foreach ($entry in $entries) {
        if ($entry.Key -like "Service:*") {
            # Format: Service:<name>:StartType
            $parts = $entry.Key -split ":"
            $svcName   = $parts[1]
            $startType = $entry.Value
            if ($DryRun) {
                Write-Log -Level DRY -Module "Rollback" -Message "Would restore service '$svcName' StartType=$startType"
            } else {
                Set-Service -Name $svcName -StartupType $startType -ErrorAction SilentlyContinue
                Write-Log -Level INFO -Module "Rollback" -Message "Restored service '$svcName' StartType=$startType"
            }
        } else {
            # Registry key: full path\name
            $regPath = Split-Path $entry.Key -Parent
            $regName = Split-Path $entry.Key -Leaf
            if ($DryRun) {
                Write-Log -Level DRY -Module "Rollback" -Message "Would restore $($entry.Key) = $($entry.Value)"
            } else {
                if ($null -eq $entry.Value) {
                    Remove-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue
                } else {
                    Set-ItemProperty -Path $regPath -Name $regName -Value $entry.Value -ErrorAction SilentlyContinue
                }
                Write-Log -Level INFO -Module "Rollback" -Message "Restored $($entry.Key) = $($entry.Value)"
            }
        }
    }
}
