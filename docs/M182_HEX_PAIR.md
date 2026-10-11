# M182 — isolated two-hex-character validation lookup

## Status: host source only, CMS performance unproven

Real z/VM 6.3 M181 passed on October 11, 2026,
with the corrected separate `GITPHX EXEC` and
`GITPHXM MODULE`: two full stage scans,
3,864,799 stage text lines per pass, 272 reached
SHA-authenticated blobs, 8 trees and 280 verified
objects, no seeks, CPU **294.57s** and elapsed
**298.38s**. This is 161.06s/35.1% faster
than the M179 elapsed baseline 459.44s.
M181 is the fastest measured read-only tree reader.

The successful M181 transcript did not show a
post-run `QUERY FILEDEF`. A simple independent
hygiene check remains appropriate; no M181 rerun
is needed. Earlier error-path cleanup was proven.

## Isolated M182 candidate

M182 keeps all M181 selective two-pass behavior
and strict validations, including SHA-1 of cached
trees in pass 1 and reachable blobs only in pass 2.
The new `src/GITPH2M.C` copies the target-proven
`GITPHXM.C` but tests one more micro-optimization
in `skipbody`, used millions of times.

M181 checks each skipped ASCII/EBCDIC-native
hexadecimal *character* with a 256-element table.
M182 instead checks each adjacent *pair* with a
65,536-element zero-initialized table indexed by
the unsigned native codes of both characters.
Initialization marks a pair valid if and only if
both characters are legal 0–9, A–F or a–f.
The loop advances exactly two characters.
The body text record length is checked first;
all nonselected record bytes are still validated.
Selected tree/blob bodies retain M181's original
`nib()` decoding and full Git SHA-1 integrity.
The new pair table uses 64 KiB static storage;
the resident tree cap remains separately 64 MiB.

**This change does not reduce the number of CMS
stage lines read.** The speed result may improve,
match or regress due to table size/cache behavior.
Do not assume it is faster than M181 until measured
on real CMS; the existing M181 reader is unchanged.

Native C89 `src/GITPH2M.C` is paired with
**different-stem** `src/GITPH2.EXEC`. The EXEC
checks/calls `GITPH2M MODULE A`, so it cannot
dispatch itself recursively (the M181 regression
cause). It refuses invalid/non-A filemode,
conflicting FILEDEFs, missing original stage/index
or module, and uses owned temporary read-only
STGIN and IDXIN definitions; no disk writes,
ERASE, COPYFILE, FORMAT, reimport, index build or
directory changes. It requires native root,
authenticated blob counts, two-scan/zero-seek and
end-of-walk PASS before final wrapper PASS.

Host `tests/test-m182-hex-pair.py` compiles C89
`-std=c89 -Wall -Wextra -Werror`, checks tree
closure and index parity, confirms both first and
second malformed hex nibble fail closed even in
unreachable skipped records, lowercase hex passes,
reached blob SHA corruption rejects, malformed
OID/truncated index reject and source/input records
are unchanged. CI guards distinct EXEC/MODULE names
and watches the new source. Host tests cannot
prove IBM CMS behavior or native runtime gain.

## Target gate after successful host CI

On Mac in the established `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITPH2M.C GITPH2.EXEC
```

On z/VM 6.3 MAINT, check protected original data,
no conflicting FILEDEFs, then compile **only**
new M182 module:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
QUERY FILEDEF
STATE GITPH2M C A
CMSCLNK GITPH2M PLAIN
STATE GITPH2M MODULE A
```

Only after clean new native build and preflight:

```text
GITPH2 G CCB18BEC067E7886D70B82EF138EE56A8B899A61
QUERY FILEDEF
```

Expected: root matches, 8 TREES, 272 BLOBS,
0 GITLINKS, 279 ENTRIES, 280 VERIFIED, 7736
index total/unique, 2 forward scans and 15472
header visits, 0 seeks, 272 authenticated
reachable blobs, 3,864,799 stage text lines
on each pass. Require
`M182 HEX PAIR VALIDATOR PASS`,
`M182 TREE CLOSURE PASS` and
`M182 VERIFIED FAST TREE TARGET GATE PASS`,
all RC0. Capture exact CMS Ready CPU and elapsed
and identical before/after `QUERY FILEDEF`.
`M182 CPU ... UNAVAILABLE` is acceptable.

Do not re-run M173/M174 import/index, M180 or
M181 full closures merely as prerequisites.
Never format or write through overlapping VMCOM1
`PMAINT 0141` fullpack. Preserve M176–M181
proven modules and `GIT600` disk contents.
