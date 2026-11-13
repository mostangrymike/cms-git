# Source consolidation progress

## Request and safety boundary

User requested the fewest practical source files, removal of obsolete
scratch/test files, and persistent progress notes. Work is limited to this Git
repository. Do not erase files from CMS A/G disks, deploy consolidated code, or
replace target-proven CMS modules as part of this refactor without a separate
review and target validation.

Preserve test coverage and all historical/source evidence unless a specific
file is proven unnecessary. Prefer moving exact historical source into the
existing verified archive format over irreversible deletion. Keep CMS
filenames, linker/module boundaries, 80-column records, and current target
proofs in view.

## Baseline

- Starting commit: `ee99f1f` (`main` clean and equal to `origin/main`).
- `src/` contains 220 top-level files on disk: 122 `.EXEC`, 40 `.C`, 22
  `.ASSEMBLE`, plus non-source fixtures, backup candidates, and upload/config
  artifacts. Git tracks 112 `.EXEC`, 40 `.C`, 22 `.ASSEMBLE`, one `.REPO`, and
  two upload shell scripts; the extra disk files are ignored/untracked and
  have not been touched.
- Initial assessment began before changes; dated entries below record all
  source archival and scratch-file disposition.
- Do not count generated `src/` files created by CI restoration as source
  consolidation candidates without checking `.gitignore`, archive guards, and
  the workflow restore steps.

## Plan

1. [~] Build a read-only inventory: tracked status, EXEC/C/ASSEMBLE references,
   native build/link boundaries, workflow/test dependencies, generated files,
   fixture assets, and backup/scratch candidates.
2. [~] Propose the smallest safe runtime source groups while preserving CMS
   command/module names and native ABI; identify files that cannot be merged.
3. [~] Consolidate one group at a time, update tests/build/restore scripts, and
   run focused plus full host gates after each coherent batch.
4. [~] Archive or remove only specifically reviewed obsolete scratch/test
   sources; keep required tests and fixtures, consolidating packaging only
   where CI can restore and byte-verify them.
5. [ ] Record file counts, changes, test results, and blockers below after each
   batch. Keep this file as the recovery handoff; do not commit/push without
   separate instruction.

## Progress log

### 2026-11-13 — started

- Read `AGENTS.md`, `CONTRIBUTING.md`, `README.md`, and `NOTES.md` guidance.
- Confirmed clean `main` at `ee99f1f`; no changes made before this progress
  record.
- Initial source-directory count is 122 EXEC + 40 C + 22 assembler decks.
- Next: complete dependency/build/test inventory; do not remove files based on
  naming or apparent inactivity alone.

### 2026-11-13 — initial dependency findings

- `GITREC.C` textually includes `GITCIDX.C` and `GITSEL.C`; this is an existing
  combined compile unit and does not require either include to be separately
  compiled as a runtime module.
- The other 37 C files each define their own `main`, reflecting multiple
  separately loaded CMS C modules/probes. A single-C-file merge would require
  explicit command dispatch and build/runtime changes; it is not a safe
  text-concatenation operation.
- `GITVREF`, `GITWT`, `GITUPD`, network/PACK helpers, target checkers, and
  historical probes are called by exact CMS EXEC/module names. Any packing
  into an archive must retain verified, non-overwriting restoration before
  tests or CMS upload.
- Separate historical performance/native implementations (for example
  `GITPH*` C variants) are used by milestone evidence and the docs; they are
  candidates for on-demand archival, not deletion.

### 2026-11-13 — archive target gates (batch 1)

- Moved 24 M155–M176 target-gate EXEC sources (including M157GATE and
  M173DCHK) losslessly into `archive/HISTORICAL_EXEC.json` bundle
  `TARGET_GATES.json`. These are reproducible test/deployment helpers, not
  runtime dependencies; all remain individually restorable by name.
- Removed the 24 tracked copies from `src/`, reducing tracked source paths
  from 177 to 153 (EXEC 112→88; C 40 and ASSEMBLE 22 unchanged). No target
  module or CMS disk was modified.
- Extended `scripts/restore-cms-exec.py` archive inventory from 99 to 123
  files. Its existing `MISSING` mode restores archived files before workflow
  tests; README now documents that step and targeted restore.
- Updated the archive guard and CI bundle comment. Archive audit passed:
  `ARCHIVED CMS EXEC DEPENDENCY AUDIT PASS 123 ARCHIVED 113 REFERENCED`.
- Focused host checks passed: `tests/test-m203-bounded-batch.py CHECK`,
  selectors `M173R` and `M173D`, Python compilation, and `git diff --check`.
- Ran `restore-cms-exec.py MISSING` and verified exact restoration. It created
  119 untracked working copies (four other archived names already have
  tracked production versions); all 119 copies were byte-checked against the
  archive and removed after the tests. No unrelated untracked source was
  touched.
- Full local native-stage workflow: **142/146 pass**. The same four known
  macOS-only environment failures remain: three GNU `stat -c` checks and the
  Linux `sudo apt-get install regina-rexx` step. All repository/code checks,
  including archive restore, passed.
- Remaining: complete the dependency inventory, assess additional safe source
  groups, and update final counts. Do not commit or push without separate
  instruction.

### 2026-11-13 — lossless source packaging batches 2–3

- `NATIVE_BENCH_C.json`: 17 historical/probe C sources, including old
  GITP21/24/25 and GITPH benchmark variants. `GITPH8M.C` remains tracked due
  the explicit protected-source guard; `GITP26M.C` remains the current source.
- `NATIVE_PROBES_C.json`: eight old compiler/parser/I/O/hash/tree-walker
  probes with no active source callers.
- `TARGET_GATES.json`: 31 target/test EXECs, including M155–M176 checkers,
  GITC22–25, GITP21, GITTEST and GITRCHK. GIT42TEST's nine-character
  host-only name is retained losslessly in `LOCAL_SCRATCH.json`.
- `ASSEMBLE_DECKS.json`: all 22 tracked assembler decks, including GITSTRM,
  M173VQ and M274 ABI adapters. Exact sources are restored on demand before
  assembly/upload. No CMS MODULE, disk or assembler source logic was changed.
- `LOCAL_SCRATCH.json`: two unique ignored backup sources plus GIT42TEST; three
  identical ignored GITWT backup files were reduced to one archived copy. Four
  scratch files were removed from `src/` after hash and secret-pattern checks.
- Current `HISTORICAL_EXEC.json`: **177** source entries in 11 verified
  bundles (138 EXEC, 17 C, 22 ASSEMBLE). `restore-cms-exec.py MISSING` is the
  non-overwriting preparation step before host guards or source upload.
- Current tracked source paths: **98**, down from 177 (72 EXEC, 23 C, 0
  ASSEMBLE, one REPO, two shell scripts). After `restore-cms-exec.py MISSING`,
  the physical `src/` directory also contains on-demand archived sources and
  fixtures; do not treat those restored/untracked files as active tracked code.
- `restore-cms-exec.py AUDIT`, archive hash/parity checks, `CHECK`, M173R/D,
  M173V, M190S, M190 benchmark, M194, M201 and the full workflow passed all
  code/archive checks. Full local gate: **142/146 pass**; the four failures are
  environment-only on macOS (GNU `stat -c`×3 and Linux Regina package install).
  All 169 generated archive copies were removed afterward.
- Inlined the sole-caller OFS_DELTA resolver from GITODLT into GITZDOFS and
  the sole-caller REF_DELTA base lookup from GITRDEL into GITZDREF. Exact old
  helpers remain archived for historical M6 restoration. M284/M285 static,
  order, and host-model guards pass.
- Inlined the sole production caller's bounded PACK SHA verifier from GITPSHA
  into the strict path in GITPNWLK. The byte-exact old helper is archived in
  `LEGACY_HELPERS.json` for historical tests and is restored on demand.
  M287 guards check bounded 64-byte reads, trailer validation, the known M8A
  digest, and archive parity. The merged CMS entrypoint has not yet been
  target-validated.
- Inlined the sole production callers' bounded native staging and output
  publisher from GITNSTG/GITNOUT into GITPZNAT. Exact originals remain in
  `LEGACY_HELPERS.json` for restored tests. M288 guards check 1-KiB staging
  bounds, output preflight/publish ordering, archive parity, and removal of
  the external EXEC calls. Regina syntax checks pass. On CMS, exact changed
  EXECs were temporarily placed under unique G1 names and invalid-command
  refusal paths returned RC4; this validates CMS parsing, not the PACK/native
  routines themselves.
- Read-only Telnet inventory of CMS G1 found `GITPZNAT EXEC`, but not
  `GITPNWLK`, `GITPBUF`, `GITPMETA`, `GITPZBUF`, `GITPSTRM`, or `GITNDRV`.
  Therefore the merged strict-PACK/native paths cannot be exercised
  end-to-end without installing a larger disposable dependency set. The two
  temporary G1 EXECs were erased and verified absent; no existing CMS file was
  overwritten and no A-disk file was written. Evidence:
  `cms-consolidation-g1-inventory.json` and
  `cms-m287-m288-syntax-target.json` in `/private/var/folders/y0/hyjtc91x5071jc0gntk0pzcw0000gn/T/opencode/`.
- Direct Telnet CMS tests of the exact EXEC sources on A1 returned RC4 for
  invalid verbs and RC8 for malformed zlib input (expected early refusal).
  The full resolver paths were not exercised: GITINFL/GITDAPP and legacy
  fixtures are absent on the target. G1 was not overwritten; the two A1 test
  sources are retained as scratch. FTP ASCII round-trips matched the local
  sources after CMS padding removal. `GITPCTX PACK A` and the selected zero-OID
  object were absent before/after. Target evidence:
  `/private/var/folders/y0/hyjtc91x5071jc0gntk0pzcw0000gn/T/opencode/cms-m284-m285-target-run3.json`.
  Do not call either full resolver path CMS-proven.
- Overall, 79 tracked source paths have been removed. Runtime modules remain
  separate where CMS EXEC/module names and distinct C `main` entry points are
  public build/runtime boundaries. No changes have been committed or pushed.

## Current handoff

- Working baseline remains `ee99f1f`; changes are staged/uncommitted, with no
  commit or push performed.
- `SOURCE_CONSOLIDATION_PROGRESS.md` is the current recovery note.
- Tracked source count: 177 → **98**. Historical/test/benchmark source is
  recoverable through `scripts/restore-cms-exec.py MISSING`; scratch copies
  have exact SHA-256 records in `archive/LOCAL_SCRATCH.json`.
- Final full local workflow run: **142/146 pass**; 4 known macOS/Linux
  environment-only failures. The Linux GitHub gate has not been rerun because
  no commit/push was authorized.
- CMS drive placement is being completed separately from source consolidation:
  operator clarified all CMS-Git files must live on G. The 18 smaller A1
  project files were copied to absent G1 names (module duplicates under
  `GITRCOLD`/`GITSTOLD`), all passed CMS `COMPARE`, then their A1 copies were
  erased and verified absent. This includes the separately copied and
  compared `M282GC EXEC`. A1 `LISTFILE * * A1 (ALLOC` now lists only the two
  PACK files and system `PROFILE`/`RESTORE`.
- `M273P014 PACK` and `M273P021 PACK` were reconstructed on G1 as V128 files
  with the original A1-reported record counts (59,987 and 60,021). The
  reconstruction used repeatable CMS FTP binary exports, F128 receipt and a
  CMS G-only conversion to V128. FTP export hashes were stable across repeat
  reads; the G candidates round-tripped byte-for-byte to the trimmed export,
  and final G files passed CMS `COMPARE` against their G candidates.
- CMS `COMPARE` from each A1 PACK to its G1 counterpart fails while reading
  the A1 source (`DMSCMP104S`, error 42). At the operator's direction to
  recreate the PACKs and erase the A1 versions, the first `ERASE M273P014
  PACK A1` hit `DMSDKD1307T` / TRKDE code 4 and entered CP disabled-wait.
  CMS was re-IPLed for read-only inspection; **both A1 PACK originals remain
  present**, and no erase was retried. Final G1 PACKs remain present and
  compare-equal to their reconstructed G candidates. A1 and G1 state evidence
  is in `cms-move-18-verified-run.json`,
  `cms-pack-recreation-erase-run.json`, and
  `cms-after-erase-failure-inspection.json` under
  `/private/var/folders/y0/hyjtc91x5071jc0gntk0pzcw0000gn/T/opencode/`.
  Binary FTP recovery material is in `/tmp/ftpserve/` (`M273P014.GBIN`,
  `M273P021.GBIN`, and their trimmed V128 transfer files). Do not retry A1
  PACK erasure until the A-disk read/track-deletion error is resolved or
  separately reviewed. `PROFILE` and `RESTORE` were never changed.
- Active runtime source edits are `src/GITZDOFS.EXEC`, `src/GITZDREF.EXEC`,
  `src/GITPNWLK.EXEC`, and `src/GITPZNAT.EXEC`; only the early-refusal paths
  of GITZDOFS/GITZDREF were target-tested. M287/M288 remain host-guarded only.
- Still open: the absolute minimum runtime-file goal. Beyond the GITODLT→
  GITZDOFS inline merge, the current pass intentionally preserves external
  EXEC/module entry points. Next phase needs a caller/ABI map for the remaining
  72 EXEC and 23 C sources, followed by small internal merges and live CMS
  validation. A one-EXEC/one-C design would require a new dispatcher and
  compiler/link strategy, not safe concatenation.
- The current lexical scan's next one-caller candidates are `GITPSTRM`
  (streaming DEFLATE, 355 lines, called by GITPZBUF) and `GITPDEF` (general
  DEFLATE, 279 lines, called by GITPINFL). These are core algorithms, not small
  wrappers; keep them separate until disposable CMS fixtures can exercise the
  merged paths end-to-end. A token caller count alone is not deletion approval.

## Decisions and validation

_(Append dated decisions, file changes, exact commands/results, and remaining
risks here.)_
