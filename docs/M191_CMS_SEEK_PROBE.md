# M191 — Direct console probe of CMS text-stream seeking

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
