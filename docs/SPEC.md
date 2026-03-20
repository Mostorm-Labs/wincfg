# SPEC 鈥?Windows Config Automation Tool

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
- Must log the registry path, value name, intended value, and prior value when available
- Must distinguish these outcomes explicitly in logs and error handling:
  - missing registry key/value
  - access denied / unauthorized operation
  - unsupported registry path/value for current OS
  - invalid registry definition
- If a registry path is OS-specific or optional, the module must follow module-level policy for skip vs fail; it must not return an ambiguous generic error

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
| High performance plan | `powercfg /setactive SCHEME_MIN`                                          | 鈥?                 |
| Sleep timeout AC     | `powercfg /change standby-timeout-ac 0`                                   | 0 (never)          |
| Sleep timeout DC     | `powercfg /change standby-timeout-dc 0`                                   | 0 (never)          |
| Display timeout AC   | `powercfg /change monitor-timeout-ac 0`                                   | 0 (never)          |
| Display timeout DC   | `powercfg /change monitor-timeout-dc 0`                                   | 0 (never)          |
| Hibernate            | `powercfg /hibernate off`                                                 | 鈥?                 |
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
| wuauserv start type        | Service `wuauserv`                                                            | 鈥?               | `Disabled` | 鈥?|
| UsoSvc start type          | Service `UsoSvc`                                                              | 鈥?               | `Disabled` | 鈥?|

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
| DiagTrack service    | Service `DiagTrack`                                                           | 鈥?                      | `Disabled` | 鈥?|

### 3.7 UI.ps1

| Setting              | Registry Path                                                                          | Name                        | Value | Type  |
| -------------------- | -------------------------------------------------------------------------------------- | --------------------------- | ----- | ----- |
| Hide Task View button | `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced`                   | `ShowTaskViewButton`        | `0`   | DWORD |
| Disable News/Interests (policy path) | `HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds`            | `EnableFeeds`               | `0`   | DWORD |
| Disable News/Interests (user path, Windows-version dependent) | `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds` | `ShellFeedsTaskbarViewMode` | `2`   | DWORD |
| Hide widgets / Chat-style taskbar entry (Windows-version dependent) | `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced` | `TaskbarDa` | `0` | DWORD |
| Hide Meet Now        | `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer`                   | `HideMeetNow`               | `1`   | DWORD |
| Disable edge gestures | `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell`                     | `EdgeUI\DisabledEdgeSwipe`  | `1`   | DWORD |

UI module policy:

- UI settings related to News/Interests, Feeds, Widgets, or taskbar-integrated shell features are Windows-version dependent.
- Before writing an OS-specific UI setting, the module must verify whether the target registry path/value is applicable on the current Windows build and user context.
- If the path is absent but valid for the current OS/context, create the key and write the value.
- If the path/value is unsupported for the current OS/context, log `WARN` and skip that setting unless the setting is marked mandatory by a future spec revision.
- Access denied / unauthorized failures must be logged as `ERROR` with the exact path and value name.

---

## 4. Background Service 鈥?winconf-agent

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

- Registry key path does not exist -> create it, then write
- Registry value does not exist -> create it if the path/value is valid for the current OS/context
- Access denied / unauthorized operation during registry write -> log `ERROR` with path and value name; do not classify as missing key
- Unsupported OS-specific registry path/value -> log `WARN`, skip that setting, continue remaining steps
- Invalid registry path/value definition in module config -> log `ERROR` and fail the affected module
- Service not found -> log `WARN`, skip (do not throw)
- `powercfg` exits non-zero -> log `ERROR`, continue remaining steps
- Snapshot file missing on `-Rollback` -> log `ERROR`, exit with code 1
