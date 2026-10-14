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



---

## Original: docs/M186-M192_HISTORY.md (including M193-M200 original)

# M186–M192 historical native performance and FSREAD milestones

Complete archival text. Original standalone paths remain in Git history. M188 target-verified baseline and M190 experimental restrictions remain unchanged.

---

## Original docs/M186_DIFFERENTIAL.md

# M186 — deterministic differential integrity matrix for skipped records

## Status and purpose

M181 is still the fastest confirmed **real z/VM 6.3**
native tree walker: CPU 294.57s / elapsed 298.38s,
8 trees, 272 reachable SHA-authenticated blobs,
280 verified objects, 7736 unique index objects,
two complete 3,864,799-line stage scans and no seeks.

M182, M183 and M185 are separately host-proven native
optimizations but do not yet have reported real CMS
success or performance. The M185 single Linux-host
comparison (15.36 MB skipped blob, seven rotating
samples) showed median 0.0760s for M185, 0.0908s
for M183, 0.0987s for M182, 0.1211s for M181.
These are observational host times, **not CMS evidence**.

M185 changes the parsing strategy in a hot path.
M186 adds an additional regression against accidental
acceptance of malformed, unauthenticated skipped data.
**M186 is HOST ONLY: no CMS transfer or new reader.**

## Test design

`tests/test-m186-skip-differential.py` compiles the
unchanged `GITPHXM.C` (M181), `GITPH3M.C` (M183),
`GITPH5M.C` (M185), plus the existing native stage
index generator, all in strict C89
(`gcc -x c -std=c89 -Wall -Wextra -Werror`).

The test creates a disposable native stage/index with
four objects: unreachable 2,048-byte blob,
reachable small blob, unreachable empty blob,
and root tree that points to the small blob.
All candidates must pass the original valid fixture
with the same authenticated tree closure, one
reachable SHA blob, two verified objects,
four unique indexed objects, two scans and zero
random seeks. No original G data is read or changed.

It then runs **181 reproducible test cases**
using fixed seed 186: canonical positive,
specific valid/invalid first-hex substitutions,
short/long/malformed record cases, 160 seeded
mutations to body hex records, and an explicit
zero-length skipped-blob set. Invalid hex
within the skipped blob MUST return failure.
Valid hex changes to that *unreachable* blob may
be accepted, because selective SHA intentionally
does not hash unrelated blobs. Reachable blobs
are still SHA-authenticated by the existing
M185 targeted parity suite. M181 is the
behavioral baseline; M183 and M185 must return
the same status as M181 for every case.
Each successful run also requires the same
root/tree/blob/index counts and native PASS,
and all unsuccessful runs must omit native PASS.
The test verifies input index SHA256 unchanged
through mutations, and restores/verifies original
stage and index at the end.

The check intentionally does not claim that
selective SHA authenticates all unreachable blob
contents: it validates their native hex syntax,
bounds and physical text-record structure.
Acceptance of a different *valid* hex payload on
an unreferenced blob remains the original M181
behavior and is not a missing integrity check
on the requested reachable tree closure.

M186 runs in the GitHub native-stage CI workflow
and prints:

```text
M186 DETERMINISTIC SEED 186 CASES 181 ACCEPTED ...
M186 M181 M183 M185 POSITIVE AND NEGATIVE PARITY PASS
M186 HOST ONLY; NATIVE CMS EXECUTION NOT IMPLIED
```

Any disagreement on a return code or final
authenticated closure is a CI failure.
No runtime ranking/performance threshold is used.

## Next protected CMS work remains unchanged

When desired, real CMS positive-path validation is
available for distinct native modules/wrappers:
`GITPH2M.C` + `GITPH2.EXEC` (M182);
`GITPH3M.C` + `GITPH3.EXEC` (M183);
`GITPH5M.C` + `GITPH5.EXEC` (M185).
Exact read-only preflight, compile, root-walk,
and post-`QUERY FILEDEF` commands live in
`docs/M182_HEX_PAIR.md`,
`docs/M183_SKIP_LENGTH.md` and
`docs/M185_DIRECT_SKIP.md`.

The protected G disk `GIT600`, `M173NET STAGE G`,
`M174NET INDEX G`, and all known-good M176–M181
modules are untouched. Never format/reimport/reindex,
ERASE protected files, or write-link overlapping
`PMAINT 0141` fullpack.


---

## Original docs/M187_NATIVE_SCALE.md

# M187 — synthetic native scale regression at 7,736 indexed Git objects

## Context and status

User instruction: **do not pause** independent GitHub
development or test gating while awaiting actual CMS
outputs. The native GIT600 stage and index are
protected and must not be overwritten or rebuilt.

Actual z/VM 6.3 target baseline is M181:
8 reachable trees, 272 blobs, 279 entries,
280 SHA-verified reached objects, 7,736 total/
unique indexed objects; two forward stage scans
of 3,864,799 text records each; zero random
seeks. Real CPU **294.57s** and elapsed
**298.38s**. M182/M183/M185 are host-proven
only and not yet target-time-proven. The M185
Linux-only observational median was 0.0760s
on a 15.36 MiB skipped-blob fixture, but
that cannot establish IBM CMS performance.

M186's 181-case seeded differential mutation
suite passed host CI and is merged. M187 adds
a complementary **large object-count** regression
to match the live retained index and reachable
closure in synthetic, entirely disposable
files. This is a host-only milestone with no
CMS module or user transfer commands.

## Synthetic Git stage/index

`tests/test-m187-live-scale.py` builds an original
Git object stream with exactly:

- 272 uniquely identified reachable blob objects
- 7 uniquely identified subtree objects
- 1 root tree referencing the seven subtrees
- 7,456 unrelated uniquely identified blob objects
- **7,736 indexed objects and 7,736 unique SHA1 IDs**

The seven directories contain a total of 272
regular-file entries. Root has seven directory
entries, so traversal must produce exactly
**8 trees, 272 blobs, 0 gitlinks, 279 entries
and 280 verified objects**, matching the real
CMS positive closure on the operator's G stage.

All Git object IDs are SHA-1 of their standard
`<type> <bytes>\0<binary body>` content.
The REXX/CMS files are not fetched: Python
generates host fixtures directly. The stage
uses `OBJ` header followed by 32-byte-per-
text-record hex format; the original native
`GITPIDX.C` builds the index *in a temporary
host directory only*. This does not mimic
the live pack's multi-million-line physical
record count or its compressed source; it
reproduces the critical **object cardinality,
types, index uniqueness and reachable closure**.

## Verification

Strict C89 builds of M181, M182, M183 and M185
must each return native RC0 with:
```text
TREE CLOSURE TREES 8 BLOBS 272 GITLINKS 0
TREE CLOSURE ENTRIES 279 VERIFIED 280
TREE CLOSURE INDEX TOTAL 7736 UNIQUE 7736
... FORWARD SCANS 2 RECORDS 15472 SEEKS 0
... AUTHENTICATED BLOBS 272
```
And the exact root OID, same dynamically measured
physical stage text records in each pass, and each
reader's own `TREE CLOSURE PASS`.

The same fixture is then modified, one scenario
at a time, to require:
- valid-hex mutation in an unrelated blob still
  passes (selected SHA does not cover that blob);
- invalid nonhex character in an unrelated blob
  is rejected even when skipped;
- valid-hex payload corruption of a *reached*
  blob is rejected by full Git SHA verification;
- truncated final stage record fails closed.

The stage and index SHA256 must equal their
original values after the test restores the
initial fixture; the index cannot be modified
by any native walk. All operations are host
temp files. No production data is touched.

M187 runs via `.github/workflows/native-stage.yml`.
A passing result prints:
```text
M187 INDEXED 7736 UNIQUE 7736 RECORDS ...
M187 REACHABLE TREES 8 BLOBS 272 ENTRIES 279 VERIFIED 280
M187 TWO SCANS 15472 HEADER VISITS ALL FOUR READERS PASS
M187 NEGATIVE CORRUPTION AND IMMUTABILITY PASS
M187 SYNTHETIC HOST FIXTURE, NOT REAL CMS VALIDATION
```

## Operational safety

M187 itself requires **no CMS run**.
Native target proof and performance for M182,
M183 and M185 remain pending, with exact safe
commands in:
`docs/M182_HEX_PAIR.md`,
`docs/M183_SKIP_LENGTH.md`, and
`docs/M185_DIRECT_SKIP.md`.

No format, reimport, index rebuild, stage write,
module replacement, ERASE, CP edit or write-link
of physically overlapping `PMAINT 0141`
fullpack is authorized. Keep all target-proven
M176–M181 modules and protected original G files.


---

## Original docs/M188_FAST_EOL.md

# M188 — direct skipped-record fast end-of-line path

## October 11, 2026 — M188 REAL CMS NATIVE SUCCESS

The operator ran the new isolated M188 reader on z/VM 6.3, **actual
target success**, at 12:44–12:48 local time. Protected data preflight:

```text
QUERY DISK G
GIT600 600 G R/W 1600 3390 4096 2 62526-22 225474 288000
STATE M173NET STAGE G
Ready
STATE M174NET INDEX G
Ready
QUERY FILEDEF
No user defined FILEDEF in effect
STATE GITPH8M C A
Ready
CMSCLNK GITPH8M PLAIN
ASSEMBLER (XF) DONE
NO STATEMENTS FLAGGED IN THIS ASSEMBLY
CMSCLNK: built GITPH8M MODULE mode PLAIN
Ready; T=2.17/2.27 12:44:41
```

Actual `GITPH8 G CCB18BEC067E7886D70B82EF138EE56A8B899A61`
output:

```text
TREE CLOSURE ROOT CCB18BEC067E7886D70B82EF138EE56A8B899A61
TREE CLOSURE TREES 8 BLOBS 272 GITLINKS 0
TREE CLOSURE ENTRIES 279 VERIFIED 280
TREE CLOSURE MAX OBJECT 393767 RESIDENT PEAK 6546851
TREE CLOSURE INDEX TOTAL 7736 UNIQUE 7736
M188 FORWARD SCANS 2 RECORDS 15472 SEEKS 0
M188 AUTHENTICATED BLOBS 272
M188 STAGE LINES PASS1 3864799 PASS2 3864799
M188 CPU INDEX UNAVAILABLE
M188 CPU TREE_SCAN UNAVAILABLE
M188 CPU GRAPH UNAVAILABLE
M188 CPU BLOB_SCAN UNAVAILABLE
M188 FAST EOL VALIDATOR PASS
M188 TREE CLOSURE PASS
M188 VERIFIED FAST TREE TARGET GATE PASS CCB18BEC067E7886D70B82EF138EE56A8B899A61 G
Ready; T=205.04/208.27 12:48:26
```

**Measured target timing:** CPU **205.04s**, elapsed **208.27s**;
M185 CPU 206.72s, elapsed 209.97s. M188 saves **1.68s CPU**
and **1.70s elapsed (0.81%)** in these single observations.
Both readers verified identical closures and scanned both
3,864,799-line stages with zero seeks. The ~0.8% difference
is small enough that variation in CMS load/cache can explain it;
**do not claim a statistically robust speed advantage**.
M181 historical elapsed 298.38s; M180 708.52s.

**Hygiene evidence boundary:** pre-run `QUERY FILEDEF`
was clean, but **there is no post-run `QUERY FILEDEF`**
in the M188 transcript. Native functional RC0 and
wrapper PASS are proven; final FILEDEF cleanup is not
independently verified. Only a cheap `QUERY FILEDEF`
would close that gap; no repeat stage walk is necessary.

M188 `GITPH8 EXEC A` and `GITPH8M MODULE A` are now
**target-proven positive-path**, and must be preserved.
M185 also remains intact and target-proven.
M189 eight-way grouping passed host integrity but was
slower on the measured Linux fixture and has not run
on CMS. Leave GIT600's two protected source files,
existing modules, and PMAINT0141 overlap untouched.

---


## Baseline and safety

Actual October 11 native z/VM 6.3 M185 compiled successfully
(`CMSCLNK GITPH5M PLAIN`) and passed complete authenticated
tree closure. Its performance is CPU **206.72s**,
elapsed **209.97s**. The root
`CCB18BEC067E7886D70B82EF138EE56A8B899A61`
has **8 trees, 272 blobs, 279 entries, 280 verified**,
7,736 total and unique index objects and two forward
scans of 3,864,799 stage text records each, 15,472
header visits and zero seeks. M181 earlier elapsed
298.38s, so M185 saves 88.41s (~29.6%). This is
measured real CMS evidence, not a Linux timing.

**No post-run `QUERY FILEDEF` was provided for
M185's successful invocation.** The reader success
does not independently prove REXX-owned DD cleanup.

M188 is a newly isolated C89 experiment; original
`GITPH5M.C`, `GITPH5.EXEC`, verified CMS modules,
protected G stage/index and other readers remain intact.
M188 is NOT real-CMS target-proven until a separate
mainframe run, and any Linux timing is observational.

## Isolated change

The new `src/GITPH8M.C` is a byte-for-byte
copy of target-proven M185 except for new name/
M188 status markers and a small common-case branch
in its bounded `skipline` suffix validation.
After validating **every** expected hex character,
it immediately accepts:
- LF then NUL;
- CR/LF then NUL;
- NUL at exactly the expected hex boundary.

For other endings it falls back to **M185's original
complete bounded suffix loop**, which accepts only
space, carriage return or line feed up to NUL,
rejects overlong/no-newline records at buffer cap,
and does not accept invalid suffix bytes.
Both line reading and record-counter updates remain
exactly as in M185: a full `fgets` on every skipped
CMS text record, no skipped/unauthenticated hex byte.
All reached tree and blob SHA-1 verification,
index/OID consistency, type/mode/name/depth/cycle
rules, 64 MiB resident cap, exactly two stage scans
and zero random seeks are unchanged.

The new `src/GITPH8.EXEC` invokes distinct
`GITPH8M MODULE A` (never itself); it retains
the protected stage/index preflight, non-A 4096
block G filemode check, caller FILEDEF conflict
refusal, temporary read FILEDEF ownership/clear,
root and native PASS count verification.
No protected data is written.

## Tests and next CMS gate

`tests/test-m188-fast-eol.py` strict C89
(`gcc -x c -std=c89 -Wall -Wextra -Werror`) proves
M178 closure parity and M185 differential result
parity, including LF, CRLF, trailing spaces,
whitespace-only/invalid suffix, malformed stage
record length, malformed hex, reached-blob SHA
corruption and truncated index. CMS/EXEC
line-width remains <= 80 and host fixture inputs
are restored. `tests/bench-m188-fast-eol.py`
adds M188 to the same seven-round rotating
disposable Linux fixture used for M181/M182/
M183/M185 and requires identical root closure,
2 sequential scans and untouched stage/index
SHA256. It prints host timings without using
performance as a CI pass criterion. **Host
comparisons do not predict real z/VM performance.**

The only legitimate deployment would be an
isolated target measurement after successful
host CI. From the existing Mac `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITPH8M.C GITPH8.EXEC
```

On CMS MAINT, check the 4096-byte G disk and
protected original data, then build ONLY the new
module:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
QUERY FILEDEF
STATE GITPH8M C A
CMSCLNK GITPH8M PLAIN
STATE GITPH8M MODULE A
```

Proceed only on clean preflight/native compilation:

```text
GITPH8 G CCB18BEC067E7886D70B82EF138EE56A8B899A61
QUERY FILEDEF
```

The target gate requires root equality and exact
8 trees,272 blobs,279 entries,280 verified,
7736 indexed unique,2 forward scans,15472
headers,0 seeks,272 SHA-authenticated reached
blobs,3,864,799 stage text lines on each pass,
then `M188 FAST EOL VALIDATOR PASS`,
`M188 TREE CLOSURE PASS` and
`M188 VERIFIED FAST TREE TARGET GATE PASS`,
all RC0. Capture CPU/elapsed and final
`QUERY FILEDEF` to independently check DD cleanup.
Compare with the new real CMS M185 baseline
**206.72s CPU / 209.97s elapsed**.
Do not repeat completed M173 import/M174 index,
erase/formats, overwrite any old module, or
write-link overlapping PMAINT 0141.


## Observed M188 Linux host result (not CMS evidence)

Full native-stage Actions run
[38155760171](https://github.com/mostangrymike/ibm-sandbox/actions/runs/38155760171)
**PASS**, including native C89/regression, host read-only
and identical authenticated closure checks. The seven-run
rotating comparison on the same 15,360,000-byte unrelated
blob, 480,007 text-records-per-scan fixture printed:

```text
M181 HOST MEDIAN 0.1211s MIN 0.1188s MAX 0.1327s
M182 HOST MEDIAN 0.1003s MIN 0.0988s MAX 0.1008s
M183 HOST MEDIAN 0.0914s MIN 0.0899s MAX 0.0930s
M185 HOST MEDIAN 0.0766s MIN 0.0760s MAX 0.0890s
M188 HOST MEDIAN 0.0735s MIN 0.0718s MAX 0.0786s
M188 HOST TIMINGS ARE OBSERVATIONAL ONLY; NOT z/VM DATA
M188 PARITY AND READ-ONLY BENCHMARK PASS
```
M188 is slightly faster than M185 on this **Linux
host sample only**. CMS C library, EBCDIC, object
data, load and scheduler differ. Do not promote
the reader or claim CMS improvement without an
actual mainframe PASS and timing.



---

## Original docs/M189_EIGHTWAY.md

# M189 — eight-hex-character validation in native stage reader

## Measured host-only negative performance result

In successful full native-stage GitHub Actions
[run 38156179675](https://github.com/mostangrymike/ibm-sandbox/actions/runs/38156179675),
all six readers produced identical read-only authenticated
closure. A shared seven-run observational Linux benchmark
on the 15.36MB unrelated-blob fixture printed:

```text
M181 HOST MEDIAN 0.0607s MIN 0.0596s MAX 0.0613s
M182 HOST MEDIAN 0.0516s MIN 0.0515s MAX 0.0523s
M183 HOST MEDIAN 0.0456s MIN 0.0455s MAX 0.0467s
M185 HOST MEDIAN 0.0411s MIN 0.0406s MAX 0.0421s
M188 HOST MEDIAN 0.0407s MIN 0.0402s MAX 0.0461s
M189 HOST MEDIAN 0.0427s MIN 0.0426s MAX 0.0503s
M189 HOST TIMINGS ARE OBSERVATIONAL ONLY; NOT z/VM DATA
M189 PARITY AND READ-ONLY BENCHMARK PASS
```

M189 was about **4.9% slower than M188** on this
single Linux host sample. Grouping eight checks did
not provide a host advantage, even though functional
integrity passed. Treat this as a **negative host
performance experiment**; prioritize M188 for one real
CMS measurement if the operator wants the next target
benchmark. Do not claim a 4.9% z/VM regression or
target CPU performance from host measurements.
M185 remains actual target-proven fastest at
**209.97s elapsed**, 206.72s CPU.

---


## Status, baseline and isolation

M185 is the fastest **real CMS verified** native tree
reader: CPU **206.72 seconds**, elapsed **209.97 seconds**
on z/VM 6.3, with root
`CCB18BEC067E7886D70B82EF138EE56A8B899A61`,
8 trees, 272 SHA-authenticated reachable blobs,
279 entries, 280 verified objects, 7736 indexed unique,
two complete 3864799-text-line forward stage scans,
15472 header visits and zero random seeks.
It improved on M181 elapsed 298.38s by 88.41s.
Post-run QUERY FILEDEF was not included in M185's
successful transcript; do not claim independent hygiene.

M188 has a separate host-proven fast EOL path that
retains all original M185 validation with common LF,
CRLF and no-suffix branches. Its **Linux host**
7-run median was 0.0735s vs M185 0.0766s on
a disposable 15.36MB stage. It has no real z/VM
CMS runtime, and must not replace M185 as a
production/proven baseline.

M189 is a new independent C89 experiment
`src/GITPH9M.C`, with a differently named wrapper
`src/GITPH9.EXEC`. It starts from M188 but
replaces the main `skipline` character loop with
an **8-character unrolled lookup**, accumulating
eight 0-or-1 `validhex` table entries via bitwise
AND and branching only once per group. It checks
all remaining 1–7 hex characters separately.
No record or hex byte may be skipped; invalid
hex still returns failure. It retains the entire
M188 common EOL path and full M185 fallback
for unusual suffixes.

Other behaviors are unchanged: full two-pass
forward scanning, all indexed stage header checks,
full Git SHA1 of selected trees and reachable
blobs, exact types/modes/name/depth/cycles,
64MiB resident cap and zero random seeks.
No G-stage/index writes; distinct wrapper avoids
CMS EXEC/MODULE self-recursion and clears only
temporary owned FILEDEFs after invocation.

## Host evidence, not real mainframe proof

`tests/test-m189-eightway.py` strict C89
(`gcc -x c -std=c89 -Wall -Wextra -Werror`)
checks closure and SHA parity against M178 and
M185, malformed headers, index, record length,
LF/CRLF/spaces, bad suffix characters and
an invalid hex character independently in
every one of the first eight character positions
of a skipped record.

`tests/bench-m189-eightway.py` extends the
existing 15.36MB disposable host stage
comparison to M181, M182, M183, M185, M188
and M189, seven rotating runs after warmup.
It requires identical authenticated closure,
two full scans, exact stage line totals,
and byte-for-byte unchanged stage/index,
with **no timing/ranking CI threshold**.
Linux timing is observational only, cannot
establish z/VM speedup, and may vary by host
compiler/runtime and caching.

M189's real CMS positive path is **NOT yet verified**.

## Conditional real CMS validation after host CI

Mac from `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITPH9M.C GITPH9.EXEC
```

CMS MAINT preflight/build:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
QUERY FILEDEF
STATE GITPH9M C A
CMSCLNK GITPH9M PLAIN
STATE GITPH9M MODULE A
```

Only if 4KiB G, protected stage/index and
FILEDEF preflight are clean and native
module compilation succeeds:

```text
GITPH9 G CCB18BEC067E7886D70B82EF138EE56A8B899A61
QUERY FILEDEF
```

Require unchanged 8 trees,272 blobs,279 entries,
280 verified, index7736/7736 unique,
2 scans, 15472 headers, 0 seeks, 272 reached
SHA1 blobs, 3864799 stage text records on
each pass, all M189 terminal markers:
`M189 EIGHTWAY HEX VALIDATOR PASS`,
`M189 TREE CLOSURE PASS`,
`M189 VERIFIED FAST TREE TARGET GATE PASS`,
and clean post-run `QUERY FILEDEF`.
Capture actual CPU/elapsed versus the real
M185 206.72s/209.97s baseline.

Keep target-proven GITPH5 and all earlier
modules intact. Never ERASE, FORMAT, rerun
completed M173/M174 import/index, overwrite
protected G stage/index, or write-link the
physically overlapping PMAINT 0141 wholepack.


---

## Original docs/M190_SELECTIVE_SEEK.md

# M190 — one validated stage scan, then indexed reachable-blob seeks

## October 11, 2026 — M191 real CMS FIRST and MID PASS; slow seeks

The operator compiled `GITPRBM MODULE` successfully with
`CMSCLNK GITPRBM PLAIN`, assembler XF DONE,
no flagged statements, `Ready; T=2.63/2.74`
at 14:58:54. Two **actual CMS** independent
`GITPRB G` read-only indexed header probes passed:

```text
GITPRB G FIRST
M191 DIRECT CMS SEEK PROBE BEGIN FIRST
M191 INDEX READY 7736 UNIQUE 7736
M191 PROBE FIRST RECORD 1 OFFSET 0
M191 SEEK BEGIN FIRST
M191 SEEK RETURNED FIRST
M191 SEEK HEADER PASS FIRST RECORD 1
M191 READ ONLY SEEK PROBE PASS
M191 CMS SEEK PROBE GATE PASS G FIRST
Ready; T=0.63/0.64 14:59:02

GITPRB G MID
M191 DIRECT CMS SEEK PROBE BEGIN MID
M191 INDEX READY 7736 UNIQUE 7736
M191 PROBE MID RECORD 3868 OFFSET 127843709
M191 SEEK BEGIN MID
M191 SEEK RETURNED MID
M191 SEEK HEADER PASS MID RECORD 3868
M191 READ ONLY SEEK PROBE PASS
M191 CMS SEEK PROBE GATE PASS G MID
Ready; T=25.12/25.82 14:59:51
```

**Conclusion:** CMS accepted both `fseek` calls and
returned the exact indexed object-header identity.
But the MID invocation took **25.12s CPU and
25.82s elapsed**, compared with **0.63s CPU,
0.64s elapsed** for FIRST. This is consistent
with expensive, position-dependent text-stream
repositioning. Two timings alone do **not**
establish asymptotic complexity or per-seek cost,
and the elapsed figures include initial index
reading and all wrapper overhead. Do NOT run
full M190 `GITPSK G ...` with 272 seeks on
the assumption that random access is cheap.
M190 had earlier been interrupted with HX and
has **never** emitted a complete target PASS.

The supplied transcript includes **no post-run
`QUERY FILEDEF`** after either probe. One
standalone `QUERY FILEDEF` would check hygiene.
`GITPRB G LAST` has **not** been run; do not
claim it passed, and no need to attempt it
while investigating record-oriented alternatives.

IBM z/VM documents a separate CMS record-I/O
interface: FSREAD supports an absolute RECNO
on CMS files; a future new, isolated assembler
adapter may use the native record number rather
than expensive C text `fseek` on encoded
stream positions. This approach is **not yet
implemented or target-validated**. First,
host-test a mapping from index object numbers
and sizes to physical CMS record numbers, then
confirm the target file format and record count
without writing any G data.

Proven working two-scan baseline remains M188:
**205.04s CPU, 208.27s elapsed**; M185 real
elapsed **209.97s**. Preserve all working
modules, GIT600, M173NET STAGE G, M174NET
INDEX G. No formatting, rebuilding, importing,
or write-linking overlapping PMAINT 0141.

---

## Observed Linux host result (not z/VM evidence)

The first successful full native staging CI run
[38166026873](https://github.com/mostangrymike/ibm-sandbox/actions/runs/38166026873)
compiled all native readers as strict C89 and verified:
- M190 one complete first scan, reachable-only SHA
  readback by indexed seeks, and no skipped-index writes;
- synthetic **7736 unique indexed Git objects** with
  exactly 8 trees, 272 blobs, 279 entries and 280
  authenticated reached objects;
- an unrelated valid-hex blob mutation accepted by
  both schemes, invalid hex in skipped data rejected,
  reached blob SHA corruption rejected, truncated
  stage rejected;
- matching root and byte-identical stage/index after
  the disposable fixture is restored.

The seven-run Linux host comparison on a
15,360,000-byte unrelated blob printed:

```text
M190 FIXTURE: 15360000 bytes unrelated blob, 480007 stage lines
M188 HOST MEDIAN 0.0719s MIN 0.0713s MAX 0.0807s
M190 HOST MEDIAN 0.0369s MIN 0.0363s MAX 0.0432s
M190 HOST TIMINGS ARE OBSERVATIONAL ONLY; NOT z/VM DATA
M190 PARITY AND READ-ONLY BENCHMARK PASS
```

The M190 host median was about **48.7% lower**
than M188 on this workload. That is consistent
with avoiding a complete second file scan,
but says nothing definitive about z/VM's support
or performance for `fseek` on `dd:STGIN`.
**Do not promise native speedup or functionality**
until one real, read-only CMS target execution.

---


## Target baseline and status

The actual z/VM 6.3 MAINT native stage and index are
`M173NET STAGE G` and `M174NET INDEX G` on
`GIT600` (3390 / 4096-byte blocks).
On October 11, M188 `GITPH8 EXEC` /
`GITPH8M MODULE` compiled and passed, root
`CCB18BEC067E7886D70B82EF138EE56A8B899A61`,
8 trees, 272 blobs, 279 entries, 280 verified,
7736 indexed unique, 2 forward full stage scans,
15472 object-header visits and 0 seeks, 3864799
physical CMS text records per scan; CPU **205.04s**,
elapsed **208.27s**. M185 (same closure) elapsed
209.97s. M188's 1.70s advantage is just 0.81%,
insufficient to claim consistent speed improvement.
The M188 pre-run FILEDEF check was clean, but the
successful transcript omitted *post-run* FILEDEF.

**M190 is a new isolated and currently HOST-ONLY
experimental C89 reader**, not an already-proven
CMS implementation. It must not replace M185/M188.

## Algorithm and read-only integrity guarantee

New `src/GITPSKM.C` forks the target-proven M188
reader but replaces the second exhaustive forward
scan with indexed random-access readback:

1. After reading the index, perform a lightweight
   **read-only seek preflight** against its first,
   middle and last stage offsets. Require `ftell`
   equality and exact header number/type/size/OID
   match. On failure exit RC8 immediately, before
   scanning 3,864,799 stage text records. On G
   report `M190 SEEK PREFLIGHT PASS 3`. These
   setup probes are not counted as blob readbacks.
2. Read and validate all 7736 stage headers,
   index offsets/IDs/sizes/types, every skipped
   blob hex record and Git SHA1 of all trees via
   **one complete forward scan**, including EOF.
   This is the original M188 first scan.
3. Traverse the cached SHA-verified tree graph to
   mark only reached blobs, preserving original
   mode/name/depth/cycle/memory limits.
4. Reopen `dd:STGIN` **read-only**, and for each
   reached blob use its **first-pass verified** native
   `ftell` offset from the original sorted index.
   Perform `fseek(offset, SEEK_SET)`, require
   `ftell()` to equal the expected offset, reparse
   and exactly compare that object's stage header
   with the selected index entry, read its entire
   hex body, recompute full Git SHA1 and compare
   against the indexed object OID. Count successful
   blob authentications. A seek or validation
   failure returns RC8 without a PASS marker.
5. No other blob is trusted as reached; unrelated
   blobs were still syntactically checked in pass 1.
   Both the source stage and index are never opened
   for writing. Total readback seeks = actual number
   of reached blobs (272 on current G closure).
6. Require complete authenticated closure, release
   temporary buffers and close handles on all paths.

On the operator's current dataset, expected native
diagnostics **if CMS's C text stream supports
repositioning**:
```text
TREE CLOSURE TREES 8 BLOBS 272 GITLINKS 0
TREE CLOSURE ENTRIES 279 VERIFIED 280
TREE CLOSURE INDEX TOTAL 7736 UNIQUE 7736
M190 SEEK PREFLIGHT PASS 3
M190 FORWARD SCANS 1 RECORDS 7736 SEEKS 272
M190 AUTHENTICATED BLOBS 272
M190 STAGE LINES FULL 3864799 READBACK <variable>
M190 SELECTIVE SEEK VALIDATOR PASS
M190 TREE CLOSURE PASS
M190 VERIFIED FAST TREE TARGET GATE PASS
```
`READBACK` counts physical text lines actually
re-read at selected indexed offsets; unlike the
old PASS2, it must **not** equal 3,864,799 and is
not hardcoded. The wrapper requires EXACTLY
one scan, as many seeks as reached blobs and
all native/wrapper PASS markers. The native
state/data was checked before seeking.

**Important target risk:** An ISO C `fseek`
using an earlier `ftell` offset is legitimate,
but it is not yet established whether the IBM
CMS C library supports this repositioning on
`dd:STGIN` with its CMS record/text format.
A target failure can mean unsupported seek
rather than wrong Git logic. The new module
fails closed and leaves all original files intact.
Do not change the proven M185/M188 readers.

## Host CI and next experiment

`tests/test-m190-selective-seek.py` C89 compiles
with `-std=c89 -Wall -Wextra -Werror`, checks
positive tree and reached SHA parity, 1 complete
scan, expected selected seeks, malformed stage
and index, invalid roots, lower-case skipped
hex, file immutability and new target wrapper's
distinct native MODULE stem.

`tests/test-m190-scale-seek.py` generates a
disposable 7736-unique-object index whose root
references 8 trees and 272 blobs, compares
M190 with M181/M182/M183/M185 native C89
readers, requires M190 one forward scan and
272 seek readbacks, exact 280-verified closure,
and fail-closed corrupt blobs/invalid hex/
truncated stage. `tests/bench-m190-selective-seek.py`
makes a seven-round rotating Linux comparison
of M188 and M190 on one large unrelated blob
and one reached blob, while requiring identical
SHA-authenticated closure and unchanged stage/
index SHA256. **Timing cannot make CI fail.**
Linux filesystem/stdio benchmarks are NOT
predictive of the CMS C runtime.

## Conditional CMS test after host CI PASS

Mac in `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITPSKM.C GITPSK.EXEC
```

CMS MAINT preflight and build **new module only**:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
QUERY FILEDEF
STATE GITPSKM C A
CMSCLNK GITPSKM PLAIN
STATE GITPSKM MODULE A
```

If 4K G, protected files, clean caller DDs and
native compilation all pass:

```text
GITPSK G CCB18BEC067E7886D70B82EF138EE56A8B899A61
QUERY FILEDEF
```

Capture all output and actual CPU/elapsed, compare
with **M188 real elapsed 208.27s**. If CMS prints
`M190 STAGE SEEK UNSUPPORTED`, `M190 STAGE
SEEK HEADER MISMATCH`, or `M190 SEEK READBACK
FAIL`, stop that isolated experiment; do not
modify the protected index or import stage to
accommodate the test. A positive target PASS
would establish only one native timing sample;
repeat to assess meaningful speedup.

No ERASE, FORMAT, repeated M173/M174 import/index
build, original module replacement, permanent
G stage/index writes or write-link of physically
overlapping PMAINT 0141 wholepack is authorized.


---

## Original docs/M191_CMS_SEEK_PROBE.md

# M191 — Direct console probe of CMS text-stream seeking

## October 11, 2026 — M191 real CMS FIRST and MID PASS; slow seeks

The operator compiled `GITPRBM MODULE` successfully with
`CMSCLNK GITPRBM PLAIN`, assembler XF DONE,
no flagged statements, `Ready; T=2.63/2.74`
at 14:58:54. Two **actual CMS** independent
`GITPRB G` read-only indexed header probes passed:

```text
GITPRB G FIRST
M191 DIRECT CMS SEEK PROBE BEGIN FIRST
M191 INDEX READY 7736 UNIQUE 7736
M191 PROBE FIRST RECORD 1 OFFSET 0
M191 SEEK BEGIN FIRST
M191 SEEK RETURNED FIRST
M191 SEEK HEADER PASS FIRST RECORD 1
M191 READ ONLY SEEK PROBE PASS
M191 CMS SEEK PROBE GATE PASS G FIRST
Ready; T=0.63/0.64 14:59:02

GITPRB G MID
M191 DIRECT CMS SEEK PROBE BEGIN MID
M191 INDEX READY 7736 UNIQUE 7736
M191 PROBE MID RECORD 3868 OFFSET 127843709
M191 SEEK BEGIN MID
M191 SEEK RETURNED MID
M191 SEEK HEADER PASS MID RECORD 3868
M191 READ ONLY SEEK PROBE PASS
M191 CMS SEEK PROBE GATE PASS G MID
Ready; T=25.12/25.82 14:59:51
```

**Conclusion:** CMS accepted both `fseek` calls and
returned the exact indexed object-header identity.
But the MID invocation took **25.12s CPU and
25.82s elapsed**, compared with **0.63s CPU,
0.64s elapsed** for FIRST. This is consistent
with expensive, position-dependent text-stream
repositioning. Two timings alone do **not**
establish asymptotic complexity or per-seek cost,
and the elapsed figures include initial index
reading and all wrapper overhead. Do NOT run
full M190 `GITPSK G ...` with 272 seeks on
the assumption that random access is cheap.
M190 had earlier been interrupted with HX and
has **never** emitted a complete target PASS.

The supplied transcript includes **no post-run
`QUERY FILEDEF`** after either probe. One
standalone `QUERY FILEDEF` would check hygiene.
`GITPRB G LAST` has **not** been run; do not
claim it passed, and no need to attempt it
while investigating record-oriented alternatives.

IBM z/VM documents a separate CMS record-I/O
interface: FSREAD supports an absolute RECNO
on CMS files; a future new, isolated assembler
adapter may use the native record number rather
than expensive C text `fseek` on encoded
stream positions. This approach is **not yet
implemented or target-validated**. First,
host-test a mapping from index object numbers
and sizes to physical CMS record numbers, then
confirm the target file format and record count
without writing any G data.

Proven working two-scan baseline remains M188:
**205.04s CPU, 208.27s elapsed**; M185 real
elapsed **209.97s**. Preserve all working
modules, GIT600, M173NET STAGE G, M174NET
INDEX G. No formatting, rebuilding, importing,
or write-linking overlapping PMAINT 0141.

---

## Why this diagnostic exists

On October 11, the actual z/VM 6.3 operator built
`GITPSKM MODULE` successfully:
```text
CMSCLNK GITPSKM PLAIN
ASSEMBLER (XF) DONE
NO STATEMENTS FLAGGED IN THIS ASSEMBLY
CMSCLNK: built GITPSKM MODULE mode PLAIN
Ready; T=2.40/2.50 14:09:04
GITPSK G CCB18BEC067E7886D70B82EF138EE56A8B899A61
HX
CMS
```

There is **NO** `M190 SEEK PREFLIGHT PASS 3`,
`M190 TREE CLOSURE PASS`, wrapper target PASS or
final `Ready`. Accordingly **M190 did NOT pass
real target validation** and no performance figure
can be claimed. IBM z/VM documents **HX as the
Halt Execution immediate command**. `CMS` is
consistent with a return to CMS command mode.
The data does **not** establish why execution
was interrupted. IBM additionally documents
that HX clears existing FILEDEF definitions;
a fresh `QUERY FILEDEF` should still be run.

The M190 wrapper invokes `PIPE CMS GITPSKM WALK ...
| STEM o.`, which buffers command output until
the native program terminates. Thus even if
M190 printed preflight progress internally, it
may not have appeared on the console during a
long-running or stuck operation. IBM CMS C
stdio/PDPCLIB `fseek` on huge variable-record
text-stage files is **not target-verified**.

## M191 isolated direct-console, read-only diagnostic

M191 introduces new, distinct names:
- `src/GITPRBM.C` => `GITPRBM MODULE A`;
- `src/GITPRB.EXEC` => `GITPRB EXEC A`.

The C source is isolated from the prior M190
code, adding `PROBE FIRST|MID|LAST` to select
a **single** native index entry by physical
stage object number. The probe:
1. Reads and validates original `M174NET INDEX G`
   without changing it; builds its checked index
   mapping.
2. Selects original physical object 1, about
   halfway (3,868 on G), or object 7,736.
3. Prints `M191 INDEX READY`,
   `M191 PROBE ... OFFSET` and
   `M191 SEEK BEGIN ...`, flushing stdout.
4. Opens original stage **read-only**, performs
   a single `fseek(offset, SEEK_SET)`, and prints
   `M191 SEEK RETURNED` as soon as that call
   completes.
5. Requires returned `ftell()` to match the
   verified index offset, reads **one** stage
   header, checks exact num/type/size/SHA OID
   against the index, and reports
   `M191 READ ONLY SEEK PROBE PASS` or FAIL.
6. Releases the index and closes the stream.
   No tree walk, full stage scan, random blob
   readback, import, file write or reindex.

Unlike M190, the REXX wrapper invokes the MODULE
**directly** with `'GITPRBM PROBE' which` rather
than `PIPE CMS ... | STEM`. Its immediate `SAY`
and native `fflush(stdout)` markers make
preflight progress visible if the console is
responsive. The wrapper checks the 4K non-A
G disk, original stage/index presence, native
module, no conflicting caller DD definitions,
and binds then clears only temporary read-only
STGIN/IDXIN FILEDEFs. It refuses to report
target PASS on a failed probe.

Host regression `tests/test-m191-cms-seek-probe.py`
strictly compiles with C89 `-Wall -Wextra -Werror`,
checks first/middle/last selected indexed headers,
deliberately corrupts each disposable indexed seek
position and requires RC8, checks exact module
vs EXEC names and direct console invocation,
and asserts original fixture stage/index SHA256
unchanged. **Host passing does not mean CMS
seeking works or is fast.**

## Exact minimal target commands

On Mac from `ibm-sandbox/src` after GitHub merge:

```sh
git pull
./cms-upload.sh GITPRBM.C GITPRB.EXEC
```

On CMS MAINT, start with the inexpensive original
input/FILEDEF checks:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
QUERY FILEDEF
STATE GITPRBM C A
CMSCLNK GITPRBM PLAIN
STATE GITPRBM MODULE A
```

If native build/preflight succeeded, run **only
the first seek probe initially**:

```text
GITPRB G FIRST
QUERY FILEDEF
```

It is not necessary to run M190 WALK again.
Expected successful console sequence includes:
```text
M191 DIRECT CMS SEEK PROBE BEGIN FIRST
M191 INDEX READY 7736 UNIQUE 7736
M191 PROBE FIRST RECORD 1 OFFSET ...
M191 SEEK BEGIN FIRST
M191 SEEK RETURNED FIRST
M191 SEEK HEADER PASS FIRST RECORD 1
M191 READ ONLY SEEK PROBE PASS
M191 CMS SEEK PROBE GATE PASS G FIRST
```

If FIRST completes quickly and cleanly, test
the midpoint separately, retaining visibility
into the exact fseek call:

```text
GITPRB G MID
QUERY FILEDEF
```

Then optionally:
```text
GITPRB G LAST
QUERY FILEDEF
```

If a `SEEK BEGIN` prints and no matching
`SEEK RETURNED` arrives, the repositioning
operation may be extremely slow or blocked.
Do not treat that as a Git-index integrity
failure without further evidence. If the
operator explicitly chooses HX, IBM documents
that it terminates the running program and
returns to CMS; any interrupted probe remains
**unverified**, and fresh `QUERY FILEDEF`
is appropriate. If `FSEEK FAILED` or
`SEEK HEADER MISMATCH` prints, collect the
exact output and stop the seeking experiment.

No ERASE/FORMAT, stage reimport, index rebuild,
original-module overwrite, original protected
G STAGE/INDEX write, or write-link overlapping
PMAINT 0141 fullpack is authorized.
Proven alternatives M185 and M188 stay intact:
M188 positive-path CPU 205.04s, elapsed
208.27s with two forward scans, no seeks;
M185 positive-path elapsed 209.97s.


---

## Original docs/M192_RECORD_NUMBER_PLAN.md

# M192 — native CMS record-number plan from verified object sizes

## Why record numbers now matter

M191 actually passed FIRST (`offset 0`, 0.64s elapsed)
and MID (`offset 127843709`, 25.82s elapsed)
on z/VM 6.3 CMS, with exact expected indexed
headers and native/wrapper PASS. This confirms
`fseek` is functional on those two C text
positions but very costly at the tested
midpoint. It does not establish linear
complexity from only two timings.
**Do not repeat full M190's 272-seek walk.**
The LAST probe has not run. No post-probe
`QUERY FILEDEF` was included in the transcript.

IBM documents the CMS **FSREAD macro** with
`RECNO` as an absolute, **one-based logical
record number** for both fixed and variable
record files. See
https://www.ibm.com/docs/SSB27U_7.2.0/com.ibm.zvm.v720.dmsa6/fsread.htm .
The CMS assembler file-system macro APIs
can be used by a new, isolated native adapter.
**M192 does not implement FSREAD** or change
the Git reader. It first answers a narrower
question: can the stage record ordinal of
each object be inferred from the already
indexed Git object size, without a scan
or expensive C text seek?

## Read-only model

The M173 stage format used by our host and
native readers has one `OBJ ...` header
record followed by ASCII/EBCDIC hex record
chunks of at most 32 decoded bytes each.
The existing stage writer emits one empty
body record for zero-length objects.

For a positive body byte size `n`, the
number of hex body records is
`ceil(n / 32)`; for size zero, one empty
record is expected. Therefore:

```text
body_records(n) = max(1, ceil(n / 32))
record_no(object 1 header) = 1
record_no(object i+1 header) =
    record_no(object i header) + 1 + body_records(size_i)
total_records = record_no(last header) +
    body_records(last size)
```

This is a **physical-line count hypothesis**
that is independently testable. It relies
on the existing stage's one-record-per-hex-line
representation. A CMS record-format difference
or unexpected extra/zero-length record causes
the model to disagree with the reported native
3,864,799 stage text records. The model then
fails closed without reading or modifying G.

## M192 new files

`src/GITRCNM.C` is an isolated, strict C89,
**index-only** reader: it opens `dd:IDXIN`
read-only, validates the PIDX1 header, PEND1
trailer, sorted and unique 40-character
Git OIDs, unique physical object numbers,
bounded sizes, nonnegative saved offsets
and complete 7736-of-7736 mapping. It then
calculates the first/middle/last object
header's one-based CMS physical record
numbers and the full estimated stage record
count. It **never opens STGIN** and performs
no random seek, full scan, stage hash or
native tree walk. It accepts an explicit
expected stage-record count and returns RC8
if the computed total differs. It does not
claim this proves actual record contents.

`src/GITRCN.EXEC` calls the different-stem
`GITRCNM MODULE` directly (no PIPE/STEM),
preflights the 4096-byte G disk and
original protected stage/index presence,
rejects caller IDXIN conflicts, binds only
the temporary, read-only IDXIN FILEDEF
and clears it after a normal return.
It does not bind or open STGIN.

`tests/test-m192-record-plan.py` constructs
a disposable **7736-object** native stage
with zero-length, short, partially filled,
32/64-byte boundaries and varied body
sizes; builds a disposable native index,
checks computed physical record positions
and total against its actual text lines,
rejects damaged OIDs, duplicate physical
numbers and an incorrect expected count,
and verifies stage/index SHA256 unchanged.
It compiles C as `-std=c89 -Wall -Wextra
-Werror` on the host.

## Next cheap, nondestructive CMS validation

Mac in `ibm-sandbox/src` after host CI
success/merge:

```sh
git pull
./cms-upload.sh GITRCNM.C GITRCN.EXEC
```

CMS MAINT:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
QUERY FILEDEF
LISTFILE M173NET STAGE G (ALLOC
STATE GITRCNM C A
CMSCLNK GITRCNM PLAIN
STATE GITRCNM MODULE A
```

With successful 4K G/index preflight
and a clean caller IDXIN definition:

```text
GITRCN G 3864799
QUERY FILEDEF
```

Expected model PASS **only if** the original
7,736 indexed object sizes collectively
predict exactly 3,864,799 stage text records.
The output will additionally reveal the
header record ordinal for native physical
object 1, 3,868 and 7,736, and original
saved byte offsets. Those record ordinals
would be inputs for a *future* FSREAD
adapter experiment; **do not use them as
C fseek offsets**.

The `LISTFILE ... (ALLOC` step is informational
and should establish the original G file
record format and logical LRECL/record count,
without opening it for writing.

## Scope and safety

M192 is a model, not a speedup and not a
fully authenticated tree reader. Any future
FSREAD integration requires a separate CMS
assembler adapter, safe C/assembler calling
convention, exact CMS record bytes/length
handling, independent read-only tests,
and full SHA/OID validation of reached
blobs before accepting a target PASS.

Do not alter or reindex `M174NET INDEX G`,
reimport `M173NET STAGE G`, format GIT600,
overwrite M185/M188/M190/M191, or write-link
physically overlapping `PMAINT 0141`.
M188 (elapsed 208.27s, CPU 205.04s)
remains the fastest positive-path CMS
reader actually reported.



---

## Original: docs/M193-M200_HISTORY.md (complete original file)

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



---

## Original: docs/M165-M166_HISTORY.md (complete original archive)

# M164–M170 milestone history and practical porcelain

## M164 (original docs/M164_PRACTICAL_PORCELAIN.md)

# M164 practical CMS worktree porcelain

M164 is the first practical write-side porcelain milestone after the
read-only/history series.

It adds these public commands:

```text
GIT IMPORT-OBJECT <oid>
GIT CHECKOUT-FILE <ref> <git-path> <cms-fn> <cms-ft> [fm]
GIT STATUS
GIT ADD <git-path>
```

It also adds internal exact-workfile primitives:

```text
GIT HASH-WORKFILE <fn> <ft> <fm> <final-lf-0-or-1>
GIT WRITE-WORKFILE <fn> <ft> <fm> <final-lf-0-or-1>
```

## Verified native-to-loose import

`GIT IMPORT-OBJECT` binds the existing dual selected generations and runs
the target-proven `GITREC CATHEX` path. The selected object is fully
GENCHECK-verified and independently rehashed before its complete body is
emitted. Only COMMIT/TREE/BLOB objects are currently accepted into the loose
`GITOBJ` store. The newly written loose object is then verified again by
`GIT VERIFY-OBJECT`.

The sealed GITFIX/M15NEW generations are never modified.

## CMS worktree model

M164 uses `GITWORK REPO A` as a small persistent worktree index. Each entry
records:
- exact Git path as ASCII hex;
- CMS filename/filetype/filemode;
- whether the Git blob ends with a final LF;
- checkout/base blob OID;
- staged blob OID.

The first implementation deliberately limits mapped paths to 30 ASCII bytes.
It is a safe initial bridge for the current flat CMS-compatible `src/`
subtree and can be extended later without changing the object model.

`CHECKOUT-FILE`:
- resolves HEAD/branch through verified `GITREF2 REPO A`;
- invokes `GITREC PATHFULLCAT` directly;
- requires complete commit-root closure verification;
- accepts text bytes only in M164;
- rejects lines longer than CMS LRECL 80;
- refuses to overwrite any existing CMS file;
- writes a fixed-record CMS workfile;
- immediately re-hashes the CMS workfile and requires the original Git blob
  OID before recording the mapping.

`STATUS` independently hashes each mapped CMS file and compares worktree,
stage, and base OIDs. It reports CLEAN, MODIFIED, STAGED, or
STAGED+MODIFIED.

`ADD` writes the exact current CMS text representation as a loose Git blob,
updates only the staged OID in GITWORK, and leaves the base OID unchanged.

CMS fixed-record padding is removed only at the record tail; leading
indentation is preserved. The final-LF bit preserves normal Git text-file
round trips.

## Disposable real-CMS gate

`M164CHK` is self-cleaning and refuses to start unless both
`M164TST DATA A` and `GITWORK REPO A` are absent.

It performs:
1. authenticated checkout of `src/GITVREF.EXEC` at HEAD to disposable
   `M164TST DATA A`;
2. initial STATUS and base=stage map verification;
3. replacement of the disposable file with one test record;
4. independent modified workfile hash;
5. STATUS showing the modified state;
6. `GIT ADD src/GITVREF.EXEC`;
7. staged OID verification and STATUS;
8. `GIT VERIFY-OBJECT` of the new loose blob;
9. erasure of only the disposable CMS file, worktree map, and newly-created
   loose object.

The protected GITFIX/M15NEW generations and selector files are read-only
throughout.

## Host proof

GitHub Actions native-stage run `37638057399` completed successfully on
M164 code head `c3bcd5fb577a2ab317b5ed31b73cb2bc7c8200b3`.
The run included all earlier M156-M163 checks, the M164 independent worktree
model, native selector tests, full CATHEX/tree recovery, and native
PACK/index tests.

The disposable gate also verifies native-to-loose IMPORT-OBJECT and removes\nthat imported loose object during cleanup.\n\nThe remaining acceptance boundary is real CMS execution of `M164CHK`.

---

# M165–M166 archive

## M165 (original docs/M165.md)

# M165 staged commit milestone

M165 creates a loose child commit from exactly one staged tracked CMS path.

Safety boundaries:
- HEAD and every base tree are authenticated through GITREC.
- The staged path must still match its checkout base in current HEAD.
- The workfile must exactly match the staged blob; unstaged changes fail.
- Only ancestor trees on the staged path are rewritten.
- The current HEAD commit is imported as the parent.
- The new commit is verified after creation.
- M165 does not update any ref. Ref compare-and-swap is a later milestone.

The real-CMS checker retains the verified loose commit candidate so the next
ref-CAS milestone can advance an isolated ref to the proven commit.


## M166 (original docs/M166.md)

# M166 modern REF2 compare-and-swap

M166 moves `GIT UPDATE-REF` from the obsolete `GITREFS REPO A` prototype
onto the active `GITREF2 REPO A` database.

The command requires three arguments:

```
GIT UPDATE-REF refs/heads/name new-oid expected-old-oid
```

CAS semantics use Git-style zero object IDs:

- expected old `000...000` creates the ref only if it is absent;
- new `000...000` deletes the ref only if the expected old OID matches;
- nonzero updates require an exact expected old OID;
- stale comparisons return RC 8 without writing REF2;
- the symbolic HEAD target cannot be deleted.

Every nonzero target must be a locally present loose COMMIT and must pass
`GIT VERIFY-OBJECT` before REF2 can move to it.

The real-CMS M166 checker uses only `refs/heads/m166test`. It points that
disposable ref at the retained M165 commit
`D6FB8432692CF8EFBDC2DDA354425D8DCDC3A008`, proves a stale CAS leaves
REF2 byte-for-byte unchanged, then deletes the disposable ref with an exact
CAS and requires the entire REF2 file to match its initial snapshot again.

Neither `HEAD` nor `refs/heads/main` is moved by the M166 checker.

---

# M167–M170 historical archive (original docs/M167-M170_HISTORY.md)

# M167–M170 historical milestone archive

Original separate files remain recoverable through Git history. This archive preserves their complete text.

---

## Original docs/M167.md

# M167 integrated staged commit to disposable ref

M167 composes the two write boundaries proven separately by M165 and M166.

The command is:

```
GIT COMMIT-STAGED-REF refs/heads/name expected-old-oid \
  -T seconds -Z zone -M message
```

The worktree/commit side is delegated to the already-proven M165
`GITWT COMMIT` path. Its output must contain exactly one staged parent and
exactly one staged commit OID. The parent must equal the caller-supplied
expected old OID before any ref update is attempted.

The ref move is delegated to M166 `GIT UPDATE-REF` using that exact expected
old OID. After CAS, M167 resolves the moved ref through the verified REF2
bridge. If post-CAS verification fails, M167 attempts an exact CAS rollback
from the new commit back to the expected old OID.

M167 does not move symbolic HEAD by itself. The real-CMS target checker uses
only `refs/heads/m167test`. It initializes that disposable branch at current
HEAD, stages a deterministic change to the sealed `src/GIT.EXEC` fixture,
runs the integrated command, proves only the disposable branch advanced,
verifies the new commit, then deletes the disposable branch and requires
`GITREF2 REPO A` to return byte-for-byte to its baseline snapshot.

Because HEAD remains on `refs/heads/main`, worktree STATUS remains STAGED
after the disposable branch advances. Updating the current symbolic HEAD
branch and reconciling the worktree map is intentionally deferred to a later
milestone.


---

## Original docs/M168.md

# M168 current-branch commit reconciliation

M168 turns the separately proven M167 commit-to-ref operation into current
branch porcelain while keeping worktree state coherent.

`GIT COMMIT-CURRENT` reads the symbolic `HEAD` ref and its exact old OID
from modern `GITREF2 REPO A`. It delegates object creation and compare-and-
swap ref advancement to `GIT COMMIT-STAGED-REF`. After the branch move,
`GITWT ACCEPT` verifies that the mapped workfile still hashes to the staged
blob, promotes `BASE=STAGE`, writes the worktree map, rereads it, and
requires the accepted map to be self-consistent.

If worktree acceptance fails after the ref CAS, `GIT COMMIT-CURRENT` uses
the new commit OID returned by M167 and performs an exact CAS rollback of the
current branch to its old commit.

The real-CMS checker does not move `refs/heads/main`. It snapshots REF2,
creates a temporary `refs/heads/m168test` at the sealed HEAD commit, and
temporarily points symbolic HEAD at that disposable branch. It then performs a
single-file staged commit through `GIT COMMIT-CURRENT`, requires the
disposable current branch to advance to a new verified commit, and requires
`GIT STATUS` to report TRACKED 1, CHANGED 0, STAGED 0.

Finally the checker restores the entire original REF2 file byte-for-byte,
removes disposable worktree files, and leaves the newly created loose commit
available for later milestones.


---

## Original docs/M169.md

# M169 generalized smart-HTTP discovery

M169 begins the post-porcelain network phase recorded after M163/M168.

The old M12 transport proved real GitHub smart-HTTP end-to-end, but its live
discovery and upload-pack POST commands hard-coded both the repository path and
historical wanted OID. M169 removes the first of those assumptions.

Public command:

```
GIT FETCH-DISCOVER bridge-host bridge-port authority owner/repo branch
```

`GITFETCH DISCOVER` builds the HTTP GET request dynamically, requires raw
REXX/SOCKETS with SO_ASCII OFF, bounds each receive to 256 bytes and the total
response to 4 MiB, validates HTTP 200 plus the Git upload-pack advertisement
content type, decodes HTTP/1.1 chunked transfer coding, and parses v0/v1 Git
pkt-lines incrementally.

The parser requires the service announcement and flush framing, validates every
advertised OID/ref pair, permits at most 10,000 refs and 4,096-byte pkt-line
payloads, requires exactly one requested branch, and requires the capabilities
`side-band-64k` and `ofs-delta` needed by the next generalized upload-pack
request milestone.

M169 intentionally does not overwrite or reuse the preserved M11BODY/M12BODY
or GITPBUF PACK captures from the target-proven M12 transport work. Parsing is
performed in bounded in-memory state only.

The real-CMS gate performs one live discovery through the existing practical
EC2 stunnel bridge:

```
GIT FETCH-DISCOVER 192.168.200.1 8443 \
  github.com mostangrymike/ibm-sandbox main
```

It does not POST or download a PACK. M170 will use the dynamically advertised
OID from this generalized boundary to construct the upload-pack request.


---

## Original docs/M170.md

# M170 dynamic upload-pack POST

M170 composes the target-proven M169 generalized discovery with a generalized
smart-HTTP upload-pack POST.

Public commands:

```
GIT FETCH-DISCOVER bridge port authority owner/repo branch
GIT FETCH-POST bridge port authority owner/repo oid
```

The M170 target gate never uses a historical hard-coded wanted OID. It captures
the short `FETCH OID <40-hex>` record from the immediately preceding live
discovery and passes that exact OID into `FETCH-POST`. The POST converts the
wire OID to lowercase, generates pkt-line length and HTTP Content-Length
dynamically, and requests only `side-band-64k` and `ofs-delta`, preserving
the minimal request shape target-proven in M12.

The POST response is consumed completely but not persisted. The parser requires
HTTP 200, upload-pack result content type, chunked transfer coding, one NAK,
valid pkt-line framing, side-band channels, no channel-3 fatal packet, and a
channel-1 PACK stream whose first 12 bytes contain PACK plus version 2/3 and a
nonzero object count.

Only bounded state is retained: counters and the first 12 PACK header bytes.
The receive size is 256 bytes, individual HTTP chunks are bounded to 1 MiB,
pkt payloads to 65,516 bytes, and the complete HTTP wire response to 16 MiB.

M170 deliberately does not read or overwrite M11BODY, M12BODY, GITPBUF, or
GITPMETA. A later milestone can add a new generalized PACK persistence path
without mutating the preserved M12/native benchmark fixture.



---

## Original: docs/M171-M176_HISTORY.md (complete original archive)

# M171–M176 historical milestone archive

Verbatim historical documentation; original paths remain in Git history. No source/test/module changes.

---

## Original docs/M171.md

# M171 generalized PACK persistence

M171 extends the target-proven M170 dynamic upload-pack POST with a safe,
separate persistence path for the newly fetched live PACK.

Public command:

```
GIT FETCH-STORE bridge port authority owner/repo oid cmsfn
```

`cmsfn` must be a new 1-8 character alphanumeric CMS filename. The command
refuses to run if either `cmsfn PACK A` or `cmsfn META A` already exists.
Only side-band channel 1 bytes are written. The writer batches 64-byte PACK
records as 128 hex characters and removes partial PACK/META files on any
transport, HTTP, pkt-line, side-band, or finalization failure.

On success, `cmsfn META A` records the wanted OID, persisted PACK byte count,
PACK version, and declared object count.

M171 adds standalone native `GITPCHK.C`. It streams hex records through
`FILEDEF PACKIN` without loading the complete PACK into memory. It validates
the PACK signature, version 2/3, nonzero declared object count, and Git PACK
SHA-1 trailer by retaining only SHA-1 state plus the final 20 bytes.

The real-CMS checker stores to `M171NET PACK A` / `M171NET META A`,
cross-checks POST counters against META, then cross-checks both against
`GITPCHK`. Successful files are intentionally retained for the next fetch
integration milestone. Any checker failure after storage erases the disposable
M171NET files.

The historical `GITPBUF PACK A` / `GITPMETA PACK A` fixture and fixed-size
`GITCWALK` path remain untouched. M171 does not enlarge or repurpose those
target-proven 340,027-byte / 1,808-object artifacts.


---

## Original docs/M172.md

# M172 generalized live PACK census

M172 consumes the retained, independently verified `M171NET PACK A`
without modifying it and proves that the current GitHub PACK is structurally
walkable object-by-object by native CMS code.

Public command:

```
GIT PACK-CENSUS
```

The caller FILEDEFs `PACKIN` to a verified PACK. The new native
`GITPCENS` module:

- accepts PACK v2/v3;
- bounds the full PACK to 16 MiB and the declared object count to 100,000;
- parses every ordinary, OFS_DELTA, and REF_DELTA entry header;
- validates OFS base-distance framing and REF base-id length;
- inflates each zlib member through the existing target-proven
  `GITCAPI/GITINFA` native inflater;
- requires inflated representation length to equal the PACK entry size;
- advances by the inflater's exact consumed-byte count;
- requires the final object boundary to equal exactly `PACK bytes - 20`.

M172 deliberately does not reconstruct deltas, compute object OIDs, stage
objects, build indexes, alter selectors, or write any persistent file.
It is the structural boundary between M171's arbitrary-size PACK persistence
and a later disk-backed generalized object importer.

The real-CMS checker reuses retained `M171NET PACK A` and
`M171NET META A`. It first reruns streaming `GITPCHK`, then runs
`GIT PACK-CENSUS` through the same `PACKIN`. Bytes, version, and object
count must agree between META, GITPCHK, and GITPCENS. The census must also
satisfy:

```
ordinary + ofs_delta + ref_delta = declared_objects
```

The historical `GITPBUF PACK A`, GITFIX, M15NEW, selector slots, staged
objects, indexes, and manifests remain untouched.


## Real CMS target result — 2026-10-08

M172 is real CMS target-proven against the retained M171 fetch. Native
`GITPCENS` completed RC0 with:

```
CENSUS PACK BYTES 2171129 VERSION 2 OBJECTS 7736
CENSUS ORDINARY 2432 OFS 5304 REF 0
CENSUS MAX INFLATED 393767 MAX COMPRESSED 122378
M172 PACK CENSUS PASS
M172 CENSUS CROSSCHECK PASS
M172 RETAINED PACK UNCHANGED M171NET PACK A
M172 GENERALIZED PACK CENSUS TARGET GATE PASS
```

The run took 29.26 CPU / 29.47 elapsed seconds. The retained PACK and META
remained unchanged. The zero REF_DELTA count permits the next isolated
integration milestone to reconstruct the complete current live PACK using a
fail-closed OFS-only importer without changing the sealed 1,808-object path.


---

## Original docs/M173.md

# M173 generalized OFS PACK import

M172 proved the retained live GitHub PACK is structurally walkable on real CMS:

- 2,171,129 PACK bytes;
- version 2;
- 7,736 objects;
- 2,432 ordinary objects;
- 5,304 OFS_DELTA objects;
- **0 REF_DELTA objects**;
- maximum inflated packed representation 393,767 bytes;
- maximum compressed member 122,378 bytes.

M173 uses those proven facts to cross the next integration boundary without
changing the sealed 1,808-object GITCWALK/GITFIX/M15NEW generation.

## Native importer

`GITPIMP` is a new isolated C89 module. Public `GIT PACK-IMPORT`
routes to `GITPIMP IMPORT`.

It accepts a caller-FILEDEF'd verified `PACKIN` and writes a caller-FILEDEF'd
`OBJOUT` in the existing CMS text-stage object format:

```
OBJ <number> <type> <size> <40-hex-OID>
<body hex in records of at most 32 decoded bytes>
```

The importer independently validates PACK signature, version, declared object
count, and trailer SHA-1. Bounds are explicit: PACK <= 16 MiB, at most 100,000
objects, and any one packed representation or reconstructed object <= 16 MiB.

M173 deliberately rejects REF_DELTA. That is fail-closed, not a hidden
limitation of the live gate: M172 independently proved the retained live PACK
contains zero REF deltas.

## Two-pass OFS dependency model

The first pass parses every entry, inflates every packed representation, records
exact zlib consumption, resolves each OFS base by PACK position, and counts how
many future objects depend on every base.

The second pass reinflates and reconstructs objects. A reconstructed base is
retained only while its precomputed future dependency count is nonzero and is
freed immediately after its last dependent has been reconstructed. Resident
reconstructed-object data is capped at 64 MiB. This avoids the old fixed
1,808-object arrays and avoids retaining all 7,736 reconstructed objects
indefinitely.

Every reconstructed object receives a canonical Git SHA-1 using explicit ASCII
object headers. The completed stage is closed before the independent readback
gate.

`GITPIMP VERIFY <count>` then rereads only `STGIN`, parses every staged
record, recomputes every canonical Git OID, requires exact object count, and
rejects trailing records.

## M173 CMS gate — current isolated data-disk contract

The checker `M173CHK G` reuses `M171NET PACK A` and
`M171NET META A` read-only. The filemode is a required argument, never A;
G is the planned separately provisioned permanent CMS data disk. The
checker first requires one accessed R/W 4096-byte-block CMS disk with at
least **180,000 free blocks**, and checks that `M173NET STAGE G` is absent
(STATE RC 28). It then reruns `GITPCHK`, binds PACKIN and OBJOUT under
the checker's exclusive FILEDEF ownership, directly executes
`GITPIMP IMPORT CHECKED`, cross-checks import counters against META,
and independently reopens and verifies the stage. It never overwrites an
existing stage, and **retains any failed output for diagnosis**: no ERASE
and no automatic retry while a partial stage exists. The success marker
is `M173 GENERALIZED OFS PACK IMPORT TARGET GATE PASS`.

**M173 is NOT target-proven.** Earlier CMS attempts on A failed and
one suffered system abend 001. The replacement isolated-disk checker is
host-tested but must not be run until the dedicated G disk has passed
the disk and backup gates documented in
`M173_PERSISTENT_DISK_RUNBOOK.md` and
`M173_EBS_RECOVERY_CHECKLIST.md`.

The historical `GITPBUF PACK A`, `GITFIX`, `M15NEW`, selectors, indexes,
and manifests are untouched.

Host coverage compiles the production source as strict C89, reconstructs
`abc -> abcd -> abcde` through chained OFS deltas, verifies the canonical
object IDs, rereads and rehashes the stage, proves a 70,000-byte object above the old
65,536-byte ceiling, proves existing-output non-overwrite, rejects REF_DELTA,
and rejects a corrupted PACK SHA-1.

## Historical CMS attempt: output-open correction (2026-10-08)

GITPIMP compiled in NAPI mode and the retained 7,736-object PACK passed
GITPCHK authentication and all M173 native prepass boundaries, ending at
offset 2,171,109. The importer then reported IMPORT OUTPUT EXISTS even though
the checker had already confirmed M173NET STAGE A was absent. No stage survived
the failure; the checker returned RC 8. This is **not** an import pass.

Root cause: fopen("dd:OBJOUT","r") on the CMS FILEDEF is not a reliable
physical-file existence predicate. The public named-output form now uses
CMS STATE on the concrete filename **before** it defines OBJOUT, fails closed
unless STATE reports the file absent (RC 28), and invokes the native
IMPORT CHECKED mode. Direct unqualified GITPIMP IMPORT retains its original
best-effort read-probe for host compatibility; only the STATE-guarded
public path is intended for production CMS output.

The checker invokes GIT PACK-IMPORT M173NET and independently rechecks the
stage after creation. This correction was host-tested in native-stage
Actions run 1327 (SUCCESS), along with the M174 analogous change.

Next real CMS gate: update only GIT.EXEC, GITPIMP.C and M173CHK.EXEC,
compile CMSCLNK GITPIMP NAPI, and rerun M173CHK. Preserve M171NET PACK/META
and historical protected generations.

## Historical CMS retry: abend 001 and FILEDEF ownership (2026-10-08)

The first CMS import attempt validated the 7,736-object prepass but failed
with IMPORT OUTPUT EXISTS: checking fopen("dd:OBJOUT","r") on the active
FILEDEF was not a valid test that M173NET STAGE A existed. The first
repair added the native IMPORT CHECKED mode and a public GIT
PACK-IMPORT M173NET wrapper. During the next real CMS run, GITPCHK
authenticated the live PACK but execution abended DMSABE148T 001.

IBM describes 001 for module DMSSTP as loss of the active FILEDEF FCB
pointer, and warns that FILEDEF clearing during an active operation may
cause it. The M173 checker still had an OBJOUT FILEDEF in scope when it
invoked the public GIT wrapper. That wrapper set its own OBJOUT FILEDEF
and then cleared it inside the active PIPE command. This overlapping
ownership is the leading diagnosis; the abend location itself has not
been traced to establish a definitive source-code instruction.

The isolated checker now keeps sole ownership of OBJOUT: it confirms
STATE M173NET STAGE A returns RC28 (not found), binds the output,
invokes PIPE CMS GITPIMP IMPORT CHECKED | STEM q. directly, then clears
the same FILEDEF only after the native PIPE returns. PACKIN stays
unchanged. No nested REXX dispatcher owns or clears the FCB during
import. The analogous M174 index checker was corrected ahead of CMS
testing. Host checks assert the single-owner command paths.

The aborted second run does not establish whether a partial M173NET
STAGE A exists. The next real CMS gate is to upload **only**
M173CHK.EXEC (plus any locally stale prerequisite files), then run
M173CHK. If its STATE preflight reports that M173NET STAGE A exists,
do not blindly delete it; inspect the disposable output first.
No repeat M171 fetch, M172 census, or GITPIMP recompile is required
for this checker-only change.


---

## Original docs/M174.md

# M174 generalized stage index

M173 produces a generalized, independently verified CMS text stage from the
retained live PACK. M174 adds a separate generalized index without modifying
the historical `GITCIDX`, `GITFIX`, `M15NEW`, selector, or generation formats.

## Native index

`GITPIDX` is an isolated C89 module with four commands:

```
GITPIDX BUILD
GITPIDX CHECK
GITPIDX AUDIT
GITPIDX GET <40-hex-oid>
```

Public `GIT PACK-INDEX` routes to `GITPIDX BUILD`.

`BUILD` reads caller-FILEDEF'd `STGIN`, requires sequential object numbers,
validates every staged body, and independently recomputes every canonical Git
OID before indexing it. It supports up to 100,000 stage objects and 16 MiB per
object. It records the `ftell()` cookie at each object header, sorts by OID,
collapses byte-identical duplicate OIDs to the earliest object number, rejects
any duplicate type/size conflict, and writes caller-FILEDEF'd `IDXOUT`.

The index is self-framing:

```
PIDX1 <total> <unique>
OID <oid> <object-number> <type> <size> <stage-cookie>
...
PEND1 <total> <unique>
```

An already-existing `IDXOUT` is not overwritten.

`CHECK` validates a reopened `IDXIN`, including total/unique bounds, strict OID
sort order, object metadata, nonnegative seek cookies, trailer counts, and no
trailing records.

`AUDIT` independently reopens both `IDXIN` and `STGIN`, sequentially rehashes
all staged objects, proves each object is covered by the sorted index, and
checks that each unique index entry's saved seek cookie names its earliest
staged occurrence.

`GET` performs a bounded binary OID lookup, seeks directly into `STGIN`, and
rehashes the selected object before returning its metadata.

## M174 target gate — current isolated data-disk contract

`M174CHK G` requires retained `M173NET STAGE G`, refuses an existing
`M174NET INDEX G` (STATE must return RC 28), and requires an accessed,
R/W 4096-byte-block data disk with at least **4,096 free blocks**.
It reads the wanted/main OID and total object count from
`M171NET META A` **without modifying A**, then:

1. builds `M174NET INDEX G` with exclusive checker-owned IDXOUT
   FILEDEF and direct `GITPIDX BUILD CHECKED`;
2. cross-checks total objects against the retained PACK META;
3. reopens and checks the completed index;
4. audits every staged object against the retained M173 stage;
5. directly looks up the original fetched main commit OID and requires type 1.

The successful index is retained for the next generalized object-access
milestone. Any failed index is **retained for diagnosis**; the checker
does not ERASE it or overwrite a previous index. M174 requires a real
CMS PASS for M173 first, and is not yet target-proven.

Host coverage includes duplicate OID collapse, strict index/trailer validation,
direct GET with independent rehash, full-stage corruption detection,
existing-index non-overwrite, and a 70,000-byte object above the old
65,536-byte ceiling.

## Historical CMS output guard following M173 prepass failure

M173 exposed that a CMS FILEDEF of a nonexistent DISK output can be opened
for input by C without proving the actual CMS file exists. M174 BUILD used
the same invalid fopen("dd:IDXOUT","r") existence shortcut. It now has
BUILD CHECKED for callers that have completed a concrete CMS STATE
nonexistence check. The earlier public GIT PACK-INDEX M174NET form checked
M174NET INDEX A with STATE before binding IDXOUT, rejected unexpected
STATE return codes and existing files, then invoked BUILD CHECKED.
This A-disk description is historical, not the present target workflow.

The isolated M174 checker retains its own preflight and invokes the
native index module directly, with no nested wrapper controlling IDXOUT.
It does not modify an existing M173 stage, GITFIX, M15NEW, selector or
manifest. M174 requires real CMS M173 import/readback PASS first.

## Preventive M174 FILEDEF ownership correction

M173 exposed a CMS system abend 001 with nested output FILEDEF
management inside PIPE CMS GIT. The isolated M174 checker retains
exclusive IDXOUT FILEDEF ownership while running
PIPE CMS GITPIDX BUILD CHECKED | STEM b. It does not route the
internal test through a public GIT wrapper that might redefine and
clear the active DD name. Its preflight requires CMS STATE on the
M174NET INDEX G destination to report RC28 before any output open.
M174 still awaits the successful M173 retained-stage gate.


---

## Original docs/M175.md

# M175 verified generalized object access

M173 reconstructs the retained live PACK into an independently verified stage,
and M174 adds a fully audited OID index with seek cookies. M175 turns those
artifacts into authenticated random-access Git objects without changing the
sealed 1,808-object generation.

## GITPCAT

The new isolated C89 module `GITPCAT` consumes caller-FILEDEF'd `IDXIN` and
`STGIN`:

```
GITPCAT INFO <40-hex-oid>
GITPCAT CAT  <40-hex-oid>
```

`INFO` and `CAT` first validate the complete PIDX1/PEND1 index framing and
strict OID order, locate the requested OID, seek to the saved stage cookie,
reread the exact staged header/body, and independently recompute its canonical
Git SHA-1. No object is returned unless this verification succeeds.

`INFO` emits only bounded metadata. `CAT` additionally emits the verified body
as `PACKOBJ HEX` records containing at most 32 decoded bytes each. This keeps
the CMS line width below 80 and avoids putting arbitrary object bodies into the
M175 REXX checker.

For commit objects, GITPCAT parses raw Git bytes using explicit ASCII byte
constants, never native C string bytes. It emits the verified root tree OID,
each parent OID, and the parent count before optional body output.

Public `GIT PACK-CAT <oid>` routes to `GITPCAT CAT <oid>`.

## M175 target gate — current isolated data-disk contract

`M175CHK G` binds the retained `M173NET STAGE G` and
`M174NET INDEX G`, reads the wanted/current-main OID from
`M171NET META A` without modifying A, and uses bounded
`GITPCAT INFO` calls to prove:

1. the fetched main OID is an independently rehashed commit;
2. its raw Git commit bytes yield a syntactically valid tree OID;
3. that root tree is present, indexed, seekable, rehashed, and type TREE;
4. every immediate parent is present, indexed, seekable, rehashed, and type
   COMMIT.

The checker limits immediate parents to 64 and never captures object body data
in a REXX stem. It writes no persistent files. It remains unproven on real
CMS pending successful M173 and M174 target gates.

Host coverage builds a PIDX1 index through the production M174 code, reads a
synthetic child commit with an actual parent and empty-tree OID, proves INFO has
no body output, proves CAT returns the exact body, validates parent/root lookup,
tests a 70,000-byte blob, and rejects corruption of the selected staged body.


---

## Original docs/M176.md

# M176 verified live root-tree closure

M175 proves authenticated random access to the fetched main commit, its root
tree, and immediate parents. M176 follows the root tree recursively and verifies
the complete current filesystem object graph through the generalized M173/M174
stage and index.

## GITPTRE

The isolated C89 module `GITPTRE WALK <tree-oid>` validates the complete
PIDX1 index, requires the root OID to name a TREE, and recursively walks raw Git
tree bytes. Every reachable local TREE and BLOB is sought through the saved
M174 stage cookie and independently rehashed before use.

Raw tree parsing uses numeric ASCII byte values. Supported Git modes are:

- 40000: subtree, which must resolve to a local TREE;
- 100644 and 100755: file blobs;
- 120000: symbolic-link blob;
- 160000: gitlink, counted as an external leaf and intentionally not required
  to exist in this repository's object index.

All other modes fail closed. Tree entry names must be nonempty, NUL terminated,
and contain no slash.

Each indexed local OID is verified at most once. The walker detects traversal
cycles, caps depth at 256, caps each object at 16 MiB through the shared format,
and caps simultaneously resident verified bodies at 64 MiB. It reports tree,
blob, gitlink, entry, verified-object, maximum-object, and peak-resident counts.

Public `GIT PACK-TREE <tree-oid>` routes to this walker.

## M176 target gate — current isolated data-disk contract

`M176CHK G` binds `M173NET STAGE G` and `M174NET INDEX G`,
retrieves the retained M171 wanted/main commit through bounded
`GITPCAT INFO` (META remains on A, read-only), extracts its
verified root tree OID, and runs the complete recursive closure walker.

The checker requires the root to match the commit, at least one tree, verified
objects to equal trees plus blobs, sufficient tree entries to cover all unique
reachable local objects plus gitlinks, and the index total to equal the original
retained PACK object count. It writes no persistent files. It is not yet
real-CMS-proven; successful M173–M175 target gates are prerequisites.

Host coverage proves nested trees, regular blobs, an executable-compatible mode
path, a symlink blob, a 70,000-byte blob, an external gitlink, full closure
counts, selected-body corruption rejection, and a structurally valid index whose
root tree references a missing local child.



---

## Original: docs/M155-M163_HISTORY.md (complete original history)

# M155–M163 historical milestone archive

This file preserves verbatim the nine historical milestone documents that previously existed as separate files under `docs/`. The original paths remain available in Git history. This is documentation-only consolidation; target-proven modules, sources, tests, and CMS files are unchanged.

---

## Original: `docs/M155_COMPACT_GATE.md`

# M155 compact CMS acceptance output

M153 and M154 are native CMS target-proven as of 2026-10-05. Future target gates should request only a small acceptance subset from the CMS transcript: the full-snapshot verification marker, the decisive milestone summary counts, any one required transition/status line, DATA END when applicable, and the following Ready line. The full authenticated command output remains diagnostic evidence but does not need to be pasted into chat unless a compact gate fails.

For presence-history gates, a sufficient successful transcript is normally 4-6 lines plus Ready. On failure, capture the complete command output for diagnosis.

---

## Original: `docs/M156_PRESENCE_DURATION.md`

# M156 authenticated closed presence duration

M156 adds:

`GIT HISTORYFIRSTPRESENCEDURATION-REF-FULL <commit|ref> <depth> <path>`

The command reuses the authenticated first-parent presence runs from M151-M154.
It reports duration only for a presence run that is bounded by authenticated
ADDED/DELETED transitions on both sides. Current/open and oldest/truncated runs
are not treated as fully closed durations.

For each closed run, the duration is the signed time difference between the
child commit that begins the run and the newer child commit that ends it.
Author and committer clocks are tracked independently. A PRESENT closed run
must begin at ADDED and end at DELETED; an ABSENT closed run must begin at
DELETED and end at ADDED. Violations fail closed.

## Sealed target fixture

Commit:
`486ADAA5B02080720F4B329C6F68550B13C6AA87`

Depth: 5

Path: `src/GITPBWALK.EXEC`

Expected presence states are ABSENT, PRESENT across four commits, ABSENT.
Therefore there are three presence runs and exactly one closed run:

- run 2 state PRESENT
- begin edge 5 status ADDED
- end edge 1 status DELETED
- author duration 50 seconds
- committer duration 50 seconds

## Compact real-CMS gate

Upload `GITVREF.EXEC`, `GIT.EXEC`, and `M156CHK.EXEC`, then run only:

`M156CHK`

At the current M157 wrapper level, success output is three lines. The checker accepts any synchronized level M156 or newer:

```text
M156 LEVEL PASS M157/M157
M156 DURATION PASS RUN 2 PRESENT 50/50
M156 COMPACT TARGET GATE PASS
```

followed by plain `Ready;`. Full verbose output is needed only if this compact
gate fails.

---

## Original: `docs/M157_PRESENCE_AGE.md`

# M157 authenticated current presence age

M157 adds:

`GIT HISTORYFIRSTPRESENCEAGE-REF-FULL <commit|ref> <depth> <path>`

It reuses the authenticated current-presence origin machinery. If the beginning
of the current presence run is known as an ADDED/DELETED change or repository
root, the command reports complete signed author and committer age from that
beginning to the newest commit. If bounded history is truncated before the
beginning, it reports observed spans rather than claiming a complete age.

## Sealed target fixture

Commit:
`6EF11911449C184457F3958ABE4CA7A0692CE8C9`

Depth: 6

Path: `src/GITPBWALK.EXEC`

Expected result:

- current state ABSENT
- current run nodes 6, exact runs 1
- begin known 1
- begin kind CHANGE
- begin edge 6 status DELETED
- author age 268 seconds
- committer age 268 seconds

## Compact target gate

After transferring the M157 wrappers and `M157CHK.EXEC`, run only:

`M157CHK`

Expected output:

```text
M157 LEVEL PASS M157/M157
M157 AGE PASS ABSENT EDGE 6 DELETED 268/268
M157 COMPACT TARGET GATE PASS
```

followed by plain `Ready;`. The checker accepts any synchronized GIT/GITVREF level M157 or newer.


## Combined compact gate through M157

`M157GATE EXEC` runs M155CHK, M156CHK, and M157CHK internally and suppresses
their successful detail. This is the preferred real-CMS acceptance command.

Expected output:

```text
M157GATE M155 PASS
M157GATE M156 PASS
M157GATE M157 PASS
M157GATE COMBINED TARGET GATE PASS
```

followed by plain `Ready;`. If it fails, run only the named compact checker
reported by the failure line; use a verbose history command only if that compact
checker also fails.

---

## Original: `docs/M158_PRESENCE_TIME.md`

# M158 authenticated first-parent presence time

M158 adds:

`GIT HISTORYFIRSTPRESENCETIME-REF-FULL <commit|ref> <depth> <path>`

It composes the authenticated presence-run, chronology, closed-duration and
current-age machinery into a per-run time ledger. Every run is classified as
CURRENT, CLOSED, ROOT, or TRUNCATED.

Complete runs contribute signed author/committer seconds to PRESENT or ABSENT
totals. A truncated oldest run is explicitly incomplete and contributes only
observed span to its own run record; it is never included in complete-time
totals.

## Sealed target fixture

Commit:

`486ADAA5B02080720F4B329C6F68550B13C6AA87`

Depth: 5

Path: `src/GITPBWALK.EXEC`

Expected accounting:

- presence runs: 3
- complete runs: 2
- incomplete runs: 1
- complete PRESENT runs: 1
- complete ABSENT runs: 1
- complete PRESENT author/committer seconds: 50 / 50
- complete ABSENT author/committer seconds: 0 / 0
- run 1: ABSENT CURRENT complete, 0 / 0 seconds
- run 2: PRESENT CLOSED complete, 50 / 50 seconds
- run 3: ABSENT TRUNCATED incomplete, 0 / 0 observed seconds

Compact proof records:

```text
HFPT P1 S 3 2 1 1 1
HFPT P1 T 50 50 0 0
HFPT P1 R 1 ABSENT CURRENT 1 0 0
HFPT P1 R 2 PRESENT CLOSED 1 50 50
HFPT P1 R 3 ABSENT TRUNCATED 0 0 0
```

## Target gate

Transfer `GIT.EXEC`, `GITVREF.EXEC`, and `M158CHK.EXEC`, then run:

`M158CHK`

The checker intentionally executes the authenticated history command directly,
not as a CMS Pipelines stage. Its full report remains visible so target proof
cannot be distorted by the pipeline-capture behavior isolated during M155-M157.
No GITREC rebuild is required.

---

## Original: `docs/M159_PRESENCE_RATIO.md`

# M159 authenticated first-parent presence ratio

M159 adds:

`GIT HISTORYFIRSTPRESENCERATIO-REF-FULL <commit|ref> <depth> <path>`

It builds on M158 complete-time accounting and reports PRESENT/ABSENT shares
in integer basis points (10000 = 100%). Ratios are emitted only when both
complete-time components are nonnegative and their total is positive.
Otherwise the corresponding AUTHOR/COMMITTER ratio is marked unavailable
instead of inventing a percentage.

## Sealed target fixture

Commit:
`486ADAA5B02080720F4B329C6F68550B13C6AA87`

Depth: 5

Path: `src/GITPBWALK.EXEC`

Expected compact proof:

```text
HFPR P1 S 2 1 1 1
HFPR P1 A 1 50 50 0 10000 0
HFPR P1 C 1 50 50 0 10000 0
```

Meaning:
- complete runs: 2
- incomplete runs: 1
- complete PRESENT runs: 1
- complete ABSENT runs: 1
- author complete total: 50 seconds, all PRESENT
- committer complete total: 50 seconds, all PRESENT
- PRESENT share: 10000 basis points
- ABSENT share: 0 basis points

## Target gate

Transfer `GIT.EXEC`, `GITVREF.EXEC`, and `M159CHK.EXEC`, then run:

`GIT LEVEL`
`M159CHK`

The checker invokes the authenticated history command directly rather than
through a CMS Pipelines command stage. No GITREC rebuild is required.

---

## Original: `docs/M160_PRESENCE_COVERAGE.md`

# M160 authenticated first-parent presence coverage

M160 adds:

`GIT HISTORYFIRSTPRESENCECOVERAGE-REF-FULL <commit|ref> <depth> <path>`

It reports structural completeness of the bounded first-parent presence history
used by M158/M159. Coverage is deliberately based on authenticated run and node
counts, not elapsed time, so commit density is not misrepresented as time
coverage.

The report reconciles:
- complete + incomplete presence runs = all presence runs;
- complete + incomplete first-parent nodes = the chain node count;
- each complete/incomplete basis-point pair sums to 10000.

## Sealed target fixture

Commit:
`486ADAA5B02080720F4B329C6F68550B13C6AA87`

Depth: 5

Path: `src/GITPBWALK.EXEC`

Expected compact proof:

```text
HFPC P1 S 3 2 1 6 5 1
HFPC P1 B 6666 3334 8333 1667
```

Meaning:
- 3 presence runs: 2 complete, 1 incomplete;
- 6 chain nodes: 5 in complete runs, 1 in the truncated run;
- run completeness: 6666 basis points;
- node completeness: 8333 basis points.

## Target gate

Transfer `GIT.EXEC`, `GITVREF.EXEC`, and `M160CHK.EXEC`, then run:

`GIT LEVEL`
`M160CHK`

The checker invokes the authenticated history command directly. No GITREC
rebuild is required.

---

## Original: `docs/M161_PRESENCE_FRONTIER.md`

# M161 authenticated first-parent presence coverage frontier

M161 adds:

`GIT HISTORYFIRSTPRESENCEFRONTIER-REF-FULL <commit|ref> <depth> <path>`

It identifies where M160's incomplete structural coverage begins. When history
is depth-truncated, the report names the oldest incomplete presence run, its
state/kind/node count, its start/end step and depth, and—when a complete region
exists immediately before it—the last complete step plus the authenticated
ADDED/DELETED transition edge at the coverage frontier.

This differs from M152 current-presence origin: M152 locates the beginning of
the current run, while M161 locates the boundary between structurally complete
and incomplete bounded history.

## Sealed target fixture

Commit:
`486ADAA5B02080720F4B329C6F68550B13C6AA87`

Depth: 5

Path: `src/GITPBWALK.EXEC`

Expected compact proof:

```text
HFPF P1 S 1 1 3 ABSENT TRUNCATED 1 6 6
HFPF P1 B 5 4 5 ADDED
```

Meaning:
- history is truncated and has a complete/incomplete frontier;
- incomplete run is run 3, ABSENT, TRUNCATED, one node;
- incomplete run occupies step 6 through step 6;
- last complete step is 5 at depth 4;
- frontier edge is edge 5, authenticated status ADDED.

## Target gate

Transfer `GIT.EXEC`, `GITVREF.EXEC`, and `M161CHK.EXEC`, then run:

`GIT LEVEL`
`M161CHK`

The checker invokes the authenticated history command directly. No GITREC
rebuild is required.

---

## Original: `docs/M162_PRESENCE_FRONTIER_DISTANCE.md`

# M162 authenticated first-parent presence frontier distance

M162 adds:

`GIT HISTORYFIRSTPRESENCEFRONTIERDISTANCE-REF-FULL <commit|ref> <depth> <path>`

It extends M161's structural coverage frontier with distance and chronology.
When a complete/incomplete frontier exists, it reports:
- first-parent step distance from HEAD to the first incomplete node;
- first-parent depth distance;
- author/committer span from HEAD to that incomplete node;
- author/committer delta across the frontier edge itself.

Signed chronology is preserved; unlike the M159 ratio, these values are not
suppressed merely because a clock delta is negative.

## Sealed target fixture

Commit:
`486ADAA5B02080720F4B329C6F68550B13C6AA87`

Depth: 5

Path: `src/GITPBWALK.EXEC`

Expected compact proof:

```text
HFPG P1 S 1 5 5 105 105
HFPG P1 E 5 ADDED 55 55
```

Meaning:
- frontier distance is available;
- incomplete history starts five first-parent steps / five depths from HEAD;
- HEAD-to-frontier author and committer span: 105 / 105 seconds;
- frontier edge 5 is ADDED;
- edge author and committer delta: 55 / 55 seconds.

## Target gate

Transfer `GIT.EXEC`, `GITVREF.EXEC`, and `M162CHK.EXEC`, then run:

`GIT LEVEL`
`M162CHK`

The checker invokes the authenticated history command directly. No GITREC
rebuild is required.

---

## Original: `docs/M163_PRESENCE_HORIZON.md`

# M163 authenticated first-parent complete presence horizon

M163 adds:

`GIT HISTORYFIRSTPRESENCEHORIZON-REF-FULL <commit|ref> <depth> <path>`

It reports the fully complete prefix of the authenticated bounded first-parent
presence history. M161/M162 describe where incomplete history begins; M163
reports how far back from HEAD the history remains structurally complete.

When a complete prefix exists, the report includes:
- complete-through step and depth;
- step and depth distance from HEAD;
- signed author/committer span from HEAD to the last complete node;
- the next incomplete step and authenticated frontier edge when truncation
  follows the complete prefix.

The complete-node count is reconciled with the complete-through step so the
reported horizon cannot silently skip or include incomplete nodes.

## Sealed target fixture

Commit:
`486ADAA5B02080720F4B329C6F68550B13C6AA87`

Depth: 5

Path: `src/GITPBWALK.EXEC`

Expected compact proof:

```text
HFPH P1 S 1 5 4 4 4 50 50
HFPH P1 F 1 6 5 5 ADDED
```

Meaning:
- complete horizon is available;
- complete history runs through step 5 at depth 4;
- complete horizon is 4 first-parent steps / 4 depths from HEAD;
- HEAD-to-horizon author and committer span: 50 / 50 seconds;
- the next node is incomplete step 6 at depth 5;
- frontier edge is edge 5, authenticated status ADDED.

## Target gate

Transfer `GIT.EXEC`, `GITVREF.EXEC`, and `M163CHK.EXEC`, then run:

`GIT LEVEL`
`M163CHK`

The checker invokes the authenticated history command directly. No GITREC
rebuild is required.
