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
