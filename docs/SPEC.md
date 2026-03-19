# SPEC.md — Windows Config Automation Tool

## Overview

A PowerShell-based automation tool that configures Windows for unattended/kiosk use cases (e.g., Zoom Rooms, digital signage, meeting room devices). All changes are idempotent, reversible, and logged.

---

## Target Environment

- OS: Windows 10 / Windows 11 (Pro or Enterprise)
- Use case: Dedicated-purpose devices (meeting rooms, kiosks, always-on displays)
- Run context: Local admin or SYSTEM account

---

## Configuration Modules

### 1. Power Management

| Setting | Value | Method |
|---|---|---|
| Power plan | High Performance | `powercfg /setactive` |
| Sleep timeout (AC) | Never | `powercfg /change` |
| Hibernate | Disabled | `powercfg /hibernate off` |
| Display timeout (AC) | Never | `powercfg /change` |
| Fast startup | Disabled | Registry `HiberbootEnabled=0` |

### 2. Screen Lock / Auto-Lock

| Setting | Value | Method |
|---|---|---|
| Screen saver | Disabled | Registry `ScreenSaveActive=0` |
| Screen saver timeout | 0 | Registry `ScreenSaveTimeOut=0` |
| Lock on resume | Disabled | Registry `ScreenSaverIsSecure=0` |
| Idle lock (GPO) | Disabled | Registry `InactivityTimeoutSecs=0` |

### 3. Windows Update

| Setting | Value | Method |
|---|---|---|
| Automatic updates | Disabled | Registry `NoAutoUpdate=1` |
| Windows Update service | Disabled | `sc config wuauserv start= disabled` |
| Update Orchestrator service | Disabled | `sc config UsoSvc start= disabled` |
| Delivery Optimization | Disabled | Registry `DODownloadMode=0` |

### 4. Cortana & Search

| Setting | Value | Method |
|---|---|---|
| Cortana | Disabled | Registry `AllowCortana=0` |
| Web search in Start | Disabled | Registry `DisableSearchBoxSuggestions=1` |
| Cortana on taskbar | Hidden | Registry `ShowCortanaButton=0` |

### 5. Notifications

| Setting | Value | Method |
|---|---|---|
| Action Center | Disabled | Registry `DisableNotificationCenter=1` |
| Toast notifications | Disabled | Registry `ToastEnabled=0` |
| Lock screen notifications | Disabled | Registry `DisableLockScreenAppNotifications=1` |

### 6. Privacy & Telemetry

| Setting | Value | Method |
|---|---|---|
| Telemetry level | Security (0) | Registry `AllowTelemetry=0` |
| DiagTrack service | Disabled | `sc config DiagTrack start= disabled` |
| Activity history | Disabled | Registry `PublishUserActivities=0` |

### 7. UI Cleanup

| Setting | Value | Method |
|---|---|---|
| Task View button | Hidden | Registry `ShowTaskViewButton=0` |
| News and Interests | Disabled | Registry `ShellFeedsTaskbarViewMode=2` |
| Meet Now | Hidden | Registry `HideMeetNow=1` |
| Auto-hide taskbar | Optional | Registry `AutoHide=1` |

### 8. Background Service (Optional)

A lightweight Windows service (`winconf-agent`) that:
- Monitors and re-applies critical settings if reverted by Windows Update
- Exposes a named pipe for status queries
- Logs to Windows Event Log under source `WinConf`

Implementation: C++ (Win32 service) or PowerShell with NSSM wrapper.

---

## Script Interface

```
winconf.ps1 [-DryRun] [-Verbose] [-Rollback] [-Module <name>]
```

| Flag | Description |
|---|---|
| `-DryRun` | Show what would change, make no modifications |
| `-Verbose` | Print each registry/service operation |
| `-Rollback` | Restore from saved backup snapshot |
| `-Module` | Run only a specific module (e.g., `Power`, `Updates`) |

---

## Logging

- Log file: `C:\ProgramData\WinConf\winconf.log`
- Format: `[YYYY-MM-DD HH:MM:SS] [MODULE] [ACTION] key=value`
- Backup snapshot: `C:\ProgramData\WinConf\snapshot.json` (saved before any change)

---

## Rollback

Before applying any change, the script saves the current value to `snapshot.json`. Running with `-Rollback` restores all saved values in reverse order.

---

## File Structure

```
winconf/
├── scripts/
│   ├── winconf.ps1          # Main entry point
│   ├── modules/
│   │   ├── Power.ps1
│   │   ├── ScreenLock.ps1
│   │   ├── WindowsUpdate.ps1
│   │   ├── Cortana.ps1
│   │   ├── Notifications.ps1
│   │   ├── Privacy.ps1
│   │   └── UI.ps1
│   └── lib/
│       ├── Registry.ps1     # Registry read/write helpers
│       ├── Service.ps1      # Service management helpers
│       └── Logger.ps1       # Logging helpers
├── service/
│   └── winconf-agent/       # Optional C++ background service
├── docs/
│   └── SPEC.md
├── CLAUDE.md
└── README.md
```

---

## Testing

- Each module should be testable in isolation via `-Module <name> -DryRun`
- Validate on: Windows 10 21H2+, Windows 11 22H2+
- Test both standard user (expect elevation prompt) and SYSTEM account contexts
