# M171–M176 historical milestone archive

Verbatim historical documentation; original paths remain in Git history. No source/test/module changes.

---

## Original docs/M171.md

# M171 generalized PACK persistence

M171 extends the target-proven M170 dynamic upload-pack POST with a safe,
separate persistence path for the newly fetched live PACK.

Public command:

```
GIT FETCH-STORE bridge port authority owner/repo oid cmsfn
```

`cmsfn` must be a new 1-8 character alphanumeric CMS filename. The command
refuses to run if either `cmsfn PACK A` or `cmsfn META A` already exists.
Only side-band channel 1 bytes are written. The writer batches 64-byte PACK
records as 128 hex characters and removes partial PACK/META files on any
transport, HTTP, pkt-line, side-band, or finalization failure.

On success, `cmsfn META A` records the wanted OID, persisted PACK byte count,
PACK version, and declared object count.

M171 adds standalone native `GITPCHK.C`. It streams hex records through
`FILEDEF PACKIN` without loading the complete PACK into memory. It validates
the PACK signature, version 2/3, nonzero declared object count, and Git PACK
SHA-1 trailer by retaining only SHA-1 state plus the final 20 bytes.

The real-CMS checker stores to `M171NET PACK A` / `M171NET META A`,
cross-checks POST counters against META, then cross-checks both against
`GITPCHK`. Successful files are intentionally retained for the next fetch
integration milestone. Any checker failure after storage erases the disposable
M171NET files.

The historical `GITPBUF PACK A` / `GITPMETA PACK A` fixture and fixed-size
`GITCWALK` path remain untouched. M171 does not enlarge or repurpose those
target-proven 340,027-byte / 1,808-object artifacts.


---

## Original docs/M172.md

# M172 generalized live PACK census

M172 consumes the retained, independently verified `M171NET PACK A`
without modifying it and proves that the current GitHub PACK is structurally
walkable object-by-object by native CMS code.

Public command:

```
GIT PACK-CENSUS
```

The caller FILEDEFs `PACKIN` to a verified PACK. The new native
`GITPCENS` module:

- accepts PACK v2/v3;
- bounds the full PACK to 16 MiB and the declared object count to 100,000;
- parses every ordinary, OFS_DELTA, and REF_DELTA entry header;
- validates OFS base-distance framing and REF base-id length;
- inflates each zlib member through the existing target-proven
  `GITCAPI/GITINFA` native inflater;
- requires inflated representation length to equal the PACK entry size;
- advances by the inflater's exact consumed-byte count;
- requires the final object boundary to equal exactly `PACK bytes - 20`.

M172 deliberately does not reconstruct deltas, compute object OIDs, stage
objects, build indexes, alter selectors, or write any persistent file.
It is the structural boundary between M171's arbitrary-size PACK persistence
and a later disk-backed generalized object importer.

The real-CMS checker reuses retained `M171NET PACK A` and
`M171NET META A`. It first reruns streaming `GITPCHK`, then runs
`GIT PACK-CENSUS` through the same `PACKIN`. Bytes, version, and object
count must agree between META, GITPCHK, and GITPCENS. The census must also
satisfy:

```
ordinary + ofs_delta + ref_delta = declared_objects
```

The historical `GITPBUF PACK A`, GITFIX, M15NEW, selector slots, staged
objects, indexes, and manifests remain untouched.


## Real CMS target result — 2026-10-08

M172 is real CMS target-proven against the retained M171 fetch. Native
`GITPCENS` completed RC0 with:

```
CENSUS PACK BYTES 2171129 VERSION 2 OBJECTS 7736
CENSUS ORDINARY 2432 OFS 5304 REF 0
CENSUS MAX INFLATED 393767 MAX COMPRESSED 122378
M172 PACK CENSUS PASS
M172 CENSUS CROSSCHECK PASS
M172 RETAINED PACK UNCHANGED M171NET PACK A
M172 GENERALIZED PACK CENSUS TARGET GATE PASS
```

The run took 29.26 CPU / 29.47 elapsed seconds. The retained PACK and META
remained unchanged. The zero REF_DELTA count permits the next isolated
integration milestone to reconstruct the complete current live PACK using a
fail-closed OFS-only importer without changing the sealed 1,808-object path.


---

## Original docs/M173.md

# M173 generalized OFS PACK import

M172 proved the retained live GitHub PACK is structurally walkable on real CMS:

- 2,171,129 PACK bytes;
- version 2;
- 7,736 objects;
- 2,432 ordinary objects;
- 5,304 OFS_DELTA objects;
- **0 REF_DELTA objects**;
- maximum inflated packed representation 393,767 bytes;
- maximum compressed member 122,378 bytes.

M173 uses those proven facts to cross the next integration boundary without
changing the sealed 1,808-object GITCWALK/GITFIX/M15NEW generation.

## Native importer

`GITPIMP` is a new isolated C89 module. Public `GIT PACK-IMPORT`
routes to `GITPIMP IMPORT`.

It accepts a caller-FILEDEF'd verified `PACKIN` and writes a caller-FILEDEF'd
`OBJOUT` in the existing CMS text-stage object format:

```
OBJ <number> <type> <size> <40-hex-OID>
<body hex in records of at most 32 decoded bytes>
```

The importer independently validates PACK signature, version, declared object
count, and trailer SHA-1. Bounds are explicit: PACK <= 16 MiB, at most 100,000
objects, and any one packed representation or reconstructed object <= 16 MiB.

M173 deliberately rejects REF_DELTA. That is fail-closed, not a hidden
limitation of the live gate: M172 independently proved the retained live PACK
contains zero REF deltas.

## Two-pass OFS dependency model

The first pass parses every entry, inflates every packed representation, records
exact zlib consumption, resolves each OFS base by PACK position, and counts how
many future objects depend on every base.

The second pass reinflates and reconstructs objects. A reconstructed base is
retained only while its precomputed future dependency count is nonzero and is
freed immediately after its last dependent has been reconstructed. Resident
reconstructed-object data is capped at 64 MiB. This avoids the old fixed
1,808-object arrays and avoids retaining all 7,736 reconstructed objects
indefinitely.

Every reconstructed object receives a canonical Git SHA-1 using explicit ASCII
object headers. The completed stage is closed before the independent readback
gate.

`GITPIMP VERIFY <count>` then rereads only `STGIN`, parses every staged
record, recomputes every canonical Git OID, requires exact object count, and
rejects trailing records.

## M173 CMS gate — current isolated data-disk contract

The checker `M173CHK G` reuses `M171NET PACK A` and
`M171NET META A` read-only. The filemode is a required argument, never A;
G is the planned separately provisioned permanent CMS data disk. The
checker first requires one accessed R/W 4096-byte-block CMS disk with at
least **180,000 free blocks**, and checks that `M173NET STAGE G` is absent
(STATE RC 28). It then reruns `GITPCHK`, binds PACKIN and OBJOUT under
the checker's exclusive FILEDEF ownership, directly executes
`GITPIMP IMPORT CHECKED`, cross-checks import counters against META,
and independently reopens and verifies the stage. It never overwrites an
existing stage, and **retains any failed output for diagnosis**: no ERASE
and no automatic retry while a partial stage exists. The success marker
is `M173 GENERALIZED OFS PACK IMPORT TARGET GATE PASS`.

**M173 is NOT target-proven.** Earlier CMS attempts on A failed and
one suffered system abend 001. The replacement isolated-disk checker is
host-tested but must not be run until the dedicated G disk has passed
the disk and backup gates documented in
`M173_PERSISTENT_DISK_RUNBOOK.md` and
`M173_EBS_RECOVERY_CHECKLIST.md`.

The historical `GITPBUF PACK A`, `GITFIX`, `M15NEW`, selectors, indexes,
and manifests are untouched.

Host coverage compiles the production source as strict C89, reconstructs
`abc -> abcd -> abcde` through chained OFS deltas, verifies the canonical
object IDs, rereads and rehashes the stage, proves a 70,000-byte object above the old
65,536-byte ceiling, proves existing-output non-overwrite, rejects REF_DELTA,
and rejects a corrupted PACK SHA-1.

## Historical CMS attempt: output-open correction (2026-10-08)

GITPIMP compiled in NAPI mode and the retained 7,736-object PACK passed
GITPCHK authentication and all M173 native prepass boundaries, ending at
offset 2,171,109. The importer then reported IMPORT OUTPUT EXISTS even though
the checker had already confirmed M173NET STAGE A was absent. No stage survived
the failure; the checker returned RC 8. This is **not** an import pass.

Root cause: fopen("dd:OBJOUT","r") on the CMS FILEDEF is not a reliable
physical-file existence predicate. The public named-output form now uses
CMS STATE on the concrete filename **before** it defines OBJOUT, fails closed
unless STATE reports the file absent (RC 28), and invokes the native
IMPORT CHECKED mode. Direct unqualified GITPIMP IMPORT retains its original
best-effort read-probe for host compatibility; only the STATE-guarded
public path is intended for production CMS output.

The checker invokes GIT PACK-IMPORT M173NET and independently rechecks the
stage after creation. This correction was host-tested in native-stage
Actions run 1327 (SUCCESS), along with the M174 analogous change.

Next real CMS gate: update only GIT.EXEC, GITPIMP.C and M173CHK.EXEC,
compile CMSCLNK GITPIMP NAPI, and rerun M173CHK. Preserve M171NET PACK/META
and historical protected generations.

## Historical CMS retry: abend 001 and FILEDEF ownership (2026-10-08)

The first CMS import attempt validated the 7,736-object prepass but failed
with IMPORT OUTPUT EXISTS: checking fopen("dd:OBJOUT","r") on the active
FILEDEF was not a valid test that M173NET STAGE A existed. The first
repair added the native IMPORT CHECKED mode and a public GIT
PACK-IMPORT M173NET wrapper. During the next real CMS run, GITPCHK
authenticated the live PACK but execution abended DMSABE148T 001.

IBM describes 001 for module DMSSTP as loss of the active FILEDEF FCB
pointer, and warns that FILEDEF clearing during an active operation may
cause it. The M173 checker still had an OBJOUT FILEDEF in scope when it
invoked the public GIT wrapper. That wrapper set its own OBJOUT FILEDEF
and then cleared it inside the active PIPE command. This overlapping
ownership is the leading diagnosis; the abend location itself has not
been traced to establish a definitive source-code instruction.

The isolated checker now keeps sole ownership of OBJOUT: it confirms
STATE M173NET STAGE A returns RC28 (not found), binds the output,
invokes PIPE CMS GITPIMP IMPORT CHECKED | STEM q. directly, then clears
the same FILEDEF only after the native PIPE returns. PACKIN stays
unchanged. No nested REXX dispatcher owns or clears the FCB during
import. The analogous M174 index checker was corrected ahead of CMS
testing. Host checks assert the single-owner command paths.

The aborted second run does not establish whether a partial M173NET
STAGE A exists. The next real CMS gate is to upload **only**
M173CHK.EXEC (plus any locally stale prerequisite files), then run
M173CHK. If its STATE preflight reports that M173NET STAGE A exists,
do not blindly delete it; inspect the disposable output first.
No repeat M171 fetch, M172 census, or GITPIMP recompile is required
for this checker-only change.


---

## Original docs/M174.md

# M174 generalized stage index

M173 produces a generalized, independently verified CMS text stage from the
retained live PACK. M174 adds a separate generalized index without modifying
the historical `GITCIDX`, `GITFIX`, `M15NEW`, selector, or generation formats.

## Native index

`GITPIDX` is an isolated C89 module with four commands:

```
GITPIDX BUILD
GITPIDX CHECK
GITPIDX AUDIT
GITPIDX GET <40-hex-oid>
```

Public `GIT PACK-INDEX` routes to `GITPIDX BUILD`.

`BUILD` reads caller-FILEDEF'd `STGIN`, requires sequential object numbers,
validates every staged body, and independently recomputes every canonical Git
OID before indexing it. It supports up to 100,000 stage objects and 16 MiB per
object. It records the `ftell()` cookie at each object header, sorts by OID,
collapses byte-identical duplicate OIDs to the earliest object number, rejects
any duplicate type/size conflict, and writes caller-FILEDEF'd `IDXOUT`.

The index is self-framing:

```
PIDX1 <total> <unique>
OID <oid> <object-number> <type> <size> <stage-cookie>
...
PEND1 <total> <unique>
```

An already-existing `IDXOUT` is not overwritten.

`CHECK` validates a reopened `IDXIN`, including total/unique bounds, strict OID
sort order, object metadata, nonnegative seek cookies, trailer counts, and no
trailing records.

`AUDIT` independently reopens both `IDXIN` and `STGIN`, sequentially rehashes
all staged objects, proves each object is covered by the sorted index, and
checks that each unique index entry's saved seek cookie names its earliest
staged occurrence.

`GET` performs a bounded binary OID lookup, seeks directly into `STGIN`, and
rehashes the selected object before returning its metadata.

## M174 target gate — current isolated data-disk contract

`M174CHK G` requires retained `M173NET STAGE G`, refuses an existing
`M174NET INDEX G` (STATE must return RC 28), and requires an accessed,
R/W 4096-byte-block data disk with at least **4,096 free blocks**.
It reads the wanted/main OID and total object count from
`M171NET META A` **without modifying A**, then:

1. builds `M174NET INDEX G` with exclusive checker-owned IDXOUT
   FILEDEF and direct `GITPIDX BUILD CHECKED`;
2. cross-checks total objects against the retained PACK META;
3. reopens and checks the completed index;
4. audits every staged object against the retained M173 stage;
5. directly looks up the original fetched main commit OID and requires type 1.

The successful index is retained for the next generalized object-access
milestone. Any failed index is **retained for diagnosis**; the checker
does not ERASE it or overwrite a previous index. M174 requires a real
CMS PASS for M173 first, and is not yet target-proven.

Host coverage includes duplicate OID collapse, strict index/trailer validation,
direct GET with independent rehash, full-stage corruption detection,
existing-index non-overwrite, and a 70,000-byte object above the old
65,536-byte ceiling.

## Historical CMS output guard following M173 prepass failure

M173 exposed that a CMS FILEDEF of a nonexistent DISK output can be opened
for input by C without proving the actual CMS file exists. M174 BUILD used
the same invalid fopen("dd:IDXOUT","r") existence shortcut. It now has
BUILD CHECKED for callers that have completed a concrete CMS STATE
nonexistence check. The earlier public GIT PACK-INDEX M174NET form checked
M174NET INDEX A with STATE before binding IDXOUT, rejected unexpected
STATE return codes and existing files, then invoked BUILD CHECKED.
This A-disk description is historical, not the present target workflow.

The isolated M174 checker retains its own preflight and invokes the
native index module directly, with no nested wrapper controlling IDXOUT.
It does not modify an existing M173 stage, GITFIX, M15NEW, selector or
manifest. M174 requires real CMS M173 import/readback PASS first.

## Preventive M174 FILEDEF ownership correction

M173 exposed a CMS system abend 001 with nested output FILEDEF
management inside PIPE CMS GIT. The isolated M174 checker retains
exclusive IDXOUT FILEDEF ownership while running
PIPE CMS GITPIDX BUILD CHECKED | STEM b. It does not route the
internal test through a public GIT wrapper that might redefine and
clear the active DD name. Its preflight requires CMS STATE on the
M174NET INDEX G destination to report RC28 before any output open.
M174 still awaits the successful M173 retained-stage gate.


---

## Original docs/M175.md

# M175 verified generalized object access

M173 reconstructs the retained live PACK into an independently verified stage,
and M174 adds a fully audited OID index with seek cookies. M175 turns those
artifacts into authenticated random-access Git objects without changing the
sealed 1,808-object generation.

## GITPCAT

The new isolated C89 module `GITPCAT` consumes caller-FILEDEF'd `IDXIN` and
`STGIN`:

```
GITPCAT INFO <40-hex-oid>
GITPCAT CAT  <40-hex-oid>
```

`INFO` and `CAT` first validate the complete PIDX1/PEND1 index framing and
strict OID order, locate the requested OID, seek to the saved stage cookie,
reread the exact staged header/body, and independently recompute its canonical
Git SHA-1. No object is returned unless this verification succeeds.

`INFO` emits only bounded metadata. `CAT` additionally emits the verified body
as `PACKOBJ HEX` records containing at most 32 decoded bytes each. This keeps
the CMS line width below 80 and avoids putting arbitrary object bodies into the
M175 REXX checker.

For commit objects, GITPCAT parses raw Git bytes using explicit ASCII byte
constants, never native C string bytes. It emits the verified root tree OID,
each parent OID, and the parent count before optional body output.

Public `GIT PACK-CAT <oid>` routes to `GITPCAT CAT <oid>`.

## M175 target gate — current isolated data-disk contract

`M175CHK G` binds the retained `M173NET STAGE G` and
`M174NET INDEX G`, reads the wanted/current-main OID from
`M171NET META A` without modifying A, and uses bounded
`GITPCAT INFO` calls to prove:

1. the fetched main OID is an independently rehashed commit;
2. its raw Git commit bytes yield a syntactically valid tree OID;
3. that root tree is present, indexed, seekable, rehashed, and type TREE;
4. every immediate parent is present, indexed, seekable, rehashed, and type
   COMMIT.

The checker limits immediate parents to 64 and never captures object body data
in a REXX stem. It writes no persistent files. It remains unproven on real
CMS pending successful M173 and M174 target gates.

Host coverage builds a PIDX1 index through the production M174 code, reads a
synthetic child commit with an actual parent and empty-tree OID, proves INFO has
no body output, proves CAT returns the exact body, validates parent/root lookup,
tests a 70,000-byte blob, and rejects corruption of the selected staged body.


---

## Original docs/M176.md

# M176 verified live root-tree closure

M175 proves authenticated random access to the fetched main commit, its root
tree, and immediate parents. M176 follows the root tree recursively and verifies
the complete current filesystem object graph through the generalized M173/M174
stage and index.

## GITPTRE

The isolated C89 module `GITPTRE WALK <tree-oid>` validates the complete
PIDX1 index, requires the root OID to name a TREE, and recursively walks raw Git
tree bytes. Every reachable local TREE and BLOB is sought through the saved
M174 stage cookie and independently rehashed before use.

Raw tree parsing uses numeric ASCII byte values. Supported Git modes are:

- 40000: subtree, which must resolve to a local TREE;
- 100644 and 100755: file blobs;
- 120000: symbolic-link blob;
- 160000: gitlink, counted as an external leaf and intentionally not required
  to exist in this repository's object index.

All other modes fail closed. Tree entry names must be nonempty, NUL terminated,
and contain no slash.

Each indexed local OID is verified at most once. The walker detects traversal
cycles, caps depth at 256, caps each object at 16 MiB through the shared format,
and caps simultaneously resident verified bodies at 64 MiB. It reports tree,
blob, gitlink, entry, verified-object, maximum-object, and peak-resident counts.

Public `GIT PACK-TREE <tree-oid>` routes to this walker.

## M176 target gate — current isolated data-disk contract

`M176CHK G` binds `M173NET STAGE G` and `M174NET INDEX G`,
retrieves the retained M171 wanted/main commit through bounded
`GITPCAT INFO` (META remains on A, read-only), extracts its
verified root tree OID, and runs the complete recursive closure walker.

The checker requires the root to match the commit, at least one tree, verified
objects to equal trees plus blobs, sufficient tree entries to cover all unique
reachable local objects plus gitlinks, and the index total to equal the original
retained PACK object count. It writes no persistent files. It is not yet
real-CMS-proven; successful M173–M175 target gates are prerequisites.

Host coverage proves nested trees, regular blobs, an executable-compatible mode
path, a symlink blob, a 70,000-byte blob, an external gitlink, full closure
counts, selected-body corruption rejection, and a structurally valid index whose
root tree references a missing local child.

