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
