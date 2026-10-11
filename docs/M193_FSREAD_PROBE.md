# M193 — First native CMS FSREAD by record number

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

## M193 isolated assembler experiment

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

**M193 is NOT yet assembled or executed on z/VM.**
The host CI test is only a **static assembler
guardrail** plus an independent C89 host model
of the record arithmetic; Linux cannot expand
the IBM `FSREAD`/CMS macros. Actual assembler
success and return codes remain target gates.

## Safe first CMS validation

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
