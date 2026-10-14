# M179–M185 historical performance milestones

Complete archival text. Original individual files remain accessible in Git history.

---

## Original docs/M179_TREE_PROFILE.md

# M179 — real-CMS proven read-only stage/CPU profiler

## October 9, 2026 — ACTUAL z/VM 6.3 CMS PASS

Operator provided a real `GITPPROF G` run ending RC0:
`M179 TREE CLOSURE PASS` and
`M179 VERIFIED FAST TREE TARGET GATE PASS`
for root `CCB18BEC067E7886D70B82EF138EE56A8B899A61`.
Observed: 8 trees, 272 blobs, 0 gitlinks,
279 entries, 280 verified, 7736 total/unique index,
largest object 393767B and resident peak 6546851B.
Two forward scans visited 15472 headers (7736 per pass),
zero seeks and 272 authenticated reachable blobs.

**Critical new measurement:** `M179 STAGE LINES PASS1 3864799
PASS2 3864799`: 3,864,799 CMS text lines read per scan,
**7,729,598 text records read total**.
All four `M179 CPU` phase diagnostics (INDEX,
TREE_SCAN, GRAPH, BLOB_SCAN) were `UNAVAILABLE` on
the real CMS C library. The successful run reported
CPU **454.92s**, elapsed **459.44s**, Ready at
**16:43:45 CDT October 9**.

M178 baseline on the same 7736-object data was
CPU 455.95s / elapsed 460.66s; this 1.22s
difference does not prove an optimization.
**M179 is target-proven for positive-path native
verification, not phase timing.** The operator
did not supply a post-run `QUERY FILEDEF`;
the wrapper is designed to clear its own
temporary FILEDEFs but the independent postcheck
remains unconfirmed. The prior prose below
describing M179 as "not target-proven" is now
historical. Do not repeat the expensive M179 run
for this checkpoint.

Next performance experiment: isolated one-pass
M180 at `docs/M180_ONEPASS_TREE.md`. Leave the
proven M178/M179 modules and immutable G stage/index
unchanged. Never reimport/reformat or link
the overlapping PMAINT0141 fullpack for writes.

---


## Why

On October 9, 2026, M178 passed real z/VM 6.3 CMS verification
over the retained 7736-object M173/M174 G stage/index.
It reported CPU 455.95s, elapsed 460.66s, two complete
forward scans, 15472 object visits and zero random seeks.
**The M178 RECORDS counter counts object headers, not
physical CMS stage records.** M177 TREE had overflowed
timing counters; no comparative speedup has been proven.

M179 is a **separate diagnostic module**, not a production
replacement and not yet target-proven. It retains the full
M178 SHA1, index, graph, type/mode/depth, resident cap,
count, two-scan, fail-closed checks and stages without writes.
The target-proven `GITPFST`, `GITPFAST`, `GITPTRE`,
`GITPVIEW` and saved PACK remain unchanged.

- `src/GITPPRF.C` is a C89 copy of M178's authenticated
  walker, with an extra counter of actual successfully
  read stage text records (OBJ header and hex body).
  Counter lines: `M179 STAGE LINES PASS1 N PASS2 N`.
- Additional C89 `clock()` instrumentation separates
  INDEX (read index/map), TREE_SCAN (pass 1), GRAPH
  (closure traversal), BLOB_SCAN (pass 2).
  Each phase reports CPU seconds, or `UNAVAILABLE`
  if the target C library clock is unsupported.
  Diagnostic timers do not change verification decisions.
- `src/GITPPROF.EXEC` requires a 4 KB explicit non-A
  input disk, preexisting M173/M174 files and module,
  rejects caller STGIN/IDXIN FILEDEF, binds only its
  own read inputs and clears only its own definitions.
  It requires the existing native two-scan count,
  OID, closure and authenticated-blob markers.
  It performs no ERASE, FORMAT, output FILEDEF,
  data copy, CP change or PACK/index build.
- Host regression: `tests/test-m179-tree-phase.py`
  compares real-format C89 stdout/closure with proven
  M178 and rejects bad OID, corrupt reached blob,
  malformed skipped body and truncated index.
  It checks physical line totals and all four CPU tags.

## Target run, only after host CI passes

On the Mac from the current `ibm-sandbox/src` directory:

```sh
git pull
./cms-upload.sh GITPPRF.C GITPPROF.EXEC
```

Then on CMS MAINT, read-only preflight:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
QUERY FILEDEF
STATE GITPPRF C A
CMSCLNK GITPPRF PLAIN
STATE GITPPRF MODULE A
GITPPROF G CCB18BEC067E7886D70B82EF138EE56A8B899A61
QUERY FILEDEF
```

Proceed to the walk only after a successful native build
and a G preflight that still shows a 4096-byte R/W disk,
both original stage/index files, and no conflicting DDs.
Expected closure: 8 trees, 272 blobs, 279 entries,
280 verified objects, 7736 unique index, 2 forward
scans, 0 seeks, 272 authenticated reachable blobs,
`M179 TREE CLOSURE PASS`, and
`M179 VERIFIED FAST TREE TARGET GATE PASS`.
Capture the new `M179 STAGE LINES` and all four
`M179 CPU` rows, and final CMS Ready CPU/elapsed.
Compare post-run `QUERY FILEDEF` to pre-run state.
The timers may be unavailable and are not an
authenticated data input.

Do not rerun M173/M174 import/index audits for the
profiler. Do not replace production module names.
No reformat, ERASE, G stage/index write, directory
edit, or write access through the physically
overlapping PMAINT0141 fullpack. M179 is diagnostic
only until actual CMS target validation.


---

## Original docs/M180_ONEPASS_TREE.md

## October 10, 2026 — M180 ACTUAL CMS PASS, PERFORMANCE REGRESSION

**Real z/VM 6.3 MAINT terminal positive-path PASS.** `GIT600 600 G R/W`
3390, 1600 cylinders, 4096-byte blocks, 2 protected files
(62526 blocks used, 225474 free). Both original `M173NET STAGE G`
and `M174NET INDEX G` STATE RC0. Before/after `QUERY FILEDEF`
reported **No user defined FILEDEF in effect**.

`STATE GITPONE C A` RC0; `CMSCLNK GITPONE PLAIN` completed
`ASSEMBLER (XF) DONE`, no flagged assembly statements,
`built GITPONE MODULE mode PLAIN` in 2.05s elapsed.
`STATE GITPONE MODULE A` RC0. Actual command:
`GITPONCE G CCB18BEC067E7886D70B82EF138EE56A8B899A61`.

```text
TREE CLOSURE ROOT CCB18BEC067E7886D70B82EF138EE56A8B899A61
TREE CLOSURE TREES 8 BLOBS 272 GITLINKS 0
TREE CLOSURE ENTRIES 279 VERIFIED 280
TREE CLOSURE MAX OBJECT 393767 RESIDENT PEAK 6486786
TREE CLOSURE INDEX TOTAL 7736 UNIQUE 7736
M180 FORWARD SCANS 1 RECORDS 7736 SEEKS 0
M180 STAGE LINES 3864799
M180 SHA1 BLOBS TOTAL 2220
M180 AUTHENTICATED BLOBS 272
M180 TREE CLOSURE PASS
M180 VERIFIED FAST TREE TARGET GATE PASS CCB18BEC067E7886D70B82EF138EE56A8B899A61 G
```

Terminal `Ready; T=704.95/708.52 10:13:31` (CPU 704.95s,
elapsed **708.52s**) and later `QUERY FILEDEF` at 10:16:35
still `No user defined FILEDEF in effect`. No persistent input
was modified. Peak resident 6,486,786 bytes.

**The single-scan approach IS FUNCTIONALLY TARGET-PROVEN, but is
NOT a performance win.** M179 elapsed 459.44s, M178 460.66s;
M180 is **249.08s / approximately 54.2% slower than M179**.
One-pass avoids 3,864,799 text-line reads but authenticates
2,220 indexed blobs rather than only the 272 reachable blobs
(1,948 additional blobs). This is an observed tradeoff, not
precise attribution of CPU time to either stage or SHA operation.
Keep the established M178/M179 two-pass readers as performance
baselines. Do not rerun completed M180 test or rebuild G data.
Follow-up experiment must isolate a bounded optimization and
prove parity/corruption behavior before a single native target run.

---

# M180 — isolated single-pass authenticated tree closure experiment

## October 10, 2026 — source/host CI only; NOT CMS target-proven

The user supplied real M179 results on z/VM 6.3 CMS on
October 9: native `GITPPROF G` returned RC0, CPU
454.92s / elapsed 459.44s; 8 trees, 272 reached
blobs, 279 entries, 280 verified objects, 7736/7736
index, no random seeks. M179 measured exactly
3,864,799 **CMS stage text lines per pass**, for a
total of 7,729,598. All four C `clock()` phase
measurements were UNAVAILABLE. M178 baseline was
455.95s CPU / 460.66s elapsed. The 1.22s difference
is not proof of an optimization.

**M179 target PASS**, but no post-run `QUERY FILEDEF`
was provided for independent hygiene comparison.
No repeat M179 run is required. Include pre/post
FILEDEF comparisons with any later experiment.

## M180 isolated experiment

M180 tests whether avoiding the second 3.86-million-line
sequential stage scan offsets hashing many more blobs.
This trades I/O for hashing; no speedup is presumed.

- `src/GITPONE.C` is a **new**, isolated C89 module
  based on M178's verified native SHA-1/index/tree code.
  It reads M174NET INDEX G read-only, builds the OID
  and object-number maps, then opens M173NET STAGE G
  read-only for exactly **one** forward pass.
- During the pass it parses/position-checks every object,
  SHA1-verifies each unique indexed tree and indexed blob,
  retains only authenticated tree bodies (64 MiB bound),
  and discards each authenticated blob body immediately.
  Commit/tag and duplicate unindexed bodies receive the
  original M178 hex/record-format checks but are not
  themselves SHA1-authenticated by this experiment.
- The root-tree walk then validates all tree modes,
  child types, names, directory depth, cycle and missing
  child rules, and **only permits a blob if it already has
  a matching SHA1 authentication marker**. Duplicated
  child references are counted once. External gitlinks
  are counted but never dereferenced. The walk and
  integrity checks remain fail-closed. Indexed unrelated
  blob corruption now rejects, unlike selective M178.
- It prints `M180 FORWARD SCANS 1 RECORDS N SEEKS 0`.
  RECORDS counts object headers, not CMS text lines.
  `M180 STAGE LINES N` counts successful OBJ/hex/empty
  stage lines read, and `M180 SHA1 BLOBS TOTAL N`
  counts distinct indexed blobs SHA1-checked, including
  unreachable blobs. `M180 AUTHENTICATED BLOBS N`
  counts reachable SHA1-validated blobs only.
- `src/GITPONCE.EXEC` checks explicit non-A 4096B
  G disk, existing protected stage/index, new module,
  no conflicting caller FILEDEF, and a one-pass
  authenticated closure/counters. It manages only
  temporary STGIN and IDXIN definitions and clears
  both on return. No output FILEDEF, import, ERASE,
  FORMAT, CP write or index rebuild.
- Host test `tests/test-m180-onepass-tree.py` is strict
  C89 and checks M178 parity, one-pass counts, exact
  stage lines, SHA of reachable and unrelated indexed
  blobs, malformed OID/hex, truncated index, and
  no mutation of stage/index input. Native-stage CI
  must pass before attempting actual CMS.

**This is a research alternative, not a replacement
for target-proven M178 or M179.** All original modules
and existing `M173NET STAGE G`, `M174NET INDEX G`,
`M171NET PACK/META A` remain unchanged.

## Exact conditional real-CMS test

On the Mac, in the existing `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITPONE.C GITPONCE.EXEC
```

On MAINT CMS, only read-only preflight and new-module build:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
QUERY FILEDEF
STATE GITPONE C A
CMSCLNK GITPONE PLAIN
STATE GITPONE MODULE A
```

Proceed only on clean 4KB G disk, present stage/index,
no STGIN/IDXIN conflict, and successful new build.

```text
GITPONCE G CCB18BEC067E7886D70B82EF138EE56A8B899A61
QUERY FILEDEF
```

Require RC0 and `M180 TREE CLOSURE PASS`,
`M180 VERIFIED FAST TREE TARGET GATE PASS`,
8 TREES, 272 BLOBS, 0 GITLINKS, 279 ENTRIES,
280 VERIFIED, index 7736 UNIQUE, one forward
scan, 7736 object-header visits, zero seeks,
272 authenticated **reachable** blobs.
Record the new physical `M180 STAGE LINES`,
`M180 SHA1 BLOBS TOTAL`, CPU/elapsed Ready,
and final `QUERY FILEDEF`. Failure preserves
all original data/code: diagnose; do not erase
or reimport the 7736-object stage or index.

Do not use the overlapping VMCOM1 fullpack
`PMAINT 0141` for writes. To compare performance,
compare measured elapsed time with M178 460.66s
and M179 459.44s under otherwise comparable
conditions, while accounting for environmental
variation. The new experiment may be slower.


---

## Original docs/M181_HEX_LOOKUP.md

# M181 — isolated hex lookup for skipped CMS stage records

## October 11, 2026 — M181 ACTUAL CMS TARGET PASS

**Successful retest after distinct MODULE name fix.**
Operator's real z/VM 6.3 console proves
`STATE GITPHXM C A` RC0 and
`CMSCLNK GITPHXM PLAIN` clean:
`ASSEMBLER (XF) DONE`, no statements flagged,
`built GITPHXM MODULE mode PLAIN`, 2.29s elapsed.
The corrected `GITPHX EXEC` calls the separate
`GITPHXM MODULE` correctly.

`GITPHX G CCB18BEC067E7886D70B82EF138EE56A8B899A61`
returned RC0, CPU **294.57s**, elapsed **298.38s**,
Ready at **10:06:35** October 11. Actual output:

```text
TREE CLOSURE ROOT CCB18BEC067E7886D70B82EF138EE56A8B899A61
TREE CLOSURE TREES 8 BLOBS 272 GITLINKS 0
TREE CLOSURE ENTRIES 279 VERIFIED 280
TREE CLOSURE MAX OBJECT 393767 RESIDENT PEAK 6546851
TREE CLOSURE INDEX TOTAL 7736 UNIQUE 7736
M181 FORWARD SCANS 2 RECORDS 15472 SEEKS 0
M181 AUTHENTICATED BLOBS 272
M181 STAGE LINES PASS1 3864799 PASS2 3864799
M181 CPU INDEX UNAVAILABLE
M181 CPU TREE_SCAN UNAVAILABLE
M181 CPU GRAPH UNAVAILABLE
M181 CPU BLOB_SCAN UNAVAILABLE
M181 HEX LOOKUP VALIDATOR PASS
M181 TREE CLOSURE PASS
M181 VERIFIED FAST TREE TARGET GATE PASS CCB18BEC067E7886D70B82EF138EE56A8B899A61 G
```

**Performance result:** vs real M179 elapsed **459.44s**
and CPU 454.92s, M181 saves **161.06s elapsed**
(approximately **35.1%**) using two identical forward
stage scans and identical reached SHA authentication.
This is a substantial single-run improvement,
not a controlled statistical benchmark.
M180 one-pass was slower at 708.52s.

**Evidence limitation:** The successful M181 transcript
did **not** include a post-run `QUERY FILEDEF`. The
earlier name-collision failure did include clean
FILEDEF before/after, but that does not establish
cleanup for this later successful native run. A
single inexpensive `QUERY FILEDEF` can close the
remaining independent hygiene check; no repeated
M181 tree scan is necessary.

M181 **native positive-path verification is now
target-proven** and must be preserved. No overwrite
of the G disk, M173 stage, M174 index, older modules
or the M181 working wrapper/module. Follow-on
experiments are isolated, host CI-gated, and must
be measured on CMS before claiming further speedup.

---


## October 11, 2026 — M181 initial CMS invocation FAIL; name collision fixed

**Operator's first M181 test did not enter native GITPHX.**
On real CMS, `GIT600 600 G R/W` still had 4096-byte
blocks, both protected G stage/index files were present,
`QUERY FILEDEF` before was empty. `STATE GITPHX C A`
and `CMSCLNK GITPHX PLAIN` passed (2.14s elapsed).
However, `GITPHX G <root>` printed `M181 FILEMODE
INVALID` followed by `M181 FAST TREE FAIL RC 4 0 0`,
returning RC 8 in 0.01s. After-run `QUERY FILEDEF`
also returned no user-defined definitions.

**Root cause:** Initial M181 had both `GITPHX EXEC A`
and `GITPHX MODULE A`. The EXEC's inner command
`PIPE CMS GITPHX WALK <root>` invoked its own REXX
wrapper again instead of the native module. `WALK`
was parsed as a filemode by the nested wrapper, causing
`FILEMODE INVALID`. This was wrapper dispatch failure,
not SHA/tree-reader or stage/index validation failure.
No full native tree scan occurred; there is no M181
performance number from this attempt.

**Isolated fix:** retain wrapper `src/GITPHX.EXEC`,
create **distinct native module source**
`src/GITPHXM.C` for `GITPHXM MODULE A` and update
EXEC to check/call `STATE GITPHXM MODULE A` and
`PIPE CMS GITPHXM WALK <root>`. The earlier
`src/GITPHX.C` and already compiled `GITPHX MODULE A`
can be left untouched; they must not be used as the
dispatch path. The strict host regression now detects
same-stem EXEC/MODULE collisions and compiles/runs
the renamed native module. No previous good module
or saved G stage/index needs changing.

**Corrected next Mac transfer** from `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITPHXM.C GITPHX.EXEC
```

**Corrected CMS MAINT preflight and compile:**

```text
QUERY FILEDEF
STATE M173NET STAGE G
STATE M174NET INDEX G
STATE GITPHXM C A
CMSCLNK GITPHXM PLAIN
STATE GITPHXM MODULE A
```

Only if native compilation succeeds and the G inputs
and FILEDEF state remain safe, **invoke the wrapper
by its original name**:

```text
GITPHX G CCB18BEC067E7886D70B82EF138EE56A8B899A61
QUERY FILEDEF
```

Success criteria remain exact 8 trees, 272 reached
blobs, 279 entries, 280 verified, 7736 indexed unique,
two scans and M181 lookup + native/wrapper PASS.
Capture CMS elapsed/CPU against M179 459.44s; no
speedup is presumed. Do not run `CMSCLNK GITPHX`
again for this test, erase the old MODULE, reset
any DATA disk, or repeat a large import/index build.

---


## Motivation and target status

Actual real z/VM 6.3 CMS output established M180
single-scan correctness (8 trees, 272 blobs, 280 verified,
7736/7736 indexed, no seeks, clean FILEDEF) at 708.52s
elapsed, compared with M179's selective two-scan
459.44s. M180 performed SHA on 2220 indexed blobs vs
272 required; avoiding a 3,864,799-line second scan
did NOT make up for the added SHA work. M179 measured
7,729,598 stage text lines across two scans.

M181 changes **only a hot validation implementation**,
NOT the two-pass selective-SHA logic. This source is an
isolated C89 fork `src/GITPHX.C` of `GITPPRF.C`.
It retains exactly two read-only scans, selected tree
body SHA1/caching on scan 1 and reached blob SHA1
on scan 2. For `skipbody` on nonselected records it
replaces repeated C nibble comparisons with a
256-byte table of valid native character codes.
`inithex()` marks ASCII/EBCDIC-native '0'-'9',
'A'-'F', 'a'-'f' before reading any stage lines.
Every skipped hex character and expected line length
continues to be validated; malformed hex still
fails closed. Header/OID/index checks, EOF, tree
graph, child modes/types, cycle/depth, 64MiB cap
and authenticated reachable blob counts are unchanged.
Object bodies selected for SHA still use the original
`nib()` decoder. The only anticipated difference is
speed of the repeatedly executed skipbody validation.

New `src/GITPHX.EXEC` copies the established
`GITPPROF.EXEC` explicit non-A 4K input disk
and safe FILEDEF ownership/cleanup behavior under
its own module name and M181 counters. No original
module, stage or index changed. New native output:
`M181 HEX LOOKUP VALIDATOR PASS`, plus the normal
`M181 TREE CLOSURE PASS` / wrapper gate marker.
M179's `M181 STAGE LINES PASS1/2` and clock CPU
phase diagnostics are retained, though `clock()`
was UNAVAILABLE on real CMS under M179.

Host test `tests/test-m181-hex-lookup.py` uses
`-std=c89 -Wall -Wextra -Werror`, compares closure
with M178, proves validation of large *unreachable*
indexed blob payload, accepts lowercase hex for
skipped data, and fails closed on invalid hex
skipped body, reached blob SHA corruption, malformed
root and truncated index. CI must pass before CMS.

**M181 NOT YET CMS TARGET-PROVEN.**
A speedup is neither assumed nor guaranteed.
The fastest measured approach remains M179 (459.44s);
M181 is separate experimental code, not replacement.

## Conditional target test after host CI

Mac from `ibm-sandbox/src` (corrected native module stem):

```sh
git pull
./cms-upload.sh GITPHXM.C GITPHX.EXEC
```

CMS MAINT preflight:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
QUERY FILEDEF
STATE GITPHXM C A
CMSCLNK GITPHXM PLAIN
STATE GITPHXM MODULE A
```

Only proceed after clean 4KB G disk, both
protected files present, no conflicting FILEDEF
and successful new module compilation:

```text
GITPHX G CCB18BEC067E7886D70B82EF138EE56A8B899A61
QUERY FILEDEF
```

Expected: same root, 8 trees, 272 blobs, 279 entries,
280 verified objects, 7736/7736 unique indexed OIDs,
2 forward scans, 15472 object header visits, zero
seeks, 272 authenticated reachable blobs, 3,864,799
stage text lines per pass, M181 terminal closure
and wrapper verified gate. Record elapsed and CPU,
and identical before/after `QUERY FILEDEF`.
The CPU phase `UNAVAILABLE` is acceptable.
Compare one native M181 run to M179 459.44s,
but consider environment variation and avoid
claiming a definitive improvement from one run.

Never ERASE, FORMAT, write G stage/index, reimport,
reindex, repeat original large milestones, or
write-link PMAINT 0141 overlapping VMCOM1 fullpack.
Keep M176–M180 modules available.


---

## Original docs/M182_HEX_PAIR.md

# M182 — isolated two-hex-character validation lookup

## Status: host source only, CMS performance unproven

Real z/VM 6.3 M181 passed on October 11, 2026,
with the corrected separate `GITPHX EXEC` and
`GITPHXM MODULE`: two full stage scans,
3,864,799 stage text lines per pass, 272 reached
SHA-authenticated blobs, 8 trees and 280 verified
objects, no seeks, CPU **294.57s** and elapsed
**298.38s**. This is 161.06s/35.1% faster
than the M179 elapsed baseline 459.44s.
M181 is the fastest measured read-only tree reader.

The successful M181 transcript did not show a
post-run `QUERY FILEDEF`. A simple independent
hygiene check remains appropriate; no M181 rerun
is needed. Earlier error-path cleanup was proven.

## Isolated M182 candidate

M182 keeps all M181 selective two-pass behavior
and strict validations, including SHA-1 of cached
trees in pass 1 and reachable blobs only in pass 2.
The new `src/GITPH2M.C` copies the target-proven
`GITPHXM.C` but tests one more micro-optimization
in `skipbody`, used millions of times.

M181 checks each skipped ASCII/EBCDIC-native
hexadecimal *character* with a 256-element table.
M182 instead checks each adjacent *pair* with a
65,536-element zero-initialized table indexed by
the unsigned native codes of both characters.
Initialization marks a pair valid if and only if
both characters are legal 0–9, A–F or a–f.
The loop advances exactly two characters.
The body text record length is checked first;
all nonselected record bytes are still validated.
Selected tree/blob bodies retain M181's original
`nib()` decoding and full Git SHA-1 integrity.
The new pair table uses 64 KiB static storage;
the resident tree cap remains separately 64 MiB.

**This change does not reduce the number of CMS
stage lines read.** The speed result may improve,
match or regress due to table size/cache behavior.
Do not assume it is faster than M181 until measured
on real CMS; the existing M181 reader is unchanged.

Native C89 `src/GITPH2M.C` is paired with
**different-stem** `src/GITPH2.EXEC`. The EXEC
checks/calls `GITPH2M MODULE A`, so it cannot
dispatch itself recursively (the M181 regression
cause). It refuses invalid/non-A filemode,
conflicting FILEDEFs, missing original stage/index
or module, and uses owned temporary read-only
STGIN and IDXIN definitions; no disk writes,
ERASE, COPYFILE, FORMAT, reimport, index build or
directory changes. It requires native root,
authenticated blob counts, two-scan/zero-seek and
end-of-walk PASS before final wrapper PASS.

Host `tests/test-m182-hex-pair.py` compiles C89
`-std=c89 -Wall -Wextra -Werror`, checks tree
closure and index parity, confirms both first and
second malformed hex nibble fail closed even in
unreachable skipped records, lowercase hex passes,
reached blob SHA corruption rejects, malformed
OID/truncated index reject and source/input records
are unchanged. CI guards distinct EXEC/MODULE names
and watches the new source. Host tests cannot
prove IBM CMS behavior or native runtime gain.

## Target gate after successful host CI

On Mac in the established `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITPH2M.C GITPH2.EXEC
```

On z/VM 6.3 MAINT, check protected original data,
no conflicting FILEDEFs, then compile **only**
new M182 module:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
QUERY FILEDEF
STATE GITPH2M C A
CMSCLNK GITPH2M PLAIN
STATE GITPH2M MODULE A
```

Only after clean new native build and preflight:

```text
GITPH2 G CCB18BEC067E7886D70B82EF138EE56A8B899A61
QUERY FILEDEF
```

Expected: root matches, 8 TREES, 272 BLOBS,
0 GITLINKS, 279 ENTRIES, 280 VERIFIED, 7736
index total/unique, 2 forward scans and 15472
header visits, 0 seeks, 272 authenticated
reachable blobs, 3,864,799 stage text lines
on each pass. Require
`M182 HEX PAIR VALIDATOR PASS`,
`M182 TREE CLOSURE PASS` and
`M182 VERIFIED FAST TREE TARGET GATE PASS`,
all RC0. Capture exact CMS Ready CPU and elapsed
and identical before/after `QUERY FILEDEF`.
`M182 CPU ... UNAVAILABLE` is acceptable.

Do not re-run M173/M174 import/index, M180 or
M181 full closures merely as prerequisites.
Never format or write through overlapping VMCOM1
`PMAINT 0141` fullpack. Preserve M176–M181
proven modules and `GIT600` disk contents.


---

## Original docs/M183_SKIP_LENGTH.md

# M183 — isolated skipped-record length and four-way hex checks

## Purpose

M181 is real z/VM 6.3 CMS target-proven: its corrected
`GITPHX EXEC` invokes distinct `GITPHXM MODULE`, and
the authenticated tree closure completed in 298.38 s
elapsed / 294.57 s CPU. It produced 8 trees, 272 blobs,
279 entries, 280 objects verified, 7736 unique indexed
objects, exactly 2 forward stage scans and zero seeks,
with 3,864,799 stage text lines read per pass.

M182 (`GITPH2 EXEC`, `GITPH2M MODULE`) is a separate,
host-tested candidate using a 64 KiB two-hex-character
lookup table; no real CMS timing/verification for M182
has been supplied. **M183 does not assume M182 success.**
It forks the actual CMS-proven M181 native source.

## M183 bounded change

`src/GITPH3M.C` retains exactly the M181 two-pass,
selective SHA1 (all reachable trees in first pass, only
reachable blobs in second), native Git OID verification,
index alignment, exact record checks, valid filemodes,
closure/type/mode/depth/cycle guards, resident cap,
zero seeks, and read-only behavior.

Its only native hot-loop changes are:
- `linein_len()` preserves the exact original `linein()`
  semantics, including CR/LF and trailing-space stripping,
  80-character maximum, stage record counters and EOF
  handling, but returns the *already calculated* trimmed
  length via an optional output integer. The old `linein()`
  is a thin call to this helper for all other callers.
- `skipbody()` compares that length against the expected
  two-hex-characters-per-byte without calling a **second**
  `strlen()` for every nonselected stage record.
- `skipbody()` checks four sequential characters per
  iteration using the unchanged 256-byte native-code
  `validhex` table; the remaining 1–3 characters are
  still checked. Invalid first, middle and final hex
  nibbles all fail closed. No runtime line is skipped,
  no SHA-1 decision changes, and no nonhex accepted.
- Zero-length bodies still require an empty CMS text
  record. Any malformed physical length remains fatal.

`src/GITPH3.EXEC` is an isolated clone of the proven
wrapper, requiring `GITPH3M MODULE` (distinct stem)
on an explicit non-A 4 KiB G input disk with preexisting
protected stage/index and no conflicting DD definitions.
It checks root and object counts and native output,
manages only its own temporary read FILEDEFs and clears
them on return. No protected G data is rewritten.

Host `tests/test-m183-skip-len.py` compiles the new
code strict C89 (`-std=c89 -Wall -Wextra -Werror`),
verifies closure/OID and counts against M178,
negative SHA and corrupt skipped text, lowercase hex,
truncated/extended malformed record lengths, an
illegal last nibble, trailing spaces on disposable
fixtures, malformed root/index, and no production
side effects. CI guards against EXEC/MODULE
name recursion and 80-column CMS source lines.

**M183 host passing does not establish z/VM speed.**
Saving one `strlen()` and unrolling the check may help,
be neutral, or regress. M181 elapsed 298.38s is the
last measured successful baseline. M182 should not be
declared faster or slower without a real CMS report.

## Conditional native CMS test, after CI PASS

Mac, existing `ibm-sandbox/src` directory:

```sh
git pull
./cms-upload.sh GITPH3M.C GITPH3.EXEC
```

On CMS MAINT, read-only preflight and compile new
independent module:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
QUERY FILEDEF
STATE GITPH3M C A
CMSCLNK GITPH3M PLAIN
STATE GITPH3M MODULE A
```

Proceed only with 4096-byte G and both protected
input files present, no caller STGIN/IDXIN collision,
and a successful native build. Invoke distinct wrapper:

```text
GITPH3 G CCB18BEC067E7886D70B82EF138EE56A8B899A61
QUERY FILEDEF
```

Required: 8 trees, 272 reached blobs, 0 gitlinks,
279 entries, 280 verified objects, 7736 unique
indexed OIDs, exactly two forward scans, 15472
object-header visits, zero random seeks,
272 authenticated reachable blobs, 3864799
stage text lines for *each* pass. Native success:
`M183 UNROLLED HEX VALIDATOR PASS`,
`M183 TREE CLOSURE PASS`, and wrapper
`M183 VERIFIED FAST TREE TARGET GATE PASS`,
all RC 0. Capture exact CMS Ready CPU/elapsed and
post-run `QUERY FILEDEF`.

Read-only input G files are `M173NET STAGE G` and
`M174NET INDEX G`; persistent disk `GIT600`.
Do not ERASE/FORMAT/reimport/rebuild original data,
repeat older expensive tests, or write-link physically
overlapping `PMAINT 0141` wholepack. Preserve
existing M176–M182 code and target-proven M181.


---

## Original docs/M184_HOST_COMPARISON.md

# M184 — observational native host comparison of M181/M182/M183

## Purpose

The user instructed **do not pause** while M182 and M183
await real CMS measurements. We can validate and compare
host behavior without repeatedly running expensive z/VM
workloads or touching the protected native G files.

The latest real z/VM 6.3 result remains M181:
`GITPHX EXEC` invokes `GITPHXM MODULE`; native
tree closure RC0 with 8 trees, 272 blobs, 279 entries,
280 verified objects, 7,736 unique indexed OIDs,
2 forward sequential stage scans of 3,864,799
physical text records each and zero random seeks.
Real CPU **294.57s**, elapsed **298.38s**.
Its final post-run FILEDEF check was not provided.

M182 is separately host-proven (`GITPH2M.C`,
pair-of-hex 65,536-entry table); M183 is separately
host-proven (`GITPH3M.C`, M181 LUT with four-way
loop and shared physical-record length). Neither
has a real z/VM 6.3 measured runtime. Do not
substitute a host performance figure for target proof.

## M184 host harness

`tests/bench-m184-hex-selective.py` is a standalone
Python 3 stdlib benchmark requiring `gcc` (GitHub
native-stage Actions runner). It does not modify
any existing production source or CMS module.

1. Strictly C89-compile M181, M182, M183 native
   sources, plus the existing read-only host
   `GITPIDX` index generator into a temp directory.
2. Generate a disposable native stage with one
   deliberately *unreachable* 15,360,000-byte blob
   to exercise skipped-body validation, a small
   reachable blob, and the root tree that refers
   only to the small blob.
3. Build the index on the disposable host fixture
   only, using the original strict index builder.
   No index generation on CMS or permanent G.
4. For every candidate, require equal root,
   1 tree, 1 reached SHA-authenticated blob,
   2 verified objects, 3 unique index objects,
   2 full forward stage scans, no random seeks,
   exactly equal physical stage-line counts
   and each candidate's specific terminal PASS.
5. After one warmup, run 7 comparative iterations
   with rotating order and print median, minimum
   and maximum wall-clock seconds for each module.
   Hash stage and index before/after; demand
   identical content and success return code.
6. Do **not** fail CI for any performance ranking,
   margin, or timing variation: only correctness
   / input preservation should determine CI PASS.

Host timings are subject to OS page cache, Python
process launching, concurrent runner load, native
CPU speed and libc behavior. They do not predict
the IBM C89 CMS runtime ranking. The user's
mainframe benchmark can differ materially, and
small host differences are not significant.
The native C89 `clock()` phase diagnostic was
UNAVAILABLE on real z/VM 6.3 for M179–M181.

The host benchmark is integrated in
`.github/workflows/native-stage.yml` and reports
`M184 PARITY AND READ-ONLY BENCHMARK PASS`
when all correctness assertions hold.

## Recorded host observation (GitHub Actions)

The stricter 15,360,000-byte fixture (480,007 native
stage text records per scan), seven measured rotating
repetitions and one warmup, completed full native-stage
CI success in [run 38151637954](https://github.com/
mostangrymike/ibm-sandbox/actions/runs/38151637954).

```text
M184 FIXTURE: 15360000 bytes unrelated blob, 480007 stage lines
M181 HOST MEDIAN 0.1197s MIN 0.1181s MAX 0.1292s
M182 HOST MEDIAN 0.1010s MIN 0.0982s MAX 0.1198s
M183 HOST MEDIAN 0.0913s MIN 0.0887s MAX 0.0954s
M184 HOST TIMINGS ARE OBSERVATIONAL ONLY; NOT z/VM DATA
M184 PARITY AND READ-ONLY BENCHMARK PASS
```

The median ordering on this *Linux host* fixture is
M183, then M182, then M181 (fastest to slowest).
The entire test uses locally cached files and
sub-second native processes. **These are NOT z/VM
CMS performance results, nor a guarantee of target
ranking or a reason to replace M181.** The mainframe
C runtime, I/O, and EBCDIC behavior may differ.

---

## Next safe target decision

- Preserve the real CMS M181 reader as the reference.
- Keep M182 and M183 installed as independent modules
  rather than overwriting or renaming known-good ones.
- When CMS operator time is available, use the already
  merged runbooks at `docs/M182_HEX_PAIR.md` and
  `docs/M183_SKIP_LENGTH.md` for their respective
  two-file Mac transfer and *one* read-only target
  execution each, plus `QUERY FILEDEF`.
- Compare actual CMS elapsed/CPU against M181
  298.38s / 294.57s, and between candidates under
  similar load, without claiming formal significance
  from single executions.

No ERASE, FORMAT, G reimport/index rebuild, write
link to overlapping `PMAINT 0141` fullpack, or
writes to `M173NET STAGE G`/`M174NET INDEX G`
are authorized. This milestone is HOST ONLY:
no new CMS EXEC, C module or transfer is needed.


---

## Original docs/M185_DIRECT_SKIP.md

# M185 — direct bounded validation of skipped CMS hex records

## October 11, 2026 — M185 real z/VM 6.3 CMS target PASS

The user's native CMS transcript provides **actual successful target
validation** (not host-only evidence). `CMSCLNK GITPH5M PLAIN` produced
`ASSEMBLER (XF) DONE`, `NO STATEMENTS FLAGGED`, and
`built GITPH5M MODULE mode PLAIN`, elapsed **2.30s**.
The invoked wrapper was:
`GITPH5 G CCB18BEC067E7886D70B82EF138EE56A8B899A61`.

```text
TREE CLOSURE ROOT CCB18BEC067E7886D70B82EF138EE56A8B899A61
TREE CLOSURE TREES 8 BLOBS 272 GITLINKS 0
TREE CLOSURE ENTRIES 279 VERIFIED 280
TREE CLOSURE MAX OBJECT 393767 RESIDENT PEAK 6546851
TREE CLOSURE INDEX TOTAL 7736 UNIQUE 7736
M185 FORWARD SCANS 2 RECORDS 15472 SEEKS 0
M185 AUTHENTICATED BLOBS 272
M185 STAGE LINES PASS1 3864799 PASS2 3864799
M185 CPU INDEX UNAVAILABLE
M185 CPU TREE_SCAN UNAVAILABLE
M185 CPU GRAPH UNAVAILABLE
M185 CPU BLOB_SCAN UNAVAILABLE
M185 DIRECT SKIP VALIDATOR PASS
M185 TREE CLOSURE PASS
M185 VERIFIED FAST TREE TARGET GATE PASS CCB18BEC067E7886D70B82EF138EE56A8B899A61 G
Ready; T=206.72/209.97 11:19:23
```

M185 **real CPU 206.72s, elapsed 209.97s**; M181 was CPU
294.57s, elapsed 298.38s. M185 saves **87.85s CPU**
and **88.41s elapsed (29.6%)**, with the same selective
SHA-authenticated root closure, two stage scans, 272 reached
blobs and zero random seeks. M179 elapsed 459.44s, M180
elapsed 708.52s. One-run performance comparison is
descriptive, not a controlled distribution of samples.

**Evidence boundary:** This successful M185 transcript does
not include preflight output or a *post-run* `QUERY FILEDEF`.
The earlier safe wrapper/host checks do not independently
establish success-path FILEDEF cleanup on CMS. One standalone
`QUERY FILEDEF` is sufficient; do **not** rerun the costly
walk to check it.

M185 is now the **fastest measured real z/VM 6.3 reader**.
Preserve the target-proven `GITPH5 EXEC A` and
`GITPH5M MODULE A` unchanged; future work must fork
isolated new stems and leave `GIT600`, `M173NET STAGE G`
and `M174NET INDEX G` intact. M182/M183 remain host-only
without actual CMS transcripts.

---


## Motivation and status

The z/VM 6.3 target-proven positive-path reference is
M181, `GITPHX EXEC` + `GITPHXM MODULE`: October 11
real run 8 trees, 272 reached blobs, 279 entries,
280 verified objects and 7,736 unique indexed OIDs.
Its two sequential scans each read 3,864,799 text
records and had zero random seeks. CPU **294.57s**,
elapsed **298.38s**. No post-run `QUERY FILEDEF`
was supplied for that successful M181 transcript.

M182 and M183 are independently merged and host-proven,
but neither has a supplied real-CMS runtime. M184's
Linux-only observational comparison suggests the
latter hot-loop optimizations may be promising, but
does not prove performance on IBM CMS.

**M185 is a new isolated reader, NOT yet CMS-proven.**

## Isolated native change

- `src/GITPH5M.C` forks the host-tested M183 C89
  implementation, itself based on target-proven M181.
- The frequent skipped-body reader now calls a
  separate bounded `skipline(f, expected_hex_chars)`.
  It uses `fgets` exactly once for each CMS record,
  increments the same per-pass physical record counter,
  tests every expected hex character using the unchanged
  256-entry native ASCII/EBCDIC hex validity table,
  then accepts only original `linein`'s trailing trim
  characters (space, CR and LF) before the NUL.
  It preserves the original `fgets` buffer-size cutoff
  and long-line rejection, and permits an ordinary
  last record without newline, as the original did.
- It does **not call `strlen` at all** inside skipped
  body record validation. Header and SHA-selected body
  parsing continue through the original path.
- A premature terminator, bad hex byte, truncated or
  extended line, nontrim suffix or overlong physical
  line rejects. Zero-length bodies require a valid
  empty/whitespace-only physical record, as before.
- All original tree SHA-1, index mapping, object sizes,
  2-pass selective SHA, mode/type/name rules, graph
  closure, 64MiB resident cap and zero-seek requirements
  are unchanged. No stage/index writes or file copies.

New `src/GITPH5.EXEC` is a safe independent REXX
wrapper. It calls **distinct** `GITPH5M MODULE A`
to avoid the prior M181 same-stem EXEC/MODULE error,
requires the explicitly selected non-A 4KiB input G
disk, protected preexisting original stage/index,
checks caller FILEDEF conflicts before binding its
own read-only STGIN/IDXIN, clears only its temporary
definitions, and requires expected closure plus
`M185 DIRECT SKIP VALIDATOR PASS`,
`M185 TREE CLOSURE PASS`, and
`M185 VERIFIED FAST TREE TARGET GATE PASS`.

## Host verification

`tests/test-m185-direct-skip.py` compiles C89
with `-std=c89 -Wall -Wextra -Werror`, compares
the expected authenticated native closure and
physical line totals, and tests malformed stage
record lengths, unexpected suffix characters,
invalid hex in skipped/unreachable records,
lowercase, SHA mismatch in a reached blob, bad
root, truncated index, and file immutability.
Tests compare additional malformed record cases
against M183, including an overlong line.

`tests/bench-m185-direct-skip.py` extends the
M184 read-only host fixture to M185. It uses a
15,360,000-byte deliberately unreachable blob,
three objects, 480,007 stage text lines per scan,
two forward scans and seven rotating Linux host
timing samples after warmup. All four readers must
produce exactly identical authenticated closure
and leave fixture stage/index checksums unchanged.
Only correctness and preservation affect CI success;
speed ordering does not.

The first valid shared Linux CI run recorded:
```text
M181 HOST MEDIAN 0.1211s MIN 0.1179s MAX 0.1444s
M182 HOST MEDIAN 0.0987s MIN 0.0985s MAX 0.1015s
M183 HOST MEDIAN 0.0908s MIN 0.0896s MAX 0.0924s
M185 HOST MEDIAN 0.0760s MIN 0.0759s MAX 0.0926s
```
The comparison is only an **observational Linux
host benchmark**, not a z/VM speedup. Further native
host CI reruns may yield different wall times.

## Native target validation, only after CI success

From the existing Mac `ibm-sandbox/src` directory:

```sh
git pull
./cms-upload.sh GITPH5M.C GITPH5.EXEC
```

On MAINT CMS, perform safe preflight and build:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
QUERY FILEDEF
STATE GITPH5M C A
CMSCLNK GITPH5M PLAIN
STATE GITPH5M MODULE A
```

Only after a successful native compile and no
conflicting caller STGIN/IDXIN FILEDEFs:

```text
GITPH5 G CCB18BEC067E7886D70B82EF138EE56A8B899A61
QUERY FILEDEF
```

Require complete marker and closure parity:
8 TREES, 272 BLOBS, 0 GITLINKS, 279 ENTRIES,
280 VERIFIED objects; index 7736 total/unique;
2 full forward scans, 15472 object-header visits,
0 seeks, 272 authenticated reachable blobs,
exactly 3864799 stage text records on each scan;
native and wrapper M185 terminal PASS as above.
Record CMS CPU/elapsed and post-run `QUERY FILEDEF`.
Compare actual elapsed with M181 **298.38s**.
Do not claim faster z/VM performance from host values.

No ERASE, FORMAT, index rebuild/reimport, G STAGE
or INDEX write, or write-link of physically overlapping
`PMAINT 0141` is authorized. Leave working M176–M184
and permanent `GIT600` intact. No old expensive
tests need repeating as prerequisites.



---

## Original: docs/M177-M178_HISTORY.md (full original archive)

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

