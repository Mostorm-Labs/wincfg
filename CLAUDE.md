# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Project: Windows Config Automation Tool

PowerShell-based automation tool that configures Windows for unattended/kiosk use cases (Zoom Rooms, meeting room devices). Hosted under the Mostorm-Labs GitHub organization.

## File Structure

- `scripts/winconf.ps1` — main entry point
- `scripts/lib/` — shared helpers (Logger, Registry, Service, Snapshot)
- `scripts/modules/` — one file per feature area (Power, ScreenLock, WindowsUpdate, Cortana, Notifications, Privacy, UI)
- `service/winconf-agent/` — background service (PowerShell + NSSM)
- `docs/` — SPEC.md, PLAN.md

## Running the Script

```powershell
# Preview all changes (no writes)
.\scripts\winconf.ps1 -DryRun -Verbose

# Apply all modules
.\scripts\winconf.ps1

# Apply a single module
.\scripts\winconf.ps1 -Module Power

# Roll back all changes
.\scripts\winconf.ps1 -Rollback
```

## Installing the Background Service

```powershell
# Requires nssm.exe in PATH or service/winconf-agent/
.\service\winconf-agent\Install-Service.ps1 -Install
.\service\winconf-agent\Install-Service.ps1 -Remove
```

## Coding Rules

- Every module exposes a single `Invoke-<Name> [-DryRun]` function
- All registry/service writes go through `lib/Registry.ps1` and `lib/Service.ps1` — never call `Set-ItemProperty` or `sc config` directly in modules
- Call `Save-Snapshot` before every write (already handled inside `Set-RegValue` and `Set-ServiceStartType`)
- Log every operation via `Write-Log`; never use `Write-Host` directly in modules
- Scripts must be idempotent — safe to run multiple times
- All changes must be reversible via `-Rollback`
- Support `-DryRun` in every module

## Commit Convention

- Format: `type(scope): message` — e.g. `feat(power): disable hibernate`, `fix(snapshot): handle null registry value`
- Types: `feat`, `fix`, `refactor`, `docs`, `chore`
- Scope = module or lib name (lowercase)
- Keep subject line under 72 characters
- Write in English

## Tech Stack

- PowerShell 5.1+ (primary)
- NSSM (background service wrapper)
- Windows Registry API via PowerShell cmdlets
