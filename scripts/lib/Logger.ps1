# Logger.ps1 — Logging helper
# Usage: dot-source this file, then call Write-Log

$script:LogFile = "C:\ProgramData\WinConf\winconf.log"
$script:VerboseLogging = $false

function Initialize-Logger {
    param(
        [string] $LogPath = $script:LogFile,
        [switch] $Verbose
    )
    $script:LogFile = $LogPath
    $script:VerboseLogging = $Verbose.IsPresent

    $dir = Split-Path $LogPath -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

function Write-Log {
    param(
        [ValidateSet("INFO","WARN","ERROR","DRY")]
        [string] $Level = "INFO",
        [string] $Module = "MAIN",
        [string] $Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Module] [$Level] $Message"

    Add-Content -Path $script:LogFile -Value $line -Encoding UTF8

    if ($script:VerboseLogging -or $Level -eq "ERROR" -or $Level -eq "WARN") {
        switch ($Level) {
            "ERROR" { Write-Host $line -ForegroundColor Red }
            "WARN"  { Write-Host $line -ForegroundColor Yellow }
            "DRY"   { Write-Host $line -ForegroundColor Cyan }
            default { Write-Host $line }
        }
    }
}
