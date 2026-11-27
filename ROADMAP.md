# Roadmap

**Canonical gap/TODO list for `cms-git`.** Each behavioural item must land with
a host guard under `tests/` and must not claim CMS target proof from host/CI
success alone. Tracked as GitHub issues where noted.

Status legend: **Missing** (no implementation), **Narrow** (implemented with
documented restrictions), **Hygiene** (docs/repo cleanup).

## 1. Merge and conflict handling — [#214](https://github.com/mostangrymike/cms-git/issues/214)

| Item | Status | Notes |
|---|---|---|
| First-class `GIT MERGE` verb | Narrow | M301 adds local branch merge; M304 adds fetched-tip `PULL` conflict/auto-merge orchestration; M305 adds structural changes. M306 qualifies live bridge pull on 2026-11-27. |
| Record-level three-way merge | Narrow | M303 auto-merges non-overlapping and adjacent record edits with bounded LCS hunks; oversized inputs fall back to whole-file markers. |
| Conflict markers / conflicted state | Narrow | M302/M304 persist `GITMERG MERGE G` for local and fetched-tip merges, report `UU`, and localize markers to overlapping record hunks. |
| `merge --abort` / `--continue` | Narrow | M302 restores the pre-merge local branch on abort and creates a two-parent commit on continue; CMS-validated. |
| Merge path additions/removals | Narrow | M305 stages one-sided additions/removals through the persistent merge lifecycle; add/add and delete/modify conflicts remain fail-closed. |
| Merge mode changes | Narrow | M305 stages `100644`↔`100755` changes in a `GITMODE` sidecar and preserves them in two-parent merge trees. |
| Local merge without a remote fetch | Narrow | M301–M303 add `GIT MERGE <branch>` for local fast-forward, whole-blob, and bounded record-level merges; M304 adds fetched-tip orchestration. Host- and CMS-validated. |

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
| Repository minidisk selection | Narrow | M306 keeps runtime/support files on G and uses `--FM <letter>` for per-minidisk repository data; clone validates capacity and an empty namespace. |
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

- The full local M306 selector/focused gate and GitHub Actions run
  `46079543515` pass. Keep the full Python host-test set and C selectors green.
- `native-stage.yml` is one ~200-step sequential job; splitting it remains work.
- Tests are source guards + synthetic fixtures, not behavioural differentials
  against reference `git`.
- No automated CMS target run; native proof is manual.

## Suggested order

1. cherry-pick / rebase / stash / content diff (#213).
2. Credential hardening + push parity (#216).
3. Deep-history strategy + fsck (#215).
4. CI split + behavioural tests (#217).
