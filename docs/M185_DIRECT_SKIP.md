# M185 — direct bounded validation of skipped CMS hex records

## October 11, 2026 — M185 real z/VM 6.3 CMS target PASS

The user's native CMS transcript provides **actual successful target
validation** (not host-only evidence). `CMSCLNK GITPH5M PLAIN` produced
`ASSEMBLER (XF) DONE`, `NO STATEMENTS FLAGGED`, and
`built GITPH5M MODULE mode PLAIN`, elapsed **2.30s**.
The invoked wrapper was:
`GITPH5 G CCB18BEC067E7886D70B82EF138EE56A8B899A61`.

```text
TREE CLOSURE ROOT CCB18BEC067E7886D70B82EF138EE56A8B899A61
TREE CLOSURE TREES 8 BLOBS 272 GITLINKS 0
TREE CLOSURE ENTRIES 279 VERIFIED 280
TREE CLOSURE MAX OBJECT 393767 RESIDENT PEAK 6546851
TREE CLOSURE INDEX TOTAL 7736 UNIQUE 7736
M185 FORWARD SCANS 2 RECORDS 15472 SEEKS 0
M185 AUTHENTICATED BLOBS 272
M185 STAGE LINES PASS1 3864799 PASS2 3864799
M185 CPU INDEX UNAVAILABLE
M185 CPU TREE_SCAN UNAVAILABLE
M185 CPU GRAPH UNAVAILABLE
M185 CPU BLOB_SCAN UNAVAILABLE
M185 DIRECT SKIP VALIDATOR PASS
M185 TREE CLOSURE PASS
M185 VERIFIED FAST TREE TARGET GATE PASS CCB18BEC067E7886D70B82EF138EE56A8B899A61 G
Ready; T=206.72/209.97 11:19:23
```

M185 **real CPU 206.72s, elapsed 209.97s**; M181 was CPU
294.57s, elapsed 298.38s. M185 saves **87.85s CPU**
and **88.41s elapsed (29.6%)**, with the same selective
SHA-authenticated root closure, two stage scans, 272 reached
blobs and zero random seeks. M179 elapsed 459.44s, M180
elapsed 708.52s. One-run performance comparison is
descriptive, not a controlled distribution of samples.

**Evidence boundary:** This successful M185 transcript does
not include preflight output or a *post-run* `QUERY FILEDEF`.
The earlier safe wrapper/host checks do not independently
establish success-path FILEDEF cleanup on CMS. One standalone
`QUERY FILEDEF` is sufficient; do **not** rerun the costly
walk to check it.

M185 is now the **fastest measured real z/VM 6.3 reader**.
Preserve the target-proven `GITPH5 EXEC A` and
`GITPH5M MODULE A` unchanged; future work must fork
isolated new stems and leave `GIT600`, `M173NET STAGE G`
and `M174NET INDEX G` intact. M182/M183 remain host-only
without actual CMS transcripts.

---


## Motivation and status

The z/VM 6.3 target-proven positive-path reference is
M181, `GITPHX EXEC` + `GITPHXM MODULE`: October 11
real run 8 trees, 272 reached blobs, 279 entries,
280 verified objects and 7,736 unique indexed OIDs.
Its two sequential scans each read 3,864,799 text
records and had zero random seeks. CPU **294.57s**,
elapsed **298.38s**. No post-run `QUERY FILEDEF`
was supplied for that successful M181 transcript.

M182 and M183 are independently merged and host-proven,
but neither has a supplied real-CMS runtime. M184's
Linux-only observational comparison suggests the
latter hot-loop optimizations may be promising, but
does not prove performance on IBM CMS.

**M185 is a new isolated reader, NOT yet CMS-proven.**

## Isolated native change

- `src/GITPH5M.C` forks the host-tested M183 C89
  implementation, itself based on target-proven M181.
- The frequent skipped-body reader now calls a
  separate bounded `skipline(f, expected_hex_chars)`.
  It uses `fgets` exactly once for each CMS record,
  increments the same per-pass physical record counter,
  tests every expected hex character using the unchanged
  256-entry native ASCII/EBCDIC hex validity table,
  then accepts only original `linein`'s trailing trim
  characters (space, CR and LF) before the NUL.
  It preserves the original `fgets` buffer-size cutoff
  and long-line rejection, and permits an ordinary
  last record without newline, as the original did.
- It does **not call `strlen` at all** inside skipped
  body record validation. Header and SHA-selected body
  parsing continue through the original path.
- A premature terminator, bad hex byte, truncated or
  extended line, nontrim suffix or overlong physical
  line rejects. Zero-length bodies require a valid
  empty/whitespace-only physical record, as before.
- All original tree SHA-1, index mapping, object sizes,
  2-pass selective SHA, mode/type/name rules, graph
  closure, 64MiB resident cap and zero-seek requirements
  are unchanged. No stage/index writes or file copies.

New `src/GITPH5.EXEC` is a safe independent REXX
wrapper. It calls **distinct** `GITPH5M MODULE A`
to avoid the prior M181 same-stem EXEC/MODULE error,
requires the explicitly selected non-A 4KiB input G
disk, protected preexisting original stage/index,
checks caller FILEDEF conflicts before binding its
own read-only STGIN/IDXIN, clears only its temporary
definitions, and requires expected closure plus
`M185 DIRECT SKIP VALIDATOR PASS`,
`M185 TREE CLOSURE PASS`, and
`M185 VERIFIED FAST TREE TARGET GATE PASS`.

## Host verification

`tests/test-m185-direct-skip.py` compiles C89
with `-std=c89 -Wall -Wextra -Werror`, compares
the expected authenticated native closure and
physical line totals, and tests malformed stage
record lengths, unexpected suffix characters,
invalid hex in skipped/unreachable records,
lowercase, SHA mismatch in a reached blob, bad
root, truncated index, and file immutability.
Tests compare additional malformed record cases
against M183, including an overlong line.

`tests/bench-m185-direct-skip.py` extends the
M184 read-only host fixture to M185. It uses a
15,360,000-byte deliberately unreachable blob,
three objects, 480,007 stage text lines per scan,
two forward scans and seven rotating Linux host
timing samples after warmup. All four readers must
produce exactly identical authenticated closure
and leave fixture stage/index checksums unchanged.
Only correctness and preservation affect CI success;
speed ordering does not.

The first valid shared Linux CI run recorded:
```text
M181 HOST MEDIAN 0.1211s MIN 0.1179s MAX 0.1444s
M182 HOST MEDIAN 0.0987s MIN 0.0985s MAX 0.1015s
M183 HOST MEDIAN 0.0908s MIN 0.0896s MAX 0.0924s
M185 HOST MEDIAN 0.0760s MIN 0.0759s MAX 0.0926s
```
The comparison is only an **observational Linux
host benchmark**, not a z/VM speedup. Further native
host CI reruns may yield different wall times.

## Native target validation, only after CI success

From the existing Mac `ibm-sandbox/src` directory:

```sh
git pull
./cms-upload.sh GITPH5M.C GITPH5.EXEC
```

On MAINT CMS, perform safe preflight and build:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
QUERY FILEDEF
STATE GITPH5M C A
CMSCLNK GITPH5M PLAIN
STATE GITPH5M MODULE A
```

Only after a successful native compile and no
conflicting caller STGIN/IDXIN FILEDEFs:

```text
GITPH5 G CCB18BEC067E7886D70B82EF138EE56A8B899A61
QUERY FILEDEF
```

Require complete marker and closure parity:
8 TREES, 272 BLOBS, 0 GITLINKS, 279 ENTRIES,
280 VERIFIED objects; index 7736 total/unique;
2 full forward scans, 15472 object-header visits,
0 seeks, 272 authenticated reachable blobs,
exactly 3864799 stage text records on each scan;
native and wrapper M185 terminal PASS as above.
Record CMS CPU/elapsed and post-run `QUERY FILEDEF`.
Compare actual elapsed with M181 **298.38s**.
Do not claim faster z/VM performance from host values.

No ERASE, FORMAT, index rebuild/reimport, G STAGE
or INDEX write, or write-link of physically overlapping
`PMAINT 0141` is authorized. Leave working M176–M184
and permanent `GIT600` intact. No old expensive
tests need repeating as prerequisites.
