# winconf-agent.ps1 — Background service worker
# Runs as a Windows service via NSSM.
# Monitors critical registry keys and re-applies them if reverted by Windows Update.
#
# Install via: .\Install-Service.ps1 -Install
# Remove via:  .\Install-Service.ps1 -Remove

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# ── Paths ─────────────────────────────────────────────────────────────────────
$dataDir  = "C:\ProgramData\WinConf"
$logFile  = "$dataDir\agent.log"
$confFile = "$dataDir\agent-watch.json"

# ── Logging (standalone, no dot-source dependency) ────────────────────────────
function Write-AgentLog {
    param(
        [ValidateSet("INFO","WARN","ERROR")] [string] $Level = "INFO",
        [string] $Message
    )
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [AGENT] [$Level] $Message"
    Add-Content -Path $logFile -Value $line -Encoding UTF8

    # Also write to Windows Event Log
    $entryType = switch ($Level) {
        "ERROR" { "Error" }
        "WARN"  { "Warning" }
        default { "Information" }
    }
    try {
        Write-EventLog -LogName Application -Source "WinConf" -EventId 1000 `
            -EntryType $entryType -Message $Message
    } catch {
        # Event source may not be registered yet; silently ignore
    }
}

# ── Event Log source registration ─────────────────────────────────────────────
function Register-EventSource {
    if (-not [System.Diagnostics.EventLog]::SourceExists("WinConf")) {
        New-EventLog -LogName Application -Source "WinConf"
        Write-AgentLog -Level INFO -Message "Registered Windows Event Log source 'WinConf'"
    }
}

# ── Watch list ────────────────────────────────────────────────────────────────
# Defines the registry keys the agent enforces.
# Loaded from agent-watch.json if present, otherwise uses built-in defaults.
function Get-WatchList {
    if (Test-Path $confFile) {
        return Get-Content $confFile -Raw | ConvertFrom-Json
    }

    # Built-in defaults: the most commonly reverted keys
    return @(
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"; Name = "NoAutoUpdate";  Value = 1 },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"; Name = "AUOptions";     Value = 1 },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection";   Name = "AllowTelemetry"; Value = 0 },
        @{ Path = "HKCU:\Control Panel\Desktop";                                Name = "ScreenSaveActive"; Value = "0" },
        @{ Path = "HKCU:\Control Panel\Desktop";                                Name = "ScreenSaverIsSecure"; Value = "0" }
    )
}

# ── Enforce a single key ──────────────────────────────────────────────────────
function Assert-RegValue {
    param($Entry)
    try {
        $current = (Get-ItemProperty -Path $Entry.Path -Name $Entry.Name -ErrorAction Stop).$($Entry.Name)
        if ("$current" -ne "$($Entry.Value)") {
            Write-AgentLog -Level WARN -Message "Drift detected: $($Entry.Path)\$($Entry.Name) = $current (expected $($Entry.Value)), re-applying"
            if (-not (Test-Path $Entry.Path)) {
                New-Item -Path $Entry.Path -Force | Out-Null
            }
            Set-ItemProperty -Path $Entry.Path -Name $Entry.Name -Value $Entry.Value
            Write-AgentLog -Level INFO -Message "Re-applied: $($Entry.Path)\$($Entry.Name) = $($Entry.Value)"
        }
    } catch {
        Write-AgentLog -Level ERROR -Message "Failed to check $($Entry.Path)\$($Entry.Name): $_"
    }
}

# ── Main loop ─────────────────────────────────────────────────────────────────
function Start-Agent {
    param([int] $IntervalSeconds = 300)  # check every 5 minutes

    if (-not (Test-Path $dataDir)) {
        New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
    }

    Register-EventSource
    Write-AgentLog -Level INFO -Message "winconf-agent started (interval=${IntervalSeconds}s)"

    while ($true) {
        $watchList = Get-WatchList
        foreach ($entry in $watchList) {
            Assert-RegValue -Entry $entry
        }
        Start-Sleep -Seconds $IntervalSeconds
    }
}

Start-Agent
