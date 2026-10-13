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

