# M195 — Complete ten-record LAST body through native FSREAD

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
QUERY FILEDEF
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
QUERY FILEDEF
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
