# Changelog

Newest first. Milestone detail lives in `NOTES.md`; proven-vs-pending status
lives in `STATUS.md`. This file records what landed, not proof claims.

## Unreleased

- Add canonical state stack: `STATUS.md`, `ROADMAP.md`, `docs/INDEX.md`,
  `CHANGELOG.md`, and a state-precedence block in `AGENTS.md`.
- Mark `docs/CURRENT_STATE.md` as history with an M300 header.
- Tests: realign three host guards that still encoded pre-M297/M299/M300
  source: M166 (`newoid`), M260 (object-disk application via `GITOBJ`), and
  M294 (loose TAG importer). `native-stage.yml` is green again.

## M300 — bounded non-fast-forward merge

- Packed-object ancestry reads and bounded unique merge-base selection.
- Two-parent merge for non-conflicting whole-blob changes on existing mapped
  paths with unchanged modes.
- Rejects same-path conflicts, path additions/removals, mode changes, unmapped
  changes, ambiguous bases, and empty tree merges.
- Host checks pass; CMS validation pending.

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
