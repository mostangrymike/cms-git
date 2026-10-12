# M198 — Read-only FSREAD into NEW-only disposable A scratch, then SHA-1

## October 12, 2026 — M196 real CMS PASS / verified expected OID

Actual M196 `GITRP6 G 7736 10` completed in
0.66 seconds elapsed, validating all 7,736 indexed
objects and selecting:

```text
M196 OBJECT 7736 TYPE 2 SIZE 291 OID 9069E154EB145C25D8E1A8D31F72252C53E6684A
M196 RECORDS HEADER 3864789 BODY 3864790 LAST 3864799 COUNT 10
M196 STAGE MODEL RECORDS 3864799 EXPECTED 3864799
M196 READ ONLY INDEX OBJECT PLAN PASS
M196 INDEX OBJECT PLAN GATE PASS G 7736
```

The real console's longer object line was cut after
the beginning of its OFFSET field, but the complete
OID, type, size and expected record geometry appeared.
The exact expected tree OID is:

```text
9069E154EB145C25D8E1A8D31F72252C53E6684A
```

Since size is **291**, the tenth body record must have
exactly **6 hex characters**; M198 currently enforces a
broader 289–320-byte bound but its M197 full-object
digest and stored header must match the complete
type-2 tree object to pass. It remains **host-only**
until separately built and run on real CMS.

### Critical prerequisite: M197 ASCII Git prefix on EBCDIC CMS

The initial M197 C source built its canonical
`tree 291\0` SHA-1 prefix using native C character
literals; those are EBCDIC on CMS, not Git's required
ASCII. A corrective M197 branch explicitly encodes
Git type bytes, ASCII space 0x20 and decimal digit
base 0x30 as numeric bytes. Its host tests exercise
a 291-byte tree and verify no native-string hash
prefix is reintroduced.

**Do not run M198 with any old M197 MODULE.**
After the fix is merged, use a fresh Mac `git pull`
and re-upload the corrected `GITVO7M.C`, then
`CMSCLNK GITVO7M PLAIN`. M198 is gated on that
clean CMS build, its own clean `ASSEMBLE GITBX8`,
no existing disposable scratch, and exact M196 OID.

After all gates, the eventual real CMS invocation is:

```text
GITB8 G LAST 9069E154EB145C25D8E1A8D31F72252C53E6684A
QUERY FILEDEF
LISTFILE GITVRAW DATA A (ALLOC
```

The LAST probe may create exactly one scratch
`GITVRAW DATA A` on the A minidisk; this is
intentional and must never overwrite an existing file.
On failure, leave any scratch untouched for diagnostics;
do not rerun automatically. The original G stage
and index must remain unmodified.

---

## Verified upstream gates

**October 12, 2026, 09:22 local CMS:** corrected
`GITFL10.ASSEMBLE` assembled with **NO STATEMENTS FLAGGED**,
then `LOAD GITFL10 (NOAUTO NOMAP` and `GENMOD GITFL10`
succeeded. The actual `GITFLP G LAST` invocation passed:

```text
M195 DIRECT LAST COMPLETE BODY PROBE BEGIN
M195 LAST FSREAD COMPLETE BODY BEGIN
M195 LAST HEADER RETURNED
M195 LAST HEADER PASS
M195 LAST TEN BODY READS BEGIN
M195 LAST TEN BODY RECORDS HEX PASS
M195 READ ONLY COMPLETE BODY RECORDS PASS
M195 COMPLETE BODY GATE PASS G LAST
Ready; T=0.01/0.01 09:22:59
```

M195 is **REAL CMS TARGET PASS** for eleven independently
accessed records (header plus ten body records), with exact
64-hex chunks, bounded final hex width, valid hex characters,
and 289–320 total decoded bytes. This does **not** verify
the Git OID or SHA-1. No post-run `QUERY FILEDEF` output
was provided in the transcript.

M193 and M194 were already real-CMS target proven. M196
index record planner and M197 full SHA-1 verification core
are merged and host tested; their actual CMS runs were
**not yet reported**. M188's native authenticated full
closure remains **205.04s CPU / 208.27s elapsed**.

## New isolated source and security model

`src/GITBX8.ASSEMBLE` is a standalone, fixed-column
assembler module distinct from M193–M195 and the proven
M188 reader.

1. Uses exactly eleven absolute extended CMS FSREAD calls
   on protected `M173NET STAGE G1`, RECNO **3864789**
   through **3864799**. Each record goes to its own
   64-byte slot in a 704-byte memory area. Each returned
   variable-record length is retained separately.
2. Checks the known `OBJ 7736 ` header prefix; all nine
   intermediate body records must be exactly 64 EBCDIC
   hexadecimal characters, and the tenth must be an
   even nonempty 2–64 hex-character record. Decoded
   object body length must be 289–320 bytes.
3. Calls **FSCLOSE on the protected stage** before
   any output file is opened. A malformed record never
   causes scratch creation. Nothing writes to G.
4. Only after complete staged input validation, invokes
   `FSOPEN FSCB=OUTFSCB,OPENTYP=NEW,FORM=E`
   for **GITVRAW DATA A1**. IBM documents that NEW
   **fails if the file already exists**, unlike REPLACE.
   Then FSWRITE publishes exactly eleven variable records
   using each *actual returned length* and FSCLOSE.
5. Returns native RC0 only on a completely closed
   scratch file; any error is RC8. A failed or partial
   scratch may remain on A and must be treated as
   untrusted. It is **never automatically erased**.

IBM FSOPEN semantics: [opening CMS files](https://www.ibm.com/docs/en/zvm/7.3.0?topic=macros-opening-cms-files),
[FSOPEN macro](https://www.ibm.com/docs/en/zvm/7.2.0?topic=instructions-fsopen).
The NEW (not REPLACE) exclusivity is a second line of
defense beyond the wrapper's existence preflight.
No other file is created or overwritten.

`src/GITB8.EXEC` requires:

```text
GITB8 G LAST expected-40-hex-oid
```

The expected full 40-hex Git OID MUST come **verbatim**
from the successful independent `GITRP6 G 7736 10`
CMS index plan. Do not guess it and do not use an
OID from unrelated objects or GitHub commit HEAD.

The wrapper guards the 4K G disk, protected index/stage
presence, native `GITBX8 MODULE A`, verified native
`GITVO7M MODULE A`, and `GITVO7 EXEC A`.
It refuses a pre-existing `GITVRAW DATA A`, aborts
on uncertain scratch `STATE` RC, and refuses
caller-owned OBJIN FILEDEF. It invokes the assembler
directly (no buffered PIPE/STEM over native console
output), checks the scratch exists, then calls
`GITVO7 7736 <expected-oid>`. That M197 wrapper
binds read-only disposable `dd:OBJIN`, verifies full
canonical Git SHA-1, and clears its owned FILEDEF.

**M198's wrapper PASS is contingent upon M197's full
OID calculation succeeding**. The assembler alone
does not assert authentication. All original stage
and index files remain untouched.

`tests/test-m198-fsread-scratch.py` host tests check
fixed 72-column source, eight-character symbols,
no FSWRITE/FSERASE on protected G, NEW-only A output,
stage close before output creation, exact record
buffer sizes, EBCDIC hex checks, refusal of existing
scratch and FILEDEF collisions. A synthetic 289–320
byte Git object passes the same ten-record geometry,
then an independently compiled strict C89 M197 SHA
verifier; data and malformed hex/short/odd/truncated
cases are tested. Linux cannot assemble IBM CMS
macros or establish real FSWRITE runtime behavior.
**M198 is HOST-ONLY until a separate z/VM test.**

## Exact operator gates

**Prerequisite:** the actual M196 CMS output for
`GITRP6 G 7736 10` must PASS and report HEADER
3864789, BODY 3864790, LAST 3864799, COUNT 10,
plus the real indexed type, size, and OID. The
M197 C module must also compile cleanly on CMS.
A failure in either prerequisite stops this trial.

After M198 CI is green and merged to main, Mac
`ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITBX8.ASSEMBLE GITB8.EXEC
```

No G data transfer or previous module replacement.
CMS MAINT cheap preflight:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
QUERY FILEDEF
STATE GITVRAW DATA A
STATE GITBX8 ASSEMBLE A
STATE GITVO7M MODULE A
```

`STATE GITVRAW DATA A` is expected to report
file **not found** (normally RC28). If it exists,
**stop**: do not overwrite or erase an unexpected
scratch file. No automatic cleanup is performed.

Build ONLY the new isolated module:

```text
GLOBAL MACLIB OSMACRO DMSGPI PDPCLIB
ASSEMBLE GITBX8
```

Only on `NO STATEMENTS FLAGGED IN THIS ASSEMBLY`:

```text
GLOBAL TXTLIB PDPCLIB
LOAD GITBX8 (NOAUTO NOMAP
GENMOD GITBX8
STATE GITBX8 MODULE A
```

Run the full SHA-integrated probe ONLY using the
actual expected OID from the preceding M196 output:

```text
GITB8 G LAST <actual-40-hex-oid-from-M196>
QUERY FILEDEF
LISTFILE GITVRAW DATA A (ALLOC
```

The angle-bracket placeholder is **not** a runnable
CMS OID: substitute the exact 40-digit hex value.

Required native markers and wrapper sequence:

```text
M198 SOURCE FSREAD TO NEW SCRATCH BEGIN
M198 READ ONLY STAGE LAST OBJECT BEGIN
M198 LAST 11 STAGE RECORDS VERIFIED
M198 NEW DISPOSABLE OBJECT WRITE PASS
M198 VERIFIED SHA1 CHECK BEGIN
M197 DISPOSABLE FULL OBJECT VERIFICATION BEGIN
M197 VERIFIED OID <exact-index-OID>
M197 READ ONLY FULL OBJECT SHA1 PASS
M197 DISPOSABLE FULL OBJECT GATE PASS
M198 NATIVE FSREAD FULL OID GATE PASS G LAST
```

Capture native and wrapper RC, Ready CPU/elapsed,
resulting scratch metadata, and final `QUERY FILEDEF`.
On any failure, **leave the scratch file untouched**
for diagnosis; do not rerun when it may exist.

## Non-goals and protected state

This first bridge remains deliberately sealed to
the **final** indexed object (7736); it is not yet
an arbitrary-object FSREAD adapter or full tree walk.
The user-facing selector and expected OID are bound
to independent M196 evidence, and the complete
scratch payload is authenticated by M197.

Do not change the original G stage/index, reimport,
reindex, erase/format GIT600, replace M185/M188/
M193/M194/M195 or write-link the physically overlapping
PMAINT 0141 fullpack. Never run the unverified
M190 272-seek experiment to compare performance.
