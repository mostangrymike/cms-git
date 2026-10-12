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
