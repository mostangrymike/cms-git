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
| Host CI | `.github/workflows/native-stage.yml` |
| CMS target | manual; see proof status below |

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
  **host-CI-proven, CMS target validation pending.**

## What is not proven

- Host/CI success is **not** CMS target proof. Do not describe a milestone as
  target-proven unless a real CMS run is recorded.
- M300 and the G-layout migration still need a CMS run on disposable G1
  fixtures.

## Read next

1. [`ROADMAP.md`](ROADMAP.md) — missing features and tracked issues.
2. [`docs/INDEX.md`](docs/INDEX.md) — what every doc is (current / history / runbook).
3. [`CHANGELOG.md`](CHANGELOG.md) — delivered milestones, newest first.
4. [`NOTES.md`](NOTES.md) — detailed chronological work log.
5. [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`AGENTS.md`](AGENTS.md) — how to validate and contribute.

`docs/CURRENT_STATE.md` is **history**, not current state.
