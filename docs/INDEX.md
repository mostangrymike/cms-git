# Documentation index

Every document at the repository root and in `docs/`, classified. **Current**
means authoritative now; **history** means retained record; **runbook** means
operational procedure; **reference** means design/interface detail.

## Canonical entrypoints (read in this order)

| Path | Kind | Purpose |
|---|---|---|
| [`../README.md`](../README.md) | current | Project overview and consolidation background. |
| [`../STATUS.md`](../STATUS.md) | current | **Only file that says what is current.** |
| [`../ROADMAP.md`](../ROADMAP.md) | current | Missing features and tracked issues. |
| [`../CHANGELOG.md`](../CHANGELOG.md) | current | Delivered milestones, newest first. |
| [`../CONTRIBUTING.md`](../CONTRIBUTING.md) | current | Build/test/PR rules. |
| [`../AGENTS.md`](../AGENTS.md) | current | Agent read order and safety rules. |

## Root documents

| Path | Kind | Notes |
|---|---|---|
| `../NOTES.md` | history | Chronological per-milestone work log (long). |
| `../SECURITY.md` | current | Vulnerability reporting and credential scope. |
| `../CODE_OF_CONDUCT.md` | current | Community policy. |
| `../LICENSE` | current | GPL-3.0-or-later. |
| `../SOURCE_CONSOLIDATION_PROGRESS.md` | history | Source consolidation record. |
| `../M13O_NATIVE_INTERFACE.md` | reference | Native interface design notes. |

## `docs/`

| Path | Kind | Notes |
|---|---|---|
| `CURRENT_STATE.md` | history | Milestone prose; superseded by `STATUS.md`. |
| `FEATURE_GAPS.md` | history | Superseded by `ROADMAP.md`. |
| `GENERATION_RECOVERY.md` | runbook | Recovery of sealed generations. |
| `GITHUB_BRANCH_AUDIT.md` | history | Branch audit record. |
| `GITHUB_SYNC_PLAN.md` | history | Sync implementation plan and gates. |
| `M173_DIRECTORY_CHANGE_PLAN.md` | history | CP directory change plan. |
| `M173_PERSISTENT_DISK_RUNBOOK.md` | runbook | Persistent disk provisioning and recovery. |
| `M179-M185_HISTORY.md` | history | Optimization milestone history. |
| `M201-M205_HISTORY.md` | history | Batch/SHA milestone history. |
| `M273-SHALLOW-PULL.md` | reference | Shallow pull/clone design and cost model. |
| `NATIVE_REF.md` | reference | Native REF/stage/index interface reference. |
