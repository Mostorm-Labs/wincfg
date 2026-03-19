# PRD — Windows Config Automation Tool

**Project:** winconf
**Use Case:** Zoom Rooms / Unattended Kiosk Deployment
**Date:** 2026-03-19
**Status:** Active

---

## 1. Background

Zoom Rooms requires a specific Windows configuration to operate reliably as an always-on meeting room device. The Zoom Rooms setup wizard presents a checklist of recommended system changes (see `zoom.png`). This tool automates those changes in a repeatable, auditable, and reversible way — suitable for fleet deployment without manual intervention.

---

## 2. Goals

- Automate all Windows settings required by Zoom Rooms setup
- Support dry-run preview before applying any changes
- Be fully idempotent — safe to run multiple times
- Support rollback of every change made
- Run unattended with no user interaction

---

## 3. Functional Requirements

### 3.1 Screen Lock

| ID | Requirement | Acceptance Criteria |
|----|-------------|---------------------|
| SL-01 | Disable automatic screen lock after inactivity | Screen does not lock when left idle |
| SL-02 | Disable password login after PC wakes up from sleep | No password prompt on resume from sleep |

### 3.2 Cortana

| ID | Requirement | Acceptance Criteria |
|----|-------------|---------------------|
| CO-01 | Disable Cortana | Cortana is not active; requires restart to take effect |

### 3.3 Notifications

| ID | Requirement | Acceptance Criteria |
|----|-------------|---------------------|
| NO-01 | Disable push notifications | No toast or action center notifications appear |

### 3.4 Windows Update

| ID | Requirement | Acceptance Criteria |
|----|-------------|---------------------|
| WU-01 | Disable Windows automatic update | Windows does not download or install updates automatically; requires restart |

### 3.5 Power

| ID | Requirement | Acceptance Criteria |
|----|-------------|---------------------|
| PW-01 | Enable high performance power plan | Active power scheme is High Performance |
| PW-02 | Do not hibernate on battery | Device does not hibernate when on battery |
| PW-03 | Never put the computer to sleep | Sleep timeout is Never on both AC and battery |
| PW-04 | Never turn off display | Display timeout is Never on both AC and battery |

### 3.6 UI

| ID | Requirement | Acceptance Criteria |
|----|-------------|---------------------|
| UI-01 | Disable gestures on the edge of the screen | Edge swipe and action center gesture are inactive |

---

## 4. Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| NF-01 | All changes must be reversible via `-Rollback` |
| NF-02 | All modules must support `-DryRun` — preview with no writes |
| NF-03 | Scripts must be idempotent — safe to run multiple times |
| NF-04 | Compatible with PowerShell 5.1+ on Windows 10 / Windows 11 |
| NF-05 | Must run under local admin or SYSTEM account |
| NF-06 | All operations must be logged with module, action, and outcome |

---

## 5. Out of Scope

- Zoom Rooms application installation
- Network or firewall configuration
- Domain join or Active Directory policies
- Hardware driver management

---

## 6. Requirement Traceability

| ID | Requirement | Module | Status |
|----|-------------|--------|--------|
| SL-01 | Disable screen lock on idle | `modules/ScreenLock.ps1` | Implemented |
| SL-02 | Disable password on wake | `modules/ScreenLock.ps1` | Implemented |
| CO-01 | Disable Cortana | `modules/Cortana.ps1` | Implemented |
| NO-01 | Disable push notifications | `modules/Notifications.ps1` | Implemented |
| WU-01 | Disable auto update | `modules/WindowsUpdate.ps1` | Implemented |
| PW-01 | High performance power plan | `modules/Power.ps1` | Implemented |
| PW-02 | No hibernate on battery | `modules/Power.ps1` | Implemented |
| PW-03 | Never sleep | `modules/Power.ps1` | Implemented |
| PW-04 | Never turn off display | `modules/Power.ps1` | Implemented |
| UI-01 | Disable edge gestures | `modules/UI.ps1` | Implemented |
