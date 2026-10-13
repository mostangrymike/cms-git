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

