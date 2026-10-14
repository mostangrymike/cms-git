# Native Git generation, external-ref and ref-resolution records

## Archived original: docs/GENERATION_RECOVERY.md

# GEN2 candidate-generation seal and restart validation

## Status and safety boundary

The canonical 1,808-object GITFIX stage, IDX2 index, and SIDX2
seek index have each passed complete real-CMS readback and hash
verification. GITCIDX SFAST and PAIR also passed on the target
with every saved seek position reconciled against the actual
unchanged staging file.

New `GITCIDX GENWRITE` and `GENCHECK` are **host-tested only**.
They provide a candidate-generation **completion manifest**, not
an atomic CMS object-store transaction or an active-generation
pointer. No code changes or truncates the existing stage/index/seek
files. A manifest must be written to a *new* candidate filename,
not over a previously verified active generation.

`GENWRITE` first runs PAIR (full independent stage readback,
canonical SHA verification and IDX2/SIDX2 metadata/cookie matching).
Only after this passes does it write the separate GEN2 manifest
through FILEDEF `GENOUT`. Its record grammar is:

```text
GEN2 1808 1808
DIGEST <40 uppercase hex bytes>
MINOID <40 uppercase hex bytes>
MAXOID <40 uppercase hex bytes>
GEND2 1808 1808
```

The unique count is derived rather than assumed; `1808` is the
currently verified real-PACK value. The digest binds every
**sorted** canonical OID plus its object ordinal, type, size,
and saved seek-position cookie. Each descriptor is encoded as
20 raw OID bytes, 2-byte big-endian ordinal, 1-byte type,
4-byte big-endian length, and 4-byte big-endian cookie.
Canonical Git blob hashing over these concatenated metadata bytes
generates the 40-character DIGEST. All records fit LRECL 80.
No CMS-native EBCDIC type/decimal header enters that hash.

`GENCHECK` must reject an absent, truncated, malformed, legacy
or extra-record manifest. It independently reopens all three
candidate data files, runs the complete paired canonical content
audit, recomputes the deterministic descriptor digest, and requires
matching unique count, min/max OID, and digest. The final GEND2
record detects incomplete manifest writes. A changed stage,
inconsistent index, altered cookie or mismatched manifest fails
closed.

Host CI passed synthetic 1,808-object sealing and reopening,
deliberate header corruption, truncated-manifest rejection,
restoration, corrupt staged body and mismatched seek descriptor:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36282365907 .
This is not yet CMS compilation or cross-logon/reboot evidence.

## Isolated CMS gate

The canonical GITFIX STAGE/INDEX/SEEK files are unchanged;
do not rerun the saved PACK or rewrite either index.

On the Mac, in `/Users/mikewommack/ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/GITCIDX.C
```

On CMS, compile before FILEDEFs and choose a **new manifest**
file `GITFIX GEN A`, rather than replacing any old generation:

```text
CMSCLNK GITCIDX PLAIN
FILEDEF STGIN DISK GITFIX STAGE A
FILEDEF IDXIN DISK GITFIX INDEX A
FILEDEF FIDXIN DISK GITFIX SEEK A
FILEDEF GENOUT DISK GITFIX GEN A (RECFM V LRECL 80
FILEDEF GENIN DISK GITFIX GEN A
GITCIDX GENWRITE
GITCIDX GENCHECK
```

These operations are intentionally redundant:
GENWRITE hashes every staged body via PAIR before writing
the manifest, and GENCHECK reopens everything and does so again.
Both must return RC 0 and report:

```text
FAST AUDIT VERIFIED 1808 UNIQUE 1808
PAIR VERIFIED UNIQUE 1808
GENERATION SEALED 1808 UNIQUE 1808
GENERATION VERIFIED 1808 UNIQUE 1808
```

To prove *cross-logon* persistence later, log off and back on,
reaccess A and rebind STGIN, IDXIN, FIDXIN and GENIN to the
same existing GITFIX files. Re-run only `GITCIDX GENCHECK`;
do not rewrite the manifest. For a reboot test, repeat after
an authorized system restart, not as part of this initial gate.
The manifest intentionally binds saved ftell cookies, so moving
or rewriting the stage can invalidate the seek index even when
the content OIDs remain unchanged. Rebuild/verify a **new**
candidate generation instead of overwriting an attested one.

## Remaining transaction work

GEN2 is a completion proof for one unmodified candidate dataset,
not an atomic multi-file rename, lock, active-generation selector,
concurrent writer protocol or automatic rollback. Those need
separate design and recovery tests before claiming a durable
transactional Git object database. GitHub issue #2 remains open.

### Latest consolidated CI

The host suite including GEN2 writes, fresh readback, malformed
and truncated manifest rejection, stage-body tampering and seek-index
descriptor mismatches passed again together with forward/external
REF tests:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36282493293 .
The synthetic fixture has 1,808 records but 8 unique OIDs;
the real target generation has 1,808 unique OIDs and is not yet
GEN2-sealed on CMS. Only the target can establish cross-logon and
reboot durability; the manifest is not an atomic promotion scheme.

## Actual CMS GEN2 candidate sealing and rechecking: PASSED

At 19:39–19:40 CDT September 26, 2026, the user compiled the updated
GITCIDX under `CMSCLNK GITCIDX PLAIN` without assembler flags.
GENOUT and GENIN were bound to newly created `GITFIX GEN A`,
with the existing untouched canonical GITFIX STAGE, INDEX and SEEK
files as inputs. `GENWRITE` performed a complete SFAST and PAIR
(1,808 unique objects, all canonical SHA and seek cookies rechecked),
then printed `GENERATION SEALED 1808 UNIQUE 1808` in 21.56 s
elapsed. The separate `GENCHECK` invocation reread the manifest,
independently reran all SFAST/PAIR checks, and printed
`GENERATION VERIFIED 1808 UNIQUE 1808` in 21.57 s elapsed.

This demonstrates completed-manifest validation across separate
invocations on the same current CMS session. The manifest itself and
all three canonical datasets must be preserved unchanged for a
subsequent logoff/logon test. Neither cross-logon nor reboot survival
has yet been demonstrated. These tests are also not an atomic
multi-file commit, concurrent-writer lock or active-generation switch.

### Read-only cross-logon check (next durability gate)

After an ordinary user-initiated CMS logoff and logon, check that
the same A disk is accessed read/write, then reissue only the four
input definitions if absent:

```text
FILEDEF STGIN DISK GITFIX STAGE A
FILEDEF IDXIN DISK GITFIX INDEX A
FILEDEF FIDXIN DISK GITFIX SEEK A
FILEDEF GENIN DISK GITFIX GEN A
GITCIDX GENCHECK
```

Require the full `GENERATION VERIFIED 1808 UNIQUE 1808` result;
do not run GENWRITE or recreate GITFIX GEN. This is a separate
user-controlled test, not a reason to disrupt the current system.

### September 27: indexed external REF separately passed

XSEEK and XSAPPLY both passed on actual CMS against the real GITFIX generation, verifying/reconstructing the 270-byte first commit via SIDX2 direct seek in 0.19 and 0.18 seconds elapsed respectively. The original 1,808-object stage, both indexes and the GEN2 seal remain intact. Cross-logon GENCHECK has not been run yet and should remain a read-only user-controlled next durability gate; avoid GENWRITE or reinitializing any protected files.

## 2026-09-27 10:20–10:21 CDT: GEN2 cross-logon survival PROVEN ON CMS

After an actual logoff and fresh CMS logon, the user successfully defined STGIN GITFIX STAGE A, IDXIN GITFIX INDEX A, FIDXIN GITFIX SEEK A and GENIN GITFIX GEN A. They ran only `GITCIDX GENCHECK`, without rewriting the stage, indexes, or GEN2 manifest. The existing program printed all SFAST progress checkpoints (256 to 1792), `FAST AUDIT VERIFIED 1808 UNIQUE 1808`, `PAIR VERIFIED UNIQUE 1808`, and `GENERATION VERIFIED 1808 UNIQUE 1808`, with normal RC 0, CPU 21.47 sec and elapsed 21.68 sec. This now conclusively establishes **same minidisk cross-logon CMS persistence** for this validated, unmodified full canonical 1,808-object candidate generation, including stage body integrity, both index descriptors, saved seek-cookie correspondence and manifest digest. It does NOT establish survival across an actual system restart or atomic active-generation promotion/multi-writer safety. Protect GITFIX STAGE/INDEX/SEEK/GEN A; no need to rerun GENWRITE or recapture the PACK. The next user-controlled, read-only durability gate, only when a regular system reboot is appropriate, is to reaccess the same A minidisk and reissue the four input FILEDEFs followed by GITCIDX GENCHECK. Concurrent with target work, independently design active-generation selection and interrupted-promotion recovery in GitHub, without claiming an untested atomic CMS file rename guarantee.

---

## Archived original: docs/INDEXED_EXTERNAL_REF.md

# Indexed external REF_DELTA: isolated CMS performance gate

## Target-proven baseline

The 1,808-object canonical GITFIX STAGE A, IDX2 and SIDX2
indexes and GEN2 sealed manifest passed all CMS audit and separate
GENCHECK invocations. FPACK has reconstructed both chained forward
REF_DELTA objects on CMS. XPACK has verified and reconstructed the
270-byte first commit from the actual GITFIX stage through XREAL
PACK A, using canonical commit OID
00D8D63229305230C8D37F884CE87F9E1A89468C.
The sequential XREAL scan took 8.17 seconds elapsed because XPACK
checks all 1,808 staged records for absent, duplicate and malformed
matching bases. Existing XPACK remains available and unchanged.

## New optional XSEEK and XSAPPLY modes

GITCWALK XSEEK/XSAPPLY use FILEDEF EXIDX to read the complete
SIDX2 seek index, select the matching 20-byte canonical Git OID
and obtain its saved ftell cookie. The index must have the correct
SIDX2/SEND2 envelope and sorted, unique records. The selected
external object is read via fseek on FILEDEF EXTIN, with exact
ordinal, type, size and OID comparisons and independently
recomputed canonical Git SHA-1 of the reconstructed body. Its
verified bytes then form the base of the native REF_DELTA.

XSEEK computes the final object's OID; XSAPPLY tests the
apply-only path with no final OID printing. Neither changes
the PACK, stage, index or GEN2 manifest. They do not replace
full GEN2 integrity checking or make a new active-generation
pointer. The production stage/index pair must already have
passed SFAST/PAIR/GENCHECK; indexing a maliciously substituted
stage is not a substitute for full generation attestation.

Host integration includes synthetic first- and later-record
indexed lookups, stale saved-cookie rejection, truncated index
rejection and selected-body tamper rejection. Complete suite
passed:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36283446044 .
CMS runtime and actual performance are **not yet tested**.

## Minimal actual CMS gate

The current GITFIX STAGE A, GITFIX SEEK A, GITFIX INDEX A and
GITFIX GEN A are already complete. There is no need to rebuild
them or recapture the live GitHub PACK.

On the Mac, from /Users/mikewommack/ibm-sandbox/src, use the
existing single c3270-based uploader:

```sh
git pull
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/GITCWALK.C
```

On CMS, compile before defining the DD names; make sure that
XREAL PACK A was preserved from the earlier successful target run.
If the named DD definitions already exist, first clear only
those actual old definitions that point elsewhere. In a fresh
CMS process, these commands can be entered directly:

```text
CMSCLNK GITCWALK
FILEDEF PACKIN DISK XREAL PACK A
FILEDEF EXTIN DISK GITFIX STAGE A
FILEDEF EXIDX DISK GITFIX SEEK A
GITCWALK XSEEK
GITCWALK XSAPPLY
```

Required XSEEK markers:

```text
EXTERNAL SEEK VERIFIED TYPE 1 SIZE 270
OID OBJ 1 TYPE 1 SIZE 270 00D8D63229305230C8D37F884CE87F9E1A89468C
PASS 1 OBJECTS NEXT OFFSET 48
REF DELTAS APPLIED 1
```

XSAPPLY must independently report the verified external type
and size, one applied REF delta, and successful PACK completion
without printing a final OID. Measure actual CMS CPU/elapsed
time for both commands; compare the observed XSEEK result with
the previous *single-run* XPACK XREAL elapsed time of 8.17 s.

For subsequent cross-logon durability validation, avoid
overwriting GITFIX GEN A and only rebind the four required input
FILEDEFs and run GITCIDX GENCHECK after logging back on. Reboot
persistence and atomic generation promotion are separate gates.

## Real CMS XSEEK performance and correctness PASSED

On September 27, 2026 at 10:09–10:10 CDT, the user compiled the updated GITCWALK under CMSCLNK NAPI with three clean Assembler XF passes (6.44/6.72 sec CPU/elapsed). XSEEK on the existing XREAL PACK A, EXIDX GITFIX SEEK A and EXTIN GITFIX STAGE A validated the full 68-byte thin PACK, selected and independently rehashed the actual persisted first commit (TYPE 1 SIZE 270), applied one REF delta and returned its canonical OID 00D8D63229305230C8D37F884CE87F9E1A89468C, PASS 1 OBJECTS NEXT OFFSET 48, in 0.17/0.19 sec. XSAPPLY also verified the base and applied the REF successfully without ordinary OID printing in 0.17/0.18 sec. Historical sequential XPACK on the same actual commit took 8.05/8.17 sec; timings are individual observations, not a controlled benchmark. This proves SIDX2-indexed external REF direct access on the actual CMS stage without changing GITFIX or GEN2. Cross-logon/reboot GEN2 durability is still untested; keep protected files intact.

### Post-validation source hardening

After the CMS success, XSEEK's SIDX2 reader was additionally hardened to reject unsorted or duplicate OIDs, with the host multi-record fixture generator updated to produce canonical sorted entries. The full host CI passed at https://github.com/mostangrymike/ibm-sandbox/actions/runs/36328763996 . This incremental source change has not yet been recompiled on CMS. The preceding XSEEK and XSAPPLY functional behavior itself is independently target-proven by the September 27 logs. Existing GITFIX data needs no changes.

---

## Archived original: docs/REF_RESOLUTION.md

# M13 next isolated CMS gate: external and forward REF_DELTA

## Verified baseline

On September 26, 2026, z/VM CMS compiled the corrected native C
walker and indexer. The positive three-object backward chained REF
fixture passed with Git-compatible OIDs and two REF_DELTA applications.
The original 1,808-object saved PACK was then rebuilt offline into
`GITFIX STAGE A`, `GITFIX INDEX A` (IDX2), and
`GITFIX SEEK A` (SIDX2). Independent VERIFY, AUDIT, SFAST and PAIR
all passed with 1,808 unique canonical OIDs. Original PACK checksum:
`8C92E274ECA84B797F8925A6082915DD6CCDE196`.

The canonical first commit is
`00D8D63229305230C8D37F884CE87F9E1A89468C`, size 270.
The canonical last tree is
`EB37E3F23FF4FC137D715D71A711D3B7632D75F2`, size 5,224.
Both were retrieved via target SGET. Do not repeat full PACK capture,
reconstruction or indexing for this experiment. Preserve historical
IDX1/SIDX1 as legacy and the new GITFIX generation as validated.

## Independent implementation and host results

The updated `GITCWALK.C` adds two **isolated, optional** modes:
`XPACK`/`XAPPLY` resolve a missing REF base by scanning bounded
CMS text records from FILEDEF `EXTIN`. They require a matching
40-byte canonical Git OID and recompute the selected external
object's SHA-1 over the actual body before using it. Malformed,
duplicated, unprovided and altered external bases fail closed.
`FPACK` defers unresolved forward same-PACK REF_DELTA instructions,
then completes multi-pass dependency resolution once later objects
have been inflated and hashed. A three-object fixture contains
two chained forward deltas followed by their ordinary base.

Separate host fixtures are generated with
`tests/make-native-ref-pack.py`. They cover chained forward
dependencies, previously proven backward deltas, absent/forward
negative resolution, external single/multiple staged records,
duplicated/altered/missing staged base OIDs, and a real target
first-commit no-op copy delta. The host adapter substitutes zlib
only for the native CMS inflater. Git itself independently
accepts the backward and forward PACKs via `git index-pack`
and reconstructs all three blobs with `git cat-file`.
All host regressions passed in
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36282246527 .

These new modes are **not yet CMS validated**. They do not replace
the target-proven original STAGE, RPACK, RTEST, IDX2 or SIDX2 paths.

## Exact isolated target test

Mac commands from `/Users/mikewommack/ibm-sandbox/src`; use
the already running single c3270 through the existing uploader:

```sh
git pull
python3 ../tests/make-native-ref-pack.py .
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/GITCWALK.C
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/FCHAIN.PACK
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/XPACK.PACK
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/XBAD.PACK
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/XREAL.PACK
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/EXTBASE.DATA
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/EXTMULT.DATA
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/EXTBAD.DATA
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/EXTMISS.DATA
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/EXTDUP.DATA
```

On CMS, compile **before** FILEDEF; none of these tests writes
to GITFIX or the historical stage/index/seek files.

```text
CMSCLNK GITCWALK
FILEDEF PACKIN DISK FCHAIN PACK A
GITCWALK FPACK
FILEDEF PACKIN CLEAR
FILEDEF PACKIN DISK XPACK PACK A
FILEDEF EXTIN DISK EXTBASE DATA A
GITCWALK XPACK
GITCWALK XAPPLY
FILEDEF EXTIN CLEAR
FILEDEF EXTIN DISK EXTMULT DATA A
GITCWALK XPACK
FILEDEF PACKIN CLEAR
FILEDEF PACKIN DISK XREAL PACK A
FILEDEF EXTIN CLEAR
FILEDEF EXTIN DISK GITFIX STAGE A
GITCWALK XPACK
```

Expected positive markers for FCHAIN: `FORWARD REF OBJ 2`
(type 3, 4 bytes, `85DF50785D62D3B05AB03D9CBF7E4A0B49449730`),
then `FORWARD REF OBJ 1` (type 3, 5 bytes,
`6A8165460570531A1247BD99A73B53A5A6E500D5`), ending
`PASS 3 OBJECTS` and `REF DELTAS APPLIED 2`.

Both XPACK and XAPPLY with EXTBASE must verify an external
blob of 3 bytes and reconstruct Git blob `abcd`, OID
`85DF50785D62D3B05AB03D9CBF7E4A0B49449730`.
The EXTMULT stage stores the matching base as record #2;
it must produce the same result. The XREAL fixture is a
single REF_DELTA copy of the already-validated first commit
from the full GITFIX stage, proving actual persisted external
lookup. Expected output: `EXTERNAL REF BASE VERIFIED TYPE 1
SIZE 270` and an ordinary reconstructed type 1 / 270-byte
object with the *same* commit OID
`00D8D63229305230C8D37F884CE87F9E1A89468C`.

### Negative CMS fixtures

Only after the positive gates pass, keep changes isolated by
redefining existing FILEDEFs between tests:

```text
FILEDEF PACKIN CLEAR
FILEDEF PACKIN DISK XPACK PACK A
FILEDEF EXTIN CLEAR
FILEDEF EXTIN DISK EXTBAD DATA A
GITCWALK XPACK
FILEDEF EXTIN CLEAR
FILEDEF EXTIN DISK EXTMISS DATA A
GITCWALK XPACK
FILEDEF EXTIN CLEAR
FILEDEF EXTIN DISK EXTDUP DATA A
GITCWALK XPACK
FILEDEF EXTIN CLEAR
FILEDEF EXTIN DISK EXTBASE DATA A
FILEDEF PACKIN CLEAR
FILEDEF PACKIN DISK XBAD PACK A
GITCWALK XPACK
```

All four negative invocations must return RC 8. The corrupted
and duplicated stage cases must report `INVALID EXTERNAL
STAGE RECORD`; absent or unmatched OIDs must report
`UNRESOLVED REF BASE OBJ 1`. A malformed or absent external
source must never be silently accepted.

## Scope and remaining gaps

FPACK currently resolves forward **REF_DELTA** chains when their
base objects are available later in the same PACK. An OFS_DELTA
that depends on a still-deferred REF object is not yet supported;
neither is a cyclic unresolved dependency. XPACK uses a verified
separate stage for external bases but does not yet perform a
content-addressed indexed lookup; it scans the external stage.
These are optional test modes, not a complete production Git
receive-pack implementation.

Full canonical stage/index consistency is target-proven. A
transactional commit marker, restart/reboot readback and safe
generation recovery remain separate work under GitHub issue #2.

### Latest consolidated host evidence

The expanded host suite passed after adding strict short-OID rejection,
a structurally valid later-record external base, duplicate-record
rejection and a real-target first-commit copy fixture. The latest
complete run is
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36282493293 .
Only the updated GITCWALK C source and newly generated small
fixture files need CMS transfer. No new network PACK or rebuilding
of the existing 1,808-object GITFIX generation is necessary.
The optional malformed short-OID stage fixture is EXTSHORT DATA A;
when bound to EXTIN with XPACK PACK A, XPACK must return RC 8 and
print INVALID EXTERNAL STAGE RECORD 1.

## Actual CMS forward/external REF validation: PASSED

At 19:36–19:38 CDT September 26, 2026, the updated GITCWALK NAPI
module compiled with three clean Assembler XF passes. FPACK validated
FCHAIN PACK A (SHA-1 `0F5F312E5E584C32B83488C4AEDF9D2786806884`,
114 bytes, three objects), reconstructed ordinary object #3 blob abc,
then resolved both forward dependencies: #2 abcd, Git OID
`85DF50785D62D3B05AB03D9CBF7E4A0B49449730`; #1 abcde,
Git OID `6A8165460570531A1247BD99A73B53A5A6E500D5`.
All three objects completed and both REF deltas applied, 0.04 s
elapsed.

XPACK with the separate EXTBASE DATA A verified a 3-byte blob
external base, applied one REF and reconstructed abcd with the
correct Git OID in 0.02 s elapsed. XPACK with the **actual existing
GITFIX STAGE A** verified the canonical persisted 270-byte first
commit, then applied XREAL's thin copy delta and produced the same
Git OID `00D8D63229305230C8D37F884CE87F9E1A89468C`,
8.17 s elapsed. This verifies a real stored external base, not just
a synthetic in-memory fixture. It takes longer because XPACK scans
all 1,808 external stage records before accepting a base so that
malformed or duplicate matching records cannot be silently ignored.

The current transcript does not show standalone XAPPLY, EXTMULT or
the four optional negative fixture executions on CMS; those remain
host tested. The already validated GITFIX stage and both canonical
indexes were unchanged. This experimental lookup is sequential,
not indexed. Full GEN2 sealing and reopening also passed on CMS;
see [generation recovery](GENERATION_RECOVERY.md).

### Target-proven indexed external REF

The optional XSEEK and XSAPPLY modes subsequently passed on actual CMS on September 27, 2026. Using XREAL PACK A, EXIDX GITFIX SEEK A and EXTIN GITFIX STAGE A, both independently validated the real stored first commit (TYPE 1, SIZE 270) via its canonical Git OID. XSEEK produced 00D8D63229305230C8D37F884CE87F9E1A89468C and completed in 0.19 sec elapsed; XSAPPLY completed in 0.18 sec. XPACK's prior sequential lookup took 8.17 sec elapsed in a separate run. The original canonical stage/indexes/GEN2 files were not altered. See docs/INDEXED_EXTERNAL_REF.md.


---

## Original: docs/CANONICAL_OIDS.md (complete original record)

# Canonical Git object IDs on EBCDIC CMS

## Confirmed September 26, 2026 failure

The user ran the updated native REF-capable GITCWALK on real CMS.
Its compiler succeeded, and its REFPACK trailer checksum matched
`9CD9B4CCFA5D5371C608230D3157F4766248355F`.
But the first blob, whose decompressed bytes are ASCII `abc`, was
reported with OID `5492DC378EC7097F3437B18BE17F4C58D0923A03`.
The fixture's subsequent REF_DELTA correctly references Git's real
blob ID `F2BA8F84AB5C1BCE84A7B441CB1959CFC7093B7F`.
Thus RPACK/RAPPLY both failed locating the second object's base.
The old in-memory RTEST printed an unrelated
`0414AADE456A43A390C3A0E689DD2CDE0439DAA7` but declared
success, because it never checked a known external Git OID.

The root cause is now verified, not a suspected inflater problem.
Before this correction, GITCWALK object_oid/fast_oid and GITCIDX
idx_hash constructed Git's binary `type size NUL body` input with
`sprintf` over CMS-native EBCDIC type names, space and digits.
For `blob 3\0abc`, CMS produced this incorrect preimage:

```text
82 93 96 82 40 F3 00 61 62 63
```

SHA-1 of these exact bytes is the incorrect `5492DC37...`.
Git requires ASCII header bytes:

```text
62 6C 6F 62 20 33 00 61 62 63
```

SHA-1 of these bytes is `F2BA8F84...`, independently validated
by Git `hash-object`. For `blob 5\0abcde`, the correct Git
OID is `6A8165460570531A1247BD99A73B53A5A6E500D5`.
The selftest's body bytes were also CMS-native before the fix;
they are now explicit hexadecimal ASCII.

## Committed correction and compatibility boundary

The current GitHub main branch changes both programs:

- `src/GITCWALK.C` has `canonical_head`, constructing the raw
  ASCII type, space (0x20), decimal digits (0x30–0x39) and NUL
  using explicit byte values. Both object_oid and fast_oid use it.
  RTEST now checks the known raw `blob 3 NUL` header plus the
  actual Git SHA-1 results for `abc` and `abcde`.
- `src/GITCIDX.C` uses its own explicit ASCII `idx_head` in
  every OID calculation. `GITCIDX SELF` checks `blob 3\0abc`
  against Git's known hash, without accessing any stage file.
  The index formats are bumped from `IDX1` to `IDX2`, and
  `SIDX1` to `SIDX2`, with new matching END2/SEND2 markers.
  New code fails closed on old index formats.
- `GITCIDX SVAUDIT` additionally independently reopens and
  SHA-1-checks **every** stored direct-seek cookie in the new
  index. It prints progress every 256 unique objects.
- CI guards reject any reintroduction of native-text sprintf
  for canonical object headers. Synthetic host regression tests
  check full stage/index, REF chains, malformed and legacy index
  version rejection, independently accepted Git PACK, and
  direct-seek audit including corruption rejection.

Both old and optimized C SHA-1 compression algorithms were
previously byte-for-byte equal on 1,808 target objects, but
they shared the same **incorrect EBCDIC canonical header**.
Consequently, prior positive CMS STAGE/VERIFY/AUDIT results
proved file integrity and consistency, not Git interoperability.
The old GITSTAGE DATA A and GITINDEX DATA A / GITSEEK INDEX A
contain incorrect OIDs and must **not** be used as a production
Git object database. Their unpacked object body bytes and
verified raw PACK are still useful. They are preserved as
historical artifacts until a correct, independently checked
replacement is target-validated.

The inspected REXX `GITBOID.EXEC` and `GITOID.EXEC` already
construct ASCII type/space/decimal/NUL **in hexadecimal**;
they do not use this C-specific native-text header path.
This does not establish every other REXX path independently.

## Target validation and safe rebuild (not yet completed)

The next target test requires no live network download. Use the
existing positive REFPACK PACK A, the already saved
GITPBUF PACK A and new *separate* output file names. Do not
overwrite old GITSTAGE or either legacy index.

On the Mac, in `ibm-sandbox/src`:

```sh
git pull
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/GITCWALK.C
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/GITCIDX.C
```

Compile both programs before defining file DD names:

```text
CMSCLNK GITCWALK
CMSCLNK GITCIDX PLAIN
GITCWALK RTEST
GITCIDX SELF
FILEDEF PACKIN CLEAR
FILEDEF PACKIN DISK REFPACK PACK A
GITCWALK RPACK
GITCWALK RAPPLY
```

Expected: RTEST prints `CANONICAL ABC OID` equal to the correct
F2BA... OID and `REFTEST OID` equal to the correct 6A816... OID.
GITCIDX SELF prints `INDEX CANONICAL ASCII ABC PASSED`.
RPACK must produce exactly 3 objects, 2 REF_DELTA applications,
and the expected Git OIDs of abc, abcd and abcde. RAPPLY must
also resolve both REF bases. An unexpected RC 8 is a stop gate.

If all the preceding pass, the independent offline rebuild can
use the existing 340,027-byte PACK but **new files**:

```text
FILEDEF PACKIN CLEAR
FILEDEF PACKIN DISK GITPBUF PACK A
FILEDEF OBJOUT CLEAR
FILEDEF OBJOUT DISK GITFIX STAGE A (RECFM V LRECL 80
GITCWALK STAGE
GITCWALK VERIFY
FILEDEF STGIN CLEAR
FILEDEF STGIN DISK GITFIX STAGE A
FILEDEF IDXOUT CLEAR
FILEDEF IDXOUT DISK GITFIX INDEX A (RECFM V LRECL 80
FILEDEF IDXIN CLEAR
FILEDEF IDXIN DISK GITFIX INDEX A
GITCIDX BUILD
GITCIDX CHECK
GITCIDX AUDIT
FILEDEF FIDXOUT CLEAR
FILEDEF FIDXOUT DISK GITFIX SEEK A (RECFM V LRECL 80
FILEDEF FIDXIN CLEAR
FILEDEF FIDXIN DISK GITFIX SEEK A
GITCIDX SBUILD
GITCIDX SCHECK
GITCIDX SVAUDIT
```

The corrected real-PACK commit/tree OIDs will be **different**
from the previously printed legacy `5A81...` and `BA9F...`.
Do not write down hypothetical replacements. The target
GITCWALK STAGE output supplies the actual first/last values,
which can then be compared with independent Git data if the
corresponding raw object bytes are available. Never promote or
erase legacy files before all new gates succeed.

Remaining milestones: target-proven canonical headers and backward
REF_DELTA, correct fresh stage/index, persisted external and forward
REF_DELTA support, and safe committed/recoverable storage. GitHub
issue #2 remains open. Follow maximum-work-per-turn rule; CMS
runtime behavior requires actual target validation.

## Current independent validation evidence

The full C89 host regression, explicit ASCII source guard, backward
REF fixture verified through real Git index-pack/cat-file, canonical
GITCWALK RTEST and GITCIDX SELF, IDX1/SIDX1 rejection, corrupted-stage
negative tests, and full direct-seek SVAUDIT all pass:

https://github.com/mostangrymike/ibm-sandbox/actions/runs/36275050558

The CMS staging migration has not yet been run with these fixes.
Expected positive summaries when the new target test succeeds are:

```text
CANONICAL ABC OID F2BA8F84AB5C1BCE84A7B441CB1959CFC7093B7F
REFTEST OID 6a8165460570531a1247bd99a73b53a5a6e500d5
INDEX CANONICAL ASCII ABC PASSED
REF DELTAS APPLIED 2
STAGED OBJECTS 1808
STAGE VERIFIED OBJECTS 1808
INDEX WRITTEN 1808 UNIQUE 1808
INDEX VERIFIED 1808 UNIQUE 1808
AUDIT VERIFIED 1808 UNIQUE 1808
SEEK INDEX WRITTEN 1808 UNIQUE 1808
SEEK INDEX VERIFIED 1808 UNIQUE 1808
SEEK AUDIT VERIFIED UNIQUE 1808
```

In addition, the old index versions can be tested nondestructively
by pointing IDXIN at GITINDEX DATA A and FIDXIN at GITSEEK INDEX A
and running CHECK and SCHECK after compilation; both must reject
IDX1/SIDX1 with RC 8. Do this only before rebinding those FILEDEFs
to the new GITFIX files. Do not accept a failure from the legacy
source as proof of the new code; RTEST and SELF are authoritative
for the canonical hash correction on CMS.

## September 26 CMS validation completed

The corrected RTEST and index SELF both passed on the target. RPACK verified the 114-byte fixture and produced Git-compatible IDs for abc, abcd and abcde. Both backward chained REF deltas applied. RAPPLY also passed with on-demand OID resolution. The four malformed external fixture cases have not been run on CMS. The prior full 1,808-object stage and indexes remain legacy and must be preserved.

The next target-only step uses the existing corrected binaries and saved original GITPBUF PACK A. No transfer, compile or new network request is needed. Run the offline GITFIX STAGE, VERIFY, BUILD/CHECK/AUDIT and SBUILD/SCHECK/SVAUDIT commands in the preceding section. Require all 1,808 reconstructed objects, full independent readback and both complete canonical IDX2/SIDX2 audits. Record the new first and last OIDs from target output rather than assuming old OIDs. Do not overwrite legacy files before full independent validation.

### Optional further verification: matching two canonical indexes

A new, separate GITCIDX PAIR mode is committed after the CMS RTEST/
RPACK success. It compares every IDX2 and SIDX2 entry's canonical
OID, ordinal, type and length, then invokes a full direct-seek
content rehash to confirm that every cookie still resolves to the
correct bytes in STGIN. It fails if either index is stale, the stage
body is altered, or a stored cookie is invalid. Host CI covers both
matching and deliberately mismatched index descriptors, valid-hex
stage corruption and recovery:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36280431393 .

The GITCIDX binary used for the successful SELF test may precede
PAIR. The base 1,808-object migration above needs no new transfer;
run its existing VERIFY, AUDIT and SVAUDIT gates first. To add PAIR,
transfer the latest src/GITCIDX.C through the existing uploader,
compile with CMSCLNK GITCIDX PLAIN, reestablish STGIN, IDXIN and
FIDXIN FILEDEFs pointing at the new GITFIX files, then run
GITCIDX PAIR. Expected final marker is
PAIR VERIFIED UNIQUE 1808. No legacy file is overwritten and
PAIR does not modify the stage or either index.

### Separate negative REF fixture target gate (after canonical migration)

The positive CMS transcript did not include the four transferred
negative fixtures. If REFBAD, REFFWD, REFSIZE and REFSHA PACK A are
still present, verify that each correctly returns CMS RC 8 after
setting its own PACKIN. The expected diagnostic sequence is:
`UNRESOLVED REF BASE OBJ 2`, `UNRESOLVED REF BASE OBJ 1`,
`FAIL NATIVE DELTA APPLY`, and `FAIL NATIVE PACK SHA1`.
The host suite already checks all four cases with recomputed
checksums where appropriate. This additional CMS fixture test uses
only separate fixture files and does not modify GITPBUF or the
staging/index datasets. It is not a substitute for the full
canonical stage migration or its readback verification.

## Actual 1,808-object canonical migration: stage and indexes passed

September 26, 2026 target output from the saved GITPBUF PACK A
confirmed the correct raw PACK SHA-1, all 1,117 OFS_DELTA operations,
and 1,808 newly reconstructed canonical object OIDs. The new
GITFIX STAGE A file was written in 25.16/25.58 s CPU/elapsed;
independent GITCWALK VERIFY rehashed all 1,808 records in
22.37/22.57 s. The correct real-PACK first commit OID is
00D8D63229305230C8D37F884CE87F9E1A89468C (270 bytes);
the last tree OID is
EB37E3F23FF4FC137D715D71A711D3B7632D75F2 (5224 bytes).
Do not use the historical legacy first/last values.

The separate GITFIX INDEX A IDX2 file was built (6.86/6.94 s),
checked twice and fully AUDIT-verified (20.86/20.99 s):
1,808 unique entries. GITFIX SEEK A SIDX2 was built
(7.29/7.39 s), checked and found structurally valid with
1,808 unique entries. The original SVAUDIT emitted progress
through 256, but the user reported severe slowness before
completion. It must **not** be marked target-passed.

The slow code repeatedly reopened STGIN, once for each of the
1,808 OIDs. New GitHub code optimizes old SVAUDIT to use one
open stream, and offers a more efficient SFAST full canonical
audit: one sequential read of all staged bodies, an independent
hash check of each body, matching SIDX2 metadata and precise
saved-ftell-cookie agreement on the reopened STGIN. PAIR
compares the complete IDX2/SIDX2 descriptor sets and then
runs SFAST instead of 1,808 individual reopen/seek operations.
Host synthetic corruption, mismatched-index and open-count
regressions PASSED:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36281295118 .
Target execution of the **new optimized audit code** is pending.

### Only next required CMS test: SFAST and PAIR

All corrected GITFIX files have already been created. Do not
re-download the live PACK, repeat STAGE, repeat index BUILD,
overwrite GITFIX, or erase the old historical files.

If the old read-only SVAUDIT is still running, PA1 may interrupt
that operation. The existing GITFIX STAGE/INDEX/SEEK files
remain valid; an interrupted read-only audit is not evidence of
file corruption. On the Mac, in the existing ibm-sandbox/src
working directory, with the same one-instance c3270 uploader:

```sh
git pull
./cms-upload.sh /Users/mikewommack/ibm-sandbox/src/GITCIDX.C
```

Compile the updated program, then restore its input FILEDEFs:

```text
CMSCLNK GITCIDX PLAIN
FILEDEF STGIN DISK GITFIX STAGE A
FILEDEF IDXIN DISK GITFIX INDEX A
FILEDEF FIDXIN DISK GITFIX SEEK A
GITCIDX SFAST
GITCIDX PAIR
GITCIDX SGET 00D8D63229305230C8D37F884CE87F9E1A89468C
GITCIDX SGET EB37E3F23FF4FC137D715D71A711D3B7632D75F2
```

Required summaries: `FAST AUDIT VERIFIED 1808 UNIQUE 1808`,
`PAIR VERIFIED UNIQUE 1808`, and both SGET results must give
the expected OIDs and object types/sizes. PAIR repeats the
SFAST full verification after cross-checking both index formats,
so it reads all bodies again. Measure actual CMS timings.
The original SVAUDIT may be kept as a slower optional diagnostic;
it is no longer required for completion of the index-pair gate.

### FILEDEF input status from the latest CMS session

The user issued `FILEDEF STGIN CLEAR`, `FILEDEF IDXIN CLEAR`, and
`FILEDEF FIDXIN CLEAR`, and each reported `DMSFLD704I Invalid CLEAR
request`. The immediately following three `FILEDEF ... DISK` commands
all returned normal `Ready` with no errors, so their desired GITFIX
input definitions were established. Do not repeat CLEAR or DISK
before SFAST/PAIR/SGET in that same session. CLEAR is unnecessary
when the DD name has no existing definition; only remove or replace
an actual prior definition when needed. Continue directly with the
already-linked current GITCIDX module's read-only validation gates.

## Final 1,808-object CMS migration gate PASSED

The updated GITCIDX module built under CMSCLNK PLAIN and all new
canonical datasets were fully validated on September 26, 2026:
`GITCIDX SFAST` hashed all 1,808 unique objects and validated
seek cookies in 20.85 s CPU / 20.99 s elapsed; `PAIR` reconciled
IDX2 and SIDX2 descriptors and rehashed the stage again in
21.24/21.38 s. Direct SGET succeeded on the first canonical
commit `00D8D63229305230C8D37F884CE87F9E1A89468C`
(270 bytes; 0.15 s elapsed) and last canonical tree
`EB37E3F23FF4FC137D715D71A711D3B7632D75F2`
(5,224 bytes; 1.81 s elapsed). All original raw-PACK,
STAGE/VERIFY, BUILD/CHECK/AUDIT and SBUILD/SCHECK gates also
passed on this generation. The earlier slow SVAUDIT is superseded
by target-proven SFAST and PAIR; do not repeat the entire migration.

Follow-on external/forward REF resolution and a candidate-generation
manifest have passed host tests. They are **separate new target
gates**, documented in [REF resolution](REF_RESOLUTION.md) and
[GEN2 recovery](GENERATION_RECOVERY.md); they must not overwrite
or alter the validated stage or indexes. Historical IDX1/SIDX1
remain noncanonical and unpromoted.
