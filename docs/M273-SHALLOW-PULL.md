# Shallow pull and fast activation (M273/M274)

This note records the validated `GIT PULL` and `GIT CLONE` paths on z/VM CMS
and the performance rules behind them.  The measured runs below were
exercised against GitHub over the plain-HTTP -> TLS bridge.  Clone is the same
fetch/import/activate/ref-update path with default-branch discovery and the
first checkout prepended; both paths have passed on the CMS target.

## Why shallow by default

A full-history import of `main` needs about 11,863 objects / 298 MB.  With
the CMS stage and loose-object encodings that is roughly 1.34 GB of DASD,
which does not fit on the 288,000-block object disk.  A tip-closure pull is
about 199 objects / 4.3 MB and fits comfortably.

`GIT PULL` therefore sends `HAVE <local-tip>` so the server returns only the
objects needed to connect the local tip to the remote tip.  `deepen 1` is
used only when there is no local tip (clone / first fetch), because a
depth-1 pack omits the parent commits that the ancestry check needs.

## Cost model

CMS text-file access costs roughly 80 microseconds per record and a random
`fseek` is O(offset), not O(1); scanning runs at about 0.8-4 MB/s even with
`RECFM F`.  The fast path is therefore built from sequential passes:

1. Fetch the pack into `PULLPACK PACK/META` on the A disk.
2. Import into a `RECFM V LRECL 4096` stage file.  A CMS variable record
   holds at most 4092 data bytes (4-byte RDW), so chunks are 2000 bytes.
3. Cache tree bodies in one sequential pass, resolve the checkout closure
   in memory, then verify reachable blobs in a second pass.
4. Install loose objects in stage-object-number order with one sequential
   scan (`M274L5 BATCH`).

## Assembling M274L5

`M274L5` is a CMS C program that needs the native `gitpfs` helper from
`M274PF2.ASSEMBLE` (or `M274PFS.ASSEMBLE` for the shared-library
variant).  The CMS assembler accepts only fixed 80-character input, while
an FTP ASCII transfer stores the source as variable 72; copy it to a
fixed-80 work file before assembling:

    GLOBAL MACLIB OSMACRO DMSGPI PDPCLIB
    COPYFILE M274PF2 ASSEMBLE A M274PF2F ASSEMBLE A (RECFM F LRECL 80
    ASSEMBLE M274PF2F
    EXEC GCCE M274L5 C A (NOASM PARAM STD380
    ASSEMBLE M274L5
    GLOBAL TXTLIB PDPCLIB
    LOAD M274L5 M274PF2F (NOAUTO NOMAP
    GENMOD M274L5

`CMSCLNK` cannot build this program: its `PLAIN` mode links only the C
module, and its `NAPI` mode adds `GITCAPI`/`GITINFA` instead of the
`gitpfs` helper.  A successful `LOAD` prints no undefined names.

The sequence was verified on GCCLIB `29D` (`F`) on 2026-11-11 with
disposable names (`ZT274`/`ZT2PF2`, plus a plain `ZTCH` hello build):
the fixed-80 copy, both assemblies, the C compile, `LOAD` and `GENMOD`
returned RC 0, and the module printed its usage line.  The disposable
files were then erased; the working `M274L5 MODULE A` was left untouched.

The host stand-in is built with `gcc -DGITPLOAD_HOST` and reads/writes
`dd:IDXIN` and `dd:STGIN` directly, so the same BATCH logic can be
exercised outside CMS.

## Incremental (HAVE) packs

An incremental pack contains only the new objects; the unchanged closure is
already in the verified loose store.  `GITFACT ... INCREMENTAL` therefore
skips the stage-closure walk, because the pack cannot contain that closure.

After install, every activation (incremental or full) runs the same
installed-closure verification: starting at the new root tree, `GITFACT`
walks the loose store and requires each reachable object to exist with a
matching OID, type, size, and total `DATA` length.  This proves the
installed closure is structurally complete; it does not re-hash every blob
body.

## Pull sequence

`GIT PULL` performs:

1. Erase stale `PULLPACK PACK/META`, `PULLPACK STAGE`, `PULLIDX INDEX`
   (a failed pull keeps them for recovery, so a retry must clear them).
2. Discover the remote refs and fetch with `HAVE`.
3. Verify the pack checksum (`GITPCHK`) and import it to the stage.
4. Activate (`INCREMENTAL` when a `HAVE` was sent).
5. Verify the fetched tip is a descendant of the local tip.  A repository
   whose branch is unborn skips this step and uses the zero object-id as the
   old tip, so the first pull is a create.
6. Worktree three-way preflight over the old and new commit trees: every
   mapped path must be clean and still match its base blob; mapped paths
   missing from the new tree are removals, changed mapped paths are updates,
   and paths introduced since the old tip are adds.  A partial worktree map
   is valid and never acquires pre-existing unmapped paths.
7. Update `refs/remotes/<remote>/<branch>` and fast-forward (or create) the
   local branch.
8. Apply the preflight result: reserve every new CMS file ID, rewrite
   updates, erase removals, write adds, re-hash each written file, and save
   the rebuilt map.  On create, run `GITWT CHECKOUT-TREE <branch>` so the
   first pull materializes the worktree and worktree map.

An empty pack (server already has everything) is accepted; the pull reports
`Already up to date <oid>`.

## Measured timings

| Case | Result | Time |
| --- | --- | --- |
| `0E5E3F27` -> `4B260B02` (3 objects) | `PULL COMPLETE` | ~4.2 s |
| `4B260B02` -> `CE5F0D5B` (3 objects) | `PULL COMPLETE` | ~4.3 s |
| `CE5F0D5B` -> `5C2CA58C` (25 objects, 110 KB) | `PULL COMPLETE` | 15.65 s |
| `5C2CA58C` -> `3FDEC0AE` (6 objects, 11.5 KB, 3 commits) | `PULL COMPLETE` | 5.27 s |
| already up to date | `Already up to date` | ~3.7 s |
| `90095C2B` -> `8AEEFDF1` (3 objects, 287 B) | `PULL COMPLETE`, `FAST-FORWARD` | ~2 s |
| `GIT CLONE` of `cms-git-push-test` (`testmin`, 6 objects, 435 B) | `GIT CLONE COMPLETE` | ~2 s |

## Transport

The CMS HTTP client speaks plain HTTP.  A host bridge must accept it and
originate verified TLS to `github.com:443`.  The default endpoint is
`192.168.200.1:8443`; override it with one record in `GITBRIDG CONFIG A`:

    BRIDGE 192.168.200.1 8444

`GIT PULL` with no arguments reads that file.  `GIT CLONE` and the explicit
`GIT PULL remote bridge port pack index` form accept the endpoint directly.
The bridge relays until EOF instead of closing on the final chunk, which
previously truncated small responses and produced
`GITPOST: failed at HTTP-PARSE`.

## Clone

`GIT CLONE <https-url> [object-filemode] [bridge] [port]` performs, in order:

1. Validate and record `origin` from the URL.
2. Discover the advertised `HEAD` symref and take its branch as the local
   default, rather than assuming `main`.
3. `GIT INIT <object-filemode> <default-branch>`.
4. Run the same fast-forward pull path described above with `HEAD`.

The first pull into the initialized repository is a create: `GITUPD` accepts
the zero old object-id only when `HEAD` still names the branch and no branch
record exists, `GITWT CHECK-PULL` allows that same unborn case, and
`GITWT CHECKOUT-TREE` writes the files and worktree map.

Clone therefore inherits the pull envelope: regular CMS-compatible text
paths, including nested, long and multi-dot paths.  The worktree map stores
each Git path as uppercase ASCII hex in a `PATH` record, so the path is the
identity and the CMS file ID is a derived handle.  A natural 8.8 name is used
when the basename fits; otherwise checkout and pull allocate a stable
synthetic `WT###### GITF` name.  The mapped worktree is capped at 50 files,
while pull preflight may scan a commit tree of up to 4096 paths before
failing closed.  Binary blobs and unsupported tree modes are refused.
A fresh project minidisk accessed as `A` is a valid
object disk; the pack, stage, index and installed loose objects share it.
The pull refuses before import when the selected disk cannot hold about five
times the fetched pack plus a small metadata allowance.  If the initial pull
fails, the metadata and remote record are retained so a corrected retry can
run `GIT PULL` with no arguments.

## Worktree map and arbitrary paths

`GITWORK REPO A` is the source of truth.  Each `ENTRY` names a CMS file ID
and each `PATH` record holds the full Git path as uppercase ASCII hex.
`BASE` and `STAGE` hold blob OIDs and the trailing `ENTRY` field is the
final-LF flag.  Checkout and pull share one recursive tree collector, so a
nested path such as `docs/guide/setup.md` or a long multi-dot basename is an
ordinary mapped workfile.

A natural CMS name is used when the path's basename is one dot-separated
name with at most 8+8 characters and no other dots.  Everything else gets a
stable `WT###### GITF` name; the hex `PATH` record keeps the real Git path.
This is why a multi-dot name and a deep nested path can coexist with a
natural `ADDED.TXT` mapping without flattening the repository.

Pull compares the mapped paths against the old and new commit trees:

- kept: blob OID unchanged, workfile untouched;
- update: mapped still, new blob OID, rewrite and re-hash;
- remove: mapped path absent from the new tree, erase workfile and map entry;
- add: path present only in the new tree, write a new workfile.

Unmapped paths that already existed are never added, so a partial worktree
stays partial.  Every new CMS name is reserved before the first mutation,
every written file is re-hashed against the new blob OID, and any failure
restores the workfiles, the map and the branch ref.

Live CMS validation on 2026-11-11 used the `nested-fixture` history in
`mostangrymike/cms-git-push-test`.  A 201-file tip gained 7 nested/multi-dot
paths (5 natural names and 2 synthetic).  A second tip updated a natural and
a synthetic mapping, removed `x.y`, and added `newdir/added.txt`.  A third
tip removed `data.json`, updated `nested/deep/dir/file.txt`, and added
`newdir/second.txt`.  The pulls reported `PULLED WORKTREE FILES 2 ADDED 1
REMOVED 1` and `PULLED WORKTREE FILES 1 ADDED 1 REMOVED 1`; the map rebuilt
to 9 then 8 entries and `GIT STATUS` ended
`TRACKED 8 CHANGED 0 STAGED 0`.

## Multi-project layout

Use one minidisk per project and `ACCESS <addr> A` before running `GIT`
commands: repository metadata, refs, the remote record, and (optionally)
loose objects live on `A`.  Large installations can keep loose objects on a
separate non-`A` disk by passing that filemode to `GIT INIT` or `GIT CLONE`.

