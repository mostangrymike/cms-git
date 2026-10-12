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
