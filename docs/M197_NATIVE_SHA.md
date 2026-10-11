# M197: Canonical Git object SHA-1 from disposable input

## Purpose

M197 introduces a stand-alone strict-C89 verification core,
`GITVO7M.C`, and distinct CMS REXX wrapper `GITVO7.EXEC`.
It validates one complete object represented as a bounded
header and hexadecimal body records. It reads only
`dd:OBJIN`, which the wrapper binds to a pre-existing
disposable `GITVRAW DATA A` file. Neither program accesses
or modifies the original G stage or index.

Input header: `OBJ number type size 40-hex-oid`.
Types 1..4 map to commit/tree/blob/tag. For size zero
exactly one empty body record is required; otherwise
body records are chunks of 32 binary bytes encoded as
at most 64 hex characters per record. The final record
must match the remaining decoded size exactly, without
extra records. The verifier rejects malformed headers,
sizes greater than 16 MiB, odd or invalid hex, mismatched
OID and changed, truncated or extra body records.

Successful verification independently calculates
canonical Git SHA-1 of
`type + space + decimal-size + NUL + binary-body`
and compares all 20 digest bytes to the expected OID.
Only a complete match returns RC0 and
`M197 READ ONLY FULL OBJECT SHA1 PASS`.

## Evidence boundary

Host CI builds the C source under
`-std=c89 -Wall -Wextra -Werror` and tests zero-size,
short and multiblock blob, tree, commit and tag vectors,
corruptions and preserved input SHA256. This is a
host-only SHA core. The live CMS FSREAD-to-disposable
input bridge has **not** been implemented; M197 does not
claim real target FSREAD or full-tree performance.

M193 and M194 passed real CMS at FIRST/MID/LAST.
M195's complete LAST body probe is merged and
host-proven but still requires live `GITFLP G LAST`.
M196's index-to-object plan is merged and host-proven
but still requires live `GITRP6 G 7736 10`.
M188 remains the real authenticated closure baseline,
208.27s elapsed.

## Next gated implementation

Complete M195 and M196 CMS runs before integrating
an isolated read-only FSREAD adapter that copies a
single validated object into a collision-checked
disposable scratch file. No original G file may be
written, reformatted, reindexed or replaced.

The M197 program can be built independently with
`CMSCLNK GITVO7M PLAIN`, but `GITVO7` must not
be run until an independently verified disposable
`GITVRAW DATA A` source and its expected OID exist.

Never overwrite proven M185/M188/M193/M194/M195
modules or write-link the overlapping PMAINT 0141
fullpack. Do not run M190's unverified 272-seek walk.
