# M177–M178 Historical Pack Access and Forward-Tree Plans

Both milestone notes are retained in full. Original paths remain in Git history.

---

## Original docs/M177_READONLY_PACK_ACCESS_PLAN.md

# M177 — explicit, read-only PACK access to verified CMS G repository

## 2026-10-09 15:51:13 CDT — M177 INFO, TREE, FILEDEF and M175 standalone ALL LIVE PASS

Actual CMS MAINT:
`QUERY FILEDEF` before M177 INFO at 15:46:33:
`No user defined FILEDEF in effect`.
`GITPVIEW INFO G ADA83FF3B3813961CEF2A9FFC50A453540039E0B`
returned `PACKOBJ OBJ 7000 TYPE 1 SIZE 265`,
root `CCB18BEC067E7886D70B82EF138EE56A8B899A61`,
parent `B81D3CE7BAC08420BF7DB862E93F82FB3968DDC0`,
`PACKOBJ INDEX TOTAL 7736 UNIQUE 7736`,
`M175 PACK INFO PASS`, and
`M177 PACK VIEW INFO PASS
ADA83FF3B3813961CEF2A9FFC50A453540039E0B G`,
Ready RC0 T=40.39/41.52 at 15:47:16.
Follow-up `QUERY FILEDEF` at 15:48:54:
`No user defined FILEDEF in effect`, exactly
matching the initial query. This proves the
positive path does not leak STGIN/IDXIN DDs
on actual CMS. It does **not** test the
already-defined DD conflict negative path.

Standalone `M175CHK G` completed at 15:51:13:
`M175 MAIN COMMIT VERIFIED` at tip OID,
`M175 ROOT TREE VERIFIED` at root OID
(OBJ7197 TYPE2 SIZE291),
`M175 PARENT VERIFIED 1` at parent OID
(OBJ7001 TYPE1 SIZE264), and
`M175 LIVE COMMIT TREE CLOSURE PASS`,
`M175 VERIFIED RANDOM ACCESS TARGET GATE PASS`,
Ready RC0 T=121.27/124.65.
The parent has its own tree
`8B7134918D12ED07D60E3CB28A1803EBCA7DB65B`
and parent `550C982759DC6685A13B59AE2D91D3A54F6D8496`.

**M177 positive-path INFO and TREE, plus M175 full
standalone checker, are now real CMS verified.**
M177 TREE was already verified at 15:32:00
with 8 trees, 272 blobs, 0 gitlinks, 279 entries,
280 verified and 7736 unique index. No repeated
index builds or PACK reimports necessary.

Next feature development M178 read-only performance
improvement described in
`docs/M178_PACK_TREE_PERFORMANCE_PLAN.md`.
Do not overwrite G stage/index or change working
GITPTRE/GITPCAT/GITPVIEW as part of experimentation.

---


## 2026-10-09 15:32 CDT — M177 TREE ACTUAL z/VM 6.3 TARGET PASS

The user ran the isolated `GITPVIEW TREE G`
command against the retained G stage and index.
Actual CMS output:

```text
GITPVIEW TREE G CCB18BEC067E7886D70B82EF138EE56A8B899A61
TREE CLOSURE ROOT CCB18BEC067E7886D70B82EF138EE56A8B899A61
TREE CLOSURE TREES 8 BLOBS 272 GITLINKS 0
TREE CLOSURE ENTRIES 279 VERIFIED 280
TREE CLOSURE MAX OBJECT 393767 RESIDENT PEAK 394058
TREE CLOSURE INDEX TOTAL 7736 UNIQUE 7736
M176 TREE CLOSURE PASS
M177 PACK VIEW TREE PASS CCB18BEC067E7886D70B82EF138EE56A8B899A61 G
Ready; T=*.**/*.** 15:32:00
```

**TREE mode is now LIVE TARGET VERIFIED**: the
new wrapper used the existing native GITPTRE
to authenticate the same 8-tree/272-blob root
closure as M176, indexed across 7736 objects,
with all expected output markers.

**Do not yet label the entire M177 suite
target verified.** No separate M177 `INFO`
terminal output, full standalone M175CHK G
result, or before/after CMS `QUERY FILEDEF`
state comparison has been supplied. The
source wrapper attempts to safeguard existing
DD bindings; the successful TREE query does
not by itself demonstrate every negative
branch or unchanged preexisting FILEDEFs.

Immediately useful remaining read-only checks:

```text
QUERY FILEDEF
GITPVIEW INFO G ADA83FF3B3813961CEF2A9FFC50A453540039E0B
QUERY FILEDEF
M175CHK G
```

Run M175 only if its full terminal PASS has
not already been observed. Expect `M177 PACK
VIEW INFO PASS` and `M175 VERIFIED RANDOM
ACCESS TARGET GATE PASS` respectively.
Never rerun M173/M174 or reformat G.

**Performance warning:** Prior CMS Ready
was shown at 13:28:51; TREE Ready
at 15:32:00. The gap is about 2h03m09s
between displayed terminal timestamps,
not a certified CPU or elapsed time for
the TREE command. `T=*.**/*.**`
overflowed. The current native GITPTRE
uses per-object file seeks into a very
large variable-record CMS G stage.
A sequential scan could reduce costly
random access, but no performance
diagnosis or optimization has been
measured yet; do not present this as
a proven bottleneck.

---


## Implemented source checkpoint — October 9, 2026

Added `src/GITPVIEW.EXEC`, a new 8-character CMS name,
without changing existing `GIT.EXEC`, `GITVREF.EXEC`
or native C modules. A corresponding
`tests/test-m177-pack-view.py` source guard runs in
the native-stage GitHub workflow. **Host proof is
not actual CMS validation.**

The EXEC checks an explicit non-A filemode
accessed with 4096-byte blocks, both retained
M173 stage/M174 index files, and the needed
existing native GITPCAT/GITPTRE module on A.
It checks the complete CMS `QUERY FILEDEF`
listing before binding inputs: any preexisting
STGIN or IDXIN causes refusal, with **no
replacement** of the caller's DD assignment.
The wrapper binds only its own two read-only
inputs and clears only its own definitions
after the native call. It requires both
native terminal PASS and exact request-OID
match. It performs no import, build,
directory update, CMS FORMAT or ERASE.
The z/VM 6.3 details of `QUERY FILEDEF`
remain to be proven at the actual target.

**Next target smoke-check**, only after
confirming the existing 7,736-object stage
and index remain intact and there is no
session FILEDEF conflict. On the Mac from
`ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITPVIEW.EXEC
```

On CMS MAINT:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
STATE GITPVIEW EXEC A
QUERY FILEDEF
GITPVIEW INFO G ADA83FF3B3813961CEF2A9FFC50A453540039E0B
GITPVIEW TREE G CCB18BEC067E7886D70B82EF138EE56A8B899A61
QUERY FILEDEF
```

The before/after FILEDEF queries must have
identical state. If either DD was defined
beforehand, **do not clear it**; wrapper is
designed to fail closed. INFO should print
`M175 PACK INFO PASS` and
`M177 PACK VIEW INFO PASS`; TREE should
print `M176 TREE CLOSURE PASS` and
`M177 PACK VIEW TREE PASS`, verifying
the same 8-tree/272-blob/280-verified
closure as the live M176 run. Stop on
unexpected RC or mismatched output, and
preserve the stage/index. A standalone
`M175CHK G` full PASS is still a distinct
milestone check if not already performed.

Official IBM CMS:
https://www.ibm.com/docs/en/zvm/7.3.0?topic=gc-query-filedef
https://www.ibm.com/docs/en/zvm/7.2?topic=commands-filedef

---


**Status: M177 INFO + TREE live CMS PASS; FILEDEF positive-path hygiene verified.**
Prepared October 9, 2026 after actual M173, M174 and
M176 G-stage/index target PASS (`M176 LIVE ROOT TREE CLOSURE TARGET GATE PASS`). The standalone M175CHK G
terminal result was not supplied with the M176 output.

## Verified baseline

- z/VM 6.3 CMS MAINT on Hercules; GCCCMS C compiler and
  CMS XF assembler operational. Use the existing C-first
  toolchain; do not recreate the verified M173 stage/index.
- New GIT600 CMS disk: MAINT vdev0600 3390 R/W 1600 CYL
  with 4096B blocksize, VMCOM1 real0127 start6000.
- Retained original M171NET PACK/META A:
  7736 objects, version2, 2171129 bytes,
  SHA1 A705122BC39A3383BC05ABC6C888A1F788B1D067.
- M173NET STAGE G: actual M173 independent READBACK PASS.
- M174NET INDEX G: 7736 unique OIDs, index audit and
  commit GET PASS.
- Live tip commit:
  ADA83FF3B3813961CEF2A9FFC50A453540039E0B,
  OBJ7000, type1, size265, parent
  B81D3CE7BAC08420BF7DB862E93F82FB3968DDC0.
- M176 root:
  CCB18BEC067E7886D70B82EF138EE56A8B899A61;
  full root closure 8 tree, 272 blob, 0 gitlinks,
  279 entries, 280 verified objects.
  Largest decoded object 393767B, resident peak 394058B.
- `GITPCAT MODULE` and `GITPTRE MODULE` were used
  successfully by M176. Its internal M175 PACK INFO PASS
  is **not** sufficient evidence of standalone M175CHK G.

## Problem to solve

The higher-level GIT EXEC already dispatches
`GIT PACK-CAT <40-hex-oid>` to GITPCAT and
`GIT PACK-TREE <40-hex-tree-oid>` to GITPTRE.
Native modules use the DDnames STGIN and IDXIN,
currently provided by the M175/M176 test checkers
through explicit `FILEDEF` setup/cleanup.
For everyday Git use, a caller should be able to
choose an existing non-A CMS filemode explicitly,
bind the verified stage/index without manually
recreating those FILEDEFs, and view one object/tree.
Do not silently choose A, overwrite any output
files, or alter a user's session FILEDEF state.

## Suggested M177 user-visible interface

One new short CMS REXX name, e.g. `GITPVIEW EXEC`
(8-character name). Proposed commands only:

```text
GITPVIEW INFO G ADA83FF3B3813961CEF2A9FFC50A453540039E0B
GITPVIEW TREE G CCB18BEC067E7886D70B82EF138EE56A8B899A61
```

Validate exact argument count, explicit single-letter
data filemode other than A, 40 uppercase hex OID,
and an accessed 4096-byte CMS disk.
Require existing `M173NET STAGE <mode>` and
`M174NET INDEX <mode>` with STATE RC0.
Do not create or update either protected file.
INFO must require expected type1 for a requested
commit in its target regression; TREE checks
native root/descendant walk and its own proof
marker.

The REXX wrapper should invoke only the native
read paths (`GITPCAT INFO`, `GITPTRE WALK`),
with bounded/checked pipeline results and
RC propagation. Do not copy object text to A,
modify Git refs, or run M173/M174.
The wrapper must **not** clobber preexisting
STGIN or IDXIN FILEDEFs: establish and test
the exact IBM CMS QUERY FILEDEF behavior on
the actual installed release first. If either
DD is already defined, fail closed without
rebinding or clearing it; otherwise bind
both, invoke, and clear only the bindings it
created, including all error paths.
Do not change global FILEDEF state in the
absence of a reliable preexisting-binding check.
If this check cannot be proven, prefer a
documented manual command sequence over an
unsafe wrapper. Avoid modifying GIT/GITVREF
until the isolated wrapper passes host tests
and real CMS validation.

Host tests: argument validation; unsafe filenames,
wrong mode, wrong OID, missing stage/index,
already-bound DDs, native nonzero RC and
cleanup; ensure zero ERASE/FORMAT/WRITE commands.
Test source formatting within fixed 80-column
CMS upload limits. Host fixture tests are not
proof of CMS QUERY FILEDEF behavior.

Target proof order: preserve M173/M174 data,
confirm standalone M175CHK G if not already
passed; transfer only new EXEC, run INFO on
tip and TREE on root, compare OID and closure
counts to M176. Leave existing G stage and
index intact; no repeat of lengthy imports,
index audits or disk formatting.

**Safety:** Physical PMAINT0141 VMCOM1 fullpack
overlaps G; never link it for writing while G
contains data. Preserve the CP directory
original/backup and original PACK on A.

---

## Original docs/M178_PACK_TREE_PERFORMANCE_PLAN.md

# M178 — forward-only authenticated tree closure (live CMS proven)

## October 9, 2026, 16:24 CDT — ACTUAL z/VM 6.3 M178 CMS PASS

**TARGET-PROVEN.** The operator uploaded the previously host-tested
`GITPFST.C` and `GITPFAST.EXEC`, checked that the existing G disk and
stage/index were accessible, and compiled the new module without any
flagged assembly statements. This proof supersedes the earlier
"not CMS target-proven" provisional status below; that text is retained
as historical design/validation context.

- `QUERY DISK G`: `GIT600 600 G R/W 1600 3390 4096`, 2 files,
  62526 blocks used (22%), 225474 free of 288000 total.
- `STATE M173NET STAGE G` and `STATE M174NET INDEX G`: RC 0.
- `QUERY FILEDEF` before: `No user defined FILEDEF in effect`.
- `STATE GITPFST C A`: RC 0; `CMSCLNK GITPFST PLAIN`:
  `ASSEMBLER (XF) DONE`, `NO STATEMENTS FLAGGED IN THIS ASSEMBLY`,
  `CMSCLNK: built GITPFST MODULE mode PLAIN` (2.01s elapsed).
  `STATE GITPFST MODULE A`: RC 0.
- Real run: `GITPFAST G CCB18BEC067E7886D70B82EF138EE56A8B899A61`
  returned RC 0, CPU 455.95s, elapsed **460.66s** at 16:24:00 CDT.
- Exact closure: **8 trees, 272 blobs, 0 gitlinks, 279 entries,
  280 verified objects**, largest 393767 bytes; peak resident
  **6546851 bytes** (approximately 6.24 MiB).
- Existing index: **7736 total and 7736 unique**. Forward scans **2**,
  object-header visits **15472** (7736 per pass; not physical CMS
  stage records), seeks **0**, authenticated blobs **272**.
- Native markers: `M178 TREE CLOSURE PASS` and
  `M178 VERIFIED FAST TREE TARGET GATE PASS
  CCB18BEC067E7886D70B82EF138EE56A8B899A61 G`.
- `QUERY FILEDEF` after at 16:25:37:
  `No user defined FILEDEF in effect`, matching before.

This is **positive-path native functional verification**, not proof
of comparative speed. Prior M177 TREE output had overflowed elapsed
counters, so the raw earlier wall-clock gap is not a valid timing
baseline. No original M173 stage, M174 index, M171 input PACK,
GITPTRE, GITPVIEW, directory or selector was altered by M178.
Keep these protected; especially never write-link overlapping
`PMAINT 0141`. Any next optimization must be isolated, host-tested,
and measured against comparable CMS runs without reimport or format.

---

## October 9, 2026 — independent two-pass native C prototype

**IMPLEMENTED SOURCE ONLY; NO REAL CMS TARGET RESULT AND NO
PERFORMANCE IMPROVEMENT CLAIMED.** A new `src/GITPFST.C`
reuses the original GITPTRE SHA-1/index parsing and
tree-format validation, but changes the access strategy:

1. Read `M174NET INDEX G` read-only, validate PIDX1,
   monotonic OID order, every offset, and build an
   in-memory object-number-to-index map.
2. **Forward scan 1** over `M173NET STAGE G`:
   sequentially validate object headers and records,
   cache and SHA1-verify tree objects using a strict
   64MiB resident budget. It matches each selected
   tree's identity and file position against the index.
   No random stage seeks.
3. Traverse cached trees with bounded depth 256,
   mode/name/type, missing-child, external-gitlink and
   cycle rules. Mark distinct reachable blobs without
   accepting their contents yet.
4. **Forward scan 2** over the stage: SHA1-verify only
   marked reachable blob bodies and compare their OID,
   type, length, record number and byte offset against
   the original index. Count authenticated reachable
   blobs. The module does not use `fseek`.
5. Require all reached blobs authenticated, no memory
   leak, and output validated TREE CLOSURE counters,
   `M178 FORWARD SCANS 2 RECORDS ... SEEKS 0`,
   `M178 AUTHENTICATED BLOBS ...`, and
   `M178 TREE CLOSURE PASS`. Fail closed otherwise.

This approach holds more tree bodies temporarily than
the original walk and rereads the stage twice. That
is an explicit bounded-memory tradeoff, not an
established faster implementation on CMS. An unusual
repository with more than 64MiB cumulative tree
data may fail this prototype while the original
walker succeeds; keep the original as baseline.
All previous M176/M177 modules and G stage/index
are unchanged.

Added the independent `GITPFAST EXEC` wrapper:
it requires an explicit non-A 4096-byte CMS
disk and 40-hex tree OID; checks the existing
stage/index and new GITPFST module, refuses
caller-bound STGIN or IDXIN DDs, establishes
temporary input FILEDEFs, runs the native
walker and cleans only its own DDnames.
It independently crosschecks counts, native
PASS, authenticated blob count, zero-seek
diagnostic, requested root, and cleanup RC.
No ERASE, FORMAT, stage/index OUTPUT or
directory command is present.

Host model: `tests/test-m178-forward-tree.py`
compiles both old/new modules with GCC
C89 `-Wall -Wextra -Werror`, compares
output for a tree/blob/gitlink fixture
including a 70,000B blob and verifies
failure on malformed OID, corrupted
blob body and missing child. Actions
native-stage runs the test for relevant
source changes. **Host testing cannot
establish z/VM 6.3 FILEDEF or large-stage
runtime behavior.**

### Exact eventual CMS target validation (after host CI)

Mac, from existing `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITPFST.C GITPFAST.EXEC
```

CMS MAINT, ensure previous stage/index remain
protected and no DD definitions exist:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
QUERY FILEDEF
STATE GITPFST C A
CMSCLNK GITPFST PLAIN
STATE GITPFST MODULE A
GITPFAST G CCB18BEC067E7886D70B82EF138EE56A8B899A61
QUERY FILEDEF
```

Only run GITPFAST if the new C compiler/module
build succeeds. Check expected root closure:
8 trees, 272 blobs, zero gitlinks, 279 entries,
280 verified objects, global index 7736/7736.
Require `M178 TREE CLOSURE PASS`, the
two-pass/zero-seek counter, and final
`M178 VERIFIED FAST TREE TARGET GATE PASS`.
The FILEDEF state must be identical before/
after. Measure wall time externally and
compare with the old result only if the
measurement methods are genuinely comparable.
Never run `M173CHK G`, `M174CHK G` or
FORMAT as part of this experiment.
Retain the existing GITPTRE and GITPVIEW
as fallback under all circumstances.

---


## October 9, 2026, 15:51 CDT — prerequisite native gate closure

Subsequent to writing this plan, the operator confirmed
**full M175CHK G PASS**, **M177 GITPVIEW INFO G PASS**
and **identical empty before/after QUERY FILEDEF**
at 15:46:33 / 15:48:54. INFO runtime was
41.52s elapsed; standalone M175 runtime 124.65s.
Together with previously verified M177 TREE,
M173–M177 positive-path CMS validation is
complete. The below section titled *Immediate remaining
M177/M175 checks* is now historical and should
not be rerun before engineering M178.

No production C code has been changed, and the
unmeasured random-seek performance hypothesis
remains an engineering investigation, not fact.

---


**Status: isolated prototype source and host tests; not CMS target-proven.**
Prepared October 9, 2026 after full real-CMS M176 and M177 TREE
closure success using the 7,736-object stage/index on GIT600.

## Proven, immutable reference

- `M173NET STAGE G`: actual native PACK import and readback PASS
  (7,736 objects); expensive to recreate.
- `M174NET INDEX G`: 7,736 unique OIDs with complete stage/index
  audit PASS; do not modify.
- Root `CCB18BEC067E7886D70B82EF138EE56A8B899A61`;
  tip `ADA83FF3B3813961CEF2A9FFC50A453540039E0B`.
- Full `GITPTRE WALK` reached
  8 trees + 272 blobs = 280 verified objects, 279 entries,
  0 gitlinks, largest object 393767B, peak resident 394058B.
  The standalone `GITPVIEW TREE G` returned
  `M177 PACK VIEW TREE PASS` at 15:32 CDT on Oct 9.
- Its CMS `Ready; T=*.**/*.**` timing overflowed.
  A previous Ready line at 13:28:51 and TREE Ready at
  15:32:00 are about 2h03m09s apart, **not proof of exact
  elapsed duration for the TREE command**.

## Mechanism worth investigating

`src/GITPTRE.C` builds an in-memory OID-sorted index and
calls `fetch()` for each required tree/blob. In `fetch()`
it does `fseek(stage, ix[pos].offset, SEEK_SET)`,
then decodes and SHA1-verifies the object from
`dd:STGIN`. The 280-object root closure is verified
correctly; however, many random byte-offset seeks into
a large CMS variable-record stage could be costly.
This is a **hypothesis**, not a measured causal finding.

Do not weaken any of the existing guards:
- object header number/type/size/OID must match the
  verified index, and computed Git OID must match body
  SHA1 and object header;
- mode, name, child existence, child type, cycle/depth,
  external gitlink rules and resident memory caps;
- index ordered/unique boundaries and PEND1;
- full root/object counts and final authenticated
  closure PASS; wrong OID or corrupted body must
  fail closed;
- existing M176/GITPTRE/ GITPVIEW paths and original
  stage/index remain available for comparison.

## Safest work sequence

1. Add an **isolated** M178 native module (e.g.
   `GITPFST C`/MODULE) and M178 checker, built PLAIN,
   with its own input FILEDEFs. Avoid changing or
   overwriting the target-proven `GITPTRE MODULE`.
2. Begin with a portable Linux host fixture matching the
   native CMS text STAGE and PIDX1 formats. Compare
   new module vs `GITPTRE` in the same process environment:
   same tree/blob/gitlink/entry/verified counts;
   same accepted modes; identical SHA-authenticated
   subobject closure and same failure classes for
   missing/corrupt child, truncated stage/index,
   bad OID, cycle, depth, and memory exhaustion.
3. Consider **forward-only reading** of stage objects
   rather than up to 280 independent seeks:
   scan stage sequentially in its original object
   sequence, authenticate tree bodies while caching
   only bounded parsed tree edges; construct the
   reachable tree/blob closure using the existing
   OID index; scan stage sequentially to authenticate
   only the reachable blobs. Fail closed if tree-edge
   memory exceeds the bounded budget. A second full
   forward scan may outperform hundreds of random
   backward seeks on CMS, but must be measured.
4. Add bounded counters (stage records consumed,
   seeks attempted, objects authenticated) and host
   performance comparison. Counters are diagnostic
   only, not validation evidence.
5. After host CI passes, upload the **new** module only,
   run it on the existing 7736-object G stage/index
   without writes, and compare the live closure exactly
   against the already-proven M176/M177 counts.
   Record actual wall-time externally or via bounded
   instrumentation since CMS Ready T overflowed.
6. Only if new behavior is demonstrably correct and
   faster may an opt-in new GIT frontend command be
   considered. Do not change existing `GIT PACK-TREE`
   dispatch or the proven M177 TREE handler by default.

## Immediate remaining M177/M175 checks

The observed M177 TREE PASS does **not** independently
establish M177 INFO success, unchanged before/after
`QUERY FILEDEF` output or the complete M175 checker.
Their minimal read-only target checks are:

```text
QUERY FILEDEF
GITPVIEW INFO G ADA83FF3B3813961CEF2A9FFC50A453540039E0B
QUERY FILEDEF
M175CHK G
```

Skip standalone M175 if full terminal PASS was already
obtained. Do not re-run the slow root TREE just to
check filedef hygiene.

**Physical protection:** PMAINT0141 fullpack still
overlaps VMCOM1/0127 cylinders 6000–7599; do not
link/write it while G contains retained Git data.
Preserve `M171NET PACK/META A`, G stage/index and
directory backups.

