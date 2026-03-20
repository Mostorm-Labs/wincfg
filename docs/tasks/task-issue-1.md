# Task Plan: Issue #1

Source Issue: https://github.com/Mostorm-Labs/wincfg/issues/1  
Issue Analysis: [../issues/ISSUE-001-ui-module-registry-key-handling.md](../issues/ISSUE-001-ui-module-registry-key-handling.md)  
Related Spec: [../SPEC.md](../SPEC.md)

## Task Plan ID

**TASK-ISSUE-1**

## Objective

Implement the SPEC updates required by Issue `WINCFG-UI-001` so the `UI` module handles missing registry keys/values, OS-specific taskbar settings, and registry write failures in a precise and testable way.

## Execution Rules

Each task in this file must be:

- executable
- testable
- independent

## Atomic Tasks

### TASK-ISSUE-1-01

**Title**  
Add registry outcome classification in `Registry.ps1`

**Scope**

- Update registry helper behavior so write operations distinguish:
  - missing registry key/value
  - access denied / unauthorized operation
  - unsupported OS-specific path/value
  - invalid registry definition

**Deliverable**

- Registry helper behavior and logging semantics updated to classify each failure mode explicitly.

**Test**

- Trigger one case for each failure mode and verify that logs and returned behavior are distinct.

**Dependency**

- None.

**Done Definition**

- No registry write failure is reported as a generic ambiguous error.

---

### TASK-ISSUE-1-02

**Title**  
Add prior-value and target-value logging for registry writes

**Scope**

- Ensure each registry write logs:
  - registry path
  - value name
  - intended value
  - prior value when available

**Deliverable**

- Registry logging output expanded to include the required fields.

**Test**

- Execute a registry write where the value exists and verify prior value is logged.
- Execute a registry write where the value is absent and verify the absence is logged cleanly.

**Dependency**

- None.

**Done Definition**

- Logs are sufficient to identify exactly what write was attempted and what existed before the write.

---

### TASK-ISSUE-1-03

**Title**  
Handle missing registry value creation

**Scope**

- When a registry key exists but the target value does not, create the value if the path/value is valid for the current OS/context.

**Deliverable**

- Missing-value path is supported explicitly by registry write flow.

**Test**

- Run against an existing valid key without the target value and confirm the value is created successfully.

**Dependency**

- None.

**Done Definition**

- Missing value creation succeeds without being misclassified as an error.

---

### TASK-ISSUE-1-04

**Title**  
Handle missing registry key creation for valid OS-specific settings

**Scope**

- When a target registry key does not exist, create the key only if the setting is valid for the current OS/context.

**Deliverable**

- Registry helper supports safe key creation with OS/context validation.

**Test**

- Run against a valid supported path with a missing key and confirm the key and value are created.

**Dependency**

- `TASK-ISSUE-1-01`

**Done Definition**

- Missing key creation works for supported settings and does not mask unsupported-path cases.

---

### TASK-ISSUE-1-05

**Title**  
Skip unsupported OS-specific registry paths with explicit warning

**Scope**

- Add handling so unsupported UI/taskbar registry settings are skipped with `WARN` instead of failing the module ambiguously.

**Deliverable**

- Unsupported-path branch implemented in registry/module flow.

**Test**

- Run a UI setting against an unsupported Windows version/build and confirm the step logs `WARN` and execution continues.

**Dependency**

- `TASK-ISSUE-1-01`

**Done Definition**

- Unsupported settings no longer surface as access or missing-key errors.

---

### TASK-ISSUE-1-06

**Title**  
Add invalid registry-definition validation

**Scope**

- Detect malformed or incomplete registry setting definitions before execution.

**Deliverable**

- Validation exists for required registry metadata such as path, name, value, and type.

**Test**

- Run a deliberately malformed registry definition and confirm the affected module fails with explicit `ERROR`.

**Dependency**

- None.

**Done Definition**

- Invalid definitions fail deterministically and are not mistaken for runtime OS or permission issues.

---

### TASK-ISSUE-1-07

**Title**  
Implement UI setting for `ShellFeedsTaskbarViewMode`

**Scope**

- Add or align support for:
  - `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds`
  - `ShellFeedsTaskbarViewMode`
  - value `2`
  - type `DWORD`

**Deliverable**

- UI module supports the user-path Feeds setting defined in SPEC.

**Test**

- On a supported system, verify the expected value is written.
- On an unsupported system, verify the step is skipped with `WARN`.

**Dependency**

- `TASK-ISSUE-1-05`

**Done Definition**

- The setting behaves according to SPEC in both supported and unsupported contexts.

---

### TASK-ISSUE-1-08

**Title**  
Implement UI setting for `TaskbarDa`

**Scope**

- Add or align support for:
  - `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced`
  - `TaskbarDa`
  - value `0`
  - type `DWORD`

**Deliverable**

- UI module supports the taskbar entry setting defined in SPEC.

**Test**

- On a supported system, verify the expected value is written.
- Verify logs clearly identify the path, value name, and result.

**Dependency**

- `TASK-ISSUE-1-05`

**Done Definition**

- `TaskbarDa` handling is implemented with correct success, skip, and failure behavior.

---

### TASK-ISSUE-1-09

**Title**  
Preserve and align policy-path `EnableFeeds` handling

**Scope**

- Keep support for:
  - `HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds`
  - `EnableFeeds`
  - value `0`
  - type `DWORD`
- Align this existing setting with the new registry and error-handling semantics.

**Deliverable**

- Existing policy-path behavior remains supported and consistent with the new SPEC.

**Test**

- Verify that policy-path execution still works and uses the new classification/logging rules.

**Dependency**

- `TASK-ISSUE-1-01`
- `TASK-ISSUE-1-02`

**Done Definition**

- `EnableFeeds` support is preserved without legacy ambiguous error handling.

---

### TASK-ISSUE-1-10

**Title**  
Add UI-module applicability checks for OS-dependent settings

**Scope**

- Before applying Feeds, Widgets, or similar taskbar-integrated settings, determine whether the setting applies to the current Windows build and current user context.

**Deliverable**

- UI module contains a clear applicability gate for OS-dependent settings.

**Test**

- Verify supported settings execute and unsupported settings are skipped with `WARN`.

**Dependency**

- `TASK-ISSUE-1-05`

**Done Definition**

- OS-dependent UI settings are gated by a deterministic applicability decision.

---

### TASK-ISSUE-1-11

**Title**  
Prevent access-denied errors from being misclassified as missing-key failures

**Scope**

- Update exception handling so permission-related failures remain permission-related in logs and execution results.

**Deliverable**

- Permission failure path separated from missing-key and unsupported-setting paths.

**Test**

- Force a registry permission failure and verify the module reports `ERROR` with exact path/value.

**Dependency**

- `TASK-ISSUE-1-01`

**Done Definition**

- Access-denied failures are never reported as missing key/value.

---

### TASK-ISSUE-1-12

**Title**  
Verify snapshot and rollback behavior for newly created keys and values

**Scope**

- Confirm snapshot records remain correct when registry keys or values are created during apply operations.

**Deliverable**

- Snapshot/rollback rules validated and adjusted if necessary for newly created paths/values.

**Test**

- Apply a setting that creates a missing key or value, then run rollback and verify prior state is restored correctly.

**Dependency**

- `TASK-ISSUE-1-03`
- `TASK-ISSUE-1-04`

**Done Definition**

- Rollback remains deterministic after key/value creation scenarios.

---

### TASK-ISSUE-1-13

**Title**  
Add registry helper tests for the outcome matrix

**Scope**

- Add automated tests covering:
  - existing key/value
  - missing key
  - missing value
  - access denied
  - unsupported OS-specific path
  - invalid registry definition

**Deliverable**

- Test coverage exists for all required registry outcome branches.

**Test**

- Run the registry test suite and verify all cases pass.

**Dependency**

- `TASK-ISSUE-1-01`
- `TASK-ISSUE-1-03`
- `TASK-ISSUE-1-04`
- `TASK-ISSUE-1-05`
- `TASK-ISSUE-1-06`
- `TASK-ISSUE-1-11`

**Done Definition**

- Registry helper behavior is covered by automated tests for every required result class.

---

### TASK-ISSUE-1-14

**Title**  
Add UI module tests for Issue #1 settings

**Scope**

- Add tests for:
  - `ShowTaskViewButton`
  - `EnableFeeds`
  - `ShellFeedsTaskbarViewMode`
  - `TaskbarDa`
- Cover supported and unsupported OS/context scenarios where applicable.

**Deliverable**

- Automated UI-module tests cover all settings touched by this issue.

**Test**

- Run the UI module test suite and verify all new cases pass.

**Dependency**

- `TASK-ISSUE-1-07`
- `TASK-ISSUE-1-08`
- `TASK-ISSUE-1-09`
- `TASK-ISSUE-1-10`

**Done Definition**

- UI settings introduced or clarified by this issue are covered by automated tests.

---

### TASK-ISSUE-1-15

**Title**  
Align implementation-facing documentation with the updated SPEC

**Scope**

- Update developer-facing documentation so registry semantics, UI applicability rules, and testing expectations match the revised SPEC.

**Deliverable**

- Relevant docs reflect the final behavior introduced for Issue #1.

**Test**

- Review documentation against `SPEC.md` and confirm no conflicting statements remain.

**Dependency**

- `TASK-ISSUE-1-13`
- `TASK-ISSUE-1-14`

**Done Definition**

- Documentation, implementation behavior, and tests all describe the same rules.

## Suggested Execution Order

1. `TASK-ISSUE-1-01`
2. `TASK-ISSUE-1-02`
3. `TASK-ISSUE-1-03`
4. `TASK-ISSUE-1-04`
5. `TASK-ISSUE-1-05`
6. `TASK-ISSUE-1-06`
7. `TASK-ISSUE-1-11`
8. `TASK-ISSUE-1-10`
9. `TASK-ISSUE-1-07`
10. `TASK-ISSUE-1-08`
11. `TASK-ISSUE-1-09`
12. `TASK-ISSUE-1-12`
13. `TASK-ISSUE-1-13`
14. `TASK-ISSUE-1-14`
15. `TASK-ISSUE-1-15`

## Completion Standard

This issue is complete only when:

- the implementation matches the updated `SPEC.md`
- all atomic tasks marked as code or test work are completed
- the relevant automated tests pass
- logs and failure behavior are unambiguous for registry operations touched by this issue
