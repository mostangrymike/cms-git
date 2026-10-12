# M206 — Stratified 16-/32-band SHA verification on z/VM CMS

## October 12, 2026 — M205 real target PASS (8 indexed objects)

Actual z/VM 6.3 CMS results:

```text
CMSCLNK GITP25M PLAIN
ASSEMBLER (XF) DONE
NO STATEMENTS FLAGGED IN THIS ASSEMBLY
CMSCLNK: built GITP25M MODULE mode PLAIN
GITC25 G CHECK 64 8
M205 STRATIFIED INDEX PLANS PASS 8
M205 SAMPLE CHECK NO SCRATCH PASS 8
Ready; T=0.63/0.65 13:58:08
GITC25 G RUN 64 8
M205 FULL SHA VERIFIED 1 5
M205 SCRATCH CLEAN VERIFIED 1 5
M205 FULL SHA VERIFIED 2 969
M205 SCRATCH CLEAN VERIFIED 2 969
M205 FULL SHA VERIFIED 3 1935
M205 SCRATCH CLEAN VERIFIED 3 1935
M205 FULL SHA VERIFIED 4 2902
M205 SCRATCH CLEAN VERIFIED 4 2902
M205 FULL SHA VERIFIED 5 3869
M205 SCRATCH CLEAN VERIFIED 5 3869
M205 FULL SHA VERIFIED 6 4836
M205 SCRATCH CLEAN VERIFIED 6 4836
M205 FULL SHA VERIFIED 7 5803
M205 SCRATCH CLEAN VERIFIED 7 5803
M205 FULL SHA VERIFIED 8 6835
M205 SCRATCH CLEAN VERIFIED 8 6835
M205 STRATIFIED FULL SHA CLEAN PASS 8
Ready; T=0.88/1.04 13:59:29
```

The CHECK-only eight-object plan was verified in 0.65
seconds elapsed; the complete RUN (including one full
PIDX1 scan, eight native FSREADs, eight complete
independent Git SHA-1 checks, and eight disposable A1
scratch cleanups) completed in **1.04 seconds elapsed**.

The real PIDX1 plans and authenticated SHA/OIDs were:

| Band | Obj | Type | Bytes | Header CMS record | Bodies | Verified OID |
|---|---:|---|---:|---:|---:|---|
| 1 | 5 | commit | 285 | 13693 | 9 | 00577289AC473F405FB510795F6119A9B5A9845E |
| 2 | 969 | blob | 1959 | 461624 | 62 | 4A676C837DC348799DCE22FC177B4FC886E5953C |
| 3 | 1935 | commit | 259 | 923773 | 9 | 7BA8CDB666B6087E3733840AD979B788C5F37552 |
| 4 | 2902 | commit | 301 | 1324294 | 10 | C2AE5C4E8976C6961B0FE37172D773A22B715808 |
| 5 | 3869 | blob | 1155 | 1969394 | 37 | 06DCD89E780A4B7463945802CF1E8299AAD21676 |
| 6 | 4836 | blob | 1339 | 2731825 | 42 | 772BC3543AA43A7105E77DC93723C4946EF813FF |
| 7 | 5803 | tree | 807 | 2886646 | 26 | 0DF713FD715C955A3BA9DF94E376C1BF45BBE7EF |
| 8 | 6835 | blob | 1938 | 3104693 | 61 | 1843ECBD12CFDAA23836D14B3E0913DB094B0A7E |

**M205 is REAL CMS TARGET PASS for eight stratified objects:**
three commits, four blobs, one tree; **8,043 decoded bytes**
independently authenticated through M197. All stage reads
used the original protected `M173NET STAGE G1` and the
index `M174NET INDEX G1` read-only; scratch files were
created only as NEW A files and cleared only after SHA PASS.
All eight internal STATE checks confirmed scratch removal.
The pasted console output is interleaved around terminal
paging, but contains all eight M197 SHA passes and the
terminal M205 PASS. **No separate final FILEDEF result**
was shown. The eight-object 1.04s timing is not a comparable
full-tree result against M188's 208.27s/280 objects.

## M206 — increase bounded sampled coverage

M205's reader and wrapper are unchanged. New isolated
`src/GITP26M.C` and `src/GITC26.EXEC` expand the
number of deterministic nonoverlapping ordinal bands
from 2..8 to **2..32**, while preserving:

- One complete 7,736-object PIDX1 validation per batch,
  including 3,864,799 stage-record reconciliation.
- One first eligible 1..2048-byte object per band with
  1..64 body records. All bands must qualify before any
  `P201` success plans appear; empty bands fail closed.
- Exact ordinal-band, type, size, length/count and
  expected 40-hex OID checks in the CMS REXX wrapper.
- CHECK-only operation without creating scratch.
- Independent full M199 native FSREAD and M197 Git
  canonical SHA-1 for every selected object.
- Exact, already target-proven `GITCLN SCRATCH` cleanup
  only **after** the complete object SHA passes.
- Fail-closed stop and preservation of any failed/partial
  scratch, with no modification of the original G files
  or previously target-proven native modules.

The 32 bands divide 7,736 original object ordinals into
groups of approximately 241–242 entries, covering the
entire index. This is a bounded *sample*, not a complete
authenticated reachability walk.

Host test `tests/test-m206-stratified-32.py` compiles
the planner, index generator and SHA verifier with
strict ISO C89 flags. It creates 7,736 unique synthetic
objects, validates 2/3/8/16/32 indexed band selections
and independent full Git SHA-1s, checks model-record
geometry and original file immutability, and tests
an all-ineligible 32-band region that must produce
**zero P201 success lines**. No host test proves
IBM CMS PIPE or scratch cleanup behavior.

**M206 is HOST-ONLY until its own real CMS gates pass.**

## M206 real CMS target instructions after host CI / merge

Mac, from `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITP26M.C GITC26.EXEC
```

CMS MAINT preflight:

```text
FILEDEF
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
STATE GITR199 DATA A
STATE GITVRAW DATA A
CMSCLNK GITP26M PLAIN
STATE GITP26M MODULE A
```

Do not run a batch if either scratch file is present;
never replace one. Original G has 4K blocks and its
stage/index must be readable. Compile only the new
module, requiring the actual `NO STATEMENTS FLAGGED`
result. Older working modules and EXECs remain as-is.

Begin with a 16-band CHECK-only gate:

```text
GITC26 G CHECK 64 16
FILEDEF
STATE GITR199 DATA A
```

Require 16 `M206 BAND OBJECT VERIFIED` lines from
distinct bands, 16 expected 40-hex OIDs, and:

```text
M206 STRATIFIED INDEX PLANS PASS 16
M206 SAMPLE CHECK NO SCRATCH PASS 16
```

CHECK must not create scratch. Only on full CHECK PASS:

```text
GITC26 G RUN 64 16
FILEDEF
STATE GITR199 DATA A
```

Every selected object requires its own native M199
FSREAD and canonical M197 SHA1 PASS, plus exact
scratch cleanup confirmation. Terminal:

```text
M206 STRATIFIED FULL SHA CLEAN PASS 16
```

After this **separate actual target PASS**, 32 bands
may be checked and run using the same new module:

```text
GITC26 G CHECK 64 32
FILEDEF
STATE GITR199 DATA A
GITC26 G RUN 64 32
FILEDEF
STATE GITR199 DATA A
```

Never run the 32-band RUN if CHECK fails, or if scratch
is present. If screen paging interleaves text, rely on
complete object SHA, cleanup and terminal PASS markers.
Preserve the complete console and CPU/elapsed results.
No automatic rerun or deletion after a failed hash.

## Beyond M206

The next distinct capability after sampled-object
verification is authenticated object selection based
on Git *reachability* and expanding bounded object
sizes. Those are not proven by sampling alone.
M188's protected 280-object authenticated closure
baseline remains 205.04s CPU / 208.27s elapsed.
Do not reimport/reindex, write or format protected
GIT600 stage/index, write-link overlapping PMAINT
0141, or rerun M190's 272-seek experiment.
