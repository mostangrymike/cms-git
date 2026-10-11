# M183 — isolated skipped-record length and four-way hex checks

## Purpose

M181 is real z/VM 6.3 CMS target-proven: its corrected
`GITPHX EXEC` invokes distinct `GITPHXM MODULE`, and
the authenticated tree closure completed in 298.38 s
elapsed / 294.57 s CPU. It produced 8 trees, 272 blobs,
279 entries, 280 objects verified, 7736 unique indexed
objects, exactly 2 forward stage scans and zero seeks,
with 3,864,799 stage text lines read per pass.

M182 (`GITPH2 EXEC`, `GITPH2M MODULE`) is a separate,
host-tested candidate using a 64 KiB two-hex-character
lookup table; no real CMS timing/verification for M182
has been supplied. **M183 does not assume M182 success.**
It forks the actual CMS-proven M181 native source.

## M183 bounded change

`src/GITPH3M.C` retains exactly the M181 two-pass,
selective SHA1 (all reachable trees in first pass, only
reachable blobs in second), native Git OID verification,
index alignment, exact record checks, valid filemodes,
closure/type/mode/depth/cycle guards, resident cap,
zero seeks, and read-only behavior.

Its only native hot-loop changes are:
- `linein_len()` preserves the exact original `linein()`
  semantics, including CR/LF and trailing-space stripping,
  80-character maximum, stage record counters and EOF
  handling, but returns the *already calculated* trimmed
  length via an optional output integer. The old `linein()`
  is a thin call to this helper for all other callers.
- `skipbody()` compares that length against the expected
  two-hex-characters-per-byte without calling a **second**
  `strlen()` for every nonselected stage record.
- `skipbody()` checks four sequential characters per
  iteration using the unchanged 256-byte native-code
  `validhex` table; the remaining 1–3 characters are
  still checked. Invalid first, middle and final hex
  nibbles all fail closed. No runtime line is skipped,
  no SHA-1 decision changes, and no nonhex accepted.
- Zero-length bodies still require an empty CMS text
  record. Any malformed physical length remains fatal.

`src/GITPH3.EXEC` is an isolated clone of the proven
wrapper, requiring `GITPH3M MODULE` (distinct stem)
on an explicit non-A 4 KiB G input disk with preexisting
protected stage/index and no conflicting DD definitions.
It checks root and object counts and native output,
manages only its own temporary read FILEDEFs and clears
them on return. No protected G data is rewritten.

Host `tests/test-m183-skip-len.py` compiles the new
code strict C89 (`-std=c89 -Wall -Wextra -Werror`),
verifies closure/OID and counts against M178,
negative SHA and corrupt skipped text, lowercase hex,
truncated/extended malformed record lengths, an
illegal last nibble, trailing spaces on disposable
fixtures, malformed root/index, and no production
side effects. CI guards against EXEC/MODULE
name recursion and 80-column CMS source lines.

**M183 host passing does not establish z/VM speed.**
Saving one `strlen()` and unrolling the check may help,
be neutral, or regress. M181 elapsed 298.38s is the
last measured successful baseline. M182 should not be
declared faster or slower without a real CMS report.

## Conditional native CMS test, after CI PASS

Mac, existing `ibm-sandbox/src` directory:

```sh
git pull
./cms-upload.sh GITPH3M.C GITPH3.EXEC
```

On CMS MAINT, read-only preflight and compile new
independent module:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
QUERY FILEDEF
STATE GITPH3M C A
CMSCLNK GITPH3M PLAIN
STATE GITPH3M MODULE A
```

Proceed only with 4096-byte G and both protected
input files present, no caller STGIN/IDXIN collision,
and a successful native build. Invoke distinct wrapper:

```text
GITPH3 G CCB18BEC067E7886D70B82EF138EE56A8B899A61
QUERY FILEDEF
```

Required: 8 trees, 272 reached blobs, 0 gitlinks,
279 entries, 280 verified objects, 7736 unique
indexed OIDs, exactly two forward scans, 15472
object-header visits, zero random seeks,
272 authenticated reachable blobs, 3864799
stage text lines for *each* pass. Native success:
`M183 UNROLLED HEX VALIDATOR PASS`,
`M183 TREE CLOSURE PASS`, and wrapper
`M183 VERIFIED FAST TREE TARGET GATE PASS`,
all RC 0. Capture exact CMS Ready CPU/elapsed and
post-run `QUERY FILEDEF`.

Read-only input G files are `M173NET STAGE G` and
`M174NET INDEX G`; persistent disk `GIT600`.
Do not ERASE/FORMAT/reimport/rebuild original data,
repeat older expensive tests, or write-link physically
overlapping `PMAINT 0141` wholepack. Preserve
existing M176–M182 code and target-proven M181.
