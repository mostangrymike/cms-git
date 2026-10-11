# M186 — deterministic differential integrity matrix for skipped records

## Status and purpose

M181 is still the fastest confirmed **real z/VM 6.3**
native tree walker: CPU 294.57s / elapsed 298.38s,
8 trees, 272 reachable SHA-authenticated blobs,
280 verified objects, 7736 unique index objects,
two complete 3,864,799-line stage scans and no seeks.

M182, M183 and M185 are separately host-proven native
optimizations but do not yet have reported real CMS
success or performance. The M185 single Linux-host
comparison (15.36 MB skipped blob, seven rotating
samples) showed median 0.0760s for M185, 0.0908s
for M183, 0.0987s for M182, 0.1211s for M181.
These are observational host times, **not CMS evidence**.

M185 changes the parsing strategy in a hot path.
M186 adds an additional regression against accidental
acceptance of malformed, unauthenticated skipped data.
**M186 is HOST ONLY: no CMS transfer or new reader.**

## Test design

`tests/test-m186-skip-differential.py` compiles the
unchanged `GITPHXM.C` (M181), `GITPH3M.C` (M183),
`GITPH5M.C` (M185), plus the existing native stage
index generator, all in strict C89
(`gcc -x c -std=c89 -Wall -Wextra -Werror`).

The test creates a disposable native stage/index with
four objects: unreachable 2,048-byte blob,
reachable small blob, unreachable empty blob,
and root tree that points to the small blob.
All candidates must pass the original valid fixture
with the same authenticated tree closure, one
reachable SHA blob, two verified objects,
four unique indexed objects, two scans and zero
random seeks. No original G data is read or changed.

It then runs **181 reproducible test cases**
using fixed seed 186: canonical positive,
specific valid/invalid first-hex substitutions,
short/long/malformed record cases, 160 seeded
mutations to body hex records, and an explicit
zero-length skipped-blob set. Invalid hex
within the skipped blob MUST return failure.
Valid hex changes to that *unreachable* blob may
be accepted, because selective SHA intentionally
does not hash unrelated blobs. Reachable blobs
are still SHA-authenticated by the existing
M185 targeted parity suite. M181 is the
behavioral baseline; M183 and M185 must return
the same status as M181 for every case.
Each successful run also requires the same
root/tree/blob/index counts and native PASS,
and all unsuccessful runs must omit native PASS.
The test verifies input index SHA256 unchanged
through mutations, and restores/verifies original
stage and index at the end.

The check intentionally does not claim that
selective SHA authenticates all unreachable blob
contents: it validates their native hex syntax,
bounds and physical text-record structure.
Acceptance of a different *valid* hex payload on
an unreferenced blob remains the original M181
behavior and is not a missing integrity check
on the requested reachable tree closure.

M186 runs in the GitHub native-stage CI workflow
and prints:

```text
M186 DETERMINISTIC SEED 186 CASES 181 ACCEPTED ...
M186 M181 M183 M185 POSITIVE AND NEGATIVE PARITY PASS
M186 HOST ONLY; NATIVE CMS EXECUTION NOT IMPLIED
```

Any disagreement on a return code or final
authenticated closure is a CI failure.
No runtime ranking/performance threshold is used.

## Next protected CMS work remains unchanged

When desired, real CMS positive-path validation is
available for distinct native modules/wrappers:
`GITPH2M.C` + `GITPH2.EXEC` (M182);
`GITPH3M.C` + `GITPH3.EXEC` (M183);
`GITPH5M.C` + `GITPH5.EXEC` (M185).
Exact read-only preflight, compile, root-walk,
and post-`QUERY FILEDEF` commands live in
`docs/M182_HEX_PAIR.md`,
`docs/M183_SKIP_LENGTH.md` and
`docs/M185_DIRECT_SKIP.md`.

The protected G disk `GIT600`, `M173NET STAGE G`,
`M174NET INDEX G`, and all known-good M176–M181
modules are untouched. Never format/reimport/reindex,
ERASE protected files, or write-link overlapping
`PMAINT 0141` fullpack.
