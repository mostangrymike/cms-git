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
