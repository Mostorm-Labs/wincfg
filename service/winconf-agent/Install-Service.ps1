# Install-Service.ps1 — Install or remove the winconf-agent Windows service
# Requires: NSSM (Non-Sucking Service Manager) in PATH or same directory
# Usage:
#   .\Install-Service.ps1 -Install
#   .\Install-Service.ps1 -Remove

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [switch] $Install,
    [switch] $Remove,
    [int]    $IntervalSeconds = 300
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$serviceName  = "WinConfAgent"
$displayName  = "WinConf Agent"
$description  = "Monitors and re-applies WinConf settings if reverted by Windows Update."
$agentScript  = Join-Path $PSScriptRoot "winconf-agent.ps1"
$pwshExe      = (Get-Command powershell.exe).Source

# Locate NSSM
function Get-Nssm {
    $local = Join-Path $PSScriptRoot "nssm.exe"
    if (Test-Path $local) { return $local }
    $inPath = Get-Command nssm.exe -ErrorAction SilentlyContinue
    if ($inPath) { return $inPath.Source }
    throw "nssm.exe not found. Download from https://nssm.cc and place it next to this script or add it to PATH."
}

function Install-Agent {
    $nssm = Get-Nssm

    if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
        Write-Host "Service '$serviceName' already exists. Run with -Remove first to reinstall."
        exit 1
    }

    $args = "-NonInteractive -NoProfile -ExecutionPolicy Bypass -File `"$agentScript`""

    & $nssm install $serviceName $pwshExe $args
    & $nssm set     $serviceName DisplayName  $displayName
    & $nssm set     $serviceName Description  $description
    & $nssm set     $serviceName Start        SERVICE_AUTO_START
    & $nssm set     $serviceName AppStdout    "C:\ProgramData\WinConf\agent-stdout.log"
    & $nssm set     $serviceName AppStderr    "C:\ProgramData\WinConf\agent-stderr.log"
    & $nssm set     $serviceName AppRotateFiles 1
    & $nssm set     $serviceName AppRotateBytes 5242880  # 5 MB

    Start-Service -Name $serviceName
    Write-Host "Service '$serviceName' installed and started."
}

function Remove-Agent {
    $nssm = Get-Nssm

    $svc = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if (-not $svc) {
        Write-Host "Service '$serviceName' not found."
        exit 0
    }

    if ($svc.Status -eq "Running") {
        Stop-Service -Name $serviceName -Force
    }

    & $nssm remove $serviceName confirm
    Write-Host "Service '$serviceName' removed."
}

# ── Entry point ───────────────────────────────────────────────────────────────
if ($Install -and $Remove) {
    Write-Error "Specify either -Install or -Remove, not both."
    exit 1
}

if ($Install) { Install-Agent }
elseif ($Remove) { Remove-Agent }
else {
    Write-Host "Usage: .\Install-Service.ps1 -Install | -Remove"
    exit 1
}
