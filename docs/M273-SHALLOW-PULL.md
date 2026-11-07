# Shallow pull and fast activation (M273/M274)

This note records the validated `GIT PULL` path on z/VM CMS and the
performance rules behind it.  Everything here was exercised against
`mostangrymike/cms-git` on GitHub over the plain-HTTP -> TLS bridge.

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
5. Verify the fetched tip is a descendant of the local tip.
6. Worktree preflight (refs-only when the worktree map is empty).
7. Update `refs/remotes/<remote>/<branch>` and fast-forward the local branch.

An empty pack (server already has everything) is accepted; the pull reports
`Already up to date <oid>`.

## Measured timings

| Case | Result | Time |
| --- | --- | --- |
| `0E5E3F27` -> `4B260B02` (3 objects) | `PULL COMPLETE` | ~4.2 s |
| `4B260B02` -> `CE5F0D5B` (3 objects) | `PULL COMPLETE` | ~4.3 s |
| already at `CE5F0D5B` | `Already up to date` | ~3.7 s |

## Transport

The CMS HTTP client speaks plain HTTP.  `scripts/github_tls_bridge.py`
accepts it on `0.0.0.0:8443` and relays to `github.com:443` over TLS.  It
relays until EOF instead of closing on the final chunk, which previously
truncated small responses and produced `GITPOST: failed at HTTP-PARSE`.
