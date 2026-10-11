# M188 — direct skipped-record fast end-of-line path

## Baseline and safety

Actual October 11 native z/VM 6.3 M185 compiled successfully
(`CMSCLNK GITPH5M PLAIN`) and passed complete authenticated
tree closure. Its performance is CPU **206.72s**,
elapsed **209.97s**. The root
`CCB18BEC067E7886D70B82EF138EE56A8B899A61`
has **8 trees, 272 blobs, 279 entries, 280 verified**,
7,736 total and unique index objects and two forward
scans of 3,864,799 stage text records each, 15,472
header visits and zero seeks. M181 earlier elapsed
298.38s, so M185 saves 88.41s (~29.6%). This is
measured real CMS evidence, not a Linux timing.

**No post-run `QUERY FILEDEF` was provided for
M185's successful invocation.** The reader success
does not independently prove REXX-owned DD cleanup.

M188 is a newly isolated C89 experiment; original
`GITPH5M.C`, `GITPH5.EXEC`, verified CMS modules,
protected G stage/index and other readers remain intact.
M188 is NOT real-CMS target-proven until a separate
mainframe run, and any Linux timing is observational.

## Isolated change

The new `src/GITPH8M.C` is a byte-for-byte
copy of target-proven M185 except for new name/
M188 status markers and a small common-case branch
in its bounded `skipline` suffix validation.
After validating **every** expected hex character,
it immediately accepts:
- LF then NUL;
- CR/LF then NUL;
- NUL at exactly the expected hex boundary.

For other endings it falls back to **M185's original
complete bounded suffix loop**, which accepts only
space, carriage return or line feed up to NUL,
rejects overlong/no-newline records at buffer cap,
and does not accept invalid suffix bytes.
Both line reading and record-counter updates remain
exactly as in M185: a full `fgets` on every skipped
CMS text record, no skipped/unauthenticated hex byte.
All reached tree and blob SHA-1 verification,
index/OID consistency, type/mode/name/depth/cycle
rules, 64 MiB resident cap, exactly two stage scans
and zero random seeks are unchanged.

The new `src/GITPH8.EXEC` invokes distinct
`GITPH8M MODULE A` (never itself); it retains
the protected stage/index preflight, non-A 4096
block G filemode check, caller FILEDEF conflict
refusal, temporary read FILEDEF ownership/clear,
root and native PASS count verification.
No protected data is written.

## Tests and next CMS gate

`tests/test-m188-fast-eol.py` strict C89
(`gcc -x c -std=c89 -Wall -Wextra -Werror`) proves
M178 closure parity and M185 differential result
parity, including LF, CRLF, trailing spaces,
whitespace-only/invalid suffix, malformed stage
record length, malformed hex, reached-blob SHA
corruption and truncated index. CMS/EXEC
line-width remains <= 80 and host fixture inputs
are restored. `tests/bench-m188-fast-eol.py`
adds M188 to the same seven-round rotating
disposable Linux fixture used for M181/M182/
M183/M185 and requires identical root closure,
2 sequential scans and untouched stage/index
SHA256. It prints host timings without using
performance as a CI pass criterion. **Host
comparisons do not predict real z/VM performance.**

The only legitimate deployment would be an
isolated target measurement after successful
host CI. From the existing Mac `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh GITPH8M.C GITPH8.EXEC
```

On CMS MAINT, check the 4096-byte G disk and
protected original data, then build ONLY the new
module:

```text
QUERY DISK G
STATE M173NET STAGE G
STATE M174NET INDEX G
QUERY FILEDEF
STATE GITPH8M C A
CMSCLNK GITPH8M PLAIN
STATE GITPH8M MODULE A
```

Proceed only on clean preflight/native compilation:

```text
GITPH8 G CCB18BEC067E7886D70B82EF138EE56A8B899A61
QUERY FILEDEF
```

The target gate requires root equality and exact
8 trees,272 blobs,279 entries,280 verified,
7736 indexed unique,2 forward scans,15472
headers,0 seeks,272 SHA-authenticated reached
blobs,3,864,799 stage text lines on each pass,
then `M188 FAST EOL VALIDATOR PASS`,
`M188 TREE CLOSURE PASS` and
`M188 VERIFIED FAST TREE TARGET GATE PASS`,
all RC0. Capture CPU/elapsed and final
`QUERY FILEDEF` to independently check DD cleanup.
Compare with the new real CMS M185 baseline
**206.72s CPU / 209.97s elapsed**.
Do not repeat completed M173 import/M174 index,
erase/formats, overwrite any old module, or
write-link overlapping PMAINT 0141.


## Observed M188 Linux host result (not CMS evidence)

Full native-stage Actions run
[38155760171](https://github.com/mostangrymike/ibm-sandbox/actions/runs/38155760171)
**PASS**, including native C89/regression, host read-only
and identical authenticated closure checks. The seven-run
rotating comparison on the same 15,360,000-byte unrelated
blob, 480,007 text-records-per-scan fixture printed:

```text
M181 HOST MEDIAN 0.1211s MIN 0.1188s MAX 0.1327s
M182 HOST MEDIAN 0.1003s MIN 0.0988s MAX 0.1008s
M183 HOST MEDIAN 0.0914s MIN 0.0899s MAX 0.0930s
M185 HOST MEDIAN 0.0766s MIN 0.0760s MAX 0.0890s
M188 HOST MEDIAN 0.0735s MIN 0.0718s MAX 0.0786s
M188 HOST TIMINGS ARE OBSERVATIONAL ONLY; NOT z/VM DATA
M188 PARITY AND READ-ONLY BENCHMARK PASS
```
M188 is slightly faster than M185 on this **Linux
host sample only**. CMS C library, EBCDIC, object
data, load and scheduler differ. Do not promote
the reader or claim CMS improvement without an
actual mainframe PASS and timing.

