# M184 — observational native host comparison of M181/M182/M183

## Purpose

The user instructed **do not pause** while M182 and M183
await real CMS measurements. We can validate and compare
host behavior without repeatedly running expensive z/VM
workloads or touching the protected native G files.

The latest real z/VM 6.3 result remains M181:
`GITPHX EXEC` invokes `GITPHXM MODULE`; native
tree closure RC0 with 8 trees, 272 blobs, 279 entries,
280 verified objects, 7,736 unique indexed OIDs,
2 forward sequential stage scans of 3,864,799
physical text records each and zero random seeks.
Real CPU **294.57s**, elapsed **298.38s**.
Its final post-run FILEDEF check was not provided.

M182 is separately host-proven (`GITPH2M.C`,
pair-of-hex 65,536-entry table); M183 is separately
host-proven (`GITPH3M.C`, M181 LUT with four-way
loop and shared physical-record length). Neither
has a real z/VM 6.3 measured runtime. Do not
substitute a host performance figure for target proof.

## M184 host harness

`tests/bench-m184-hex-selective.py` is a standalone
Python 3 stdlib benchmark requiring `gcc` (GitHub
native-stage Actions runner). It does not modify
any existing production source or CMS module.

1. Strictly C89-compile M181, M182, M183 native
   sources, plus the existing read-only host
   `GITPIDX` index generator into a temp directory.
2. Generate a disposable native stage with one
   deliberately *unreachable* 15,360,000-byte blob
   to exercise skipped-body validation, a small
   reachable blob, and the root tree that refers
   only to the small blob.
3. Build the index on the disposable host fixture
   only, using the original strict index builder.
   No index generation on CMS or permanent G.
4. For every candidate, require equal root,
   1 tree, 1 reached SHA-authenticated blob,
   2 verified objects, 3 unique index objects,
   2 full forward stage scans, no random seeks,
   exactly equal physical stage-line counts
   and each candidate's specific terminal PASS.
5. After one warmup, run 7 comparative iterations
   with rotating order and print median, minimum
   and maximum wall-clock seconds for each module.
   Hash stage and index before/after; demand
   identical content and success return code.
6. Do **not** fail CI for any performance ranking,
   margin, or timing variation: only correctness
   / input preservation should determine CI PASS.

Host timings are subject to OS page cache, Python
process launching, concurrent runner load, native
CPU speed and libc behavior. They do not predict
the IBM C89 CMS runtime ranking. The user's
mainframe benchmark can differ materially, and
small host differences are not significant.
The native C89 `clock()` phase diagnostic was
UNAVAILABLE on real z/VM 6.3 for M179–M181.

The host benchmark is integrated in
`.github/workflows/native-stage.yml` and reports
`M184 PARITY AND READ-ONLY BENCHMARK PASS`
when all correctness assertions hold.

## Next safe target decision

- Preserve the real CMS M181 reader as the reference.
- Keep M182 and M183 installed as independent modules
  rather than overwriting or renaming known-good ones.
- When CMS operator time is available, use the already
  merged runbooks at `docs/M182_HEX_PAIR.md` and
  `docs/M183_SKIP_LENGTH.md` for their respective
  two-file Mac transfer and *one* read-only target
  execution each, plus `QUERY FILEDEF`.
- Compare actual CMS elapsed/CPU against M181
  298.38s / 294.57s, and between candidates under
  similar load, without claiming formal significance
  from single executions.

No ERASE, FORMAT, G reimport/index rebuild, write
link to overlapping `PMAINT 0141` fullpack, or
writes to `M173NET STAGE G`/`M174NET INDEX G`
are authorized. This milestone is HOST ONLY:
no new CMS EXEC, C module or transfer is needed.
