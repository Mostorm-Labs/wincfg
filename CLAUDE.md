# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Project: Windows Config Automation Tool

PowerShell-based automation tool that configures Windows for unattended/kiosk use cases (Zoom Rooms, meeting room devices). Hosted under the Mostorm-Labs GitHub organization.

## File Structure

- `scripts/winconf.ps1` — main entry point
- `scripts/lib/` — shared helpers (Logger, Registry, Service, Snapshot)
- `scripts/modules/` — one file per feature area (Power, ScreenLock, WindowsUpdate, Cortana, Notifications, Privacy, UI)
- `service/winconf-agent/` — background service (PowerShell + NSSM)
- `docs/` — SPEC.md, PLAN.md

## Running the Script

```powershell
# Preview all changes (no writes)
.\scripts\winconf.ps1 -DryRun -Verbose

# Apply all modules
.\scripts\winconf.ps1

# Apply a single module
.\scripts\winconf.ps1 -Module Power

# Roll back all changes
.\scripts\winconf.ps1 -Rollback
```

## Installing the Background Service

```powershell
# Requires nssm.exe in PATH or service/winconf-agent/
.\service\winconf-agent\Install-Service.ps1 -Install
.\service\winconf-agent\Install-Service.ps1 -Remove
```

## Coding Rules

- Every module exposes a single `Invoke-<Name> [-DryRun]` function
- All registry/service writes go through `lib/Registry.ps1` and `lib/Service.ps1` — never call `Set-ItemProperty` or `sc config` directly in modules
- Call `Save-Snapshot` before every write (already handled inside `Set-RegValue` and `Set-ServiceStartType`)
- Log every operation via `Write-Log`; never use `Write-Host` directly in modules
- Scripts must be idempotent — safe to run multiple times
- All changes must be reversible via `-Rollback`
- Support `-DryRun` in every module

## Commit Convention

- Format: `type(scope): message` — e.g. `feat(power): disable hibernate`, `fix(snapshot): handle null registry value`
- Types: `feat`, `fix`, `refactor`, `docs`, `chore`
- Scope = module or lib name (lowercase)
- Keep subject line under 72 characters
- Write in English

## Tech Stack

- PowerShell 5.1+ (primary)
- NSSM (background service wrapper)
- Windows Registry API via PowerShell cmdlets

---

## Documentation Standards

All docs live in `docs/`. Each file has a distinct scope — do not duplicate content across files.

### PRD.md — Product Requirements

**Answers: what and why. No implementation details.**

Required sections:

1. **Background** — problem context and use case
2. **Goals** — what success looks like
3. **Functional Requirements** — grouped by feature area, each with an ID, description, and acceptance criteria
4. **Non-Functional Requirements** — constraints (idempotency, rollback, DryRun, OS compatibility)
5. **Out of Scope** — explicit exclusions
6. **Requirement Traceability** — maps requirement IDs to module files and implementation status

Rules:

- No registry key names, command-line flags, or function signatures
- Acceptance criteria describe observable behavior, not implementation
- Requirement IDs follow the pattern `<PREFIX>-NN` (e.g. `PW-01`, `SL-02`)

### SPEC.md — Technical Specification

**Answers: how. Precise implementation details for developers.**

Required sections:

1. **Script Interface** — CLI flags, types, and descriptions
2. **Lib Layer** — function signatures, parameters, side effects, DryRun behavior
3. **Module Layer** — per-module table of exact registry paths, key names, values, and types; or `powercfg` / `sc` commands used
4. **Background Service** — service properties, poll interval, watch list schema, event log config
5. **File & Data Paths** — all runtime file locations
6. **Error Handling** — per-error-condition behavior (skip, warn, throw, exit code)

Rules:

- Every registry entry must include: full path, name, value, and `RegistryValueKind` type
- No user stories, goals, or acceptance criteria — those belong in PRD.md
- Function signatures must match the actual PowerShell implementation

### PLAN.md — Implementation Plan

**Answers: in what order, and why those decisions were made.**

Required sections:

1. **Phases** — ordered list of implementation phases, each with tasks as checkboxes (`- [ ]` / `- [x]`)
2. **Structure Decisions** — table of key architectural choices with rationale

Rules:

- Tasks use `- [ ]` (pending) or `- [x]` (done) — keep status current
- Each phase has a clear deliverable
- Record *why* a decision was made, not just what was decided
- Remove completed phases once the project is stable; archive to git history

### TASK.md — Active Work Tracking

**Answers: what is being worked on right now.**

Create `docs/TASK.md` when starting a non-trivial work session. Delete or clear it when done.

Required sections:

1. **Goal** — one sentence describing the session objective
2. **Tasks** — checkbox list of concrete steps (`- [ ]` / `- [x]`)
3. **Blockers** (optional) — anything preventing progress

Rules:

- One active task at a time — mark done immediately on completion
- Scope is the current session only; do not record history here
- If a task reveals new sub-tasks, add them inline below the parent
- Do not duplicate content from PLAN.md; TASK.md is ephemeral, PLAN.md is durable
