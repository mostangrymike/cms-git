# M193–M200 native CMS reader and cleanup history

Full historical runbooks preserved, including verification and failure safeguards. Original document versions remain available through Git history.

---

## Original: docs/M193_FSREAD_PROBE.md

# M193 — Native CMS FSREAD by record number

## October 11, 2026 15:45 — FINAL M193 LAST REAL CMS PASS

Operator's separate and third actual CMS probe:

```text
GITFSP G LAST
M193 DIRECT FSREAD G1 PROBE BEGIN LAST
M193 FSREAD BEGIN LAST RECNO 3864789
M193 FSREAD RETURNED
M193 RECORD HEADER PASS
M193 READ ONLY FSREAD PROBE PASS
M193 CMS FSREAD GATE PASS G LAST
Ready; T=0.01/0.01 15:45:07
```

**FIRST, MID, and LAST have ALL passed on actual z/VM 6.3 CMS:**
header RECNO 1, 1,969,357, and 3,864,789, with matching
indexed `OBJ 1 `, `OBJ 3868 `, and `OBJ 7736 ` prefixes.
Each individual run reported 0.01s CPU/elapsed.

M193 is COMPLETE for three **single-record header** probes.
Full body content, SHA-1/OID authentication, closure performance
and post-run `QUERY FILEDEF` are not established. The prior
M188 authenticated two-scan full closure remains the proven
208.27s elapsed baseline.

Next, isolated M194 adds a separate assembler/wrapper to read
an object's first hex body record as well as its header. See
`docs/M194_FSREAD_BODY.md`. No M193 reassembly or rerun is needed.

---

## Historical 15:37 checkpoint — REAL FIRST and MID PASS

**Target-proven at FIRST and MID (one record per invocation).**
Actual CMS `ASSEMBLE GITFSRD` produced no flagged statements,
then `LOAD GITFSRD (NOAUTO NOMAP` and `GENMOD GITFSRD`
succeeded. The operator's real single-record probes were:

```text
GITFSP G FIRST
M193 DIRECT FSREAD G1 PROBE BEGIN FIRST
M193 FSREAD BEGIN FIRST RECNO 1
M193 FSREAD RETURNED
M193 RECORD HEADER PASS
M193 READ ONLY FSREAD PROBE PASS
M193 CMS FSREAD GATE PASS G FIRST
Ready; T=0.01/0.01 15:29:48

GITFSP G MID
M193 DIRECT FSREAD G1 PROBE BEGIN MID
M193 FSREAD BEGIN MID RECNO 1969357
M193 FSREAD RETURNED
M193 RECORD HEADER PASS
M193 READ ONLY FSREAD PROBE PASS
M193 CMS FSREAD GATE PASS G MID
Ready; T=0.01/0.01 15:37:38
```

Both exact header checks passed: `OBJ 1 ` and `OBJ 3868 `.
Both probes use read-only native `FSREAD`, `FORM=E`,
`RECFM=V`, `NOREC=1`, `BSIZE=64`,
and `FSCLOSE` with the known one-based RECNO.
The underlying original G file has 3,864,799
variable records of LRECL 64. These are genuine
target results, not Linux-host IBM-macro simulations.

The 0.01s MID elapsed compares favorably with the
**25.82s** actual C text-stream `fseek` MID probe.
However, 0.01s is a two-decimal timer reading;
two isolated probes do not prove a repeatable
per-object bound or a full Git reader speedup.

**Evidence boundary:** LAST RECNO 3,864,789 remains
untested. Neither FULL object-body reads, Git SHA/OID
authentication through FSREAD, nor post-run
`QUERY FILEDEF` has been demonstrated by the
supplied M193 transcripts. The proven complete
closure baseline remains M188, 208.27s elapsed.

**Next safe CMS test using the already-installed,
known-good `GITFSRD MODULE A`:**

```text
GITFSP G LAST
QUERY FILEDEF
```

Require native `M193 FSREAD BEGIN LAST RECNO 3864789`,
`M193 FSREAD RETURNED`, `M193 RECORD HEADER PASS`,
`M193 READ ONLY FSREAD PROBE PASS`, and wrapper
`M193 CMS FSREAD GATE PASS G LAST`; record actual
CPU/elapsed. No Mac transfer or reassembly needed.
A failure halts new FSREAD optimization work,
without touching G or replacing M188.

If LAST passes, move to a **new isolated** index-to-record
adapter with independent record count/length and
SHA/OID validation; avoid uncontrolled large-scale
seek experiments and do not replace older proven modules.

---



## Confirmed M192 real CMS evidence (October 11, 2026)

Original protected input `M173NET STAGE G` is a
variable-record CMS file:

```text
LISTFILE M173NET STAGE G (ALLOC
M173NET STAGE G1 V 64 3864799 62189
CMSCLNK GITRCNM PLAIN
ASSEMBLER (XF) DONE
NO STATEMENTS FLAGGED IN THIS ASSEMBLY
CMSCLNK: built GITRCNM MODULE mode PLAIN
GITRCN G 3864799
M192 DIRECT RECORD MODEL BEGIN
M192 INDEX TOTAL 7736 UNIQUE 7736
M192 RECORD 1 RECNO 1 OFFSET 0
M192 RECORD 3868 RECNO 1969357 OFFSET 127843709
M192 RECORD 7736 RECNO 3864789 OFFSET 250858746
M192 STAGE MODEL RECORDS 3864799 EXPECTED 3864799
M192 READ ONLY RECORD PLAN PASS
M192 RECORD MODEL GATE PASS G 3864799
Ready; T=0.60/0.61 15:16:28
```

**M192 has passed on real CMS**: the size-derived
physical record ordinal calculation exactly predicts
the stage's 3,864,799 records. M192 performs index-only
arithmetic; it has not actually read a stage record.

M191's earlier direct C text-stream seek probes
passed FIRST in 0.64s and MID in 25.82s elapsed.
That expense motivates CMS **record-number** I/O,
not more C `fseek` calls. The 272-seek M190 walk
should **not** be rerun as a performance experiment.

## M193 isolated assembler experiment (original host-only design notes)

The first native CMS macro probe is a separate
`src/GITFSRD.ASSEMBLE` program and distinct
`src/GITFSP.EXEC` wrapper. Neither changes any
M185/M188 native source or protected original
stage/index. The program uses IBM CMS:

```text
FSREAD 'M173NET STAGE G1',BUFFER=RECBUF,BSIZE=64,
       RECFM=V,RECNO=(5),NOREC=1,FORM=E,ERROR=RDERR
```

Important IBM-documented constraints:

- `RECNO` is an **absolute one-based CMS record**
  number. `FORM=E` supports values exceeding 65,535.
- The actual original stage has **RECFM V, LRECL 64**;
  `NOREC=1`, `BSIZE=64` and `RECFM=V` match.
- FSREAD register 0 reports actual bytes read.
  Only RC0 is accepted; truncated, missing or
  malformed records fail the probe.
- `FSCLOSE` is called after the read, so the
  file is not intentionally left open.
- The file ID is **hard-coded** to protected
  `M173NET STAGE G1`, and no write, erase,
  reformat, reindex or file creation is present.

This deliberately does **one record read only**.
The existing M192-verified three ordinals are
hard-coded, preventing arbitrary or unvalidated
record numbers:

| Probe | One-based RECNO | Required prefix |
|---|---:|---|
| FIRST | 1 | `OBJ 1 ` |
| MID | 1,969,357 | `OBJ 3868 ` |
| LAST | 3,864,789 | `OBJ 7736 ` |

The assembler obtains `FIRST`, `MID` or `LAST`
via one `LINERD TYPE=STACK` record. The REXX
wrapper checks the 4K G disk, original stage and
index, and that `GITFSRD MODULE A` exists,
before placing the selector on the CMS stack.
It calls the MODULE directly, with no
`PIPE CMS ... | STEM` buffering. `LINEWRT`
prints before/after the single FSREAD so that
the progress is visible on the operator's
3270 console.

**Historical pre-target note:** at the time this section was drafted, M193 had not yet assembled or executed on z/VM. FIRST and MID have now passed, as documented above.
The host CI test is only a **static assembler
guardrail** plus an independent C89 host model
of the record arithmetic; Linux cannot expand
the IBM `FSREAD`/CMS macros. Actual assembler
success and return codes remain target gates.

## Original first CMS validation runbook (historical)

Mac, from the usual `ibm-sandbox/src` directory:

```sh
git pull
./cms-upload.sh GITFSRD.ASSEMBLE GITFSP.EXEC
```

CMS MAINT — inexpensive preflight:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
LISTFILE M173NET STAGE G (ALLOC
QUERY FILEDEF
STATE GITFSRD ASSEMBLE A
GLOBAL MACLIB OSMACRO DMSGPI PDPCLIB
ASSEMBLE GITFSRD
```

Only after `ASSEMBLE GITFSRD` reports **no
flagged statements**, load and generate the new
module on A (do not replace an older module):

```text
GLOBAL TXTLIB PDPCLIB
LOAD GITFSRD (NOAUTO NOMAP
GENMOD GITFSRD
STATE GITFSRD MODULE A
```

Then **run FIRST only**:

```text
GITFSP G FIRST
QUERY FILEDEF
```

Expected if FSREAD works:

```text
M193 DIRECT FSREAD G1 PROBE BEGIN FIRST
M193 FSREAD BEGIN FIRST RECNO 1
M193 FSREAD RETURNED
M193 RECORD HEADER PASS
M193 READ ONLY FSREAD PROBE PASS
M193 CMS FSREAD GATE PASS G FIRST
```

If FIRST passes safely, a separate MID
probe can test large-record access:

```text
GITFSP G MID
QUERY FILEDEF
```

`GITFSP G LAST` is optional and should be
deferred until FIRST/MID prove the macro behavior.
A header mismatch, RC8, unexpected EOF, or
stalled read is **not a PASS**; keep the console
output. Any assembly error must be fixed in
the isolated new source; never modify original
G inputs or verified older modules as a
workaround.

The current performance reference remains
the M188 **two-sequential-scan** reader:
205.04s CPU / **208.27s elapsed**, with
8 trees, 272 reached blobs, 280 verified,
7,736 unique indexed OIDs and zero random
seeks. M193 is an I/O feasibility probe,
**not** a replacement Git tree reader.

## References

The relevant IBM z/VM CMS macro documentation:

- https://www.ibm.com/docs/en/zvm/7.2.0?topic=instructions-fsread
- https://www.ibm.com/docs/en/zvm/7.2.0?topic=instructions-fsclose
- https://www.ibm.com/docs/en/zvm/7.2.0?topic=instructions-fscb

No original `M173NET STAGE G`,
`M174NET INDEX G`, GIT600 minidisk,
M185/M188 target module or overlapping
PMAINT 0141 fullpack is modified.


---

## Original: docs/M194_FSREAD_BODY.md

# M194 — Read-only native CMS FSREAD first-body-record gate

## October 11, 2026 — REAL CMS FIRST/MID/LAST TARGET PASS

User's actual z/VM 6.3 console showed clean XF assembly:

```text
ASSEMBLE GITFRB
ASSEMBLER (XF) DONE
NO STATEMENTS FLAGGED IN THIS ASSEMBLY
Ready; T=0.16/0.18 16:03:16
LOAD GITFRB (NOAUTO NOMAP
GENMOD GITFRB
```

All three independent native two-record probes passed:

```text
GITFRP G FIRST
M194 FSREAD HEADER RETURNED
M194 RECORD HEADER PASS
M194 FSREAD BODY RETURNED
M194 FIRST BODY RECORD HEX PASS
M194 READ ONLY BODY PROBE PASS
M194 BODY PROBE GATE PASS G FIRST
Ready; T=0.01/0.01 16:03:47

GITFRP G MID
M194 FSREAD HEADER RETURNED
M194 RECORD HEADER PASS
M194 FSREAD BODY RETURNED
M194 FIRST BODY RECORD HEX PASS
M194 READ ONLY BODY PROBE PASS
M194 BODY PROBE GATE PASS G MID
Ready; T=0.01/0.01 16:04:08

GITFRP G LAST
M194 FSREAD HEADER RETURNED
M194 RECORD HEADER PASS
M194 FSREAD BODY RETURNED
M194 FIRST BODY RECORD HEX PASS
M194 READ ONLY BODY PROBE PASS
M194 BODY PROBE GATE PASS G LAST
Ready; T=0.01/0.01 16:04:15
```

Each target invocation additionally printed its DIRECT BODY PROBE BEGIN,
FSREAD HEADER BEGIN and FSREAD BODY BEGIN markers.
M194 is **REAL CMS TARGET PROVEN** for both header and first
hexadecimal body record at FIRST/MID/LAST. Each invocation
reported 0.01s elapsed, not a full-reader benchmark.
The supplied transcript does not include post-run `QUERY FILEDEF`.

**Next isolated gate: M195** reads the entire known LAST
object body: ten records, using `GITFL10`/`GITFLP`.
See `docs/M195_LAST_BODY.md`. It is host-only until
separate successful real-CMS assembly/execution.
No complete-object SHA/OID check exists yet;
the working M188 tree closure remains 208.27s elapsed.

---

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

## Historical M194 initial-target runbook (completed)

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


---

## Original: docs/M195_LAST_BODY.md

# M195 — Complete ten-record LAST body through native FSREAD

## October 12, 2026 — CORRECTED M195 REAL CMS TARGET PASS

The prior nine-character-label error was corrected,
uploaded and actually reassembled successfully. The
new real z/VM 6.3 transcript includes:

```text
ASSEMBLE GITFL10
ASSEMBLER (XF) DONE
NO STATEMENTS FLAGGED IN THIS ASSEMBLY
Ready; T=0.13/0.15 09:22:41
GLOBAL TXTLIB PDPCLIB
LOAD GITFL10 (NOAUTO NOMAP
GENMOD GITFL10
GITFLP G LAST
M195 DIRECT LAST COMPLETE BODY PROBE BEGIN
M195 LAST FSREAD COMPLETE BODY BEGIN
M195 LAST HEADER RETURNED
M195 LAST HEADER PASS
M195 LAST TEN BODY READS BEGIN
M195 LAST TEN BODY RECORDS HEX PASS
M195 READ ONLY COMPLETE BODY RECORDS PASS
M195 COMPLETE BODY GATE PASS G LAST
Ready; T=0.01/0.01 09:22:59
```

**M195 is REAL CMS TARGET PASS** for the complete
physical header-plus-ten-body-record sequence of the
final staged object. The 289–320 decoded byte length
and hexadecimal content are validated. The original
G stage/index were not changed by the M195 read-only
module. This result does **not** calculate Git SHA1
or compare the object's complete stored OID. The
supplied transcript does not contain a post-run
`QUERY FILEDEF`, so FILEDEF cleanup is not separately
established.

M196 (index-only object type/size/OID/record geometry)
is the next independent CMS gate; after its target
PASS and a native M197 module build, M198 can test a
new read-only FSREAD-to-A-scratch bridge and complete
SHA1 authentication. See `docs/M198_FSREAD_SHA_BRIDGE.md`.

---

## October 12, 2026 — REAL CMS ASSEMBLY RC8 / FIXED SOURCE

Actual CMS operator output:

```text
ASSEMBLE GITFL10
ASSEMBLER (XF) DONE
              223          B     EVENCHECK
IFO236 ILLEGAL CHARACTER IN EXPRESSION NEAR OPERAND COLUMN 1
              226 EVENCHECK LR    6,7
IFO016 ILLEGAL OR INVALID NAME FIELD
NUMBER OF STATEMENTS FLAGGED IN THIS ASSEMBLY =     2
Ready(00008); T=0.13/0.15 09:13:01
```

Root cause: label `EVENCHECK` was 9 characters long; CMS XF
assembler symbols must fit columns 1–8. The source was corrected
to the 7-character `EVENCHK` in the branch and its two references:

```text
         B     EVENCHK
EVENCHK  LR    6,7
```

A host regression guard now checks **all assembler labels** in
M193, M194 and M195 for the eight-character ceiling, in addition
to the original 72-column and record-body validations.
The initial GitHub host checks did **not** catch this XF syntax
error. The real M195 runtime remains **not verified** until a
clean reassembly and a successful target invocation.

From Mac `ibm-sandbox/src`, after fixing branch is merged:

```sh
git pull
./cms-upload.sh GITFL10.ASSEMBLE
```

CMS MAINT: reassemble corrected source **before** any LOAD or
GENMOD. Do not use failed-assembly TEXT or any earlier module:

```text
GLOBAL MACLIB OSMACRO DMSGPI PDPCLIB
ASSEMBLE GITFL10
```

Only if assembler reports **NO STATEMENTS FLAGGED**:

```text
GLOBAL TXTLIB PDPCLIB
LOAD GITFL10 (NOAUTO NOMAP
GENMOD GITFL10
GITFLP G LAST
FILEDEF
```

No second upload of `GITFLP.EXEC` is necessary if it was
already installed. Do not run M196 as a substitute for this
target gate; capture actual Ready CPU/elapsed and FILEDEF.

---

## Real CMS evidence establishing the bounded range

October 11, 2026 at 16:01–16:04 local CMS time:
`ASSEMBLE GITFRB` reported NO STATEMENTS FLAGGED.
`LOAD/GENMOD GITFRB` succeeded.
`GITFRP G FIRST`, `GITFRP G MID` and
`GITFRP G LAST` **each passed on z/VM 6.3 CMS**,
verifying **both** the exact selected header and its
first hexadecimal body record through two direct `FSREAD`
calls. Each printed `T=0.01/0.01`. No final
`QUERY FILEDEF` was included in the supplied transcript.
M194 is REAL CMS TARGET PASS for all three locations.

M193 previously passed all three single-header positions:
1 / 1,969,357 / 3,864,789. The M192 index-derived
model matched the original protected `M173NET STAGE G1`
file's **3,864,799** variable-length CMS records.

For the final object, the known verified header is
**RECNO 3,864,789**, object 7,736. Therefore the
entire remaining original stage file holds exactly
**ten body records, RECNO 3,864,790 through 3,864,799**.
Under the M192 32-byte body-chunk model, the last object's
encoded data has between **289 and 320 decoded bytes**:
nine complete 64-character hex records, then one final
2..64-character even-length hex record.

## Isolated implementation

M195 adds two separate files only, with **no modification
to M193/M194, M188, or any original G file**:

- `src/GITFL10.ASSEMBLE`: native CMS assembler with
  one FSREAD of the known LAST header and ten explicit
  absolute one-based FSREAD calls for its entire hex
  body. Each of the first nine returned record lengths must
  be precisely 64; the tenth must be an even nonzero
  length 2..64. Every byte must be an EBCDIC hex digit;
  the aggregate decoded length must be 289..320.
  It calls FSCLOSE and returns RC0 only if all checks pass.
- `src/GITFLP.EXEC`: independent filemode-G/4K-disk,
  protected stage/index presence and new MODULE preflight;
  only `GITFLP G LAST` is accepted. Direct module call,
  no PIPE buffering or writes.
- `tests/test-m195-last-body.py` independently models
  7,736 synthetic objects and the exact last-body format,
  includes malformed-length/hex/truncation negatives and
  guards read-only assembler and EXEC forms. **Linux cannot
  assemble or execute IBM CMS macros.**

**Evidence boundary:** A PASS here establishes complete
physical hexadecimal body-record coverage for the final object,
not Git SHA-1/OID authentication. The header is checked by
the `OBJ 7736 ` prefix, and the count by the sealed file-end
model, but the entire header's stored size/OID and Git digest
are not verified. Next must introduce an index-driven,
fully OID-authenticated object reader before full-tree
performance comparisons.

## Safe target runbook (after green CI and merge)

Mac, from the existing `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITFL10.ASSEMBLE GITFLP.EXEC
```

CMS MAINT preflight — stop on unexpected state:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
LISTFILE M173NET STAGE G (ALLOC
FILEDEF
GLOBAL MACLIB OSMACRO DMSGPI PDPCLIB
ASSEMBLE GITFL10
```

Only if `ASSEMBLER (XF) DONE` and
`NO STATEMENTS FLAGGED IN THIS ASSEMBLY`:

```text
GLOBAL TXTLIB PDPCLIB
LOAD GITFL10 (NOAUTO NOMAP
GENMOD GITFL10
STATE GITFL10 MODULE A
```

Then run only this one bounded LAST body probe:

```text
GITFLP G LAST
FILEDEF
```

Expected ordered markers:

```text
M195 DIRECT LAST COMPLETE BODY PROBE BEGIN
M195 LAST FSREAD COMPLETE BODY BEGIN
M195 LAST HEADER RETURNED
M195 LAST HEADER PASS
M195 LAST TEN BODY READS BEGIN
M195 LAST TEN BODY RECORDS HEX PASS
M195 READ ONLY COMPLETE BODY RECORDS PASS
M195 COMPLETE BODY GATE PASS G LAST
```

Capture true `Ready; T=CPU/elapsed`, final FILEDEF
output and any assembler error; no looping many thousands
of random records for speed testing until this bounded
real mainframe gate is complete.

## Protected operations

GIT600 `M173NET STAGE G1` and `M174NET INDEX G1`
remain original read-only inputs. Do not reimport,
reindex, erase, format, replace M185/M188/M193/M194,
overwrite prior proven MODULEs or write-link the
physically overlapping PMAINT 0141 fullpack.
No full M190 272-seek experiment. The existing M188
authenticated closure baseline remains 205.04s CPU /
208.27s elapsed (8 trees, 272 blobs, 280 verified).


---

## Original: docs/M196_INDEX_OBJECT_PLAN.md

# M196 — Select a verified index object and compute its CMS record span

## October 12, 2026 — REAL CMS M196 TARGET PASS

User's actual z/VM 6.3 build and validation:

```text
CMSCLNK GITRP6M PLAIN
ASSEMBLER (XF) DONE
NO STATEMENTS FLAGGED IN THIS ASSEMBLY
CMSCLNK: built GITRP6M MODULE mode PLAIN
Ready; T=0.83/0.88 10:10:33
GITRP6 G 7736 10
M196 NATIVE INDEX OBJECT RECORD PLAN BEGIN
M196 INDEX TOTAL 7736 UNIQUE 7736
M196 OBJECT 7736 TYPE 2 SIZE 291 OID 9069E154EB145C25D8E1A8D31F72252C53E6684A OF
M196 RECORDS HEADER 3864789 BODY 3864790 LAST 3864799 COUNT 10
M196 STAGE MODEL RECORDS 3864799 EXPECTED 3864799
M196 READ ONLY INDEX OBJECT PLAN PASS
M196 INDEX OBJECT PLAN GATE PASS G 7736
Ready; T=0.65/0.66 10:10:46
```

**M196 is REAL CMS TARGET PASS.** The selected final object
is **TYPE 2 (tree), SIZE 291 bytes, OID
`9069E154EB145C25D8E1A8D31F72252C53E6684A`**.
Its ten body records span exactly 3,864,790–3,864,799,
with nine complete 64-character hex records and a final
6-character hex record (3 remaining decoded bytes).
The OID is the **indexed expected Git identity**, not
a freshly SHA-1-authenticated stage-body digest.

The console line appears to truncate after `OF`,
where the native program's longer byte-offset field
would print. Do not infer a real indexed OFFSET number
from that truncated line. Complete record geometry
and both PASS markers are independently visible.
The 0.66-second elapsed is one observation.
No post-run `QUERY FILEDEF` is included.

M195 previously passed its complete eleven-record FSREAD
target gate at 09:22. Next is corrected M197 SHA core
plus M198's independent, NEW-only A scratch adapter.
**Critical EBCDIC caveat:** M197's original C source
used native character literals for the canonical Git
hash prefix. A source correction replaces that prefix
with explicit ASCII bytes before attempting real CMS
authentication. See `docs/M197_NATIVE_SHA.md`.

---

## Scope and target evidence

M193: FIRST, MID and LAST header FSREAD on real z/VM 6.3 CMS
passed (0.01s each). M194: on the same real machine, three
independent probes of header **and first body record** all
passed (also 0.01s each).

M195, the new isolated ten-record LAST body probe, was
merged as PR #174 and passed Linux static/model CI, but
**has not yet supplied an actual CMS `GITFLP G LAST` PASS**.
Do not infer it succeeded.

The known original stage/index on protected GIT600 are:

- `M173NET STAGE G1`: RECFM V, LRECL 64, 3,864,799 records.
- `M174NET INDEX G1`: 7,736 unique Git object entries.
- M192 index-only physical-record arithmetic completed in
  0.61s on CMS, exactly matching the stage's record count.
- Known object headers: number 1 at record 1; 3868 at
  1,969,357; 7736 at 3,864,789.

M196 advances from M192's **three hard-coded samples** to
a validated **arbitrary physical object number**. This is
an independent read-only index-to-record *plan* needed
before a future dynamic native FSREAD adapter.

## Implementation and integrity contract

New standalone, strictly C89 `src/GITRP6M.C`:

1. Read *only* `dd:IDXIN` opened `r`; **never open
   STGIN**, access stage bytes, or call `fseek`.
2. Validate full PIDX1/PEND1 header/trailer; totals and
   unique counts; 40-hex binary OIDs strictly increasing;
   unique and complete physical object numbers, types 1..4,
   bounded sizes, nonnegative and strictly increasing
   physical byte offsets (checked in physical order).
3. Compute each object's header record number, first body
   record number, number of body records and final
   inclusive body record using one header followed by
   `max(1, ceil(size/32))` hex records per object.
4. Require computed full original stage count to match
   the caller's exact observed 3,864,799 records; require
   31-bit extended CMS record-number bounds.
5. Require caller's selected object number to be present;
   require its body-record count at most an explicit 1..64
   bound, before providing its expected Git OID/type/size
   and exact header/body/last records.
6. Print a PASS only after all checks. RC4 is bad usage,
   RC8 is failed integrity/bounds, RC0 means index-only
   record plan success.

The different-stem `src/GITRP6.EXEC` accepts:

```text
GITRP6 G object-number max-body-records
```

It checks the 4K G disk, original stage/index, native
`GITRP6M MODULE A`, rejects caller-owned IDXIN FILEDEF,
binds **only** `IDXIN` read-only to the original index,
executes the C89 module **directly** without PIPE buffering,
captures its RC, and clears its owned IDXIN before gate
PASS. No STGIN definition, stage read, writes or changes
to any prior milestone modules. This model does NOT
authenticate the stage data by itself; do not confuse
an index OID with a newly computed object SHA-1.

The host test `tests/test-m196-index-object-plan.py`
compiles C with `-std=c89 -Wall -Wextra -Werror`,
creates 7,736 distinct synthetic Git objects and a real
GITPIDX index, checks FIRST/MID/LAST selected span and
OID/type/size, source unchanged SHA256 and rejects bad
trailer/record total/number/size bound/duplicate/invalid
OIDs/invalid offsets. Linux CI is host-only, not CMS.

## Safe CMS gate, only after CI and merge

**First finish and record M195's real-CMS validation**
separately; this M196 index-only run neither replaces
nor proves the pending M195 full-body probe.

Mac in the existing `ibm-sandbox/src` directory:

```sh
git pull
./cms-upload.sh GITRP6M.C GITRP6.EXEC
```

CMS MAINT preflight and build (no edits to G or M195):

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
FILEDEF
STATE GITRP6M C A
CMSCLNK GITRP6M PLAIN
STATE GITRP6M MODULE A
```

Only on clean 4K-disk preflight and no flagged
assembler statements, plan the LAST object first:

```text
GITRP6 G 7736 10
FILEDEF
```

Expected *shape* of native output, not guessed size/OID:

```text
M196 NATIVE INDEX OBJECT RECORD PLAN BEGIN
M196 INDEX TOTAL 7736 UNIQUE 7736
M196 OBJECT 7736 TYPE ... SIZE ... OID ... OFFSET ...
M196 RECORDS HEADER 3864789 BODY 3864790 LAST 3864799 COUNT 10
M196 STAGE MODEL RECORDS 3864799 EXPECTED 3864799
M196 READ ONLY INDEX OBJECT PLAN PASS
M196 INDEX OBJECT PLAN GATE PASS G 7736
```

The program will print the **actual** type, size and
40-hex OID read from the verified index. Do not invent
those values or claim them until target output arrives.
Actual size should imply ten body records, but exact
size/OID still need target evidence.

Capture `Ready; T=CPU/elapsed` and `QUERY FILEDEF`.
A failure halts progression to any dynamic FSREAD reader;
preserve M188 full authenticated tree closure at
205.04s CPU / 208.27s elapsed.

## Next design boundary after M195 and M196 real-CMS PASS

Plan an isolated assembler adapter taking bounded,
index-validated RECNO/count/type/size/OID rather
than the three hard-coded M193/M194 probe positions.
Read every variable-length record, reconstruct all
canonical Git object bytes and calculate SHA-1
independently before accepting any object as authentic.
That adapter must pass negative record/size/OID tests
and target performance measurements before any attempt
to replace M188.

Keep GIT600 original stage and index read-only, no
reimport/reindex, no FORMAT/ERASE, no overwriting
M185/M188/M193/M194/M195 modules or write-link to the
overlapping PMAINT 0141 fullpack. Do not rerun the
unverified M190 272-seek walk.


---

## Original: docs/M197_NATIVE_SHA.md

# M197: Canonical Git object SHA-1 from disposable input

## October 12, 2026 — EBCDIC portability correction

The first M197 C89 SHA core was tested on ASCII Linux,
but its Git prefix construction used native C string
literals (`"tree"`, `"blob"`, etc.) and native digit
arithmetic (`'0'+digit`). On z/VM CMS, native C text
is EBCDIC, while the canonical Git SHA-1 prefix
**must be ASCII bytes**, including the type, space,
decimal digits and final NUL. Without correction, a
perfectly valid binary body would yield a wrong Git
OID on the real CMS.

The new `GITVO7M.C` uses fixed numeric ASCII byte
arrays for each Git type and ASCII numeric constants
`0x20` for space and `0x30` for decimal digits.
The input staging text parser still uses the native
execution character set for EBCDIC `OBJ`, decimal
header fields and hex digits. Only the canonical
bytes entering SHA-1 are explicitly ASCII.

Host `tests/test-m197-native-object-sha.py` now
verifies every raw Git type-byte array against ASCII,
requires explicit numeric delimiter/digit bytes,
checks that native C type strings cannot reappear in
the SHA header constructor, and adds a **291-byte
type-2 tree** SHA vector, corresponding to the actual
M196 CMS target object's type and length. The real
M196 expected OID is
`9069E154EB145C25D8E1A8D31F72252C53E6684A`.
A passing host fixture does not claim that actual
stage payload is authenticated.

**Do not compile or use an older M197 module** built
from the pre-correction M197 C source. Re-upload the
updated `GITVO7M.C` from main after correction CI
and merge, rebuild `CMSCLNK GITVO7M PLAIN`, and
then test through the distinct M198 read-only native
FSREAD-to-NEW-scratch bridge, using the exact indexed
OID above. No original G file is written.

M195 complete body and M196 index plan both PASSED
on actual z/VM 6.3 CMS on October 12. M198 is still
host-only until direct IBM macro assembly/runtime
and independent M197 SHA result succeed on CMS.

---

## Purpose

M197 introduces a stand-alone strict-C89 verification core,
`GITVO7M.C`, and distinct CMS REXX wrapper `GITVO7.EXEC`.
It validates one complete object represented as a bounded
header and hexadecimal body records. It reads only
`dd:OBJIN`, which the wrapper binds to a pre-existing
disposable `GITVRAW DATA A` file. Neither program accesses
or modifies the original G stage or index.

Input header: `OBJ number type size 40-hex-oid`.
Types 1..4 map to commit/tree/blob/tag. For size zero
exactly one empty body record is required; otherwise
body records are chunks of 32 binary bytes encoded as
at most 64 hex characters per record. The final record
must match the remaining decoded size exactly, without
extra records. The verifier rejects malformed headers,
sizes greater than 16 MiB, odd or invalid hex, mismatched
OID and changed, truncated or extra body records.

Successful verification independently calculates
canonical Git SHA-1 of
`type + space + decimal-size + NUL + binary-body`
and compares all 20 digest bytes to the expected OID.
Only a complete match returns RC0 and
`M197 READ ONLY FULL OBJECT SHA1 PASS`.

## Evidence boundary

Host CI builds the C source under
`-std=c89 -Wall -Wextra -Werror` and tests zero-size,
short and multiblock blob, tree, commit and tag vectors,
corruptions and preserved input SHA256. This is a
host-only SHA core. The live CMS FSREAD-to-disposable
input bridge has **not** been implemented; M197 does not
claim real target FSREAD or full-tree performance.

M193 and M194 passed real CMS at FIRST/MID/LAST.
M195's complete LAST body probe is merged and
host-proven but still requires live `GITFLP G LAST`.
M196's index-to-object plan is merged and host-proven
but still requires live `GITRP6 G 7736 10`.
M188 remains the real authenticated closure baseline,
208.27s elapsed.

## Next gated implementation

Complete M195 and M196 CMS runs before integrating
an isolated read-only FSREAD adapter that copies a
single validated object into a collision-checked
disposable scratch file. No original G file may be
written, reformatted, reindexed or replaced.

The M197 program can be built independently with
`CMSCLNK GITVO7M PLAIN`, but `GITVO7` must not
be run until an independently verified disposable
`GITVRAW DATA A` source and its expected OID exist.

Never overwrite proven M185/M188/M193/M194/M195
modules or write-link the overlapping PMAINT 0141
fullpack. Do not run M190's unverified 272-seek walk.


---

## Original: docs/M198_FSREAD_SHA_BRIDGE.md

# M198 — Read-only FSREAD into NEW-only disposable A scratch, then SHA-1

## October 12, 2026 — REAL CMS END-TO-END SHA PASS

The corrected M197 SHA C MODULE assembled and linked
successfully using `CMSCLNK GITVO7M PLAIN`. New
`GITBX8` also assembled with no flagged statements,
loaded and GENMOD'd. The full target transcript:

```text
GITB8 G LAST 9069E154EB145C25D8E1A8D31F72252C53E6684A
DMSSTT002E File GITVRAW DATA A not found
M198 SOURCE FSREAD TO NEW SCRATCH BEGIN
M198 READ ONLY STAGE LAST OBJECT BEGIN
M198 LAST 11 STAGE RECORDS VERIFIED
M198 NEW DISPOSABLE OBJECT WRITE PASS
M198 VERIFIED SHA1 CHECK BEGIN
M197 DISPOSABLE FULL OBJECT VERIFICATION BEGIN
M197 OBJECT 7736 TYPE 2 SIZE 291 BODY RECORDS 10
M197 VERIFIED OID 9069E154EB145C25D8E1A8D31F72252C53E6684A
M197 READ ONLY FULL OBJECT SHA1 PASS
M197 DISPOSABLE FULL OBJECT GATE PASS
M198 NATIVE FSREAD FULL OID GATE PASS G LAST
Ready; T=0.02/0.03 10:28:57
LISTFILE GITVRAW DATA A (ALLOC
GITVRAW DATA A1 V 64 11 1
Ready; T=0.01/0.01 10:29:05
```

M198 and M197 **ARE FULLY REAL CMS TARGET-PROVEN**
for this 291-byte type-2 Git tree and its independent
SHA1. Only the original G stage was read; an eleven
variable-record one-block disposable A scratch was
created using NEW-only semantics. The original G
stage and index remain preserved. The combined
runtime for this one object was 0.03 seconds; this
does not prove full tree speed. The caller did not
provide final `QUERY FILEDEF`; FILEDEF state is
not independently established. Preserve the
existing `GITVRAW DATA A1`; do not re-run M198.

Next separate M199 broadens the adapter to accept
bounded physical record numbers and count from
the independently verified M196 object plan and
creates **GITR199 DATA A1**, a different scratch
file. See `docs/M199_BOUNDED_FSREAD.md`.

---

## October 12, 2026 — M196 real CMS PASS / verified expected OID

Actual M196 `GITRP6 G 7736 10` completed in
0.66 seconds elapsed, validating all 7,736 indexed
objects and selecting:

```text
M196 OBJECT 7736 TYPE 2 SIZE 291 OID 9069E154EB145C25D8E1A8D31F72252C53E6684A
M196 RECORDS HEADER 3864789 BODY 3864790 LAST 3864799 COUNT 10
M196 STAGE MODEL RECORDS 3864799 EXPECTED 3864799
M196 READ ONLY INDEX OBJECT PLAN PASS
M196 INDEX OBJECT PLAN GATE PASS G 7736
```

The real console's longer object line was cut after
the beginning of its OFFSET field, but the complete
OID, type, size and expected record geometry appeared.
The exact expected tree OID is:

```text
9069E154EB145C25D8E1A8D31F72252C53E6684A
```

Since size is **291**, the tenth body record must have
exactly **6 hex characters**; M198 currently enforces a
broader 289–320-byte bound but its M197 full-object
digest and stored header must match the complete
type-2 tree object to pass. It remains **host-only**
until separately built and run on real CMS.

### Critical prerequisite: M197 ASCII Git prefix on EBCDIC CMS

The initial M197 C source built its canonical
`tree 291\0` SHA-1 prefix using native C character
literals; those are EBCDIC on CMS, not Git's required
ASCII. A corrective M197 branch explicitly encodes
Git type bytes, ASCII space 0x20 and decimal digit
base 0x30 as numeric bytes. Its host tests exercise
a 291-byte tree and verify no native-string hash
prefix is reintroduced.

**Do not run M198 with any old M197 MODULE.**
After the fix is merged, use a fresh Mac `git pull`
and re-upload the corrected `GITVO7M.C`, then
`CMSCLNK GITVO7M PLAIN`. M198 is gated on that
clean CMS build, its own clean `ASSEMBLE GITBX8`,
no existing disposable scratch, and exact M196 OID.

After all gates, the eventual real CMS invocation is:

```text
GITB8 G LAST 9069E154EB145C25D8E1A8D31F72252C53E6684A
FILEDEF
LISTFILE GITVRAW DATA A (ALLOC
```

The LAST probe may create exactly one scratch
`GITVRAW DATA A` on the A minidisk; this is
intentional and must never overwrite an existing file.
On failure, leave any scratch untouched for diagnostics;
do not rerun automatically. The original G stage
and index must remain unmodified.

---

## Verified upstream gates

**October 12, 2026, 09:22 local CMS:** corrected
`GITFL10.ASSEMBLE` assembled with **NO STATEMENTS FLAGGED**,
then `LOAD GITFL10 (NOAUTO NOMAP` and `GENMOD GITFL10`
succeeded. The actual `GITFLP G LAST` invocation passed:

```text
M195 DIRECT LAST COMPLETE BODY PROBE BEGIN
M195 LAST FSREAD COMPLETE BODY BEGIN
M195 LAST HEADER RETURNED
M195 LAST HEADER PASS
M195 LAST TEN BODY READS BEGIN
M195 LAST TEN BODY RECORDS HEX PASS
M195 READ ONLY COMPLETE BODY RECORDS PASS
M195 COMPLETE BODY GATE PASS G LAST
Ready; T=0.01/0.01 09:22:59
```

M195 is **REAL CMS TARGET PASS** for eleven independently
accessed records (header plus ten body records), with exact
64-hex chunks, bounded final hex width, valid hex characters,
and 289–320 total decoded bytes. This does **not** verify
the Git OID or SHA-1. No post-run `QUERY FILEDEF` output
was provided in the transcript.

M193 and M194 were already real-CMS target proven. M196
index record planner and M197 full SHA-1 verification core
are merged and host tested; their actual CMS runs were
**not yet reported**. M188's native authenticated full
closure remains **205.04s CPU / 208.27s elapsed**.

## New isolated source and security model

`src/GITBX8.ASSEMBLE` is a standalone, fixed-column
assembler module distinct from M193–M195 and the proven
M188 reader.

1. Uses exactly eleven absolute extended CMS FSREAD calls
   on protected `M173NET STAGE G1`, RECNO **3864789**
   through **3864799**. Each record goes to its own
   64-byte slot in a 704-byte memory area. Each returned
   variable-record length is retained separately.
2. Checks the known `OBJ 7736 ` header prefix; all nine
   intermediate body records must be exactly 64 EBCDIC
   hexadecimal characters, and the tenth must be an
   even nonempty 2–64 hex-character record. Decoded
   object body length must be 289–320 bytes.
3. Calls **FSCLOSE on the protected stage** before
   any output file is opened. A malformed record never
   causes scratch creation. Nothing writes to G.
4. Only after complete staged input validation, invokes
   `FSOPEN FSCB=OUTFSCB,OPENTYP=NEW,FORM=E`
   for **GITVRAW DATA A1**. IBM documents that NEW
   **fails if the file already exists**, unlike REPLACE.
   Then FSWRITE publishes exactly eleven variable records
   using each *actual returned length* and FSCLOSE.
5. Returns native RC0 only on a completely closed
   scratch file; any error is RC8. A failed or partial
   scratch may remain on A and must be treated as
   untrusted. It is **never automatically erased**.

IBM FSOPEN semantics: [opening CMS files](https://www.ibm.com/docs/en/zvm/7.3.0?topic=macros-opening-cms-files),
[FSOPEN macro](https://www.ibm.com/docs/en/zvm/7.2.0?topic=instructions-fsopen).
The NEW (not REPLACE) exclusivity is a second line of
defense beyond the wrapper's existence preflight.
No other file is created or overwritten.

`src/GITB8.EXEC` requires:

```text
GITB8 G LAST expected-40-hex-oid
```

The expected full 40-hex Git OID MUST come **verbatim**
from the successful independent `GITRP6 G 7736 10`
CMS index plan. Do not guess it and do not use an
OID from unrelated objects or GitHub commit HEAD.

The wrapper guards the 4K G disk, protected index/stage
presence, native `GITBX8 MODULE A`, verified native
`GITVO7M MODULE A`, and `GITVO7 EXEC A`.
It refuses a pre-existing `GITVRAW DATA A`, aborts
on uncertain scratch `STATE` RC, and refuses
caller-owned OBJIN FILEDEF. It invokes the assembler
directly (no buffered PIPE/STEM over native console
output), checks the scratch exists, then calls
`GITVO7 7736 <expected-oid>`. That M197 wrapper
binds read-only disposable `dd:OBJIN`, verifies full
canonical Git SHA-1, and clears its owned FILEDEF.

**M198's wrapper PASS is contingent upon M197's full
OID calculation succeeding**. The assembler alone
does not assert authentication. All original stage
and index files remain untouched.

`tests/test-m198-fsread-scratch.py` host tests check
fixed 72-column source, eight-character symbols,
no FSWRITE/FSERASE on protected G, NEW-only A output,
stage close before output creation, exact record
buffer sizes, EBCDIC hex checks, refusal of existing
scratch and FILEDEF collisions. A synthetic 289–320
byte Git object passes the same ten-record geometry,
then an independently compiled strict C89 M197 SHA
verifier; data and malformed hex/short/odd/truncated
cases are tested. Linux cannot assemble IBM CMS
macros or establish real FSWRITE runtime behavior.
**M198 is HOST-ONLY until a separate z/VM test.**

## Exact operator gates

**Prerequisite:** the actual M196 CMS output for
`GITRP6 G 7736 10` must PASS and report HEADER
3864789, BODY 3864790, LAST 3864799, COUNT 10,
plus the real indexed type, size, and OID. The
M197 C module must also compile cleanly on CMS.
A failure in either prerequisite stops this trial.

After M198 CI is green and merged to main, Mac
`ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITBX8.ASSEMBLE GITB8.EXEC
```

No G data transfer or previous module replacement.
CMS MAINT cheap preflight:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
FILEDEF
STATE GITVRAW DATA A
STATE GITBX8 ASSEMBLE A
STATE GITVO7M MODULE A
```

`STATE GITVRAW DATA A` is expected to report
file **not found** (normally RC28). If it exists,
**stop**: do not overwrite or erase an unexpected
scratch file. No automatic cleanup is performed.

Build ONLY the new isolated module:

```text
GLOBAL MACLIB OSMACRO DMSGPI PDPCLIB
ASSEMBLE GITBX8
```

Only on `NO STATEMENTS FLAGGED IN THIS ASSEMBLY`:

```text
GLOBAL TXTLIB PDPCLIB
LOAD GITBX8 (NOAUTO NOMAP
GENMOD GITBX8
STATE GITBX8 MODULE A
```

Run the full SHA-integrated probe ONLY using the
actual expected OID from the preceding M196 output:

```text
GITB8 G LAST <actual-40-hex-oid-from-M196>
FILEDEF
LISTFILE GITVRAW DATA A (ALLOC
```

The angle-bracket placeholder is **not** a runnable
CMS OID: substitute the exact 40-digit hex value.

Required native markers and wrapper sequence:

```text
M198 SOURCE FSREAD TO NEW SCRATCH BEGIN
M198 READ ONLY STAGE LAST OBJECT BEGIN
M198 LAST 11 STAGE RECORDS VERIFIED
M198 NEW DISPOSABLE OBJECT WRITE PASS
M198 VERIFIED SHA1 CHECK BEGIN
M197 DISPOSABLE FULL OBJECT VERIFICATION BEGIN
M197 VERIFIED OID <exact-index-OID>
M197 READ ONLY FULL OBJECT SHA1 PASS
M197 DISPOSABLE FULL OBJECT GATE PASS
M198 NATIVE FSREAD FULL OID GATE PASS G LAST
```

Capture native and wrapper RC, Ready CPU/elapsed,
resulting scratch metadata, and final `QUERY FILEDEF`.
On any failure, **leave the scratch file untouched**
for diagnosis; do not rerun when it may exist.

## Non-goals and protected state

This first bridge remains deliberately sealed to
the **final** indexed object (7736); it is not yet
an arbitrary-object FSREAD adapter or full tree walk.
The user-facing selector and expected OID are bound
to independent M196 evidence, and the complete
scratch payload is authenticated by M197.

Do not change the original G stage/index, reimport,
reindex, erase/format GIT600, replace M185/M188/
M193/M194/M195 or write-link the physically overlapping
PMAINT 0141 fullpack. Never run the unverified
M190 272-seek experiment to compare performance.


---

## Original: docs/M199_BOUNDED_FSREAD.md

# M199 — Parameterized, bounded CMS FSREAD with Git SHA-1

## October 12, 2026 — Second M199 object: REAL CMS SHA PASS

This is an additional, distinct object from the original
291-byte tree. The user confirmed:

```text
GITB9 G 3868 1969357 36 8AF5E45B1B905F781D0BFB8A547049494B8D07A2
M199 BOUNDED ORIGINAL STAGE READ PASS
M199 NEW A SCRATCH TRANSFER PASS
M197 OBJECT 3868 TYPE 3 SIZE 1148 BODY RECORDS 36
M197 VERIFIED OID 8AF5E45B1B905F781D0BFB8A547049494B8D07A2
M197 READ ONLY FULL OBJECT SHA1 PASS
M199 PARAMETERIZED FULL OID PASS G 3868
Ready; T=0.02/0.03 11:47:45
FILEDEF
DMSFLD324I No user defined FILEDEFs in effect
LISTFILE GITR199 DATA A (ALLOC
GITR199 DATA A1 V 64 37 1
```

**M199 now has real-CMS authenticated read evidence for
both a 291-byte tree (object 7736) and a 1,148-byte
blob (object 3868).** The latter used 37 scratch records,
one block, and 0.03 seconds elapsed for this one object.
No active user-defined FILEDEFs were present after
the test. The user supplied this transcript twice;
it is one observed execution, not two. The successful
GITR199 DATA A1 scratch is disposable, eligible for
exact-name cleanup with GITCLN SCRATCH after checkpoint.
The stage and index remain read-only.

---

## Baseline established October 12, 2026

Real z/VM 6.3 M198 passed after native GITBX8 assembler and
GITVO7M C-module builds. It read object 7736 (type 2 tree,
291 bytes) through 11 absolute native FSREAD records,
created disposable GITVRAW DATA A1, and independently
verified SHA-1 `9069E154EB145C25D8E1A8D31F72252C53E6684A`
using M197. The combined elapsed time was 0.03 seconds.
The scratch was listed as 11 variable records, LRECL 64,
one disk block. No post-run QUERY FILEDEF was provided.

## M199 implementation and safety

New GITBX9.ASSEMBLE and GITB9.EXEC accept a user-supplied,
previously M196-validated tuple of physical object number,
starting one-based CMS record, 1..64 body records and
expected 40-character OID. The native module receives
starting record and count as two EBCDIC decimal STACK
records and validates digit range and arithmetic limits.

M199 validates the OBJ header prefix, complete even-length
body hex records, aggregate size 1..2048 decoded bytes,
and closes protected G-stage input before using FSOPEN
OPENTYP=NEW to create a new disposable GITR199 DATA A1.
It refuses existing scratch; never writes the original G
stage or index; never overwrites or removes any existing
file. On failure, preserve any incomplete scratch for
inspection and do not rerun automatically.

The REXX wrapper verifies the scratch using target-proven
GITVO7M full canonical Git SHA1 and the supplied OID. The
caller must use the actual M196 index-derived record span
and expected OID. Automated index-to-adapter binding is a
future milestone. Zero-byte body objects are not yet
supported by this new transfer gate.

Host tests include assembler continuation-column and label
checks, bounded-input and hex validation, separate
scratch ownership and read-only policies, plus strict C89
full SHA parity over synthetic blobs, trees and commits.
The new M199 module is HOST-ONLY until actual CMS assembly
and execution pass.

## Target operator runbook after green CI and merge

Mac, from ibm-sandbox/src:

```sh
git pull
./cms-upload.sh GITBX9.ASSEMBLE GITB9.EXEC
```

CMS MAINT preflight:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
FILEDEF
STATE GITVRAW DATA A
STATE GITR199 DATA A
STATE GITVO7M MODULE A
```

GITVRAW DATA A is expected to exist (verified M198 scratch).
GITR199 DATA A must be ABSENT. Do not replace either file.

Only if preflight is correct:

```text
GLOBAL MACLIB OSMACRO DMSGPI PDPCLIB
ASSEMBLE GITBX9
```

Only on NO STATEMENTS FLAGGED:

```text
GLOBAL TXTLIB PDPCLIB
LOAD GITBX9 (NOAUTO NOMAP
GENMOD GITBX9
STATE GITBX9 MODULE A
GITB9 G 7736 3864789 10 9069E154EB145C25D8E1A8D31F72252C53E6684A
FILEDEF
LISTFILE GITR199 DATA A (ALLOC
```

A complete PASS must include:
```text
M199 BOUNDED ORIGINAL STAGE READ PASS
M199 NEW A SCRATCH TRANSFER PASS
M197 OBJECT 7736 TYPE 2 SIZE 291 BODY RECORDS 10
M197 VERIFIED OID 9069E154EB145C25D8E1A8D31F72252C53E6684A
M197 READ ONLY FULL OBJECT SHA1 PASS
M199 PARAMETERIZED FULL OID PASS G 7736
```

M199 first tries only the already-proven object 7736, using a
separate new scratch. Future runs for distinct objects
must use new scratch names and verify their own M196 plans.
M188's authenticated full-tree baseline remains
205.04 CPU / 208.27 elapsed seconds, without replacement.


---

## Original: docs/M200_CLEANUP.md

# M200 — CMS FILEDEF listing and safe test artifact cleanup

## Real CMS M199 result — October 12, 2026

The user built `GITBX9` with no assembler errors, loaded
and GENMOD'd it, then ran:

```text
GITB9 G 7736 3864789 10 9069E154EB145C25D8E1A8D31F72252C53E6684A
M199 DIRECT NATIVE RECORD-BOUNDED READ BEGIN
M199 PARAMETERIZED FSREAD SOURCE BEGIN
M199 BOUNDED ORIGINAL STAGE READ PASS
M199 NEW A SCRATCH TRANSFER PASS
M199 FULL CANONICAL SHA1 VERIFY BEGIN
M197 OBJECT 7736 TYPE 2 SIZE 291 BODY RECORDS 10
M197 VERIFIED OID 9069E154EB145C25D8E1A8D31F72252C53E6684A
M197 READ ONLY FULL OBJECT SHA1 PASS
M199 PARAMETERIZED FULL OID PASS G 7736
Ready; T=0.01/0.02 11:21:19
LISTFILE GITR199 DATA A (ALLOC
GITR199 DATA A1 V 64 11 1
Ready; T=0.01/0.01 11:21:29
```

**M199 is real-CMS-target-proven** for the indexed tree
object 7736 using a caller-supplied record coordinate
and independent canonical Git SHA1. It remains to select
and authenticate a second object and automate tuple
acquisition. The new `GITR199 DATA A1` is a successful
disposable scratch, not a protected repository artifact.
The M198 scratch `GITVRAW DATA A1` is also now superseded.
The original G stage/index remain untouched.

## Correct way to list CMS FILEDEFs

The user noticed `QUERY FILEDEF` on their CMS session
was interpreted as a CP query about userid `FILEDEF`,
not the desired list of CMS ddnames.

IBM z/VM CMS supports entering simply:

```text
FILEDEF
```

with no operands to list all current definitions.
The normal no-definitions result is
`DMSFLD324I No user defined FILEDEFs in effect`.
Clear an owned definition by its exact ddname, for example:

```text
FILEDEF OBJIN CLEAR
```

Never use `FILEDEF * CLEAR` as an automatic cleanup
shortcut because it could clear unrelated active
definitions. The M196/M197/M198/M199 wrappers have been
updated to use `PIPE CMS FILEDEF | STEM f.` rather
than `PIPE CMS QUERY FILEDEF | STEM f.`. The
source change preserves their individual collision
checks and FILEDEF cleanup.

IBM references: CMS FILEDEF command, z/VM 7.3 documentation;
CMS ERASE command reference, z/VM 7.2 documentation.

## New GITCLN EXEC — strict A1-only whitelist

New `src/GITCLN.EXEC`, two explicit choices:

```text
GITCLN SCRATCH
GITCLN RETIRED
```

`SCRATCH` deletes **only** these exact, successful,
now-unneeded A1 files:

- `GITVRAW DATA A1` (M198)
- `GITR199 DATA A1` (M199)

`RETIRED` deletes only generated build outputs and
obsolete one-off probe executables of M193, M194, M195
and M198: `GITFSRD`, `GITFRB`, `GITFL10`,
`GITBX8` MODULE/TEXT/LISTING and their wrappers
`GITFSP`, `GITFRP`, `GITFLP`, `GITB8` EXEC.
Missing individual files are skipped.

The following are **never erased** by this helper:
original G stage and index, GIT600, any G file;
the actual `.ASSEMBLE` source on A; `GITRP6M`,
`GITVO7M`, `GITBX9` or active executables;
the GitHub repository or its checkpoint records.

For each exact filename/filetype/filemode A1 it:
checks `STATE`, refuses unknown RC; issues an exact
`ERASE fn ft A1` only if it exists; requires a
subsequent `STATE` RC28 to verify deletion.
No wildcard erase, rename, FORMAT, disk reaccess,
or automatically deleted evidence after an error.

It also requires a successful `QUERY DISK A` and
checks the no-operand CMS `FILEDEF` output before
deleting. It refuses to run while any user-defined
DISK FILEDEF is present, to avoid erasing a
potentially open or referenced scratch file.
If any check fails, the helper stops with RC8.
No operations are performed in the background.

**The helper itself is host-tested only until an
actual CMS run verifies its REXX and FILEDEF behavior.**
No remote CMS deletion was executed from GitHub.

## Safe operator sequence after CI and merge

Mac (from `ibm-sandbox/src`):

```sh
git pull
./cms-upload.sh GITCLN.EXEC GITRP6.EXEC GITB8.EXEC GITB9.EXEC GITVO7.EXEC
```

CMS MAINT inspect before cleanup:

```text
FILEDEF
LISTFILE GITVRAW DATA A (ALLOC
LISTFILE GITR199 DATA A (ALLOC
```

Expect these two known disposable files to be present,
11 variable records each. Any unexpected FILEDEF binding
should be investigated and cleared by its own owner
before proceeding.

Then one exact-mode cleanup at a time:

```text
GITCLN SCRATCH
STATE GITVRAW DATA A
STATE GITR199 DATA A
FILEDEF
```

The two STATEs should say file not found (RC28).
If `SCRATCH` failed, stop, preserve console output.

After scratch cleanup is confirmed, optionally
remove obsolete test executables and generated text
and listing files:

```text
GITCLN RETIRED
FILEDEF
```

The active M196/M197/M199 modules remain available.
Original `M173NET STAGE G` and `M174NET INDEX G`
are NEVER erased. In particular, don't use wildcard
`ERASE`, ACCESS ERASE, FORMAT, or drive G write-link.

## Next Git object validation after cleanup

M199's one-object record selection is now real CMS
target-proven, but it is still manually passed a tuple
from M196. Select a **second independent object** by
asking the index planner first, with an upper bound
of 64 body records:

```text
GITRP6 G 3868 64
FILEDEF
```

Do not guess the new record span, size, type or OID:
use the actual subsequent M196 output. If object 3868
exceeds the 64-record bound, plan another candidate.
M199's wrapper requires 1..64 nonempty body records
and 1..2048 decoded bytes; an empty object is not yet
supported by its native assembler.
After a successful second-object M196 plan and a
confirmed-absent `GITR199 DATA A`, invoke M199
with that exact new tuple. As with the first run,
check full M197 canonical SHA1 and clean scratch
only AFTER a successful authenticated PASS.

M188's authenticated 280-object closure remains the
read-only comparison baseline at 205.04 CPU seconds
and 208.27 elapsed seconds. M200 neither replaces
that reader nor claims a complete-tree speedup.

