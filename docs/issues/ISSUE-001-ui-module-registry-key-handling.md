# Issue Analysis: GitHub Issue #1

Source: https://github.com/Mostorm-Labs/wincfg/issues/1

## 1. Feature ID

**WINCFG-UI-001**  
UI module must safely apply taskbar-related registry settings when target registry keys or values are missing or unavailable.

## 2. Clear Requirement

The `UI` module shall apply the configured taskbar UI settings without failing due to a missing registry key, missing registry value, or unsupported taskbar feature path.

Specifically:

- Before writing a registry value, the system shall verify whether the target registry key exists.
- If the key does not exist and the setting is valid for the current OS/context, the system shall create the key before writing the value.
- If the setting is not supported on the current Windows version, edition, or user context, the module shall not terminate unexpectedly; it shall log the condition explicitly and continue or exit according to defined policy.
- The module shall distinguish between:
  - missing key/value,
  - access denied / unauthorized operation,
  - unsupported OS feature,
  - invalid registry path/value definition.

## 3. System-Level Operations

### Registry

Observed target paths/values from the issue:

- `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced`
  - `ShowTaskViewButton`
  - `TaskbarDa`
- `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds`
  - `ShellFeedsTaskbarViewMode`

Required system-level behavior:

- Check existence of registry key:
  - `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced`
  - `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds`
- Create missing key only if the setting is valid and intended to exist on that OS/profile.
- Write registry value with the correct value type.
- Read current value first for snapshot/rollback logging.
- Log exact failure reason if write is rejected.

### Command / Execution Context

Issue evidence shows execution via:

- `powershell -ExecutionPolicy Bypass -File .\winconf.ps1 -Module UI -Verbose`

Operational expectations:

- Run in the current user context because the paths are under `HKCU`.
- Detect whether the current shell/token has sufficient rights for the target operation.
- Do not treat all registry write failures as "missing key" problems; unauthorized access must remain a separate error class.

### Service

No Windows service interaction is explicitly required by the issue.

Potential indirect shell/UI refresh behavior is not specified in the issue.

## 4. Acceptance Criteria

### Functional

- When the `UI` module processes a registry-backed UI setting and the target key already exists, the value is written successfully and logged.
- When the target key does not exist but is valid for the current OS and feature, the key is created and the value is written successfully.
- When the target setting is unsupported on the current Windows version or feature state, the module logs `unsupported setting/path` explicitly.
- The module must not fail with an ambiguous generic error when the actual condition is `missing key`.
- The module must not misclassify `access denied` as `missing key`.

### Logging / Diagnostics

- Logs must identify:
  - registry path,
  - value name,
  - intended value,
  - whether key was created,
  - whether failure was due to missing key, access denial, or unsupported setting.
- If a module step fails, the failing registry operation must be identifiable from logs without reading source code.

### Stability

- A failure on one registry-backed UI setting must not cause silent corruption of snapshot/rollback state.
- Behavior on failure must be deterministic:
  - either stop the module with a precise error,
  - or continue and report partial completion,
  - but this policy must be defined and consistent.

## 5. Risks

- **OS compatibility risk**: `Feeds` / `News and Interests` behavior differs across Windows 10 and Windows 11; some keys may be absent by design.
- **Privilege/context risk**: even under `HKCU`, policy, profile state, or shell context may block modification.
- **Wrong root-cause assumption**: the issue suggests the key may be missing, but the logged error is `unauthorized operation`; these are not the same failure mode.
- **Value-type risk**: incorrect registry value type can produce write failures or ineffective settings.
- **Rollback risk**: creating a missing key changes rollback semantics; rollback must know whether to delete the created key or only restore prior values.
- **Feature drift risk**: Microsoft may deprecate or ignore some taskbar registry settings on newer builds.

## 6. Missing Information

- Exact Windows version/build where the failure occurred.
- Whether the machine is Windows 10 or Windows 11.
- Whether `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds` existed before execution.
- Exact registry value type expected for:
  - `TaskbarDa`
  - `ShellFeedsTaskbarViewMode`
- Whether the intended behavior for unsupported settings is:
  - fail the module,
  - skip with warning,
  - or continue with partial success.
- Whether explorer/taskbar refresh or sign-out/restart is required for the change to take effect.
- Whether rollback should remove newly created keys or only restore values.
- Whether the product officially supports OS-conditional settings in a single `UI` module.

## Suggested Interpretation of the Issue

The most likely requirement behind the issue is:

> The `UI` module must safely handle missing or unsupported registry paths for taskbar configuration, especially `Feeds`-related settings, and must report the exact cause instead of failing with a generic unauthorized-operation error.
