# Status

**Canonical current-state file for `cms-git`.** If any other document
disagrees with this page, this page wins. Last updated 2026-11-16.

## Right now

| Field | Value |
|---|---|
| Branch | `main` |
| Latest milestone | **M300** — bounded non-fast-forward merge |
| Latest commit | see `git log -1 --oneline` (M300 handoff) |
| Build | no package build; host checks only |
| Host CI | `.github/workflows/native-stage.yml` — **green** on `3fd30de` (run `43922439161`) |
| CMS target | `GIT600 G` runtime EXECs match current main; item-1 read-only checks run (details below) |

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
- M300 merge (packed ancestry, bounded merge-base, two-parent merge):
  **host-CI-proven**, but its write path remains CMS-target-unvalidated.
- CMS latest runtime source deployed on `GIT600 G` on 2026-11-16. The active
  `GIT.EXEC` blob is `96B343E3A881CDC1B4CA94E59056213E74DB35B8`; all 20 promoted
  runtime EXECs matched current-main/archive Git blob hashes. The existing
  `GIT LEVEL M176` output is a native-generation marker, not the whole-client
  source revision.
- Item-1 read-only user-command stress: 15/16 passed on the updated G runtime.
  `GIT LOG -n 16` stopped at missing object `C30F39A6` (tracked in issue #215).
  No command exceeded 120 seconds; slowest CMS-reported timing was about 23.4s.

## What is not proven

- Host/CI success is **not** CMS target proof. Do not describe a milestone as
  target-proven unless a real CMS run is recorded.
- M300 non-fast-forward merge and the G-layout migration still need CMS
  write-path validation on disposable G1 fixtures. Item-1 checks were read-only.
- `native-stage.yml` was red after M297 because M166/M260/M294 guards were
  stale. Those guards are aligned; latest CI is green on `3fd30de`.
- Old runtime EXEC backups remain on G as `* M300BK G`; a VMARC archive of all
  20 pre-update EXECs is `M300BK VMARC G`. VMARC itself is installed on A;
  original binary retained as `VMARCRAW MODULE A`.

## Read next

1. [`ROADMAP.md`](ROADMAP.md) — missing features and tracked issues.
2. [`docs/INDEX.md`](docs/INDEX.md) — what every doc is (current / history / runbook).
3. [`CHANGELOG.md`](CHANGELOG.md) — delivered milestones, newest first.
4. [`NOTES.md`](NOTES.md) — detailed chronological work log.
5. [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`AGENTS.md`](AGENTS.md) — how to validate and contribute.

`docs/CURRENT_STATE.md` is **history**, not current state.
