# Issue Analysis: Profile-Based Restore and Rollback Governance

Source Review: Derived from rollback behavior analysis across `Snapshot.ps1`, `winconf.ps1`, and current module implementations

## 1. Feature ID

**WINCFG-RESTORE-006**

WinConf must support two distinct restoration models through a shared abstraction:

- snapshot-based rollback to a recorded historical machine state
- profile-based restore to a predefined target configuration

## 2. Clear Requirement

The system shall not treat `-Rollback` as the only restoration mechanism.

The product shall distinguish between:

1. Snapshot rollback
   - Restore the machine to the recorded state captured before WinConf changed a setting.
   - This is machine-history-based behavior.

2. Profile-based restore
   - Restore the machine to a predefined product-owned configuration profile.
   - This is target-state-based behavior.

The system shall provide a shared abstraction so both models can coexist without each module inventing bespoke reverse logic.

The feature shall satisfy all of the following requirements:

1. Snapshot rollback must remain supported for settings whose original state was captured.
2. Profile-based restore must be available for modules where restoring to a fixed target state is more useful than restoring to the historically captured state.
3. The same module may support both models.
4. Users must be able to choose whether they want:
   - rollback to snapshot,
   - or restore to a named profile.
5. Metadata-driven modules must be able to express both:
   - forward/apply behavior,
   - and reverse/profile behavior,
   through the same implementation model where feasible.

## 3. System-Level Operations

### Registry

Profile-based restore must support registry-backed settings that need an explicit reverse target, for example:

- write a value to a predefined restore-state value
- remove a value during restore
- restore a setting to product-defined default behavior

This cannot always be derived from snapshot data, because snapshot may reflect a historically undesirable device state.

### Command

Profile-based restore must support command-driven modules and reverse actions, for example:

- `reagentc /disable`
- `reagentc /enable`
- future `powercfg` restore flows

These actions need an explicit profile-driven reverse contract, not only snapshot behavior.

### Service

Profile-based restore must support service-oriented modules where desired restore behavior may mean:

- a specific startup type,
- a specific running/stopped target state,
- or both.

## 4. Acceptance Criteria

### Functional

- The architecture distinguishes snapshot rollback from profile-based restore explicitly.
- The user-facing invocation contract can choose between:
  - historical rollback,
  - and predefined profile restore.
- At least one registry-heavy module and one command-driven module can be represented by the shared restore abstraction after implementation.

### Governance

- Shared metadata can express both apply-state and restore/profile-state semantics where appropriate.
- Modules no longer need to invent one-off reverse logic when they fit the shared model.
- Documentation clearly explains when snapshot is authoritative and when profile restore is authoritative.

### Safety

- No module is forced to pretend that a predefined restore profile is the same thing as the machine's original state.
- Users can distinguish:
  - "put this device back the way it was recorded"
  - from
  - "put this device into a supported baseline configuration"

## 5. Risks

- **Semantic confusion risk**: users may confuse snapshot rollback with predefined restore unless both are named and documented clearly.
- **Abstraction risk**: trying to force all modules into a single reverse model may overfit registry modules and underfit command/service modules.
- **Compatibility risk**: some settings may restore more safely by deleting values than by writing explicit values, so profile metadata must support more than one reverse action type.
- **Historical-state risk**: snapshot data can legitimately preserve an already undesirable machine state, so it cannot be the only restoration strategy.
- **Migration risk**: existing rollback code is snapshot-centric, so adding profile restore must avoid breaking current rollback expectations.

## 6. Missing Information

- Final user-facing parameter shape for choosing restore mode.
- Whether profiles should be global, per module, or both.
- Naming scheme for predefined profiles such as:
  - `Default`
  - `RestoreBasic`
  - `Baseline`
  - `Enabled`
- Whether profile restore should support dry-run output identical in quality to current apply flows.
- Whether profile restore should participate in snapshot capture when it writes new state.

## Recommended Interpretation

The correct next step is not to replace snapshot rollback, but to add a second restoration model.

The product should treat:

- snapshot rollback as historical-state recovery
- profile-based restore as product-defined target-state recovery

and standardize both through a shared governance model instead of leaving reversal behavior module-specific.
