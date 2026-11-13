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
- Current `HISTORICAL_EXEC.json`: **244** source entries in 12 verified
  bundles (205 EXEC, 17 C, 22 ASSEMBLE). `restore-cms-exec.py MISSING` is the
  non-overwriting preparation step before host guards or source upload.
- Current tracked source paths: **30**, down from 177 (4 EXEC, 23 C, 0
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
  digest, and archive parity. CMS verified parsing and early-refusal only;
  strict PACK processing remains unvalidated on the target.
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
- Inlined the sole production caller's 355-line streaming DEFLATE core from
  GITPSTRM into GITPZBUF; the exact former helper is archived for historical
  M9J tests. M289 guards compare the inlined body with the archive and check
  fixed, dynamic, stored/fixed, and bad-Adler fixtures. A G1-only CMS stack
  with unique temporary names passed all four cases, including expected
   bad-Adler rejection. All temporary EXECs and data files were erased and
   verified absent; no A-disk file was written. Evidence:
   `cms-m289-streaming-zlib-target.json`.
- Inlined the sole production caller's general DEFLATE engine from GITPDEF
  into GITPINFL. The exact engine remains archived for restored M9E tests.
  M290 guards compare the copied core with its archive and model fixed,
  dynamic, stored/fixed, and bad-Adler cases. A G1-only CMS stack passed all
  four cases; temporary EXECs and PACK files were erased and verified absent.
  No A-disk file was written. Evidence:
  `cms-m290-general-inflater-target.json`.
- Inlined legacy HEAD/checkout support from GITHEAD into GIT's fallback path.
  Exact GITHEAD source remains archived for M5 regression tests. M291 guards
  compare the helper procedures with the archive and prohibit the old EXEC
  call. A temporary G1-only repository fixture passed HEAD, checkout, and
  missing-branch-preserves-HEAD cases; all temporary EXEC/data files were
  erased and verified absent. No A-disk file was written. Evidence:
  `cms-m291-githead-target.json`.
- Inlined legacy `GIT BRANCH` listing/creation fallback from GITREF into
  `GIT.EXEC`. The exact former source is archived; M292 compares the inline
  validation/read/write procedures with that archive and prohibits the old
  EXEC call. A G1-only CMS fixture passed current-branch listing, commit-object
  branch creation, duplicate rejection, and listing the new branch. All five
  temporary EXECs and three repository/object files were erased and verified
  absent. No A-disk file was written. Evidence:
  `cms-m292-gitref-target.json`.
- Inlined the single production caller of credential handling from GITCRED
  into `GIT.EXEC`; the former exact source is preserved in the historical
  archive. M293 compares the inlined handler against its archived source and
  guards against the external EXEC call. A G1-only CMS fixture passed synthetic
  API-key and username/password import, status, removal, and legacy-format
  reading. Synthetic values were not printed. All temporary G1 files were
  erased and verified absent; no A-disk file was written. Evidence:
   `cms-m293-gitcred-target.json`.
- Inlined the single production caller of loose-object import from GITIMP into
  `GIT.EXEC`; the exact GITIMP source remains archived. M294 guards compare the
  handler with the archived source and reject the external EXEC route. A
  G1-only CMS fixture imported a synthetic blob from a canned CATHEX response,
  verified the loose object, and confirmed repeat-import idempotence. All test
  EXECs and repository/object files were erased and verified absent. No A-disk
  file was written. Evidence: `cms-m294-gitimp-target.json`.
- M295 deferred 62 remaining tracked EXEC paths into on-demand restoration.
  Sixty-one exact sources are in `RUNTIME_MODULES.json`; GIT9CTX reuses its
  existing archived copy. GIT.EXEC, three guarded M6 protocol helpers, all
  23 C sources, GITREF2.REPO, and two transfer scripts remain tracked: 30 paths.
  CMS command/module names and source bodies are unchanged. `MISSING` restores
  runtime sources before tests or upload, and dependency audits include the
  deferred source texts. This packaging batch does not change CMS target files.
  Read-only CMS `STATE GIT EXEC G`, `STATE GITMETA REPO G`, and `GIT STAMP`
  succeeded; no target source was uploaded or erased. Evidence:
  `cms-m295-package-smoke.json`.
- GitHub CI for M289 exposed a stale ACLEAN test assertion that enumerated
  only five legacy helpers. The preserved ACLEAN host fixture now enumerates
  all fourteen archived helpers; `python3 tests/test-m203-bounded-batch.py ACLEAN`
  passes.
- Direct Telnet CMS tests of the exact EXEC sources on A1 returned RC4 for
  invalid verbs and RC8 for malformed zlib input (expected early refusal).
  The full resolver paths were not exercised: GITINFL/GITDAPP and legacy
  fixtures are absent on the target. G1 was not overwritten; the two A1 test
  sources are retained as scratch. FTP ASCII round-trips matched the local
  sources after CMS padding removal. `GITPCTX PACK A` and the selected zero-OID
  object were absent before/after. Target evidence:
  `/private/var/folders/y0/hyjtc91x5071jc0gntk0pzcw0000gn/T/opencode/cms-m284-m285-target-run3.json`.
  Do not call either full resolver path CMS-proven.
- Overall, 147 tracked source paths have been removed. Runtime module names
  and C `main` entrypoints remain unchanged; deferred EXEC sources are
  byte-exact and restorable.

## Current handoff

- M289 `279e91f`, M290 `02f4f80`, ACLEAN correction `3612aa2`, M291
  `b57e257`, M292 `be4e5c6`, M293 `93be2f7`, and M294 `e12c654` are published.
  M295 packages the remaining REXX sources in this handoff.
- `SOURCE_CONSOLIDATION_PROGRESS.md` is the current recovery note.
- Tracked source count: 177 → **30**. Deferred EXEC sources are restored with
  `scripts/restore-cms-exec.py MISSING`; scratch copies have exact SHA-256
  records in `archive/LOCAL_SCRATCH.json`.
- GitHub Actions run 2239 passed for `d2985bf`. The full local macOS gate
  remains **142/146 pass** with four known environment-only failures.
  M289-M294 source guards and G1-only CMS fixtures pass. M295 archive and
  dependency checks plus the preserved-source `CHECK` suite pass locally.
- GitHub Actions run 2241 passed for M294 (`e12c654`). Run 2242 failed at
  `LIVEPLANFIX`: its synthetic checkout lacks the production archive, while
  `scan_live_sources()` unconditionally loaded that archive to add deferred
  runtime sources. Made archive enrichment conditional for archive-free
  synthetic checkouts; the fixture now passes locally. `MISSING` parity,
  `AUDIT`, `LIVEDEPS`, full canonical guards, and preserved-source `CHECK` also
  pass locally. The fix was pushed as `78a97b1`; GitHub Actions run 2243
  completed successfully.
- Full CMS read-only smoke pass: 332 offline CMS-tooling unit tests and MCP
  protocol validation passed before connecting. On the existing G repository,
  `QUERY TERMINAL`, `QUERY DISK G`, source/repository `STATE`, `GIT STAMP`,
  `STATUS --short --branch`, `BRANCH`, `TAG --list`, `LOG --max-count 1`,
  `SHOW HEAD`, and `DIFF --name-only` all returned to Ready. The selected log
  and show verified commit `BE43A71F4C6030A0D8D3649DFDFE478409D03A10`; the
  worktree status was `## main` and diff output was empty. The test used G only;
  it created, changed, uploaded, or erased no CMS files and did not touch A.
  The terminal was left connected and idle. Evidence:
  `/private/var/folders/y0/hyjtc91x5071jc0gntk0pzcw0000gn/T/opencode/cms-full-smoke-evidence.json`.
- CI runs 2236/2237 initially stopped at M167 and 2238 at M168 because two
  preserved tests still expected the former combined HEAD/CHECKOUT dispatch.
  Both boundaries were updated; run 2239 passed, including M164-M171.
- GitHub runs 2233/2234 failed at the ACLEAN archive-inventory assertion: its
  expected legacy-helper set still listed five entries. The fixture now tracks
  all fourteen archived helpers; the focused ACLEAN test passes locally.
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
- The tracked runtime source set now retains `src/GIT.EXEC`, three protected
  M6 protocol helpers, 23 C sources, and `GITREF2.REPO`. Deferred EXEC modules
  are restored from the archive before tests or CMS source upload. M287/M288
  remain parse/refusal tested; M289-M294 have G-only fixture passes.
- C consolidation review confirmed `GITREC.C` includes `GITCIDX.C` and
  `GITSEL.C` with renamed `main` symbols, while each is also built as a
  standalone CMS module and referenced independently by target gates. Keep
  these files separate until the CMS build/upload interface is redesigned.
- Final `LIVEPLAN` inventory after M290: 96 tracked paths (88 GIT, 2 milestone,
  6 other), no exact duplicate source groups, and 32 files with zero lexical
  callers. Zero-call files remain preserved; this is not deletion approval.
- Remaining tracked C/runtime files retain CMS module and native ABI
  boundaries. Deferred EXEC modules keep their original CMS names through the
  lossless restore step; no target module or minidisk was changed by M295.

## Decisions and validation

_(Append dated decisions, file changes, exact commands/results, and remaining
risks here.)_
