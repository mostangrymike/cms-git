# M190 — one validated stage scan, then indexed reachable-blob seeks

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

1. Read and validate all `7736` stage object headers,
   index offsets/IDs/sizes/types, every skipped blob
   hex record and Git SHA1 of all trees via **one
   complete forward scan**, including EOF check.
   This is identical to the original M188 pass 1.
2. Using cached and SHA-authenticated tree bodies,
   traverse the requested tree graph and mark only
   actually reachable blobs. Preserve all original
   name, mode, depth, cycle, count and memory limits.
3. Reopen `dd:STGIN` **read-only**, and for each
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
4. No other blob is trusted as reached; unrelated
   blobs were still syntactically checked in pass 1.
   Both the source stage and index are never opened
   for writing. Total readback seeks = actual number
   of reached blobs (272 on current G closure).
5. Require complete authenticated closure, release
   temporary buffers and close handles on all paths.

On the operator's current dataset, expected native
diagnostics **if CMS's C text stream supports
repositioning**:
```text
TREE CLOSURE TREES 8 BLOBS 272 GITLINKS 0
TREE CLOSURE ENTRIES 279 VERIFIED 280
TREE CLOSURE INDEX TOTAL 7736 UNIQUE 7736
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
