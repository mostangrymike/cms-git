# M189 — eight-hex-character validation in native stage reader

## Status, baseline and isolation

M185 is the fastest **real CMS verified** native tree
reader: CPU **206.72 seconds**, elapsed **209.97 seconds**
on z/VM 6.3, with root
`CCB18BEC067E7886D70B82EF138EE56A8B899A61`,
8 trees, 272 SHA-authenticated reachable blobs,
279 entries, 280 verified objects, 7736 indexed unique,
two complete 3864799-text-line forward stage scans,
15472 header visits and zero random seeks.
It improved on M181 elapsed 298.38s by 88.41s.
Post-run QUERY FILEDEF was not included in M185's
successful transcript; do not claim independent hygiene.

M188 has a separate host-proven fast EOL path that
retains all original M185 validation with common LF,
CRLF and no-suffix branches. Its **Linux host**
7-run median was 0.0735s vs M185 0.0766s on
a disposable 15.36MB stage. It has no real z/VM
CMS runtime, and must not replace M185 as a
production/proven baseline.

M189 is a new independent C89 experiment
`src/GITPH9M.C`, with a differently named wrapper
`src/GITPH9.EXEC`. It starts from M188 but
replaces the main `skipline` character loop with
an **8-character unrolled lookup**, accumulating
eight 0-or-1 `validhex` table entries via bitwise
AND and branching only once per group. It checks
all remaining 1–7 hex characters separately.
No record or hex byte may be skipped; invalid
hex still returns failure. It retains the entire
M188 common EOL path and full M185 fallback
for unusual suffixes.

Other behaviors are unchanged: full two-pass
forward scanning, all indexed stage header checks,
full Git SHA1 of selected trees and reachable
blobs, exact types/modes/name/depth/cycles,
64MiB resident cap and zero random seeks.
No G-stage/index writes; distinct wrapper avoids
CMS EXEC/MODULE self-recursion and clears only
temporary owned FILEDEFs after invocation.

## Host evidence, not real mainframe proof

`tests/test-m189-eightway.py` strict C89
(`gcc -x c -std=c89 -Wall -Wextra -Werror`)
checks closure and SHA parity against M178 and
M185, malformed headers, index, record length,
LF/CRLF/spaces, bad suffix characters and
an invalid hex character independently in
every one of the first eight character positions
of a skipped record.

`tests/bench-m189-eightway.py` extends the
existing 15.36MB disposable host stage
comparison to M181, M182, M183, M185, M188
and M189, seven rotating runs after warmup.
It requires identical authenticated closure,
two full scans, exact stage line totals,
and byte-for-byte unchanged stage/index,
with **no timing/ranking CI threshold**.
Linux timing is observational only, cannot
establish z/VM speedup, and may vary by host
compiler/runtime and caching.

M189's real CMS positive path is **NOT yet verified**.

## Conditional real CMS validation after host CI

Mac from `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITPH9M.C GITPH9.EXEC
```

CMS MAINT preflight/build:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
QUERY FILEDEF
STATE GITPH9M C A
CMSCLNK GITPH9M PLAIN
STATE GITPH9M MODULE A
```

Only if 4KiB G, protected stage/index and
FILEDEF preflight are clean and native
module compilation succeeds:

```text
GITPH9 G CCB18BEC067E7886D70B82EF138EE56A8B899A61
QUERY FILEDEF
```

Require unchanged 8 trees,272 blobs,279 entries,
280 verified, index7736/7736 unique,
2 scans, 15472 headers, 0 seeks, 272 reached
SHA1 blobs, 3864799 stage text records on
each pass, all M189 terminal markers:
`M189 EIGHTWAY HEX VALIDATOR PASS`,
`M189 TREE CLOSURE PASS`,
`M189 VERIFIED FAST TREE TARGET GATE PASS`,
and clean post-run `QUERY FILEDEF`.
Capture actual CPU/elapsed versus the real
M185 206.72s/209.97s baseline.

Keep target-proven GITPH5 and all earlier
modules intact. Never ERASE, FORMAT, rerun
completed M173/M174 import/index, overwrite
protected G stage/index, or write-link the
physically overlapping PMAINT 0141 wholepack.
