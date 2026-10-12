# M200 — CMS FILEDEF listing and safe test artifact cleanup

## Real CMS M199 result — October 12, 2026

The user built `GITBX9` with no assembler errors, loaded
and GENMOD'd it, then ran:

```text
GITB9 G 7736 3864789 10 9069E154EB145C25D8E1A8D31F72252C53E6684A
M199 DIRECT NATIVE RECORD-BOUNDED READ BEGIN
M199 PARAMETERIZED FSREAD SOURCE BEGIN
M199 BOUNDED ORIGINAL STAGE READ PASS
M199 NEW A SCRATCH TRANSFER PASS
M199 FULL CANONICAL SHA1 VERIFY BEGIN
M197 OBJECT 7736 TYPE 2 SIZE 291 BODY RECORDS 10
M197 VERIFIED OID 9069E154EB145C25D8E1A8D31F72252C53E6684A
M197 READ ONLY FULL OBJECT SHA1 PASS
M199 PARAMETERIZED FULL OID PASS G 7736
Ready; T=0.01/0.02 11:21:19
LISTFILE GITR199 DATA A (ALLOC
GITR199 DATA A1 V 64 11 1
Ready; T=0.01/0.01 11:21:29
```

**M199 is real-CMS-target-proven** for the indexed tree
object 7736 using a caller-supplied record coordinate
and independent canonical Git SHA1. It remains to select
and authenticate a second object and automate tuple
acquisition. The new `GITR199 DATA A1` is a successful
disposable scratch, not a protected repository artifact.
The M198 scratch `GITVRAW DATA A1` is also now superseded.
The original G stage/index remain untouched.

## Correct way to list CMS FILEDEFs

The user noticed `QUERY FILEDEF` on their CMS session
was interpreted as a CP query about userid `FILEDEF`,
not the desired list of CMS ddnames.

IBM z/VM CMS supports entering simply:

```text
FILEDEF
```

with no operands to list all current definitions.
The normal no-definitions result is
`DMSFLD324I No user defined FILEDEFs in effect`.
Clear an owned definition by its exact ddname, for example:

```text
FILEDEF OBJIN CLEAR
```

Never use `FILEDEF * CLEAR` as an automatic cleanup
shortcut because it could clear unrelated active
definitions. The M196/M197/M198/M199 wrappers have been
updated to use `PIPE CMS FILEDEF | STEM f.` rather
than `PIPE CMS QUERY FILEDEF | STEM f.`. The
source change preserves their individual collision
checks and FILEDEF cleanup.

IBM references: CMS FILEDEF command, z/VM 7.3 documentation;
CMS ERASE command reference, z/VM 7.2 documentation.

## New GITCLN EXEC — strict A1-only whitelist

New `src/GITCLN.EXEC`, two explicit choices:

```text
GITCLN SCRATCH
GITCLN RETIRED
```

`SCRATCH` deletes **only** these exact, successful,
now-unneeded A1 files:

- `GITVRAW DATA A1` (M198)
- `GITR199 DATA A1` (M199)

`RETIRED` deletes only generated build outputs and
obsolete one-off probe executables of M193, M194, M195
and M198: `GITFSRD`, `GITFRB`, `GITFL10`,
`GITBX8` MODULE/TEXT/LISTING and their wrappers
`GITFSP`, `GITFRP`, `GITFLP`, `GITB8` EXEC.
Missing individual files are skipped.

The following are **never erased** by this helper:
original G stage and index, GIT600, any G file;
the actual `.ASSEMBLE` source on A; `GITRP6M`,
`GITVO7M`, `GITBX9` or active executables;
the GitHub repository or its checkpoint records.

For each exact filename/filetype/filemode A1 it:
checks `STATE`, refuses unknown RC; issues an exact
`ERASE fn ft A1` only if it exists; requires a
subsequent `STATE` RC28 to verify deletion.
No wildcard erase, rename, FORMAT, disk reaccess,
or automatically deleted evidence after an error.

It also requires a successful `QUERY DISK A` and
checks the no-operand CMS `FILEDEF` output before
deleting. It refuses to run while any user-defined
DISK FILEDEF is present, to avoid erasing a
potentially open or referenced scratch file.
If any check fails, the helper stops with RC8.
No operations are performed in the background.

**The helper itself is host-tested only until an
actual CMS run verifies its REXX and FILEDEF behavior.**
No remote CMS deletion was executed from GitHub.

## Safe operator sequence after CI and merge

Mac (from `ibm-sandbox/src`):

```sh
git pull
./cms-upload.sh GITCLN.EXEC GITRP6.EXEC GITB8.EXEC GITB9.EXEC GITVO7.EXEC
```

CMS MAINT inspect before cleanup:

```text
FILEDEF
LISTFILE GITVRAW DATA A (ALLOC
LISTFILE GITR199 DATA A (ALLOC
```

Expect these two known disposable files to be present,
11 variable records each. Any unexpected FILEDEF binding
should be investigated and cleared by its own owner
before proceeding.

Then one exact-mode cleanup at a time:

```text
GITCLN SCRATCH
STATE GITVRAW DATA A
STATE GITR199 DATA A
FILEDEF
```

The two STATEs should say file not found (RC28).
If `SCRATCH` failed, stop, preserve console output.

After scratch cleanup is confirmed, optionally
remove obsolete test executables and generated text
and listing files:

```text
GITCLN RETIRED
FILEDEF
```

The active M196/M197/M199 modules remain available.
Original `M173NET STAGE G` and `M174NET INDEX G`
are NEVER erased. In particular, don't use wildcard
`ERASE`, ACCESS ERASE, FORMAT, or drive G write-link.

## Next Git object validation after cleanup

M199's one-object record selection is now real CMS
target-proven, but it is still manually passed a tuple
from M196. Select a **second independent object** by
asking the index planner first, with an upper bound
of 64 body records:

```text
GITRP6 G 3868 64
FILEDEF
```

Do not guess the new record span, size, type or OID:
use the actual subsequent M196 output. If object 3868
exceeds the 64-record bound, plan another candidate.
M199's wrapper requires 1..64 nonempty body records
and 1..2048 decoded bytes; an empty object is not yet
supported by its native assembler.
After a successful second-object M196 plan and a
confirmed-absent `GITR199 DATA A`, invoke M199
with that exact new tuple. As with the first run,
check full M197 canonical SHA1 and clean scratch
only AFTER a successful authenticated PASS.

M188's authenticated 280-object closure remains the
read-only comparison baseline at 205.04 CPU seconds
and 208.27 elapsed seconds. M200 neither replaces
that reader nor claims a complete-tree speedup.
