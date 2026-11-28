# Changelog

Newest first. Milestone detail lives in `NOTES.md`; proven-vs-pending status
lives in `STATUS.md`. This file records what landed, not proof claims.

## Unreleased

- CMS target sync and M307–M309 qualification: all 12 current runtime EXECs
  were deployed to G and hash-verified. Target testing on disposable `0601 B`
  proved `COMMIT-INFO`, content diff, stash save/pop, and single-parent replay,
  and exposed three real defects now fixed: content-diff ceiling initialization,
  `ADD -u`/`workoid`/`COMMIT-TREE` filemode propagation and loop-index reuse,
  and non-truncating workfile restore. Host guards were updated accordingly.
- Add M309 bounded record-level content output to `GIT DIFF`. Without
  `--name-only`, changed paths report old/new blob OIDs and LCS-aligned `-`/`+`
  CMS records; `--cached`/`--staged` covers the index and the default covers
  the worktree. Inputs over the M303 record/cell ceilings report `DIFF TOO
  LARGE` and are not decoded. Name-only output and the 16-pathspec limit stay
  unchanged. Adds `tests/test-m309-content-diff.py` and a workflow gate.
  Host-proven only.
- Add M308 `GIT STASH [-m message]` and `GIT STASH POP`. Save stages tracked
  workfiles, creates a single-parent snapshot commit without moving the branch,
  records its OID in a strictly validated `GITSTASH REPO` sidecar, then restores
  workfiles from HEAD and resets the index. Pop replays the snapshot through
  `CHERRY-PICK` and clears the sidecar only after a successful update. Narrow
  scope: one slot, at most 16 mapped paths, no untracked files, staged
  additions, deletions, or structural changes. Adds
  `tests/test-m308-stash.py` and a workflow gate. Host-proven only.
- Add M307 single-parent `GIT CHERRY-PICK <commit-id> [-m message]`. A verified
  `COMMIT-INFO` reader rejects root and merge commits; the M301–M305 three-way
  merge stack replays clean content changes onto the current branch, builds a
  commit with the old tip as its only parent, and applies it through
  `GITUPD MERGE-HEAD`. Conflicts, add/add, delete/modify, path additions,
  removals, and mode changes fail closed. Adds `CHERRY-PICK-STACK` in `GITWT`,
  `tests/test-m307-cherry-pick.py`, and a workflow gate. Host-proven only.
- Add M306 multi-minidisk repository support: runtime/support files stay on G,
  while `GIT --FM <letter>` selects repository metadata, refs, objects, packs,
  worktree map, and workfiles. Clone requires an explicit filemode and validates
  disk capacity plus an empty repository namespace. Add optional clone branch
  selection and qualify real bridge clone/up-to-date/incremental pull on a
  provisioned `0601 B` minidisk.
- Update historical M156–M171 host guards to require repository-filemode
  dispatch through `--FM`.
- Add M305 structural merge support: one-sided path additions/removals and
  `100644`↔`100755` mode changes now stage through the persistent merge
  lifecycle, with rollback/abort and two-parent continuation. A `GITMODE` sidecar
  preserves staged executable-bit changes without changing the worktree-map
  format. Add/add and delete/modify conflicts remain fail-closed. Adds
  `tests/test-m305-structural-merge.py` and a workflow gate.
- Add M304 fetched-tip merge orchestration for `GIT PULL`: divergent verified
  tips route through the M303 conflict stack. Real conflicts persist for
  `GIT MERGE --continue`/`--abort` while the remote-tracking ref advances and
  the local branch stays unchanged; clean record-level auto-merges continue to
  a two-parent commit. Adds `tests/test-m304-pull-conflicts.py` and a workflow
  gate.
- Add M303 bounded record-level three-way merge: LCS-derived edit hunks
  auto-merge non-overlapping replacements, insertions, deletions, and adjacent
  record edits; overlapping hunks produce localized conflict blocks. Auto-merged
  paths stay staged under the existing merge state until `--continue`. Inputs
  over 2,048 records or 65,536 LCS cells fall back to whole-file markers.
  Conflict detection now keys on `<<<<<<< HEAD`, so ordinary `===========`
  records are not false conflicts. Adds `tests/test-m303-record-merge.py` and a
  workflow gate.
- Add M302 persistent merge conflicts: whole-file conflict markers,
  `GITMERG MERGE G` state, `UU` status, `GIT MERGE --abort`, and
  resolve/stage/`GIT MERGE --continue` with a two-parent commit. Rollback
  rewrites now truncate fixed-80 targets before restoring shorter content.
  Adds `tests/test-m302-merge-conflicts.py` and a workflow gate. CMS validation
  details and the post-test restore are recorded in `NOTES.md`.
- Add M301 `GIT MERGE <branch>` for local fast-forward and non-conflicting
  whole-blob merges without a remote fetch. Reuses M300 merge-base,
  preflight, two-parent commit, ref CAS, and worktree apply; adds
  `GITUPD MERGE-HEAD` labeling, queued stack-based long-command primitives,
  and host source/model guards. CMS validation details and the post-test
  restore are recorded in `NOTES.md`.
- Add canonical state stack: `STATUS.md`, `ROADMAP.md`, `docs/INDEX.md`,
  `CHANGELOG.md`, and a state-precedence block in `AGENTS.md`.
- Mark `docs/CURRENT_STATE.md` as history with an M300 header.
- Tests: realign three host guards that still encoded pre-M297/M299/M300
  source: M166 (`newoid`), M260 (object-disk application via `GITOBJ`), and
  M294 (loose TAG importer). `native-stage.yml` is green again.
- Fix revision peeling to expose `objectfm` into its private REXX variable
  pool; host guard added. Native-stage CI passed on `3fd30de` and the follow-up
  docs/stress-runner commit `316bd7a`.
- Deploy 20 then-current-main/runtime EXEC sources to CMS `GIT600 G` after
  hash-verifying staged A files and preserving the previous G sources as
  `M300BK`; VMARC archive created for backup. Item-1 read-only CMS checks
  passed 15/16; deeper history stops at missing object (issue #215).

## M300 — bounded non-fast-forward merge

- Packed-object ancestry reads and bounded unique merge-base selection.
- Two-parent merge for non-conflicting whole-blob changes on existing mapped
  paths with unchanged modes.
- Rejects same-path conflicts, path additions/removals, mode changes, unmapped
  changes, ambiguous bases, and empty tree merges.
- Host CI green; CMS synthetic fixture passed merge-base, preflight,
  two-parent merge commit, compare-and-swap ref update, pull apply, and clean
  status. Full network `GIT PULL` qualification remains pending.

## M299 — verified pack reader and real GC

- `GIT GC` / `GIT REPACK` verify packs, import to retained stages, build
  indexes, readback-verify, and register in `GITPACKS`.
- Packed-object fallback for reads; `--prune=now` and `REPACK -d` remove
  superseded artifacts only after replacement verification.

## M298 — opt-in untracked status

- `GIT STATUS --untracked-files=<FM>` scans one CMS filemode via `LISTFILE`.

## M297 — annotated commit tags

- `GIT TAG -a|--annotate` creates tag objects; peeling and verification follow
  nested tags up to a bound.

## M296 — pathspec expansion

- Bracket expressions and directory-prefix matching across ADD/STATUS/RESET/
  RESTORE/DIFF.

## M295 — compact tracked source set

- Tracked `src/` reduced to 30 paths; deferred EXECs retained in
  `RUNTIME_MODULES.json` and restorable.

## M292–M294 — source consolidation

- Inlined legacy branch fallback, credential handler, and loose-object importer;
  originals archived byte-for-byte.
