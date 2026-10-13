# M201–M205 index-driven Git object verification history

Preserved original CMS runbooks and host-test notes. Current M206 deployment instructions remain separate in docs/M206_STRATIFIED_32.md. The individual original paths remain in Git history.

---

## Original: docs/M201_AUTOMATED_PLAN.md

# M201 — Capture an index-derived record plan and invoke M199 automatically

## October 12, 2026 — M201 CHECK and full automatic SHA: REAL CMS PASS

Actual z/VM 6.3 results:

```text
CMSCLNK GITP21M PLAIN
ASSEMBLER (XF) DONE
NO STATEMENTS FLAGGED IN THIS ASSEMBLY
CMSCLNK: built GITP21M MODULE mode PLAIN
GITP21 G 3868 64 CHECK
M201 INDEX PLAN TUPLE ACCEPTED 3868 1969357 36 3 1148
M201 INDEX EXPECTED OID 8AF5E45B1B905F781D0BFB8A547049494B8D07A2
M201 INDEX ONLY CHECK PASS G 3868
Ready; T=0.63/0.64 13:07:18
FILEDEF
DMSFLD324I No user defined FILEDEFs in effect
STATE GITR199 DATA A
DMSSTT002E File GITR199 DATA A not found
GITP21 G 3868 64
M201 INDEX PLAN TUPLE ACCEPTED 3868 1969357 36 3 1148
M201 INDEX EXPECTED OID 8AF5E45B1B905F781D0BFB8A547049494B8D07A2
M199 BOUNDED ORIGINAL STAGE READ PASS
M199 NEW A SCRATCH TRANSFER PASS
M197 OBJECT 3868 TYPE 3 SIZE 1148 BODY RECORDS 36
M197 VERIFIED OID 8AF5E45B1B905F781D0BFB8A547049494B8D07A2
M197 READ ONLY FULL OBJECT SHA1 PASS
M199 PARAMETERIZED FULL OID PASS G 3868
M201 INDEX AUTOMATED FULL SHA PASS G 3868
Ready; T=0.67/0.68 13:07:44
FILEDEF
DMSFLD324I No user defined FILEDEFs in effect
```

**M201 is now REAL CMS TARGET PASS.** CMS PIPE
successfully captured exactly one compact P201 tuple
from the native C index planner and closed IDXIN.
The CHECK-only mode correctly created no scratch.
Full mode passed the index tuple directly into
M199 and independently authenticated the complete
1,148-byte Git blob with M197 SHA-1.

The original G stage and index remained read-only.
The supplied log ended after a `LISTFILE GITR199
DATA A (ALLOC` invocation without the completed
listing, so do not claim post-run scratch metadata
from that particular output.

Next M202 uses this target-proven module twice
with strict cleanup between successfully verified
objects. See `docs/M202_DUAL_AUTH_CLEAN.md`.
M201's 0.68-second full result is for one object;
it does not replace the 208.27-second full-tree
M188 baseline.

---

## October 12, 2026 — SECOND M199 REAL CMS OID PASS

The operator subsequently ran the M199 standalone bounded
reader against a **different indexed object**, with no
recompile of the target-proven GITBX9 or GITVO7M modules:

```text
GITB9 G 3868 1969357 36 8AF5E45B1B905F781D0BFB8A547049494B8D07A2
DMSSTT002E File GITR199 DATA A not found
M199 DIRECT NATIVE RECORD-BOUNDED READ BEGIN
M199 PARAMETERIZED FSREAD SOURCE BEGIN
M199 BOUNDED ORIGINAL STAGE READ PASS
M199 NEW A SCRATCH TRANSFER PASS
M199 FULL CANONICAL SHA1 VERIFY BEGIN
M197 OBJECT 3868 TYPE 3 SIZE 1148 BODY RECORDS 36
M197 VERIFIED OID 8AF5E45B1B905F781D0BFB8A547049494B8D07A2
M197 READ ONLY FULL OBJECT SHA1 PASS
M199 PARAMETERIZED FULL OID PASS G 3868
Ready; T=0.02/0.03 11:47:45
FILEDEF
DMSFLD324I No user defined FILEDEFs in effect
LISTFILE GITR199 DATA A (ALLOC
GITR199 DATA A1 V 64 37 1
Ready; T=0.01/0.01 11:47:55
```

**M199 is now real-CMS-proven for two different objects:
a 291-byte type-2 tree at record 3,864,789 and a
1,148-byte type-3 blob at record 1,969,357.**
Both independently matched their exact indexed Git SHA1.
The new scratch `GITR199 DATA A1` contains exactly
37 variable records, LRECL64, one 4K block.
The correct standalone `FILEDEF` command reports no
active definitions.

Cleanup is still needed before running M201. The M200
`GITCLN SCRATCH` command only deletes exact verified
disposable A1 names; it will skip the previously removed
GITVRAW and retire the new GITR199 file. Run it only
after verifying FILEDEF is empty and preserving the
successful console transcript, then confirm scratch absent.

A host M201 test initially failed because generated
objects repeated OIDs: the synthetic payload used a
periodic byte sequence plus a periodic size. That
fixture was corrected by prefixing each synthetic
body with its unique physical object number; it is
not evidence of a problem with the real indexed G data
or the target-proven M199 native reader. The complete
CI suite must pass before any M201 merge/target run.

---


## Verified real-CMS prerequisite (October 12, 2026)

M193–M199 have passed their specified real z/VM 6.3 CMS
gates. M199 already fully authenticated a 291-byte Git tree
object number 7736 from caller-supplied absolute record
geometry using native read-only FSREAD, a NEW-only A scratch
and canonical M197 SHA-1 in 0.02s elapsed.

M200 subsequently passed its real CMS cleanup gates.
The existing M199 reader has also now fully authenticated
the separate **1,148-byte blob, object 3868**, with
SHA-1 `8AF5E45B1B905F781D0BFB8A547049494B8D07A2`
and a 37-record disposable A1 scratch. Before running
M201, explicitly clean that known disposable scratch
through M200's `GITCLN SCRATCH`, and check `FILEDEF`
and `STATE GITR199 DATA A` afterward.

Earlier cleanup evidence:

- `FILEDEF` with no operands showed no user-defined definitions.
- `GITCLN SCRATCH` deleted exactly `GITVRAW DATA A1` and
  `GITR199 DATA A1`. Both subsequent STATE commands returned RC28.
- `GITCLN RETIRED` removed the 16 explicitly listed superseded
  probe/module/build files. All reported individual erasures and
  aggregate cleanup returned success, without G file mutations.
- `FILEDEF` afterward again showed no active user definitions.

The second independent index-selected object was measured on
real CMS:

```text
GITRP6 G 3868 64
M196 INDEX TOTAL 7736 UNIQUE 7736
M196 OBJECT 3868 TYPE 3 SIZE 1148 OID 8AF5E45B1B905F781D0BFB8A547049494B8D07A2 O
M196 RECORDS HEADER 1969357 BODY 1969358 LAST 1969393 COUNT 36
M196 STAGE MODEL RECORDS 3864799 EXPECTED 3864799
M196 READ ONLY INDEX OBJECT PLAN PASS
M196 INDEX OBJECT PLAN GATE PASS G 3868
Ready; T=0.63/0.64 11:46:37
```

This is a Git blob, 1,148 bytes, needing 36 body records
and 56 hex characters in the final one. The visible console
line clips at the offset suffix; don't invent that number.

**M199's second-object authentication has now PASSED**,
as independently documented above. The command that
established the success was:

```text
GITB9 G 3868 1969357 36 8AF5E45B1B905F781D0BFB8A547049494B8D07A2
FILEDEF
LISTFILE GITR199 DATA A (ALLOC
```

This run has already succeeded; it must not be
repeated while the resulting scratch exists.
On a failed or partial scratch, do not automatically
rerun, overwrite or erase it.

## Why M201

Today the M196 index planner prints a multi-line
human-readable record plan, and M199 must be invoked with
the manually copied tuple `object header count OID`.
That is an avoidable handoff risk. The existing M199 module
remains protected and target-proven, so M201 adds a
different-stem standalone host-gated index planner plus
a REXX orchestration wrapper, not a replacement.

`src/GITP21M.C` copies the proven read-only PIDX1
validation and index-to-record math from M196 into an
independent strict C89 program. It opens **only**
`dd:IDXIN` for reading, verifies the full 7,736-object
index against the expected 3,864,799 CMS records and
the requested 1..64 record limit, and on success prints
**exactly one** short physical-plan line:

```text
P201 <obj> <header> <count> <type> <size> <40-character-OID>
```

For object 3868 the known expected output is:

```text
P201 3868 1969357 36 3 1148 8AF5E45B1B905F781D0BFB8A547049494B8D07A2
```

This short record is designed to fit entirely within
an 80-column CMS PIPE STEM record, unlike M196's
longer full-offset console line. The new parser never
opens the stage data and never writes the index.

`src/GITP21.EXEC` provides two modes. Start with the
read-only index-capture **CHECK** gate, which does not invoke
M199 or create scratch:

```text
GITP21 G 3868 64 CHECK
```

After CHECK succeeds on actual CMS, use the automatic
complete-SHA mode:

```text
GITP21 G 3868 64
```

It checks the original 4K G disk/stage/index, the
new planner and existing target-proven GITBX9/GITVO7M
modules, refuses a pre-existing GITR199 DATA A,
and refuses caller-owned IDXIN/OBJIN FILEDEFs. It
binds IDXIN read-only, captures

```text
PIPE CMS GITP21M PLAN 3864799 3868 64 | STEM p.
```

and clears IDXIN. It fails closed unless the
capture is **exactly one P201 record** with a matching
object number, valid record geometry, correct 36-record
size arithmetic, valid type and exact 40-character
hex OID. It then invokes the already target-proven
`GITB9 G` wrapper directly, passing the complete
independently computed tuple, and accepts only its
full M197 SHA-1 PASS. It never erases scratch files
and cannot replace the original protected G data.

A key technical uncertainty remains: whether
`PIPE CMS GITP21M ... | STEM p.` reliably captures
C MODULE stdout under real CMS. Earlier M196 avoided
PIPE for native output. The M201 wrapper is **fail-closed
on capture failure** and does not call FSREAD in that
case, so this is safe to test after its host CI.
Host tests do not establish the PIPE/CMS behavior.

`tests/test-m201-plan-export.py` builds the indexer
with strict ISO C89 flags, constructs a full synthetic
7,736-object Git stage and real PIDX1 index, and
validates exact compact OID/record tuples, corrupted
metadata, record limits, SHA256 immutability and wrapper
read-only/ownership restrictions.

## CMS test after CI and merge

Mac, from `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITP21M.C GITP21.EXEC
```

CMS MAINT preflight:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
STATE GITR199 DATA A
FILEDEF
STATE GITBX9 MODULE A
STATE GITVO7M MODULE A
```

The scratch must be absent; if it exists, stop.
Build only the new C program:

```text
CMSCLNK GITP21M PLAIN
STATE GITP21M MODULE A
```

Only if compilation/link succeeds and the existing
reader inputs remain protected, first test native
module output capture without any FSREAD or scratch write:

```text
GITP21 G 3868 64 CHECK
FILEDEF
STATE GITR199 DATA A
```

The CHECK pass requires the one-line P201 tuple,
M201's accepted index plan, and
`M201 INDEX ONLY CHECK PASS G 3868`. Scratch must
remain absent. If CHECK fails, **stop** and do not run
the automatic native reader; retain the exact
console output for diagnosis.

Only if CHECK succeeds with the known M196 tuple:

```text
GITP21 G 3868 64
FILEDEF
LISTFILE GITR199 DATA A (ALLOC
```

Expected compact plan fields are independently
known from the real M196 target proof above. A
complete PASS requires both the accepted M201
plan and the downstream M199/M197 canonical OID
match, not merely a short compact line.

Do not run M201 while M199's preceding second-object
scratch exists. If the distinct M199 verification
passes first, the user can retire that now-proven A1
scratch with `GITCLN SCRATCH` after documenting
the actual successful OID and running FILEDEF.

## Protected state and next evolution

M201 is a host-tested index-to-M199 selector, not yet
a real target PASS, and not a full authenticated
280-object tree closure or a performance comparison.
The long-term target is automatically selecting a
set of reachable objects and computing independent
SHA-1s without M188's two full 3.86-million-record
scans. M188's proven full closure remains
205.04s CPU / 208.27s elapsed.

Do not overwrite or erase M173NET STAGE G,
M174NET INDEX G, GIT600, working M196/M197/M199
modules or protected generation files. No GIT600
format/reimport/reindex, no physically overlapping
PMAINT 0141 write-link, and no M190 272-seek walk.


---

## Original: docs/M202_DUAL_AUTH_CLEAN.md

# M202 — Two distinct Git objects with automatic post-SHA cleanup

## Actual z/VM 6.3 CMS M201 proof, October 12, 2026

The user completed the full M201 validation on IBM z/VM CMS.
`GITCLN SCRATCH` first erased the previously authenticated
`GITR199 DATA A1`, while skipping the already absent
`GITVRAW DATA A1`. The two-file scratch cleanup passed.
CMS `FILEDEF` showed no active definitions before and after.

`CMSCLNK GITP21M PLAIN` built with no statements flagged.
`GITP21 G 3868 64 CHECK` then captured the native C
index output through CMS PIPE/STEM, parsed the expected
object tuple and passed **without creating scratch**:

```text
M201 INDEX PLAN TUPLE ACCEPTED 3868 1969357 36 3 1148
M201 INDEX EXPECTED OID 8AF5E45B1B905F781D0BFB8A547049494B8D07A2
M201 INDEX ONLY CHECK PASS G 3868
Ready; T=0.63/0.64 13:07:18
```

The subsequent `GITP21 G 3868 64` independently
recomputed its validated 7,736-object indexed plan,
passed the exact tuple to the target-proven M199
native FSREAD reader, and computed complete canonical
SHA-1 using M197:

```text
M201 INDEX PLAN TUPLE ACCEPTED 3868 1969357 36 3 1148
M201 INDEX EXPECTED OID 8AF5E45B1B905F781D0BFB8A547049494B8D07A2
M199 BOUNDED ORIGINAL STAGE READ PASS
M199 NEW A SCRATCH TRANSFER PASS
M197 OBJECT 3868 TYPE 3 SIZE 1148 BODY RECORDS 36
M197 VERIFIED OID 8AF5E45B1B905F781D0BFB8A547049494B8D07A2
M197 READ ONLY FULL OBJECT SHA1 PASS
M199 PARAMETERIZED FULL OID PASS G 3868
M201 INDEX AUTOMATED FULL SHA PASS G 3868
Ready; T=0.67/0.68 13:07:44
```

A final `FILEDEF` showed no active user-defined
definitions. The subsequent `LISTFILE GITR199 DATA A
(ALLOC` command is visible, but its full output is **not
included** in the submitted transcript. A new scratch
was necessarily created by the M199 NEW-only stage,
but do not infer the final directory display.

**M201 is REAL CMS TARGET PASS** for automatic full
index-to-original-FSREAD-to-Git-SHA verification,
with no manual header, body count, type, size or OID
handoff. The observed elapsed time was 0.68 seconds
for one object (including complete index validation).
This is not yet a 280-object closure speed comparison.

## Why M202

M201 verifies one object, leaving a disposable scratch
`GITR199 DATA A1`. The user explicitly requests
cleanup of unnecessary test files and obsolete modules
as the project advances.

M202 is a separate, narrow `src/GITC22.EXEC` that
checks **exactly two different index-selected objects**
before performing full SHA1 verification of each.
It does not alter M201, M199, M197, the original G
stage/index, or any other target-proven module.

Usage:

```text
GITC22 G object1 object2 max-body CHECK
GITC22 G object1 object2 max-body RUN
```

Only distinct object numbers 1..7736 and a body
record limit 1..64 are permitted. Any other form
fails RC4. The initial real-CMS test tuple uses
two independently proven objects:

```text
object 3868: TYPE3 BLOB SIZE1148, BODY36,
 OID 8AF5E45B1B905F781D0BFB8A547049494B8D07A2
object 7736: TYPE2 TREE SIZE291, BODY10,
 OID 9069E154EB145C25D8E1A8D31F72252C53E6684A
```

The wrapper first checks the required M201,
M199, M197 and M200 modules and EXECs.
It refuses any existing `GITVRAW DATA A` or
`GITR199 DATA A`; the former is the retired
M198 scratch, and cleanup must never delete
an unexpected pre-existing file. It also refuses
caller-owned OBJIN and IDXIN FILEDEF conflicts.

Before creating any scratch, it runs:

```text
GITP21 G 3868 64 CHECK
GITP21 G 7736 64 CHECK
```

Both index plans must independently pass. In CHECK
mode, the wrapper returns only after those checks:
**no FSREAD, no new scratch, no ERASE**.

In RUN mode, it invokes the fully proven
`GITP21 G 3868 64` and requires its RC0,
including the internal complete canonical Git SHA.
Only after the full SHA success does it invoke
`GITCLN SCRATCH` to remove the disposable
`GITR199 DATA A1` and verify it is absent.
Then it similarly authenticates object 7736,
cleans its new scratch, and returns overall PASS.

This is an explicit, bounded, two-object integration
test. It does not use generic wildcard ERASE,
replace a scratch file, reindex, write the original G,
or leave successful disposable files behind.

### Failure and evidence rules

If either index CHECK fails, the full RUN mode stops
before creating a scratch. If a native read,
object SHA comparison, or command fails, it
immediately stops **without cleanup**, leaving
any failed/partial scratch for diagnosis.
If cleanup fails, it stops and refuses the next
object. On successful SHA and cleanup, each
object's PASS markers are still in the console
transcript, while the temporary scratch is gone.

As in prior milestones, the new wrapper is **host
tested only until a real CMS invocation passes**.
Host CI tests bounded input and file ownership
checks, exact ordering, and representative failure
sequences that preserve scratch and halt advancement.
No claim is made for multi-object real-CMS throughput
before the target test.

## Safe real-CMS gate after merging

Mac, from `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITC22.EXEC
```

CMS MAINT read-only checks:

```text
FILEDEF
STATE GITR199 DATA A
STATE GITVRAW DATA A
STATE GITP21 EXEC A
STATE GITP21M MODULE A
STATE GITBX9 MODULE A
STATE GITVO7M MODULE A
STATE GITCLN EXEC A
```

The user must first clean the successful M201
scratch when it exists. Confirm FILEDEF is empty:

```text
GITCLN SCRATCH
STATE GITR199 DATA A
FILEDEF
```

Only after both scratch files are confirmed absent
and all component STATE checks pass, test M202's
CHECK-only mode:

```text
GITC22 G 3868 7736 64 CHECK
FILEDEF
STATE GITR199 DATA A
```

Expected:

```text
M202 TWO OBJECT INDEX PREFLIGHT PASS 3868 7736
M202 TWO OBJECT CHECK ONLY PASS
```

No scratch should exist. Only on CHECK PASS,
attempt RUN exactly once:

```text
GITC22 G 3868 7736 64 RUN
FILEDEF
STATE GITR199 DATA A
```

Expected ordered end markers:

```text
M202 FULL OBJECT SHA VERIFIED 3868
M200 CLEANUP PASS SCRATCH
M202 SCRATCH CLEAN VERIFIED 3868
M202 FULL OBJECT SHA VERIFIED 7736
M200 CLEANUP PASS SCRATCH
M202 SCRATCH CLEAN VERIFIED 7736
M202 TWO OBJECT FULL SHA CLEAN PASS 3868 7736
```

Each run still needs complete internal M201, M199
and M197 SHA PASS outputs for each object.
Record actual CPU/elapsed for two index reads
and two full SHA object validations. Failure
preserves diagnostic scratch without an automatic
retry or overwrite.

The M188 authenticated full 280-object reachable
closure baseline (205.04 CPU / 208.27 elapsed seconds)
remains unchanged. M202 does not replace it or
establish full traversal performance.


---

## Original: docs/M203_BATCH_AUTH.md

# M203 — Bounded 2–8-object automatic Git SHA verification

## Target-proven prerequisite: M202 real CMS PASS, October 12, 2026

The user completed the M202 CHECK and RUN gates on z/VM 6.3.
CHECK verified the M201 index plans for objects 3868 and
7736 without creating a scratch file, elapsed 1.28s.

RUN independently rechecked both index plans, then read and
authenticated both objects through the existing
M201 → M199 → M197 chain. After each successful SHA-1,
GITCLN SCRATCH erased the newly created GITR199 DATA A1
and M202 confirmed its absence.

The actual RUN ended:

```text
M202 FULL OBJECT SHA VERIFIED 3868
M200 CLEANUP PASS SCRATCH
M202 SCRATCH CLEAN VERIFIED 3868
M202 FULL OBJECT SHA VERIFIED 7736
M200 CLEANUP PASS SCRATCH
M202 SCRATCH CLEAN VERIFIED 7736
M202 TWO OBJECT FULL SHA CLEAN PASS 3868 7736
Ready; T=2.59/2.67 13:18:06
```

The two indexed identities are:

- Object 3868: Git blob, 1148 bytes, OID
  8AF5E45B1B905F781D0BFB8A547049494B8D07A2;
  header record 1969357; 36 body records.
- Object 7736: Git tree, 291 bytes, OID
  9069E154EB145C25D8E1A8D31F72252C53E6684A;
  header record 3864789; ten body records.

Console output around a MORE prompt was interleaved with
earlier commands, but the complete terminal PASS proves
both SHA checks and both cleanups. No post-RUN FILEDEF or
STATE output was provided independently, though M202
verified scratch absence after each cleanup.

## M203 independent multi-object EXEC

New `src/GITC23.EXEC` expands the number of distinct
objects to **2 through 8**, without editing M201, M199,
M197, M200 or M202. It accepts:

```text
GITC23 G CHECK max-body obj1 obj2 ... obj8
GITC23 G RUN   max-body obj1 obj2 ... obj8
```

The limit is 1..64 body records for each object.
Every object number must be 1..7736, numeric and
distinct. No accidental repeated object numbers.
The checker requires existing, target-proven M201,
M199, M197 and M200 modules/EXECs and refuses a
pre-existing GITVRAW or GITR199 scratch on A.
It also refuses caller IDXIN/OBJIN FILEDEF conflicts.

All objects are checked with `GITP21 G object limit CHECK`
before RUN mode may create any scratch. CHECK mode
only verifies their independently indexed record
geometry, OIDs, sizes and bounded record counts.

RUN mode then loops over the selected objects in order:
for each it invokes target-proven `GITP21 G object limit`,
which retrieves through read-only native FSREAD and
requires complete M197 canonical SHA-1/OID. Only after
that PASS does it invoke target-proven `GITCLN SCRATCH`,
verify scratch absence and advance. On SHA failure the
scratch is preserved for diagnosis. On cleanup failure
the batch stops. No overwrites, G writes, wildcard
cleanup or replacements of proven native modules.

Host test `tests/test-m203-bounded-batch.py` validates
the source-level guards, batch sizes, duplicate refusal,
all-index-checks-before-any-SHA ordering and fail-closed
failure sequences. **M203 is host-only until target
CHECK and RUN results are actually supplied.**

## Next real CMS test after CI/merge

From Mac `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITC23.EXEC
```

On CMS, verify A1 scratch and FILEDEF state:

```text
FILEDEF
STATE GITR199 DATA A
STATE GITVRAW DATA A
STATE GITC23 EXEC A
```

The scratch files must be absent; no cleanup is required
if they are already absent. M202's successful cleanup
indicates that they should be absent, but verify.

First test exactly the two index-selected, independently
SHA-proven objects using the new batch parser:

```text
GITC23 G CHECK 64 3868 7736
FILEDEF
STATE GITR199 DATA A
```

Require `M203 ALL INDEX CHECKS PASS 2` and
`M203 CHECK ONLY NO SCRATCH PASS 2`; no file
should be created. Only after success:

```text
GITC23 G RUN 64 3868 7736
FILEDEF
STATE GITR199 DATA A
```

Require separate complete M201/M199/M197 SHA-1 PASS
for both objects, M200 cleanup PASS after each,
and final `M203 BOUNDED FULL SHA CLEAN PASS 2`.
If anything fails, stop without retries or automatic
deletion of unverified scratch.

After the two-object parser gate passes, select a
third, distinct object with `GITP21 G object 64 CHECK`
to establish its actual indexed size and bounded
record count before any 3-object RUN. Do not
guess an OID or claim an untested third-object pass.

## Future direction

The next optimization is reducing per-object repeated
full 7,736-entry index validation while preserving
the successful M201/M199/M197 SHA and fail-closed
source protection. M188 remains the target-proven
authenticated complete 280-object closure baseline
at 205.04s CPU and 208.27s elapsed.

Never alter protected M173NET STAGE G1, M174NET INDEX G1,
or the GIT600 original, and never rerun the M190
272-seek experimental benchmark or write-link the
overlapping PMAINT 0141.


---

## Original: docs/M204_INDEX_ONCE_BATCH.md

# M204 — Verify index once, authenticate bounded batch

## Real CMS foundation, October 12, 2026

The operator completed real M203 z/VM 6.3 tests with
objects 3868 and 7736. CHECK mode passed in 1.32s.
RUN mode passed full SHA-1/OID verification for both
objects, cleaning `GITR199 DATA A1` after each:
```text
M203 FULL OBJECT SHA VERIFIED 1 3868
M203 CLEAN VERIFIED 1 3868
M203 FULL OBJECT SHA VERIFIED 2 7736
M203 CLEAN VERIFIED 2 7736
M203 BOUNDED FULL SHA CLEAN PASS 2
Ready; T=2.58/2.67 13:31:15
```
The operator output is interleaved around a CMS screen
pause, but all verified OIDs, SHA passes, and cleanup
markers appear. M203 is REAL CMS TARGET PASS for a
two-object batch only. The final independent
`FILEDEF` and `STATE` results were not supplied.

The two verified objects remain:
- 3868, blob TYPE3, SIZE1148, HEADER1969357,
  BODY36, OID 8AF5E45B1B905F781D0BFB8A547049494B8D07A2
- 7736, tree TYPE2, SIZE291, HEADER3864789,
  BODY10, OID 9069E154EB145C25D8E1A8D31F72252C53E6684A

## Bottleneck addressed

M203 currently calls M201 `GITP21 G n 64 CHECK`
for every selected object and again calls M201 for
the full object. Each invocation rereads, validates
and traverses all 7,736 PIDX1 entries, despite only
needing a distinct header/count/OID tuple.

M204 adds **separate** `src/GITP24M.C` and
`src/GITC24.EXEC`, leaving the real-CMS-proven
M196–M203 native programs and EXECs unchanged.

`GITP24M` is a strict ISO C89 read-only planner.
It uses the proven PIDX1 parser and validates the
whole index once, including all 7,736 object numbers,
sorted OIDs, unique objects, monotonic physical
offsets and 3,864,799 original stage record count.
It computes record numbers for all objects in one
pass. It checks every selected object against
nonempty body, 2,048-byte upper limit and 1..64
body records before publishing **any** plans.

On success, it emits one compact `P201` plan line
per requested object, in request order:

```text
P201 3868 1969357 36 3 1148 8AF5E45B1B905F781D0BFB8A547049494B8D07A2
P201 7736 3864789 10 2 291 9069E154EB145C25D8E1A8D31F72252C53E6684A
```

These 2 lines are each shorter than CMS's
80-character console/PIPE record width. No partial
P201 success lines are emitted on index failure.

`GITC24.EXEC` syntax:

```text
GITC24 G CHECK 64 3868 7736
GITC24 G RUN 64 3868 7736
```

It accepts 2..8 **distinct** object numbers 1..7736
and a body bound 1..64. It preflights original G
stage/index, distinct native planner and already
target-proven M199/M197 modules, and refuses an
existing `GITVRAW DATA A` or `GITR199 DATA A`.
It refuses caller-owned IDXIN or OBJIN filedefs,
temporarily binds IDXIN, captures one PIPE from
GITP24M into STEM, then **clears IDXIN** before
any FSREAD. The wrapper requires the exact number
of P201 records, correct input ordering, all sizes,
record bounds/types and exact 40-hex OIDs. It
also checks the scratch is still absent.

CHECK mode returns after index-only validation;
it creates no file. RUN calls the target-proven
M199 `GITB9 G object header count OID` for each
tuple, which independently retrieves native FSREAD
and verifies complete canonical Git SHA1 against the
index OID using M197. **Only after that SHA PASS**
does M204 invoke target-proven M200 exact A-scratch
cleanup and confirm absence. On any failure it
stops, does not retry or erase a partial scratch.

The optimization is ONLY the one-time PIDX1 scan
and plan capture. The expensive/critical verification
of the actual bytes remains identical to M199/M197.
This does not yet establish authenticated reachability
or a replacement for the M188 full 280-object closure.

Host CI builds GITP24M with GCC strict C89 and
constructs a synthetic unique 7,736-object PIDX1.
It tests 2-, 3-, and 8-object batches; exact plans,
wrong stage count, duplicate/out-of-range objects,
limit violations, no partial success output and
index immutability. CMS PIPE and sequential scratch
cleanup remain **target pending**.

## First real CMS gate after host CI and merge

Mac from `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITP24M.C GITC24.EXEC
```

On CMS MAINT:

```text
FILEDEF
STATE GITR199 DATA A
STATE GITVRAW DATA A
STATE M173NET STAGE G
STATE M174NET INDEX G
CMSCLNK GITP24M PLAIN
STATE GITP24M MODULE A
```

The two scratch files MUST be absent. Stop if
either exists unexpectedly; do not overwrite.

CHECK-only, no scratch:

```text
GITC24 G CHECK 64 3868 7736
FILEDEF
STATE GITR199 DATA A
```

Required: the exact two P201 tuples above,
`M204 INDEX ONCE ALL PLANS PASS 2` and
`M204 CHECK ONLY NO SCRATCH PASS 2`. If CHECK
fails, STOP. No full RUN or scratch writes.

Only after CHECK passes:

```text
GITC24 G RUN 64 3868 7736
FILEDEF
STATE GITR199 DATA A
```

Required: independent full M197 canonical SHA1 PASS
for both objects, two M204 FULL SHA VERIFIED markers,
two M200 CLEANUP PASS SCRATCH markers, two M204 SCRATCH
CLEAN VERIFIED markers, terminal
`M204 ONE INDEX FULL SHA CLEAN PASS 2`.

Record CPU/elapsed. Compare to M203 2.67s elapsed
for two objects; a speedup is a hypothesis, not
a claim until measured and test cases are equivalent.

Never modify original `M173NET STAGE G1`,
`M174NET INDEX G1`, GIT600 or the target-proven
M188 full closure. No reimport/reindex, G format,
overlapping PMAINT 0141 write-link or M190 272-seek.


---

## Original: docs/M205_STRATIFIED_AUTH.md

# M205 — Stratified Git object authentication across the entire index

## October 12, 2026 — M204 real CMS index-once PASS

The operator compiled `GITP24M MODULE` with no assembler
errors and verified the first index-once multi-object batch:

```text
GITC24 G CHECK 64 3868 7736
M204 INDEX TUPLE VERIFIED 1 3868 1969357 36 3 1148
M204 EXPECTED OID 1 8AF5E45B1B905F781D0BFB8A547049494B8D07A2
M204 INDEX TUPLE VERIFIED 2 7736 3864789 10 2 291
M204 EXPECTED OID 2 9069E154EB145C25D8E1A8D31F72252C53E6684A
M204 INDEX ONCE ALL PLANS PASS 2
M204 CHECK ONLY NO SCRATCH PASS 2
Ready; T=0.62/0.64 13:46:04
```

Full native stage FSREAD and complete M197 SHA-1:

```text
GITC24 G RUN 64 3868 7736
M197 OBJECT 3868 TYPE 3 SIZE 1148 BODY RECORDS 36
M197 VERIFIED OID 8AF5E45B1B905F781D0BFB8A547049494B8D07A2
M197 READ ONLY FULL OBJECT SHA1 PASS
M204 FULL SHA VERIFIED 1 3868
M200 CLEANUP PASS SCRATCH
M204 SCRATCH CLEAN VERIFIED 1 3868
M197 OBJECT 7736 TYPE 2 SIZE 291 BODY RECORDS 10
M197 VERIFIED OID 9069E154EB145C25D8E1A8D31F72252C53E6684A
M197 READ ONLY FULL OBJECT SHA1 PASS
M204 FULL SHA VERIFIED 2 7736
M200 CLEANUP PASS SCRATCH
M204 SCRATCH CLEAN VERIFIED 2 7736
M204 ONE INDEX FULL SHA CLEAN PASS 2
Ready; T=0.67/0.72 13:46:38
```

**M204 is real-CMS proven for two objects**, with CHECK
elapsed 0.64s and full RUN elapsed 0.72s. The preceding
equivalent M203 two-object run took 2.67s, so the new
single index validation reduced measured elapsed time
by roughly 73% (approximately 3.7x). Those measurements
refer to the *same two individually authenticated objects*,
not the M188 full reachable tree closure.

Independent final `FILEDEF` and `STATE` output after M204
RUN was not supplied. M204's own cleanup checks succeeded
after each object, so new tests must confirm scratch is
absent before proceeding.

## M205 — extend beyond the same two known objects

Previously, we selected objects 3868 and 7736 because
their exact OIDs/record spans were already known. M205
selects objects **automatically across distinct regions**
of the original 7,736-object Git index, without manually
specifying their numbers or inventing their identities.

New `src/GITP25M.C` reuses the proven read-only PIDX1
parser, validates all indexed object ordinals, sorted
40-hex Git OIDs, offsets, and physical stage-record model
of exactly **3,864,799 records**, and computes all header
and body positions once.

For requested sample count 2 through 8, divide the object
ordinal range into equal-sized, nonoverlapping bands.
For each band in order, select its first indexed object
whose decoded size is **1–2048 bytes** and whose body
requires no more than the caller's **1–64** record limit.

Examples: an 8-object sample spans eight different ordinal
bands; this is deliberately not just eight neighboring
entries. Source selection is deterministic, but the actual
sampled numbers, types and OIDs MUST come from the real
index output. Do not infer or fabricate their values.

If any band has no eligible object, fail RC8 and emit
**no P201 success plans**. No zero-byte or oversized object
is passed into M199. All eligible selections and stage
bounds are verified before publishing any records.

On success, it writes exactly N short CMS PIPE lines,
one per band, in ascending ordinal order:

```text
P201 <obj> <header-recno> <body-count> <type> <size> <40-hex-OID>
```

New `src/GITC25.EXEC` syntax:

```text
GITC25 G CHECK 64 8
GITC25 G RUN 64 8
```

It confirms original G is a 4K CMS disk, original stage
and index exist, native planner and target-proven
M199/M197/M200 components exist, and no caller OBJIN/
IDXIN FILEDEF collision or pre-existing scratch remains.
It binds only read-only IDXIN temporarily; CMS PIPE
captures the exactly N planner records, then IDXIN
is cleared regardless of planner return code.

The wrapper strictly checks each tuple's band membership,
physical record geometry, type, size, body count and
40-character OID. CHECK mode creates **no scratch**.

Only after all N plans are checked does RUN call the
already target-proven `GITB9 G object header count OID`
for each. That module reads the original protected G
stage with native FSREAD to **NEW-only disposable A scratch**
and independently authenticates full canonical Git SHA-1
against the indexed OID. Only after SHA succeeds does
the wrapper call `GITCLN SCRATCH`; it checks the scratch
has been removed before advancing.

On stage read error, malformed hex, wrong SHA or cleanup
failure the batch halts, with no retry and no erasure of
potentially untrusted scratch. It does not modify G,
M188, M193–M204, or any previous successful module.

**Important non-goal:** a stratified sample is a
coverage test across many physical record regions;
it is not a reachable Git history traversal. It is
not equivalent to the M188 280-object full closure
and must not be described as such.

## Host tests

`tests/test-m205-stratified-sample.py` compiles
the new planner, the strict C89 PIDX1 builder
and target-proven M197 SHA verification core.
It constructs a 7,736-object synthetic index
with unique Git OIDs, tests 2/3/8 selected bands,
checks every exact calculated record span and
SHA, validates no partial P201 on error/empty bands,
and checks source index/stage immutability.

Host tests do not exercise real IBM CMS PIPE,
native FSREAD or scratch cleanup. M205 is therefore
**host-only until the real target gates pass**.

## Real CMS validation after full host CI and merge

Mac from `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITP25M.C GITC25.EXEC
```

CMS preflight:

```text
FILEDEF
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
STATE GITR199 DATA A
STATE GITVRAW DATA A
CMSCLNK GITP25M PLAIN
STATE GITP25M MODULE A
```

**Both scratch files must be absent**, and the native
module must build with no flagged statements. Stop
rather than overwrite or erase unexpected scratch.

CHECK-only with eight distributed selections:

```text
GITC25 G CHECK 64 8
FILEDEF
STATE GITR199 DATA A
```

Expect exactly eight `M205 BAND OBJECT VERIFIED` and
`M205 EXPECTED OID` lines, with eight different objects
from distinct bands; and the terminal result:

```text
M205 STRATIFIED INDEX PLANS PASS 8
M205 SAMPLE CHECK NO SCRATCH PASS 8
```

No scratch must exist after CHECK. If the sample is
rejected due to a band lacking an eligible object,
**stop** and inspect the output; do not invent
another object OID or bypass the bounds.

Only after clean CHECK success, run:

```text
GITC25 G RUN 64 8
FILEDEF
STATE GITR199 DATA A
```

For all eight objects require complete M197 canonical
Git SHA1 PASS and individual `M205 FULL SHA VERIFIED`
plus `M205 SCRATCH CLEAN VERIFIED` markers.
Only then does the terminal

```text
M205 STRATIFIED FULL SHA CLEAN PASS 8
```

constitute actual M205 proof. Record both CMS CPU and
elapsed times. The full eight-object run is **not**
directly equivalent to M204's two-object 0.72s or
M188's complete 280-object 208.27s timings.

Keep protected `M173NET STAGE G1` and
`M174NET INDEX G1` unchanged. Do not alter or
write-link the overlapping PMAINT 0141, format
GIT600, reimport/reindex the stage, or run the
M190 multi-seek experiment.

