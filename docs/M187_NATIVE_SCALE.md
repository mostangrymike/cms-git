# M187 — synthetic native scale regression at 7,736 indexed Git objects

## Context and status

User instruction: **do not pause** independent GitHub
development or test gating while awaiting actual CMS
outputs. The native GIT600 stage and index are
protected and must not be overwritten or rebuilt.

Actual z/VM 6.3 target baseline is M181:
8 reachable trees, 272 blobs, 279 entries,
280 SHA-verified reached objects, 7,736 total/
unique indexed objects; two forward stage scans
of 3,864,799 text records each; zero random
seeks. Real CPU **294.57s** and elapsed
**298.38s**. M182/M183/M185 are host-proven
only and not yet target-time-proven. The M185
Linux-only observational median was 0.0760s
on a 15.36 MiB skipped-blob fixture, but
that cannot establish IBM CMS performance.

M186's 181-case seeded differential mutation
suite passed host CI and is merged. M187 adds
a complementary **large object-count** regression
to match the live retained index and reachable
closure in synthetic, entirely disposable
files. This is a host-only milestone with no
CMS module or user transfer commands.

## Synthetic Git stage/index

`tests/test-m187-live-scale.py` builds an original
Git object stream with exactly:

- 272 uniquely identified reachable blob objects
- 7 uniquely identified subtree objects
- 1 root tree referencing the seven subtrees
- 7,456 unrelated uniquely identified blob objects
- **7,736 indexed objects and 7,736 unique SHA1 IDs**

The seven directories contain a total of 272
regular-file entries. Root has seven directory
entries, so traversal must produce exactly
**8 trees, 272 blobs, 0 gitlinks, 279 entries
and 280 verified objects**, matching the real
CMS positive closure on the operator's G stage.

All Git object IDs are SHA-1 of their standard
`<type> <bytes>\0<binary body>` content.
The REXX/CMS files are not fetched: Python
generates host fixtures directly. The stage
uses `OBJ` header followed by 32-byte-per-
text-record hex format; the original native
`GITPIDX.C` builds the index *in a temporary
host directory only*. This does not mimic
the live pack's multi-million-line physical
record count or its compressed source; it
reproduces the critical **object cardinality,
types, index uniqueness and reachable closure**.

## Verification

Strict C89 builds of M181, M182, M183 and M185
must each return native RC0 with:
```text
TREE CLOSURE TREES 8 BLOBS 272 GITLINKS 0
TREE CLOSURE ENTRIES 279 VERIFIED 280
TREE CLOSURE INDEX TOTAL 7736 UNIQUE 7736
... FORWARD SCANS 2 RECORDS 15472 SEEKS 0
... AUTHENTICATED BLOBS 272
```
And the exact root OID, same dynamically measured
physical stage text records in each pass, and each
reader's own `TREE CLOSURE PASS`.

The same fixture is then modified, one scenario
at a time, to require:
- valid-hex mutation in an unrelated blob still
  passes (selected SHA does not cover that blob);
- invalid nonhex character in an unrelated blob
  is rejected even when skipped;
- valid-hex payload corruption of a *reached*
  blob is rejected by full Git SHA verification;
- truncated final stage record fails closed.

The stage and index SHA256 must equal their
original values after the test restores the
initial fixture; the index cannot be modified
by any native walk. All operations are host
temp files. No production data is touched.

M187 runs via `.github/workflows/native-stage.yml`.
A passing result prints:
```text
M187 INDEXED 7736 UNIQUE 7736 RECORDS ...
M187 REACHABLE TREES 8 BLOBS 272 ENTRIES 279 VERIFIED 280
M187 TWO SCANS 15472 HEADER VISITS ALL FOUR READERS PASS
M187 NEGATIVE CORRUPTION AND IMMUTABILITY PASS
M187 SYNTHETIC HOST FIXTURE, NOT REAL CMS VALIDATION
```

## Operational safety

M187 itself requires **no CMS run**.
Native target proof and performance for M182,
M183 and M185 remain pending, with exact safe
commands in:
`docs/M182_HEX_PAIR.md`,
`docs/M183_SKIP_LENGTH.md`, and
`docs/M185_DIRECT_SKIP.md`.

No format, reimport, index rebuild, stage write,
module replacement, ERASE, CP edit or write-link
of physically overlapping `PMAINT 0141`
fullpack is authorized. Keep all target-proven
M176–M181 modules and protected original G files.
