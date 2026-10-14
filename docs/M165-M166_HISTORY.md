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

