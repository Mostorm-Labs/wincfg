# SPEC — Windows Config Automation Tool

**Date:** 2026-03-19

---

## 1. Script Interface

```
winconf.ps1 [-DryRun] [-Verbose] [-Rollback] [-Module <name>]
```

| Flag        | Type   | Description                                              |
| ----------- | ------ | -------------------------------------------------------- |
| `-DryRun`   | switch | Print what would change; make no writes                  |
| `-Verbose`  | switch | Print each registry/service operation to console         |
| `-Rollback` | switch | Restore all values from snapshot, then exit              |
| `-Module`   | string | Run only the named module (e.g. `Power`, `ScreenLock`)   |

---

## 2. Lib Layer

### 2.1 Logger.ps1

```powershell
Write-Log -Level <string> -Module <string> -Message <string>
```

- Appends to `C:\ProgramData\WinConf\winconf.log`
- Format: `[YYYY-MM-DD HH:MM:SS] [MODULE] [LEVEL] message`
- Levels: `INFO`, `WARN`, `ERROR`
- When `-Verbose` is active, mirrors output to console via `Write-Verbose`

### 2.2 Registry.ps1

```powershell
Get-RegValue -Path <string> -Name <string>
Set-RegValue -Path <string> -Name <string> -Value <object> -Type <RegistryValueKind> [-DryRun]
```

- `Set-RegValue` calls `Save-Snapshot` before writing, then calls `Write-Log`
- In `-DryRun` mode: logs intent, skips `Set-ItemProperty`
- Creates the key path if it does not exist

### 2.3 Service.ps1

```powershell
Set-ServiceStartType -Name <string> -StartType <string> [-DryRun]
Stop-ServiceIfRunning  -Name <string> [-DryRun]
```

- `StartType` values: `Automatic`, `Manual`, `Disabled`
- Calls `Save-Snapshot` before changing start type
- Calls `Write-Log` on every operation
- In `-DryRun` mode: logs intent, skips `sc.exe` calls

### 2.4 Snapshot.ps1

```powershell
Save-Snapshot -Module <string> -Key <string> -CurrentValue <object>
Restore-Snapshot
```

- Snapshot file: `C:\ProgramData\WinConf\snapshot.json`
- Schema per entry: `{ module, key, value, type, timestamp }`
- `Restore-Snapshot` replays entries in reverse order

---

## 3. Module Layer

Every module exposes one public function: `Invoke-<ModuleName> [-DryRun]`

### 3.1 Power.ps1

| Setting              | Registry / Command                                                        | Value              |
| -------------------- | ------------------------------------------------------------------------- | ------------------ |
| High performance plan | `powercfg /setactive SCHEME_MIN`                                          | —                  |
| Sleep timeout AC     | `powercfg /change standby-timeout-ac 0`                                   | 0 (never)          |
| Sleep timeout DC     | `powercfg /change standby-timeout-dc 0`                                   | 0 (never)          |
| Display timeout AC   | `powercfg /change monitor-timeout-ac 0`                                   | 0 (never)          |
| Display timeout DC   | `powercfg /change monitor-timeout-dc 0`                                   | 0 (never)          |
| Hibernate            | `powercfg /hibernate off`                                                 | —                  |
| Fast startup         | `HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power` `HiberbootEnabled` DWORD `0` | 0 |

### 3.2 ScreenLock.ps1

| Setting              | Registry Path                                      | Name                    | Value | Type   |
| -------------------- | -------------------------------------------------- | ----------------------- | ----- | ------ |
| Screen saver enabled | `HKCU:\Control Panel\Desktop`                      | `ScreenSaveActive`      | `0`   | String |
| Screen saver timeout | `HKCU:\Control Panel\Desktop`                      | `ScreenSaveTimeOut`     | `0`   | String |
| Lock on resume       | `HKCU:\Control Panel\Desktop`                      | `ScreenSaverIsSecure`   | `0`   | String |
| Idle lock (GPO)      | `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System` | `InactivityTimeoutSecs` | `0` | DWORD |

### 3.3 WindowsUpdate.ps1

| Setting                    | Registry Path                                                                 | Name             | Value | Type  |
| -------------------------- | ----------------------------------------------------------------------------- | ---------------- | ----- | ----- |
| Disable auto update        | `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU`                  | `NoAutoUpdate`   | `1`   | DWORD |
| Delivery Optimization      | `HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization`              | `DODownloadMode` | `0`   | DWORD |
| wuauserv start type        | Service `wuauserv`                                                            | —                | `Disabled` | — |
| UsoSvc start type          | Service `UsoSvc`                                                              | —                | `Disabled` | — |

### 3.4 Cortana.ps1

| Setting              | Registry Path                                                                          | Name                        | Value | Type  |
| -------------------- | -------------------------------------------------------------------------------------- | --------------------------- | ----- | ----- |
| Disable Cortana      | `HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search`                             | `AllowCortana`              | `0`   | DWORD |
| Disable web search   | `HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer`                                   | `DisableSearchBoxSuggestions` | `1` | DWORD |
| Hide taskbar button  | `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced`                    | `ShowCortanaButton`         | `0`   | DWORD |

### 3.5 Notifications.ps1

| Setting                    | Registry Path                                                                              | Name                              | Value | Type  |
| -------------------------- | ------------------------------------------------------------------------------------------ | --------------------------------- | ----- | ----- |
| Disable Action Center      | `HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer`                                       | `DisableNotificationCenter`       | `1`   | DWORD |
| Disable toast notifications | `HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications`              | `NoToastApplicationNotification`  | `1`   | DWORD |
| Disable lock screen notifs | `HKLM:\SOFTWARE\Policies\Microsoft\Windows\System`                                         | `DisableLockScreenAppNotifications` | `1` | DWORD |

### 3.6 Privacy.ps1

| Setting              | Registry Path                                                                 | Name                    | Value | Type  |
| -------------------- | ----------------------------------------------------------------------------- | ----------------------- | ----- | ----- |
| Telemetry level      | `HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection`                    | `AllowTelemetry`        | `0`   | DWORD |
| Activity history     | `HKLM:\SOFTWARE\Policies\Microsoft\Windows\System`                            | `PublishUserActivities` | `0`   | DWORD |
| DiagTrack service    | Service `DiagTrack`                                                           | —                       | `Disabled` | — |

### 3.7 UI.ps1

| Setting              | Registry Path                                                                          | Name                        | Value | Type  |
| -------------------- | -------------------------------------------------------------------------------------- | --------------------------- | ----- | ----- |
| Hide Task View button | `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced`                   | `ShowTaskViewButton`        | `0`   | DWORD |
| Disable News/Interests | `HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds`                            | `EnableFeeds`               | `0`   | DWORD |
| Hide Meet Now        | `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer`                   | `HideMeetNow`               | `1`   | DWORD |
| Disable edge gestures | `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell`                     | `EdgeUI\DisabledEdgeSwipe`  | `1`   | DWORD |

---

## 4. Background Service — winconf-agent

| Property       | Value                                      |
| -------------- | ------------------------------------------ |
| Wrapper        | NSSM                                       |
| Script         | `service/winconf-agent/winconf-agent.ps1`  |
| Poll interval  | 5 minutes                                  |
| Watch list     | `agent-watch.json` (falls back to defaults)|
| Event log      | Windows Event Log, source `WinConf`        |
| Log rotation   | NSSM, max 5 MB                             |

On drift detection: write `WARN` log entry, re-invoke the affected `Set-RegValue` or `Set-ServiceStartType` call.

---

## 5. File & Data Paths

| Artifact        | Path                                    |
| --------------- | --------------------------------------- |
| Log file        | `C:\ProgramData\WinConf\winconf.log`    |
| Snapshot        | `C:\ProgramData\WinConf\snapshot.json`  |
| Watch list      | `C:\ProgramData\WinConf\agent-watch.json` |

---

## 6. Error Handling

- Registry key path does not exist → create it, then write
- Service not found → log `WARN`, skip (do not throw)
- `powercfg` exits non-zero → log `ERROR`, continue remaining steps
- Snapshot file missing on `-Rollback` → log `ERROR`, exit with code 1
