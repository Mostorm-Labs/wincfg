# Snapshot.ps1 - Save and restore pre-change values
# Depends on: Logger.ps1

$script:SnapshotFile = 'C:\ProgramData\WinConf\snapshot.json'
$script:SnapshotData = [System.Collections.Generic.List[object]]::new()

function Initialize-Snapshot {
    param([string] $Path = $script:SnapshotFile)
    $script:SnapshotFile = $Path
    $script:SnapshotData = [System.Collections.Generic.List[object]]::new()
}

function Save-Snapshot {
    param(
        [string] $Module,
        [string] $Key,
        $CurrentValue,
        [string] $Type
    )
    $exists = $script:SnapshotData | Where-Object { $_.Key -eq $Key }
    if ($exists) { return }

    if ([string]::IsNullOrWhiteSpace($Type)) {
        if ($Key -like 'Service:*') {
            $Type = 'Service'
        } else {
            $Type = 'Registry'
        }
    }

    $entry = [PSCustomObject]@{
        Module    = $Module
        Key       = $Key
        Value     = $CurrentValue
        Type      = $Type
        Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    }
    $script:SnapshotData.Add($entry)

    $script:SnapshotData | ConvertTo-Json -Depth 5 | Set-Content -Path $script:SnapshotFile -Encoding UTF8
    Write-Log -Level INFO -Module $Module -Message "Snapshot saved: $Key = $CurrentValue"
}

function Remove-EmptyRegistryKey {
    param([string] $Path)

    if (-not (Test-Path $Path)) { return }

    $item = Get-Item -Path $Path -ErrorAction SilentlyContinue
    if (-not $item) { return }

    $hasSubKeys = (@($item.GetSubKeyNames()).Count -gt 0)
    $propertyCount = @($item.Property | Where-Object { $_ -ne '(default)' }).Count

    if (-not $hasSubKeys -and $propertyCount -eq 0) {
        Remove-Item -Path $Path -Force -ErrorAction SilentlyContinue
    }
}

function ConvertTo-SnapshotEntryList {
    param($InputObject)

    $list = [System.Collections.Generic.List[object]]::new()

    if ($null -eq $InputObject) {
        return (, $list)
    }

    foreach ($item in @($InputObject)) {
        if ($null -ne $item) {
            $list.Add($item)
        }
    }

    return (, $list)
}

function Get-SnapshotEntries {
    param([string] $Module = '')

    if (-not (Test-Path $script:SnapshotFile)) {
        return @()
    }

    try {
        $rawEntries = Get-Content $script:SnapshotFile -Raw | ConvertFrom-Json
        $entries = ConvertTo-SnapshotEntryList -InputObject $rawEntries
        if ($Module -ne '') {
            $entries = ConvertTo-SnapshotEntryList -InputObject ($entries | Where-Object { $_.Module -eq $Module })
        }
        return @($entries)
    } catch {
        return @()
    }
}

function Test-SnapshotAvailable {
    param([Parameter(Mandatory)][string] $Module)
    return (@(Get-SnapshotEntries -Module $Module).Count -gt 0)
}

function Restore-Snapshot {
    param(
        [switch] $DryRun,
        [string] $Module = ''
    )

    if (-not (Test-Path $script:SnapshotFile)) {
        $message = "No snapshot file found at $($script:SnapshotFile)"
        Write-Log -Level ERROR -Module 'Rollback' -Message $message
        throw [System.IO.FileNotFoundException]::new($message, $script:SnapshotFile)
    }

    $rawEntries = Get-Content $script:SnapshotFile -Raw | ConvertFrom-Json
    $entries = ConvertTo-SnapshotEntryList -InputObject $rawEntries

    if ($Module -ne '') {
        $entries = ConvertTo-SnapshotEntryList -InputObject ($entries | Where-Object { $_.Module -eq $Module })
    }

    if ($entries.Count -gt 1) {
        [System.Array]::Reverse($entries)
    }

    foreach ($entry in $entries) {
        $entryKey = [string] $entry.Key

        if ($entry.Type -eq 'PowerScheme') {
            if ($null -eq $entry.Value -or [string]::IsNullOrWhiteSpace([string]$entry.Value)) {
                Write-Log -Level WARN -Module 'Rollback' -Message "Skipping power scheme restore because the original value is unavailable"
                continue
            }
            if ($DryRun) {
                Write-Log -Level DRY -Module 'Rollback' -Message "Would restore active power scheme='$($entry.Value)'"
            } else {
                & powercfg /setactive ([string]$entry.Value) | Out-Null
                if ($LASTEXITCODE -ne 0) { throw "Failed to restore active power scheme '$($entry.Value)'" }
                Write-Log -Level INFO -Module 'Rollback' -Message "Restored active power scheme='$($entry.Value)'"
            }
            continue
        }

        if ($entry.Type -eq 'PowerSettingAc') {
            if ($entryKey -notmatch '^PowerCfg:HighPerformance:(?<Name>StandbyAC|MonitorAC)$' -or $null -eq $entry.Value) {
                Write-Log -Level WARN -Module 'Rollback' -Message "Skipping invalid power setting snapshot entry key='$entryKey'"
                continue
            }
            $highPerformanceGuid = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
            $subGroup = if ($Matches.Name -eq 'StandbyAC') { 'SUB_SLEEP' } else { 'SUB_VIDEO' }
            $setting = if ($Matches.Name -eq 'StandbyAC') { 'STANDBYIDLE' } else { 'VIDEOIDLE' }
            if ($DryRun) {
                Write-Log -Level DRY -Module 'Rollback' -Message "Would restore power setting key='$entryKey' value='$($entry.Value)'"
            } else {
                & powercfg /setacvalueindex $highPerformanceGuid $subGroup $setting ([string]$entry.Value) | Out-Null
                if ($LASTEXITCODE -ne 0) { throw "Failed to restore power setting '$entryKey'" }
                Write-Log -Level INFO -Module 'Rollback' -Message "Restored power setting key='$entryKey' value='$($entry.Value)'"
            }
            continue
        }

        if ($entry.Type -eq 'PowerHibernate') {
            if ($null -eq $entry.Value) {
                Write-Log -Level WARN -Module 'Rollback' -Message 'Skipping hibernate restore because the original value is unavailable'
                continue
            }
            $hibernateAction = if ([int]$entry.Value -eq 0) { 'off' } else { 'on' }
            if ($DryRun) {
                Write-Log -Level DRY -Module 'Rollback' -Message "Would restore hibernate action='$hibernateAction'"
            } else {
                & powercfg /hibernate $hibernateAction | Out-Null
                if ($LASTEXITCODE -ne 0) { throw "Failed to restore hibernate action '$hibernateAction'" }
                Write-Log -Level INFO -Module 'Rollback' -Message "Restored hibernate action='$hibernateAction'"
            }
            continue
        }

        if ($entry.Type -eq 'WindowsRE') {
            if ($entry.Value -notin @('enabled', 'disabled')) {
                Write-Log -Level WARN -Module 'Rollback' -Message "Skipping Windows RE restore because the original value is unavailable"
                continue
            }
            $reagentArgument = if ($entry.Value -eq 'enabled') { '/enable' } else { '/disable' }
            if ($DryRun) {
                Write-Log -Level DRY -Module 'Rollback' -Message "Would restore Windows RE status='$($entry.Value)'"
            } else {
                & reagentc $reagentArgument | Out-Null
                if ($LASTEXITCODE -ne 0) { throw "Failed to restore Windows RE status '$($entry.Value)'" }
                Write-Log -Level INFO -Module 'Rollback' -Message "Restored Windows RE status='$($entry.Value)'"
            }
            continue
        }

        if ($entry.Type -eq 'ServiceStatus') {
            if ($entryKey -notmatch '^Service:(?<Name>[^:]+):Status$') {
                Write-Log -Level WARN -Module 'Rollback' -Message "Skipping invalid service status snapshot entry key='$entryKey'"
                continue
            }
            $svcName = [string]$Matches.Name
            if ($DryRun) {
                Write-Log -Level DRY -Module 'Rollback' -Message "Would restore service '$svcName' Status=$($entry.Value)"
            } else {
                if ($entry.Value -eq 'Running') {
                    Start-Service -Name $svcName -ErrorAction Stop
                } elseif ($entry.Value -eq 'Stopped') {
                    Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
                }
                Write-Log -Level INFO -Module 'Rollback' -Message "Restored service '$svcName' Status=$($entry.Value)"
            }
            continue
        }

        if ($entryKey -like 'Service:*') {
            if ($entryKey -notmatch '^Service:(?<Name>[^:]+):StartType$') {
                Write-Log -Level WARN -Module 'Rollback' -Message "Skipping invalid service snapshot entry key='$entryKey'"
                continue
            }

            $svcName   = [string] $Matches.Name
            $startType = $entry.Value
            if ($DryRun) {
                Write-Log -Level DRY -Module 'Rollback' -Message "Would restore service '$svcName' StartType=$startType"
            } else {
                Set-Service -Name $svcName -StartupType $startType -ErrorAction SilentlyContinue
                Write-Log -Level INFO -Module 'Rollback' -Message "Restored service '$svcName' StartType=$startType"
            }
        } else {
            $separatorIndex = $entryKey.LastIndexOf('\')
            if ($separatorIndex -lt 0) {
                Write-Log -Level WARN -Module 'Rollback' -Message "Skipping invalid registry snapshot entry key='$entryKey'"
                continue
            }

            $regPath = [string] $entryKey.Substring(0, $separatorIndex)
            $regName = [string] $entryKey.Substring($separatorIndex + 1)
            if ($DryRun) {
                Write-Log -Level DRY -Module 'Rollback' -Message "Would restore $entryKey = $($entry.Value)"
            } else {
                if ($null -eq $entry.Value) {
                    Remove-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue
                    Remove-EmptyRegistryKey -Path $regPath
                } else {
                    New-Item -Path $regPath -Force -ErrorAction SilentlyContinue | Out-Null
                    New-ItemProperty -Path $regPath -Name $regName -Value $entry.Value -Force -ErrorAction SilentlyContinue | Out-Null
                }
                Write-Log -Level INFO -Module 'Rollback' -Message "Restored $entryKey = $($entry.Value)"
            }
        }
    }
}
