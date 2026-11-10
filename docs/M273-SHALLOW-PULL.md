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
variant).  Assemble in this order on a writable GCC F disk:

    ASSEMBLE M274PF2 (or M274PFS)
    GLOBAL TXTLIB PDPCLIB
    GCC M274L5 C (NOAUTO NOMAP)
    LOAD M274L5 (NOAUTO NOMAP)
    GENMOD M274L5

The host stand-in is built with `gcc -DGITPLOAD_HOST` and reads/writes
`dd:IDXIN` and `dd:STGIN` directly, so the same BATCH logic can be
exercised outside CMS.

## Incremental (HAVE) packs

An incremental pack contains only the new objects; the unchanged closure is
already in the verified loose store.  `GITFACT ... INCREMENTAL` therefore
skips the full stage-closure walk and checks that the new root tree exists
in the loose store.  A full cross-store closure verification for incremental
packs is still an open follow-up.

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
6. Worktree preflight (refs-only when the worktree map is empty).
7. Update `refs/remotes/<remote>/<branch>` and fast-forward (or create) the
   local branch.
8. On create, run `GITWT CHECKOUT-TREE <branch>` so the first pull
   materializes the flat worktree and worktree map.

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

Clone therefore inherits the pull envelope: one flat set of regular
CMS-compatible text paths, no nested directories, binaries, or path
additions/removals.  A fresh project minidisk accessed as `A` is a valid
object disk; the pack, stage, index and installed loose objects share it.
The pull refuses before import when the selected disk cannot hold about five
times the fetched pack plus a small metadata allowance.  If the initial pull
fails, the metadata and remote record are retained so a corrected retry can
run `GIT PULL` with no arguments.

## Multi-project layout

Use one minidisk per project and `ACCESS <addr> A` before running `GIT`
commands: repository metadata, refs, the remote record, and (optionally)
loose objects live on `A`.  Large installations can keep loose objects on a
separate non-`A` disk by passing that filemode to `GIT INIT` or `GIT CLONE`.

