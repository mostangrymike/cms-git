# Native CMS Git foundational architecture archive

## Archived original: docs/NATIVE_REF.md

# M13 native backward REF_DELTA gate

The captured 340,027-byte real GitHub PACK contains 1,808 objects
and 1,117 OFS_DELTA entries, but **no REF_DELTA entries**.
Its existing CMS-proven staging/index/seek modes are retained.
The separate native REF_DELTA implementation below is
host-regression-proven; the first CMS compilation succeeded but
its REF lookup exposed a shared EBCDIC Git-header defect, corrected
in current source but not yet retested on CMS.

## Implemented scope

GITCWALK now resolves a REF_DELTA base by its 20-byte Git object ID
when a fully reconstructed matching object **precedes** the REF in
the same PACK. It inherits the base's final object type, applies
the bounded delta to the base's reconstructed bytes, and computes
the canonical OID of the resulting object. Chained backward REF
bases are supported. OFSAPPLY can compute prior base OIDs on demand
without enabling object-ID output for its whole run.

An absent, forward-only, or external base fails closed with
`UNRESOLVED REF BASE OBJ n`. Do not claim complete REF_DELTA
interoperability until forward/external base lookup exists and has
its own regression and target proof. The new code changes no
previous target-proven ordinary/OFS behavior for a PACK that
contains zero REF_DELTA objects.

## Host-generated fixtures and independent Git verification

`tests/make-native-ref-pack.py` writes CMS ASCII hex-record fixtures
(each record 64 characters or less), plus a host-only binary copy:

- `REFPACK PACK`: a three-object Git PACK v2. Object #1 is
  blob `abc`, #2 is a REF_DELTA referencing #1 and making
  blob `abcd`, and #3 is a chained REF_DELTA referencing #2
  and making blob `abcde`.
- `REFBAD PACK`: same structure but an unknown base OID for
  the second object; valid recomputed PACK SHA-1.
- `REFFWD PACK`: the base exists later in the PACK but is not
  yet reconstructed; must reject rather than use uninitialized data.
- `REFSIZE PACK`: valid PACK SHA-1 but a REF delta declares the
  wrong base length; must fail bounded delta application.
- `REFSHA PACK`: valid objects but a corrupted trailer SHA-1;
  must fail before reconstructing any object.

The host harness substitutes zlib only for the existing CMS
GITCAPI/GITINFA inflater, so all native C PACK header parsing,
REF lookup, delta reconstruction, and native SHA-1 logic is
exercised. It compares each resulting blob OID against
`git hash-object`. The same generated binary `REFPACK`
is independently ingested by Git's `git index-pack --stdin`,
and `git cat-file` must reconstruct all three blobs correctly.
Thus the positive fixture is Git-readable rather than merely
self-consistent with our parser.

`GITCWALK RTEST` also exercises a small two-step REF chain,
missing/forward base lookup rejection, malformed delta length,
and the final independently checked OID entirely in memory.
`RPACK` accepts a bounded synthetic PACK of fewer than
340,027 bytes and enables REF reconstruction plus OID output.
`RAPPLY` tests the same PACK with OIDs generated on demand for
base resolution instead of the normal object-OID output path.
Neither writes to GITSTAGE or changes the saved real PACK.

Host tests including negative fixtures and independent Git
PACK acceptance passed in GitHub Actions run
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36274025088 .

## Single isolated CMS target gate

This is the first actual target compilation of the updated
REF-capable GITCWALK source. No live GitHub request, modification
to `GITPBUF PACK A`, or restaging is required.

On the Mac, in `/Users/mikewommack/ibm-sandbox/src`:

```sh
git pull
python3 ../tests/make-native-ref-pack.py .
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/GITCWALK.C
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/REFPACK.PACK
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/REFBAD.PACK
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/REFFWD.PACK
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/REFSIZE.PACK
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/REFSHA.PACK
```

On CMS, compile with the intended F-disk compiler wrapper, if
installed; the prior `GITCLNK GITCWALK` remains a fallback.
Define each PACKIN only after compilation:

```text
CMSCLNK GITCWALK
GITCWALK RTEST
FILEDEF PACKIN CLEAR
FILEDEF PACKIN DISK REFPACK PACK A
GITCWALK RPACK
GITCWALK RAPPLY
FILEDEF PACKIN CLEAR
FILEDEF PACKIN DISK REFBAD PACK A
GITCWALK RPACK
FILEDEF PACKIN CLEAR
FILEDEF PACKIN DISK REFFWD PACK A
GITCWALK RPACK
FILEDEF PACKIN CLEAR
FILEDEF PACKIN DISK REFSIZE PACK A
GITCWALK RPACK
FILEDEF PACKIN CLEAR
FILEDEF PACKIN DISK REFSHA PACK A
GITCWALK RPACK
```

The expected positive case reports:

```text
PASS 3 OBJECTS NEXT OFFSET 94
OFS DELTAS APPLIED 0
REF DELTAS APPLIED 2
OID OBJ 1 TYPE 3 SIZE 3 F2BA8F84AB5C1BCE84A7B441CB1959CFC7093B7F
OID OBJ 2 TYPE 3 SIZE 4 85DF50785D62D3B05AB03D9CBF7E4A0B49449730
OID OBJ 3 TYPE 3 SIZE 5 6A8165460570531A1247BD99A73B53A5A6E500D5
```

The OID lines occur earlier in the actual program output,
before the PASS/counter lines. `RTEST` must print
`REF BACKWARD CHAIN AND NEGATIVE TESTS PASSED`.
`RAPPLY` must print `REF DELTAS APPLIED 2` without needing
the normal object OID output. All four negative test invocations
should return CMS RC 8 with, respectively,
`UNRESOLVED REF BASE OBJ 2`,
`UNRESOLVED REF BASE OBJ 1`,
`FAIL NATIVE DELTA APPLY`, and
`FAIL NATIVE PACK SHA1`.
Keep each preceding negative file definition isolated;
do not accept any unexpected RC 0.

The currently stored 1,808-object PACK remains untouched.
After this test, the next distinct functional milestone is
persisted/external and forward REF_DELTA base resolution with
restart/recovery tests; the real captured PACK cannot exercise
those cases. Keep GitHub issue #2 open.

## September 26 CMS failure and confirmed correction

The user compiled the original REF implementation successfully
with `CMSCLNK GITCWALK` (NAPI, no assembler flags), but the first
real target REF fixture failed at OBJ 2. The raw PACK was valid:
SHA-1 `9CD9B4CCFA5D5371C608230D3157F4766248355F`, 114 bytes,
3 objects. The ordinary first blob `abc` was incorrectly reported
as `5492DC378EC7097F3437B18BE17F4C58D0923A03` instead of
Git's `F2BA8F84AB5C1BCE84A7B441CB1959CFC7093B7F`.
RPACK and RAPPLY each printed `UNRESOLVED REF BASE OBJ 2` (RC 8).
The original RTEST passed its internal chain, but its resulting
`0414AADE456A43A390C3A0E689DD2CDE0439DAA7` was also not the
correct Git ABCDE OID.

This is the confirmed EBCDIC canonical object-header bug, not an
inflater or PACK SHA defect. Corrected GitHub source now builds the
hash preimage using explicit ASCII bytes and checks known Git test
vectors directly on CMS. GITCIDX was corrected too; earlier staged
and indexed OIDs need rebuilding separately, not promotion. Host
regressions passed; the corrected implementation is **awaiting CMS
validation**. For current minimal Mac transfer, exact CMS retest,
and safe separately named staging/index rebuild, use
[Canonical Git OIDs on CMS](CANONICAL_OIDS.md). The older RPACK
steps above are historical and do not by themselves establish a
successful target result. No new live GitHub capture is needed.

## Follow-on host milestones: external and forward REF

The original backward same-PACK chained REF implementation passed
actual CMS RPACK and RAPPLY tests with canonical Git OIDs. The
subsequent full 1,808-object GITFIX stage plus both canonical IDX2
and SIDX2 indexes passed complete target readback, full SFAST and
PAIR audit (20.99 and 21.38 seconds elapsed respectively).

Additional **host-verified, not yet CMS-verified** modes in the
latest GITCWALK source now cover deferred forward same-PACK REF
chains and external bases provided by bounded, independently
SHA-checked CMS staging records. Git independently indexed and
reconstructed the forward-chain test PACK; corrupted, absent,
duplicated and mismatched external stages are rejected by host tests.
The full consolidated CMS fixture transfer and safe validation gate
is in [External and forward REF resolution](REF_RESOLUTION.md).
The validated GITFIX generation is read-only throughout these tests.

---

## Archived original: docs/NATIVE_STAGE.md

# Native CMS object staging: GITCWALK

## Target-proven prerequisites and the initial failure

The captured GitHub PACK is 340,027 bytes, version 2, containing
1,808 objects and 1,117 OFS_DELTA instructions. Its trailer SHA-1 is
`8C92E274ECA84B797F8925A6082915DD6CCDE196`. Native optimized
SHA-1 matched the original reference for **all 1,808 reconstructed
objects** under `GITCWALK OPTCHECK`. Optimized-only `OPTSHA` ran in
19.29 s CPU / 19.42 s elapsed on one CMS run.

The initial `GITCWALK STAGE` test ran the complete verified PACK
processing path but failed while opening the output file:

```text
PASS 1808 OBJECTS NEXT OFFSET 340007
OFS BASE POSITIONS RESOLVED 1117
OFS DELTAS APPLIED 1117
OBJECT OIDS COMPUTED 1808
DMSSOP036E Open error code 4 on OBJOUT
STAGE WRITE FAIL
Ready(00008); T=19.30/19.51
```

No `GITSTAGE DATA A` file was created. IBM FILEDEF documentation
identifies error code 4 on a new output file as missing both LRECL
and BLKSIZE. The former `FILEDEF OBJOUT DISK GITSTAGE DATA A`
omitted these values. [IBM FILEDEF reference](
https://www.ibm.com/docs/en/zvm/7.3.0?topic=commands-filedef).

## Current source and staging format

Commits `fa7052d`, `0806eb0`, and `04be7ee` add buffered
32-byte hex output records, independent readback validation, a
non-destructive negative gate, and progress/error diagnostics.
The updated code is now compiled and **CMS target-validated** for the
captured 1,808-object PACK.

`STAGE` computes the optimized OID for every reconstructed object
and emits CMS **variable-length text records** to FILEDEF `OBJOUT`:

- One header per object: `OBJ <index> <type> <length> <40-hex-OID>`.
- Uppercase body hex in records of at most 32 decoded bytes
  (64 characters) each. Empty object bodies use one blank record.
- The largest header and hex record both fit within LRECL 80.
- 1,808 headers and about 7.9 million body-hex characters are expected
  for the captured PACK. Ensure the A disk has enough free space.

This is a **temporary CMS-native staging file**. It is not yet
a durable content-addressable CMS object database or Git loose-object
storage. Existing `ALL`, `BADSHA`, `OFSAPPLY`, `OID`, `FASTOID`,
`FASTONLY`, `OPTSHA`, and `OPTCHECK` remain available.

`VERIFY` reads only `OBJOUT` (no live network and no PACKIN), strictly
checks record order, type, bounds and all hex bytes, reconstructs each
staged body, and independently recomputes and compares its canonical
Git SHA-1. Successful output: `STAGE VERIFIED OBJECTS 1808`.
`BADSTG` changes the first object **in memory only**, without altering
the file, and must print `PASS BADSTG: ALTERED BODY REJECTED`.

## Completed original CMS staging test

On the Mac, from the repository's `src` directory:

```sh
git pull
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/GITCWALK.C
```

On CMS, compile first, **then** issue FILEDEFs (language processors
can clear non-permanent FILEDEFs):

```text
GITCLNK GITCWALK
FILEDEF PACKIN DISK GITPBUF PACK A
FILEDEF OBJOUT CLEAR
FILEDEF OBJOUT DISK GITSTAGE DATA A (RECFM V LRECL 80
GITCWALK STAGE
LISTFILE GITSTAGE DATA A
GITCWALK VERIFY
GITCWALK BADSTG
```

Explicit output LRECL 80 corrected the open error. All three
commands passed on CMS with the captured real PACK. If `OBJOUT` still fails, capture the
FILEDEF response, `QUERY FILEDEF`, and complete CMS error code.
If writing stops partway through, `STAGE WRITE STOP OBJ n` identifies
the object; treat any partial file as invalid.

## Later work, not yet claimed

The isolated `GITCIDX` prototype is now committed, host-tested and
documented in [Native index](NATIVE_INDEX.md). It creates a sorted OID
index, detects incomplete index writes, and rehashes selected staged
objects during `GET`. Its original CHECK and first/last GET are now CMS target-proven;
AUDIT and experimental direct-seek modes still need CMS validation.
Remaining work: safe committed storage generations,
restart/readback validation and native REF_DELTA support.
The captured PACK uses OFS_DELTA, so the current 1,808-object test
does not exercise REF. Issue #2 remains open.

## Host-side independent regression gate (2026-09-26)

The host-only test `tests/native_stage_host.c` and its shell runner
`tests/run-native-stage-host.sh` compile `GITCWALK.C` as C89, stage
1,808 synthetic objects, read back and rehash every record, pass a
non-destructive in-memory corruption gate, demonstrate detection of an
actual corrupted disk record, restore the record, and pass readback
again. The runner independently checks Git's native `git hash-object`
result for `blob 3\\0abc`: `f2ba8f84ab5c1bce84a7b441cb1959cfc7093b7f`.

GitHub Actions workflow `.github/workflows/native-stage.yml` run
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36271371785
completed successfully. Its job logs show `STAGE VERIFIED OBJECTS 1808`,
`PASS BADSTG: ALTERED BODY REJECTED`, detection of disk tamper, and
`HOST STAGING AND GIT OID TEST PASSED`. Those initial results were HOST tests with synthetic data; the
subsequent real-PACK CMS proof appears in the target result below.

The original staging gate is now complete on CMS. The next new
CMS-only gate is AUDIT and the isolated direct-seek experiment,
documented in [Native index](NATIVE_INDEX.md).

## Combined CMS gate and host-proven index extension

The complete current test procedure is in
[`docs/NATIVE_INDEX.md`](NATIVE_INDEX.md). Host CI also proves
bounded sorted index construction, OID lookup, independently hashed
`GET`, malformed staged-body rejection, and incomplete index trailer
rejection. All four canonical Git type hashes have been cross-checked
against Git using both empty and nonempty synthetic bodies. Latest
expanded run: https://github.com/mostangrymike/ibm-sandbox/actions/runs/36271873734 .
Those host tests preceded the subsequent CMS proof of variable-record
output, full readback and 1,808 unique indexed OIDs.

## Target result: CMS staging and full readback

On September 26, 2026, GITCLNK GITCWALK built cleanly. With
RECFM V and LRECL 80, STAGE wrote all 1,808 reconstructed objects,
including 1,117 OFS_DELTA results, in 24.89 s CPU / 25.32 s elapsed.
Independent disk readback VERIFY recomputed all 1,808 OIDs and
completed in 22.64 / 22.84 s. BADSTG rejected deliberately altered
first-object content without writing it to disk. The full V1 index
passed GITCIDX CHECK (1,808 unique OIDs), and both first and last
GET calls returned correct metadata and independently verified OIDs.
Staging and indexing are thus target-proven for this captured PACK;
they are not a committed generation/recovery mechanism or native
REF_DELTA resolution. New AUDIT and experimental direct-seek index
tests are documented in [Native index](NATIVE_INDEX.md).

## Critical correctness revision: EBCDIC canonical hash headers

The earlier CMS STAGE/VERIFY/BADSTG run reconstructed and consistently
hashed all 1,808 objects, and PACK checksum verification was valid.
However, both the original native SHA implementations formatted Git
object headers using CMS-native EBCDIC text. Their agreement did
not prove correct Git object IDs. Existing GITSTAGE DATA A and
GITINDEX/GITSEEK files are now **legacy and unsuitable for real Git
interoperability**, though their captured object body bytes remain
useful. Corrected GITCWALK now uses explicit ASCII canonical headers.
Create the new stage as `GITFIX STAGE A` instead of overwriting the
legacy file, then independently rehash every object and build new
IDX2/SIDX2 indexes. See [Canonical Git OIDs](CANONICAL_OIDS.md)
for the exact required validation and migration commands.

---

## Archived original: docs/NATIVE_INDEX.md

# Native CMS OID index for staged PACK objects

This experimental `GITCIDX.C` program builds a bounded, sorted
content-addressable index from the separate `GITCWALK STAGE` spool.
It does **not** store Git loose objects. BUILD/CHECK/GET are now
CMS-compiled and the resulting index passed full target CHECK and
first/last GET. The BUILD invocation/timing itself was not included
in the posted terminal output. It is independent of the native PACK inflater and does
not need a live network connection or another GitHub POST.

## Input and guarantees

The source `GITSTAGE DATA A` consists of `OBJ` header records and
uppercase hexadecimal body records as described in
[Native staging](NATIVE_STAGE.md). Run `GITCWALK VERIFY` **before**
building the index; `GITCIDX BUILD` checks the complete staged record
structure, every hex character, object sequence and bounds, but does
not independently recompute the Git SHA-1. The `VERIFY` pass does.

`BUILD` collects exactly 1,808 bounded object descriptors, sorts by
the 20-byte binary OID, collapses duplicate OIDs only when their type
and length agree, and writes `IDX1`, `OID`, and final `END` records
to `IDXOUT`. The final `END 1808 <unique>` trailer is a completeness
marker: interrupted, truncated, unsorted, duplicated, or malformed
index files cannot pass `GITCIDX CHECK`. Never use an index that
has not passed `CHECK`. `FIND` validates the entire index first
and performs binary search in bounded memory. `GET` additionally
opens `STGIN`, retrieves the selected body, recomputes its canonical
Git object SHA-1 independently, rejects mismatches, and reports the
first 16 bytes in hex without displaying unbounded object content.

The source and output records fit CMS variable record length 80.
BUILD, CHECK and FIND retain only 1,808 bounded descriptors in
memory. GET additionally holds one selected decoded body (up to
65,536 bytes) and a bounded canonical-hash scratch buffer.

## Completed V1 CMS validation (historical)

The September 26, 2026 target session compiled the original
GITCWALK and GITCIDX modules, defined the variable-length staging
files with LRECL 80, staged and independently verified all 1,808
reconstructed objects, and rejected deliberately corrupted data.
The resulting index passed CHECK with exactly 1,808 unique OIDs;
GET independently rehashed the first and last real objects. The
old compiler wrapper was GITCLNK; the canonical replacement is
now CMSCLNK, intended for the GCC F disk.

These commands do not need to be repeated for the next experiment.
For the only current target-dependent AUDIT and direct-seek test,
use the installation and test commands in the next-gate section
near the end of this document, including the new CMSCLNK EXEC.

## Host tests and remaining work

`tests/native_index_host.c` adds 1,808 synthetic descriptors,
duplicate normalization, OID lookups, independently hashed GETs,
valid-hex body tamper rejection, negative lookup, malformed staged
record detection and truncated-index-trailer rejection. The
`tests/run-native-stage-host.sh` runner compiles it under C89 and
independently checks native Git SHA-1 across all four Git object types
and both empty and nonempty bodies. GitHub Actions run
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36271873734
passed the full GET and tamper tests; run
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36271801328
passed the all-types Git cross-check. These are synthetic host tests; the real-PACK CMS target results
are recorded separately below.

This is only the **index and verified retrieval prototype**. Durable content-addressable object
storage still requires safe committed generations or equivalent
recovery, end-to-end restart proof, faster indexed retrieval, and native
REF_DELTA resolution. Indexing the verified spool does not complete
issue #2.

## Target-proven checkpoint: September 26, 2026

CMS compiled GITCWALK and GITCIDX cleanly using GITCLNK. The
explicit output FILEDEF succeeded. GITCWALK STAGE completed
all 1,808 objects and 1,117 OFS_DELTA instructions in
24.89/25.32 s CPU/elapsed. GITCWALK VERIFY independently
read back and hashed all 1,808 staged objects in 22.64/22.84 s;
BADSTG rejected the deliberately altered in-memory first body.
GITCIDX CHECK verified 1,808 unique OIDs in 0.13/0.14 s.
GITCIDX GET returned the known first and last object metadata
and content-hash-checked those bodies on target:

- OBJ 1: commit, 270 bytes, OID
  5A81BAF86E7DC7B72377087A8F160CAF8B889B74;
  GET elapsed 0.14 s.
- OBJ 1808: tree, 5,224 bytes, OID
  BA9F4D66B41352F0D0266090D14AD52F37318FCB;
  GET elapsed 7.59 s.

The terminal transcript does not show the BUILD command/result or
untruncated GET prefixes. CHECK conclusively validates an index
file exists, but BUILD's own timing is not measured in this log.

The time difference is consistent with GET's sequential scan of
all preceding stage records. Next isolated experiment will store
text-stream position cookies returned by ftell during BUILD and
use fseek for direct retrieval, but CMS variable-record seek
semantics are **not yet tested**. Preserve proven CHECK and GET
unchanged; any new seek behavior must be independently validated
on actual target before adoption.

## M13 next gate: complete AUDIT and experimental direct-seek index

Commit `a838b28` adds `GITCIDX AUDIT`: it loads the proven V1
index, scans all 1,808 staged objects, recomputes every canonical
Git SHA-1, verifies type, length and earliest object ordinal, and
requires complete coverage of all unique index entries. It is a
whole-file integrity reconciliation, not just a selected-object GET.

Commit `6e6b5b3` adds a **separate experimental seek index**.
`GITCIDX SBUILD` records each staged object's `ftell` position
before reading its header, writes a separately versioned sorted
OID index with record positions to FILEDEF `FIDXOUT` and adds a
mandatory `SEND` trailer. `SCHECK` validates this index using
`FIDXIN`. `SGET` uses `fseek` with the stored position to load
and independently hash only the selected object. Original V1
BUILD/CHECK/FIND/GET are retained unchanged as fallback.

IBM's C library documentation describes `ftell` values for
record-oriented text files as encoded positions. The native CMS
GCCCMS runtime must prove that an `ftell` position saved during
SBUILD can be consumed by `fseek` after the file is reopened
in a separate process. Host success does NOT prove this on CMS.
If it fails or returns the wrong record, SGET fails closed rather
than falling back silently. The measured baseline for sequential
V1 GET on captured OBJ 1808 is 7.59 s elapsed.

New host tests exercise 1,808 synthetic objects, full AUDIT
and negative tamper gates, SBUILD and SCHECK, direct SGET on
both ends, stale-body SHA rejection, and truncated seek-index
trailer rejection. GitHub Actions run
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36272574127
completed successfully. Synthetic fixture has 8 unique objects;
real captured PACK has 1,808 unique objects on CMS.

### Completed CMS AUDIT and direct-seek validation (historical commands)

The target-proven `GITSTAGE DATA A` and `GITINDEX DATA A`
already exist. No new PACK download or restaging is necessary.

On the Mac, from `ibm-sandbox/src`, transfer the neutral
compiler EXEC and current GITCIDX C source via the proven uploader:

```sh
git pull
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/CMSCLNK.EXEC
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/GITCIDX.C
```

On CMS, check whether the existing GCC F disk is writable. If it
reports `R/W`, install the neutral EXEC there and verify the copy.

```text
QUERY DISK F
COPYFILE CMSCLNK EXEC A CMSCLNK EXEC F
STATE CMSCLNK EXEC F
```

**Only after the copy succeeds**, erase `CMSCLNK EXEC A` to force
subsequent commands to resolve from F. If F reports `R/O`, skip the
COPYFILE/ERASE steps and use the uploaded A copy temporarily; an
authorized R/W F-disk access will be required for permanent installation.

For the independent AUDIT/seek gate, build the C-only program with
`CMSCLNK GITCIDX PLAIN`, then issue FILEDEFs. The experiment uses
distinct `GITSEEK INDEX A`; it cannot overwrite the target-proven
V1 `GITINDEX DATA A`.

```text
CMSCLNK GITCIDX PLAIN
FILEDEF STGIN DISK GITSTAGE DATA A
FILEDEF IDXIN DISK GITINDEX DATA A
FILEDEF FIDXOUT DISK GITSEEK INDEX A (RECFM V LRECL 80
FILEDEF FIDXIN DISK GITSEEK INDEX A
GITCIDX AUDIT
GITCIDX SBUILD
GITCIDX SCHECK
GITCIDX SGET 5A81BAF86E7DC7B72377087A8F160CAF8B889B74
GITCIDX SGET BA9F4D66B41352F0D0266090D14AD52F37318FCB
```

Required positive markers: `AUDIT VERIFIED 1808 UNIQUE 1808`,
`SEEK INDEX WRITTEN 1808 UNIQUE 1808`, and
`SEEK INDEX VERIFIED 1808 UNIQUE 1808`. Both SGET results
must return the same validated OIDs, types and sizes as V1 GET.
The last object's elapsed time is the important performance
measurement; do not claim a speedup before observing it on CMS.

Do not clear or overwrite target-proven `GITINDEX DATA A`
during this experiment. Failure of the seek experiment leaves
V1 CHECK/GET available.

### Live F-disk result

On 2026-09-26 the user's `Q DISK` showed GCCLIB VDEV 29D accessed
as **F R/W**, with 2,055 free blocks. The neutral compiler may
therefore be copied directly from its uploaded A copy into F.
Copy and verify before erasing the temporary CMSCLNK EXEC A,
and preserve the existing old GITCLNK EXEC A for rollback until
the new CMSCLNK PLAIN build passes. The actual transfer, copy,
compile and seek-index run remain CMS-validation pending.

### Compiler EXEC rename

`GITCLNK` is the historical build utility used for the target-proven
C/assembler modules; `CMSCLNK` is now the canonical GCCCMS build
utility intended to reside on F. Its default NAPI mode retains the
legacy build sequence. The new optional PLAIN mode omits the native
inflater adapter for GITCIDX and other ordinary C programs. Host
static-source checks passed; CMS F-disk placement and PLAIN-mode
module linking still require target validation. See [Build](BUILD.md).

## Latest result: target-proven direct seek

September 26, 2026 CMS transcript:

| Mode | Result | CPU / elapsed |
|---|---|---|
| AUDIT | 1,808 staged bodies, 1,808 unique OIDs | 20.96 / 21.09 s |
| SBUILD | 1,808-unique separate seek index written | 7.13 / 7.21 s |
| SCHECK | 1,808-unique seek index verified | 0.14 / 0.15 s |
| SGET first | commit #1, 270 bytes, expected OID | 0.15 / 0.15 s |
| SGET last | tree #1808, 5,224 bytes, expected OID | 1.72 / 1.77 s |

The last-object sequential V1 GET previously took 7.59 seconds
elapsed. The single observed direct-seek run reduced this to
1.77 seconds, a 4.29x ratio and approximately 76.7% less time.
The SBUILD/SCHECK and first/last SGET success on actual CMS prove
that this GCCCMS runtime can reuse saved ftell positions after
closing and reopening the **unchanged** CMS staging file. They do
not prove index-cookie portability after stage modification or
system reboot. Retain V1 index/GET as fallback. The user's
log begins after an unlabeled command's Ready line, so actual
F-disk CMSCLNK installation is not independently confirmed by
that excerpt.

The next functional gate is native backward REF_DELTA, now
implemented and independently validated with Git on the host.
See [Native REF_DELTA](NATIVE_REF.md) for generated positive and
negative PACK fixtures, exact Mac upload/CMS execution commands,
and the limits of this first native REF milestone. No real-PACK
restaging or separate seek-index retest is needed.

## EBCDIC canonical OID correction

The first CMS REF fixture revealed that native C code formatted the Git
object header using EBCDIC, producing consistent but noncanonical
hashes. The original staging/index tests proved reconstruction and
readback consistency, not Git object-ID correctness. Original IDX1
and SIDX1 indexes must not be promoted. Current GITCIDX uses explicit
ASCII for the type, separator, decimal length and zero byte;
SELF checks the known Git blob ABC vector. New IDX2/SIDX2 formats
reject the old indexes, and SVAUDIT independently rehashes every
saved direct-seek entry. Preserve existing GITSTAGE, GITINDEX and
GITSEEK files. Regenerate into GITFIX STAGE, GITFIX INDEX and
GITFIX SEEK only after the corrected RTEST/RPACK pass on CMS.
Exact commands: docs/CANONICAL_OIDS.md. The previously measured
1.77-second SGET run proved seek mechanics, but its legacy stored
OID is not a canonical Git ID.

## New optional IDX2 and SIDX2 PAIR gate

Following the on-target Git-compatible RTEST, SELF, RPACK and RAPPLY
success on September 26, 2026, GITCIDX gained a separate PAIR mode.
It loads both newly generated IDX2 and SIDX2 formats, compares every
sorted canonical OID, object ordinal, type and size, and then invokes
SVAUDIT to independently reopen/re-hash every staged object via the
seek cookies. It detects stale or mismatched index generations,
corrupt stage bytes and invalid offsets without modifying source or
index files. The 1,808-synthetic-object host suite passed including
mismatch injection and restoration in GitHub Actions run
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36280431393 .

PAIR is additional verification, not required before the first
canonical 1,808-object GITFIX migration. After uploading/building the
latest GITCIDX.C with the known CMSCLNK GITCIDX PLAIN sequence and
binding STGIN, IDXIN and FIDXIN to the three new GITFIX files,
`GITCIDX PAIR` must report `PAIR VERIFIED UNIQUE 1808` before
regarding the two indexes as a mutually attested candidate. The
original IDX1/SIDX1 files must remain historical, not be mixed with
new IDX2/SIDX2 files.

## Canonical 1,808-object target result and faster full audit

The corrected, Git-compatible GITFIX STAGE A and GITFIX INDEX A
now passed complete target reconstruction, independent readback
and full IDX2 AUDIT. GITFIX SEEK A was built and SCHECK-verified
with 1,808 unique SIDX2 entries. Canonical first commit:
00D8D63229305230C8D37F884CE87F9E1A89468C; canonical
last tree: EB37E3F23FF4FC137D715D71A711D3B7632D75F2.
Original SVAUDIT reached progress 256 but was reported very slow,
with no completion evidence in the supplied transcript.

The implementation reopened and closed dd:STGIN separately for
every seek entry. In current GitHub code, SVAUDIT reuses one
open file instead; new GITCIDX SFAST avoids random seeks as
well, hashes every object while reading the stage once in
ordinal order and compares saved ftell cookies to positions
in the reopened stream. Optional PAIR compares all IDX2/SIDX2
descriptors and calls SFAST. Both require no new output files
and preserve the original stage/index/seek files.

Host CI passed all synthetic readback, 1,808-object and tamper
tests including stale index descriptors and one-open assertions:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36281295118 .

For exact CMS transfer, build, FILEDEFs and SFAST/PAIR tests
against the already-created canonical GITFIX datasets, use the
latest section of docs/CANONICAL_OIDS.md. No further PACK
download, restaging or rebuilding of either index is needed.

---

## Archived original: docs/NATIVE_RECOVERY_GATE.md

# M14: native dual-slot recovery against a complete GEN2 audit

## Current result and safety boundary

The 1,808-object GITFIX stage, IDX2, SIDX2 and GEN2 seal have
passed full native-CMS checks, including a complete GENCHECK
after a new CMS login. The new recovery components below were
subsequently implemented in GitHub and have **passed host tests
only**. They do not perform active-generation promotion or write
to any existing GITFIX data file.

- `src/GITSEL.C`: strict SEL1 parser, CRC32 over explicit ASCII
  bytes (independent of the host/CMS character set), and a
  `WRITE` command that creates one caller-directed selector
  record on FILEDEF SELOUT. The write does not mark a
  generation as verified or selected.
- `src/GITREC.C`: read-only recovery selector linking native
  GITSEL and GITCIDX. For each candidate it binds the correct
  separate set of four input FILEDEFs, compares the claimed
  selector digest with its GEN2 manifest, then calls the
  **actual complete GENCHECK**, which reruns SFAST and PAIR
  over all staged objects, index entries and seek cookies.
  It selects only a fully verified candidate, checks that
  selector names match their assigned slots, refuses
  ambiguous identical slot names, and falls back to an older
  fully verified slot if the newer candidate fails.
  It never writes any stage, index, seek or GEN2 file.

The host fixture uses 1,808 synthetic staged records and two
independent GEN2 candidates. Tests inject changed staged bytes,
a damaged GEN2 manifest, truncated SIDX2, missing IDX2, spoofed
slot identities, invalid selector checksums and interrupted
selector writes. The real complete GEN2 verifier rejects each
damaged newer candidate and recovery chooses the older verified
one; it rejects both when neither can be verified.

The full host CI suite passed:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36330993480 .

## Isolated first CMS compilation and recovery check

These are a **read-only test on GITFIX**, plus two *new* small
selector files. They are not an active-generation promotion.
Do not run GENWRITE, STAGE or either index BUILD. The same
GITFIX files remain the protected baseline.

On the Mac, from `/Users/mikewommack/ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/GITSEL.C
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/GITREC.C
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/GITCIDX.C
```

On CMS compile both new programs **before** defining FILEDEFs:

```text
CMSCLNK GITSEL PLAIN
CMSCLNK GITREC PLAIN
TYPE GITFIX GEN A
```

The new `GITSEL WRITEGEN` can read the completed `GEN2` manifest
from the input FILEDEF `GENIN` and derive its DIGEST without
copying a 40-character value by hand. The record it writes
remains **untrusted** until GITREC performs complete GENCHECK.
Use the existing GITFIX GEN A; do not regenerate the manifest.

Only if `GITSEL0 PTR A` and `GITSEL1 PTR A` do not already
exist, create two disposable selectors using that input manifest:

```text
FILEDEF GENIN DISK GITFIX GEN A
FILEDEF SELOUT DISK GITSEL0 PTR A (RECFM V LRECL 80
GITSEL WRITEGEN 41 GITFIX GITSEL0
FILEDEF SEL0 DISK GITSEL0 PTR A
FILEDEF C0STG DISK GITFIX STAGE A
FILEDEF C0IDX DISK GITFIX INDEX A
FILEDEF C0SEEK DISK GITFIX SEEK A
FILEDEF C0GEN DISK GITFIX GEN A
GITREC SELECT GITFIX GITBAD
```

The first result should rehash every existing object, print
`GENERATION VERIFIED 1808 UNIQUE 1808`, and then
`SELECTED 41 GITFIX` with the same DIGEST. No SEL1 file or
new candidate generation is required for this first test.

Then test an invalid newer **disposable selector**, still
without creating or modifying any new generation's data:

```text
FILEDEF SELOUT CLEAR
FILEDEF SELOUT DISK GITSEL1 PTR A (RECFM V LRECL 80
GITSEL WRITEGEN 42 GITBAD GITSEL1
FILEDEF SEL1 DISK GITSEL1 PTR A
GITREC SELECT GITFIX GITBAD
```

Do not bind C1STG/C1IDX/C1SEEK/C1GEN to valid data.
The newer selector is syntactically valid, but its
referenced GEN2 data cannot be opened and verified.
Recovery must instead run full GENCHECK on the existing
GITFIX candidate and print `RECOVERED 41 GITFIX`.
Any false `SELECTED 42 GITBAD` result is a serious gate
failure. Preserve both disposable selector files for
diagnosis and keep all original GITFIX files unchanged.

If CMS cannot resolve the included `GITCIDX.C` or
`GITSEL.C` while compiling GITREC, capture the complete
compiler diagnostic. Do not substitute an untested
binary or claim target validation from host success.

## What remains

The current code does **not** write an active pointer, make
CMS file writes power-loss atomic or claim restart/reboot
recovery. A future isolated promotion milestone must use
different never-before-used generation filenames, two slot
records and failure injection, with a verified writer
exclusion protocol. Actual CMS recovery across system
reboot is still untested. The verified existing GITFIX
generation must never be used as a mutation target.

## Existing selector overwrite safeguard (host-proven)

The latest native `GITSEL WRITE` additionally opens SELOUT for
reading first and refuses to create an output when the mapped
selector slot already exists. It returns RC 8 and prints
`SELECTOR OUTPUT EXISTS` without overwriting the existing record.
The strict C89 regression tests verify the old selector bytes remain
unchanged after a second WRITE attempt. Full host CI passed:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36331581650 .

This guard prevents accidental sequential reuse of a selector file;
it is **not** an atomic create-if-absent operation or concurrent
writer lock. The test above must still use only previously unused
disposable selector filenames. Never bind SELOUT to a protected
existing selector or any GITFIX stage/index/seek/GEN data file.

## Host-proven digest-safe selector creation

The latest `src/GITSEL.C` also supports `WRITEGEN SEQUENCE BASENAME`.
It reads the existing completed GEN2 manifest through `GENIN`,
requires the complete five-record GEN2/DIGEST/MINOID/MAXOID/GEND2
grammar and matching counts, and uses its exact 40-hex DIGEST to
create a new untrusted selector through `SELOUT`. No user-supplied
digest is required. The existing best-effort output-exists guard
still refuses to overwrite an existing selector file. This avoids
confusing a commit, PACK checksum or min/max OID with the descriptor
digest and reduces error-prone manual copying. The host suite tests
correct byte-for-byte output, malformed/truncated/extra GEN2 records
and attempted overwrite. Complete CI passed:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36332001510 .
`WRITEGEN` has not yet been compiled or tested on CMS. It does not
validate staged content itself; the separate GITREC SELECT full
GENCHECK remains mandatory. Never bind SELOUT to an existing GITFIX
file. If either disposable selector filename already exists, choose
new unused 8-character names rather than overwrite it.

## Actual target compiler and first-runtime recovery finding

Both `CMSCLNK GITSEL PLAIN` and `CMSCLNK GITREC PLAIN`
compiled successfully on native CMS September 27, 2026 after
replacing literal C XOR operators incompatible with this DFT
source translation. The first `WRITEGEN` operation did not
create a selector: its read-only fopen existence probe returned
a non-null stream on an absent CMS DD, triggering
`SELECTOR OUTPUT EXISTS`. Recovery therefore could not
read SEL0/SEL1. This is a target-discovered runtime defect;
it is not evidence that the original GEN2 seal is damaged.

The updated `WRITEGEN SEQUENCE BASENAME OUTPUTNAME`
uses CMS `STATE OUTPUTNAME PTR A` instead of the lazy
read-only DD probe. It proceeds only if STATE reports missing
with RC 28; RC 0 refuses an existing file, and every other
return code fails closed. The operator must bind SELOUT to
the same OUTPUTNAME PTR A on a write-accessible minidisk.
The extra argument is mandatory for this CMS gate. It is
not an atomic concurrent-writer lock; STATE and write
remain separate operations.

After the revised code compiles, require STATE to report
missing for each new selector before binding SELOUT.
For slot zero, define all four inputs including C0IDX;
none of STAGE/INDEX/SEEK/GEN may be output FILEDEFs.
Do not rerun GENWRITE or any index build.

## September 27 CMS runtime correction: REXX owns the STATE gate

The target showed that GCCCMS C `system("STATE GITSEL0 PTR A")`
returns 0 even when interactive CMS and REXX `STATE` report
RC 28. Calling `fopen("dd:SELOUT","r")` before creating a file
also falsely reports an existing file. Thus neither C-level
probe can safely guard selector creation on this runtime.

The new CMS test path requires `GITRUN.EXEC`, which executes
`STATE GITSEL0 PTR A` with `ADDRESS CMS` and accepts only
RC 28. It then binds SELOUT to that same new filename and calls
`GITSEL WRITEGEN 41 GITFIX GITSEL0 ABSENT28`. The final
argument is an explicit attestation of the REXX-side check;
GITSEL rejects the named-slot form without it. This is only
a guarded single-writer test, NOT an independent atomic
create-if-absent guarantee. Never run it concurrently and
never run it against the existing verified GITFIX data files.

After fresh compilation, GITRUN first creates the new slot,
confirms STATE RC 0, binds SEL0 and all four C0 input DDs,
and invokes read-only `GITREC SELECT GITFIX GITBAD`.
If any gate fails, it stops. Reuse this exact GITRUN filename
for later milestone batches by editing it on GitHub first.

## September 27 native CMS: first valid selector target-proven

GITRUN ran the REXX RC-28 existence check and successfully issued
GITSEL WRITEGEN 41 GITFIX GITSEL0 ABSENT28, then checked
STATE GITSEL0 PTR A RC 0. GITREC SELECT GITFIX GITBAD
ran the real complete audit:
FAST AUDIT VERIFIED 1808 UNIQUE 1808,
PAIR VERIFIED UNIQUE 1808, GENERATION VERIFIED 1808 UNIQUE 1808.
It returned SELECTED 41 GITFIX with DIGEST
493F0896884B28AC4836B88328629B7E95404B46 and RC 0.
The SEL1 open diagnostic was expected because slot one was absent.
The protected GITFIX stage, IDX2, SIDX2 and GEN2 were not modified.

The reused src/GITRUN.EXEC now performs the second target gate:
check old selector exists and GITSEL1 PTR A is absent;
clear every C1 candidate FILEDEF; write only disposable
GITSEL1 PTR A with sequence 42 and nonexistent GITBAD name
using WRITEGEN ... GITSEL1 ABSENT28; then bind SEL1 and
invoke full GITREC SELECT GITFIX GITBAD. Expected result
is RECOVERED 41 GITFIX with the same digest and RC 0.
The second target gate has not yet been observed on CMS.
No active promotion, writer locking or reboot atomicity is claimed.

## September 27 target result: invalid-newer-slot recovery PASSED

The second CMS GITRUN run confirmed GITSEL0 PTR A present and
GITSEL1 PTR A absent (STATE RC 28), then created only the
disposable GITSEL1 PTR A with sequence 42, name GITBAD and
DIGEST 493F0896884B28AC4836B88328629B7E95404B46.
GITREC SELECT GITFIX GITBAD could not open C1GEN, as expected,
and ran complete SFAST/PAIR/GENCHECK on the older GITFIX
generation. It reported FAST AUDIT VERIFIED 1808 UNIQUE 1808,
PAIR VERIFIED UNIQUE 1808, GENERATION VERIFIED 1808 UNIQUE
1808, and RECOVERED 41 GITFIX with exactly the existing
manifest digest and RC 0. Both native first-selection and
invalid-newer fallback gates are now target-proven.

FILEDEF CLEAR on four undefined C1 DDs emitted harmless
DMSFLD704I diagnostics; subsequent GITRUN batches omit
these unnecessary CLEAR operations. Never repeat the selector
creation batch now that GITSEL1 PTR A exists: preserve both
selector records and all four original GITFIX data files.

The next separate durability gate is read-only GITREC SELECT
after an ordinary future CMS logoff/logon; a further
read-only check after an authorized system reboot would
establish system restart persistence. Neither proves atomic
promotion or concurrent-writer exclusion.

## September 27 completed CMS matrix: selector rejection

Additional read-only target tests passed:
(1) Both slot identities incorrectly mapped to GITBAD/GITFIX
were rejected with two mismatch diagnostics and RC8;
correct mapping recovered seq41 GITFIX with full 1808
audit and RC0. (2) With C0GEN temporarily mapped to
missing GITBAD GEN A, both generations were rejected,
RC8; restoring C0GEN recovered the full protected
generation. (3) Mapping SEL0 to a non-SEL1 GEN2
manifest rejected the old slot and bad-new-only
selection failed RC8; restoration recovered.
(4) A valid older slot with absent SEL1 selected
seq41 GITFIX with full audit RC0; missing SEL0 plus
unverifiable newer slot failed RC8; restoring both
recovered seq41 GITFIX RC0. No protected data or
existing selector records were modified.

These establish native single-slot recovery, invalid
newer fallback, name mismatch rejection, missing manifest,
malformed selector and bad-only fail-closed behavior.
They do not prove cross-reboot persistence, exclusive
writer locking, atomic file promotion or true interrupted
generation write recovery.


---

## Original: docs/BUILD.md (complete original build and transfer workflow)

# CMS/z/VM build and transfer workflow

## Canonical workflow

GitHub `main` is canonical. Edit there first. On the Mac, work from the local
`ibm-sandbox/src` directory, pull, then transfer only the files needed for the
next target gate.

For EXEC files:

    git pull
    ./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/NAME.EXEC

For assembler source:

    git pull
    ./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/NAME.ASSEMBLE

The established helper drives the single interactive c3270 instance through its
local script port and uses DFT file transfer. c3270 DFT 2048 is target-proven.
An absolute LocalFile path is preferred because c3270 resolves relative paths
from its own launch directory.

CMS filenames and filetypes are each limited to eight characters. Check this
before creating a target file.

## CMS assembler rules

`PROFILE EXEC` globalizes the preferred CMS macro library:

    GLOBAL MACLIB DMSGPI

Build a native module only after assembly succeeds:

    ASSEMBLE NAME
    LOAD NAME
    GENMOD NAME

Do not replace a known-good MODULE after an assembly failure. For fixed-card
assembler, keep ordinary source through column 71 unless an intentional
continuation is used. Assembler symbols must be at most eight characters.
SS-format MVC/XC explicit lengths must not exceed 256 bytes.

## CMS networking

Current routed TAP configuration:

- CMS/z/VM OSA1: `192.168.200.2/24`
- EC2 Debian tap0: `192.168.200.1/24`
- CMS default gateway: `192.168.200.1`
- DNS: `8.8.8.8`
- EC2 outbound NAT: MASQUERADE through ens5

MAINT's profile links TCPMAINT 592 read-only and accesses it as T so TCP/IP
client commands remain available.

## HTTPS bridge

The practical GitHub HTTPS path uses stunnel on EC2. The listener is bound only
to the TAP address:

    192.168.200.1:8443

Its outbound side connects to `github.com:443` with certificate-chain
validation, hostname validation, SNI, and TLS 1.2 or newer.

The EC2-local plaintext-to-stunnel test returned GitHub HTTP/1.1 200. The CMS
M11BRAW test then connected to `192.168.200.1:8443`, sent exact raw HTTP
bytes, received 176 bytes, saw wire prefix
`485454502F312E3120333031204D6F76` (`HTTP/1.1 301 Mov`), and passed its
bounded binary-safe socket gate. This proves CMS -> TAP -> stunnel -> verified
TLS -> GitHub -> CMS.

`M12PRXY EXEC` is the isolated `Host: github.com` probe. Live Git smart-HTTP
is now proven through `M12GDISC`, `GIT12CHK`, `M12JPOST`, and `M12KPACK`.
The captured live PACK is 340,027 bytes with 1,808 objects and verified SHA-1
`8C92E274ECA84B797F8925A6082915DD6CCDE196`. Keep the already-proven M11BRAW
core intact.

## Native System SSL

`M12TLS4 ASSEMBLE` and related diagnostics are preserved for native z/VM
Dynamic SSL research. They are not required for the practical stunnel transport.
Do not regress the target-proven VMCF callcodes or retry certificate-validation
bypass attempts; server-certificate validation is mandatory on this path.

## GCCCMS native build checkpoint (2026-09-26)

The original `GITCLNK EXEC` proved the compiler/linker path through
`GITCWALK` and `GITCIDX`. The canonical replacement is now the
neutral `CMSCLNK EXEC` (7-character CMS name), intended to live on
the existing GCCCMS F disk. The default `NAPI` mode retains the
exact required GCCE, Assembler XF, GITCAPI/GITINFA and PDPCLIB
linkage. Optional `PLAIN` builds C modules that do not call the
native inflater (such as `GITCIDX`), without assembling those
adapters. Both modes must be proven on actual CMS before retiring
the previous A-disk copy of `GITCLNK`.

## Installing the build EXEC on the GCC F disk

GitHub `src/CMSCLNK.EXEC` is canonical. Upload through the
existing *single* c3270 file-transfer session; the uploader places
it on CMS A first. On the Mac from `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/CMSCLNK.EXEC
```

On CMS, **first** check whether the GCC F disk is read/write:

```text
QUERY DISK F
```

If it reports `R/W`, copy the new EXEC to F and confirm it exists:

```text
COPYFILE CMSCLNK EXEC A CMSCLNK EXEC F
STATE CMSCLNK EXEC F
```

For an F disk reporting `R/O`, **do not attempt a destructive
remount or modify GCC installation**. The A-disk copy is usable
temporarily; installing on F requires authorized read/write access
to that minidisk. Never assume the F disk can be written merely
because GCC is installed there.

Once the copy to F succeeds and is verified, remove **only the
new A-disk copy** (`ERASE CMSCLNK EXEC A`) to ensure subsequent
`CMSCLNK` commands resolve to F, leaving the proven
`GITCLNK EXEC A` available until the new build is CMS-validated.
The runtime build uses source and generated assembler on A; moving
the tool itself to F does **not** move the Git-specific adapter
sources from A or overwrite working modules.

Usage once F is ready:

```text
CMSCLNK GITCWALK
CMSCLNK GITCIDX PLAIN
```

The default `NAPI` mode uses the original target-proven sequence.
`PLAIN` is new and needs one real CMS link test. Avoid needless
rebuilding of the working `GITCWALK MODULE` while validating
installation; begin with `CMSCLNK GITCIDX PLAIN` after copying
the new tool to F. Once its module builds and runs normally,
`GITCLNK EXEC A` can be retired. IBM's `QUERY DISK F` reports
`R/W` or `R/O` and `COPYFILE` supports copying across accessed
minidisks; a file is only writable on a disk accessed `R/W`.

## Confirmed GCC F-disk access (2026-09-26)

User's live `Q DISK` shows `GCCLIB` at VDEV `29D`, accessed as
**F R/W**, 20 cylinders, 2,055 free 4K blocks, 38 files. Therefore
`CMSCLNK EXEC` can be copied directly from A to F; no relink,
reaccess, remount, or permission change is required. Do not claim
installation is complete until `STATE CMSCLNK EXEC F` and the new
CMSCLNK PLAIN build succeed on CMS. Existing GITCLNK EXEC A is
rollback until that test. The only necessary F-disk installation
commands after Mac upload are:

```text
COPYFILE CMSCLNK EXEC A CMSCLNK EXEC F
STATE CMSCLNK EXEC F
ERASE CMSCLNK EXEC A
CMSCLNK GITCIDX PLAIN
```

Run `ERASE` only after confirming the preceding `COPYFILE` and
`STATE` succeeded; never erase the original GITCLNK EXEC A at
this checkpoint. Once the new compile succeeds, run the separate
AUDIT/SBUILD/SCHECK/SGET gate in docs/NATIVE_INDEX.md.

For historic compile fixture results, see `docs/STATUS.md`;
for the native object-store next gate, see `docs/NATIVE_INDEX.md`.


---

## Original: docs/LINK_BATCH.md (complete original record)

# M38: single-audit read-only link validation batch

## Why

The actual z/VM CMS M37 compact regression on September 28, 2026
passed in 693.54 CPU / 708.96 elapsed seconds. Three individual
successful M35/M36/M37 commands each independently ran a complete
native GEN2 verification, even though depth-two success proves
the shallower checks for the same selected immutable generation.
This repeated audit work motivates a narrower native interface.

## LINKBATCH

`GITREC LINKBATCH C0NAME C1NAME COMMIT_OID40` performs exactly
one usual fail-closed selector choice. Each candidate still undergoes
the complete native GENCHECK (including staged-body SHA-1, IDX2 and
SIDX2 pairing, seek cookies and GEN2 seal). After a candidate passes,
the command validates the supplied child commit and every parent
commit (maximum 16), all associated root trees and all locally
referenced root links through depth two within that same generation.
The existing bounded walker enforces 256 links per visited tree and
a shared 1,024-tree visit budget. Gitlinks point into external
repositories and remain excluded from local object resolution.

Only on *complete* success, the command emits three markers:
```
NESTED ROOT LINKS VERIFIED
DEEP ROOT LINKS VERIFIED
LINK DEPTH 2 VERIFIED
```
It then emits the usual framed complete parent list. A missing
object returns RC4; wrong type, malformed structure, failed hash
or exceeded limits return RC8. No partial success markers or parent
lists on failure. The prior ROOTLINKS, NESTLINKS, DEEPLINKS and
DEPTHLINKS commands are unchanged and remain independently
regression-tested on the host.

The command does NOT make a pointer active, write or alter a
generation, establish reboot durability, or implement atomic
promotion or locking.

## Existing proof and outstanding proof

M35, M36 and M37 have all passed actual CMS compilation and the
standard M37 one-page gate. M38 adds a performance-oriented
single-audit batch. The native integration test includes valid
deep links, missing/wrong-type deep links, bad child OIDs, older
generation recovery, both-generation rejection and restored newer
selection. Check actual GitHub Actions CI before describing M38
as host-proven; it has not yet been tested on actual CMS.

## Next safe target gate

On the Mac from `ibm-sandbox/src`:
```sh
git pull
./cms-upload.sh GITREC.C
./cms-upload.sh GITRUN.EXEC
```
On CMS:
```text
CMSCLNK GITREC PLAIN
GITRUN
```
Use only the standard in-memory, one-page compact runner.
M38 keeps both independent original GITFIX/M15NEW 1,808-object
audits and explicit selector selection. It replaces three
separate successful depth-two-or-shallower GITREC checks with one
LINKBATCH. Negative depth, noncommit and missing child checks,
older recovery, both-invalid fail-closed, restored newer selection
and final original STATE checks remain.

Expected final marker, only if every check succeeds:
```
GITRUN M38 ALL READ ONLY NATIVE GIT TESTS PASSED
```

The original GITFIX/M15NEW STAGE, INDEX, SEEK and GEN files,
selector PTRs, and GITPBUF PACK remain protected and read-only.
Only upload GITREC.C and the standard GITRUN.EXEC; the other
native programs do not change.

## M39: skip redundant subtree reads during recursive validation

After M38, the depth-aware walker still read, rehashed and
parsed a referenced subtree as a direct entry, then read,
rehashed and parsed the same subtree again when descending.
At any positive remaining depth, M39 skips the first
redundant body read for tree entries. The existing recursive
call still independently resolves the indexed OID, validates
the exact tree type, rehashes the body, parses its entire Git
binary tree structure and checks every requested descendant.
Every blob is still validated at its original level; at
depth zero every referenced subtree is still validated.
The per-tree 256-entry and shared 1,024-tree budgets and
fail-closed return codes remain unchanged.

The host integration additionally tests missing and wrong-type
linked objects in a nested child tree, corruption in a merge
parent's tree, and the 257-entry root limit, with no partial
success markers or metadata. Native host CI passed on
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36482019995
and M39's implementation was squash-merged to main at
`a359c9c4f72486bf2b69454286d83b1b57123419`.

M39's first real CMS gate is the standard M39-labelled
GITRUN, which also serves as the first actual M38 LINKBATCH
target proof. No separate M38 target run is needed if M39
passes. Use the same two Mac uploads and two CMS commands
above; successful final marker becomes:

```
GITRUN M39 ALL READ ONLY NATIVE GIT TESTS PASSED
```

Do not infer a target performance improvement before
the actual M39 CMS timing. Existing real target proof ends
at M37 until the operator runs this new combined gate.

## M40: atomic path metadata for terminal directories

The M39 read-only tree walk is target-proven. A separate
path-walking edge case remained: PATH could return a canonical,
correctly typed but structurally malformed *terminal* subtree;
LSDIR printed PATH OBJECT TYPE and OID before checking its
tree structure. The SHA-1 of a malformed tree is a valid Git
OID, but should not authenticate it as a directory.

M40 requires the full binary Git tree parser to succeed before
either PATH or LSDIR emits **any** metadata about a terminal
tree. This is in addition to the existing full selected GEN2
audit, referenced object-type check and SGET SHA-1 verification.
Malformed terminal trees return RC8 with
`DIRECTORY TREE STRUCTURE INVALID`; no PATH OBJECT TYPE
or TREE DATA BEGIN is emitted. Plain blob PATH and PATHCAT
semantics, Gitlinks and all existing link-depth commands
are unchanged.

Full host integration adds deliberately malformed terminal
subtree tests for both PATH and LSDIR, including no partial
result checks. One standard `GITRUN M40` adds a positive
real 1,808-object historical `src` directory lookup using
the known first commit and path hex 737263, while retaining
both independent full GEN2 audits, the M39 LINKBATCH test,
the negative cases, two-slot recovery and final protected
STATE checks. Only GITREC.C and GITRUN.EXEC require CMS
transfer. After full host CI succeeds, real target gate:

```sh
git pull
./cms-upload.sh GITREC.C
./cms-upload.sh GITRUN.EXEC
```

```text
CMSCLNK GITREC PLAIN
GITRUN
```

Expected final marker after a genuine target success:
`GITRUN M40 ALL READ ONLY NATIVE GIT TESTS PASSED`.
No protected original generation or pointer is modified.

## M41: fully verified directory listing

`GITREC LSDIRV C0NAME C1NAME COMMIT_OID40 DIRHEX`
extends the target-proven path walker: after real
full GEN2 selection and an authenticated commit-to-directory
path, it checks that *every immediate local directory entry*
references an independently rehashed object of the expected
Git blob/tree type. Linked subtrees are additionally parsed
as complete binary Git trees. Gitlinks represent external
repositories and are not falsely treated as local objects.
The existing 256-entry/tree and shared 1024-visit limits
remain enforced. A missing reference returns RC4, a wrong
type, invalid subtree, malformed terminal directory or limit
violation RC8, and *no* verified marker, path metadata or
directory listing is emitted on failure.

The read-only walker reuses its body buffer for linked
objects, so LSDIRV explicitly reloads and revalidates the
selected directory before producing its listing. The old
LSDIR command retains its original structural-only listing
semantics; PATH and PATHCAT remain unchanged except for
M40's terminal-tree validation. Host integration checks a
valid nested directory and a pair of structurally valid
directories with respectively missing and wrong-type linked
blobs; the legacy LSDIR accepts the latter but LSDIRV must
reject them before any output. A malformed subtree must
also be rejected without leaking metadata.

M41's ONE compact GITRUN combines M40's terminal-tree
hardening, M41's positive actual historical `src` directory
listing and all previously target-proven M39 full audits,
link batch, negatives, fallback and protection checks.
Only GITREC.C and GITRUN.EXEC need uploading. The
expected actual CMS final marker after a real success is
`GITRUN M41 ALL READ ONLY NATIVE GIT TESTS PASSED`.
M40 and M41 must remain host-only until the full CI run
and actual CMS transcript establish the respective results.

## M42: bounded recursive directory verification

`GITREC LSDIRDEPTH C0 C1 COMMIT_OID40 DIRHEX DEPTH`
extends M41's authenticated directory lookup with a strict
one-byte decimal depth from 0 through 4. At depth zero,
the selected directory's immediate local blob/tree entries
are independently authenticated, as in LSDIRV; larger
depths also descend through that many levels of local
subtrees. The existing 256-entry-per-tree and shared
1024-tree-visit limits apply; external Gitlinks are skipped
as external repository references. All operations remain
within one completely audited immutable GEN2 generation,
and no partial metadata/listing is printed if ANY
referenced object fails. Successful output includes
`DIRECTORY LINK DEPTH N VERIFIED`, followed by the
full authenticated directory listing. Invalid depth RC4,
missing referenced objects RC4, wrong type, malformed
subtree or exceeded limits RC8.

The native host suite checks all five valid depths,
invalid depth strings and two groups of fixtures where a
shallower directory check succeeds but a deeper check
discovers a missing or wrong-type object. M41 LSDIRV,
M40 structural-only PATH/LSDIR and all prior read-only
commands remain individually regression-tested.

One standard M42 compact target runner tests the actual
historic `src` directory at depth one. This exercises
M40, M41 and M42 together, in addition to independently
auditing GITFIX and M15NEW, checking M39 LINKBATCH,
negative child/depth errors, seq51 fallback, both-slot
fail-closed handling, seq52 restoration and original
protected data STATE checks. The historic root/depth
objects were previously authenticated by the real M39
depth-two child/parent tree walk, so this target fixture
does not require a new network fetch or test generation.

Only transfer GITREC.C and the standard GITRUN.EXEC:
```sh
git pull
./cms-upload.sh GITREC.C
./cms-upload.sh GITRUN.EXEC
```

```text
CMSCLNK GITREC PLAIN
GITRUN
```

The real target final marker must be
`GITRUN M42 ALL READ ONLY NATIVE GIT TESTS PASSED`
before M40-M42 can be described as target-proven.

## M43: enforce tree-entry budget across external Gitlinks

The bounded recursive walker previously counted only *local* blob/tree references against its 256-entry-per-tree limit. Gitlinks (`160000`) were correctly skipped for local object resolution but also skipped the entry counter; 257 or more external Gitlinks could evade the published bound. M43 separates the total entry count from the local object-array count, rejects the 257th entry of **any** supported mode with `ROOT LINK LIMIT EXCEEDED` RC8, and continues to skip external Gitlink object lookups. Original 1,024-tree visit budget and all fail-closed behavior are unchanged. Tests exercise exactly 256 Gitlinks (success), 257 Gitlinks in a commit root (RC8 without parent or success markers), and 257 Gitlinks in a commit-relative directory via LSDIRDEPTH (RC8 without metadata or partial listing). Both original 1,808-object generation audits and all recovery/protection gates remain in one M43 standard compact runner. The real positive historical directory case is unchanged. M43 requires only GITREC.C and GITRUN.EXEC on the next actual CMS gate; GITCIDX and GITSEL remain unchanged. Expected terminal marker: `GITRUN M43 ALL READ ONLY NATIVE GIT TESTS PASSED`.

## M44: bounded complete tree closure

New read-only `GITREC CLOSURE C0 C1 COMMIT_OID40` traverses the complete local Git tree/blob graph for the supplied child commit and every authenticated parent root, beyond M37's caller-selected depth-four ceiling. It uses a bounded iterative stack instead of unbounded C recursion, independently checks each referenced local object's indexed type and staged-body SHA-1, parses every reached Git binary tree, and skips external Gitlinks without falsely requiring locally stored submodule commits. Both the existing 256-entry per-tree limit (including Gitlinks, per M43) and a single shared 1,024-tree visit budget across the child and all parent roots remain enforced. Trees are allowed to share object IDs but repeated visits count against the budget. On ANY missing object (RC4), wrong type/structure or resource limit (RC8), no `FULL ROOT CLOSURE VERIFIED` marker or framed parent list is emitted. This checks presence and integrity within the same fully audited immutable generation, not any write/promote or restart-durability operation.

Synthetic native C89 host fixtures include six nested tree levels. M37 `DEPTHLINKS 4` intentionally passes while a deepest missing or wrong-type object exists; M44 `CLOSURE` must reject those child or merge-parent cases before any authenticated success output. The standard single-page M44 GITRUN additionally runs full closure of the historical real first commit and all its parents, alongside independent original full 1,808-object audits, M43's existing positive link and directory checks, negative cases, older-slot recovery, both unavailable fail-closed, restoration and final protected-file checks. It supersedes the untested M43 target gate; one M44 target run covers M43/M44 after full host CI. Transfer only GITREC.C and GITRUN.EXEC, compile with `CMSCLNK GITREC PLAIN`, run `GITRUN`; expected final marker `GITRUN M44 ALL READ ONLY NATIVE GIT TESTS PASSED`. If historical full closure is legitimately incomplete, the read-only gate must fail closed without changing either original generation.

## M45: complete closure for a chosen directory

New read-only `GITREC LSDIRFULL C0 C1 COMMIT_OID40 DIRHEX` extends the target-proven M42 path traversal with M44's iterative **complete local closure** of the chosen terminal directory. After full selected-generation GEN2 verification, commit structure and commit-relative path checks, it traverses every local tree/blob descendant (no depth-four ceiling), verifies indexed object type and SHA-1 body, parses every tree, counts all modes including external Gitlinks toward 256 entries/tree, and enforces a shared 1,024-tree visit budget. Gitlinks are external and are not dereferenced. After full closure, it reloads the chosen directory because linked lookups reuse the body buffer and emits `DIRECTORY FULL CLOSURE VERIFIED`, authenticated path metadata and one complete directory listing. Missing data RC4; bad type/syntax/budget RC8, with no marker, metadata or partial listing. Existing LSDIR/LSDIRV/LSDIRDEPTH behavior remains unchanged.

Synthetic host tests verify that depth-four listing succeeds on a six-level tree with a missing or mistyped deepest object, while LSDIRFULL rejects it without partial output; a valid long tree succeeds, 257-Gitlink directories are rejected, and malformed path syntax is rejected before a selected-generation audit. The one standard M45 compact GITRUN adds a real complete closure of the historical `src` directory alongside M44 full child/all-parent root closure, both independent original 1,808-object GEN2 audits, original single-link batch, bounded depth-one src proof, fail-closed negatives, older fallback, both unavailable and restored newer selection and final protected-state checks. The actual M44 target already authenticated the entire historical first-commit graph, so this positive M45 path reuses a known original tree, not a synthetic CMS fixture. Once full native host CI passes, transfer only GITREC.C and GITRUN.EXEC and run CMSCLNK GITREC PLAIN, then GITRUN. Expected last marker, only after actual native success: `GITRUN M45 ALL READ ONLY NATIVE GIT TESTS PASSED`.

## M46: complete closure from a raw tree object ID

`GITREC TREECLOSURE C0 C1 TREE_OID40` authenticates any indexed Git tree without requiring an associated commit or commit-relative path. It first selects a fully verified sealed GEN2 generation, then reuses the M44 bounded iterative full-closure walker with the M43 256-total-entries/tree (Gitlinks count) and shared 1024-tree visit budget. Every local blob/tree reference must have the expected indexed type and a rehashed staged object body; all encountered subtrees must have structurally valid binary Git records. External Gitlinks are counted toward the entry limit but never falsely dereferenced as local objects. Only after the entire closure succeeds does it reload the root tree and emit `TREE FULL CLOSURE VERIFIED` and a complete direct tree listing. Missing tree/blob RC4, malformed root or descendants, wrong types and resource limits RC8, without partial listing or success marker.

Host production-C89 integration covers a valid six-deep tree, corrupt deeply nested blobs, malformed root, missing tree, wrong root type, 256/257 Gitlinks, and exact 1024/1025 tree-visit limits. One standard compact M46 GITRUN adds a real historic first-commit root tree closure to the existing independently audited 1808-object original generations, M39 linked-depth batch, M42 src depth-one, M45 src full closure, M44 complete child+all-parent closure, negative child/depth, old-slot fallback, both-invalid fail-closed, restored new slot and final protected files. This historical root's complete closure was already target-proven in the real M44 test; M46 tests that it can be requested directly by raw tree OID. Only GITREC.C and GITRUN.EXEC require transfer. Do not mark M46 actual target-proven until a real `CMSCLNK GITREC PLAIN` and `GITRUN` print `GITRUN M46 ALL READ ONLY NATIVE GIT TESTS PASSED`.

## Actual CMS proof through M45

On September 28, the real z/VM CMS `CMSCLNK GITREC PLAIN` compiled M45 with no flagged statements, then its complete standard compact `GITRUN M45` passed all checks, including two independent full original 1,808-object audits, historic src complete closure, complete child/parent closure, fallback, both-generation-invalid rejection, restoration and all final protected files. Full run was 705.89 CPU / 721.23 elapsed sec. M45 is ACTUAL CMS target-proven. Synthetic M43/M44 resource boundaries and deep M45 corruption cases were proven in separate host C89 integration; do not conflate those fixtures with the real immutable stage. M46's direct tree-OID closure reuses the existing bounded verifier and remains host-only until one real `GITRUN M46` success is supplied.

## M47: require entire commit-root closure before path metadata

`GITREC PATHFULL C0 C1 COMMIT_OID40 PATHHEX` first verifies the selected generation and commit structure, then runs the existing bounded iterative full-root closure on the commit's tree **before any path-specific result**. It independently checks every local tree and blob in the entire snapshot, including unrelated sibling branches; 256 entries/tree including external Gitlinks and the shared 1,024-tree-visit limit still apply. It then traverses the requested commit-relative path and returns authenticated metadata (`PATH OBJECT TYPE ... OID ...`) or external Gitlink reference, preceded by `COMMIT ROOT FULL CLOSURE VERIFIED`. This is metadata only; no blob HEX or tree listing. For missing descendants or path RC4, malformed/wrong-type descendants, noncommit or budget failure RC8, it never emits the success marker or path metadata. Invalid `PATHHEX` is rejected before auditing. This is stronger than ordinary PATH, which only validates the traversed path, and different from LSDIRFULL, which verifies the requested directory's descendants but not other sibling branches.

Synthetic tests confirm that ordinary PATH successfully reports a valid README.md while PATHFULL refuses to disclose it if an unrelated deeply nested sibling blob is missing or wrong-type. Positive fixtures cover blob, tree and external Gitlink terminal paths, missing names and malformed inputs. The only standard M47 native gate adds the target-proven historic first-commit `src` path with whole-root closure; M46 already demonstrated native complete closure of that root. All preceding independent original full audits, dir/commit/raw-tree closure checks, expected negative RCs, older-generation fallback, both-invalid fail-closed, restoration, and final protected-state checks remain intact. Full host CI required before main merge; then transfer only GITREC.C and GITRUN.EXEC for one actual M47 CMS run.

## M48: snapshot-authenticated binary blob retrieval

`GITREC PATHFULLCAT C0 C1 COMMIT_OID40 PATHHEX` extends M47 PATHFULL with full raw hex blob data output. It first fully verifies the selected sealed generation and commit structure, then authenticates the **entire commit root** using the bounded iterative closure verifier before walking the requested path. Only a correctly typed, SHA-1 authenticated local blob is accepted; a tree or external Gitlink cannot be read as a blob. After all verification succeeds it emits `COMMIT ROOT FULL CLOSURE VERIFIED`, canonical `PATH OBJECT TYPE 3 SIZE ... OID ...`, `PATH DATA BEGIN`, 32-byte `PATH HEX` chunks, and `PATH DATA END`. Empty and 64-KiB blobs use the same lossless format as PATHCAT, but missing or mistyped unrelated sibling objects and resource-limit breaches now fail without any path metadata or blob content. Every read is from the fully validated immutable selected generation. Malformed hex input is rejected before auditing. No persistent files or selector writes.

Host C89 regressions cover zero-length, binary (0x00 to 0xFF), maximum 64-KiB, nested paths, missing/wrong-type deep siblings that ordinary PATHCAT does not inspect, forbidden tree/Gitlink terminals, malformed paths, older seq51 recovery, both-generation-invalid RC8 with no content and restored seq52. The only standard M48 compact target GITRUN adds the real historical first-commit README.md snapshot-authenticated blob read, retaining M47 PATHFULL of the real `src` tree plus all earlier full audits, full closures, negative RCs, recovery and protected originals. Original historic root SHA and descendants were already target-proven in M44–M46; only GITREC.C and GITRUN.EXEC need CMS transfer after full host CI is green. Exact final marker requires real CMS success: `GITRUN M48 ALL READ ONLY NATIVE GIT TESTS PASSED`.

## M49: complete-snapshot authenticated directory listing

`GITREC PATHFULLDIR C0 C1 COMMIT_OID40 DIRHEX` verifies the entire local Git tree/blob closure of a commit in the same fully audited immutable selected GEN2 generation before disclosing the requested directory's metadata or listing. It uses M44's bounded iterative closure verifier with M43's 256-entry/tree bound counting external Gitlinks and one 1024-tree visit budget. Unlike LSDIRFULL, corruption in an unrelated sibling subtree prevents disclosure. A valid directory prints `COMMIT ROOT FULL CLOSURE VERIFIED`, authenticated `PATH OBJECT TYPE 2 ... OID ...` and one complete `TREE DATA BEGIN`/`TREE DATA END` listing. Non-tree terminal entries, missing paths, missing local siblings, wrong type or traversal limits fail without a success marker or partial metadata/listing. Empty and malformed hex paths are rejected before a full audit; Gitlink terminal entries cannot be mistaken for local directories.

Host production C89 fixtures check valid six-level trees, unrelated missing/wrong-type deep branches, forbidden blob/Gitlink terminals, malformed path strings, fully verified older seq51 fallback, both invalid fail-closed output and restored seq52. The one standard M49 GITRUN adds complete-snapshot historic `src` listing and retains both independent original full 1808-object audits and every M39–M48 positive/negative, fallback, fail-closed, restored and final protected-file check. The historical first-commit root closure was already independently actual CMS target-proven in M44–M48. This M49 command still requires its own real CMS proof before being called target-proven. Transfer only GITREC.C and GITRUN.EXEC after complete native-stage host CI passes; GITCIDX/GITSEL and all protected original files remain unchanged.

## M50: complete-closure paths from an arbitrary raw tree OID

`GITREC TREEPATHCAT C0 C1 TREE_OID40 PATHHEX` and `GITREC TREEPATHDIR C0 C1 TREE_OID40 DIRHEX` accept a tree's raw SHA-1 and a HEX path relative to that tree; no commit is needed. After full selected-generation GEN2 attestation, each validates the root's type and runs the existing complete iterative tree/blob closure over the **entire supplied root** before traversing the requested path. Tree visits share the 1024 limit; all entries including external Gitlinks count toward 256/tree. TREEPATHCAT returns fully authenticated binary blob bytes in the established `PATH HEX` 32-byte chunk format; TREEPATHDIR returns fully authenticated directory metadata and complete tree listing. Both print `TREE ROOT FULL CLOSURE VERIFIED` only after all local tree/blob links and selected terminal type have passed. Missing roots/links return RC4; wrong types, invalid structure and resource limits RC8 without success marker or path metadata/blob bytes/tree listing. A Gitlink remains external and cannot be mistaken for a local blob or directory. Bad PATHHEX is rejected before a full audit.

Production strict C89 host tests cover binary/empty/64-KiB/nested files, raw tree directory listings, unrelated missing/wrong deep subtree rejection, absent/wrong-type root, invalid terminals and hex, 257 Gitlinks, 1024 versus 1025 tree visits, older fully verified seq51 fallback, dual invalid fail-closed and restored seq52. The one M50 compact native gate adds raw historical root README and src directory traversal to all previous real original 1808-object audits, M35–49 full closures, negative RC4/8, fallback and protected original checks. The actual historical root's closure was already proven on real CMS by M44–M49, but M50's new commands remain host-only until real native `GITRUN M50` succeeds. Transfer only GITREC.C and GITRUN.EXEC; preserve every sealed original, selector PTR and PACK.

## M51: complete raw-tree closure before arbitrary path metadata

`GITREC TREEPATH C0 C1 TREE_OID40 PATHHEX` expands M50 raw-tree-relative binary and directory commands with metadata-only lookup for blobs, subtrees and external Gitlinks. The selected sealed GEN2 generation is fully audited and the raw root must be a valid tree; all local tree/blob descendants of that root are verified within 1024 tree visits and 256 entries per tree (external Gitlinks count but are never dereferenced locally). Only after the entire closure and selected path are valid does it release `TREE ROOT FULL CLOSURE VERIFIED` and authenticated `PATH OBJECT TYPE ... OID ...` metadata or `PATH GITLINK (EXTERNAL COMMIT)` and `PATH OID` for an external Gitlink. No content or listing is emitted. Missing roots/descendants return RC4; wrong root type, invalid descendants and limits return RC8, with no metadata leakage. Bad hex paths are rejected before a full generation audit. Host strict C89 regressions exercise terminal blob, directory and external Gitlink, deep missing/wrong sibling rejection, invalid hex/root, resource boundaries, older seq51 recovery, dual-invalid fail-closed and restored seq52. The compact M51 CMS runner adds historic raw root `src` metadata proof while retaining every protected preceding milestone's original-data test. M50 actual CMS target proof is recorded in docs/CURRENT_STATE.md; M51 requires real CMS target verification after full host CI.

## M52: one selector audit for the complete positive regression

`GITREC RUNBATCH C0 C1 COMMIT_OID40 TREE_OID40 DIRHEX FILEHEX` runs the existing production positive checks sequentially **inside one selected GITREC process**, after a single complete strict GEN2 selector verification. Its eleven operations are: LINKBATCH depth2 (combined M35–37), LSDIRDEPTH directory depth1, LSDIRFULL, CLOSURE child and all direct parents, standalone raw TREECLOSURE, commit-root PATHFULL metadata, PATHFULLCAT blob data, PATHFULLDIR directory listing, raw-root TREEPATHCAT blob, TREEPATHDIR directory and TREEPATH metadata. Each operation still performs independent full local object/link validation, with its own fresh resource budget, but does not repeat the selected-generation audit in a new process. The final `BATCH ALL POSITIVE CHECKS PASSED` is printed only if **every** operation returns RC0; failures abort immediately and never print that aggregate marker. The compact standard M52 `GITRUN.EXEC` preserves both original independent GITCIDX GENCHECK 1808-object audits, the standalone selector check and the distinct negative, older seq51 fallback, both-invalid fail-closed, restored newest seq52 and final protected-file tests. Only eleven redundant full-selector audit runs are collapsed into one. No sealed original files are touched. The previous M50 actual native run was CPU 1109.69/elapsed 1133.73 sec on the post-reboot host; the user noticed the tests taking longer. M51 real native test still has NOT been confirmed: the post-reboot CMS terminal reported `GITRUN M50`, indicating a stale runner was executed.

Mac `src/cms-upload.sh` and `src/cms-download.sh` now accept `CMS_SCRIPT_PORT` (default 3271), so with the present SSH tunnel on 3271 and c3270 script socket on 3272 use `CMS_SCRIPT_PORT=3272 ./cms-upload.sh GITREC.C` and `CMS_SCRIPT_PORT=3272 ./cms-upload.sh GITRUN.EXEC`. Before any native M52 regression, confirm on Mac that `GITRUN.EXEC` begins `/* M52` after git pull, that each upload reports success, and on CMS that `TYPE GITRUN EXEC A` starts with the M52 banner. Then `CMSCLNK GITREC PLAIN` and one `GITRUN`. Host strict C89 integration tests must pass before merging the M52 branch. Runtime savings on real CMS remain to be measured; this architecture removes repeated selector audits, not the per-feature descendant checks or original independent audits.

## M53–M54: avoid redundant selected-generation audits

M52 passed actual CMS on 2026-09-29 (CPU 962.91 / elapsed 986.89 seconds). M53 removes the redundant separate `GITREC SELECT` from the one compact REXX test runner; `RUNBATCH` independently verifies and reports `SELECTED 52 M15NEW` and the compact test asserts that exact selection before printing `PASS SELECT SEQ52 FROM VERIFIED BATCH`. Both independent 1,808-object original GITCIDX full audits remain unchanged. Strict host native-stage CI for M53 passed. M54 adds expected wrong-type and missing-child tests *inside* the same fully verified `RUNBATCH`, after the eleven positive operations. It requires `rec_parents` called on the already verified raw tree OID to return RC8, then on an absent all-zero child OID to return RC4. Each gets an explicit `BATCH NON COMMIT CHILD RC8 VERIFIED` / `BATCH MISSING CHILD RC4 VERIFIED` marker only for the exact expected return code. Any unexpected RC aborts and withholds final `BATCH ALL POSITIVE CHECKS PASSED`. The REXX gate captures both markers from the single batch before reporting those negative tests passed, removing two redundant separate GITREC selector verifications. It keeps the invalid-depth RC4 syntax test, older seq51 recovered audit, both invalid fail-closed RC8, seq52 restored audit, both separate original full audits, and final protected files. Exact C89 host regression checks new markers under normal selected seq52, older seq51 recovery, restored seq52 and their absence when both generations are invalid. M54 is NOT target-proven until an actual CMS `GITRUN M54` passes.

## M55: bounded cache inside single immutable-generation RUNBATCH

Actual M54 CMS full regression passed, CPU 900.08 / elapsed 923.83 seconds. M55 keeps two in-memory entries keyed by the exact 20-byte raw tree OID. The cache operates **only within RUNBATCH after complete selected GEN2 attestation**, remembers exclusively successful complete root closures under a fresh 1024-visit budget, and never spans a new process, selector choice, standalone command, partial verification or parent-shared traversal budget. Repeated PATHFULL, PATHFULLCAT, PATHFULLDIR and TREEPATH variants reuse the authenticated complete root while still re-reading and checking their own path and terminal object. RUNBATCH emits `BATCH ROOT CLOSURE REUSES N` only after successful reuses and requires that N be positive before final aggregate success. Native C89 host integration tests include latest selection, older seq51 fallback, dual-invalid no-output and restored seq52. The compact regression retains two independent 1808-object original full audits, every previous feature, wrong-type RC8 and missing-child RC4 inside batch, invalid-depth RC4, recovered seq51, both-invalid RC8, restored seq52 and final protected files. A new native runtime comparison is valid only after actual CMS completion.

## M56: one parsed seek-index snapshot per verified RUNBATCH

M55 actual z/VM CMS native full test passed on 2026-09-29, zero flagged statements, CPU 619.93/elapsed 635.48 seconds, versus M54 923.83 elapsed. M56 removes another source of repeated work: the eleven operations inside fully selected RUNBATCH each reparse the same 1808-entry selected seek-index. After the complete original GEN2 selector audit, RUNBATCH now performs one direct fresh complete `sidx_read`, then keeps that exact parsed in-memory seek-index snapshot for its own read-only process. The code retains the original `sidx_read` on all standalone commands and on every GEN2 full verification, uses no persistent cache across calls or generations, and still freshly reopens/reconstructs/re-hashes object bytes for every `sidx_get` and validates each complete closure and requested path. A required `BATCH SEEK INDEX REUSES N` marker is emitted only after successful complete batch checks; N must be positive. Host tests check it on newest seq52, verified older seq51 fallback and newest restored, but never on both-invalid or standalone calls. The single compact M56 regression retains the two independent full original 1808-object GITCIDX audits, all previous positive features and complete root cache proof, exact wrong-child RC8/absent RC4 inside batch, malformed depth RC4, older recovery, both-invalid fail-closed, restored newest and final protected original-file checks. M56 actual target timing must be measured on z/VM after full strict C89 CI.
