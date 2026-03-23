# Issue Analysis: GitHub Issue #5

Source Issue: https://github.com/Mostorm-Labs/wincfg/issues/5  
Source Attachment: `10. OPS 禁用win系统更新_系统恢复.pdf`

## 1. Feature ID

**WINCFG-WU-005**

Windows Update control must be redefined as a policy-driven feature set that:

- disables automatic Windows Update behaviors,
- suppresses update-related UI entry points and notifications,
- preserves Microsoft Store availability,
- and defines a separate `WindowsRestore` module for the "system restore" requirement.

## 2. Clear Requirement

The system shall implement Windows Update restriction through policy-compatible registry settings and related policy-refresh commands, not by disabling core update services.

The feature shall satisfy all of the following requirements:

1. Automatic Windows Update checks and install flows shall be disabled through policy-backed registry settings.
2. Update notifications and update-related shutdown options shall be suppressed where supported by the target Windows version.
3. Driver delivery through Windows Update shall be disabled.
4. The Windows Update entry point in Settings shall be hidden from the user.
5. Microsoft Store availability shall be preserved. The feature must not disable update-related services in a way that breaks Store access.
6. Because the `WindowsUpdate` feature now contains many registry-backed policy items, the implementation shall consolidate those settings through shared metadata / descriptor-driven registry governance instead of scattering them as long sequences of ad hoc writes.
7. The implementation shall support modern Windows policy drift by allowing different registry coverage for Windows 11 23H2, 24H2, and 25H2+.
8. The feature shall include a separate `WindowsRestore` module:
   - `reagentc /disable` shall be used by `WindowsRestore` to make system restore points not discoverable / not usable through the user-facing restore flow.
   - `reagentc /enable` shall be used by `WindowsRestore` as the recovery path to restore that capability.
9. The product shall treat the `WindowsUpdate` policy flow and the `WindowsRestore` `reagentc` flow as part of the same feature area for this issue, but not as the same module.

## 3. System-Level Operations

### Registry

Required registry-backed operations identified from the issue attachment:

- `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU`
  - `NoAutoUpdate = 1`
  - `AUOptions = 1`
  - `NoAUShutdownOption = 1`
  - `NoAUAsDefaultShutdownOption = 1`
  - `NoAutoRebootWithLoggedOnUsers = 1`

- `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`
  - `SetAutoRestartNotificationDisable = 1`
  - `SetUpdateNotificationLevel = 2`
  - `ExcludeWUDriversInQualityUpdate = 1`
  - `DisableOSUpgrade = 1`

- `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer`
  - `SettingsPageVisibility = "hide:windowsupdate-action"`

- `HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore`
  - `RemoveWindowsStore = 0`
  - `AutoDownload = 4`

- `HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings`
  - `RestartNotificationsAllowed2 = 0`
  - `HideWUXMessages = 1`

- `HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update`
  - `AllowAutoUpdate = 0`
  - `DoNotShowUpdateNotifications = 1`
  - `HideUpdatePowerOption = 1`
  - `ExcludeWUDriversInQualityUpdate = 1`

- `HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Store`
  - `AllowStore = 1`
  - `AutoDownload = 4`

- `HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Settings`
  - `SettingsPageVisibility = "hide:windowsupdate-action"`

### Command

System-level commands explicitly referenced by the issue attachment:

- `gpupdate /force`
  Purpose:
  Refresh local policy application after registry-backed policy writes.

- `reagentc /disable`
  Purpose:
  Used by the dedicated `WindowsRestore` module to disable the restore capability used by the product requirement so restore points are not discoverable / usable from the normal user-facing restore flow.

- `reagentc /enable`
  Purpose:
  Used by the dedicated `WindowsRestore` module to re-enable that restore capability as the supported reverse operation.

### Service

The attachment explicitly states that core Windows Update services should not be disabled as part of this feature because doing so may affect Microsoft Store behavior, and this direction is now confirmed for the project requirement.

Services that shall not be disabled by the Windows Update feature implementation:

- `wuauserv`
- `UsoSvc`
- and, by rationale, similar update infrastructure services such as `BITS` or `WaaSMedicSvc`

## 4. Acceptance Criteria

### Functional Acceptance

- On a supported test machine, the required Windows Update policy keys are present with the exact expected values after feature execution.
- Automatic Windows Update is disabled by policy rather than by stopping or disabling `wuauserv` or `UsoSvc`.
- Windows Update notifications are suppressed where the target OS honors the corresponding policy path.
- Windows Update driver delivery is disabled.
- The Windows Update page entry in Settings is hidden through `SettingsPageVisibility`.
- Microsoft Store remains launchable and usable after the feature is applied.
- The Windows Update registry settings are maintained through a coherent metadata-driven structure rather than only by repeated per-setting imperative calls.
- `WindowsRestore` invokes `reagentc /disable` as the supported disable path for restore availability.
- `WindowsRestore` defines `reagentc /enable` as the supported reverse operation for re-enabling restore availability.

### Version-Aware Acceptance

- On Windows 11 23H2, the legacy `Policies\Microsoft\Windows\WindowsUpdate*` paths are written.
- On Windows 11 24H2, the legacy paths remain covered and the `WindowsUpdate\UX\Settings` compatibility keys are also written.
- On Windows 11 25H2 or later, `PolicyManager\current\device\*` compatibility keys are also written.
- Unsupported version-specific keys are skipped only when the applicability rule is explicit and logged clearly.

### Non-Regression Acceptance

- The feature does not disable `wuauserv` or `UsoSvc` as part of the default Windows Update control path.
- The feature does not disable Microsoft Store.
- Logs clearly distinguish:
  - policy write success,
  - unsupported version-specific key,
  - access denial,
  - and skipped optional compatibility branch.
- Logs also distinguish `WindowsUpdate` policy execution from `WindowsRestore` command execution.

### Recovery / Restore Acceptance

- After the disable flow is applied, the restore capability controlled by `reagentc` is no longer discoverable / usable in the intended user-facing path.
- After the enable flow is applied, that restore capability becomes available again.
- The restore-control behavior is implemented through `WindowsRestore`, not folded into `WindowsUpdate`.
- Logs must distinguish `WindowsUpdate` policy application from `WindowsRestore` `reagentc` execution.

## 5. Risks

- **Migration risk**: the current project logic disables `wuauserv` and `UsoSvc`, so the existing implementation contract must be changed to the new policy-only direction for Windows Update control.
- **Store compatibility risk**: disabling update services may unintentionally degrade Microsoft Store downloads, app updates, or related system functionality.
- **OS drift risk**: Windows 11 23H2, 24H2, and 25H2 appear to use different policy consumption layers, so one fixed registry set may not be sufficient.
- **Policy effectiveness risk**: some values may write successfully but not fully suppress newer UX flows on later Windows builds.
- **Governance risk**: without metadata consolidation, the expanded Windows Update policy set will become harder to maintain and more prone to path/value drift.
- **Domain management risk**: local registry-backed policies may be overwritten by domain GPO, Intune, or other MDM policy sources.
- **Operational semantics risk**: `reagentc /disable` is being adopted as the product contract for restore unavailability, so implementation and validation must be based on observed product behavior rather than on narrower terminology debates about underlying Windows subsystems.
- **Privilege risk**: registry writes under `HKLM` and `reagentc` operations both require elevated execution.

## 6. Missing Information

- Exact target Windows versions that must be supported in this project:
  - Windows 10,
  - Windows 11 23H2,
  - Windows 11 24H2,
  - Windows 11 25H2+,
  - or a narrower subset.
- Whether `DisableOSUpgrade = 1` is a required part of the product requirement or only an optional compatibility hardening item from the PDF.
- Whether all listed compatibility keys are mandatory, or whether some should be version-gated and treated as optional.
- Whether `SettingsPageVisibility` should hide only `windowsupdate-action` or a broader set of Settings pages.
- Whether preserving Microsoft Store means:
  - Store app launches successfully,
  - Store app downloads work,
  - Store app updates work,
  - or all of the above.
- Whether rollback is required for all written update-policy keys and for any recovery-related command.
- Whether `gpupdate /force` is required as part of the runtime contract or only suggested as an operational follow-up.

## Recommended Interpretation

Issue #5 should be treated as the new authoritative direction for the Windows Update feature area.

The authoritative requirement is:

- replace the current service-disabling approach with a policy-driven Windows Update model,
- preserve Microsoft Store availability,
- consolidate the large Windows Update registry surface through shared metadata,
- include version-aware compatibility keys where needed,
- and implement `reagentc /disable` / `reagentc /enable` through a separate `WindowsRestore` module.
