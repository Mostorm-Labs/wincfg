# Task Plan: Setting Metadata Governance

Source Review: Follow-up design step after shared optional-setting handling was introduced in `Registry.ps1`  
Related Spec: [../SPEC.md](../SPEC.md)  
Related Task Plan: [task-risk-priority-remediation.md](./task-risk-priority-remediation.md)

## Task Plan ID

**TASK-SETTING-METADATA-1**

## Objective

Replace scattered per-module setting rules with a shared metadata-driven model so WinConf can express:

- whether a setting is required or optional
- whether a setting is stable, OS-dependent, or OS-protected
- build applicability rules
- fallback behavior for unsupported or rejected direct writes

This plan focuses on design and implementation structure, not only individual setting fixes.

## Why This Plan Exists

The project currently has a partially unified fallback model through shared registry helpers, but setting behavior is still encoded ad hoc in module logic, for example:

- direct `switch` blocks for applicability
- per-module string-based warning prefixes
- repeated decisions about whether a setting is optional or required

That approach works for a few settings but will become harder to maintain as more Windows-version-dependent shell settings are added.

## Execution Rules

Each task in this file must be:

- executable
- testable
- independent
- framed around one shared-governance outcome

## Atomic Tasks

### TASK-SETTING-METADATA-1-01

**Title**  
Define a shared setting descriptor schema

**Status**  
Pending

**Scope**

- Define a common structure for describing settings, including fields such as:
  - `Name`
  - `Path`
  - `Type`
  - `Value`
  - `Required`
  - `Category`
  - `MinBuild`
  - `MaxBuild`
  - `SkipOnUnauthorized`
  - `UnsupportedWarningPrefix`
  - `WarningPrefix`
- Keep the schema simple enough for PowerShell scripts to consume without heavy framework overhead.

**Deliverable**

- A documented descriptor schema exists for registry-backed settings.

**Test**

- Review at least two real settings and confirm the schema can represent their behavior without special-case module code.

**Dependency**

- None.

**Done Definition**

- The schema is concrete enough that module logic can begin reading behavior from metadata instead of hardcoded conditionals.

---

### TASK-SETTING-METADATA-1-02

**Title**  
Implement shared metadata helpers for applicability and fallback

**Status**  
Pending

**Scope**

- Add shared helper functions that consume the descriptor schema to determine:
  - whether a setting applies on the current build/context
  - which warning message to use
  - whether unauthorized write rejection should be skipped or thrown
- Build on the current `Set-OptionalRegValue` / `Set-ApplicableOptionalRegValue` helpers instead of replacing working behavior unnecessarily.

**Deliverable**

- Registry-setting execution can be driven by descriptor metadata.

**Test**

- Add tests showing that shared helpers return correct applicability and fallback behavior for at least:
  - one stable policy-backed setting
  - one unsupported OS-dependent setting
  - one OS-protected optional setting

**Dependency**

- `TASK-SETTING-METADATA-1-01`

**Done Definition**

- Shared helpers can execute or skip a setting based on metadata alone.

---

### TASK-SETTING-METADATA-1-03

**Title**  
Migrate `UI` module settings to descriptor-based execution

**Status**  
Pending

**Scope**

- Convert `UI` settings to descriptor definitions for at least:
  - `ShowTaskViewButton`
  - `EnableFeeds`
  - `ShellFeedsTaskbarViewMode`
  - `TaskbarDa`
  - `HideMeetNow`
- Remove now-redundant per-setting branching where metadata covers the behavior.

**Deliverable**

- `UI.ps1` becomes the first module primarily driven by setting descriptors.

**Test**

- Verify existing UI tests still pass or are updated to assert descriptor-driven behavior.

**Dependency**

- `TASK-SETTING-METADATA-1-02`

**Done Definition**

- `UI` applicability and optional-setting policy are no longer scattered across module-specific conditionals.

---

### TASK-SETTING-METADATA-1-04

**Title**  
Migrate `Cortana` module optional shell behavior to descriptor-based execution

**Status**  
Pending

**Scope**

- Convert `Cortana` settings to descriptor-based execution, including:
  - `AllowCortana`
  - `DisableSearchBoxSuggestions`
  - `ShowCortanaButton`
- Ensure `ShowCortanaButton` uses descriptor metadata instead of module-specific fallback decisions.

**Deliverable**

- `Cortana.ps1` uses the same descriptor model as `UI`.

**Test**

- Update `Cortana` tests to verify descriptor-driven behavior and fallback semantics.

**Dependency**

- `TASK-SETTING-METADATA-1-02`

**Done Definition**

- `Cortana` no longer contains bespoke optional shell-setting handling beyond what the descriptor model requires.

---

### TASK-SETTING-METADATA-1-05

**Title**  
Evaluate whether `Notifications` should adopt descriptor metadata now or later

**Status**  
Pending

**Scope**

- Decide whether the current `Notifications` module is:
  - simple enough to keep explicit,
  - or a strong candidate for descriptor migration because of mixed stability categories.
- Record the decision and rationale in code comments or docs if the migration is deferred.

**Deliverable**

- A documented decision exists for `Notifications` metadata adoption timing.

**Test**

- Review `Notifications` against the descriptor schema and confirm whether migration adds value now.

**Dependency**

- `TASK-SETTING-METADATA-1-02`

**Done Definition**

- `Notifications` metadata strategy is deliberate rather than accidental.

---

### TASK-SETTING-METADATA-1-06

**Title**  
Add regression tests for descriptor-driven setting execution

**Status**  
Pending

**Scope**

- Add tests covering:
  - descriptor applicability by build
  - descriptor-driven warning selection
  - unauthorized skip behavior for OS-protected optional settings
  - stable required setting execution paths

**Deliverable**

- Test coverage exists for the shared metadata execution model itself, not just individual module strings.

**Test**

- Run the relevant registry and module test suites and verify all descriptor-driven cases pass.

**Dependency**

- `TASK-SETTING-METADATA-1-03`
- `TASK-SETTING-METADATA-1-04`

**Done Definition**

- The metadata model is protected by tests, so future module edits cannot silently bypass it.

---

### TASK-SETTING-METADATA-1-07

**Title**  
Align documentation with the descriptor-based governance model

**Status**  
Pending

**Scope**

- Update implementation-facing documentation to explain:
  - the shared setting descriptor model
  - required vs optional setting categories
  - unsupported vs OS-protected fallback behavior
- Align references in `SPEC.md`, issue docs, and task docs where needed.

**Deliverable**

- Documentation reflects the shared-governance design instead of only the old module-local logic.

**Test**

- Review docs against code and test behavior for contradictions.

**Dependency**

- `TASK-SETTING-METADATA-1-06`

**Done Definition**

- Code, tests, and docs all describe the same metadata-driven governance model.

## Suggested Execution Order

1. `TASK-SETTING-METADATA-1-01`
2. `TASK-SETTING-METADATA-1-02`
3. `TASK-SETTING-METADATA-1-03`
4. `TASK-SETTING-METADATA-1-04`
5. `TASK-SETTING-METADATA-1-05`
6. `TASK-SETTING-METADATA-1-06`
7. `TASK-SETTING-METADATA-1-07`

## Completion Standard

This setting-governance plan is complete only when:

- setting applicability and fallback rules are represented by shared metadata
- at least `UI` and `Cortana` use the metadata-driven model
- tests cover the shared governance behavior directly
- documentation explains the model consistently
