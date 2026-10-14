# M164–M170 milestone history and practical porcelain

## M164 (original docs/M164_PRACTICAL_PORCELAIN.md)

# M164 practical CMS worktree porcelain

M164 is the first practical write-side porcelain milestone after the
read-only/history series.

It adds these public commands:

```text
GIT IMPORT-OBJECT <oid>
GIT CHECKOUT-FILE <ref> <git-path> <cms-fn> <cms-ft> [fm]
GIT STATUS
GIT ADD <git-path>
```

It also adds internal exact-workfile primitives:

```text
GIT HASH-WORKFILE <fn> <ft> <fm> <final-lf-0-or-1>
GIT WRITE-WORKFILE <fn> <ft> <fm> <final-lf-0-or-1>
```

## Verified native-to-loose import

`GIT IMPORT-OBJECT` binds the existing dual selected generations and runs
the target-proven `GITREC CATHEX` path. The selected object is fully
GENCHECK-verified and independently rehashed before its complete body is
emitted. Only COMMIT/TREE/BLOB objects are currently accepted into the loose
`GITOBJ` store. The newly written loose object is then verified again by
`GIT VERIFY-OBJECT`.

The sealed GITFIX/M15NEW generations are never modified.

## CMS worktree model

M164 uses `GITWORK REPO A` as a small persistent worktree index. Each entry
records:
- exact Git path as ASCII hex;
- CMS filename/filetype/filemode;
- whether the Git blob ends with a final LF;
- checkout/base blob OID;
- staged blob OID.

The first implementation deliberately limits mapped paths to 30 ASCII bytes.
It is a safe initial bridge for the current flat CMS-compatible `src/`
subtree and can be extended later without changing the object model.

`CHECKOUT-FILE`:
- resolves HEAD/branch through verified `GITREF2 REPO A`;
- invokes `GITREC PATHFULLCAT` directly;
- requires complete commit-root closure verification;
- accepts text bytes only in M164;
- rejects lines longer than CMS LRECL 80;
- refuses to overwrite any existing CMS file;
- writes a fixed-record CMS workfile;
- immediately re-hashes the CMS workfile and requires the original Git blob
  OID before recording the mapping.

`STATUS` independently hashes each mapped CMS file and compares worktree,
stage, and base OIDs. It reports CLEAN, MODIFIED, STAGED, or
STAGED+MODIFIED.

`ADD` writes the exact current CMS text representation as a loose Git blob,
updates only the staged OID in GITWORK, and leaves the base OID unchanged.

CMS fixed-record padding is removed only at the record tail; leading
indentation is preserved. The final-LF bit preserves normal Git text-file
round trips.

## Disposable real-CMS gate

`M164CHK` is self-cleaning and refuses to start unless both
`M164TST DATA A` and `GITWORK REPO A` are absent.

It performs:
1. authenticated checkout of `src/GITVREF.EXEC` at HEAD to disposable
   `M164TST DATA A`;
2. initial STATUS and base=stage map verification;
3. replacement of the disposable file with one test record;
4. independent modified workfile hash;
5. STATUS showing the modified state;
6. `GIT ADD src/GITVREF.EXEC`;
7. staged OID verification and STATUS;
8. `GIT VERIFY-OBJECT` of the new loose blob;
9. erasure of only the disposable CMS file, worktree map, and newly-created
   loose object.

The protected GITFIX/M15NEW generations and selector files are read-only
throughout.

## Host proof

GitHub Actions native-stage run `37638057399` completed successfully on
M164 code head `c3bcd5fb577a2ab317b5ed31b73cb2bc7c8200b3`.
The run included all earlier M156-M163 checks, the M164 independent worktree
model, native selector tests, full CATHEX/tree recovery, and native
PACK/index tests.

The disposable gate also verifies native-to-loose IMPORT-OBJECT and removes\nthat imported loose object during cleanup.\n\nThe remaining acceptance boundary is real CMS execution of `M164CHK`.

---

# M165–M166 archive

## M165 (original docs/M165.md)

# M165 staged commit milestone

M165 creates a loose child commit from exactly one staged tracked CMS path.

Safety boundaries:
- HEAD and every base tree are authenticated through GITREC.
- The staged path must still match its checkout base in current HEAD.
- The workfile must exactly match the staged blob; unstaged changes fail.
- Only ancestor trees on the staged path are rewritten.
- The current HEAD commit is imported as the parent.
- The new commit is verified after creation.
- M165 does not update any ref. Ref compare-and-swap is a later milestone.

The real-CMS checker retains the verified loose commit candidate so the next
ref-CAS milestone can advance an isolated ref to the proven commit.


## M166 (original docs/M166.md)

# M166 modern REF2 compare-and-swap

M166 moves `GIT UPDATE-REF` from the obsolete `GITREFS REPO A` prototype
onto the active `GITREF2 REPO A` database.

The command requires three arguments:

```
GIT UPDATE-REF refs/heads/name new-oid expected-old-oid
```

CAS semantics use Git-style zero object IDs:

- expected old `000...000` creates the ref only if it is absent;
- new `000...000` deletes the ref only if the expected old OID matches;
- nonzero updates require an exact expected old OID;
- stale comparisons return RC 8 without writing REF2;
- the symbolic HEAD target cannot be deleted.

Every nonzero target must be a locally present loose COMMIT and must pass
`GIT VERIFY-OBJECT` before REF2 can move to it.

The real-CMS M166 checker uses only `refs/heads/m166test`. It points that
disposable ref at the retained M165 commit
`D6FB8432692CF8EFBDC2DDA354425D8DCDC3A008`, proves a stale CAS leaves
REF2 byte-for-byte unchanged, then deletes the disposable ref with an exact
CAS and requires the entire REF2 file to match its initial snapshot again.

Neither `HEAD` nor `refs/heads/main` is moved by the M166 checker.

---

# M167–M170 historical archive (original docs/M167-M170_HISTORY.md)

# M167–M170 historical milestone archive

Original separate files remain recoverable through Git history. This archive preserves their complete text.

---

## Original docs/M167.md

# M167 integrated staged commit to disposable ref

M167 composes the two write boundaries proven separately by M165 and M166.

The command is:

```
GIT COMMIT-STAGED-REF refs/heads/name expected-old-oid \
  -T seconds -Z zone -M message
```

The worktree/commit side is delegated to the already-proven M165
`GITWT COMMIT` path. Its output must contain exactly one staged parent and
exactly one staged commit OID. The parent must equal the caller-supplied
expected old OID before any ref update is attempted.

The ref move is delegated to M166 `GIT UPDATE-REF` using that exact expected
old OID. After CAS, M167 resolves the moved ref through the verified REF2
bridge. If post-CAS verification fails, M167 attempts an exact CAS rollback
from the new commit back to the expected old OID.

M167 does not move symbolic HEAD by itself. The real-CMS target checker uses
only `refs/heads/m167test`. It initializes that disposable branch at current
HEAD, stages a deterministic change to the sealed `src/GIT.EXEC` fixture,
runs the integrated command, proves only the disposable branch advanced,
verifies the new commit, then deletes the disposable branch and requires
`GITREF2 REPO A` to return byte-for-byte to its baseline snapshot.

Because HEAD remains on `refs/heads/main`, worktree STATUS remains STAGED
after the disposable branch advances. Updating the current symbolic HEAD
branch and reconciling the worktree map is intentionally deferred to a later
milestone.


---

## Original docs/M168.md

# M168 current-branch commit reconciliation

M168 turns the separately proven M167 commit-to-ref operation into current
branch porcelain while keeping worktree state coherent.

`GIT COMMIT-CURRENT` reads the symbolic `HEAD` ref and its exact old OID
from modern `GITREF2 REPO A`. It delegates object creation and compare-and-
swap ref advancement to `GIT COMMIT-STAGED-REF`. After the branch move,
`GITWT ACCEPT` verifies that the mapped workfile still hashes to the staged
blob, promotes `BASE=STAGE`, writes the worktree map, rereads it, and
requires the accepted map to be self-consistent.

If worktree acceptance fails after the ref CAS, `GIT COMMIT-CURRENT` uses
the new commit OID returned by M167 and performs an exact CAS rollback of the
current branch to its old commit.

The real-CMS checker does not move `refs/heads/main`. It snapshots REF2,
creates a temporary `refs/heads/m168test` at the sealed HEAD commit, and
temporarily points symbolic HEAD at that disposable branch. It then performs a
single-file staged commit through `GIT COMMIT-CURRENT`, requires the
disposable current branch to advance to a new verified commit, and requires
`GIT STATUS` to report TRACKED 1, CHANGED 0, STAGED 0.

Finally the checker restores the entire original REF2 file byte-for-byte,
removes disposable worktree files, and leaves the newly created loose commit
available for later milestones.


---

## Original docs/M169.md

# M169 generalized smart-HTTP discovery

M169 begins the post-porcelain network phase recorded after M163/M168.

The old M12 transport proved real GitHub smart-HTTP end-to-end, but its live
discovery and upload-pack POST commands hard-coded both the repository path and
historical wanted OID. M169 removes the first of those assumptions.

Public command:

```
GIT FETCH-DISCOVER bridge-host bridge-port authority owner/repo branch
```

`GITFETCH DISCOVER` builds the HTTP GET request dynamically, requires raw
REXX/SOCKETS with SO_ASCII OFF, bounds each receive to 256 bytes and the total
response to 4 MiB, validates HTTP 200 plus the Git upload-pack advertisement
content type, decodes HTTP/1.1 chunked transfer coding, and parses v0/v1 Git
pkt-lines incrementally.

The parser requires the service announcement and flush framing, validates every
advertised OID/ref pair, permits at most 10,000 refs and 4,096-byte pkt-line
payloads, requires exactly one requested branch, and requires the capabilities
`side-band-64k` and `ofs-delta` needed by the next generalized upload-pack
request milestone.

M169 intentionally does not overwrite or reuse the preserved M11BODY/M12BODY
or GITPBUF PACK captures from the target-proven M12 transport work. Parsing is
performed in bounded in-memory state only.

The real-CMS gate performs one live discovery through the existing practical
EC2 stunnel bridge:

```
GIT FETCH-DISCOVER 192.168.200.1 8443 \
  github.com mostangrymike/ibm-sandbox main
```

It does not POST or download a PACK. M170 will use the dynamically advertised
OID from this generalized boundary to construct the upload-pack request.


---

## Original docs/M170.md

# M170 dynamic upload-pack POST

M170 composes the target-proven M169 generalized discovery with a generalized
smart-HTTP upload-pack POST.

Public commands:

```
GIT FETCH-DISCOVER bridge port authority owner/repo branch
GIT FETCH-POST bridge port authority owner/repo oid
```

The M170 target gate never uses a historical hard-coded wanted OID. It captures
the short `FETCH OID <40-hex>` record from the immediately preceding live
discovery and passes that exact OID into `FETCH-POST`. The POST converts the
wire OID to lowercase, generates pkt-line length and HTTP Content-Length
dynamically, and requests only `side-band-64k` and `ofs-delta`, preserving
the minimal request shape target-proven in M12.

The POST response is consumed completely but not persisted. The parser requires
HTTP 200, upload-pack result content type, chunked transfer coding, one NAK,
valid pkt-line framing, side-band channels, no channel-3 fatal packet, and a
channel-1 PACK stream whose first 12 bytes contain PACK plus version 2/3 and a
nonzero object count.

Only bounded state is retained: counters and the first 12 PACK header bytes.
The receive size is 256 bytes, individual HTTP chunks are bounded to 1 MiB,
pkt payloads to 65,516 bytes, and the complete HTTP wire response to 16 MiB.

M170 deliberately does not read or overwrite M11BODY, M12BODY, GITPBUF, or
GITPMETA. A later milestone can add a new generalized PACK persistence path
without mutating the preserved M12/native benchmark fixture.



---

## Original: docs/M171-M176_HISTORY.md (complete original archive)

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



---

## Original: docs/M155-M163_HISTORY.md (complete original history)

# M155–M163 historical milestone archive

This file preserves verbatim the nine historical milestone documents that previously existed as separate files under `docs/`. The original paths remain available in Git history. This is documentation-only consolidation; target-proven modules, sources, tests, and CMS files are unchanged.

---

## Original: `docs/M155_COMPACT_GATE.md`

# M155 compact CMS acceptance output

M153 and M154 are native CMS target-proven as of 2026-10-05. Future target gates should request only a small acceptance subset from the CMS transcript: the full-snapshot verification marker, the decisive milestone summary counts, any one required transition/status line, DATA END when applicable, and the following Ready line. The full authenticated command output remains diagnostic evidence but does not need to be pasted into chat unless a compact gate fails.

For presence-history gates, a sufficient successful transcript is normally 4-6 lines plus Ready. On failure, capture the complete command output for diagnosis.

---

## Original: `docs/M156_PRESENCE_DURATION.md`

# M156 authenticated closed presence duration

M156 adds:

`GIT HISTORYFIRSTPRESENCEDURATION-REF-FULL <commit|ref> <depth> <path>`

The command reuses the authenticated first-parent presence runs from M151-M154.
It reports duration only for a presence run that is bounded by authenticated
ADDED/DELETED transitions on both sides. Current/open and oldest/truncated runs
are not treated as fully closed durations.

For each closed run, the duration is the signed time difference between the
child commit that begins the run and the newer child commit that ends it.
Author and committer clocks are tracked independently. A PRESENT closed run
must begin at ADDED and end at DELETED; an ABSENT closed run must begin at
DELETED and end at ADDED. Violations fail closed.

## Sealed target fixture

Commit:
`486ADAA5B02080720F4B329C6F68550B13C6AA87`

Depth: 5

Path: `src/GITPBWALK.EXEC`

Expected presence states are ABSENT, PRESENT across four commits, ABSENT.
Therefore there are three presence runs and exactly one closed run:

- run 2 state PRESENT
- begin edge 5 status ADDED
- end edge 1 status DELETED
- author duration 50 seconds
- committer duration 50 seconds

## Compact real-CMS gate

Upload `GITVREF.EXEC`, `GIT.EXEC`, and `M156CHK.EXEC`, then run only:

`M156CHK`

At the current M157 wrapper level, success output is three lines. The checker accepts any synchronized level M156 or newer:

```text
M156 LEVEL PASS M157/M157
M156 DURATION PASS RUN 2 PRESENT 50/50
M156 COMPACT TARGET GATE PASS
```

followed by plain `Ready;`. Full verbose output is needed only if this compact
gate fails.

---

## Original: `docs/M157_PRESENCE_AGE.md`

# M157 authenticated current presence age

M157 adds:

`GIT HISTORYFIRSTPRESENCEAGE-REF-FULL <commit|ref> <depth> <path>`

It reuses the authenticated current-presence origin machinery. If the beginning
of the current presence run is known as an ADDED/DELETED change or repository
root, the command reports complete signed author and committer age from that
beginning to the newest commit. If bounded history is truncated before the
beginning, it reports observed spans rather than claiming a complete age.

## Sealed target fixture

Commit:
`6EF11911449C184457F3958ABE4CA7A0692CE8C9`

Depth: 6

Path: `src/GITPBWALK.EXEC`

Expected result:

- current state ABSENT
- current run nodes 6, exact runs 1
- begin known 1
- begin kind CHANGE
- begin edge 6 status DELETED
- author age 268 seconds
- committer age 268 seconds

## Compact target gate

After transferring the M157 wrappers and `M157CHK.EXEC`, run only:

`M157CHK`

Expected output:

```text
M157 LEVEL PASS M157/M157
M157 AGE PASS ABSENT EDGE 6 DELETED 268/268
M157 COMPACT TARGET GATE PASS
```

followed by plain `Ready;`. The checker accepts any synchronized GIT/GITVREF level M157 or newer.


## Combined compact gate through M157

`M157GATE EXEC` runs M155CHK, M156CHK, and M157CHK internally and suppresses
their successful detail. This is the preferred real-CMS acceptance command.

Expected output:

```text
M157GATE M155 PASS
M157GATE M156 PASS
M157GATE M157 PASS
M157GATE COMBINED TARGET GATE PASS
```

followed by plain `Ready;`. If it fails, run only the named compact checker
reported by the failure line; use a verbose history command only if that compact
checker also fails.

---

## Original: `docs/M158_PRESENCE_TIME.md`

# M158 authenticated first-parent presence time

M158 adds:

`GIT HISTORYFIRSTPRESENCETIME-REF-FULL <commit|ref> <depth> <path>`

It composes the authenticated presence-run, chronology, closed-duration and
current-age machinery into a per-run time ledger. Every run is classified as
CURRENT, CLOSED, ROOT, or TRUNCATED.

Complete runs contribute signed author/committer seconds to PRESENT or ABSENT
totals. A truncated oldest run is explicitly incomplete and contributes only
observed span to its own run record; it is never included in complete-time
totals.

## Sealed target fixture

Commit:

`486ADAA5B02080720F4B329C6F68550B13C6AA87`

Depth: 5

Path: `src/GITPBWALK.EXEC`

Expected accounting:

- presence runs: 3
- complete runs: 2
- incomplete runs: 1
- complete PRESENT runs: 1
- complete ABSENT runs: 1
- complete PRESENT author/committer seconds: 50 / 50
- complete ABSENT author/committer seconds: 0 / 0
- run 1: ABSENT CURRENT complete, 0 / 0 seconds
- run 2: PRESENT CLOSED complete, 50 / 50 seconds
- run 3: ABSENT TRUNCATED incomplete, 0 / 0 observed seconds

Compact proof records:

```text
HFPT P1 S 3 2 1 1 1
HFPT P1 T 50 50 0 0
HFPT P1 R 1 ABSENT CURRENT 1 0 0
HFPT P1 R 2 PRESENT CLOSED 1 50 50
HFPT P1 R 3 ABSENT TRUNCATED 0 0 0
```

## Target gate

Transfer `GIT.EXEC`, `GITVREF.EXEC`, and `M158CHK.EXEC`, then run:

`M158CHK`

The checker intentionally executes the authenticated history command directly,
not as a CMS Pipelines stage. Its full report remains visible so target proof
cannot be distorted by the pipeline-capture behavior isolated during M155-M157.
No GITREC rebuild is required.

---

## Original: `docs/M159_PRESENCE_RATIO.md`

# M159 authenticated first-parent presence ratio

M159 adds:

`GIT HISTORYFIRSTPRESENCERATIO-REF-FULL <commit|ref> <depth> <path>`

It builds on M158 complete-time accounting and reports PRESENT/ABSENT shares
in integer basis points (10000 = 100%). Ratios are emitted only when both
complete-time components are nonnegative and their total is positive.
Otherwise the corresponding AUTHOR/COMMITTER ratio is marked unavailable
instead of inventing a percentage.

## Sealed target fixture

Commit:
`486ADAA5B02080720F4B329C6F68550B13C6AA87`

Depth: 5

Path: `src/GITPBWALK.EXEC`

Expected compact proof:

```text
HFPR P1 S 2 1 1 1
HFPR P1 A 1 50 50 0 10000 0
HFPR P1 C 1 50 50 0 10000 0
```

Meaning:
- complete runs: 2
- incomplete runs: 1
- complete PRESENT runs: 1
- complete ABSENT runs: 1
- author complete total: 50 seconds, all PRESENT
- committer complete total: 50 seconds, all PRESENT
- PRESENT share: 10000 basis points
- ABSENT share: 0 basis points

## Target gate

Transfer `GIT.EXEC`, `GITVREF.EXEC`, and `M159CHK.EXEC`, then run:

`GIT LEVEL`
`M159CHK`

The checker invokes the authenticated history command directly rather than
through a CMS Pipelines command stage. No GITREC rebuild is required.

---

## Original: `docs/M160_PRESENCE_COVERAGE.md`

# M160 authenticated first-parent presence coverage

M160 adds:

`GIT HISTORYFIRSTPRESENCECOVERAGE-REF-FULL <commit|ref> <depth> <path>`

It reports structural completeness of the bounded first-parent presence history
used by M158/M159. Coverage is deliberately based on authenticated run and node
counts, not elapsed time, so commit density is not misrepresented as time
coverage.

The report reconciles:
- complete + incomplete presence runs = all presence runs;
- complete + incomplete first-parent nodes = the chain node count;
- each complete/incomplete basis-point pair sums to 10000.

## Sealed target fixture

Commit:
`486ADAA5B02080720F4B329C6F68550B13C6AA87`

Depth: 5

Path: `src/GITPBWALK.EXEC`

Expected compact proof:

```text
HFPC P1 S 3 2 1 6 5 1
HFPC P1 B 6666 3334 8333 1667
```

Meaning:
- 3 presence runs: 2 complete, 1 incomplete;
- 6 chain nodes: 5 in complete runs, 1 in the truncated run;
- run completeness: 6666 basis points;
- node completeness: 8333 basis points.

## Target gate

Transfer `GIT.EXEC`, `GITVREF.EXEC`, and `M160CHK.EXEC`, then run:

`GIT LEVEL`
`M160CHK`

The checker invokes the authenticated history command directly. No GITREC
rebuild is required.

---

## Original: `docs/M161_PRESENCE_FRONTIER.md`

# M161 authenticated first-parent presence coverage frontier

M161 adds:

`GIT HISTORYFIRSTPRESENCEFRONTIER-REF-FULL <commit|ref> <depth> <path>`

It identifies where M160's incomplete structural coverage begins. When history
is depth-truncated, the report names the oldest incomplete presence run, its
state/kind/node count, its start/end step and depth, and—when a complete region
exists immediately before it—the last complete step plus the authenticated
ADDED/DELETED transition edge at the coverage frontier.

This differs from M152 current-presence origin: M152 locates the beginning of
the current run, while M161 locates the boundary between structurally complete
and incomplete bounded history.

## Sealed target fixture

Commit:
`486ADAA5B02080720F4B329C6F68550B13C6AA87`

Depth: 5

Path: `src/GITPBWALK.EXEC`

Expected compact proof:

```text
HFPF P1 S 1 1 3 ABSENT TRUNCATED 1 6 6
HFPF P1 B 5 4 5 ADDED
```

Meaning:
- history is truncated and has a complete/incomplete frontier;
- incomplete run is run 3, ABSENT, TRUNCATED, one node;
- incomplete run occupies step 6 through step 6;
- last complete step is 5 at depth 4;
- frontier edge is edge 5, authenticated status ADDED.

## Target gate

Transfer `GIT.EXEC`, `GITVREF.EXEC`, and `M161CHK.EXEC`, then run:

`GIT LEVEL`
`M161CHK`

The checker invokes the authenticated history command directly. No GITREC
rebuild is required.

---

## Original: `docs/M162_PRESENCE_FRONTIER_DISTANCE.md`

# M162 authenticated first-parent presence frontier distance

M162 adds:

`GIT HISTORYFIRSTPRESENCEFRONTIERDISTANCE-REF-FULL <commit|ref> <depth> <path>`

It extends M161's structural coverage frontier with distance and chronology.
When a complete/incomplete frontier exists, it reports:
- first-parent step distance from HEAD to the first incomplete node;
- first-parent depth distance;
- author/committer span from HEAD to that incomplete node;
- author/committer delta across the frontier edge itself.

Signed chronology is preserved; unlike the M159 ratio, these values are not
suppressed merely because a clock delta is negative.

## Sealed target fixture

Commit:
`486ADAA5B02080720F4B329C6F68550B13C6AA87`

Depth: 5

Path: `src/GITPBWALK.EXEC`

Expected compact proof:

```text
HFPG P1 S 1 5 5 105 105
HFPG P1 E 5 ADDED 55 55
```

Meaning:
- frontier distance is available;
- incomplete history starts five first-parent steps / five depths from HEAD;
- HEAD-to-frontier author and committer span: 105 / 105 seconds;
- frontier edge 5 is ADDED;
- edge author and committer delta: 55 / 55 seconds.

## Target gate

Transfer `GIT.EXEC`, `GITVREF.EXEC`, and `M162CHK.EXEC`, then run:

`GIT LEVEL`
`M162CHK`

The checker invokes the authenticated history command directly. No GITREC
rebuild is required.

---

## Original: `docs/M163_PRESENCE_HORIZON.md`

# M163 authenticated first-parent complete presence horizon

M163 adds:

`GIT HISTORYFIRSTPRESENCEHORIZON-REF-FULL <commit|ref> <depth> <path>`

It reports the fully complete prefix of the authenticated bounded first-parent
presence history. M161/M162 describe where incomplete history begins; M163
reports how far back from HEAD the history remains structurally complete.

When a complete prefix exists, the report includes:
- complete-through step and depth;
- step and depth distance from HEAD;
- signed author/committer span from HEAD to the last complete node;
- the next incomplete step and authenticated frontier edge when truncation
  follows the complete prefix.

The complete-node count is reconciled with the complete-through step so the
reported horizon cannot silently skip or include incomplete nodes.

## Sealed target fixture

Commit:
`486ADAA5B02080720F4B329C6F68550B13C6AA87`

Depth: 5

Path: `src/GITPBWALK.EXEC`

Expected compact proof:

```text
HFPH P1 S 1 5 4 4 4 50 50
HFPH P1 F 1 6 5 5 ADDED
```

Meaning:
- complete horizon is available;
- complete history runs through step 5 at depth 4;
- complete horizon is 4 first-parent steps / 4 depths from HEAD;
- HEAD-to-horizon author and committer span: 50 / 50 seconds;
- the next node is incomplete step 6 at depth 5;
- frontier edge is edge 5, authenticated status ADDED.

## Target gate

Transfer `GIT.EXEC`, `GITVREF.EXEC`, and `M163CHK.EXEC`, then run:

`GIT LEVEL`
`M163CHK`

The checker invokes the authenticated history command directly. No GITREC
rebuild is required.
