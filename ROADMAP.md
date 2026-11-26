# Roadmap

**Canonical gap/TODO list for `cms-git`.** Each behavioural item must land with
a host guard under `tests/` and must not claim CMS target proof from host/CI
success alone. Tracked as GitHub issues where noted.

Status legend: **Missing** (no implementation), **Narrow** (implemented with
documented restrictions), **Hygiene** (docs/repo cleanup).

## 1. Merge and conflict handling — [#214](https://github.com/mostangrymike/cms-git/issues/214)

| Item | Status | Notes |
|---|---|---|
| First-class `GIT MERGE` verb | Narrow | M301 adds local branch merge; CMS synthetic merge passed 2026-11-26. Network `PULL` merge remains separate. |
| Line-level three-way merge | Missing | M302 writes whole-file conflict blocks; no record-level hunk merge yet. |
| Conflict markers / conflicted state | Narrow | M302 writes whole-file markers, persists `GITMERG MERGE G`, and reports `UU`; CMS-validated. |
| `merge --abort` / `--continue` | Narrow | M302 restores the pre-merge local branch on abort and creates a two-parent commit on continue; CMS-validated. |
| Merge path additions/removals | Missing | Rejected by M300. |
| Merge mode changes | Missing | Rejected by M300. |
| Local merge without a remote fetch | Narrow | M301 adds `GIT MERGE <branch>` for local fast-forward and non-conflicting whole-blob merges; host- and CMS-validated. |

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

1. Build on M302: record-level three-way merged hunks inside the existing conflict lifecycle (#214).
2. cherry-pick / rebase / stash / content diff (#213).
3. Credential hardening + push parity (#216).
4. Deep-history strategy + fsck (#215).
5. CI split + behavioural tests (#217).
