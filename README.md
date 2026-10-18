# IBM Sandbox

## Consolidation status (2026-10-14, verified archive merge)

GitHub `main` is canonical. The repository has **181 tracked files** after
lossless consolidation from 425, a reduction of 244 tracked paths (57.4%).
This measures file count, **not** lines of code or executable complexity.
The latest fully verified host CI commit is
`9fa27106b476562382a5ea3f105b4d7d1c289e21`, workflow run
[39147362503](https://github.com/mostangrymike/ibm-sandbox/actions/runs/39147362503).
This is a complete host-CI success, not new CMS target validation.

The consolidated Python test runner is `tests/test-m203-bounded-batch.py`;
the shell safety/native integration runner is `tests/check-canonical-source.sh`.
Both preserve independently invoked historical gates. All 99 historical EXEC source entries now reside in a single
`archive/HISTORICAL_EXEC.json` collection retaining six separately audited
bundle identities and counts (15, 48, 23, 3, 3, 7). Exact original historical
EXEC files are recoverable using `scripts/restore-cms-exec.py`, and ten
native tree wrappers are regenerated using `scripts/restore-ph-wrappers.py`.
Never delete active production helpers based solely on static reference misses.

Protected CMS G stage/index (7,736 objects), proven M188 tree closure and
M206 stratified SHA authentication, target MODULEs, and A/G disks are unchanged.
A-disk cleanup is **PLAN-only** until explicit backup and target validation;
no destructive `ACLEAN APPLY` is authorized by host CI.

## A-disk cleanup: full inventory reviewed, existing ACLEAN updated

The October 13, 2026 full `LISTFILE * * A (ALLOC`
inventory supports three explicit **opt-in** batches
in the same existing `ACLEAN.EXEC` utility:

| Exact manifest | Listed files | 4K blocks listed |
|---|---:|---:|
| RECENTGEN (previously verified) | 20 | 637 |
| PACKGEN (16 legacy C-native build triples) | 48 | 3,642 |
| NETTRACE (selected SSL/TCP diagnostic files) | 11 | 106 |
| **Maximum if fully reviewed and erased** | **79** | **4,385** |

The nominal file-count projection is **342 → 263**,
and roughly 17.1 MiB of per-file allocation appears
on the A-disk inventory. **No new deletion has
occurred**, and actual free space must be measured,
not inferred. `PACKGEN` deletes only C-generated
ASSEMBLE/TEXT/LISTING when the matching source C and
MODULE exist. `NETTRACE` covers exactly 11
diagnostic outputs, not active SSLPOOL logs,
SSL/TLS source, TCPIP service files or configurations.

A prior CMS A TRKDE 4 disk allocation problem
requires a verified backup/snapshot before APPLY.
The SSL/TCP trace producers must be stopped and logs
archived or deemed unneeded before NETTRACE APPLY.

On Mac from `ibm-sandbox/src`, after merge:

```sh
git pull
./cms-upload.sh ACLEAN.EXEC
```

On CMS, **read-only audit first**:

```text
FILEDEF
QUERY DISK A
ACLEAN PLAN RECENTGEN
ACLEAN PLAN PACKGEN
ACLEAN PLAN NETTRACE
```

For detailed limits, complete manifest names and
separate opt-in APPLY/measurement instructions,
see `docs/M173_PERSISTENT_DISK_RUNBOOK.md`.

**Source-reuse rule stays mandatory:** update
existing canonical `GITP26M.C` / `GITC26.EXEC`
and other established sources, with GitHub rollback
and real CMS validation. Do not add numbered
programs for every milestone. M206's real-CMS
32-object sample SHA PASS (2.06s elapsed) is
the preserved baseline; it is not a complete
280-object reachable history walk.

The in-place M207 extension raises the sampler limit
to 128 disjoint bands in those same sources. Host C89
and REXX source checks cover 2–128 bands, full SHA-1
verification for every selected object, rejection at
129, and fail-closed empty bands. This extension is
host-tested only; it has not been compiled or run on CMS.

M208 adds lightweight commit tags to the modern `GITREF2` store. M209 makes
listing output tag names and accepts `-l`/`--list`; M210 adds `*` and `?`
list-pattern wildcards (no bracket classes). `GIT TAG` and `GIT TAG -l`/
`--list` list tag names in lexical order. `GIT TAG <name> <full-commit-oid>` creates a tag;
`GIT TAG -f|--force <name> <new-oid> <expected-old-oid>` updates an existing
tag using compare-and-swap; the expected OID must be nonzero and match the
current tag;
`GIT TAG -d|--delete <name> <expected-commit-oid>` deletes one using
compare-and-swap.
Creation verifies the target commit; deletion requires its exact old OID.
Names use a safe ASCII subset and the stored full ref is limited to 35
characters to fit the existing 80-column records. `GIT VERIFY-REF` resolves
tag refs; worktree checkout remains branch-only. Annotated tags and tags of
non-commit objects are not supported. Host source/REXX checks pass; CMS
compilation and target behavior remain unverified.

M217 routes `GIT BRANCH` through `GITREF2` when that modern store exists, with
the legacy M5 branch path retained when it does not. The modern path lists
current/noncurrent branches, creates a branch from an explicit commit OID, and
deletes with an expected-old-OID CAS; deletion of the current branch is refused
by the updater. Host REXX checks pass; CMS behavior remains unverified.

M218 adds `GIT SWITCH <branch>` for modern REF2 branches. It verifies the
symbolic HEAD and destination branch, and changes HEAD only when both branches
resolve to the same verified commit. Switching between different tips is
refused until the client can update mapped CMS workfiles and stage state as one
guarded worktree transition. Host REXX checks pass; CMS behavior remains
unverified.

M219 extends switching across different commit tips when the mapped worktree
is clean and every mapped path has the same blob OID in both commits. It refuses
staged or modified workfiles, missing mapped files, stale base mappings, and
destination commits that change a mapped path. Unmapped CMS files are preserved;
the command does not materialize paths that are absent from the current map.
Host REXX checks pass; CMS behavior remains unverified.

M220 adds `GIT SWITCH -c|--create <name> [<full-commit-oid>]`. Without an OID,
the new branch starts at current HEAD; with an OID, it starts at that verified
commit and uses the M219 worktree preflight when the tip differs. Branch
creation and symbolic HEAD movement share one REF2 rewrite with rollback and
readback checks. Branch or worktree conflicts leave REF2 unchanged. Host REXX
checks pass; CMS behavior remains unverified.

M221 extends the optional start point to short or full branch/tag refs using
GITVREF's verified resolver. It also accepts `HEAD` and full 40-character
object IDs. The argument is restricted to a safe ref-name alphabet before it
enters CMS PIPE, and the returned record must match the requested ref and carry
one full OID. Abbreviated OIDs are not accepted. Host REXX checks pass; CMS
behavior remains unverified.

M222 adds `GIT BRANCH -m|--move <old-name> <new-name>`. It resolves the old
branch to an expected OID, refuses stale/missing sources and existing
destinations, and updates REF2 with rollback/readback checks. Renaming the
current branch moves symbolic HEAD in the same rewrite; renaming another branch
preserves HEAD. No force-rename mode is provided. Host REXX checks pass; CMS
behavior remains unverified.

M223 applies the same strict ASCII branch-name validator in the REF2 updater,
resolver, and worktree code. It accepts alphanumeric names plus `.`, `_`, `/`,
and `-`, while rejecting unsafe delimiters, empty or dot-prefixed components,
`..`, trailing dots, and `.lock` components. Host REXX fixtures verify accepted
and rejected names and require the three validator implementations to match;
CMS behavior remains unverified.

M224 checks branch operands in `GIT.EXEC` before they are interpolated into
CMS command strings for create, delete, rename, or switch operations. The same
CMS-safe name rules apply at this boundary; source-derived REXX cases and
dispatch-order guards cover it. CMS behavior remains unverified.

M225 validates lightweight tag names and list patterns before GIT.EXEC forwards
them to CMS commands. Tag names use the safe ASCII ref alphabet; list patterns
also allow Git's `*` and `?` wildcards. Exact-source fixtures cover both forms
and unsafe delimiters. CMS behavior remains unverified.

M226 lets `GIT TAG name [start-point]` create a lightweight tag at `HEAD`, a
full object ID, or a resolvable branch/tag ref. Omitting the start point uses
`HEAD`; the resolved target still must verify as a commit. Host fixtures cover
framing, missing refs, malformed OIDs, and unsafe input. CMS behavior remains
unverified.

M227 sorts modern `GIT BRANCH` output with the same ref-name comparator used by
tag listing, while preserving the current-branch marker. The host fixture starts
from deliberately unsorted refs and checks the exact rendered order. CMS
behavior remains unverified.

M228 adds `GIT BRANCH --show-current`. It reads the symbolic HEAD through
GITVREF, requires one valid branch ref, and prints the short branch name. The
host fixtures cover nested and malformed HEAD values. CMS behavior remains
unverified.

---

## M206 full 32-object CMS PASS and A-disk audit (October 13, 2026)

**REAL z/VM 6.3 CMS PASS:** `GITC26 G CHECK 64 32`
validated all 32 sampled-index plans, elapsed 0.70s;
`GITC26 G RUN 64 32` independently authenticated
32 Git objects using native read-only FSREAD and complete
canonical SHA-1 and cleaned each successful A1 scratch.
Final `M206 STRATIFIED FULL SHA CLEAN PASS 32`,
CPU 1.42s / elapsed **2.06s**. M206 16-object
CHECK/RUN had already passed (0.66/1.43s elapsed).
The original G stage/index remain unchanged.
These are sampled objects, not the M188 full tree closure.

**CMS A disk reported 342 files**, 13,206/31,500
4K blocks used, 18,294 free. The user ran the
existing `ACLEAN PLAN` modes on CMS:

```text
RECENTGEN    FOUND 20  REMOVED 0
LISTINGS     FOUND  0  REMOVED 0
EXPERIMENTS  FOUND  0  REMOVED 0
OLDTESTS     FOUND  0  REMOVED 0
BUILDDECK    FOUND  0  REMOVED 0
```

Only 20 source-backed build intermediates are currently
confirmed disposable. Their exact-name removal, **after
backup/recoverability review**, can lower 342 to
about 322 files; the block savings are not yet known.
No CMS APPLY was performed and no file should be reported
deleted based on PLAN alone. Full current `LISTFILE * *
A (ALLOC` output is still needed to classify other files.

The new user development rule is to **modify established
source files in place** for future milestones rather than
creating more M-numbered C/EXEC/ASSEMBLE files. The
current stable reader sources are `GITP26M.C` and
`GITC26.EXEC`. Preserve working MODULEs until new
versions pass both host CI and real CMS; use GitHub
history for rollback. The earlier numbered-file M207
scratch branch remains separate and must not be deployed;
the current in-place M207 update does not use it.

See `docs/M201-M205_HISTORY.md` and
`docs/M173_PERSISTENT_DISK_RUNBOOK.md`. Next safe cleanup commands
after a verified backup and intentional review are:

```text
ACLEAN APPLY RECENTGEN
QUERY DISK A
ACLEAN PLAN RECENTGEN
FILEDEF
```

If a deletion fails, stop and inspect the exact file
and disk integrity before attempting anything else.
Avoid wildcards, G-disk writes and unnecessary
rebuild artifacts.

---

## In-place source updates and A-disk cleanup (October 13, 2026)

**New operating rule:** do not create a new milestone-numbered
CMS C/EXEC/ASSEMBLE file merely to iterate a proven capability.
After M206's remaining 32-band real-CMS gate, update the
existing `GITP26M.C` and `GITC26.EXEC` in place.
Build/validate the new version before replacing the
proven module. Preserve rollback in GitHub history,
not in dozens of identically purposed A-disk programs.

The operator reports about **342 A-disk files**.
The earlier exact-name `ACLEAN.EXEC` utility
was extended IN PLACE with `PLAN RECENTGEN` and
`APPLY RECENTGEN` for at most 20 known, reproducible
ASSEMBLE/TEXT/LISTING build outputs associated
with six C-native modules and the assembler GITBX9.
PLAN is read-only. APPLY checks existence of
each source and MODULE before a fully addressed
A-only ERASE. No MODULE, EXEC, C, handwritten
ASSEMBLE, PACK, STAGE, INDEX or G file is erased.
Do not apply without reviewed PLAN and recovery
safeguards; see `docs/M173_PERSISTENT_DISK_RUNBOOK.md`.

M206 has **REAL CMS 16-object SHA1 and cleanup PASS**:
`GITC26 G CHECK 64 16` 0.66s elapsed;
`GITC26 G RUN 64 16` 1.43s elapsed,
terminal `M206 STRATIFIED FULL SHA CLEAN PASS 16`.
The complete native FSREAD, M197 canonical SHA1,
and exact A scratch cleanup gates passed across
sixteen separated index regions. Console output
was heavily interleaved, and final independent
FILEDEF/STATE was not supplied.

The M206 32-object real CMS gate was subsequently
completed as recorded above. The earlier unmerged
M207 scratch branch remains outside the canonical build.
The current in-place M207 source change is host-only
and must pass full host CI and a real CMS compile,
CHECK and RUN before replacing the proven module.

After merge, Mac `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh ACLEAN.EXEC
```

CMS read-only cleanup assessment:

```text
FILEDEF
QUERY DISK A
ACLEAN PLAN RECENTGEN
LISTFILE * * A (ALLOC
```

Capture the current exact A inventory. When reviewed
and backed up, selected exact artifacts can be
retired by explicit APPLY; no wildcard cleanup.
Current G stage/index and full-tree baseline remain protected.

---

## M205 real CMS eight-object SHA PASS; M206 32-band expansion

On October 12, 2026, M205 successfully compiled on
z/VM 6.3 and passed CHECK (0.65s elapsed) and full
RUN (1.04s elapsed) across eight separate PIDX1
object-ordinal regions. All eight objects passed
original-stage native FSREAD and full canonical
Git SHA-1, with exact A1 disposable scratch cleanup
after each. Terminal:
`M205 STRATIFIED FULL SHA CLEAN PASS 8`.

The authenticated objects were Git index ordinals
**5, 969, 1935, 2902, 3869, 4836, 5803, and 6835**:
three commits, four blobs and one tree; 8,043 decoded
bytes overall. All eight expected OIDs and physical
record coordinates are preserved in
`docs/M201-M205_HISTORY.md` and `NOTES.md`.
The original protected G stage/index remained read-only.
No final independent FILEDEF listing was supplied.

M206 introduces standalone `GITP26M.C` and
`GITC26.EXEC` to expand the same deterministic
one-index stratified authentication from 2..8 to
**2..32 disjoint index bands**. Every object remains
restricted to 1..2048 decoded bytes and 1..64 native
body records; the planner rejects an ineligible
band before emitting any P201 success record.
CHECK never creates scratch. RUN independently
SHA-1 authenticates every selected object with
existing M199/M197 and cleans new A scratch
**only after each hash passes**. Failure preserves
diagnostic scratch and stops. Prior modules unchanged.

M206 has strict C89 host tests for 2/3/8/16/32
samples and a negative case where an entire
sample band is ineligible. **M206 is not yet
real CMS target validated**; see
`docs/M201-M205_HISTORY.md`.

After CI and merge from Mac `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITP26M.C GITC26.EXEC
```

On CMS, verify original G files, absent scratch
and empty FILEDEF; build `CMSCLNK GITP26M PLAIN`.
Begin with the 16-band CHECK gate:

```text
GITC26 G CHECK 64 16
FILEDEF
STATE GITR199 DATA A
```

Only after CHECK succeeds, 16 plan OIDs are verified,
and scratch is absent, run:

```text
GITC26 G RUN 64 16
FILEDEF
STATE GITR199 DATA A
```

When the 16-band run is real-CMS-proven, test
32-band CHECK before a corresponding 32-band RUN.
All proven M188/M193–M205 functionality and original
stage/index remain protected.

---

## M204 REAL CMS PASS; M205 stratified eight-object SHA gate

On October 12, 2026, actual z/VM 6.3 CMS
successfully compiled `GITP24M` and validated the
M204 one-index batch in CHECK mode (0.64s) and
RUN mode (0.72s elapsed). Both originally
indexed Git objects, 3868 (1148-byte blob)
and 7736 (291-byte tree), passed complete M197
canonical SHA-1; M200 cleanup passed after
each object. Terminal result:
`M204 ONE INDEX FULL SHA CLEAN PASS 2`.

This is about **3.7 times faster than the same
two objects under M203** (2.67s elapsed).
It does not prove a faster complete reachable tree
walk than the protected M188 208.27-second baseline.
Final independent FILEDEF/STATE output after RUN
was not supplied, although both M204 internal
scratch cleanup checks passed.

New M205 provides automatic, stratified selection
across eight disjoint index regions rather than
retesting only the same two already-known objects.
`GITP25M.C` validates the original complete
PIDX1 index once, then chooses one nonempty
1–2048-byte object in each ordinal band whose
body fits a user-specified 1–64 record bound.
It never prints partial plans if a band has
no eligible object.

`GITC25.EXEC` validates every selected
record span and OID before retrieving any stage
data. RUN authenticates every new object with
target-proven native M199 FSREAD and M197 SHA-1,
then uses M200 cleanup **only after each success**.
No original G data or proven modules are modified.

**M205 is host-tested only pending real CMS**.
See `docs/M201-M205_HISTORY.md`.

After CI and merge, Mac `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITP25M.C GITC25.EXEC
```

CMS: verify no scratch, compile
`CMSCLNK GITP25M PLAIN`, then CHECK first:

```text
GITC25 G CHECK 64 8
FILEDEF
STATE GITR199 DATA A
```

Only on CHECK success and absent scratch:

```text
GITC25 G RUN 64 8
FILEDEF
STATE GITR199 DATA A
```

Require eight independent M197 SHA-1 PASS records,
eight M205 post-SHA scratch cleanup confirmations,
and terminal `M205 STRATIFIED FULL SHA CLEAN PASS 8`.

---

## M203 real CMS PASS; M204 one-index batch optimization

On October 12, 2026, actual z/VM 6.3 CMS completed
M203 CHECK and RUN for objects 3868 and 7736.
CHECK: 1.32s elapsed. RUN: 2.67s elapsed and
both M197 canonical Git SHA-1 checks passed,
with successful A1 scratch cleanup after each.
Terminal: `M203 BOUNDED FULL SHA CLEAN PASS 2`.
M203 is target-proven for **two selected objects**;
batches of three through eight remain untested.
No independent final FILEDEF/STATE results were supplied.

M204 adds distinct `GITP24M.C` and `GITC24.EXEC`.
It validates the complete original 7,736-object
PIDX1 index **once** per batch instead of invoking
M201 for every object twice. It emits one compact
record/OID plan per selected object. Full RUN still
uses the proven M199 direct CMS FSREAD and M197
canonical SHA-1 verification for each and cleans
only after each complete PASS. An index error or
SHA failure stops without deleting diagnostic data.
All original G files, earlier modules and the M188
authenticated full-tree baseline remain unchanged.

M204 is **host-tested only** until CMS compilation,
CHECK, full SHA RUN and post-cleanup state pass.
See `docs/M201-M205_HISTORY.md`. After merge:

```sh
git pull
./cms-upload.sh GITP24M.C GITC24.EXEC
```

CMS first verify no scratch, then build
`CMSCLNK GITP24M PLAIN`. Check only first:

```text
GITC24 G CHECK 64 3868 7736
FILEDEF
STATE GITR199 DATA A
```

Only on complete check pass and absent scratch:

```text
GITC24 G RUN 64 3868 7736
FILEDEF
STATE GITR199 DATA A
```

Compare actual elapsed with M203's 2.67s; do not
assume a speedup before the real CMS result.

---

## M202 z/VM PASS; M203 bounded batch

October 12, 2026: real z/VM M202 CHECK passed for objects
3868 and 7736 without scratch creation (1.28s elapsed).
Its full RUN independently SHA-authenticated both the
1148-byte blob and 291-byte tree using M201/M199/M197,
cleaning the disposable A scratch after each success.
Terminal gate: M202 TWO OBJECT FULL SHA CLEAN PASS 3868 7736,
Ready CPU 2.59s / elapsed 2.67s at 13:18:06.

M202 is real-CMS-proven. Final FILEDEF and STATE commands
after the full RUN were not included in the operator trace.

M203 adds separate GITC23.EXEC for 2 through 8 distinct
object numbers, all CHECKs before any SHA, followed by full
M201/M199/M197 authentication and M200 cleanup after each
success. On any failure it stops and preserves scratch.
M203 is host-only until independently validated on CMS.
No original G files or prior modules are modified.

Mac from ibm-sandbox/src: git pull, then upload GITC23.EXEC.
CMS test: FILEDEF, confirm no scratch, then
`GITC23 G CHECK 64 3868 7736`.
Only on CHECK pass, `GITC23 G RUN 64 3868 7736`.
See docs/M201-M205_HISTORY.md for complete instructions.

---

## M201 real CMS authenticated index-to-object PASS; M202 dual-object gate

**October 12, 2026:** M201 compiled without errors on real
z/VM 6.3, successfully captured a compact validated
object record from native C via CMS PIPE, and passed
`GITP21 G 3868 64 CHECK` with **no scratch file**.
Its full `GITP21 G 3868 64` then automatically
passed the M196-derived record/OID tuple to M199
and authenticated the entire 1,148-byte blob with
M197 canonical SHA1, elapsed **0.68 seconds**.
Object 3868, OID:
`8AF5E45B1B905F781D0BFB8A547049494B8D07A2`.
Final FILEDEF: no user-defined definitions.
The last `LISTFILE` command's completed output
was not supplied.

M202 adds `GITC22.EXEC` for **two distinct** automatically
selected and SHA-authenticated objects. It requires
both M201 CHECK modes to pass before starting any
write-once A scratch. On full SHA PASS for each,
it invokes target-proven `GITCLN SCRATCH` and
verifies removal before advancing. Any failure
stops without deleting an untrusted scratch.
It refuses existing scratch files and does not
alter previously proven readers or protected G files.

**M202 is host-tested only** until actual z/VM
`CHECK` and `RUN` results are provided.

From Mac `ibm-sandbox/src` after merge:

```sh
git pull
./cms-upload.sh GITC22.EXEC
```

On CMS, first check `FILEDEF`, and clean the
successful M201 scratch using `GITCLN SCRATCH`.
Then, only when both scratch files are absent:

```text
GITC22 G 3868 7736 64 CHECK
FILEDEF
GITC22 G 3868 7736 64 RUN
FILEDEF
```

Never advance from a failed CHECK; preserve any scratch
after SHA or cleanup failure. See
`docs/M201-M205_HISTORY.md`.

---

## M199 second-object real CMS PASS; M201 automatic tuple (Oct 12)

M199 is now authenticated on **two different native FSREAD
objects**: tree 7736 (291 bytes, 0.03 seconds elapsed)
and blob 3868 (1,148 bytes, 0.03 seconds elapsed).
The latter returned SHA-1
`8AF5E45B1B905F781D0BFB8A547049494B8D07A2`
matching the M196 index; 36 body records, plus the
header, were copied into `GITR199 DATA A1`.
No user FILEDEFs remained.

M200's two cleanup modes already passed real CMS;
the old probes and scratch files were deleted. The
**latest** M199 second-object run recreated
`GITR199 DATA A1` (37 records, one block).
Clean this exact disposable scratch using
`GITCLN SCRATCH` before the next write-once test.

M201 adds the isolated read-only `GITP21M.C` and
`GITP21.EXEC` to extract the record coordinates
and expected OID automatically from the validated
index before invoking the existing M199 SHA path.
It has a no-scratch `CHECK` mode to validate CMS
PIPE/STEM capture before any native FSREAD write.

After host CI/merge, Mac `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITP21M.C GITP21.EXEC
```

CMS MAINT, after `GITCLN SCRATCH`, `FILEDEF`,
and G disk read-only checks:

```text
CMSCLNK GITP21M PLAIN
STATE GITP21M MODULE A
GITP21 G 3868 64 CHECK
FILEDEF
```

Only once CHECK validates the exact 3868 index
tuple, invoke `GITP21 G 3868 64`, then inspect
complete M197 SHA PASS and output scratch metadata.
**M201 is host-tested, not yet real-CMS proven.**
See `docs/M201-M205_HISTORY.md`.

---

## M199 second real-CMS SHA PASS; M201 indexed automation (Oct 12)

M199 authenticated **another independent object**
on actual z/VM 6.3 CMS, without new assembler code:

```text
GITB9 G 3868 1969357 36 8AF5E45B1B905F781D0BFB8A547049494B8D07A2
M199 BOUNDED ORIGINAL STAGE READ PASS
M199 NEW A SCRATCH TRANSFER PASS
M197 OBJECT 3868 TYPE 3 SIZE 1148 BODY RECORDS 36
M197 VERIFIED OID 8AF5E45B1B905F781D0BFB8A547049494B8D07A2
M197 READ ONLY FULL OBJECT SHA1 PASS
M199 PARAMETERIZED FULL OID PASS G 3868
Ready; T=0.02/0.03 11:47:45
```

The new verified `GITR199 DATA A1` has RECFM V,
LRECL64, 37 records and one block. CMS `FILEDEF`
afterward reported no user-defined definitions.
M199 has now authenticated **two** widely
separated physical objects: a 291-byte tree
and this 1,148-byte blob.

M201 is a new independent strict-C89 compact
index planner `GITP21M` plus REXX orchestrator
`GITP21`. It revalidates all 7,736 index
objects and produces exactly one short
index-derived object/record/count/type/size/OID
line. This avoids copying the M196 output
into M199 by hand. On success it delegates
full SHA verification to the existing
target-proven M199 reader.

**M201 is still HOST-ONLY.** Because capturing
C MODULE stdout through CMS PIPE is unverified,
its first target gate is a `CHECK` mode that
does NOT read G-stage records or create scratch:

```text
GITP21 G 3868 64 CHECK
```

Only after that safe capture test passes,
use `GITP21 G 3868 64` for the automatic
end-to-end SHA trial. The currently present
verified `GITR199 DATA A1` should first be
retired with the target-proven explicit
`GITCLN SCRATCH` helper, after confirming
the clean `FILEDEF` state. See
`docs/M201-M205_HISTORY.md` for the
full safe CMS runbook.

---

## M199 target PASS and M200 cleanup — October 12, 2026

M199 is **REAL CMS TARGET PASS**. `GITBX9`
assembled with no flagged statements, and
`GITB9 G 7736 3864789 10
9069E154EB145C25D8E1A8D31F72252C53E6684A`
read the original indexed 291-byte tree through
bounded native FSREAD, created a separate A1
scratch, and independently passed M197 canonical
Git SHA-1. The direct native/wrapper run took
0.02s elapsed. `GITR199 DATA A1` was confirmed
RECFM V, LRECL64, 11 records, 1 block. The older
authenticated M198 scratch `GITVRAW DATA A1`
also exists; both may now be retired after
the checkpoint.

**CMS FILEDEF correction:** to list active CMS
file definitions, enter `FILEDEF` with **no operands**.
The earlier advice `QUERY FILEDEF` was interpreted
as a CP userid query in this session. M196–M199
REXX wrappers now use `PIPE CMS FILEDEF | STEM`
for their own collision checks, and runbooks use
the standalone CMS `FILEDEF` command.

M200 adds `GITCLN.EXEC`, an exact-name A1-only
helper to clean successful disposable scratch
files or separately retire superseded M193–M195/
M198 probe executables. No wildcards, original
G files, active M196/M197/M199 programs, or
ASSEMBLE sources are deleted. Both cleanup
modes must be invoked explicitly; the helper
is host-tested but needs its first real CMS run.

After green CI and merge, Mac `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITCLN.EXEC GITB9.EXEC GITRP6.EXEC
```

CMS MAINT:

```text
FILEDEF
GITCLN SCRATCH
STATE GITVRAW DATA A
STATE GITR199 DATA A
FILEDEF
GITCLN RETIRED
FILEDEF
```

Run each mode only after inspecting the current
FILEDEF state and the complete exact-name cleanup
list in `docs/M179-M185_HISTORY.md`. Stop and
investigate any cleanup failure. M199's next
functional gate is an **independent second object**:
`GITRP6 G 3868 64`; do not guess its
record span, size, type or expected OID.

---

## M198 REAL CMS PASS and M199 host-only next gate

October 12, 2026: actual z/VM 6.3 M198 completed
read-only FSREAD of the original 291-byte tree object
7736 into NEW-only GITVRAW DATA A1 (11 variable records).
The corrected M197 independently verified SHA1 OID
`9069E154EB145C25D8E1A8D31F72252C53E6684A`.
Native/wrapper PASS, elapsed 0.03 seconds. The
disposable A file must be preserved; post-run
QUERY FILEDEF output was not provided.

M199 (GITBX9.ASSEMBLE / GITB9.EXEC) introduces
bounded parameterized record numbers and count, with
independent NEW-only GITR199 DATA A scratch and
complete M197 SHA verification. It is host-only
until independently assembled and run on real CMS.
See docs/M179-M185_HISTORY.md.

---
 
## M196 REAL CMS PASS + M197 EBCDIC Git SHA fix (Oct 12)

At 10:10 on actual z/VM 6.3 CMS, newly built
`GITRP6M MODULE` passed:
`GITRP6 G 7736 10`. It validated **7,736 unique**
indexed objects in **0.66s elapsed** and reported:

```text
M196 OBJECT 7736 TYPE 2 SIZE 291 OID 9069E154EB145C25D8E1A8D31F72252C53E6684A
M196 RECORDS HEADER 3864789 BODY 3864790 LAST 3864799 COUNT 10
M196 STAGE MODEL RECORDS 3864799 EXPECTED 3864799
M196 READ ONLY INDEX OBJECT PLAN PASS
M196 INDEX OBJECT PLAN GATE PASS G 7736
```

The actual console truncated the OFFSET suffix
on the longer object line; the full 40-character OID
is visible. Object 7736 is a **291-byte Git tree**;
its tenth hexadecimal body record must contain
exactly **6 hex characters**.

M195's separate full eleven-record FSREAD also passed
on actual CMS earlier at 09:22 (0.01s). These facts
do **not** prove full SHA-1 verification of the stage.

**Critical M197 correction before real CMS build:**
canonical Git SHA-1 uses ASCII bytes `tree 291\0`,
not native EBCDIC C string bytes. The original M197
host-tested C code used native type literals and
`'0'`-based digits, which would hash incorrectly on
CMS. Corrected `src/GITVO7M.C` now constructs
the canonical Git hash prefix with explicit ASCII
type arrays, `0x20` space and `0x30` digits.
Strict host regressions verify the actual raw bytes,
including a 291-byte tree and M198 end-to-end
disposable-file SHA-1 test.

**Do not build or run old M197 code.** After this
corrective PR passes CI and merges, update from GitHub:

```sh
git pull
./cms-upload.sh GITVO7M.C
```

Then build the corrected `GITVO7M` and M198
`GITBX8` separately on CMS, only after checking
that disposable `GITVRAW DATA A` does not exist.
The final SHA check uses the exact expected OID:

```text
GITB8 G LAST 9069E154EB145C25D8E1A8D31F72252C53E6684A
```

Do not execute this M198 command before clean
assembler/compiler gates and absence of scratch.
Original G stage/index remain protected and
unchanged. See `docs/M179-M185_HISTORY.md` and
`docs/M179-M185_HISTORY.md` for safeguards.

---

## M198 — read-only FSREAD into NEW A scratch + full SHA1 (HOST-ONLY)

After a corrected clean `ASSEMBLE GITFL10` on real
z/VM 6.3 CMS, **M195 PASSED** at 09:22 on
October 12, 2026: full header plus ten body
records of final object 7736, valid hex/width,
0.01s elapsed. SHA1 remains unverified; no
post-run FILEDEF output was supplied.

M198 adds separate `GITBX8.ASSEMBLE` and
`GITB8.EXEC`. The assembler reads all eleven
absolute CMS records of the last object into
memory first, validates the exact body layout,
and **closes original G stage before any output**.
It then uses `FSOPEN OPENTYP=NEW` for
`GITVRAW DATA A1`: unlike REPLACE, this
refuses to overwrite an existing scratch.
It writes only that new disposable A file,
never the original stage or index.

The wrapper requires the actual 40-hex last
object OID from a successful M196 index plan,
refuses a pre-existing scratch file, invokes
native `GITBX8`, and requires the existing M197
`GITVO7` complete SHA1/OID verification before
reporting any full M198 PASS. On error it leaves
scratch alone for inspection instead of blindly
erasing it.

**M198 is host-only pending real CMS assembly
and runtime; do not run before M196 real CMS
index plan PASS and M197 module build.**
See `docs/M179-M185_HISTORY.md`.

The next immediate CMS batch (if already
uploaded) is **M196 only**:

```text
QUERY FILEDEF
STATE GITRP6M C A
CMSCLNK GITRP6M PLAIN
STATE GITRP6M MODULE A
GITRP6 G 7736 10
QUERY FILEDEF
```

Retain the proven M188 complete authenticated
closure baseline (205.04s CPU / 208.27s elapsed)
and keep all original protected G files intact.

---

## M195 — real CMS complete LAST body PASS (Oct 12)

Actual corrected target command produced:

```text
ASSEMBLE GITFL10
ASSEMBLER (XF) DONE
NO STATEMENTS FLAGGED IN THIS ASSEMBLY
GITFLP G LAST
M195 LAST HEADER PASS
M195 LAST TEN BODY RECORDS HEX PASS
M195 READ ONLY COMPLETE BODY RECORDS PASS
M195 COMPLETE BODY GATE PASS G LAST
Ready; T=0.01/0.01 09:22:59
```

M195 fully passed its stated header/body
physical-record goal. It does not independently
authenticate the Git OID. See `docs/M179-M185_HISTORY.md`.

---

## M195 assembly correction — October 12, 2026

Actual CMS `ASSEMBLE GITFL10` returned **RC8** with
`IFO236` and `IFO016`: the label `EVENCHECK` was
nine characters long, exceeding the eight-character
IBM assembler symbol limit. **M195 has not passed
CMS assembly or runtime validation.** The isolated
source now uses seven-character `EVENCHK` at
both the branch operand and label definition,
with corrected opcode alignment.

The updated `tests/test-m195-last-body.py`
now checks all labels in M193/M194/M195 assembler
sources, not merely 72-column source width.
This closes the host-test gap that permitted
the error into the earlier merged source.

After the corrective PR merges, from Mac `src`:

```sh
git pull
./cms-upload.sh GITFL10.ASSEMBLE
```

Then CMS MAINT:

```text
GLOBAL MACLIB OSMACRO DMSGPI PDPCLIB
ASSEMBLE GITFL10
```

Only if **NO STATEMENTS FLAGGED**:

```text
GLOBAL TXTLIB PDPCLIB
LOAD GITFL10 (NOAUTO NOMAP
GENMOD GITFL10
GITFLP G LAST
QUERY FILEDEF
```

Preserve original G stage/index and prior
proven CMS modules. Keep M196 target and M197
integration gates distinct. See
`docs/M179-M185_HISTORY.md`.

---

## M197 — full canonical Git object SHA1 core (HOST-ONLY)

New separate `GITVO7M.C` validates a complete
bounded Git object supplied through **disposable**
`dd:OBJIN`. It checks object number, type, size,
complete hex record count/width/content, and independently
calculates canonical SHA-1 for Git commit/tree/blob/tag.
An exact expected 40-hex OID must match the stored header
and computed 20-byte digest; malformed, extra, missing
and corrupted body records fail closed.

`GITVO7.EXEC` only binds an existing disposable
`GITVRAW DATA A` to read-only OBJIN and clears its
own FILEDEF. It **never opens the original G stage**
or index. Strict C89 host tests cover zero/multiblock
objects, boundary records and SHA-1 negative cases.

**M197 is a host-only verification core**, not a working
FSREAD-to-object bridge. It must not run on CMS without
an independently prepared disposable object fixture and
expected OID. Full target integration is still pending.

M195 ten-record LAST body test and M196 selected-object
record plan are both already merged and host tested.
Neither has yet been reported as passing on real CMS.
Proceed with their exact existing CMS tests first:
`GITFLP G LAST` and `GITRP6 G 7736 10`.
See `docs/M179-M185_HISTORY.md` for scope and safeguards.
The proven M188 full tree closure remains 208.27s elapsed.

---

## M196 — verified index-selected object record plan (HOST-ONLY)

M196 introduces new, separate `GITRP6M.C` and
`GITRP6.EXEC`. Unlike the sample-only M192,
this strict C89 reader validates all 7,736 unique
indexed object numbers and OIDs, enforces increasing
physical offsets, reconciles the original 3,864,799
stage records, then prints the selected object's
actual indexed Git type/size/OID and absolute CMS
header/body/last record positions. It never opens
the stage file or changes original G data.

**After green host CI and merge, the next M196 CMS
gate is index-only:**

Mac `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITRP6M.C GITRP6.EXEC
```

CMS MAINT:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
QUERY FILEDEF
CMSCLNK GITRP6M PLAIN
STATE GITRP6M MODULE A
GITRP6 G 7736 10
QUERY FILEDEF
```

This must print exact original-LAST record geometry:
HEADER 3864789, BODY 3864790, LAST 3864799,
COUNT 10, plus original index OID/type/size and
a model PASS. All target results remain pending.

**M195 has not yet been executed on real CMS.**
Its independent full-body probe must be validated
separately; a successful M196 index-only model
cannot substitute for M195 or a Git SHA-1 check.
The full authenticated M188 two-scan closure
remains the proven 208.27s elapsed baseline.
See `docs/M179-M185_HISTORY.md`.

---

## M195 — bounded complete LAST body (HOST-ONLY; CMS NEXT)

October 11, 2026: M194 assembled successfully on actual
z/VM 6.3 CMS and **FIRST, MID, LAST all passed**, each reading
the correct header **and first body record**. Every invocation
reported 0.01s elapsed. M193's preceding one-record FIRST,
MID and LAST tests also passed.

M195 is a new **isolated, read-only native FSREAD** gate:
`GITFL10.ASSEMBLE` / `GITFLP.EXEC`. The known final
header of object 7,736 is CMS RECNO 3,864,789; original
stage end is 3,864,799. Thus exactly ten body records
remain. M195 checks all ten, requiring nine full 64-character
hex records, an even nonzero 2..64-character final record,
valid EBCDIC hex throughout, aggregate 289..320 bytes,
FSCLOSE and native/wrapper RC0. Strict host source and
synthetic index-model checks accompany the new module.

**CMS execution is not yet proven.** After CI and merge,
use Mac `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITFL10.ASSEMBLE GITFLP.EXEC
```

Then follow the read-only preflight and exact assembler
build in `docs/M179-M185_HISTORY.md` before:

```text
GITFLP G LAST
QUERY FILEDEF
```

A successful ten-record pass is **not** Git SHA-1/OID
verification. M188 remains the verified 208.27s full-tree
closure baseline. No stage/index write, reimport, old
module replacement, GIT600 format/erase, or physically
overlapping PMAINT 0141 write-link is permitted.

---

## M194 — FIRST/MID/LAST header and body REAL CMS PASS

Actual M194 target transcript on October 11, 2026:
`ASSEMBLE GITFRB` reported `NO STATEMENTS FLAGGED`;
`LOAD`/`GENMOD` succeeded; `GITFRP G FIRST`,
`GITFRP G MID`, and `GITFRP G LAST` each printed:

```text
M194 FSREAD HEADER RETURNED
M194 RECORD HEADER PASS
M194 FSREAD BODY RETURNED
M194 FIRST BODY RECORD HEX PASS
M194 READ ONLY BODY PROBE PASS
```

and exact wrapper `M194 BODY PROBE GATE PASS G FIRST`,
`... G MID`, `... G LAST`, respectively, each at
0.01s elapsed. No post-run `QUERY FILEDEF`
output was supplied. M194 is complete for this
two-record feasibility gate, not for full-object SHA.

---

## M193 native CMS FSREAD FIRST, MID and LAST — REAL TARGET PASS

October 11, 2026: the actual `GITFSP G LAST`
probe passed on real CMS and returned:

```text
M193 DIRECT FSREAD G1 PROBE BEGIN LAST
M193 FSREAD BEGIN LAST RECNO 3864789
M193 FSREAD RETURNED
M193 RECORD HEADER PASS
M193 READ ONLY FSREAD PROBE PASS
M193 CMS FSREAD GATE PASS G LAST
Ready; T=0.01/0.01 15:45:07
```

FIRST (RECNO 1), MID (1,969,357) and LAST
(3,864,789) have all passed with identical
0.01s reported elapsed times. The three single-record
header checks establish real CMS random-record
feasibility, not a full-object hashing speedup.
No post-M193 `QUERY FILEDEF` transcript was supplied.

---




## M192 real CMS PASS; M193 native FSREAD header probe

M192 compiled and passed **on actual z/VM 6.3 CMS**.
The protected `M173NET STAGE G1` is RECFM V,
LRECL 64, **3,864,799 records** occupying 62,189
CMS blocks. With 7,736 unique index objects, the
index-only model calculated exactly the same record
total, including these physical header locations:

| Object | CMS RECNO | C stream offset |
|---|---:|---:|
| 1 | 1 | 0 |
| 3868 | 1,969,357 | 127,843,709 |
| 7736 | 3,864,789 | 250,858,746 |

M192 returned all native/wrapper PASS markers in
**0.61s elapsed**. This proves the record ordinal
arithmetic against real stage metadata without
reading any stage content. It does not prove
random CMS record-read performance.

M193 now adds a separate `GITFSRD.ASSEMBLE`
module with direct `FSREAD` (FORM=E,
RECFM=V, BSIZE=64, NOREC=1) to probe **one
M192-verified header** by absolute CMS RECNO.
Its distinct wrapper `GITFSP.EXEC` dispatches
FIRST, MID, or LAST directly to the native
MODULE, with console output and no PIPE/STEM
buffering. An exact `OBJ` prefix check and
`FSCLOSE` must succeed before a native PASS.
All input is read-only and the original G
files are never changed.

Strict host static guardrails and the record
arithmetic fixture passed, but IBM CMS macro
assembly/execution remains **unverified**.
The safe first target trial is `GITFSP G FIRST`
after a clean standalone native assembly;
see `docs/M179-M185_HISTORY.md`. The
working M188 two-scan reader remains the
208.27-second real CMS baseline. Do not run
the 272-seek M190 experiment.

---


## M192 — index-only physical CMS record-number plan

M191's actual FIRST and MID probes passed, but
MID at C text-stream offset 127,843,709 took
**25.82s elapsed**, compared with FIRST's
**0.64s**. Thus the full 272-seek M190 walk
remains an inappropriate next performance test.

IBM CMS `FSREAD` supports accessing a file
by its *one-based physical record number*.
New independent `src/GITRCNM.C` and
`src/GITRCN.EXEC` test whether those
record positions can be calculated directly
from the existing Git stage index sizes:
one object header plus one 64-hex-character
record per 32 decoded bytes (one empty body
record when the object has size zero).

M192 **only reads the index**, never scans or
seeks the 3,864,799-record stage. It prints
physical header record ordinals for first,
middle and last object and checks the
predicted total against the actual observed
3,864,799 records. The model is fail-closed
on mismatches or invalid index structures.
Strict C89 host CI generates 7,736 distinct
synthetic objects and tests exact line
positions, malformed index rejection and
unchanged source hashes.

This is a **record-layout model**, not yet a
CMS FSREAD adapter or native tree reader.
No target runtime improvement is claimed.
See `docs/M179-M185_HISTORY.md`.
M188 remains the proven 208.27-second
two-scan reader; original G files and
existing modules are unchanged.

---


## M191 actual CMS indexed seek evidence

M191 FIRST and MID read-only header probes both
**passed on actual z/VM CMS**. FIRST at offset 0
took **0.64s elapsed**; MID at indexed offset
127843709 took **25.82s elapsed**. This indicates
potentially expensive location-dependent C text
seeks. The full 272-seek M190 walk remains
**unverified and not recommended**; the LAST
probe has not run. Investigating native CMS
record-number FSREAD as a separate approach,
first through read-only host mapping tests.
See `docs/M179-M185_HISTORY.md`.

---


## M190 interruption; M191 direct CMS seek diagnostic

A real z/VM 6.3 test successfully built
`GITPSKM MODULE` but its terminal output
after `GITPSK G ...` was only `HX` and
`CMS`, with **no native seek preflight,
tree closure, target PASS or final Ready**.
IBM documents HX as *Halt Execution*,
which returns the terminal to CMS. Thus
M190 is **not target verified**, and the
reason it was interrupted remains unknown.
Its wrapper buffers native output using
`PIPE CMS ... | STEM`, hiding progress
until the native call returns.

New isolated M191 `GITPRBM.C` and
`GITPRB.EXEC` provide a **read-only,
direct-console** seek diagnostic that
checks just one indexed first, middle, or
last stage header without scanning the
multi-million-line stage. Progress is
flushed before and after `fseek`; there
is no buffered native-output PIPE. It
fails closed for mismatched positions,
headers and invalid indexes, owns only
temporary FILEDEFs, and never modifies G.

After strict host CI, run `GITPRB G FIRST`
first, then separately MID and LAST if
safe. The full runbook is
`docs/M179-M185_HISTORY.md`. Do **not**
repeat the full M190 walk merely to
diagnose `fseek`. M185 and M188 stay
target-proven, the latest M188 elapsed
baseline being **208.27s** (two scans,
zero seeks). No original G files changed.

---


## M190 — experimental indexed reachable-blob readback

The current **actual CMS positive-path** baseline is
M188 CPU **205.04s**, elapsed **208.27s**:
8 trees, 272 reached blobs, 280 verified objects,
7736 indexed unique, two full sequential stage
scans and zero seeks. Its observed 1.70s elapsed
advantage over M185 is only 0.81% (one sample);
a post-run FILEDEF result was not supplied.

M190 is an **independent HOST-ONLY candidate**:
`GITPSKM.C` / distinct wrapper `GITPSK.EXEC`.
It validates the entire original stage/index
and authenticates all trees in a **single full
forward scan**, traverses the requested root,
and reopens the stage read-only to `fseek`
directly to each 272 reached blobs using
first-pass verified `ftell` offsets. Every
sought header and reached blob SHA1 is fully
reverified; any unsupported seek or mismatch
fails closed. All protected original files
and prior modules remain unchanged.

Host CI on 7736 unique synthetic indexed
objects passed strict C89, exact 280-object
reached closure, one scan/272 seeks, and
malformed index/hex/SHA negatives. A seven-round
Linux-host comparison showed **M190 0.0369s**
vs **M188 0.0719s** on a disposable 15.36MB
fixture. **Those are not z/VM results.** IBM
CMS's C text stream seek behavior on `dd:STGIN`
is unproven; test only as a separate reader,
following `docs/M179-M185_HISTORY.md`.

---


## M188 real CMS target PASS — 208.27 s elapsed

On October 11, 2026, **M188 passed** on the actual z/VM 6.3
target. The isolated `GITPH8 EXEC` and `GITPH8M MODULE`
verified 8 trees, 272 blobs, 279 entries, 280 reached
objects and 7,736 unique indexed OIDs. Two forward
scans each read 3,864,799 CMS stage text records,
with zero random seeks. Native CPU **205.04s**,
elapsed **208.27s**. The previous real CMS M185
was CPU 206.72s, elapsed 209.97s, so the
single observed M188 run is **1.70s/0.81% shorter**.
This small difference is not a robust performance
claim without repeated samples. G was checked as a
4096-byte disk; stage/index present; FILEDEF clean
**before** execution. The transcript did **not**
include post-run `QUERY FILEDEF`; final DD cleanup
not independently proven. Original modules and G
data remain preserved. Evidence:
`docs/M179-M185_HISTORY.md`.

---


## M189 eight-way hex validator — host-only negative speed result

M189 uses separate `GITPH9M.C` and `GITPH9.EXEC`,
cloned from M188, but checks eight skipped hex chars
with a single combined validhex-table test before
the unchanged strict suffix handling. Full C89
host SHA/record/index/parity tests pass; no
protected G data or proven modules are modified.

On one seven-run Linux comparison, M189 median
**0.0427s** versus M188 **0.0407s** and M185
**0.0411s** on the same 15.36MB host fixture.
Thus **M189 did not improve host speed**.
This is **not real CMS evidence**. M185 remains
the fastest verified on z/VM at **209.97s**.
Prioritize the isolated M188 CMS experiment
ahead of M189. Full details and optional
independent M189 runbook:
`docs/M179-M185_HISTORY.md`.

---


## M188 isolated native EOL fast path (host proven only)

M185 is confirmed on real z/VM 6.3: CPU 206.72s,
elapsed **209.97s**, exact authenticated
8-tree/272-blob/280-object closure, 7736 unique
index objects and two 3864799-record stage scans.

New `GITPH8M.C` / distinct `GITPH8.EXEC` adds
bounded LF, CRLF and NUL suffix fast paths while
retaining M185's full fallback, selected SHA1
authentication, strict skipped-hex rules and
read-only stage/index. GitHub native C89 CI passed,
including differential malformed suffix/SHA tests.
Linux fixture medians: M188 0.0735s versus M185
0.0766s (seven rounds), **host-only evidence**.
Actual M188 CMS performance is unmeasured.
See `docs/M179-M185_HISTORY.md` for safe instructions.

---


## M185 real CMS performance milestone — 209.97 seconds

On October 11, 2026, isolated M185 `GITPH5 EXEC` and
`GITPH5M MODULE` **compiled and passed on actual z/VM 6.3**.
The exact authenticated closure remained 8 trees, 272 blobs,
279 entries, 280 verified objects and 7,736 unique indexed
objects. Both full scans read 3,864,799 CMS stage text records,
with no seeks. Real CPU **206.72s**, elapsed **209.97s**,
vs M181 real elapsed 298.38s: **88.41s/29.6% faster**.
M185 now replaces M181 as the *measured performance baseline*,
without overwriting any earlier module. A successful post-walk
`QUERY FILEDEF` has not yet been supplied. Target transcript
and bounds: `docs/M179-M185_HISTORY.md`.

---


## M187 — synthetic 7,736-object native index/closure parity

Without waiting for further z/VM 6.3 results,
M187 adds `tests/test-m187-live-scale.py` to
strict C89 host CI. It builds a disposable
Git stage/index with exactly 7,736 unique
indexed object IDs, including 8 trees and
272 reachable blobs, and verifies the same
280-object closure and 279 entries returned
on the real G disk. The four isolated native
readers M181, M182, M183 and M185 must agree
on authenticated closure, two forward scans,
15,472 object-header visits and zero seeks.
The synthetic host fixture contains **15,791
text records**, not the live 3,864,799 per
pass. Unreachable malformed hex, reached
SHA corruption and truncated stage all
fail closed. Original temp fixture hashes
are unchanged when the test completes.

This is host-only correctness evidence,
**not M182/M183/M185 z/VM performance proof**.
Latest real CMS elapsed benchmark remains
M181 **298.38s**. No read or write to
protected G data. See `docs/M179-M185_HISTORY.md`.

---


## M186 — deterministic host-only skipped-record differential safety

M186 adds `tests/test-m186-skip-differential.py`,
a reproducible seeded (186) fault matrix that runs
M181, M183 and M185 on **181 shared positive and
negative** Git-format stage mutations. It rejects
any new native reader that returns success when
the original target-proven M181 reader rejects,
or that produces a different authenticated closure.
It verifies unchanged source index and restores
the disposable stage. No new CMS code or protected
G input is modified. Detailed test rules and
limitations: `docs/M179-M185_HISTORY.md`.

The latest real-CMS positive performance reference
is **M181 298.38s elapsed** (294.57s CPU). M182,
M183 and M185 have host proof only; their relative
Linux host timings do **not** establish CMS speed.

---


## M185 — direct skipped-record validation, host gated

Continuing without waiting for M182/M183 CMS evidence,
M185 adds an isolated C89 reader `GITPH5M.C` with
distinct REXX wrapper `GITPH5.EXEC`. It preserves
M181's selective two-scan Git SHA/index/tree rules but
removes `strlen` from the frequent *skipped*
hex-text-record validation path. It checks all expected
hex characters and any trailing space, CR or LF in
one bounded read, retaining native encoding support
and fail-closed invalid records. Stage lines are
not skipped; each is still read and checked.

All new tests compile strictly C89, compare correct
closures, and reject shortened/extended records,
malformed hex, malformed suffixes and corrupted
reached SHA. A disposable Linux 15.36MB stage
benchmark shows the new M185 median **0.0760s**
versus M183 **0.0908s**, M182 **0.0987s** and
M181 **0.1211s** in one seven-round host run.
These are **host-only observational timings**;
the last actual z/VM 6.3 result is M181
**298.38s** elapsed (CPU 294.57s). M182,
M183 and M185 are not target-proven; no real
CMS speedup claimed. See `docs/M179-M185_HISTORY.md`
for isolated and nondestructive target commands.
No stage/index/PACK or older module changed.

---


## M184 — independent native host comparison, no CMS wait

Without pausing for the pending M182/M183 real CMS
measurements, M184 adds a **host-only comparative
benchmark**, `tests/bench-native-stage.py M184`.
It strictly compiles all three native C89 readers
M181, M182 and M183, builds a disposable canonical
stage/index (15,360,000-byte unreachable blob),
verifies identical SHA-authenticated tree closure
and read-only input hashes, then reports rotating
7-run median/min/max host durations. Timings are
observational only and are **not CMS performance
claims**; CI can fail for correctness or input
mutation, never for a speed ranking.

On the Linux GitHub CI runner, the seven-run
medians on the 15.36MB skipped-blob host fixture were
**M181 0.1197s, M182 0.1010s, M183 0.0913s**;
all exact authenticated closure and unchanged-input
checks passed. These timings are **not** z/VM speed
claims or a replacement of target proof.

M181 remains the fastest **real target measured**
at **298.38 seconds** elapsed, CPU 294.57s.
M182 and M183 have host integrity PASS but
z/VM runtime remains unmeasured. No existing
CMS module or `GIT600` persistent stage/index
is changed by this purely host-based M184 task.
Details: `docs/M179-M185_HISTORY.md`.

---


## M183 — isolated four-way skipped-record hex validation (host CI)

The latest **real CMS** native performance baseline is M181:
`GITPHX EXEC` -> `GITPHXM MODULE`, 298.38s elapsed,
294.57s CPU, with 8 trees, 272 SHA-authenticated
reachable blobs, 280 verified objects and two
3,864,799-line sequential stage scans. M181 remains
unchanged and target-proven. No post-run FILEDEF
was included in its successful run transcript.

M182 (two-digit hex lookup) is host-proven **only**;
its actual z/VM execution time remains unknown.
M183 is another **independent** host-tested candidate
using new `GITPH3M.C` and `GITPH3.EXEC`. It forks
the target-proven M181 reader (not unverified M182),
reuses the original computed trimmed record length
rather than calling `strlen` twice, and validates
four hex characters at a time using M181's small
native lookup table. All indexes, SHA1 verification,
two-scan count and skipped-byte validation remain.
No original module, disk, stage or index changes.
**No CMS speedup is claimed** for M183.
See `docs/M179-M185_HISTORY.md` for host scope and
safe conditional native commands.

---


## M181 real CMS pass; isolated M182 native pair-hex candidate

October 11, 2026: the fixed separate `GITPHX EXEC`
and `GITPHXM MODULE` passed real z/VM 6.3:
8 trees, 272 blobs, 279 entries, 280 verified objects,
index 7736/7736, two full 3,864,799-line scans,
zero seeks and correct Git SHA authentication.
CPU **294.57s**, elapsed **298.38s**, versus
M179 elapsed 459.44s, a **161.06s/35.1%**
single-run improvement. The final independent
`QUERY FILEDEF` was not included in this success
transcript. Verified original M181 remains preserved.

Next M182 is an isolated host-tested research branch:
native `GITPH2M.C` and differently named
`GITPH2.EXEC` use a 65,536-entry table to validate
**pairs of skipped hex characters**, rather than
M181's 256-entry one-character table. It retains
the proven two-pass, selective-SHA and failure
checks and is **not yet real-CMS target-proven**.
It may be faster or slower. Exact read-only next
commands: `docs/M179-M185_HISTORY.md`. Do not
reformat/reimport or touch permanent G inputs.

---


## M181 name-collision correction (October 11, 2026)

On real z/VM 6.3 CMS, the first M181 build of
`GITPHX MODULE A` succeeded, but the `GITPHX EXEC`
wrapper's internal `PIPE CMS GITPHX WALK` dispatched
back into the EXEC. Nested EXEC interpreted `WALK`
as a filemode, producing `M181 FILEMODE INVALID`
and wrapper RC 8 before the native tree scan began.
The protected G stage/index remained intact and
`QUERY FILEDEF` was empty before and after.

The corrected split is **`GITPHX EXEC`** (wrapper)
calling **`GITPHXM MODULE`** (native C89 reader), built
from new `GITPHXM.C`. No erase/rebuild/reformat or
change to proven modules. Host CI explicitly guards
against module/EXEC name collisions. **Real CMS native
M181 closure is still pending.** Exact corrected
upload/compile commands: `docs/M179-M185_HISTORY.md`.

---


## M181 isolated selective-SHA hex validation experiment (host CI)

The real z/VM 6.3 M180 test proved single-pass functionality,
but it ran **708.52s elapsed**, versus **459.44s** for M179.
One-pass authentication SHA1-checked 2220 indexed blobs,
instead of only 272 reachable blobs. M180's 249.08s
slowdown is documented in `docs/M179-M185_HISTORY.md`.
The old G data and all earlier modules are preserved.

M181 is a **separate C89 module** `GITPHX.C`, exposed via
`GITPHX.EXEC`, retaining the selective two-scan M179
integrity checks but accelerating skipped hex-record
validation using a 256-entry native ASCII/EBCDIC
character table. All bytes and record lengths are
still checked, with same SHA-authenticated root closure.
Strict host C89 parity/corruption tests pass.
**M181 is not yet CMS target-proven or speed-proven.**
Use the conditional target runbook in
`docs/M179-M185_HISTORY.md` without rewriting G.

---


## M180 actual CMS pass — correctness with slower performance

October 10, 2026: isolated one-scan `GITPONE/GITPONCE`
compiled and passed on real z/VM 6.3 CMS. Same expected
8 trees, 272 blobs, 279 entries, 280 authenticated objects,
7736/7736 indexed OIDs and **zero seeks**, with one scan
of **3,864,799 text lines**. It SHA-authenticated 2,220
indexed blobs to support the requested 272 reachable blobs.
CPU **704.95s**, elapsed **708.52s**, clean before/after
FILEDEF. Compared with M179 elapsed **459.44s**, M180
is **249.08s (about 54.2%) slower**. M180 proves the
one-pass algorithm is functional, not faster. Preserve
M178/M179 selective two-pass readers and all G stage/index.
See `docs/M179-M185_HISTORY.md`.

---


## M179 native stage profiling PASS; M180 single-pass candidate

On real z/VM 6.3 CMS, the new M179 profiler returned RC0,
the same 8-tree/272-blob/280-authenticated-object closure,
7,736 unique objects indexed, and reported **3,864,799
stage text records per scan**, 7,729,598 for two scans.
All four C89 `clock()` phases returned `UNAVAILABLE`.
CPU 454.92s, elapsed **459.44s** (October 9, 2026);
M178 had elapsed 460.66s. Neither result establishes
a comparative speedup. M179's final FILEDEF postcheck
has not been provided. Details: `docs/M179-M185_HISTORY.md`.

M180 is a **new, isolated, host-tested C89 experiment**
(`GITPONE.C` and `GITPONCE.EXEC`), not yet proven
on the CMS target. It authenticates all indexed tree
and blob objects during a **single** sequential stage
scan, keeps only authenticated tree bodies resident,
then validates the requested graph from the verified
index and blob-authentication markers. It trades more
SHA1 computations for eliminating one complete stage
read. The permanent G STAGE and INDEX and all proven
M176/M177/M178/M179 modules remain unchanged.
M180 may be faster or slower and is never a replacement
without measurement. Runbook: `docs/M179-M185_HISTORY.md`.

---


## M179 isolated stage/CPU profiling (host CI; CMS pending)

After M178's real CMS PASS (8 trees, 272 blobs, 280 verified,
7736 unique index, two scans, 0 seeks, CPU 455.95s / 460.66s
elapsed), M179 adds a **separate** C89 read-only diagnostic
module `GITPPRF.C` and safe `GITPPROF.EXEC`. It reports
physical stage text-line counts for each full scan and
four `clock()` CPU phases: index/map, tree scan, graph
walk and blob scan. Its host parity/corruption tests pass.
**It is not yet real-CMS target-proven and does not claim
a speedup.** See `docs/M179-M185_HISTORY.md` for the exact
two-file transfer and conditional target test. The known-good
M173–M178 readers and verified G stage/index are untouched.

---


## M178 — native CMS tree reader TARGET PASS (October 9, 2026)

M178's isolated C89 forward-only, two-pass authenticated tree walker
(`src/GITPFST.C` through `src/GITPFAST.EXEC`) passed host CI and a
**real z/VM 6.3/CMS** run on the retained `GIT600` G disk.
The clean native module build was followed by a positive `GITPFAST G`
tree-closure verification of **8 trees, 272 blobs, 279 entries,
280 authenticated objects, 0 gitlinks**, against the verified
**7736/7736** stage index. The instrumented reader reported
**2 forward scans, 15472 object-header visits, 0 seeks** and authenticated
272 reached blobs. Largest object: 393767 bytes; peak resident:
6546851 bytes. CMS CPU **455.95s**, elapsed **460.66s**.

Both before and after `QUERY FILEDEF` returned no user-defined
FILEDEFs. Terminal markers: `M178 TREE CLOSURE PASS` and
`M178 VERIFIED FAST TREE TARGET GATE PASS`. The original M176/M177
code and G stage/index were not changed. **No comparative speedup
has been established**, because the M177 TREE elapsed counter
previously overflowed. The next step is independent measurement and
bounded performance analysis, not any rebuild/reformat of the
verified G stage/index. Details: `docs/M179-M185_HISTORY.md`.

---


## Current live CMS native-Git checkpoint — October 9, 2026

The native CMS Git client now has a verified **7,736-object**
GitHub PACK stored on an independently provisioned
1600-cylinder, 4KB-block **GIT600** CMS G disk,
rather than overrunning A. The retained original
`M171NET PACK/META A` input is preserved.

- **M173 LIVE PASS:** native OFS-capable import,
  `M173NET STAGE G`, with independent readback
  (elapsed **1396.22 seconds**, October 9, 10:48:28).
- **M174 LIVE PASS:** index `M174NET INDEX G`
  with **7736 unique OIDs**, full index check and
  stage audit and lookup of Git tip commit
  `ADA83FF3B3813961CEF2A9FFC50A453540039E0B`
  (elapsed **1459.65 seconds**, October 9, 11:27:15).
- **M176 LIVE PASS:** recursive closure of the
  tip's root `CCB18BEC067E7886D70B82EF138EE56A8B899A61`.
  **8 trees, 272 blobs, 0 gitlinks, 279 entries,
  280 verified objects**, largest object
  **393767 bytes**, peak resident **394058 bytes**;
  `M176 LIVE ROOT TREE CLOSURE TARGET GATE PASS`,
  October 9, 12:51:40. The CMS timing field
  overflowed (`T=*.**/*.**`), so do not attribute
  an elapsed time.
- The M176 output includes `M175 PACK INFO PASS`
  from its internal object-information call.
  **Standalone M175CHK G terminal success has
  not been provided** with that output; keep
  the distinction.

**M177 TREE LIVE CMS PASS — October 9, 2026 15:32 CDT.**
The new `GITPVIEW TREE G CCB18BEC...` read-only command
verified the same root closure of 8 trees, 272 blobs,
279 entries and 280 objects using the retained G stage/index,
and printed `M177 PACK VIEW TREE PASS` on real CMS.
The CMS time field overflowed and no exact duration is known.
**M177 INFO and standalone M175 are now also live CMS PASS.**
At 15:47 the `GITPVIEW INFO G <tip>` returned the
correct tip commit, root tree, parent and 7736 unique
indexed objects, with a `M177 PACK VIEW INFO PASS` marker;
CMS elapsed 41.52 seconds. Identical before/after
`QUERY FILEDEF` responses were `No user defined FILEDEF
in effect`. At 15:51 the full `M175CHK G` verified the
commit, root and parent and ended in
`M175 VERIFIED RANDOM ACCESS TARGET GATE PASS`;
elapsed 124.65 seconds. **M173–M177 positive-path CMS
target gates are complete**. Next: isolated, non-mutating
M178 tree-closure performance research.
See `docs/M179-M185_HISTORY.md`.
Do not reformat G or overwrite `M173NET STAGE G`,
`M174NET INDEX G`, original PACK A, or earlier
sealed generations. An overlapping fullpack
`PMAINT 0141` exists on VMCOM1; do not write
through it while G holds data.

Detailed current checkpoints and instructions:
`docs/M173_PERSISTENT_DISK_RUNBOOK.md` and
`NOTES.md`. Historical status farther down
is retained as chronological context.

---


Native IBM platform development experiments.

## CMS Git client

The active project is a native Git client for CMS on z/VM 6.3 Evaluation
Edition under Hercules Aethra on an AWS EC2 Debian ARM64 host.

The Git-format core is target-proven through M10: objects, refs, PACK handling,
bounded inflate/delta reconstruction, pkt-line/side-band transport, and a real
Git upload-pack fixture. M11 native CMS TCP and bounded binary-safe HTTP framing
are also target-proven.

Current practical HTTPS architecture:

- CMS/z/VM: native REXX/SOCKETS TCP and Git smart-HTTP bytes.
- EC2 TAP gateway: `192.168.200.1/24`.
- CMS: `192.168.200.2/24`.
- stunnel listener: `192.168.200.1:8443`, bound only to the TAP interface.
- stunnel establishes verified modern TLS to `github.com:443`, including CA
  chain validation, hostname checking, and SNI.
- The CMS -> EC2 stunnel -> GitHub path is target-proven through live Git
  smart-HTTP discovery and upload-pack. A 340,027-byte live PACK containing
  1,808 objects was received and its PACK SHA-1 verified on CMS. The next work
  is optimizing the bounded object walker for practical large-pack performance.

Native z/VM System SSL work is preserved as an experimental/research path.
Current GitHub uses an ECC Sectigo certificate chain that the old z/VM 6.3
service level cannot currently validate/import with the installed crypto
facilities, so it is no longer the practical blocker for GitHub transport.

See `docs/NATIVE_REF.md`, `docs/CURRENT_STATE.md`, and `NOTES.md`.

## Native PACK checkpoint: staging and index prototypes

`GITCWALK OPTCHECK` is CMS-proven for the captured 1,808-object PACK:
the optimized and reference SHA-1 implementations agreed on every
reconstructed object, including all 1,117 OFS_DELTA objects.
`OPTSHA` ran in 19.29 s CPU / 19.42 s elapsed on one CMS run.

The original STAGE output FILEDEF error was corrected by specifying
RECFM V and LRECL 80. On September 26, CMS STAGE wrote all 1,808
reconstructed objects; VERIFY independently rehashed every stored
object and BADSTG rejected deliberately altered content. GITCIDX
CHECK validated 1,808 unique indexed OIDs, and first/last GETs
returned independently SHA-1-checked object content on actual CMS.

The canonical compiler wrapper is now `CMSCLNK EXEC`, with the
existing native-inflater link mode as its default and a new `PLAIN`
mode for programs without inflater dependencies. It is prepared for
installation beside GCCCMS on F; see `docs/NATIVE_REF.md`. Its F-disk
placement and PLAIN linkage still require CMS validation.

The separate GITCIDX AUDIT mode and experimental ftell/fseek
seek index with direct SGET have passed host C89/CI regressions,
including corrupt stage and truncated-index tests. The faster seek
mode still needs real CMS validation. See docs/NATIVE_REF.md and
docs/NATIVE_REF.md for the full record and next target gate.
Native forward/external REF_DELTA resolution, safe committed storage
generations, and reboot/restart proof remain outstanding. Issue #2
remains open.

## Performance redesign: native PACK engine

The REXX-per-object pipeline is a correctness reference, not the intended
production architecture. On the captured 1,808-object PACK, a 20-object
prefix took 230.13 seconds initially and 64.44 seconds after bounded I/O
optimizations. Do not extrapolate a full-run time from the prefix: object
sizes and delta costs vary. A 90-minute interactive terminal test is not an
acceptable production workflow.

Target architecture (incremental gates):

1. Keep the existing strict walker and 27-case GITTEST suite as a regression
   oracle. Preserve the captured PACK; ALL overwrites the active buffer.
2. Remove remaining per-record REXX dispatch while retaining bounded file
   access. GIT9CTX SAVE now reads 16 object records per EXECIO directly.
3. Implement a native PACK engine with one CMS entry point: sequential
   buffered PACK input, header and varint decoding, GITNAPI inflation,
   binary object hashing, delta application, and a position/OID index.
   Reuse GITINFA; do not reimplement the inflater. Keep REXX for orchestration.
4. Native gates in order: regular-object fixture; 20-object prefix; delta
   fixture with OFS and REF; 100-object prefix; 500-object prefix; full
   1,808-object PACK with checksum and final boundary verification.
5. Use CPU time and elapsed time for every gate. A sub-five-second 20-object
   run is an engineering target, not an established capability.

Fail closed on malformed headers, short reads, invalid delta bases, wrong
object hashes, missing trailers and out-of-range offsets. No unbounded REXX
strings or repeated network capture. Do not claim native-engine parity until
its implementation and target-side tests demonstrate it.

## GCCCMS native C checkpoint (2026-09-26)

The working GCCCMS toolchain now builds C plus the existing assembler inflater. `GITCAPI` adapts GCCCMS's argument-list calling convention to `GITNAPI`; `GITCLNK` builds the combined CMS module. `GITCINF` passed both a known-good `abc` zlib fixture (3 output bytes, 11 compressed bytes) and the first live PACK object (270 output bytes, 182 compressed bytes, next object at offset 196). The later `GITCWALK` 1,808-object inflation timing and remaining correctness work are recorded in `docs/CURRENT_STATE.md`. C is the main native-engine implementation path; retain assembler where the existing inflater or CMS interfaces warrant it, and preserve the REXX walker as the correctness reference.

## GCCCMS native C integration (2026-09-26)

GCCCMS now builds a combined C and native assembler CMS module using GITCLNK, GITCAPI, and GITINFA. The adapter corrects GCCCMS argument-list calling convention. GITCINF passed the known abc fixture (3 output bytes, 11 consumed) and the first live PACK object (270 output bytes, 182 consumed; second object at offset 196). GITCWALK subsequently completed the 1,808-object inflation gate; see docs/CURRENT_STATE.md for its measured time and the remaining delta, OID, checksum, and persistence work. Preserve the REXX implementation as the correctness reference.

## GCCCMS build-tool rename

`CMSCLNK EXEC` supersedes `GITCLNK EXEC` as the build wrapper for
GCCCMS. Default `CMSCLNK GITCWALK` links the native inflater;
`CMSCLNK GITCIDX PLAIN` builds an ordinary C-only module. GitHub
source and host static checks pass. To install the EXEC next to
GCC on CMS F, check `QUERY DISK F`, copy from A to F only if F is
R/W, and validate the newly built module before retiring the
original A-disk GITCLNK. Instructions: `docs/NATIVE_REF.md`.

## September 26, 2026 — direct-seek index and native REF progress

On actual CMS, `GITCIDX AUDIT` independently verified all 1,808
staged bodies and 1,808 unique OIDs. Experimental `SBUILD` and
`SCHECK` succeeded; direct `SGET` retrieved both end objects,
confirming ftell/fseek across separate CMS program invocations
on an unchanged stage. Last-object retrieval improved from
7.59 s elapsed via the original V1 sequential GET to 1.77 s
via SGET in the observed runs (4.29x).

The native C PACK walker now also resolves backward, same-PACK
REF_DELTA chains by OID, without changing the proven original
PACK file or index. A deterministic three-object REF PACK has
passed host native parsing, negative tests and independent
`git index-pack`/`git cat-file` interoperability tests.
CMS validation of the updated REF-capable C source remains open.
See `docs/NATIVE_REF.md` for one isolated CMS fixture gate;
do not repeat the live GitHub network capture.

The remaining full-Git gaps include forward/external REF_DELTA
bases and atomic/recoverable content-addressable storage. GitHub
issue #2 remains open. The compiler wrapper has been renamed
`CMSCLNK EXEC` and is intended for the writable GCC F disk;
a command-labeled installation result was not present in the
most recent posted CMS transcript.

## Critical OID interoperability correction: Git ASCII vs CMS EBCDIC

The first CMS backward-REF test exposed a shared native C hash defect:
GCCCMS formatted the Git object header in EBCDIC, not the required
ASCII. As a result, previous 1,808-object C hash parity, staging,
readback and index checks established internal consistency but did
not establish canonical Git OIDs. PACK checksum and object inflation
remained correct. Inspected REXX GITBOID/GITOID already construct
canonical headers explicitly in hexadecimal.

GITCWALK and GITCIDX now construct explicit ASCII headers, and
known Git blob-vector tests detect CMS character-set regressions.
IDX2/SIDX2 index formats reject old incompatible indexes. Full
host CI passes, but the fixed C code needs the next CMS run.
Preserve existing GITSTAGE, GITINDEX and GITSEEK files; rebuild
separately named GITFIX stage/index/seek files from the saved PACK
after the corrected REF test succeeds. See docs/GENERATION_RECOVERY.md
for exact safe commands and source of the defect. Issue #2 remains
open for target proof and broader native Git functionality.

## September 26: canonical REF validation on CMS completed

The corrected GITCWALK RTEST and independent GITCIDX SELF now pass
on real CMS with known Git canonical SHA-1 vectors. The saved small
three-object REF fixture passes on the target, reconstructing abc,
abcd and abcde with the correct Git object IDs, and both chained
backward same-PACK REF_DELTA instructions apply correctly in RPACK
and RAPPLY modes. This fixes the confirmed EBCDIC canonical-header
failure exposed in the earlier REF attempt. The four separately
generated malformed PACK fixtures remain host-tested; they were not
part of the latest target transcript.

The earlier 1,808-object staging and seek/index artifacts still have
legacy incompatible IDs. The next required step is to rebuild the
existing captured PACK offline into new GITFIX STAGE, INDEX and SEEK
files and verify every object and both canonical IDX2/SIDX2 indexes.
Do not overwrite the original stage or indexes. Full commands and
success criteria: docs/GENERATION_RECOVERY.md. A later optional GITCIDX
PAIR mode is host-tested to compare both new indexes and independently
rehash each indexed body; it may require one new compiler transfer.

## Canonical native stage complete; full seek audit optimization

The full original 1,808-object captured PACK has now been rebuilt
on CMS with the corrected ASCII Git hashing implementation into
a new GITFIX STAGE A. Independent VERIFY passed every object,
and the new GITFIX INDEX A passed complete IDX2 AUDIT with
1,808 unique canonical Git object IDs. The separate GITFIX
SEEK A SIDX2 index was built and structurally checked successfully.
First canonical commit ID:
00D8D63229305230C8D37F884CE87F9E1A89468C.
Last canonical tree ID:
EB37E3F23FF4FC137D715D71A711D3B7632D75F2.

The initial SVAUDIT became very slow after progress 256 because
it reopened the staging file per object. Current GITCIDX source
avoids repeated opens and adds a one-pass SFAST hash/seek-cookie
verification. Optional PAIR compares both canonical index
generations and invokes SFAST. Host regression passed; actual
CMS execution of these updated audit modes remains the next
validation gate. See docs/GENERATION_RECOVERY.md for the minimal
GITCIDX-only transfer and test commands. Preserve all existing
canonical and historical datasets.

## Native M13 follow-on: external/forward REF and GEN2 seal

The corrected full 1,808-object GITFIX stage plus canonical IDX2
and SIDX2 indexes are now target-validated. Actual CMS SFAST
verified all 1,808 unique Git object OIDs in 20.99 seconds elapsed;
PAIR independently reconciled both indexes and every staged body
in 21.38 seconds. The first canonical commit and last tree were
retrieved by direct SGET in 0.15 and 1.81 seconds elapsed.

Independent subsequent C89 host development adds optional
`GITCWALK FPACK` for chained forward same-PACK REF_DELTA,
`XPACK/XAPPLY` for canonical-SHA-verified external CMS staged
bases, and `GITCIDX GENWRITE/GENCHECK` for a sealed GEN2
candidate-generation manifest. Host CI passes positive, malformed,
missing, duplicate and stale-data gates plus independent Git
forward PACK interoperability. **These new modes still require
actual CMS validation and are not yet a transactional object store.**
The exact nondestructive target gates are in
`docs/GENERATION_RECOVERY.md` and `docs/GENERATION_RECOVERY.md`.

## Real CMS forward/external REF and GEN2 passed

The optional new source is now target-proven for chained forward
same-PACK REF_DELTA (`FPACK`, two resolved forward references);
external REF base lookup from both a synthetic three-byte blob and
actual persisted `GITFIX STAGE A` (a 270-byte commit), both producing
Git's correct canonical OIDs; and GEN2 sealed generation creation
and independent revalidation in a separate invocation. Both GENWRITE
and GENCHECK fully hashed all 1,808 objects and reconciled both
canonical indexes with the stored seek cookies. They each completed
in about 21.6 seconds elapsed on CMS. The stage and indexes remained
unchanged. GEN2 is a candidate completion proof, not atomic promotion
or reboot recovery. Future work includes faster indexed external REF
lookup, cross-logon/reboot durability tests and safe active-generation
selection; see docs/GENERATION_RECOVERY.md and
 docs/GENERATION_RECOVERY.md.

## New optional fast external REF lookup

The real CMS XREAL test successfully used a complete sequential scan
of the validated GITFIX STAGE to reconstruct its own 270-byte first
commit. That scan took 8.17 s elapsed. GITCWALK now has an optional
indexed alternative, XSEEK/XSAPPLY, that reads the existing SIDX2
seek index, selects an external base's saved ftell cookie, seeks to
it and independently hashes the selected body before delta
application. Host tests for the targeted lookup, later record,
corrupted object, bad index cookie and truncated index passed:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36283446044 .
This new indexed path is NOT yet CMS-proven. The single-source
upload and nondestructive CMS gate using the existing XREAL PACK,
GITFIX STAGE and SEEK are in docs/GENERATION_RECOVERY.md.
Cross-logon GEN2 GENCHECK is also still pending; existing same-session
GENWRITE/GENCHECK already passed on CMS.

## 2026-09-27 10:20–10:21 CDT: GEN2 cross-logon survival PROVEN ON CMS

After an actual logoff and fresh CMS logon, the user successfully defined STGIN GITFIX STAGE A, IDXIN GITFIX INDEX A, FIDXIN GITFIX SEEK A and GENIN GITFIX GEN A. They ran only `GITCIDX GENCHECK`, without rewriting the stage, indexes, or GEN2 manifest. The existing program printed all SFAST progress checkpoints (256 to 1792), `FAST AUDIT VERIFIED 1808 UNIQUE 1808`, `PAIR VERIFIED UNIQUE 1808`, and `GENERATION VERIFIED 1808 UNIQUE 1808`, with normal RC 0, CPU 21.47 sec and elapsed 21.68 sec. This now conclusively establishes **same minidisk cross-logon CMS persistence** for this validated, unmodified full canonical 1,808-object candidate generation, including stage body integrity, both index descriptors, saved seek-cookie correspondence and manifest digest. It does NOT establish survival across an actual system restart or atomic active-generation promotion/multi-writer safety. Protect GITFIX STAGE/INDEX/SEEK/GEN A; no need to rerun GENWRITE or recapture the PACK. The next user-controlled, read-only durability gate, only when a regular system reboot is appropriate, is to reaccess the same A minidisk and reissue the four input FILEDEFs followed by GITCIDX GENCHECK. Concurrent with target work, independently design active-generation selection and interrupted-promotion recovery in GitHub, without claiming an untested atomic CMS file rename guarantee.

## M14: real full-audit dual-slot recovery now host-tested

The native C89 `GITSEL` parser now writes and checks bounded
checksummed SEL1 selector records. New `src/GITREC.C` binds each
slot to a distinct set of candidate FILEDEFs and requires the
actual GITCIDX full `GENCHECK` — including all staged canonical
Git OIDs, IDX2/SIDX2 pairing, saved seek cookies and GEN2 seal —
before selecting a candidate. Its host regression uses two
independent 1,808-record synthetic generations and tests rollback
from damaged GEN2, modified stage, truncated seek index, missing
ordinary index and spoofed selector names. The complete host
suite passed at
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36330993480 .

This is not yet compiled on CMS and performs no automatic active
pointer writes. Real CMS compilation and a *read-only* selection
test using protected GITFIX as the older generation and disposable
SEL1 files are described in docs/NATIVE_REF.md. Existing
GITFIX has already passed same-minidisk cross-logon GENCHECK;
system reboot persistence and actual atomic promotion remain open.

## September 28, 2026 — M37 native target and M38 audit batching

Actual z/VM CMS compiled GITREC cleanly and the standard M37 compact
regression passed every read-only gate. M35 NESTLINKS, M36 DEEPLINKS
and M37 DEPTHLINKS 2 are now target-proven on both original sealed
1,808-object generations, including older-slot recovery and
fail-closed invalid slots. Observed complete test runtime was
693.54 seconds CPU / 708.96 seconds elapsed.

M38 adds optional read-only `GITREC LINKBATCH`: one ordinary full
generation verification followed by one depth-two complete graph
check emits three success markers only after all links validate.
It replaces three separate positive full-audit invocations in the
standard compact GITRUN and preserves independent original audits,
all negative/recovery tests and all protected original files. Source
record and runner static checks have passed; independent complete
GitHub Actions and real CMS execution of M38 remain unconfirmed.
See `docs/NATIVE_REF.md` and the last section of `NOTES.md`.

## September 28 follow-on: M38/M39 host-CI-complete

M38 read-only `GITREC LINKBATCH` combines M35–M37
positive depth-two link authentication into one complete
GEN2 selection audit and one subtree traversal. M39 removes
redundant subtree read/hash/parse at positive recursion depth:
the recursive call fully authenticates each subtree once.
Blobs, terminal trees, all parent/child roots, bounded
limits, missing/wrong-type failure codes and no-partial-output
rules remain protected. All original GITREC commands continue
to exist. The standard one-page `GITRUN.EXEC` is M39
and retains two independent original full 1,808-object
generation audits, selector proof, negatives, fallback,
dual-invalid rejection, restoration and final STATE checks.

Complete strict native C89/integration/selector/index/REF
GitHub CI succeeded for M38 and M39, including the final
M39 runner and guard:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36482128273

M38/M39 are host-proven, **not yet actually CMS-tested**.
One real CMS compile and standard M39 GITRUN tests both;
see `docs/NATIVE_REF.md`. Original sealed generations,
selector pointers and captured PACK remain immutable.

## M39–M42 latest native milestones

M39 completed its actual CMS regression on September 28: two independent 1,808-object full-generation audits, verified batched nested links, fail-closed negatives, older-slot recovery, newer-slot restoration and protected originals. The complete run used 454.77 seconds CPU and 464.18 seconds elapsed.

Further host-tested work adds M40 atomic terminal-directory parsing for PATH/LSDIR, M41 LSDIRV to authenticate immediate directory references, and M42 LSDIRDEPTH to authenticate referenced local subtrees to caller-selected depth 0–4. Full native C89 integration, source-guard and staging/index/REF PACK Actions suite passed: https://github.com/mostangrymike/ibm-sandbox/actions/runs/36484134487 . M40–M42 require one combined actual CMS M42 test before target-proof claims. See docs/NATIVE_REF.md and NOTES.md.

## Latest: M42 native CMS and M43/M44 full host CI

On September 28 M42's actual CMS compile and complete compact gate passed both independent original 1,808-object generation audits, authentic historical `src` directory to depth one, all recovery/fail-closed cases and protected-file checks (522.41 CPU / 533.40 elapsed seconds). M40–M42 are target-proven.

M43 fixes the 256-tree-entry bound to count external Gitlinks without trying to dereference their external commits. M44 introduces iterative, bounded `GITREC CLOSURE`, which SHA-authenticates and validates all local tree/blob descendants of a commit and every parent root without the former depth-four ceiling, within a shared 1,024-tree-visit limit. Host synthetic regressions test deep missing/mis-typed objects, 256/257 external Gitlinks and exactly 1024/1025 visited-tree budget boundaries. Strict C89 complete native-stage Actions passed: https://github.com/mostangrymike/ibm-sandbox/actions/runs/36487140427 . M43/M44 are host-proven, not yet CMS-proven. The standard M44 `GITRUN.EXEC` batches one actual target gate. Consult `NOTES.md` and `docs/NATIVE_REF.md` for exact two-file upload and read-only CMS commands.

## M44 native proof; M45 complete directory closure

Actual z/VM CMS compiled and passed the entire M44 compact regression, including independent original 1,808-object audits, complete child/parent tree closure, recovery/fail-closed cases and final protected files (638.32 CPU, 652.08 elapsed seconds). M43 and M44 are target-proven.

M45 adds read-only `GITREC LSDIRFULL`, which authenticates every local tree/blob descendant beneath an explicitly requested commit-relative directory before revealing directory metadata or listing; traversal is iterative with the established 256 entries/tree and 1,024 tree visits bounds. All source and synthetic deep failure tests, including older fallback and both-invalid rejection, passed full native host CI: https://github.com/mostangrymike/ibm-sandbox/actions/runs/36489401717 . M45 has not yet run on actual CMS. The one standard M45 compact GITRUN tests the real historical `src` directory and preserves all original full-generation/protection checks. Only GITREC.C and GITRUN.EXEC need transferring; see `NOTES.md` and `docs/NATIVE_REF.md`.

## Current native proof and M46 follow-on

The September 28 actual z/VM CMS M45 run compiled `GITREC` cleanly and passed the complete standard `GITRUN M45` regression: both independent original 1,808-object audits, historic `src` full closure, full child/all-parent closure, negative cases, seq51 fallback, dual-invalid failure, seq52 restoration and protected-state checks. Full regression: 705.89 CPU / 721.23 elapsed seconds. M45 is real CMS target-proven.

M46 adds read-only `GITREC TREECLOSURE C0 C1 TREE_OID40` to validate complete local closure from a raw tree object ID and release a direct tree listing only after full closure. It reuses existing bounded iterative traversal, external Gitlink handling and full selected-generation validation. Host integration covers deep corruption and exact visit/entry limits. The one compact `GITRUN M46` adds the historical root tree by OID to every original M45 gate; it requires only `GITREC.C` and `GITRUN.EXEC` for the next CMS transfer. M46 must not be called actual target-proven until real CMS output confirms it.

## September 29: M46 target-proven; M47/M48 host-green

Actual native z/VM CMS compiled M46 without flagged statements and passed the entire one-page original-data regression: both independent 1,808-object audits, historic full commit/parent/directory/raw-tree closure, all expected negative tests, older fallback, dual-invalid fail-closed, restored newer generation and protected-file checks. CPU 775.91 / elapsed 792.93 sec. M46 is real CMS target-proven.

M47 adds PATHFULL, which validates an **entire commit-root snapshot** before disclosing any requested path metadata. M48 adds PATHFULLCAT, which additionally outputs lossless binary blob HEX only after the same full-root attestation. Host regression proves deep corrupt unrelated sibling fail-closed behavior, exact 256/257 Gitlink and 1024/1025 tree-visit limits, empty/binary/64-KiB blob fidelity, older-generation recovery, dual-invalid no-output and restored newer generation. Full strict C89 CI passed https://github.com/mostangrymike/ibm-sandbox/actions/runs/36576137300 . M47/M48 are fully host-proven, **not actual CMS-proven**. The current single compact `GITRUN.EXEC` is M48, and only two Mac transfers (`GITREC.C`, `GITRUN.EXEC`) plus one real CMS compile and GITRUN are needed; see `docs/CURRENT_STATE.md` for exact commands. The M48 target run supersedes the older M47 target gate and retains every previously protected original regression.

## M48 real CMS pass; M49 snapshot-wide directory listings

Real CMS compiled the M48 production `GITREC` with zero flagged statements and passed the full original-data compact regression: two independent 1,808-object generation audits, whole-root PATHFULL src metadata, whole-root PATHFULLCAT README blob bytes, all prior directory/root/tree closure checks, fail-closed/recovery/restoration and final protected files. Full CPU 958.09 / elapsed 979.38 sec. M47 and M48 are actual CMS target-proven.

M49 adds read-only `PATHFULLDIR`: authenticate the entire commit-root local tree/blob graph before returning the requested directory's metadata and listing, including rejecting a corrupt *unrelated* sibling. Synthetic production-C89 tests cover deep missing/wrong-typed siblings, missing/invalid path, invalid terminal type, fallback, both invalid and restoration, exact 1024/1025 tree visits and 257 Gitlink-entry failure. The full native-stage CI passed https://github.com/mostangrymike/ibm-sandbox/actions/runs/36580384415 and supplemental resource-boundary CI passed https://github.com/mostangrymike/ibm-sandbox/actions/runs/36580525841 . M49 is full host-CI-proven and awaiting real CMS validation. One standard compact M49 runner retains every prior original-data gate and tests historic src PATHFULLDIR; only GITREC.C and GITRUN.EXEC need transfer. See `docs/CURRENT_STATE.md` for exact next commands.

## M49 native success and M50 raw-tree relative paths

The September 29 actual CMS `GITRUN M49` fully passed the historic immutable original-data regression, including whole-snapshot src directory listing, all earlier root/directory/blob verification, original independent 1808-object audits, older recovery, dual-invalid fail-closed and final protected files. CPU 981.93 / elapsed 1003.66 sec; no flagged assembly statements. M49 is native CMS target-proven.

M50 adds read-only `TREEPATHCAT` and `TREEPATHDIR`: given a raw tree OID and a HEX path relative to it, first fully authenticate the selected immutable GEN2 and **all** local descendant tree/blob objects, then output lossless blob HEX or a complete directory listing. No commit is required. Host production-C89 regression proves empty/binary/64-KiB/nested data, deep sibling failures without partial output, 256/257 total entries including external Gitlinks, 1024/1025 tree visits, older fallback, both invalid and restored newest generation. Full native CI https://github.com/mostangrymike/ibm-sandbox/actions/runs/36584751834 and supplemental both-command recovery CI https://github.com/mostangrymike/ibm-sandbox/actions/runs/36584911315 passed. M50 is host-proven and awaits one actual standard CMS gate using only GITREC.C and GITRUN.EXEC; see `docs/CURRENT_STATE.md`. Protected original stages, selectors and PACK remain unchanged.

## M52 native target proof; M53–M54 faster full-protection regression

M52's one-process positive regression passed actual z/VM CMS on September 29 with 962.91 CPU/986.89 elapsed seconds against the immutable original 1808-object data, versus 1133.73 elapsed seconds for the immediately preceding M50 run on the rebooted host. M53 removed the redundant standalone selector audit because RUNBATCH already proves and reports newest seq52; full native-stage CI https://github.com/mostangrymike/ibm-sandbox/actions/runs/36625850247 passed. M54 also moves wrong-type-child RC8 and missing-child RC4 tests into the already selected batch, with exact expected-code markers required before aggregate success. It retains both independent original 1808-object full audits, all earlier positive features, invalid-depth RC4, older seq51 recovery, dual-invalid fail-closed, restored seq52 and final protected-file checks. Full M54 C89 native-stage CI https://github.com/mostangrymike/ibm-sandbox/actions/runs/36626167890 passed and merged; M54 real CMS performance and target proof remain to be measured. The standard current `GITRUN.EXEC` is M54. The current EC2/3270 setup has SSH forwarded terminal at Mac local 3271 and c3270 script port 3272; use `CMS_SCRIPT_PORT=3272` with the updated transfer scripts. See `docs/CURRENT_STATE.md` for exact current two-file next commands.

## M54 native pass and M55 scoped tree proof reuse

Actual z/VM CMS `GITRUN M54` passed all protected original 1808-object, positive, negative, recovery and restoration tests on 2026-09-29, CPU 900.08 / elapsed 923.83 sec. M55 memoizes at most two complete and successful immutable tree-root closures within a single fully verified RUNBATCH selection, retaining fresh path and terminal checks and independent standalone commands. Full strict C89 CI passed https://github.com/mostangrymike/ibm-sandbox/actions/runs/36628776152 . Supplemental corrupt/over-budget cache-isolation CI passed https://github.com/mostangrymike/ibm-sandbox/actions/runs/36628992018 . M55 is merged on main and awaits real CMS validation; preserve the two original full audits and all fail-closed tests. Next transfer only GITREC.C and GITRUN.EXEC, using CMS_SCRIPT_PORT=3272 for the current c3270 scripting socket. See docs/CURRENT_STATE.md for exact commands.

## M55 native success and M56 one-snapshot seek-index optimization

The real September 29 z/VM CMS M55 protected regression passed on the original 1808-object repository with CPU 619.93 / elapsed 635.48 seconds, compared with M54 923.83 seconds. M56 further reduces redundant work inside the one already fully verified read-only RUNBATCH by parsing its selected seek index once and reusing that exact 1808-entry in-memory snapshot for that batch only. Every standalone command still freshly reads its index and every object body is freshly reopened and hashed. Both separate complete original 1808-object audits, complete bounded root closures, current and fallback selector validation, expected negative RC4/8, dual-invalid fail closed, restoration and final protected-file checks remain mandatory. Full strict C89 CI passed https://github.com/mostangrymike/ibm-sandbox/actions/runs/36631835500 ; M56 is host-proven and awaits the real native CMS target test. Use the standard M56 GITRUN, transfer only GITREC.C and GITRUN.EXEC via current CMS_SCRIPT_PORT=3272 and refer to docs/CURRENT_STATE.md for the exact next steps.

## Restoring historical CMS test EXEC source

Older M3–M13 milestone-only test EXEC sources are preserved losslessly in `archive/M3-M5_EXEC.json`, `archive/M6-M9_EXEC.json` and `archive/M10-M13_EXEC.json` rather than occupying one tracked source file per test. This is *source packaging only*: working CMS programs, Git core sources, current M188/M206 behavior and target-proven modules are not changed. Git history also retains each original path. From the Mac checkout, run:

```sh
python3 scripts/restore-cms-exec.py M9PCONS.EXEC
# or restore all archived historical test EXECs:
python3 scripts/restore-cms-exec.py ALL
```

Restoration refuses to overwrite any pre-existing `src/NAME.EXEC`. To test on CMS after restoring a particular source, use the established `src`-directory upload script, e.g. `./cms-upload.sh M9PCONS.EXEC`; only then invoke the associated CMS test. The archives are not CMS files and should not be uploaded directly. Archive sources are checked for exact preservation, and restoration is exercised by GitHub CI. A successful GitHub host check does not replace a real CMS target test.


## Regenerate native tree performance wrappers

The ten historical read-only CMS wrapper sources `GITPH2.EXEC`,
`GITPH3.EXEC`, `GITPH5.EXEC`, `GITPH8.EXEC`, `GITPH9.EXEC`,
`GITPFAST.EXEC`, `GITPPROF.EXEC`, `GITPHX.EXEC`,
`GITPONCE.EXEC`, and `GITPSK.EXEC`
are now generated byte-for-byte by `scripts/restore-ph-wrappers.py`.
They are not maintained as separate tracked files. Existing native
MODULE names, CMS entry-point names, messages, and 80-column source
limits remain unchanged. Git history also preserves each original.

From the Mac repository root run:

```sh
python3 scripts/restore-ph-wrappers.py ALL
```

Or restore exactly one missing file:

```sh
python3 scripts/restore-ph-wrappers.py GITPH8.EXEC
```

The generator refuses to overwrite any existing output. From the
`src` directory, upload regenerated files using the established
`./cms-upload.sh GITPH8.EXEC` workflow. Do not upload the Python
generator itself to CMS. GitHub CI regenerates all ten before
running the original source and native host regression gates.


## Restore archived M9 PACK walker experiments

The legacy M9 K/L/M experimental PACK walker EXEC sources are preserved
byte-for-byte in `archive/M9_WALKERS.json`. The live `GITP9PWK.EXEC`
production wrapper remains tracked and unchanged. From the Mac checkout:

```sh
python3 scripts/restore-cms-exec.py GITP9KWK.EXEC
python3 scripts/restore-cms-exec.py GITP9LWK.EXEC
python3 scripts/restore-cms-exec.py GITP9MWK.EXEC
```

Restoration refuses to overwrite existing sources. The GitHub Actions
workflow restores all three historical entry points and verifies source
identity before running host regression checks; these are not live CMS
target revalidations. Only upload a restored wrapper when running its
specific historical CMS experiment.


## Restore historical M9–M12 transport helpers

Six milestone-only transport helper EXECs (`G10DFIX`, `GIT10BF`,
`GIT10PK`, `GIT10UP`, `GIT11HTP`, `GIT12CHK`) are preserved
byte-for-byte in `archive/M9-M12_TRANSPORT.json` rather than tracked
individually in `src/`. Restore one from the Mac repository root with
`python3 scripts/restore-cms-exec.py GIT10UP.EXEC`, then upload the
restored file through the existing CMS transfer script if required.

**Do not archive or delete `GIT9CTX.EXEC` from the working sources:**
`GITP9PWK.EXEC` still references that helper. The archive also retains a
backup copy of `GIT9CTX.EXEC`, but its active tracked source stays live.
GitHub Actions recreates the six absent helper sources and verifies all
seven archived entries exactly before running host regressions. These
repository operations do not modify CMS A or G disks.


## Preserved M6 protocol helper sources

`archive/M6_PROTOCOL.json` now preserves complete original sources for
`GITACK.EXEC`, `GITADV.EXEC`, and `GITZLIB.EXEC`. **These three files
remain tracked in `src/`** while their caller dependencies are audited.
CI checks exact archived-source parity and can restore missing copies.
An archive backup does not establish that a CMS helper is unused; do
not remove the live EXECs until their callers and target behavior are
verified. To restore an absent copy from the Mac project root, run
`python3 scripts/restore-cms-exec.py GITACK.EXEC`; this refuses to
overwrite existing files.

### Dependency-safe source cleanup

Before retiring any of the 159 tracked `src/` paths, run
`python3 scripts/restore-cms-exec.py LIVEDEPS` (read-only).
The CI workflow runs it alongside the independent archive `AUDIT`.
It scans same-repository source-token references, detects ambiguous CMS
source stems, and fails if protected runtime files or the known
`GITP9PWK -> GIT9CTX` source dependency disappear. This is a
**conservative inventory, not proof that files with no detected callers
are safe to remove**; dynamic REXX calls, target modules, external
operators, and CMS execution semantics require separate checks.
The first full host CI run with the audit passed:
[38587307751](https://github.com/mostangrymike/ibm-sandbox/actions/runs/38587307751)
(commit `b01e2aab7bf9aaaad5855ed1272004bc4e67854a`).

### Dependency-safe source cleanup

Before retiring any of the 159 tracked `src/` paths, run
`python3 scripts/restore-cms-exec.py LIVEDEPS` (read-only).
The CI workflow runs it alongside the independent archive `AUDIT`.
It scans same-repository source-token references, detects ambiguous CMS
source stems, and fails if protected runtime files or the known
`GITP9PWK -> GIT9CTX` source dependency disappear. This is a
**conservative inventory, not proof that files with no detected callers
are safe to remove**; dynamic REXX calls, target modules, external
operators, and CMS execution semantics require separate checks.
The first full host CI run with the audit passed:
[38587307751](https://github.com/mostangrymike/ibm-sandbox/actions/runs/38587307751)
(commit `b01e2aab7bf9aaaad5855ed1272004bc4e67854a`).

### M164–M170 documentation consolidation (2026-10-14)

The complete contents of the former `docs/M164_PRACTICAL_PORCELAIN.md`,
`docs/M179-M185_HISTORY.md`, and `docs/M167-M170_HISTORY.md` are retained
in `docs/M179-M185_HISTORY.md`, in milestone order M164–M170. The original
standalone document blobs remain recoverable from Git history. This reduces
the repository to **203 tracked files** (222 fewer than its 425-file baseline).
The merged document is included in the host workflow path filter.

### Consolidated native architecture records (2026-10-14)

The complete text of the previous native REF, stage, index, and recovery-gate
records is collected in `docs/NATIVE_REF.md`. The original generation,
indexed external-ref, and ref-resolution records are now collected in
`docs/GENERATION_RECOVERY.md`. Original document paths remain recoverable
from Git history. Links above now point to retained documents, rather than
removed paths. This is documentation-only; no production CMS behavior changed.
