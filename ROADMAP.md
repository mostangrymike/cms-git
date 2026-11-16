# Roadmap

**Canonical gap/TODO list for `cms-git`.** Each behavioural item must land with
a host guard under `tests/` and must not claim CMS target proof from host/CI
success alone. Tracked as GitHub issues where noted.

Status legend: **Missing** (no implementation), **Narrow** (implemented with
documented restrictions), **Hygiene** (docs/repo cleanup).

## 1. Merge and conflict handling — [#214](https://github.com/mostangrymike/cms-git/issues/214)

| Item | Status | Notes |
|---|---|---|
| First-class `GIT MERGE` verb | Missing | Merge only happens implicitly in `GIT PULL` (M300). |
| Line-level three-way merge | Missing | Whole-blob only; same-path divergent edits rejected. |
| Conflict markers / conflicted state | Missing | Fails closed; no markers, no conflicted index. |
| `merge --abort` / `--continue` | Missing | Rollback snapshots exist; no user command. |
| Merge path additions/removals | Missing | Rejected by M300. |
| Merge mode changes | Missing | Rejected by M300. |
| Local merge without a remote fetch | Missing | Only the pull path builds a merge commit. |

## 2. History editing and worktree — [#213](https://github.com/mostangrymike/cms-git/issues/213)

| Item | Status | Notes |
|---|---|---|
| `cherry-pick` | Missing | — |
| `rebase` | Missing | — |
| `revert` | Missing | — |
| `stash` / `stash pop` | Missing | — |
| `reset --hard` | Narrow | `RESET` is path-only (M245). |
| `restore` | Narrow | Staged-content alias (M246). |
| `diff` with content | Narrow | Name-only (M244); no hunks. |
| `blame` | Missing | — |
| `.gitignore` semantics | Missing | Untracked status is opt-in (M298). |
| Untracked files in default `status` | Narrow | Opt-in only (M298). |
| Hooks | Missing | — |

## 3. Content and trees

| Item | Status | Notes |
|---|---|---|
| Binary workfiles | Missing | CMS text only; fail closed. |
| Nested paths outside hex PATH map | Narrow | 6g hex `PATH` map only. |
| Submodules / Gitlinks | Missing | Counted, never dereferenced. |
| Unsupported tree modes | Missing | Fail closed. |

## 4. Transport and remotes — [#216](https://github.com/mostangrymike/cms-git/issues/216)

| Item | Status | Notes |
|---|---|---|
| Credential-at-rest protection | Missing | `GHCRED` is plaintext CMS records. |
| Deep clone / `--unshallow` | Missing | Depth-1; full history won't fit the object disk. |
| Multi-remote fetch / `fetch --all` / prune | Missing | One remote per operation. |
| Push force-with-lease | Missing | M281 is narrow fast-forward. |
| Push branch/tag deletion | Missing | Not in M281. |
| Commit signing / author identity | Missing | Deterministic default metadata. |

## 5. Object store and integrity — [#215](https://github.com/mostangrymike/cms-git/issues/215)

| Item | Status | Notes |
|---|---|---|
| `fsck`-equivalent sweep | Missing | Only `VERIFY-OBJECT` / `VERIFY-REF`. |
| Alternates / shared store | Missing | — |
| Incremental repack | Narrow | M299 GC + `REPACK`; no incremental policy. |

## 6. CI and tests — [#217](https://github.com/mostangrymike/cms-git/issues/217)

- `main` CI has been red since M297; repair the stale M166 guard first, then
  confirm the full Python host-test set and the C selectors pass on
  `native-stage.yml`.
- `native-stage.yml` is one ~200-step sequential job.
- Tests are source guards + synthetic fixtures, not behavioural differentials
  against reference `git`.
- No automated CMS target run; native proof is manual.

## Suggested order

1. Line-level three-way merge + conflict state + abort (#214).
2. cherry-pick / rebase / stash / content diff (#213).
3. Credential hardening + push parity (#216).
4. Deep-history strategy + fsck (#215).
5. CI split + behavioural tests (#217).
