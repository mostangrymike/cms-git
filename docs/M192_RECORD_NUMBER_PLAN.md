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
