# CMS A-disk obsolete-file cleanup (2026-10-08)

## Real target baseline

The operator successfully removed the failed partial M173NET STAGE A,
then individually removed GITREC, GITCWALK, and GITCIDX LISTING A.
The latest CMS QUERY DISK output was MNT191 A R/W, 175 cylinders,
4096 bytes per block, 295 files, 10361 blocks used and 21139 free.
No proof of A minidisk integrity or independent DASD backup has been
reported since the September 27 TRKDE 4 deallocation-map incident.
An actual unmodified backup/snapshot is the prudent prerequisite
for further intentional deletes. Do not ERASE an unverified file
system in bulk.

## Why there are three separate batches

The cleanup tool `src/ACLEAN.EXEC` is deliberately restricted to
**exact A-disk filenames** observed in the operator's LISTFILE
inventory. Its default is not to erase anything. `PLAN` is read
only; `APPLY` is explicitly destructive. It uses CMS STATE for
each item, skips absent files only on RC28, stops on unexpected
errors, and issues one exact-file ERASE at a time, stopping at the
first failed erase. It reports disk space after each APPLY batch.

1. `LISTINGS` — 20 remaining older compiler/assembler LISTING
   files. The three largest legacy listings have already been erased.
   The four current diagnostic listings GITPIMP, GITINFA,
   GITPCHK, GITPCENS are retained. Expected additional LISTING
   file reduction is 20 files, 489 blocks (~1.91 MiB) based
   on the operator's snapshot. All are generated outputs.

2. `EXPERIMENTS` — 26 generated artifacts: paired MODULE and
   TEXT files for CCTEST1, HELLO, GITCABI, GITCINF, GITCPARS,
   GITCPROB, GITC2, GIT12Q, M12ABEG, M12BOPN,
   M12TLS2, M12TLS3, M12TLS4. Their C or ASSEMBLE
   source remains on A, and most are additionally in GitHub.
   They are retired historical experiments, not active native
   generalized import modules. Approximate historical
   allocation: 229 blocks (~0.89 MiB). Their standalone
   MODULE invocations will cease to work until they are rebuilt.

3. `OLDTESTS` — 29 early M9–M13 disposable testing EXECs
   whose original sources are present in GitHub. They are not
   called by current GIT, GITVREF, GITWT, GITFETCH or GITPOST.
   GITTEST's older M13AAREF/M13ABREF requirements are
   explicitly *excluded*. Standalone past milestone test
   EXECs can be restored later from `src/` in GitHub.
   This is a separate opt-in because it retires callable
   historical test entry points rather than generated outputs.

If every manifest entry still exists and all three batches pass,
75 old files are removed, bringing the observed 295-file
inventory to approximately 220 files plus the new ACLEAN EXEC.
The exact disk-block changes must be measured on CMS; more
than the LISTFILE sum may be reclaimed through disk-directory
metadata, as seen in the previous listing cleanup.

## Protected and deliberately retained files

- GITFIX and M15NEW verified STAGE/INDEX/SEEK/GEN files;
  GITSEL0/GITSEL1/M15SL0/M15SL1 PTR selectors.
- GITPBUF PACK and M171NET PACK/META; other PACK input/fixtures.
- GITREF2 REPO and GITOBJ files; old DATA, diagnostic traces,
  and network payload fixtures unless explicitly archived.
- All C, ASSEMBLE, EXEC, and CMS compiler/toolchain source
  except the opt-in named early tests in OLDTESTS.
- All active MODULE/TEXT for GITCORE, GITSTRM, GITREC,
  GITSEL, GITCIDX, GITCWALK, GITCAPI, GITINFA,
  GITPCHK, GITPCENS, GITPIMP. The native bridge
  GITNDRV/GITNCALL/GITNHEX is also retained.
- M12ATLS ASSEMBLE A (historically involved in TRKDE 4),
  M12ATLS MODULE A, PROFILE EXEC/XEDIT and
  all disks other than MAINT A.

## Operator workflow

On the Mac, from `ibm-sandbox/src`:

    git pull
    ./cms-upload.sh ACLEAN.EXEC

On CMS, preview and then run only the approved batch:

    ACLEAN PLAN LISTINGS
    ACLEAN APPLY LISTINGS
    QUERY DISK

Check the output and free-block count before the next category.

    ACLEAN PLAN EXPERIMENTS
    ACLEAN APPLY EXPERIMENTS
    QUERY DISK

The final opt-in test cleanup:

    ACLEAN PLAN OLDTESTS
    ACLEAN APPLY OLDTESTS
    QUERY DISK

`PLAN` is the safest entry to run immediately; only `APPLY`
performs deletion. If any STATUS or ERASE fails, stop and investigate.
Do not run `GITRUN` or a generic wildcard cleanup as a shortcut.

To reconstruct a removed historical experiment, restore its
source or EXEC from the canonical GitHub repository, compile or
assemble as appropriate and link it normally. The retained
historical PACK and staged object generations are unchanged.

This cleanup reduces A-disk clutter but does **not** solve
M173's capacity problem: the new generalized live-PACK STAGE and
INDEX belong on a larger, separate persistent writable
minidisk, with the verified 2,171,129-byte input PACK retained on A.


## Follow-up A inventory after the 75-item cleanup

The operator reported CMS QUERY DISK: 221 A files, 9,620 blocks used,
21,880 blocks free, 31% utilized. This represents net 74 fewer files
and 741 additional blocks free since the 295-file baseline; a
newly installed ACLEAN EXEC accounts for the file-count difference.

The next operator inventory listed 26 ASSEMBLE files and many
remaining EXECs. These are **not** all expendable: handwritten
GITCAPI/GITINFA/GITNCALL/GITNDRV/GITNHEX/GITCORE/GITSTRM
and M12* diagnostic assembler inputs are sources rather than
compiler outputs; retain them. M12ATLS ASSEMBLE is specifically
excluded because its attempted removal previously triggered a
TRKDE 4 deallocation-map error.

The new optional `BUILDDECK` batch contains exactly nine
GCCCMS-generated intermediary ASSEMBLE files, each corresponding
to a retained original `.C` source in GitHub. Current production
MODULEs are untouched; the old experiment MODULEs were already
retired in the previous cleanup: GITCABI, GITCINF, GITCPARS, GITCPROB,
GITC2, GITREC, GITCIDX, GITCWALK, GITSEL.
Individual CMS LISTFILE allocations total **952 blocks**,
about 3.72 MiB. These files are not required to *run*
the existing native modules. When rebuilding any one of
them later, use `CMSCLNK NAME NAPI` or `CMSCLNK NAME PLAIN`
as appropriate; the compiler regenerates the ASSEMBLE.
Deleting a generated deck removes convenient direct
reassembly until recompilation. The target is a reduction
of nine more files (221 to roughly 212 after updating
ACLEAN itself), but count and blocks must be verified
through QUERY DISK rather than claimed in advance.

The existing source-backed M155-M173 checkers, GIT EXEC/GITVREF,
GITFETCH/GITPOST, GITWT, GITIMP, PROFILE, GITTEST,
native bridge EXECs, and old potentially unique diagnostics
are retained. Some orphan-looking M13* EXECs do not have
matching files in the current GitHub source tree and must not
be erased as though they were already backed up.

After preserving an independently verified DASD image/snapshot,
upload the updated `ACLEAN.EXEC` on CMS A and run:

    ACLEAN PLAN BUILDDECK
    ACLEAN APPLY BUILDDECK
    QUERY DISK

Do not include wildcard targets or run the new batch
without first inspecting PLAN. This only tidies A;
a distinct large persistent minidisk is still required
for the generalized live 7736-object stage.
 

## October 13, 2026: reuse the existing code and cleanup infrastructure

The A disk has been reported as approximately **342 files**; this
is a recent user observation, not an itemized current CMS LISTFILE
inventory. Do not assume which historical manifests have already
been applied. The disk was approximately 343 files in the most
recent M206 CMS run, and the snapshot / TRKDE 4 data-integrity
caution above still applies.

**New default development rule:** stop creating new version-numbered
native program filenames every milestone. Continue editing and
rebuilding the canonical files `GITP26M.C` and `GITC26.EXEC`
for later stratified reader improvements; likewise continue using
`GITBX9.ASSEMBLE`, `GITB9.EXEC`, `GITVO7M.C`, `GITCLN.EXEC`
and `ACLEAN.EXEC` where appropriate. Preserve target-proven
modules until replacement code has passed host CI, CMS build
and all required target regression gates. GitHub commits and
tags retain past source versions; never depend on old local
compiler output for rollback. New filenames require a genuinely
new standalone capability, not just the next milestone number.

M206 has **real-CMS 16-object target PASS** as of October 13,
2026; M206 32-object target CHECK/RUN is not yet proven.
Preserve `GITP26M MODULE A`, `GITC26 EXEC A`, the canonical
source on A, target-proven `GITBX9 MODULE A`,
`GITB9 EXEC A`, `GITVO7M MODULE A`,
`GITCLN EXEC A`, and the protected original G stage and
index. Do not edit or replace the current M206 binaries
until the separate 32-band target gate is complete.

### ACLEAN RECENTGEN: 20 exact generated intermediates

`ACLEAN.EXEC` was extended **in place** with a new
`RECENTGEN` manifest. It considers the generated
`ASSEMBLE`, `TEXT`, and `LISTING` files for precisely
these six source-backed C programs:

```text
GITRP6M GITVO7M GITP21M GITP24M GITP25M GITP26M
```

It also considers the generated `GITBX9 TEXT A` and
`GITBX9 LISTING A` from its assembler build. It
**does not erase `GITBX9 ASSEMBLE A`**, which is
hand-authored source.

The cleanup finds files only by full `filename
filetype A`, skipping absent files. It never uses
wildcards and never touches MODULE, EXEC, C, PACK,
STAGE, INDEX, SEEK, GEN, PTR, REPO, or any G-disk
file. On APPLY, for each *present* RECENTGEN target
it first requires that its `filename C A` source
(`GITBX9 ASSEMBLE A` for GITBX9) **and its current
filename MODULE A** exist; otherwise it stops without
erasing that file. Only then does it issue the
precisely addressed ERASE. The original A data and
the protected G repository are unaffected.

This batch is a **maximum of 20 candidates**, not a
claim that twenty such files are currently present
or that all twenty will be removed. The CMS
`PLAN` report establishes the actual count and the
post-APPLY disk count must be measured.

Run `ACLEAN PLAN RECENTGEN` first. The safest time
to APPLY is after a current DASD backup/snapshot
and after the current M206 32-band CHECK/RUN
has passed, or another deliberate safe checkpoint.
Do not run APPLY merely because the file count is
large. If there is any failure or ambiguity, keep
the files and report the complete console output.

### Operator commands and inventory

From Mac `ibm-sandbox/src` after the updated
existing ACLEAN source is merged to main:

```sh
git pull
./cms-upload.sh ACLEAN.EXEC
```

On CMS, the following are read-only:

```text
FILEDEF
QUERY DISK A
LISTFILE * * A (ALLOC
ACLEAN PLAN RECENTGEN
ACLEAN PLAN LISTINGS
ACLEAN PLAN EXPERIMENTS
ACLEAN PLAN OLDTESTS
ACLEAN PLAN BUILDDECK
```

The inventory should be captured **before** deleting
anything else, preferably copied or archived outside
the minidisk. Some old manifests may now report zero;
do not treat them as newly available savings. An
independent backup is recommended before applying.

Only with a checked plan, verified recoverability and
a separate intentional cleanup decision, apply the
specific selected batch:

```text
ACLEAN APPLY RECENTGEN
QUERY DISK A
FILEDEF
```

`ACLEAN PLAN` cannot modify anything; `ACLEAN APPLY`
will erase the exact matched files. Build intermediates
can be regenerated from the retained `.C` sources
using `CMSCLNK name PLAIN`. The handwritten GITBX9
assembly can be rebuilt with the installed macro and
text libraries, LOAD, and GENMOD as already validated.

For further reductions, classify the actual A
inventory by source-backed generated output,
obsolete-but-recoverable historical MODULE/EXEC,
unique diagnostics, and protected production/data.
Do not add an unreviewed sweeping MODULE or EXEC
manifest, especially while M206's 32-band test is
pending. Existing opt-in batches retain their
original semantics.

## Actual CMS A-disk cleanup PLAN results — October 13, 2026

The user ran the merged `ACLEAN.EXEC` on z/VM CMS.
Actual A-disk inventory headline:

```text
QUERY DISK A
MNT191 191 A R/W 175 3390 4096 342 files
13206 blocks used (42%), 18294 blocks free, 31500 total
```

Exact manifest results (all PLAN operations read-only):

| ACLEAN PLAN batch | Candidates found | Items considered |
|---|---:|---:|
| RECENTGEN | **20** | 20 |
| LISTINGS | 0 | 20 |
| EXPERIMENTS | 0 | 26 |
| OLDTESTS | 0 | 29 |
| BUILDDECK | 0 | 9 |

**All twenty RECENTGEN generated artifacts are present.**
They are the six sets of generated ASSEMBLE/TEXT/LISTING
files for GITRP6M, GITVO7M, GITP21M, GITP24M, GITP25M,
GITP26M, plus GITBX9 TEXT and LISTING. No source C,
handwritten ASSEMBLE, EXEC, MODULE, stage, index or
repository data is in that manifest. The prior four
cleanup batches are exhausted and should not be rerun
for savings.

At most 20 fewer A-disk directory entries are therefore
currently established: **342 → 322** if and only if
`ACLEAN APPLY RECENTGEN` succeeds completely and no
other files change. The actual block savings are unknown
until CMS measures them; do not claim a recovered block
count or completed deletion based on a PLAN.

IMPORTANT: CMS A experienced a historical TRKDE 4
deallocation-map problem. The safer sequence remains:
verify a usable independent DASD snapshot/backup,
review the full `LISTFILE * * A (ALLOC` inventory,
confirm canonical .C / handwritten source and working
MODULEs exist, then intentionally invoke
`ACLEAN APPLY RECENTGEN` for exact items only.
The utility independently refuses a present target
whose source or MODULE is missing, but it does not
provide a transactional rollback for a mid-batch failure.
After APPLY, check `QUERY DISK A`, `FILEDEF`, and
`ACLEAN PLAN RECENTGEN` again.

**No APPLY output or full current A inventory is in the
operator-provided transcript.** Do not mark anything
deleted yet; do not widen the deletion manifest
without examining that actual inventory.

M206 also passed its **32-region CHECK and full SHA RUN**
on the same date (0.70s CHECK, 2.06s full elapsed),
so it is now appropriate to evolve the *existing*
M206 source filenames after safe host/CMS checks, rather
than generating another numbered source file for every
milestone. Preserve GitHub rollback and active modules.


## Full A1 inventory review — legacy generated builds and SSL/TCP traces

The operator supplied the full A-disk `LISTFILE * * A (ALLOC`
inventory on October 13, 2026, after `QUERY DISK A` reported
342 files, 13,206 used blocks, 18,294 free, block size 4096.
The earlier `ACLEAN PLAN RECENTGEN` found all 20 original
intermediates, with no removals. No APPLY result has been
supplied for any batch.

The inventory exposes **two additional separately gated
cleanup groups**. Existing `ACLEAN.EXEC` and its existing
host safety test were updated in place (not replaced).

### PACKGEN — source-backed older standalone native build outputs

`ACLEAN PLAN PACKGEN` examines exactly 48 files: the generated
`ASSEMBLE`, `TEXT`, and `LISTING` for each of 16 programs:

```text
GITPCENS GITPCHK  GITPIMP  GITPIDX
GITPCAT  GITPTRE  GITPFST  GITPPRF
GITPONE  GITPHX   GITPHXM  GITPH5M
GITPH8M  GITPSKM  GITPRBM  GITRCNM
```

For these programs, the complete 48 target files are
visible in the supplied inventory, totaling **3,642
allocated 4K blocks** by per-file LISTFILE metadata.
This is a *nominal allocation tally*; it is not a
claim that CMS has freed those blocks. APPLY must first
verify each same-name `C A` source file and the
corresponding `MODULE A` exist, then erase exactly
the generated intermediate file. It does **not** target
modules, C sources, shared linkage libraries, handwritten
assembler, native G stage/index, verified generations
or source rollback in GitHub.

CAUTION: removing `TEXT` can require rebuilding it
from retained C source if a later custom link depends
on that intermediate. Review build workflows and
backup recoverability before applying this group;
PLAN alone is safe.

### NETTRACE — old SSL/TCP diagnostics, not SSLPOOL

`ACLEAN PLAN NETTRACE` examines exactly 11 existing
A-disk diagnostic output files:

```text
SSLDBG DATA      SSLDB2 DATA      SSLDB3 DATA
SSLDB4 DATA      SSLDB5 DATA      SSL1LOG DATA
SSL3TRC DATA     TCPTRACE DATA    TCPTRC2 DATA
TCPTRC3 DATA     M12TRACE TCPIP
```

Those 11 files are visible in the supplied inventory
and account for **106 allocated 4K blocks** in the
LISTFILE column. They contain diagnostic data rather
than executable source; they may be relevant to an
open TLS/TCP problem. Do not apply this group until
current SSL/TCP trace collection is stopped and the
logs have been archived externally or explicitly
deemed unneeded.

Explicitly **protected / excluded**:
`SSLPOOL $MSGLOG A`, `SSLPOOL PLANINFO A`,
`SSLTEST C A`, `SSLTEST2 C A`,
`TLSQTEST C A`, `TCPMAINT` / TCPIP
service records, and all other SSL-related files.
No filename-prefix wildcard cleanup is permitted.

### Combined potential, not completed deletions

| Manifest | Exact candidates in supplied A inventory | Allocated blocks |
|---|---:|---:|
| RECENTGEN | 20 | 637 |
| PACKGEN | 48 | 3,642 |
| NETTRACE | 11 | 106 |
| **Combined** | **79** | **4,385** |

If all 79 files are independently reviewed, backed up,
and successfully removed *with no new files created*,
the nominal directory count would decline from **342 to
263**. The allocation shown corresponds to approximately
17.1 MiB. The actual CMS used/free block change must
be measured after APPLY, and the historical TRKDE 4
A-disk integrity incident makes a verified disk backup
and conservative sequential deletion important. This
is a projection, **not a report of completed work**.

Many tempting large files **must not be cleaned based
on filename/size alone**: `GITFIX STAGE/INDEX/SEEK/GEN`,
`M15NEW STAGE/INDEX/SEEK/GEN`, selector pointers,
`M171NET PACK`, `GCCCMS VMARC`, `PROFILE EXEC/XEDIT`,
`VMARC MODULE`, repository GITOBJ/REPO objects and
other protected data. In particular `GCCCMS VMARC`
(821 blocks) is a toolchain/archive resource and is
not an automatically disposable cache.

### Safe operator plan (NO deletion)

After pulling and uploading the changed existing
`ACLEAN.EXEC`, run:

```text
FILEDEF
QUERY DISK A
ACLEAN PLAN RECENTGEN
ACLEAN PLAN PACKGEN
ACLEAN PLAN NETTRACE
```

These are all read-only. The historical LISTINGS,
EXPERIMENTS, OLDTESTS and BUILDDECK categories already
reported zero and do not need another run.

Only after the reviewed PLAN, an actual independent
backup/snapshot, and a deliberate decision to erase
each class, use exact opt-in APPLY commands *one batch
at a time*. For example, **do not combine the following
into an automatic single script**:

```text
ACLEAN APPLY RECENTGEN
QUERY DISK A
ACLEAN PLAN RECENTGEN
```

```text
ACLEAN APPLY PACKGEN
QUERY DISK A
ACLEAN PLAN PACKGEN
```

```text
ACLEAN APPLY NETTRACE
QUERY DISK A
ACLEAN PLAN NETTRACE
```

The last NETTRACE APPLY additionally requires the TLS/TCP
trace collection to be finished and those logs archived.
Never use wildcard ERASE. Every newly produced MODULE
and handwritten source must remain intact. Stop if
an APPLY command reports anything other than the
expected exact deletion count and clean return code.

### Policy for future milestones

Keep editing the proven canonical `GITP26M.C`,
`GITC26.EXEC`, and existing helper sources in place.
Host CI, GitHub commit history and target CMS validation
are the source rollback mechanism; do not litter A with
a new series of numbered binaries every milestone.
The original 32-object M206 real-CMS gate has passed
and remains the unmodified baseline.
