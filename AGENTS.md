# Agent notes

- This is a native z/VM CMS Git client: active source is `src/` (CMS REXX `*.EXEC` and C); there is no package-manager build.
- Read `CONTRIBUTING.md` and the current sections of `README.md`/`NOTES.md` before changing target behavior; these docs also retain dated milestone history.
- The main host test entrypoint is selector-based: `python3 tests/test-m203-bounded-batch.py CHECK` checks preserved test sources; use a specific selector for focused cases.
- Source-derived REXX guards use `sh tests/check-canonical-source.sh <selector>` (for example `VREF` or `M260`); the complete host gate is the command list in `.github/workflows/native-stage.yml`.
- Also run the focused standalone test when changing its area: `python3 tests/test-m273-clone-pull.py`, `test-m274-install.py`, `test-m280-pack.py`, or `test-m281-m282-push-gc.py`.
- CMS REXX records are limited to 80 columns; relevant source guards enforce this. C host checks use strict C89 where specified by the tests.
- `src/GITPFAST.EXEC` and related historical wrappers are generated on demand: `python3 scripts/restore-ph-wrappers.py CHECK` is read-only; `ALL` restores missing files only and refuses overwrites. Archived EXECs are restored with `scripts/restore-cms-exec.py`.
- Host tests/CI do not prove z/VM behavior; report CMS target validation separately and do not deploy unvalidated source as target-proven.
- Treat CMS A/G disks, existing modules, stage/index data, and scratch files as persistent user data. Do not run cleanup/apply or overwrite operations without explicit review and a verified recovery path; a static “unused” scan is not deletion authorization.
- Never print or commit CMS/GitHub credentials (including `GHCRED`, tokens, or passwords); keep local secrets outside the repository.
