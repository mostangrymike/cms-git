# M201 — Capture an index-derived record plan and invoke M199 automatically

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

**M199's second-object authentication has NOT yet been
provided**. It is the next immediate existing target
gate and must be performed independently of M201:

```text
GITB9 G 3868 1969357 36 8AF5E45B1B905F781D0BFB8A547049494B8D07A2
FILEDEF
LISTFILE GITR199 DATA A (ALLOC
```

Only when the scratch is confirmed absent and the existing
modules are healthy. On a failed or partial scratch,
do not automatically rerun, overwrite or erase it.

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
