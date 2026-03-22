# Task Plan: Risk-Priority Remediation

Source Review: Local codebase risk review performed against `docs/SPEC.md` and current module implementations  
Related Spec: [../SPEC.md](../SPEC.md)  
Related Task Plan: [task-issue-1.md](./task-issue-1.md)

## Task Plan ID

**TASK-RISK-REMEDIATION-1**

## Objective

Reduce the highest-risk implementation and maintenance issues in the WinConf project by fixing:

- spec/implementation mismatches
- unstable OS-dependent shell settings
- missing applicability/fallback policy for optional UI settings
- insufficient regression coverage for high-drift registry settings

This plan is intentionally ordered by operational risk, not by module name.

## Risk Order

1. `ScreenLock` spec/implementation mismatch
2. `Notifications` spec/implementation mismatch and mixed policy/user-preference behavior
3. `Cortana` and remaining `UI` shell/taskbar settings with likely OS/version drift
4. Cross-module governance for optional OS-protected settings
5. Regression coverage and documentation alignment

## Execution Rules

Each task in this file must be:

- executable
- testable
- independent
- scoped to one risk area or one shared framework concern

## Atomic Tasks

### TASK-RISK-REMEDIATION-1-01

**Title**  
Align `ScreenLock` idle-lock implementation with the SPEC

**Status**  
Pending

**Scope**

- Replace the current `NoLockScreen` implementation in `ScreenLock.ps1` with the SPEC-defined idle-lock policy setting:
  - `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`
  - `InactivityTimeoutSecs`
  - value `0`
  - type `DWORD`
- Preserve the existing screen-saver settings unless they independently conflict with the SPEC.

**Deliverable**

- `ScreenLock.ps1` matches the current SPEC for idle-lock behavior.

**Test**

- Run `ScreenLock` in `-DryRun` mode and verify logs target `InactivityTimeoutSecs`.
- Add or update automated tests to verify the expected path, value name, and value.

**Dependency**

- None.

**Done Definition**

- `ScreenLock` no longer writes `NoLockScreen` as a substitute for the SPEC-defined idle-lock policy.

---

### TASK-RISK-REMEDIATION-1-02

**Title**  
Add regression tests for `ScreenLock` spec alignment

**Status**  
Pending

**Scope**

- Add tests covering:
  - `ScreenSaveActive`
  - `ScreenSaveTimeOut`
  - `ScreenSaverIsSecure`
  - `InactivityTimeoutSecs`
- Ensure the test suite catches future regressions where `ScreenLock` drifts away from the SPEC again.

**Deliverable**

- `ScreenLock` automated tests enforce the current spec-defined registry contract.

**Test**

- Run the relevant test suite and verify all `ScreenLock` cases pass.

**Dependency**

- `TASK-RISK-REMEDIATION-1-01`

**Done Definition**

- A future reintroduction of `NoLockScreen` in place of `InactivityTimeoutSecs` would fail tests.

---

### TASK-RISK-REMEDIATION-1-03

**Title**  
Align `Notifications` module paths and roots with the SPEC

**Status**  
Pending

**Scope**

- Reconcile `Notifications.ps1` with the current SPEC for:
  - `DisableNotificationCenter`
  - `NoToastApplicationNotification`
  - `DisableLockScreenAppNotifications`
- Remove or explicitly justify any extra non-SPEC values such as:
  - `ToastEnabled`
  - `LockScreenToastEnabled`
- Ensure root hives match the intended policy scope (`HKLM` vs `HKCU`) where required.

**Deliverable**

- `Notifications.ps1` clearly implements either:
  - the exact SPEC,
  - or a revised agreed-upon contract with the SPEC updated to match.

**Test**

- Run `Notifications` in `-DryRun` mode and verify logs reference only the agreed settings and paths.

**Dependency**

- None.

**Done Definition**

- There is no unresolved mismatch between `Notifications.ps1` and `docs/SPEC.md`.

---

### TASK-RISK-REMEDIATION-1-04

**Title**  
Add `Notifications` risk classification for policy-backed vs user-preference settings

**Status**  
Pending

**Scope**

- Explicitly classify notification settings into:
  - policy-backed required settings
  - optional user-preference settings
- Define whether any user-preference notification settings should remain in the module at all.
- If retained, define their fallback behavior when direct writes are unsupported or ineffective.

**Deliverable**

- `Notifications` has a deterministic policy for what must succeed and what may be skipped.

**Test**

- Add tests that distinguish required policy-setting failure from optional-setting skip behavior.

**Dependency**

- `TASK-RISK-REMEDIATION-1-03`

**Done Definition**

- Notification setting failures are no longer treated uniformly when they belong to different stability categories.

---

### TASK-RISK-REMEDIATION-1-05

**Title**  
Audit `Cortana` module for deprecated or OS-drifted settings

**Status**  
Pending

**Scope**

- Review `Cortana.ps1` settings for Windows-version relevance:
  - `AllowCortana`
  - `BingSearchEnabled`
  - `DisableSearchBoxSuggestions`
  - `ShowCortanaButton`
- Determine which settings are:
  - stable and required
  - optional and OS-dependent
  - obsolete and should be removed

**Deliverable**

- A clear decision for each `Cortana` setting: keep, gate, downgrade to optional, or remove.

**Test**

- Add/update tests and docs to reflect the final decision matrix.

**Dependency**

- None.

**Done Definition**

- `Cortana` no longer assumes all legacy search/taskbar values are valid and writable on current Windows builds.

---

### TASK-RISK-REMEDIATION-1-06

**Title**  
Extend OS-protected optional-setting handling beyond `TaskbarDa`

**Status**  
Pending

**Scope**

- Identify remaining shell/UI values likely to behave like `TaskbarDa`, including candidates such as:
  - `ShowCortanaButton`
  - `HideMeetNow`
  - any retained user-preference notification shell values
- Apply a shared handling strategy where appropriate:
  - applicability gate
  - OS-protected optional classification
  - `WARN + skip` fallback on direct-write rejection

**Deliverable**

- Optional shell/UI settings across modules use a consistent fallback model.

**Test**

- Add tests covering at least one additional setting besides `TaskbarDa` that follows the shared optional-setting fallback path.

**Dependency**

- `TASK-RISK-REMEDIATION-1-04`
- `TASK-RISK-REMEDIATION-1-05`

**Done Definition**

- `TaskbarDa` is no longer the only setting with explicit OS-protected optional handling when the same risk pattern exists elsewhere.

---

### TASK-RISK-REMEDIATION-1-07

**Title**  
Introduce shared metadata for registry-setting stability categories

**Status**  
Pending

**Scope**

- Introduce a lightweight shared representation for registry-setting behavior, such as:
  - required policy-backed
  - stable user-preference
  - optional OS-dependent
  - OS-protected optional
- Use this metadata to reduce per-module ad hoc decisions.

**Deliverable**

- A reusable pattern or helper exists for expressing setting stability and fallback policy.

**Test**

- Verify that at least two modules use the new shared pattern consistently.

**Dependency**

- `TASK-RISK-REMEDIATION-1-04`
- `TASK-RISK-REMEDIATION-1-06`

**Done Definition**

- Setting behavior categories are encoded in implementation structure instead of only in comments and docs.

---

### TASK-RISK-REMEDIATION-1-08

**Title**  
Expand regression coverage for drift-prone shell and policy settings

**Status**  
Pending

**Scope**

- Add or expand tests across modules to cover:
  - spec-aligned required settings
  - unsupported optional settings
  - OS-protected optional settings
  - root-hive/path correctness

**Deliverable**

- Automated tests cover the main drift and mismatch failure classes identified in this review.

**Test**

- Run the relevant test suites and verify all new cases pass.

**Dependency**

- `TASK-RISK-REMEDIATION-1-02`
- `TASK-RISK-REMEDIATION-1-06`
- `TASK-RISK-REMEDIATION-1-07`

**Done Definition**

- Future drift in spec alignment or optional-setting behavior is caught automatically by tests.

---

### TASK-RISK-REMEDIATION-1-09

**Title**  
Align implementation-facing documentation after risk remediation

**Status**  
Pending

**Scope**

- Update `docs/SPEC.md` and any related issue/task docs so they accurately describe:
  - final `ScreenLock` behavior
  - final `Notifications` behavior
  - final `Cortana` / `UI` optional-setting policy
  - shared stability-category rules if introduced

**Deliverable**

- Documentation reflects the actual implementation and fallback model after remediation.

**Test**

- Review code, tests, and docs for contradictions.

**Dependency**

- `TASK-RISK-REMEDIATION-1-08`

**Done Definition**

- There are no known contradictions between code, tests, and docs for the risk areas covered by this plan.

## Suggested Execution Order

1. `TASK-RISK-REMEDIATION-1-01`
2. `TASK-RISK-REMEDIATION-1-02`
3. `TASK-RISK-REMEDIATION-1-03`
4. `TASK-RISK-REMEDIATION-1-04`
5. `TASK-RISK-REMEDIATION-1-05`
6. `TASK-RISK-REMEDIATION-1-06`
7. `TASK-RISK-REMEDIATION-1-07`
8. `TASK-RISK-REMEDIATION-1-08`
9. `TASK-RISK-REMEDIATION-1-09`

## Completion Standard

This risk-remediation plan is complete only when:

- the highest-risk spec/implementation mismatches are resolved
- drift-prone optional shell settings have deterministic handling rules
- regression tests cover both required and optional-setting outcomes
- implementation-facing documentation matches the final code behavior
