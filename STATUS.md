# Status

**Canonical current-state file for `cms-git`.** If any other document
disagrees with this page, this page wins. Last updated 2026-11-26.

## Right now

| Field | Value |
|---|---|
| Branch | `main` |
| Latest milestone | **M305** — structural merge changes |
| Latest commit | M305 structural merge support; see `git log -1 --oneline` for the exact commit |
| Build | no package build; host checks only |
| Host CI | full local M305 selector/focused gate passes; GitHub Actions validation pending |
| CMS target | `GIT600 G` restored; M305 conflict/abort, pure mode-only, and structural auto-merge pulls passed on 2026-11-26 with synthetic verified fetch stubs; all `M301BK` targets and `M305BK` `GITFPACK` were restored and rechecked read-only |

## What is proven

- Native read-only Git operations (log/show/tree/path/blob) over sealed CMS
  generations: M46–M50 are **actual z/VM CMS target-proven**.
- Read/write porcelain through M292–M299 (branch/tag/status/add/diff/reset/
  restore, annotated tags, opt-in untracked status, verified pack reads, GC)
  is **host-CI-proven**; per-milestone CMS target proof is recorded in
  `NOTES.md` where it exists.
- Pull/clone via shallow fetch: M273/M274 passed on a real CMS target
  (2026-11-10).
- Push: M281 host-proven path.
- M300 merge core (bounded merge-base, non-conflicting whole-blob merge,
  two-parent commit, ref CAS, worktree apply): **host-CI-proven and CMS-tested**
  with a synthetic root and two mapped disjoint changes. Full network
  `GIT PULL` integration and disposable-G1 qualification remain pending.
- M301 adds local `GIT MERGE <branch>`: fast-forward, already-contained, and
  non-conflicting whole-blob merge without a remote fetch. Host syntax,
  source, archive, workflow, and merge-model gates pass. On 2026-11-26 a real
  CMS synthetic two-branch merge produced `868157275B4ADFFBDA05C1E22CEDBF8544A49F34`
  with two parents, applied both disjoint file changes, left clean status, and
  restored every runtime/ref/workfile backup byte-for-byte afterward.
- M302 adds persistent same-path conflict markers, `GITMERG MERGE G` state,
  `UU` status, `GIT MERGE --abort`, and resolve/stage/`GIT MERGE --continue`.
  A real CMS fixture produced two-parent commit
  `960881F4B77E7F40D07267061B078D66024ED89E`, cleared merge state, and verified
  abort restored the pre-merge local branch with clean status. Merge state and
  temp files are excluded from untracked scans.
- M303 adds bounded record-level three-way merge. Non-overlapping and adjacent
  record edits auto-merge; overlapping edit hunks get localized markers and
  stay staged until `--continue`. Real CMS fixtures produced two-parent commits
  `A80FBAAD66102F6E7FED9400796985C394475BE9` (separated edits),
  `474898F10AF9EC338456CDAE0994B13AC563128E` (adjacent edits), and
  `8F32B092A355C640F0BA9897B202959EA50C108C` (resolved overlap), then restored
  every runtime/ref/workfile backup and left `main` clean.
- M304 routes divergent fetched tips through the M303 conflict stack. Real
  conflicts persist with `UU` while the remote-tracking ref advances and the
  local branch stays unchanged; abort restores the local tip/worktree and keeps
  the tracking ref. Clean record-level pulls auto-continue to a two-parent
  commit. A CMS synthetic-fetch fixture produced merge commit
  `5E5645DE2B5BA00A89088060737A509B04D144D1`, then restored every M301BK target
  and the original `GITFPACK` byte-for-byte.
- M305 adds one-sided path additions/removals and `100644`↔`100755` merge
  changes. `GITMODE REPO G` preserves staged modes without changing `GITWORK`;
  structural-only pulls auto-continue, while conflicts remain abortable.
  Add/add and delete/modify conflicts fail closed. CMS fixtures produced pure
  mode merge `9F700C5C54E9AF5C99F40AAB1C2BDA4B3A2A2B71` and structural merge
  `CD2B4DB6AF4022F6193D28D98D7A62406D605B17`; both merge trees and the final
  restored state were verified.
- CMS runtime source deployed on `GIT600 G` on 2026-11-16. The active
  `GIT.EXEC` blob is `96B343E3A881CDC1B4CA94E59056213E74DB35B8`; all 20 promoted
  runtime EXECs matched the then-current main/archive Git blob hashes.
  M301–M305 are not included in that deployment. The existing `GIT LEVEL M176`
  output is a native-generation marker, not the whole-client source revision.
- Item-1 read-only user-command stress: 15/16 passed on the updated G runtime.
  `GIT LOG -n 16` stopped at missing object `C30F39A6` (tracked in issue #215).
  No command exceeded 120 seconds; slowest CMS-reported timing was about 23.4s.

## What is not proven

- Host/CI success is **not** CMS target proof. Do not describe a milestone as
  target-proven unless a real CMS run is recorded.
- M303 is bounded to 2,048 records and 65,536 LCS cells per side; larger inputs
  fall back to whole-file markers. M305 accepts one-sided path additions/removals
  and `100644`↔`100755` changes; add/add and delete/modify conflicts remain
  fail-closed. M304/M305 CMS proof used synthetic verified fetch stubs; live
  network transport was not rerun.
- `MAINT 0600` was restored to the CP directory on 2026-11-26 after the
  web-console candidate `CANDGD` was found to have dropped both `MDISK 600`
  (GIT600) and `MDISK 0601`. Only GIT600 was restored, through validated
  candidate `CANDGF80 DIRECT A`; rollback source `CANDGD DIRECT C` and backup
  `CANDGD DRBK26 C` remain on `02CC`.

- Live network `GIT PULL` transport and the G-layout migration still need
  qualification on a disposable G1. M304/M305 prove post-fetch orchestration
  with standard packs through synthetic fetch stubs.
- M304 GitHub Actions run `45922512194` passed, including the Linux-only
  `MAP`/`CONFIG`/`BACKUP` checks that cannot run on this Mac.
- Old runtime EXEC backups remain on G as `* M300BK G`; VMARC archive of all
  20 pre-update EXECs is `M300BK VMARC G`. VMARC itself is installed on A;
  original binary retained as `VMARCRAW MODULE A`.
- Test fixture state was restored from `M300TEST VMARC G`; four test commits
  and their trees/blobs remain unreachable in G (no objects were erased).

## Read next

1. [`ROADMAP.md`](ROADMAP.md) — missing features and tracked issues.
2. [`docs/INDEX.md`](docs/INDEX.md) — what every doc is (current / history / runbook).
3. [`CHANGELOG.md`](CHANGELOG.md) — delivered milestones, newest first.
4. [`NOTES.md`](NOTES.md) — detailed chronological work log.
5. [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`AGENTS.md`](AGENTS.md) — how to validate and contribute.

`docs/CURRENT_STATE.md` is **history**, not current state.
