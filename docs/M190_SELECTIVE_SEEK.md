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
