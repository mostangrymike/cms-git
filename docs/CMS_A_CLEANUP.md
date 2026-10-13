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
