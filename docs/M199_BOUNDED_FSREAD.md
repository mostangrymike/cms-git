# M199 — Parameterized, bounded CMS FSREAD with Git SHA-1

## October 12, 2026 — Second M199 object: REAL CMS SHA PASS

This is an additional, distinct object from the original
291-byte tree. The user confirmed:

```text
GITB9 G 3868 1969357 36 8AF5E45B1B905F781D0BFB8A547049494B8D07A2
M199 BOUNDED ORIGINAL STAGE READ PASS
M199 NEW A SCRATCH TRANSFER PASS
M197 OBJECT 3868 TYPE 3 SIZE 1148 BODY RECORDS 36
M197 VERIFIED OID 8AF5E45B1B905F781D0BFB8A547049494B8D07A2
M197 READ ONLY FULL OBJECT SHA1 PASS
M199 PARAMETERIZED FULL OID PASS G 3868
Ready; T=0.02/0.03 11:47:45
FILEDEF
DMSFLD324I No user defined FILEDEFs in effect
LISTFILE GITR199 DATA A (ALLOC
GITR199 DATA A1 V 64 37 1
```

**M199 now has real-CMS authenticated read evidence for
both a 291-byte tree (object 7736) and a 1,148-byte
blob (object 3868).** The latter used 37 scratch records,
one block, and 0.03 seconds elapsed for this one object.
No active user-defined FILEDEFs were present after
the test. The user supplied this transcript twice;
it is one observed execution, not two. The successful
GITR199 DATA A1 scratch is disposable, eligible for
exact-name cleanup with GITCLN SCRATCH after checkpoint.
The stage and index remain read-only.

---

## Baseline established October 12, 2026

Real z/VM 6.3 M198 passed after native GITBX8 assembler and
GITVO7M C-module builds. It read object 7736 (type 2 tree,
291 bytes) through 11 absolute native FSREAD records,
created disposable GITVRAW DATA A1, and independently
verified SHA-1 `9069E154EB145C25D8E1A8D31F72252C53E6684A`
using M197. The combined elapsed time was 0.03 seconds.
The scratch was listed as 11 variable records, LRECL 64,
one disk block. No post-run QUERY FILEDEF was provided.

## M199 implementation and safety

New GITBX9.ASSEMBLE and GITB9.EXEC accept a user-supplied,
previously M196-validated tuple of physical object number,
starting one-based CMS record, 1..64 body records and
expected 40-character OID. The native module receives
starting record and count as two EBCDIC decimal STACK
records and validates digit range and arithmetic limits.

M199 validates the OBJ header prefix, complete even-length
body hex records, aggregate size 1..2048 decoded bytes,
and closes protected G-stage input before using FSOPEN
OPENTYP=NEW to create a new disposable GITR199 DATA A1.
It refuses existing scratch; never writes the original G
stage or index; never overwrites or removes any existing
file. On failure, preserve any incomplete scratch for
inspection and do not rerun automatically.

The REXX wrapper verifies the scratch using target-proven
GITVO7M full canonical Git SHA1 and the supplied OID. The
caller must use the actual M196 index-derived record span
and expected OID. Automated index-to-adapter binding is a
future milestone. Zero-byte body objects are not yet
supported by this new transfer gate.

Host tests include assembler continuation-column and label
checks, bounded-input and hex validation, separate
scratch ownership and read-only policies, plus strict C89
full SHA parity over synthetic blobs, trees and commits.
The new M199 module is HOST-ONLY until actual CMS assembly
and execution pass.

## Target operator runbook after green CI and merge

Mac, from ibm-sandbox/src:

```sh
git pull
./cms-upload.sh GITBX9.ASSEMBLE GITB9.EXEC
```

CMS MAINT preflight:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
FILEDEF
STATE GITVRAW DATA A
STATE GITR199 DATA A
STATE GITVO7M MODULE A
```

GITVRAW DATA A is expected to exist (verified M198 scratch).
GITR199 DATA A must be ABSENT. Do not replace either file.

Only if preflight is correct:

```text
GLOBAL MACLIB OSMACRO DMSGPI PDPCLIB
ASSEMBLE GITBX9
```

Only on NO STATEMENTS FLAGGED:

```text
GLOBAL TXTLIB PDPCLIB
LOAD GITBX9 (NOAUTO NOMAP
GENMOD GITBX9
STATE GITBX9 MODULE A
GITB9 G 7736 3864789 10 9069E154EB145C25D8E1A8D31F72252C53E6684A
FILEDEF
LISTFILE GITR199 DATA A (ALLOC
```

A complete PASS must include:
```text
M199 BOUNDED ORIGINAL STAGE READ PASS
M199 NEW A SCRATCH TRANSFER PASS
M197 OBJECT 7736 TYPE 2 SIZE 291 BODY RECORDS 10
M197 VERIFIED OID 9069E154EB145C25D8E1A8D31F72252C53E6684A
M197 READ ONLY FULL OBJECT SHA1 PASS
M199 PARAMETERIZED FULL OID PASS G 7736
```

M199 first tries only the already-proven object 7736, using a
separate new scratch. Future runs for distinct objects
must use new scratch names and verify their own M196 plans.
M188's authenticated full-tree baseline remains
205.04 CPU / 208.27 elapsed seconds, without replacement.
