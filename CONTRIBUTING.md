# Contributing to cms-git

`cms-git` is an experimental Git implementation for z/VM CMS (REXX/C), validated primarily on a local Hercules target. Contributions are welcome, but changes must respect CMS target safety and the project’s milestone/guard model.

## Before you start
- Read `README.md` and `NOTES.md` for project status, constraints, and proven milestones.
- Search existing issues/PRs to avoid duplicate work.
- For behavior changes, include or update the relevant host guard/test under `tests/` (for example `test-m281-m282-push-gc.py`, `test-m280-pack.py`).

## Development notes
- Source lives in `src/` (REXX `*.EXEC`, C modules). Deploy to CMS via the project’s upload workflow (`scripts/cms-upload.sh` / established tooling) — do not “push to GitHub from CMS”.
- **Never commit secrets.** Do not print or commit credentials (e.g. `GHCRED` contents, tokens, passwords). Keep local config under `~/.config/` or other untracked locations.
- Preserve CMS safety rules and file-format expectations (REXX/CMS conventions, record formats/line endings as required by the target workflow).

## Validation
- Run the affected host guards before opening a PR, e.g.:
  - `python3 tests/test-m281-m282-push-gc.py`
  - `python3 tests/test-m280-pack.py`
  - `python3 tests/test-m274-install.py`
- If a change affects CMS target behavior, describe how it was validated (target, bridge/path, command, observed result). Do not claim target proof from host/CI success alone.

## Pull requests
- Keep PRs focused and describe the user-visible behavior change, risk, and validation.
- Link related issues/milestones. Note any target-side deployment steps or compatibility constraints.
