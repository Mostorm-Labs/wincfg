# Task Plan: Windows Update Policy Metadata and Windows Restore Module

Source Review: Derived from GitHub Issue #5, attached OPS PDF, and the revised `docs/SPEC.md` contract  
Related Issue Analysis: [../issues/ISSUE-005-windows-update-policy-and-system-restore-analysis.md](../issues/ISSUE-005-windows-update-policy-and-system-restore-analysis.md)  
Related Spec: [../SPEC.md](../SPEC.md)

## Task Plan ID

**TASK-ISSUE-5-1**

## Progress

- Completed: `TASK-ISSUE-5-1-01` to `TASK-ISSUE-5-1-10`

## Objective

Replace the current `WindowsUpdate` implementation with a policy-driven, metadata-governed Windows Update control flow, and introduce a separate `WindowsRestore` module that manages restore availability through `reagentc`.

The resulting feature area must:

- disables automatic update behavior through registry-backed policy settings,
- preserves Microsoft Store usability,
- avoids disabling core update services,
- supports modern Windows policy drift across 23H2 / 24H2 / 25H2-style layers,
- consolidates the large Windows Update setting surface through shared metadata,
- and manages restore-availability control through a dedicated `WindowsRestore` module.

## Why This Plan Exists

The current project implementation and the newly confirmed requirement are in direct conflict:

- the current implementation disables update services,
- the new requirement explicitly preserves Store and forbids that default approach,
- the Windows Update setting surface is now large enough to justify metadata-driven consolidation,
- and restore-availability control now belongs in a separate module rather than inside `WindowsUpdate`.

This plan converts the requirement into implementation-sized tasks that can be executed and tested incrementally.

## Execution Rules

Each task in this file must be:

- executable
- testable
- independent
- scoped to one implementation outcome or one validation outcome

## Atomic Tasks

### TASK-ISSUE-5-1-01

**Title**  
Audit and remove the old service-disabling contract from `WindowsUpdate`

**Status**  
Completed

**Scope**

- Review the current `WindowsUpdate.ps1` implementation and identify all behavior that conflicts with the new policy-driven requirement.
- Remove the default assumption that `wuauserv` and `UsoSvc` should be stopped or set to `Disabled`.
- Remove or replace any tests that enforce service-disabling behavior.

**Deliverable**

- The `WindowsUpdate` module no longer encodes service shutdown as the feature contract.

**Test**

- Verify source and tests no longer expect `wuauserv` or `UsoSvc` disable operations in the module flow.

**Dependency**

- None.

**Done Definition**

- There is no remaining implementation-facing contract that treats Windows Update service disablement as the default solution.

---

### TASK-ISSUE-5-1-02

**Title**  
Define shared metadata structure for Windows Update policy settings

**Status**  
Completed

**Scope**

- Define a coherent descriptor / metadata representation for the Windows Update policy settings now required by the SPEC, including fields sufficient to represent:
  - path
  - name
  - type
  - value
  - required vs optional behavior
  - OS applicability where needed
  - warning / skip behavior where needed
- Confirm that the schema can represent at least these baseline settings:
  - `NoAutoUpdate`
  - `AUOptions`
  - `NoAUShutdownOption`
  - `NoAUAsDefaultShutdownOption`
  - `NoAutoRebootWithLoggedOnUsers`
  - `SetAutoRestartNotificationDisable`
  - `SetUpdateNotificationLevel`
  - `ExcludeWUDriversInQualityUpdate`
  - `DisableOSUpgrade`

**Deliverable**

- A metadata structure exists that can express the expanded Windows Update registry contract cleanly.

**Test**

- Review real Windows Update settings against the schema and confirm the baseline contract can be represented without ad hoc branching for each item.

**Dependency**

- `TASK-ISSUE-5-1-01`

**Done Definition**

- Windows Update no longer needs to encode every required registry setting as isolated hand-written imperative logic.

---

### TASK-ISSUE-5-1-03

**Title**  
Implement metadata-driven baseline Windows Update restrictions

**Status**  
Completed

**Scope**

- Update `WindowsUpdate.ps1` to apply the baseline Windows Update policy keys through shared metadata / descriptors instead of only direct repeated `Set-RegValue` calls.
- Cover at least:
  - `NoAutoUpdate`
  - `AUOptions`
  - `NoAUShutdownOption`
  - `NoAUAsDefaultShutdownOption`
  - `NoAutoRebootWithLoggedOnUsers`
  - `SetAutoRestartNotificationDisable`
  - `SetUpdateNotificationLevel`
  - `ExcludeWUDriversInQualityUpdate`
  - `DisableOSUpgrade`
- Preserve explicit registry types and path correctness.

**Deliverable**

- The module implements the baseline Windows Update policy contract through metadata-driven registry setting execution.

**Test**

- Add or update automated tests to verify every baseline path, value name, value, and type.
- Run the `WindowsUpdate` module in `-DryRun` mode and confirm logs cover the new baseline settings.

**Dependency**

- `TASK-ISSUE-5-1-02`

**Done Definition**

- The module’s baseline Windows Update behavior is metadata-driven, policy-driven, and matches the revised SPEC.

---

### TASK-ISSUE-5-1-04

**Title**  
Implement Store-preserving and Settings-visibility policy coverage

**Status**  
Completed

**Scope**

- Add policy writes required to preserve Store functionality and hide the Windows Update page:
  - `HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore`
    - `RemoveWindowsStore = 0`
    - `AutoDownload = 4`
  - `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer`
    - `SettingsPageVisibility = "hide:windowsupdate-action"`
- Fold these settings into the same metadata-driven structure used by `WindowsUpdate`.
- Ensure the implementation treats these as part of the required feature contract, not optional extras.

**Deliverable**

- The module explicitly preserves Store access and hides the Windows Update entry point in Settings.

**Test**

- Add or update tests for the Store and `SettingsPageVisibility` policy keys.
- Verify `-DryRun` logs show these operations as part of the module flow.

**Dependency**

- `TASK-ISSUE-5-1-03`

**Done Definition**

- The Windows Update feature no longer disables updates at the cost of omitting Store-preservation or Settings-page hiding behavior.

---

### TASK-ISSUE-5-1-05

**Title**  
Add version-aware compatibility coverage for UX and PolicyManager layers

**Status**  
Completed

**Scope**

- Implement compatibility handling for newer Windows policy layers, preferably through the same Windows Update metadata model, including:
  - `HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings`
    - `RestartNotificationsAllowed2`
    - `HideWUXMessages`
  - `HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update`
    - `AllowAutoUpdate`
    - `DoNotShowUpdateNotifications`
    - `HideUpdatePowerOption`
    - `ExcludeWUDriversInQualityUpdate`
  - `HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Store`
    - `AllowStore`
    - `AutoDownload`
  - `HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Settings`
    - `SettingsPageVisibility`
- Define whether these writes are unconditional or gated by OS-build applicability in the final implementation.
- Ensure unsupported compatibility branches are handled deterministically and logged clearly.

**Deliverable**

- The module supports the multi-layer policy contract described in the revised SPEC and issue analysis.

**Test**

- Add or update tests that cover:
  - the presence of UX-layer settings,
  - the presence of PolicyManager settings,
  - and any explicit build-gating logic if introduced.

**Dependency**

- `TASK-ISSUE-5-1-04`

**Done Definition**

- The module does not rely only on legacy `Policies\WindowsUpdate*` keys when newer Windows layers are part of the agreed feature contract.

---

### TASK-ISSUE-5-1-06

**Title**  
Integrate policy refresh into the Windows Update feature flow

**Status**  
Completed

**Scope**

- Add the required `gpupdate /force` step to the Windows Update feature flow after registry-backed policy application.
- Define its behavior in both normal execution and `-DryRun` mode.
- Define failure-handling expectations if the command exits non-zero.

**Deliverable**

- Policy refresh is part of the feature contract instead of an undocumented manual step.

**Test**

- Add or update tests that verify the module includes the `gpupdate /force` execution step.
- Verify `-DryRun` behavior logs the intended command without performing it.

**Dependency**

- `TASK-ISSUE-5-1-05`

**Done Definition**

- The Windows Update module includes an explicit policy-refresh stage aligned with the revised SPEC.

---

### TASK-ISSUE-5-1-07

**Title**  
Create the `WindowsRestore` module contract and disable flow using `reagentc /disable`

**Status**  
Completed

**Scope**

- Introduce a separate `WindowsRestore` module responsible for restore-availability control.
- Add the disable-path system operation that executes `reagentc /disable` in that module.
- Define how this operation is logged, how it behaves in `-DryRun`, and how failures are surfaced.
- Keep this module contract clearly separated from registry-backed Windows Update policy writes.

**Deliverable**

- A dedicated `WindowsRestore` module exists as the implementation home for the restore-disable path required by the issue and SPEC.

**Test**

- Add or update tests that verify `WindowsRestore` includes `reagentc /disable`.
- Verify logs make the restore-control operation identifiable as a separate module step.

**Dependency**

- `TASK-ISSUE-5-1-06`

**Done Definition**

- Restore disablement is no longer bundled into `WindowsUpdate`; it is managed through `WindowsRestore`.

---

### TASK-ISSUE-5-1-08

**Title**  
Define and implement the `WindowsRestore` reverse flow using `reagentc /enable`

**Status**  
Completed

**Scope**

- Decide where the reverse operation belongs in the product flow:
  - rollback path,
  - dedicated restore-enable path,
  - or both.
- Implement the supported `reagentc /enable` path in `WindowsRestore` accordingly.
- Ensure this reverse path is documented consistently with the revised issue analysis and SPEC.

**Deliverable**

- `WindowsRestore` has a defined and implementable path to restore availability after it has been disabled.

**Test**

- Add or update tests covering the chosen re-enable entry point.
- Verify the intended command is visible in logs and behaves correctly in `-DryRun`.

**Dependency**

- `TASK-ISSUE-5-1-07`

**Done Definition**

- `reagentc /enable` is no longer only a documentation note; it is part of the explicit `WindowsRestore` product flow.

---

### TASK-ISSUE-5-1-09

**Title**  
Expand automated test coverage for the revised Windows Update contract

**Status**  
Completed

**Scope**

- Add or revise tests so they cover:
  - baseline Windows Update policy keys,
  - Windows Update metadata / descriptor execution,
  - Store-preservation keys,
  - Settings-page visibility,
  - UX-layer compatibility keys,
  - PolicyManager compatibility keys,
  - `gpupdate /force`,
  - `WindowsRestore` `reagentc /disable`,
  - and the chosen `WindowsRestore` `reagentc /enable` path.
- Ensure the test suite catches regressions back to the old service-disabling model.

**Deliverable**

- Automated tests protect the full revised feature contract.

**Test**

- Run the relevant `WindowsUpdate` test suite and confirm all revised cases pass.

**Dependency**

- `TASK-ISSUE-5-1-08`

**Done Definition**

- A future regression to the old implementation model or a partial implementation of the new model would fail tests.

---

### TASK-ISSUE-5-1-10

**Title**  
Align implementation-facing documentation after the Windows Update redesign

**Status**  
Completed

**Scope**

- Review and update any remaining issue docs, task docs, or module-level comments that still describe the old service-disabling behavior.
- Ensure implementation-facing documentation consistently describes:
  - policy-based Windows Update restriction,
  - Windows Update metadata-driven governance,
  - Store-preserving behavior,
  - version-aware compatibility keys,
  - `gpupdate /force`,
  - and `WindowsRestore`-based `reagentc` control.

**Deliverable**

- Documentation and implementation expectations are fully aligned after the redesign.

**Test**

- Review code, tests, issue docs, and SPEC for contradictions.

**Dependency**

- `TASK-ISSUE-5-1-09`

**Done Definition**

- There are no known contradictions between implementation, tests, and documentation for the Windows Update feature area.

## Suggested Execution Order

1. `TASK-ISSUE-5-1-01`
2. `TASK-ISSUE-5-1-02`
3. `TASK-ISSUE-5-1-03`
4. `TASK-ISSUE-5-1-04`
5. `TASK-ISSUE-5-1-05`
6. `TASK-ISSUE-5-1-06`
7. `TASK-ISSUE-5-1-07`
8. `TASK-ISSUE-5-1-08`
9. `TASK-ISSUE-5-1-09`
10. `TASK-ISSUE-5-1-10`

## Completion Standard

This plan is complete only when:

- `WindowsUpdate` no longer depends on disabling core update services
- the module enforces the revised policy-backed Windows Update contract through shared metadata
- Microsoft Store preservation is part of the implemented feature behavior
- restore-availability control via `reagentc` is implemented through `WindowsRestore`
- tests and documentation match the new feature contract
