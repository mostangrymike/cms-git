# M194 — Read-only native CMS FSREAD first-body-record gate

## Motivation and actual baseline

On October 11, 2026, M193 passed **on real z/VM 6.3 CMS** at
FIRST, MID, LAST via single-record `FSREAD FORM=E`. Each displayed
0.01s CPU/elapsed and the exact indexed header:
- FIRST object 1, one-based header record 1.
- MID object 3868, one-based header record 1,969,357.
- LAST object 7736, one-based header record 3,864,789.

The original `M173NET STAGE G1` has **RECFM V, LRECL 64,
3,864,799 records**; `M174NET INDEX G1` contains 7,736
unique objects. M192's index-only model exactly reconciled every
one-based record position and total stage count (0.61s elapsed).
M191's C text-stream `fseek` at MID required **25.82s**, but
these individual readings do **not** establish full-reader speed.

M188 still completes a full authenticated tree closure:
8 trees, 272 blobs, 279 entries, 280 verified,
2 x 3,864,799 sequential records, zero random seeks,
**205.04s CPU / 208.27s elapsed**. Do not replace M188.

## Scope: the first stage-body read, not a SHA-authenticated object

M194 is an intentionally narrow bridging gate. It creates only:

- `src/GITFRB.ASSEMBLE`: a **new, separate** read-only
  assembler CMS MODULE. It consumes FIRST/MID/LAST from CMS STACK,
  reads one known header via absolute record number, checks the same
  exact `OBJ n ` prefix as M193, then uses a second absolute FSREAD
  at **header record number + 1**, which is the first body record.
  It verifies the second returned length is 0..64 and even, and
  validates every returned character as an EBCDIC hex digit
  (0-9, A-F, a-f). It calls FSCLOSE and returns RC0 only after all
  checks. Zero-length body text is permitted for an empty Git blob.
- `src/GITFRP.EXEC`: an independent, different-stem wrapper with
  a 4096-byte G disk check and exact stage/index/module presence
  checks. It queues only the selector, executes `GITFRB` directly
  (no PIPE/STEM buffering), and reports a wrapper PASS only on RC0.
- `tests/test-m194-fsread-body.py`: host-only fixed-column
  assembler checks, fail-closed/read-only guards, EBCDIC class
  consistency and 7,736-object synthetic adjacent-record model.
  Linux **cannot assemble IBM CMS FSREAD** or verify target behavior.

| Selector | Verified header RECNO | New first-body RECNO |
|---|---:|---:|
| FIRST | 1 | 2 |
| MID | 1,969,357 | 1,969,358 |
| LAST | 3,864,789 | 3,864,790 |

This deliberately does **not** parse the entire indexed `OBJ`
header, obtain full object bytes, validate its OID/SHA-1, or walk
trees. Those are separate mandatory steps for the future native
FSREAD/C bridge. A body-hex PASS is **not** a full Git object PASS.

## Host gating and first real-CMS validation

Only after the M194 GitHub CI completes successfully and changes
are merged into `main`, on the Mac in `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITFRB.ASSEMBLE GITFRP.EXEC
```

On CMS MAINT, inexpensive read-only preflight and isolated assembly:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
QUERY FILEDEF
GLOBAL MACLIB OSMACRO DMSGPI PDPCLIB
ASSEMBLE GITFRB
```

Do not proceed unless the original G files are present, G uses
4K blocks, and the assembler reports **NO STATEMENTS FLAGGED**.
Then build ONLY the new distinct module on A:

```text
GLOBAL TXTLIB PDPCLIB
LOAD GITFRB (NOAUTO NOMAP
GENMOD GITFRB
STATE GITFRB MODULE A
```

Run **FIRST only** on the real CMS:

```text
GITFRP G FIRST
QUERY FILEDEF
```

Expected target console in order:

```text
M194 DIRECT BODY PROBE BEGIN FIRST
M194 FSREAD HEADER BEGIN
M194 FSREAD HEADER RETURNED
M194 RECORD HEADER PASS
M194 FSREAD BODY BEGIN
M194 FSREAD BODY RETURNED
M194 FIRST BODY RECORD HEX PASS
M194 READ ONLY BODY PROBE PASS
M194 BODY PROBE GATE PASS G FIRST
```

Record `Ready; T=cpu/elapsed` and post-probe FILEDEF output.
If and **only if FIRST passes**, test separately:

```text
GITFRP G MID
QUERY FILEDEF
```

Then, only if MID passes, independently test LAST:

```text
GITFRP G LAST
QUERY FILEDEF
```

Any assembler diagnostic, read error, header mismatch, body validation
failure, unexpected RC, stalled read, or leaked caller FILEDEF is
a target **failure**. Capture actual output; debug only the isolated
M194 source. Never rewrite the stage to match an experimental parser.

## Safety / non-goals

No `FSWRITE`, `FSERASE`, C `fseek`, reimport,
reindex, protected file change, FORMAT/ERASE on GIT600, replacement
of M185/M188/M193 modules, G-disk writes, or write-link to the
physically overlapping `PMAINT 0141` fullpack.

Do not rerun M190's 272-seek walk as a speed test.
Do not infer throughput from 0.01s single-record console timing.

**Current milestone state:** Host and target gates are separate.
After PR/CI, only real-CMS FIRST can establish two-record FSREAD
behavior. M194 is a necessary exploratory subgate toward a fully
SHA-authenticated FSREAD object adapter, not the object adapter itself.
