# cms-git feature gaps (post-M300)

Snapshot taken against `main` at `05abf26` (M300 handoff). This page is the
tracked list of missing behaviour relative to ordinary Git, plus repo-hygiene
items. It is a planning document; nothing here is claimed as target-proven.

Status legend:

- **Missing** — no implementation.
- **Narrow** — implemented with explicit, documented restrictions.
- **Hygiene** — no feature work; documentation/repo cleanup.

Every behavioural item must land with a host guard under `tests/` and must not
claim CMS target proof from host/CI success alone (see `CONTRIBUTING.md`).

## 1. Merge and conflict handling

| Item | Status | Notes |
|---|---|---|
| First-class `GIT MERGE` verb | Missing | Merge only happens implicitly inside `GIT PULL` (M300). |
| Line-level three-way merge | Missing | Merge is whole-blob only. Same-path divergent edits are rejected. |
| Conflict markers / worktree conflict state | Missing | Conflicts fail closed; no markers, no conflicted index. |
| `merge --abort` / `merge --continue` | Missing | Rollback snapshots exist for pull; no user-facing abort/continue. |
| Merge path additions/removals | Missing | Rejected by M300. |
| Merge mode changes | Missing | Rejected by M300. |
| Local merge of two branches without a remote fetch | Missing | Only the pull path composes a merge commit. |

## 2. History-editing and worktree commands

| Item | Status | Notes |
|---|---|---|
| `cherry-pick` | Missing | — |
| `rebase` | Missing | — |
| `revert` | Missing | — |
| `stash` / `stash pop` | Missing | — |
| `reset --hard` | Narrow | `RESET` is path-only (M245). |
| `restore` | Narrow | Staged-content restore alias (M246); no general restore. |
| `diff` with content | Narrow | `DIFF` is mapped name-only (M244). No unified/text hunk output. |
| `blame` | Missing | — |
| `.gitignore` semantics | Missing | Untracked status is opt-in (M298); no ignore rules. |
| Untracked files in default `status` | Narrow | M298 makes it opt-in only. |
| Hooks | Missing | No `pre-commit`/`post-checkout` etc. |

## 3. Content and tree support

| Item | Status | Notes |
|---|---|---|
| Binary workfiles | Missing | CMS text only; binary/unrepresentable workfiles fail closed. |
| Nested path materialization outside hex PATH map | Narrow | 6g hex `PATH` map only. |
| Submodules / Gitlinks | Missing | Gitlinks are counted but never dereferenced. |
| Unsupported tree modes | Missing | Fail closed. |

## 4. Transport and remotes

| Item | Status | Notes |
|---|---|---|
| Credential-at-rest protection | Missing | `GHCRED` stores plaintext CMS records; access to the minidisk is the boundary. |
| Deep clone / `--unshallow` | Missing | Clone is depth-1; full history (~11.8k objects / 298 MB) does not fit the object disk. |
| Multi-remote fetch / `fetch --all` / prune | Missing | Single configured remote per operation. |
| Push force-with-lease | Missing | M281 push is narrow fast-forward whole-blob. |
| Push branch/tag deletion | Missing | Not part of M281. |
| Commit signing / author identity config | Missing | Merge commits use deterministic default metadata. |

## 5. Object store and integrity

| Item | Status | Notes |
|---|---|---|
| `fsck`-equivalent full integrity sweep | Missing | Only `VERIFY-OBJECT` / `VERIFY-REF`. |
| Alternates / shared object store | Missing | — |
| Incremental repack beyond `REPACK` | Narrow | M299 GC + `REPACK`; no incremental policy. |

## 6. Repo hygiene (no behavioural claim)

- `docs/CURRENT_STATE.md` had gone stale (stopped near M68). It now carries a
  current M300 header; the old milestone prose is retained as history.
- PR #212 (`pr/evidence-readiness`) contained only a README note and should be
  closed rather than merged.
- No production-readiness/steady-state page previously existed in this repo.
- The `evidence_schema.py` / `evidence_tools.py` files once created for
  "cms-git" are **not** in this repository; they belonged to the minidisk
  provisioning work and were relocated there.

## 7. CI and test model

- `.github/workflows/native-stage.yml` is one large sequential job (~200
  steps). Splitting into per-area jobs would speed feedback but is a
  structural change, not a feature.
- Tests are Python/shell source guards plus synthetic fixtures, not a
  behavioural differential against a reference `git`.
- No automated CMS target run exists; every native proof is a manual session.

## Suggested order

1. Line-level three-way merge + conflict state + `merge --abort` (largest user
   impact; enables normal branch workflows).
2. `cherry-pick` / `rebase` / `stash` / content `diff`.
3. Credential-at-rest hardening and push parity (force-with-lease, deletes).
4. Deep-history strategy for the object disk (pack/alternates planning).
