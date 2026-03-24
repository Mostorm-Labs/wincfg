# Task Plan: Profile-Based Restore Governance

Source Review: Follow-up design step after rollback limitations were identified across registry, service, and command-driven modules  
Related Issue Analysis: [../issues/ISSUE-006-profile-based-restore-and-rollback-governance.md](../issues/ISSUE-006-profile-based-restore-and-rollback-governance.md)  
Related Spec: [../SPEC.md](../SPEC.md)

## Task Plan ID

**TASK-RESTORE-PROFILE-1**

## Progress

- Completed: `TASK-RESTORE-PROFILE-1-01` to `TASK-RESTORE-PROFILE-1-08`

## Objective

Introduce a shared restore-governance model so WinConf can support both:

- snapshot-based historical rollback
- profile-based predefined restore

without forcing every module to implement reverse behavior ad hoc.

## Why This Plan Exists

Current rollback behavior is strongest for registry-only modules whose original state was captured in snapshot data.

It is weaker or semantically incomplete for modules that are:

- command-driven
- service-driven
- or better served by a predefined restore baseline than by the historically captured device state

This plan creates a common path forward instead of solving reversal one module at a time.

## Execution Rules

Each task in this file must be:

- executable
- testable
- independent
- scoped to one restore-governance outcome

## Atomic Tasks

### TASK-RESTORE-PROFILE-1-01

**Title**  
Define the distinction between snapshot rollback and profile-based restore

**Status**  
Completed

**Scope**

- Document the difference between:
  - historical rollback from snapshot
  - predefined restore to a product-owned profile
- Define when each model is the source of truth.
- Ensure this distinction is reflected in implementation-facing docs and future CLI behavior.

**Deliverable**

- A clear contract exists for the two restoration models.

**Test**

- Review issue docs and SPEC to confirm they distinguish the two models without contradiction.

**Dependency**

- None.

**Done Definition**

- The project no longer treats all restore behavior as if it were equivalent to snapshot rollback.

---

### TASK-RESTORE-PROFILE-1-02

**Title**  
Define a shared metadata shape for predefined restore profiles

**Status**  
Completed

**Scope**

- Extend the descriptor/governance model conceptually so settings can express:
  - apply-state behavior
  - restore-profile behavior
- Ensure the model can represent at least:
  - set value
  - remove value
  - run reverse command
  - restore service startup type / state

**Deliverable**

- A metadata shape exists for profile-based restore behavior.

**Test**

- Review real examples from registry, service, and command-driven modules and confirm the model can represent them.

**Dependency**

- `TASK-RESTORE-PROFILE-1-01`

**Done Definition**

- Profile-based restore can be described through shared metadata rather than only narrative documentation.

---

### TASK-RESTORE-PROFILE-1-03

**Title**  
Define user-facing restore mode selection in `winconf.ps1`

**Status**  
Completed

**Scope**

- Define how the top-level script chooses between:
  - snapshot rollback
  - profile-based restore
- Decide whether profile restore is selected by:
  - profile name
  - mode flag
  - or both.
- Keep the interface explicit enough that users understand which restoration model they are invoking.

**Deliverable**

- A planned CLI contract exists for restore mode selection.

**Test**

- Review the proposed invocation patterns and confirm they distinguish historical rollback from predefined restore clearly.

**Dependency**

- `TASK-RESTORE-PROFILE-1-02`

**Done Definition**

- Future implementation work no longer needs to guess how users will invoke restore profiles.

---

### TASK-RESTORE-PROFILE-1-04

**Title**  
Prototype profile-based restore for a metadata-driven registry module

**Status**  
Completed

**Scope**

- Select one descriptor-driven registry-heavy module, such as `WindowsUpdate` or `UI`, as the first implementation target.
- Define a fixed restore profile for that module.
- Ensure the profile model can express all required reverse actions without relying on snapshot semantics.

**Deliverable**

- One registry-heavy module is mapped to the profile-based restore model.

**Test**

- Add or update tests that validate the module’s predefined restore profile contract.

**Dependency**

- `TASK-RESTORE-PROFILE-1-03`

**Done Definition**

- At least one registry-heavy module proves the shared restore profile abstraction works in practice.

---

### TASK-RESTORE-PROFILE-1-05

**Title**  
Prototype profile-based restore for a command-driven module

**Status**  
Completed

**Scope**

- Use `WindowsRestore` as the first command-driven target for profile-based restore governance.
- Ensure the model can express both:
  - apply/disable behavior
  - restore/enable behavior
- Confirm the design does not depend on snapshot semantics for command reversibility.

**Deliverable**

- One command-driven module proves the shared restore abstraction can handle non-registry actions.

**Test**

- Add or update tests that validate the command-driven restore profile contract.

**Dependency**

- `TASK-RESTORE-PROFILE-1-03`

**Done Definition**

- The shared restore model is proven beyond registry-only use cases.

---

### TASK-RESTORE-PROFILE-1-06

**Title**  
Audit service-driven modules for restore-profile compatibility

**Status**  
Completed

**Scope**

- Review modules such as `Privacy` for service-related reverse needs.
- Determine whether service modules need metadata that distinguishes:
  - startup type restore
  - running/stopped state restore
  - both
- Record the decision in docs and implementation guidance.

**Deliverable**

- A service-restore compatibility decision exists for the shared profile model.

**Test**

- Review service-driven modules against the proposed metadata shape and document any gaps.

**Dependency**

- `TASK-RESTORE-PROFILE-1-02`

**Done Definition**

- Service modules are no longer an undefined corner case in the restore-governance design.

---

### TASK-RESTORE-PROFILE-1-07

**Title**  
Add regression tests for restore-governance behavior

**Status**  
Completed

**Scope**

- Add tests covering:
  - snapshot rollback semantics
  - predefined restore profile semantics
  - correct user-facing mode distinction
  - module-specific reverse behavior where implemented

**Deliverable**

- The restore-governance model is protected by automated tests.

**Test**

- Run the relevant rollback/restore-related test suites and verify all cases pass.

**Dependency**

- `TASK-RESTORE-PROFILE-1-04`
- `TASK-RESTORE-PROFILE-1-05`

**Done Definition**

- Future regressions that blur or break the two restoration models are caught automatically.

---

### TASK-RESTORE-PROFILE-1-08

**Title**  
Align documentation with the dual restore model

**Status**  
Completed

**Scope**

- Update implementation-facing docs so they consistently describe:
  - snapshot rollback
  - profile-based restore
  - module applicability
  - user-facing restore mode selection
- Ensure docs no longer imply snapshot is the only restoration strategy.

**Deliverable**

- Documentation reflects the final shared restore-governance design.

**Test**

- Review docs against code and planned CLI behavior for contradictions.

**Dependency**

- `TASK-RESTORE-PROFILE-1-07`

**Done Definition**

- Code, tests, and docs describe the same restore-governance model.

## Suggested Execution Order

1. `TASK-RESTORE-PROFILE-1-01`
2. `TASK-RESTORE-PROFILE-1-02`
3. `TASK-RESTORE-PROFILE-1-03`
4. `TASK-RESTORE-PROFILE-1-04`
5. `TASK-RESTORE-PROFILE-1-05`
6. `TASK-RESTORE-PROFILE-1-06`
7. `TASK-RESTORE-PROFILE-1-07`
8. `TASK-RESTORE-PROFILE-1-08`

## Completion Standard

This plan is complete only when:

- snapshot rollback and profile-based restore are both first-class concepts
- at least one registry-heavy module and one command-driven module use the shared restore abstraction
- restore mode selection is explicit at the top-level invocation layer
- tests and docs protect the dual restore model from regression
