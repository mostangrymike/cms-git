# IBM Sandbox

## M190 interruption; M191 direct CMS seek diagnostic

A real z/VM 6.3 test successfully built
`GITPSKM MODULE` but its terminal output
after `GITPSK G ...` was only `HX` and
`CMS`, with **no native seek preflight,
tree closure, target PASS or final Ready**.
IBM documents HX as *Halt Execution*,
which returns the terminal to CMS. Thus
M190 is **not target verified**, and the
reason it was interrupted remains unknown.
Its wrapper buffers native output using
`PIPE CMS ... | STEM`, hiding progress
until the native call returns.

New isolated M191 `GITPRBM.C` and
`GITPRB.EXEC` provide a **read-only,
direct-console** seek diagnostic that
checks just one indexed first, middle, or
last stage header without scanning the
multi-million-line stage. Progress is
flushed before and after `fseek`; there
is no buffered native-output PIPE. It
fails closed for mismatched positions,
headers and invalid indexes, owns only
temporary FILEDEFs, and never modifies G.

After strict host CI, run `GITPRB G FIRST`
first, then separately MID and LAST if
safe. The full runbook is
`docs/M191_CMS_SEEK_PROBE.md`. Do **not**
repeat the full M190 walk merely to
diagnose `fseek`. M185 and M188 stay
target-proven, the latest M188 elapsed
baseline being **208.27s** (two scans,
zero seeks). No original G files changed.

---


## M190 — experimental indexed reachable-blob readback

The current **actual CMS positive-path** baseline is
M188 CPU **205.04s**, elapsed **208.27s**:
8 trees, 272 reached blobs, 280 verified objects,
7736 indexed unique, two full sequential stage
scans and zero seeks. Its observed 1.70s elapsed
advantage over M185 is only 0.81% (one sample);
a post-run FILEDEF result was not supplied.

M190 is an **independent HOST-ONLY candidate**:
`GITPSKM.C` / distinct wrapper `GITPSK.EXEC`.
It validates the entire original stage/index
and authenticates all trees in a **single full
forward scan**, traverses the requested root,
and reopens the stage read-only to `fseek`
directly to each 272 reached blobs using
first-pass verified `ftell` offsets. Every
sought header and reached blob SHA1 is fully
reverified; any unsupported seek or mismatch
fails closed. All protected original files
and prior modules remain unchanged.

Host CI on 7736 unique synthetic indexed
objects passed strict C89, exact 280-object
reached closure, one scan/272 seeks, and
malformed index/hex/SHA negatives. A seven-round
Linux-host comparison showed **M190 0.0369s**
vs **M188 0.0719s** on a disposable 15.36MB
fixture. **Those are not z/VM results.** IBM
CMS's C text stream seek behavior on `dd:STGIN`
is unproven; test only as a separate reader,
following `docs/M190_SELECTIVE_SEEK.md`.

---


## M188 real CMS target PASS — 208.27 s elapsed

On October 11, 2026, **M188 passed** on the actual z/VM 6.3
target. The isolated `GITPH8 EXEC` and `GITPH8M MODULE`
verified 8 trees, 272 blobs, 279 entries, 280 reached
objects and 7,736 unique indexed OIDs. Two forward
scans each read 3,864,799 CMS stage text records,
with zero random seeks. Native CPU **205.04s**,
elapsed **208.27s**. The previous real CMS M185
was CPU 206.72s, elapsed 209.97s, so the
single observed M188 run is **1.70s/0.81% shorter**.
This small difference is not a robust performance
claim without repeated samples. G was checked as a
4096-byte disk; stage/index present; FILEDEF clean
**before** execution. The transcript did **not**
include post-run `QUERY FILEDEF`; final DD cleanup
not independently proven. Original modules and G
data remain preserved. Evidence:
`docs/M188_FAST_EOL.md`.

---


## M189 eight-way hex validator — host-only negative speed result

M189 uses separate `GITPH9M.C` and `GITPH9.EXEC`,
cloned from M188, but checks eight skipped hex chars
with a single combined validhex-table test before
the unchanged strict suffix handling. Full C89
host SHA/record/index/parity tests pass; no
protected G data or proven modules are modified.

On one seven-run Linux comparison, M189 median
**0.0427s** versus M188 **0.0407s** and M185
**0.0411s** on the same 15.36MB host fixture.
Thus **M189 did not improve host speed**.
This is **not real CMS evidence**. M185 remains
the fastest verified on z/VM at **209.97s**.
Prioritize the isolated M188 CMS experiment
ahead of M189. Full details and optional
independent M189 runbook:
`docs/M189_EIGHTWAY.md`.

---


## M188 isolated native EOL fast path (host proven only)

M185 is confirmed on real z/VM 6.3: CPU 206.72s,
elapsed **209.97s**, exact authenticated
8-tree/272-blob/280-object closure, 7736 unique
index objects and two 3864799-record stage scans.

New `GITPH8M.C` / distinct `GITPH8.EXEC` adds
bounded LF, CRLF and NUL suffix fast paths while
retaining M185's full fallback, selected SHA1
authentication, strict skipped-hex rules and
read-only stage/index. GitHub native C89 CI passed,
including differential malformed suffix/SHA tests.
Linux fixture medians: M188 0.0735s versus M185
0.0766s (seven rounds), **host-only evidence**.
Actual M188 CMS performance is unmeasured.
See `docs/M188_FAST_EOL.md` for safe instructions.

---


## M185 real CMS performance milestone — 209.97 seconds

On October 11, 2026, isolated M185 `GITPH5 EXEC` and
`GITPH5M MODULE` **compiled and passed on actual z/VM 6.3**.
The exact authenticated closure remained 8 trees, 272 blobs,
279 entries, 280 verified objects and 7,736 unique indexed
objects. Both full scans read 3,864,799 CMS stage text records,
with no seeks. Real CPU **206.72s**, elapsed **209.97s**,
vs M181 real elapsed 298.38s: **88.41s/29.6% faster**.
M185 now replaces M181 as the *measured performance baseline*,
without overwriting any earlier module. A successful post-walk
`QUERY FILEDEF` has not yet been supplied. Target transcript
and bounds: `docs/M185_DIRECT_SKIP.md`.

---


## M187 — synthetic 7,736-object native index/closure parity

Without waiting for further z/VM 6.3 results,
M187 adds `tests/test-m187-live-scale.py` to
strict C89 host CI. It builds a disposable
Git stage/index with exactly 7,736 unique
indexed object IDs, including 8 trees and
272 reachable blobs, and verifies the same
280-object closure and 279 entries returned
on the real G disk. The four isolated native
readers M181, M182, M183 and M185 must agree
on authenticated closure, two forward scans,
15,472 object-header visits and zero seeks.
The synthetic host fixture contains **15,791
text records**, not the live 3,864,799 per
pass. Unreachable malformed hex, reached
SHA corruption and truncated stage all
fail closed. Original temp fixture hashes
are unchanged when the test completes.

This is host-only correctness evidence,
**not M182/M183/M185 z/VM performance proof**.
Latest real CMS elapsed benchmark remains
M181 **298.38s**. No read or write to
protected G data. See `docs/M187_NATIVE_SCALE.md`.

---


## M186 — deterministic host-only skipped-record differential safety

M186 adds `tests/test-m186-skip-differential.py`,
a reproducible seeded (186) fault matrix that runs
M181, M183 and M185 on **181 shared positive and
negative** Git-format stage mutations. It rejects
any new native reader that returns success when
the original target-proven M181 reader rejects,
or that produces a different authenticated closure.
It verifies unchanged source index and restores
the disposable stage. No new CMS code or protected
G input is modified. Detailed test rules and
limitations: `docs/M186_DIFFERENTIAL.md`.

The latest real-CMS positive performance reference
is **M181 298.38s elapsed** (294.57s CPU). M182,
M183 and M185 have host proof only; their relative
Linux host timings do **not** establish CMS speed.

---


## M185 — direct skipped-record validation, host gated

Continuing without waiting for M182/M183 CMS evidence,
M185 adds an isolated C89 reader `GITPH5M.C` with
distinct REXX wrapper `GITPH5.EXEC`. It preserves
M181's selective two-scan Git SHA/index/tree rules but
removes `strlen` from the frequent *skipped*
hex-text-record validation path. It checks all expected
hex characters and any trailing space, CR or LF in
one bounded read, retaining native encoding support
and fail-closed invalid records. Stage lines are
not skipped; each is still read and checked.

All new tests compile strictly C89, compare correct
closures, and reject shortened/extended records,
malformed hex, malformed suffixes and corrupted
reached SHA. A disposable Linux 15.36MB stage
benchmark shows the new M185 median **0.0760s**
versus M183 **0.0908s**, M182 **0.0987s** and
M181 **0.1211s** in one seven-round host run.
These are **host-only observational timings**;
the last actual z/VM 6.3 result is M181
**298.38s** elapsed (CPU 294.57s). M182,
M183 and M185 are not target-proven; no real
CMS speedup claimed. See `docs/M185_DIRECT_SKIP.md`
for isolated and nondestructive target commands.
No stage/index/PACK or older module changed.

---


## M184 — independent native host comparison, no CMS wait

Without pausing for the pending M182/M183 real CMS
measurements, M184 adds a **host-only comparative
benchmark**, `tests/bench-m184-hex-selective.py`.
It strictly compiles all three native C89 readers
M181, M182 and M183, builds a disposable canonical
stage/index (15,360,000-byte unreachable blob),
verifies identical SHA-authenticated tree closure
and read-only input hashes, then reports rotating
7-run median/min/max host durations. Timings are
observational only and are **not CMS performance
claims**; CI can fail for correctness or input
mutation, never for a speed ranking.

On the Linux GitHub CI runner, the seven-run
medians on the 15.36MB skipped-blob host fixture were
**M181 0.1197s, M182 0.1010s, M183 0.0913s**;
all exact authenticated closure and unchanged-input
checks passed. These timings are **not** z/VM speed
claims or a replacement of target proof.

M181 remains the fastest **real target measured**
at **298.38 seconds** elapsed, CPU 294.57s.
M182 and M183 have host integrity PASS but
z/VM runtime remains unmeasured. No existing
CMS module or `GIT600` persistent stage/index
is changed by this purely host-based M184 task.
Details: `docs/M184_HOST_COMPARISON.md`.

---


## M183 — isolated four-way skipped-record hex validation (host CI)

The latest **real CMS** native performance baseline is M181:
`GITPHX EXEC` -> `GITPHXM MODULE`, 298.38s elapsed,
294.57s CPU, with 8 trees, 272 SHA-authenticated
reachable blobs, 280 verified objects and two
3,864,799-line sequential stage scans. M181 remains
unchanged and target-proven. No post-run FILEDEF
was included in its successful run transcript.

M182 (two-digit hex lookup) is host-proven **only**;
its actual z/VM execution time remains unknown.
M183 is another **independent** host-tested candidate
using new `GITPH3M.C` and `GITPH3.EXEC`. It forks
the target-proven M181 reader (not unverified M182),
reuses the original computed trimmed record length
rather than calling `strlen` twice, and validates
four hex characters at a time using M181's small
native lookup table. All indexes, SHA1 verification,
two-scan count and skipped-byte validation remain.
No original module, disk, stage or index changes.
**No CMS speedup is claimed** for M183.
See `docs/M183_SKIP_LENGTH.md` for host scope and
safe conditional native commands.

---


## M181 real CMS pass; isolated M182 native pair-hex candidate

October 11, 2026: the fixed separate `GITPHX EXEC`
and `GITPHXM MODULE` passed real z/VM 6.3:
8 trees, 272 blobs, 279 entries, 280 verified objects,
index 7736/7736, two full 3,864,799-line scans,
zero seeks and correct Git SHA authentication.
CPU **294.57s**, elapsed **298.38s**, versus
M179 elapsed 459.44s, a **161.06s/35.1%**
single-run improvement. The final independent
`QUERY FILEDEF` was not included in this success
transcript. Verified original M181 remains preserved.

Next M182 is an isolated host-tested research branch:
native `GITPH2M.C` and differently named
`GITPH2.EXEC` use a 65,536-entry table to validate
**pairs of skipped hex characters**, rather than
M181's 256-entry one-character table. It retains
the proven two-pass, selective-SHA and failure
checks and is **not yet real-CMS target-proven**.
It may be faster or slower. Exact read-only next
commands: `docs/M182_HEX_PAIR.md`. Do not
reformat/reimport or touch permanent G inputs.

---


## M181 name-collision correction (October 11, 2026)

On real z/VM 6.3 CMS, the first M181 build of
`GITPHX MODULE A` succeeded, but the `GITPHX EXEC`
wrapper's internal `PIPE CMS GITPHX WALK` dispatched
back into the EXEC. Nested EXEC interpreted `WALK`
as a filemode, producing `M181 FILEMODE INVALID`
and wrapper RC 8 before the native tree scan began.
The protected G stage/index remained intact and
`QUERY FILEDEF` was empty before and after.

The corrected split is **`GITPHX EXEC`** (wrapper)
calling **`GITPHXM MODULE`** (native C89 reader), built
from new `GITPHXM.C`. No erase/rebuild/reformat or
change to proven modules. Host CI explicitly guards
against module/EXEC name collisions. **Real CMS native
M181 closure is still pending.** Exact corrected
upload/compile commands: `docs/M181_HEX_LOOKUP.md`.

---


## M181 isolated selective-SHA hex validation experiment (host CI)

The real z/VM 6.3 M180 test proved single-pass functionality,
but it ran **708.52s elapsed**, versus **459.44s** for M179.
One-pass authentication SHA1-checked 2220 indexed blobs,
instead of only 272 reachable blobs. M180's 249.08s
slowdown is documented in `docs/M180_ONEPASS_TREE.md`.
The old G data and all earlier modules are preserved.

M181 is a **separate C89 module** `GITPHX.C`, exposed via
`GITPHX.EXEC`, retaining the selective two-scan M179
integrity checks but accelerating skipped hex-record
validation using a 256-entry native ASCII/EBCDIC
character table. All bytes and record lengths are
still checked, with same SHA-authenticated root closure.
Strict host C89 parity/corruption tests pass.
**M181 is not yet CMS target-proven or speed-proven.**
Use the conditional target runbook in
`docs/M181_HEX_LOOKUP.md` without rewriting G.

---


## M180 actual CMS pass — correctness with slower performance

October 10, 2026: isolated one-scan `GITPONE/GITPONCE`
compiled and passed on real z/VM 6.3 CMS. Same expected
8 trees, 272 blobs, 279 entries, 280 authenticated objects,
7736/7736 indexed OIDs and **zero seeks**, with one scan
of **3,864,799 text lines**. It SHA-authenticated 2,220
indexed blobs to support the requested 272 reachable blobs.
CPU **704.95s**, elapsed **708.52s**, clean before/after
FILEDEF. Compared with M179 elapsed **459.44s**, M180
is **249.08s (about 54.2%) slower**. M180 proves the
one-pass algorithm is functional, not faster. Preserve
M178/M179 selective two-pass readers and all G stage/index.
See `docs/M180_ONEPASS_TREE.md`.

---


## M179 native stage profiling PASS; M180 single-pass candidate

On real z/VM 6.3 CMS, the new M179 profiler returned RC0,
the same 8-tree/272-blob/280-authenticated-object closure,
7,736 unique objects indexed, and reported **3,864,799
stage text records per scan**, 7,729,598 for two scans.
All four C89 `clock()` phases returned `UNAVAILABLE`.
CPU 454.92s, elapsed **459.44s** (October 9, 2026);
M178 had elapsed 460.66s. Neither result establishes
a comparative speedup. M179's final FILEDEF postcheck
has not been provided. Details: `docs/M179_TREE_PROFILE.md`.

M180 is a **new, isolated, host-tested C89 experiment**
(`GITPONE.C` and `GITPONCE.EXEC`), not yet proven
on the CMS target. It authenticates all indexed tree
and blob objects during a **single** sequential stage
scan, keeps only authenticated tree bodies resident,
then validates the requested graph from the verified
index and blob-authentication markers. It trades more
SHA1 computations for eliminating one complete stage
read. The permanent G STAGE and INDEX and all proven
M176/M177/M178/M179 modules remain unchanged.
M180 may be faster or slower and is never a replacement
without measurement. Runbook: `docs/M180_ONEPASS_TREE.md`.

---


## M179 isolated stage/CPU profiling (host CI; CMS pending)

After M178's real CMS PASS (8 trees, 272 blobs, 280 verified,
7736 unique index, two scans, 0 seeks, CPU 455.95s / 460.66s
elapsed), M179 adds a **separate** C89 read-only diagnostic
module `GITPPRF.C` and safe `GITPPROF.EXEC`. It reports
physical stage text-line counts for each full scan and
four `clock()` CPU phases: index/map, tree scan, graph
walk and blob scan. Its host parity/corruption tests pass.
**It is not yet real-CMS target-proven and does not claim
a speedup.** See `docs/M179_TREE_PROFILE.md` for the exact
two-file transfer and conditional target test. The known-good
M173–M178 readers and verified G stage/index are untouched.

---


## M178 — native CMS tree reader TARGET PASS (October 9, 2026)

M178's isolated C89 forward-only, two-pass authenticated tree walker
(`src/GITPFST.C` through `src/GITPFAST.EXEC`) passed host CI and a
**real z/VM 6.3/CMS** run on the retained `GIT600` G disk.
The clean native module build was followed by a positive `GITPFAST G`
tree-closure verification of **8 trees, 272 blobs, 279 entries,
280 authenticated objects, 0 gitlinks**, against the verified
**7736/7736** stage index. The instrumented reader reported
**2 forward scans, 15472 object-header visits, 0 seeks** and authenticated
272 reached blobs. Largest object: 393767 bytes; peak resident:
6546851 bytes. CMS CPU **455.95s**, elapsed **460.66s**.

Both before and after `QUERY FILEDEF` returned no user-defined
FILEDEFs. Terminal markers: `M178 TREE CLOSURE PASS` and
`M178 VERIFIED FAST TREE TARGET GATE PASS`. The original M176/M177
code and G stage/index were not changed. **No comparative speedup
has been established**, because the M177 TREE elapsed counter
previously overflowed. The next step is independent measurement and
bounded performance analysis, not any rebuild/reformat of the
verified G stage/index. Details: `docs/M178_PACK_TREE_PERFORMANCE_PLAN.md`.

---


## Current live CMS native-Git checkpoint — October 9, 2026

The native CMS Git client now has a verified **7,736-object**
GitHub PACK stored on an independently provisioned
1600-cylinder, 4KB-block **GIT600** CMS G disk,
rather than overrunning A. The retained original
`M171NET PACK/META A` input is preserved.

- **M173 LIVE PASS:** native OFS-capable import,
  `M173NET STAGE G`, with independent readback
  (elapsed **1396.22 seconds**, October 9, 10:48:28).
- **M174 LIVE PASS:** index `M174NET INDEX G`
  with **7736 unique OIDs**, full index check and
  stage audit and lookup of Git tip commit
  `ADA83FF3B3813961CEF2A9FFC50A453540039E0B`
  (elapsed **1459.65 seconds**, October 9, 11:27:15).
- **M176 LIVE PASS:** recursive closure of the
  tip's root `CCB18BEC067E7886D70B82EF138EE56A8B899A61`.
  **8 trees, 272 blobs, 0 gitlinks, 279 entries,
  280 verified objects**, largest object
  **393767 bytes**, peak resident **394058 bytes**;
  `M176 LIVE ROOT TREE CLOSURE TARGET GATE PASS`,
  October 9, 12:51:40. The CMS timing field
  overflowed (`T=*.**/*.**`), so do not attribute
  an elapsed time.
- The M176 output includes `M175 PACK INFO PASS`
  from its internal object-information call.
  **Standalone M175CHK G terminal success has
  not been provided** with that output; keep
  the distinction.

**M177 TREE LIVE CMS PASS — October 9, 2026 15:32 CDT.**
The new `GITPVIEW TREE G CCB18BEC...` read-only command
verified the same root closure of 8 trees, 272 blobs,
279 entries and 280 objects using the retained G stage/index,
and printed `M177 PACK VIEW TREE PASS` on real CMS.
The CMS time field overflowed and no exact duration is known.
**M177 INFO and standalone M175 are now also live CMS PASS.**
At 15:47 the `GITPVIEW INFO G <tip>` returned the
correct tip commit, root tree, parent and 7736 unique
indexed objects, with a `M177 PACK VIEW INFO PASS` marker;
CMS elapsed 41.52 seconds. Identical before/after
`QUERY FILEDEF` responses were `No user defined FILEDEF
in effect`. At 15:51 the full `M175CHK G` verified the
commit, root and parent and ended in
`M175 VERIFIED RANDOM ACCESS TARGET GATE PASS`;
elapsed 124.65 seconds. **M173–M177 positive-path CMS
target gates are complete**. Next: isolated, non-mutating
M178 tree-closure performance research.
See `docs/M177_READONLY_PACK_ACCESS_PLAN.md`.
Do not reformat G or overwrite `M173NET STAGE G`,
`M174NET INDEX G`, original PACK A, or earlier
sealed generations. An overlapping fullpack
`PMAINT 0141` exists on VMCOM1; do not write
through it while G holds data.

Detailed current checkpoints and instructions:
`docs/M173_PERSISTENT_DISK_RUNBOOK.md` and
`CHAT_STATE.md`. Historical status farther down
is retained as chronological context.

---


Native IBM platform development experiments.

## CMS Git client

The active project is a native Git client for CMS on z/VM 6.3 Evaluation
Edition under Hercules Aethra on an AWS EC2 Debian ARM64 host.

The Git-format core is target-proven through M10: objects, refs, PACK handling,
bounded inflate/delta reconstruction, pkt-line/side-band transport, and a real
Git upload-pack fixture. M11 native CMS TCP and bounded binary-safe HTTP framing
are also target-proven.

Current practical HTTPS architecture:

- CMS/z/VM: native REXX/SOCKETS TCP and Git smart-HTTP bytes.
- EC2 TAP gateway: `192.168.200.1/24`.
- CMS: `192.168.200.2/24`.
- stunnel listener: `192.168.200.1:8443`, bound only to the TAP interface.
- stunnel establishes verified modern TLS to `github.com:443`, including CA
  chain validation, hostname checking, and SNI.
- The CMS -> EC2 stunnel -> GitHub path is target-proven through live Git
  smart-HTTP discovery and upload-pack. A 340,027-byte live PACK containing
  1,808 objects was received and its PACK SHA-1 verified on CMS. The next work
  is optimizing the bounded object walker for practical large-pack performance.

Native z/VM System SSL work is preserved as an experimental/research path.
Current GitHub uses an ECC Sectigo certificate chain that the old z/VM 6.3
service level cannot currently validate/import with the installed crypto
facilities, so it is no longer the practical blocker for GitHub transport.

See `docs/BUILD.md`, `docs/STATUS.md`, and `CHAT_STATE.md`.

## Native PACK checkpoint: staging and index prototypes

`GITCWALK OPTCHECK` is CMS-proven for the captured 1,808-object PACK:
the optimized and reference SHA-1 implementations agreed on every
reconstructed object, including all 1,117 OFS_DELTA objects.
`OPTSHA` ran in 19.29 s CPU / 19.42 s elapsed on one CMS run.

The original STAGE output FILEDEF error was corrected by specifying
RECFM V and LRECL 80. On September 26, CMS STAGE wrote all 1,808
reconstructed objects; VERIFY independently rehashed every stored
object and BADSTG rejected deliberately altered content. GITCIDX
CHECK validated 1,808 unique indexed OIDs, and first/last GETs
returned independently SHA-1-checked object content on actual CMS.

The canonical compiler wrapper is now `CMSCLNK EXEC`, with the
existing native-inflater link mode as its default and a new `PLAIN`
mode for programs without inflater dependencies. It is prepared for
installation beside GCCCMS on F; see `docs/BUILD.md`. Its F-disk
placement and PLAIN linkage still require CMS validation.

The separate GITCIDX AUDIT mode and experimental ftell/fseek
seek index with direct SGET have passed host C89/CI regressions,
including corrupt stage and truncated-index tests. The faster seek
mode still needs real CMS validation. See docs/NATIVE_STAGE.md and
docs/NATIVE_INDEX.md for the full record and next target gate.
Native forward/external REF_DELTA resolution, safe committed storage
generations, and reboot/restart proof remain outstanding. Issue #2
remains open.

## Performance redesign: native PACK engine

The REXX-per-object pipeline is a correctness reference, not the intended
production architecture. On the captured 1,808-object PACK, a 20-object
prefix took 230.13 seconds initially and 64.44 seconds after bounded I/O
optimizations. Do not extrapolate a full-run time from the prefix: object
sizes and delta costs vary. A 90-minute interactive terminal test is not an
acceptable production workflow.

Target architecture (incremental gates):

1. Keep the existing strict walker and 27-case GITTEST suite as a regression
   oracle. Preserve the captured PACK; ALL overwrites the active buffer.
2. Remove remaining per-record REXX dispatch while retaining bounded file
   access. GIT9CTX SAVE now reads 16 object records per EXECIO directly.
3. Implement a native PACK engine with one CMS entry point: sequential
   buffered PACK input, header and varint decoding, GITNAPI inflation,
   binary object hashing, delta application, and a position/OID index.
   Reuse GITINFA; do not reimplement the inflater. Keep REXX for orchestration.
4. Native gates in order: regular-object fixture; 20-object prefix; delta
   fixture with OFS and REF; 100-object prefix; 500-object prefix; full
   1,808-object PACK with checksum and final boundary verification.
5. Use CPU time and elapsed time for every gate. A sub-five-second 20-object
   run is an engineering target, not an established capability.

Fail closed on malformed headers, short reads, invalid delta bases, wrong
object hashes, missing trailers and out-of-range offsets. No unbounded REXX
strings or repeated network capture. Do not claim native-engine parity until
its implementation and target-side tests demonstrate it.

## GCCCMS native C checkpoint (2026-09-26)

The working GCCCMS toolchain now builds C plus the existing assembler inflater. `GITCAPI` adapts GCCCMS's argument-list calling convention to `GITNAPI`; `GITCLNK` builds the combined CMS module. `GITCINF` passed both a known-good `abc` zlib fixture (3 output bytes, 11 compressed bytes) and the first live PACK object (270 output bytes, 182 compressed bytes, next object at offset 196). The later `GITCWALK` 1,808-object inflation timing and remaining correctness work are recorded in `docs/STATUS.md`. C is the main native-engine implementation path; retain assembler where the existing inflater or CMS interfaces warrant it, and preserve the REXX walker as the correctness reference.

## GCCCMS native C integration (2026-09-26)

GCCCMS now builds a combined C and native assembler CMS module using GITCLNK, GITCAPI, and GITINFA. The adapter corrects GCCCMS argument-list calling convention. GITCINF passed the known abc fixture (3 output bytes, 11 consumed) and the first live PACK object (270 output bytes, 182 consumed; second object at offset 196). GITCWALK subsequently completed the 1,808-object inflation gate; see docs/STATUS.md for its measured time and the remaining delta, OID, checksum, and persistence work. Preserve the REXX implementation as the correctness reference.

## GCCCMS build-tool rename

`CMSCLNK EXEC` supersedes `GITCLNK EXEC` as the build wrapper for
GCCCMS. Default `CMSCLNK GITCWALK` links the native inflater;
`CMSCLNK GITCIDX PLAIN` builds an ordinary C-only module. GitHub
source and host static checks pass. To install the EXEC next to
GCC on CMS F, check `QUERY DISK F`, copy from A to F only if F is
R/W, and validate the newly built module before retiring the
original A-disk GITCLNK. Instructions: `docs/BUILD.md`.

## September 26, 2026 — direct-seek index and native REF progress

On actual CMS, `GITCIDX AUDIT` independently verified all 1,808
staged bodies and 1,808 unique OIDs. Experimental `SBUILD` and
`SCHECK` succeeded; direct `SGET` retrieved both end objects,
confirming ftell/fseek across separate CMS program invocations
on an unchanged stage. Last-object retrieval improved from
7.59 s elapsed via the original V1 sequential GET to 1.77 s
via SGET in the observed runs (4.29x).

The native C PACK walker now also resolves backward, same-PACK
REF_DELTA chains by OID, without changing the proven original
PACK file or index. A deterministic three-object REF PACK has
passed host native parsing, negative tests and independent
`git index-pack`/`git cat-file` interoperability tests.
CMS validation of the updated REF-capable C source remains open.
See `docs/NATIVE_REF.md` for one isolated CMS fixture gate;
do not repeat the live GitHub network capture.

The remaining full-Git gaps include forward/external REF_DELTA
bases and atomic/recoverable content-addressable storage. GitHub
issue #2 remains open. The compiler wrapper has been renamed
`CMSCLNK EXEC` and is intended for the writable GCC F disk;
a command-labeled installation result was not present in the
most recent posted CMS transcript.

## Critical OID interoperability correction: Git ASCII vs CMS EBCDIC

The first CMS backward-REF test exposed a shared native C hash defect:
GCCCMS formatted the Git object header in EBCDIC, not the required
ASCII. As a result, previous 1,808-object C hash parity, staging,
readback and index checks established internal consistency but did
not establish canonical Git OIDs. PACK checksum and object inflation
remained correct. Inspected REXX GITBOID/GITOID already construct
canonical headers explicitly in hexadecimal.

GITCWALK and GITCIDX now construct explicit ASCII headers, and
known Git blob-vector tests detect CMS character-set regressions.
IDX2/SIDX2 index formats reject old incompatible indexes. Full
host CI passes, but the fixed C code needs the next CMS run.
Preserve existing GITSTAGE, GITINDEX and GITSEEK files; rebuild
separately named GITFIX stage/index/seek files from the saved PACK
after the corrected REF test succeeds. See docs/CANONICAL_OIDS.md
for exact safe commands and source of the defect. Issue #2 remains
open for target proof and broader native Git functionality.

## September 26: canonical REF validation on CMS completed

The corrected GITCWALK RTEST and independent GITCIDX SELF now pass
on real CMS with known Git canonical SHA-1 vectors. The saved small
three-object REF fixture passes on the target, reconstructing abc,
abcd and abcde with the correct Git object IDs, and both chained
backward same-PACK REF_DELTA instructions apply correctly in RPACK
and RAPPLY modes. This fixes the confirmed EBCDIC canonical-header
failure exposed in the earlier REF attempt. The four separately
generated malformed PACK fixtures remain host-tested; they were not
part of the latest target transcript.

The earlier 1,808-object staging and seek/index artifacts still have
legacy incompatible IDs. The next required step is to rebuild the
existing captured PACK offline into new GITFIX STAGE, INDEX and SEEK
files and verify every object and both canonical IDX2/SIDX2 indexes.
Do not overwrite the original stage or indexes. Full commands and
success criteria: docs/CANONICAL_OIDS.md. A later optional GITCIDX
PAIR mode is host-tested to compare both new indexes and independently
rehash each indexed body; it may require one new compiler transfer.

## Canonical native stage complete; full seek audit optimization

The full original 1,808-object captured PACK has now been rebuilt
on CMS with the corrected ASCII Git hashing implementation into
a new GITFIX STAGE A. Independent VERIFY passed every object,
and the new GITFIX INDEX A passed complete IDX2 AUDIT with
1,808 unique canonical Git object IDs. The separate GITFIX
SEEK A SIDX2 index was built and structurally checked successfully.
First canonical commit ID:
00D8D63229305230C8D37F884CE87F9E1A89468C.
Last canonical tree ID:
EB37E3F23FF4FC137D715D71A711D3B7632D75F2.

The initial SVAUDIT became very slow after progress 256 because
it reopened the staging file per object. Current GITCIDX source
avoids repeated opens and adds a one-pass SFAST hash/seek-cookie
verification. Optional PAIR compares both canonical index
generations and invokes SFAST. Host regression passed; actual
CMS execution of these updated audit modes remains the next
validation gate. See docs/CANONICAL_OIDS.md for the minimal
GITCIDX-only transfer and test commands. Preserve all existing
canonical and historical datasets.

## Native M13 follow-on: external/forward REF and GEN2 seal

The corrected full 1,808-object GITFIX stage plus canonical IDX2
and SIDX2 indexes are now target-validated. Actual CMS SFAST
verified all 1,808 unique Git object OIDs in 20.99 seconds elapsed;
PAIR independently reconciled both indexes and every staged body
in 21.38 seconds. The first canonical commit and last tree were
retrieved by direct SGET in 0.15 and 1.81 seconds elapsed.

Independent subsequent C89 host development adds optional
`GITCWALK FPACK` for chained forward same-PACK REF_DELTA,
`XPACK/XAPPLY` for canonical-SHA-verified external CMS staged
bases, and `GITCIDX GENWRITE/GENCHECK` for a sealed GEN2
candidate-generation manifest. Host CI passes positive, malformed,
missing, duplicate and stale-data gates plus independent Git
forward PACK interoperability. **These new modes still require
actual CMS validation and are not yet a transactional object store.**
The exact nondestructive target gates are in
`docs/REF_RESOLUTION.md` and `docs/GENERATION_RECOVERY.md`.

## Real CMS forward/external REF and GEN2 passed

The optional new source is now target-proven for chained forward
same-PACK REF_DELTA (`FPACK`, two resolved forward references);
external REF base lookup from both a synthetic three-byte blob and
actual persisted `GITFIX STAGE A` (a 270-byte commit), both producing
Git's correct canonical OIDs; and GEN2 sealed generation creation
and independent revalidation in a separate invocation. Both GENWRITE
and GENCHECK fully hashed all 1,808 objects and reconciled both
canonical indexes with the stored seek cookies. They each completed
in about 21.6 seconds elapsed on CMS. The stage and indexes remained
unchanged. GEN2 is a candidate completion proof, not atomic promotion
or reboot recovery. Future work includes faster indexed external REF
lookup, cross-logon/reboot durability tests and safe active-generation
selection; see docs/REF_RESOLUTION.md and
 docs/GENERATION_RECOVERY.md.

## New optional fast external REF lookup

The real CMS XREAL test successfully used a complete sequential scan
of the validated GITFIX STAGE to reconstruct its own 270-byte first
commit. That scan took 8.17 s elapsed. GITCWALK now has an optional
indexed alternative, XSEEK/XSAPPLY, that reads the existing SIDX2
seek index, selects an external base's saved ftell cookie, seeks to
it and independently hashes the selected body before delta
application. Host tests for the targeted lookup, later record,
corrupted object, bad index cookie and truncated index passed:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36283446044 .
This new indexed path is NOT yet CMS-proven. The single-source
upload and nondestructive CMS gate using the existing XREAL PACK,
GITFIX STAGE and SEEK are in docs/INDEXED_EXTERNAL_REF.md.
Cross-logon GEN2 GENCHECK is also still pending; existing same-session
GENWRITE/GENCHECK already passed on CMS.

## 2026-09-27 10:20–10:21 CDT: GEN2 cross-logon survival PROVEN ON CMS

After an actual logoff and fresh CMS logon, the user successfully defined STGIN GITFIX STAGE A, IDXIN GITFIX INDEX A, FIDXIN GITFIX SEEK A and GENIN GITFIX GEN A. They ran only `GITCIDX GENCHECK`, without rewriting the stage, indexes, or GEN2 manifest. The existing program printed all SFAST progress checkpoints (256 to 1792), `FAST AUDIT VERIFIED 1808 UNIQUE 1808`, `PAIR VERIFIED UNIQUE 1808`, and `GENERATION VERIFIED 1808 UNIQUE 1808`, with normal RC 0, CPU 21.47 sec and elapsed 21.68 sec. This now conclusively establishes **same minidisk cross-logon CMS persistence** for this validated, unmodified full canonical 1,808-object candidate generation, including stage body integrity, both index descriptors, saved seek-cookie correspondence and manifest digest. It does NOT establish survival across an actual system restart or atomic active-generation promotion/multi-writer safety. Protect GITFIX STAGE/INDEX/SEEK/GEN A; no need to rerun GENWRITE or recapture the PACK. The next user-controlled, read-only durability gate, only when a regular system reboot is appropriate, is to reaccess the same A minidisk and reissue the four input FILEDEFs followed by GITCIDX GENCHECK. Concurrent with target work, independently design active-generation selection and interrupted-promotion recovery in GitHub, without claiming an untested atomic CMS file rename guarantee.

## M14: real full-audit dual-slot recovery now host-tested

The native C89 `GITSEL` parser now writes and checks bounded
checksummed SEL1 selector records. New `src/GITREC.C` binds each
slot to a distinct set of candidate FILEDEFs and requires the
actual GITCIDX full `GENCHECK` — including all staged canonical
Git OIDs, IDX2/SIDX2 pairing, saved seek cookies and GEN2 seal —
before selecting a candidate. Its host regression uses two
independent 1,808-record synthetic generations and tests rollback
from damaged GEN2, modified stage, truncated seek index, missing
ordinary index and spoofed selector names. The complete host
suite passed at
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36330993480 .

This is not yet compiled on CMS and performs no automatic active
pointer writes. Real CMS compilation and a *read-only* selection
test using protected GITFIX as the older generation and disposable
SEL1 files are described in docs/NATIVE_RECOVERY_GATE.md. Existing
GITFIX has already passed same-minidisk cross-logon GENCHECK;
system reboot persistence and actual atomic promotion remain open.

## September 28, 2026 — M37 native target and M38 audit batching

Actual z/VM CMS compiled GITREC cleanly and the standard M37 compact
regression passed every read-only gate. M35 NESTLINKS, M36 DEEPLINKS
and M37 DEPTHLINKS 2 are now target-proven on both original sealed
1,808-object generations, including older-slot recovery and
fail-closed invalid slots. Observed complete test runtime was
693.54 seconds CPU / 708.96 seconds elapsed.

M38 adds optional read-only `GITREC LINKBATCH`: one ordinary full
generation verification followed by one depth-two complete graph
check emits three success markers only after all links validate.
It replaces three separate positive full-audit invocations in the
standard compact GITRUN and preserves independent original audits,
all negative/recovery tests and all protected original files. Source
record and runner static checks have passed; independent complete
GitHub Actions and real CMS execution of M38 remain unconfirmed.
See `docs/LINK_BATCH.md` and the last section of `CHAT_STATE.md`.

## September 28 follow-on: M38/M39 host-CI-complete

M38 read-only `GITREC LINKBATCH` combines M35–M37
positive depth-two link authentication into one complete
GEN2 selection audit and one subtree traversal. M39 removes
redundant subtree read/hash/parse at positive recursion depth:
the recursive call fully authenticates each subtree once.
Blobs, terminal trees, all parent/child roots, bounded
limits, missing/wrong-type failure codes and no-partial-output
rules remain protected. All original GITREC commands continue
to exist. The standard one-page `GITRUN.EXEC` is M39
and retains two independent original full 1,808-object
generation audits, selector proof, negatives, fallback,
dual-invalid rejection, restoration and final STATE checks.

Complete strict native C89/integration/selector/index/REF
GitHub CI succeeded for M38 and M39, including the final
M39 runner and guard:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36482128273

M38/M39 are host-proven, **not yet actually CMS-tested**.
One real CMS compile and standard M39 GITRUN tests both;
see `docs/LINK_BATCH.md`. Original sealed generations,
selector pointers and captured PACK remain immutable.

## M39–M42 latest native milestones

M39 completed its actual CMS regression on September 28: two independent 1,808-object full-generation audits, verified batched nested links, fail-closed negatives, older-slot recovery, newer-slot restoration and protected originals. The complete run used 454.77 seconds CPU and 464.18 seconds elapsed.

Further host-tested work adds M40 atomic terminal-directory parsing for PATH/LSDIR, M41 LSDIRV to authenticate immediate directory references, and M42 LSDIRDEPTH to authenticate referenced local subtrees to caller-selected depth 0–4. Full native C89 integration, source-guard and staging/index/REF PACK Actions suite passed: https://github.com/mostangrymike/ibm-sandbox/actions/runs/36484134487 . M40–M42 require one combined actual CMS M42 test before target-proof claims. See docs/LINK_BATCH.md and CHAT_STATE.md.

## Latest: M42 native CMS and M43/M44 full host CI

On September 28 M42's actual CMS compile and complete compact gate passed both independent original 1,808-object generation audits, authentic historical `src` directory to depth one, all recovery/fail-closed cases and protected-file checks (522.41 CPU / 533.40 elapsed seconds). M40–M42 are target-proven.

M43 fixes the 256-tree-entry bound to count external Gitlinks without trying to dereference their external commits. M44 introduces iterative, bounded `GITREC CLOSURE`, which SHA-authenticates and validates all local tree/blob descendants of a commit and every parent root without the former depth-four ceiling, within a shared 1,024-tree-visit limit. Host synthetic regressions test deep missing/mis-typed objects, 256/257 external Gitlinks and exactly 1024/1025 visited-tree budget boundaries. Strict C89 complete native-stage Actions passed: https://github.com/mostangrymike/ibm-sandbox/actions/runs/36487140427 . M43/M44 are host-proven, not yet CMS-proven. The standard M44 `GITRUN.EXEC` batches one actual target gate. Consult `CHAT_STATE.md` and `docs/LINK_BATCH.md` for exact two-file upload and read-only CMS commands.

## M44 native proof; M45 complete directory closure

Actual z/VM CMS compiled and passed the entire M44 compact regression, including independent original 1,808-object audits, complete child/parent tree closure, recovery/fail-closed cases and final protected files (638.32 CPU, 652.08 elapsed seconds). M43 and M44 are target-proven.

M45 adds read-only `GITREC LSDIRFULL`, which authenticates every local tree/blob descendant beneath an explicitly requested commit-relative directory before revealing directory metadata or listing; traversal is iterative with the established 256 entries/tree and 1,024 tree visits bounds. All source and synthetic deep failure tests, including older fallback and both-invalid rejection, passed full native host CI: https://github.com/mostangrymike/ibm-sandbox/actions/runs/36489401717 . M45 has not yet run on actual CMS. The one standard M45 compact GITRUN tests the real historical `src` directory and preserves all original full-generation/protection checks. Only GITREC.C and GITRUN.EXEC need transferring; see `CHAT_STATE.md` and `docs/LINK_BATCH.md`.

## Current native proof and M46 follow-on

The September 28 actual z/VM CMS M45 run compiled `GITREC` cleanly and passed the complete standard `GITRUN M45` regression: both independent original 1,808-object audits, historic `src` full closure, full child/all-parent closure, negative cases, seq51 fallback, dual-invalid failure, seq52 restoration and protected-state checks. Full regression: 705.89 CPU / 721.23 elapsed seconds. M45 is real CMS target-proven.

M46 adds read-only `GITREC TREECLOSURE C0 C1 TREE_OID40` to validate complete local closure from a raw tree object ID and release a direct tree listing only after full closure. It reuses existing bounded iterative traversal, external Gitlink handling and full selected-generation validation. Host integration covers deep corruption and exact visit/entry limits. The one compact `GITRUN M46` adds the historical root tree by OID to every original M45 gate; it requires only `GITREC.C` and `GITRUN.EXEC` for the next CMS transfer. M46 must not be called actual target-proven until real CMS output confirms it.

## September 29: M46 target-proven; M47/M48 host-green

Actual native z/VM CMS compiled M46 without flagged statements and passed the entire one-page original-data regression: both independent 1,808-object audits, historic full commit/parent/directory/raw-tree closure, all expected negative tests, older fallback, dual-invalid fail-closed, restored newer generation and protected-file checks. CPU 775.91 / elapsed 792.93 sec. M46 is real CMS target-proven.

M47 adds PATHFULL, which validates an **entire commit-root snapshot** before disclosing any requested path metadata. M48 adds PATHFULLCAT, which additionally outputs lossless binary blob HEX only after the same full-root attestation. Host regression proves deep corrupt unrelated sibling fail-closed behavior, exact 256/257 Gitlink and 1024/1025 tree-visit limits, empty/binary/64-KiB blob fidelity, older-generation recovery, dual-invalid no-output and restored newer generation. Full strict C89 CI passed https://github.com/mostangrymike/ibm-sandbox/actions/runs/36576137300 . M47/M48 are fully host-proven, **not actual CMS-proven**. The current single compact `GITRUN.EXEC` is M48, and only two Mac transfers (`GITREC.C`, `GITRUN.EXEC`) plus one real CMS compile and GITRUN are needed; see `docs/CURRENT_STATE.md` for exact commands. The M48 target run supersedes the older M47 target gate and retains every previously protected original regression.

## M48 real CMS pass; M49 snapshot-wide directory listings

Real CMS compiled the M48 production `GITREC` with zero flagged statements and passed the full original-data compact regression: two independent 1,808-object generation audits, whole-root PATHFULL src metadata, whole-root PATHFULLCAT README blob bytes, all prior directory/root/tree closure checks, fail-closed/recovery/restoration and final protected files. Full CPU 958.09 / elapsed 979.38 sec. M47 and M48 are actual CMS target-proven.

M49 adds read-only `PATHFULLDIR`: authenticate the entire commit-root local tree/blob graph before returning the requested directory's metadata and listing, including rejecting a corrupt *unrelated* sibling. Synthetic production-C89 tests cover deep missing/wrong-typed siblings, missing/invalid path, invalid terminal type, fallback, both invalid and restoration, exact 1024/1025 tree visits and 257 Gitlink-entry failure. The full native-stage CI passed https://github.com/mostangrymike/ibm-sandbox/actions/runs/36580384415 and supplemental resource-boundary CI passed https://github.com/mostangrymike/ibm-sandbox/actions/runs/36580525841 . M49 is full host-CI-proven and awaiting real CMS validation. One standard compact M49 runner retains every prior original-data gate and tests historic src PATHFULLDIR; only GITREC.C and GITRUN.EXEC need transfer. See `docs/CURRENT_STATE.md` for exact next commands.

## M49 native success and M50 raw-tree relative paths

The September 29 actual CMS `GITRUN M49` fully passed the historic immutable original-data regression, including whole-snapshot src directory listing, all earlier root/directory/blob verification, original independent 1808-object audits, older recovery, dual-invalid fail-closed and final protected files. CPU 981.93 / elapsed 1003.66 sec; no flagged assembly statements. M49 is native CMS target-proven.

M50 adds read-only `TREEPATHCAT` and `TREEPATHDIR`: given a raw tree OID and a HEX path relative to it, first fully authenticate the selected immutable GEN2 and **all** local descendant tree/blob objects, then output lossless blob HEX or a complete directory listing. No commit is required. Host production-C89 regression proves empty/binary/64-KiB/nested data, deep sibling failures without partial output, 256/257 total entries including external Gitlinks, 1024/1025 tree visits, older fallback, both invalid and restored newest generation. Full native CI https://github.com/mostangrymike/ibm-sandbox/actions/runs/36584751834 and supplemental both-command recovery CI https://github.com/mostangrymike/ibm-sandbox/actions/runs/36584911315 passed. M50 is host-proven and awaits one actual standard CMS gate using only GITREC.C and GITRUN.EXEC; see `docs/CURRENT_STATE.md`. Protected original stages, selectors and PACK remain unchanged.

## M52 native target proof; M53–M54 faster full-protection regression

M52's one-process positive regression passed actual z/VM CMS on September 29 with 962.91 CPU/986.89 elapsed seconds against the immutable original 1808-object data, versus 1133.73 elapsed seconds for the immediately preceding M50 run on the rebooted host. M53 removed the redundant standalone selector audit because RUNBATCH already proves and reports newest seq52; full native-stage CI https://github.com/mostangrymike/ibm-sandbox/actions/runs/36625850247 passed. M54 also moves wrong-type-child RC8 and missing-child RC4 tests into the already selected batch, with exact expected-code markers required before aggregate success. It retains both independent original 1808-object full audits, all earlier positive features, invalid-depth RC4, older seq51 recovery, dual-invalid fail-closed, restored seq52 and final protected-file checks. Full M54 C89 native-stage CI https://github.com/mostangrymike/ibm-sandbox/actions/runs/36626167890 passed and merged; M54 real CMS performance and target proof remain to be measured. The standard current `GITRUN.EXEC` is M54. The current EC2/3270 setup has SSH forwarded terminal at Mac local 3271 and c3270 script port 3272; use `CMS_SCRIPT_PORT=3272` with the updated transfer scripts. See `docs/CURRENT_STATE.md` for exact current two-file next commands.

## M54 native pass and M55 scoped tree proof reuse

Actual z/VM CMS `GITRUN M54` passed all protected original 1808-object, positive, negative, recovery and restoration tests on 2026-09-29, CPU 900.08 / elapsed 923.83 sec. M55 memoizes at most two complete and successful immutable tree-root closures within a single fully verified RUNBATCH selection, retaining fresh path and terminal checks and independent standalone commands. Full strict C89 CI passed https://github.com/mostangrymike/ibm-sandbox/actions/runs/36628776152 . Supplemental corrupt/over-budget cache-isolation CI passed https://github.com/mostangrymike/ibm-sandbox/actions/runs/36628992018 . M55 is merged on main and awaits real CMS validation; preserve the two original full audits and all fail-closed tests. Next transfer only GITREC.C and GITRUN.EXEC, using CMS_SCRIPT_PORT=3272 for the current c3270 scripting socket. See docs/CURRENT_STATE.md for exact commands.

## M55 native success and M56 one-snapshot seek-index optimization

The real September 29 z/VM CMS M55 protected regression passed on the original 1808-object repository with CPU 619.93 / elapsed 635.48 seconds, compared with M54 923.83 seconds. M56 further reduces redundant work inside the one already fully verified read-only RUNBATCH by parsing its selected seek index once and reusing that exact 1808-entry in-memory snapshot for that batch only. Every standalone command still freshly reads its index and every object body is freshly reopened and hashed. Both separate complete original 1808-object audits, complete bounded root closures, current and fallback selector validation, expected negative RC4/8, dual-invalid fail closed, restoration and final protected-file checks remain mandatory. Full strict C89 CI passed https://github.com/mostangrymike/ibm-sandbox/actions/runs/36631835500 ; M56 is host-proven and awaits the real native CMS target test. Use the standard M56 GITRUN, transfer only GITREC.C and GITRUN.EXEC via current CMS_SCRIPT_PORT=3272 and refer to docs/CURRENT_STATE.md for the exact next steps.
