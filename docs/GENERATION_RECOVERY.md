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


---

## Original: docs/ACTIVE_GENERATION_DESIGN.md (complete original design and PACK evidence)

# Active generation: two-slot recovery design

The CMS-proven GITFIX STAGE/INDEX/SEEK/GEN files are the
read-only baseline. GENCHECK passed after a fresh CMS login on
September 27, 2026: all 1,808 Git OIDs, IDX2/SIDX2
descriptors, seek cookies and the existing GEN2 seal verified.

A future writer must allocate a **new, unused** CMS filename for
its stage, index, seek and GEN2 files. It must complete and
reopen all four, then run GENCHECK before making them eligible.
Never rewrite the original GITFIX generation during development.

Proposed selector slots: GITSEL0 PTR A and GITSEL1 PTR A. Each
record includes format version, monotonically increasing sequence,
strictly validated 1-8 character generation basename, the
verified GEN2 manifest digest, and a checksum of the selector
record. A selector is not proof of the generation: startup must
read both slots, reject malformed/truncated/duplicate candidates,
and rerun full GENCHECK on each referenced candidate. Choose the
highest-sequence *validated* slot; a damaged newer slot must not
prevent recovery through an older verified slot. If neither slot
verifies, fail closed rather than silently selecting an
unattested generation.

Promotion sequence: leave the active slot untouched; write
and close candidate data, seal/reopen and check its GEN2,
write the inactive selector slot, close/reopen and check the
selector, independently GENCHECK the referenced generation,
then retain the older slot and its generation for rollback.
No claim is made that CMS replacement, rename or close is
power-loss atomic. Concurrent writer exclusion, explicit slot
file persistence, and machine-reset behavior require separate
real-CMS tests before enabling automatic promotion.

Crash-injection host regressions should interrupt each candidate
write and selector write, corrupt either slot, alter its sequence
or digest, truncate GEN2 and modify the selected stage or seek
cookie. Recovery must never return any generation that fails its
own GENCHECK. All tests use disposable fixtures, never GITFIX.

Next existing-target durability test, only after a normal
authorized VM reboot, is read-only GENCHECK against the original
GITFIX STAGE, INDEX, SEEK and GEN files. Cross-logon survival
has already passed; reboot persistence is not yet demonstrated.

## First implemented host-only selector prototype

The repository now contains `tests/active_generation_selector.py`,
a strict, versioned two-slot prototype. It encodes the selector
sequence, uppercase 1–8-character CMS basename, canonical 40-hex
GEN2 digest and CRC32 over explicit ASCII bytes. Its parser
requires exactly one newline-terminated record, valid checksum,
strict grammar and sequence within an unsigned 32-bit range.
Recovery calls an **injected full-generation-verification callback**
for each candidate in descending sequence order. It fails closed if
two different slots claim the same sequence, returns the prior
verified slot if a newer selector is corrupt or its generation fails
full verification, and returns no selection if neither is valid.

`tests/test_active_generation_selector.py` checks every truncated
prefix of the newer slot, checksum corruption, wrong/missing candidate
validation, ambiguous duplicate sequences, identical slots, missing
slots and invalid grammar. Full host regression CI passed:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36329760231 .

**This is a host-only executable specification, not deployed CMS
selector code.** The callback contract is deliberately strict: it
must be backed by real GENCHECK against the candidate's four files.
It cannot be replaced by a filename-exists check or a matching
manifest header. The next implementation step is a CMS C89 parser,
then an explicit read-only candidate verification and controlled
promotion test using separate disposable generations. Never
introduce promotion writes against GITFIX during development.

## Native C89 selector reader now committed

`src/GITSEL.C` is a new bounded native C89 reader for the proposed two-slot `SEL1` records. `GITSEL CHECK` reads FILEDEF `SEL0` and `SEL1`, validates the exact record grammar, unsigned 32-bit sequence, CMS-safe generation basename, uppercase 40-digit digest, record length and CRC32. It computes CRC32 over canonical ASCII bytes even when built on EBCDIC CMS. It rejects conflicting slot records with identical sequence numbers.

**CHECK deliberately prints candidates as UNTRUSTED; it does not select an active generation.** The actual generation must independently pass full `GENCHECK` before selection or promotion. This prevents the parser from becoming an unsafe shortcut around the complete 1,808-object audit. Never connect the parser to the protected current GITFIX data as a writer.

`tests/test_native_selector.py` compiles production `src/GITSEL.C` as strict C89 with all warnings as errors, generates records with the independent Python protocol, tests every truncated prefix and checksum/grammar corruption and verifies same-sequence conflict rejection. The complete native staging CI passed: https://github.com/mostangrymike/ibm-sandbox/actions/runs/36329974642 . This is **host-compiled only**; the native reader still needs CMS compilation and its full GENCHECK integration before it can safely select any active generation.

## M14 combined native C89 recovery gate implemented (host only)

The standalone GITSEL parser now has a bounded `GITSEL WRITE`
operation for new, disposable SEL1 records, tested byte-for-byte
against Python's independent canonical ASCII CRC32 implementation.
Its optional linked SELECT callback refuses to elect a candidate
until the callback fully validates that generation.

The new `src/GITREC.C` links actual GITSEL and GITCIDX source,
reads slot records from SEL0/SEL1, and maps each independently
named candidate to separate input FILEDEFs C0STG/C0IDX/C0SEEK/C0GEN
or C1STG/C1IDX/C1SEEK/C1GEN. It checks selector identity and the
GEN2 DIGEST record, then invokes the real full `gen_check()`
for every candidate it considers. Only after complete canonical
object/paired-index/seek-cookie/manifest verification can a slot
be selected. A damaged newer slot or incomplete newer generation
causes recovery through the older fully verified candidate.

The host integration runs the *compiled GITREC binary* against
two disposable 1,808-record synthetic candidate generations and
injects corrupt GEN2, corrupt stage, truncated SIDX2, missing IDX2
and spoofed selector identity. It asserts that neither stage
corruption nor selector parsing alone can bypass full GENCHECK.
All these tests passed:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36330993480 .

This code is **not an active pointer writer, not a lock and not
an atomic promotion operation**. Real CMS compilation and the
safe read-only valid-old/invalid-new test remain to be performed.
See [the exact next target gate](NATIVE_RECOVERY_GATE.md), which
uses the actual GEN2 DIGEST from the protected GITFIX generation
and only two disposable selector files. No original stage, index,
seek or manifest file is modified.

## M14 CMS-proven recovery and M15 host interruption matrix

September 27 native CMS tests completed the real GITREC
selector recovery gate on GITFIX: valid older seq41, invalid
newer seq42, full 1808-object SFAST/PAIR/GENCHECK,
failed name matching, absent old GEN2, invalid SEL1
content and both single-slot absence cases. A correct
restored mapping recovered GITFIX and its canonical
DIGEST 493F0896884B28AC4836B88328629B7E95404B46.
All target tests were nondestructive to GITFIX and
existing selector records. Cross-logon durability for
the selectors themselves still requires confirmation,
although GITFIX GEN2 independently survived logoff/logon.

M15 host regression extends tests/native_index_host.c,
which compiles and runs the **actual production GITREC.C**
against separately generated full indexed fixture files.
A valid old candidate stays present. Simulated interrupted
promotion probes five shortened candidate selector prefixes,
then independently withholds each of the four new candidate
files (stage, index, seek, GEN2), and simulates an incomplete
new GEN2 manifest. Every incomplete new candidate must
fall back through actual full GENCHECK to the old verified
candidate. Only the fully restored candidate with an intact
selector can be selected as new. Fixture names, staged data
and slot records are host disposable; this is not a CMS
file-write atomicity or concurrent writer proof.

**Promotion remains disabled.** The currently tested
REXX STATE RC28 / ABSENT28 gate only protects the
controlled single-writer first creation of a new selector.
It is not an atomic create-if-absent or lock. True active
promotion needs an exclusively owned writer protocol,
immutable staged generations, a verified independent
second candidate, new unused slot storage and
interrupted-write testing on CMS before production use.
Never reuse or overwrite GITSEL0/GITSEL1 PTR A or the
four protected GITFIX generation files.

## M15 next native CMS test: disposable independently sealed candidate

The current reusable `src/GITRUN.EXEC` is committed as the
first isolated CMS candidate-build gate. It guards all four
new `M15NEW STAGE/INDEX/SEEK/GEN A` filenames and both
`M15SL0/M15SL1 PTR A` names with real REXX STATE
RC 28 checks **before writing**. It checks all four
protected GITFIX source files, reports A-disk space,
copies only the existing verified GITFIX STAGE and
IDX2 INDEX into never-before-used M15NEW files, builds a
fresh SIDX2 seek index against the new stage (since
CMS ftell cookies may change when copied), then creates
an independent M15NEW GEN2 manifest **last**.
Afterward GITCIDX GENCHECK must independently reopen
and rehash all 1,808 stored objects, pair both indexes,
check stage seek cookies and verify the seal. Any
failed step exits immediately with no selector writes.

This test is a **disposable candidate build**, not
active promotion and not the host interruption test.
The next separate target gate after successful verification
will use only new unused M15SL0/M15SL1 selector files,
fully verify both candidates with GITREC before and after
a deliberately invalid newer-selector case, and never
write to the existing GITSEL0/GITSEL1 files. The new
candidate should not be called durable or active until
its independent CMS verification and subsequent
persistence/recovery checks pass.

## September 27 superseding status: actual CMS M15 matrix

The complete 10-case M15 native CMS recovery matrix has
now passed. Independently verified seq51 GITFIX and
seq52 M15NEW survived each missing newer component, a
missing older GEN2, both missing GEN2s, one or both
malformed selectors and complete restoration. All selected
generations underwent the full native 1808-object audit
and returned the expected generation name/sequence. The
two independent CMS generations, all four native selector
records, and the captured original PACK remain protected.

The older Python-only selector proof-of-concept files
`tests/active_generation_selector.py` and
`tests/test_active_generation_selector.py` were retired
from current GitHub main after the independent ASCII/CRC
encoder was embedded into `tests/test_native_selector.py`.
Native C89 selector fuzz tests and full native GITREC
integration are the maintained host CI paths; historical
commits preserve the original Python-only prototype.
Latest native CI green:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36338727815 .

The next read-only CMS runner independently rechecks both
GEN2 candidates and the native dual-slot selector. Only
upon success does it optionally remove three explicitly
named historic NONCANONICAL CMS copies: GITSTAGE DATA A,
GITINDEX DATA A and GITSEEK INDEX A. It does not erase
GITPBUF PACK A, GITFIX, M15NEW, GITSEL0/1 or M15SL0/1.
Cleanup remains target-pending until the CMS transcript
shows the expected success. Full CMS interrupted write,
exclusive lock and reboot persistence remain distinct
unproven production requirements.

## September 27 current CMS cleanup verified; M16 in progress

The high-density M15 audit-and-cleanup run succeeded on actual
CMS: independent GEN2 audit of GITFIX and M15NEW (1808
unique each, RC0), deliberate selector swap rejected with
two name mismatches RC8, restored M15 selectors chose seq52
M15NEW after complete GENCHECK RC0. The three old noncanonical
GITSTAGE DATA A, GITINDEX DATA A and GITSEEK INDEX A files
were erased; each subsequent STATE confirmed absence.
The final guards found both complete canonical sealed
generations and both original/disposable pairs of PTR
selector records intact. GITPBUF PACK remains preserved.

M16 advances beyond missing inputs into native selector
protocol attacks, with a single self-cleaning CMS GITRUN:
a correctly checksummed seq60 M15NEW selector with a forged
zero manifest digest must be rejected in favor of verified
seq51 GITFIX; a genuine M15NEW seq50 selector must lose
to verified older-generation seq51 GITFIX; a genuine
same-sequence seq51 M15NEW selector must conflict with the
distinct seq51 GITFIX and fail closed RC8; restoring intact
original seq52 M15NEW must pass complete independent
GENCHECK. All M16 temporary PTR fixtures are created only
under verified-unused names M16BAD/M16LOW/M16CON and erased
after the entire test succeeds. The runner ends by
checking that all eight sealed-generation files and
the original four PTR files remain present.

The companion host regression tests the actual compiled
native GITREC for forged checksummed digest, sequence
ordering, conflict and restoration. Neither these
protocol tests nor the earlier read-only missing-input
matrix prove atomic CMS file replacement or exclusive
writer ownership. Retain both complete sealed generations
and their current selector records until real cross-logon
and normal reboot survival are explicitly established.

## M18 production-facing, read-only selected-generation object GET

`src/GITREC.C` now supports a second command:

```text
GITREC GET C0NAME C1NAME OID40
```

It uses the same explicit read-only `SEL0`/`SEL1`
and independent `C0STG/C0IDX/C0SEEK/C0GEN`,
`C1STG/C1IDX/C1SEEK/C1GEN` file bindings as
`GITREC SELECT`. It validates the 40-hex input
OID before any selector reads, refuses identical
candidate names, evaluates both selector records
including identity and seq conflict rules, and
performs the **complete native GEN2 stage/index/
seek/manifest audit** before permitting a lookup.
Only the successful verified candidate's mapped
seek index and stage are opened by `sidx_read`/
`sidx_get`; a newer unverified generation cannot
leak object bytes. The existing `SGET` independently
rehashes the selected body's Git SHA-1 and prints
`SEEK OBJECT OID` with type, size and prefix.
Absent OID returns RC4; invalid OID grammar
returns RC4; no verified generation returns RC8.

Host regression uses the actual production
`GITREC.C` against independent complete synthetic
1808-record generations: positive new-generation
GET, missing OID and malformed OID rejection,
missing new GEN2 old-generation fallback GET,
both GEN2 files missing with no object disclosure,
and restoration to new-generation GET.
This is the first usable read-only operation
*through* the independently verified generation
selector rather than only displaying its name.

Native CMS execution of this new GET mode is
**on hold** until the documented M01RES/DASD1
filesystem TRKDE-4 incident is preserved and
resolved. No GitHub source change was uploaded
to the possibly damaged CMS A disk, no cleanup
was resumed, and `src/GITRUN.EXEC` remains
an RC12 safety hold. Full OID output, atomic
promotion and exclusive writes are separate
future milestones.

## M19/M20 complete native object output and boundary verification

Production `GITREC CATHEX C0NAME C1NAME OID40` extends
the same full-GEN2-verified and dual-slot-recovered
read-only pathway as `GITREC GET`. It validates the
OID first, verifies the actual selected generation,
seeks through the verified candidate's own SIDX2
index, independently rehashes the entire Git object
body, and **only then** prints the complete body
between `OBJECT DATA BEGIN` and `OBJECT DATA END`.
Each `HEX ` line contains at most 32 body bytes
(64 hex digits), fits within CMS's 80-column output,
and an empty object has no HEX lines. Normal GET
retains its bounded 16-byte prefix behavior, without
the full output. The existing 65,536-byte maximum
is preserved; the native C89 implementation does not
need a malloc or unbounded CMS REXX string.

A second, independently built full-size host fixture
compiles the actual `src/GITCIDX.C` and
`src/GITREC.C` separately, builds and seals a
fresh indexed generation with exactly 1,808
staged objects including a full 65,536-byte
binary object, a zero-length object, a 257-byte
binary object containing NUL and high bytes,
and an ASCII `abc` object. Python independently
computes Git blob object hashes, selector ASCII
CRC32 and verifies every byte reconstructed
from production CATHEX lines. It also tests
the corrupt newer generation's fallback,
both generations invalid with **no** object-body
output, and restoration to intact newer
generation. This complements the original
native-index integration fixture's independent
small-object GET tests. All M19/M20 native
host CI PASSED:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36356523315

GITREC still has no atomic multi-writer promotion,
exclusive writer lock, production binary transport
or reboot recovery proof. No new CMS code has
been uploaded after the M01RES TRKDE incident;
the old CMS A-disk copy of GITRUN must not run.

## M20 next native CMS gate is assembled but safety-held

The full selected-generation `CATHEX` implementation and
separately generated 65,536-byte/binary/empty-object
byte-for-byte host integration are complete. All tests
passed in GitHub Actions run
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36356523315 .
The CMS smoke batch `src/GITRCHK.EXEC` is already
committed. It checks both generations, all four
protected selector files and the original captured
PACK; then exercises the real canonical 270-byte
first commit via current selected-generation GET,
complete CATHEX, newer-manifest absence fallback,
both manifests unavailable RC8, and final complete
restoration. It neither generates indexes/manifests
nor creates/deletes any persistent CMS file; a
separate CI source guard rejects such commands.
The entire expanded native suite, including this
guard, passed:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36356602355 .

**Prerequisite for any target invocation**: preserve
and verify the operator-identified actual
`/home/admin/vm630/dasd1` volume M01RES offline,
then repair or reconstruct the CMS A filesystem
after its TRKDE 4 corruption incident and verify
that the target is safe for uploads/compilation.
At that point transfer `src/GITREC.C` and
`src/GITRCHK.EXEC` through the existing single
c3270 uploader, rebuild `GITREC` using the proven
`CMSCLNK GITREC PLAIN` path, and run one
`GITRCHK` batch. Do **not** execute the
previous unsafe CMS-uploaded `GITRUN`; the
repository's current GITRUN is an RC12 safety
hold. Full native CMS CATHEX operation is not
yet target-proven; only its compiled-host output
and native C89 protocol have been tested.

## M21 native CMS result and M22 host-complete binary tree parsing

**M21 passed on actual IBM z/VM 6.3 CMS on September 27**
after `CMSCLNK GITREC PLAIN` compiled the new native module
with no assembler warnings. Standard `GITRUN` verified
both existing GITFIX and M15NEW generations independently
(1,808 unique each); selected seq52 M15NEW with digest
493F0896884B28AC4836B88328629B7E95404B46;
read the real 270-byte commit with GET and full CATHEX;
recovered seq51 GITFIX when the newer manifest was
temporarily rebound to an absent fixture; rejected
both absent manifests RC8; restored seq52 and
full CATHEX; and checked all protected files afterward.
Final user output: `GITRUN M21 ALL READ ONLY NATIVE
GIT TESTS PASSED`, CMS Ready T=150.70/151.97.
Deliberately missing M15BAD GEN and associated
open-error messages are expected negative tests,
not unexpected errors.

**M22 host-complete, CMS pending:** native
`GITREC TREE C0NAME C1NAME OID40` adds a
read-only structured Git binary-tree decode after
full native GEN2/SFAST/PAIR verification and a
second independent full requested object's Git
SHA-1 verification via the selected generation's
SIDX2 direct seek. Only Git type-2 objects are
accepted. Complete records are structurally
validated *before* any TREE data is printed.
Supported Git modes: 100644, 100755, 120000,
160000, and 40000. Tree names, which are raw
Git bytes rather than CMS-native text, are
reported in 32-byte `TREE NAMEHEX` chunks.
Each entry prints mode, name length, and full
40-digit object ID. Empty Git trees correctly
produce `TREE ENTRIES 0`. Truncated/invalid
records, unsupported modes, missing/not-tree
objects and unverified generations fail closed.
These constraints retain existing C89 and
65,536-byte native Git object bounds.

The new host integration `tests/test-native-tree.py`
compiles the actual production native C89 index
and recovery modules against independently
constructed 1,808-object binary tree, empty tree,
malformed tree and blob fixtures. It verifies
all five supported modes, raw non-ASCII name
bytes, exact OIDs/name reconstruction, empty
tree, non-tree and truncated-tree rejection,
seq51 verified old fallback, both manifests
invalid (no TREE data emission), then seq52
restoration. Full GitHub native workflow PASS:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36359383185 .

The **standard `src/GITRUN.EXEC`**, as explicitly
required by the user, is now M22's combined
read-only CMS batch: checks every protected
generation, selector and PACK; independently
audits two full generations; verifies seq52;
GET of the known first commit; TREE decode of
that actual commit's tree OID
204E1D6968FB81C35BF830D63A611AC64C072945;
refuses to treat the commit itself as a tree
(RC8); deliberately makes newer/both
manifests unavailable through read-only
FILEDEF rebindings, verifies fallback/fail-closed,
restores original mappings, and rechecks
protected files. No ERASE/COPYFILE, persistent
index/manifest writes or selector writes.
This new batch's native CMS target execution
is PENDING, not yet claimed passed.

## September 28 M22 target-proven; M23 structured commit reader

M22 `CMSCLNK GITREC PLAIN` compiled with no assembler
warnings and the standard M22 `GITRUN` completed
successfully on real z/VM CMS on September 28 at
09:28 (T=172.16/173.64). Both GITFIX and M15NEW
passed full 1,808-object native GENCHECK, selected
seq52 M15NEW, decoded actual first-commit tree
204E1D6968FB81C35BF830D63A611AC64C072945
with four entries: CHAT_STATE.md, README.md, docs
and src; rejected non-tree commit (RC8), recovered
seq51 GITFIX when newer GEN2 was absent, refused
both missing GEN2s (RC8), and reselected seq52
after restoring full input mappings. Final all
protected-file checks passed. Git's raw ASCII
modes and delimiters are decoded using explicit
0x20, 0x2f and mode-digit byte values, avoiding
the earlier CMS EBCDIC comparison bug.

M23 introduces
`GITREC COMMIT C0NAME C1NAME OID40` in actual
production C89 source. Like TREE and CATHEX, it
first audits and authenticates the entire selected
generation (GEN2, SFAST, PAIR), uses the selected
generation's direct seek index, rehashes the
requested whole Git commit object and only then
parses the binary header. All Git on-disk OID
digits, line endings and header names are tested
as explicit ASCII bytes, not CMS-native C text.
It validates exactly one first `tree` OID,
zero or more contiguous parent OIDs, author and
committer headers, the blank separator, normal
Git header keys and optional folded header lines.
No metadata is printed until the complete header
is validated. The output contains COMMIT DATA
BEGIN/END, TREE OID, every PARENT OID, parent
count, and message byte count. It does not
materialize the commit message or claim all
parent/tree dependencies are locally available.

M23 host regressions added a valid synthetic
root commit, two-parent merge, invalid parent,
missing committer and a not-commit negative
fixture to the actual 1,808-record native stage.
They verify the production compiled C89 source,
correct metadata, no parsed output on malformed
content, selected-generation fallback and
both-invalid fail-closed behavior.
Full native CI passed:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36436943632 .

The one reusable standard `src/GITRUN.EXEC`
now contains M23's read-only CMS gate against
the already protected original GITFIX and
M15NEW. It tests the real first commit
00D8D63229305230C8D37F884CE87F9E1A89468C
and independently its actual root tree, rejects
a non-commit tree (RC8), verifies older-seal
fallback for COMMIT, both unavailable (RC8)
and intact restoration. No stage, index,
manifest, selector or PACK files are written.
This new COMMIT mode is HOST-PROVEN, awaiting
real CMS execution via standard GITRUN.

## September 28 — M23 CMS pass; M24 native linked read-only paths

M23's new native `GITREC COMMIT` and standard `GITRUN`
PASSED on actual CMS, with `CMSCLNK GITREC PLAIN`
reporting no assembler issues. The target verified
both immutable 1,808-object sealed generations,
selected M15NEW seq52, decoded the actual
270-byte first commit to tree
204E1D6968FB81C35BF830D63A611AC64C072945,
parent 2D5038C551318997B865497E04CF4C037DE4135E
and message length 44 bytes. A tree passed to
COMMIT was correctly rejected RC8. Simulated
newer GEN2 absence recovered seq51 GITFIX and
returned the same commit metadata; both absent
rejected RC8; restoring both reselected seq52
and decoded the commit again. Final all-original
protected-file checks passed. Actual target end:
`GITRUN M23 ALL READ ONLY NATIVE GIT TESTS PASSED`,
T=172.06/173.45 at 09:41:52.

M24 advances from manual independent tree IDs to
**linked, native commit-relative object access**,
with two new production C89 commands:

```text
GITREC LSROOT C0NAME C1NAME COMMIT_OID40
GITREC PATH C0NAME C1NAME COMMIT_OID40 PATHHEX
```

LSROOT validates and rehashes the commit, reads
its canonical first ASCII tree header, then
verifies and decodes the linked tree using the
**same full GEN2-selected generation**, without
trusting the caller to supply the tree OID.
It emits tree entries only after independently
verifying both linked objects and the tree's
complete binary structure.

PATH accepts the relative path encoded as Git
raw-byte hex, not CMS-native text. It resolves
each component in a fully verified type-2 tree,
checks the required mode and referenced object
type, recursively follows nested subtrees and
rehashes the final blob/tree body using its
selected SIDX2 direct-seek cookie before printing
the result. A Gitlink (mode 160000) returns
its external commit OID and does not claim the
external commit is staged locally. Missing
paths or unstaged linked targets return RC4;
invalid hex/absolute/empty path components
return RC4; invalid linked types/structure and
non-tree intermediates fail closed RC8. No
mutable stage or selector operations occur.

Strict C89 host integration now uses a real
1808-object GEN2 test generation with an
authenticated commit, six-mode binary tree
and nested child tree, empty/malformed trees,
known staged blob and gitlink, wrong-type and
malformed linked trees, and the captured real
first-commit fixture. It tests root decoding,
blob/nested-tree resolution, missing paths,
invalid path hex, non-tree intermediate,
external gitlink, both invalid fail-closed,
verified older fallback and reselected newer
restoration. All native GitHub host CI passed:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36438588523 .

The single standard `src/GITRUN.EXEC` now holds
M24's read-only actual CMS tests, including
independent dual-generation audit and seq52
selector validation; LSROOT of the known first
commit; PATH of its real README.md; nested
PATH of docs/STATUS.md; non-commit LSROOT RC8;
missing-path RC4; non-tree intermediate RC8;
older-generation fallback, both-unavailable
RC8, and restored nested path; final all
protected generation/selector/PACK checks.
The actual GitHub historical first-commit
root and nested docs trees were checked when
selecting the names for this batch; the
new M24 native code has **not yet** executed
on CMS and is not claimed target-proven.

## M24 target pass; M25 full verified file bytes by relative path

M24 ran successfully on real CMS on September 28:
`CMSCLNK GITREC PLAIN` assembled with no flagged
statements and the single standard `GITRUN`
completed all ten linked-root/path tests.
Both original 1,808-object generations reaudited
fully; seq52 M15NEW selected; the first commit's
root tree decoded; `README.md` resolved to the
567-byte blob 1BA7AE466BB0A16C294D52A8642E527B07D4D1F5;
nested `docs/STATUS.md` resolved to the 5,737-byte
blob 46135A22C7394D8090619C6C70453C58A24F5239.
Wrong input types, missing files and non-tree
intermediates returned their expected RCs;
missing new-generation GEN2 recovered seq51
GITFIX; both unavailable failed closed RC8;
restoration selected seq52; all protected file
STATE tests passed. Final target line:
`GITRUN M24 ALL READ ONLY NATIVE GIT TESTS PASSED`,
Ready T=239.20/240.98 at 10:07:02.

M25 production native C89 `GITREC PATHCAT C0NAME
C1NAME COMMIT_OID40 PATHHEX` now reuses the
verified M24 nested path traversal and complete
GEN2-selected-generation audit. It independently
rehashes each linked tree and the final type-3
blob before output. Only after full success
does it print `PATH OBJECT TYPE 3 SIZE n OID ...`,
`PATH DATA BEGIN`, up to 32 exact raw bytes per
`PATH HEX` line and `PATH DATA END`. Empty
blobs produce zero HEX lines. A tree/gitlink
target is not accepted as a blob; wrong-type,
missing intermediate, invalid path, bad input
and unverified candidate fail closed without
any PATH DATA bytes. The output is textual
hex and safe for CMS console transfer; the
implementation does not assume unverified CMS
binary record semantics.

Host integration uses actual compiled production
GITCIDX/GITREC with fully sealed 1,808-record
synthetic dual generations. It byte-for-byte
reconstructs PATHCAT outputs for ASCII, nested
ASCII, empty, full 257-byte binary including
NUL/high-bit bytes, and max 65,536-byte binary
blobs. It exercises non-blob negatives, malformed
path input, missing targets, old-generation
fallback, both candidates unavailable and
restoration. A second pinned fixture preserves
the exact historical first-commit `README.md`
contents; the test reconstructs its Git blob
SHA1 and original four-entry root tree SHA1
independently, then feeds the exact previously
captured 270-byte real first commit through
production LSROOT and PATHCAT. All native host
CI passing:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36441754586 .

The single reusable `src/GITRUN.EXEC` is M25's
read-only CMS gate: independent audits for both
protected generations, seq52 selection,
PATHCAT the real first commit's README.md and
nested docs/STATUS.md, type/missing/non-tree
negative cases, seq51 fallback, both absent
fail-closed and seq52 restoration, final
all-protected file checks. Host CI verifies
that this batch has no persistent CMS writes.
M25 has not yet run on CMS.

## September 28 M25 target pass; M26 nested-directory listing

M25 passed on actual CMS: `CMSCLNK GITREC PLAIN`
compiled the updated production module with no assembler
statements flagged. The standard read-only `GITRUN M25`
independently audited both original GITFIX/M15NEW
1,808-object sealed generations; selected M15NEW seq52;
successfully emitted the entire first commit's README.md
(567-byte blob 1BA7AE466BB0A16C294D52A8642E527B07D4D1F5)
and nested docs/STATUS.md (5,737-byte blob
46135A22C7394D8090619C6C70453C58A24F5239)
as framed raw-byte hex. Wrong-type and missing-path
tests failed as expected, the absent newer manifest
recovered the verified older generation, and both absent
manifests failed closed. Restoration retrieved the
complete README again; final protected file checks
passed. Actual last line: `GITRUN M25 ALL READ ONLY
NATIVE GIT TESTS PASSED` (CMS T=218.04/220.32 at
10:28:26). The pasted terminal capture is interleaved,
but the final batch completion is unambiguous.

M26 adds native `GITREC LSDIR C0NAME C1NAME
COMMIT_OID40 DIRHEX`. This read-only command resolves
a relative directory from the verified commit's tree
through authenticated nested trees in the same
GEN2-selected generation, independently rehashes the
target tree, validates the full tree structure, and
emits all entries in the established `TREE DATA`
framing. A regular blob, external gitlink, missing
directory, malformed path, non-tree intermediate,
corrupt tree or unavailable verified generation cannot
emit tree data. Names remain raw Git bytes encoded
as `TREE NAMEHEX`, with explicit ASCII mode decoding
for native CMS/EBCDIC compatibility.

The actual compiled C89 host tests now verify `LSDIR`
of a nested directory (including exact child mode,
name and OID), missing/invalid/non-directory targets,
older-generation recovery, both-manifests-unavailable
fail-closed behavior and restored newer selection.
Standard `src/GITRUN.EXEC` has been updated to the
M26 single read-only target suite. Its positive live
CMS case lists the actual first commit's `docs`
directory, containing the historical BUILD.md and
STATUS.md. All host native regressions and the
read-only EXEC source guard passed:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36444249032 .
M26 is host-proven only until the new GITRUN is
actually executed on CMS.

## M26 target pass and compact standard GITRUN reporting

M26's native `GITREC LSDIR` compiled on CMS with no
assembler statements flagged. On September 28,
the standard `GITRUN M26` completed all tests
(T=194.96/196.38). The selected seq52 M15NEW
returned the historic docs directory as a 73-byte
tree, with precisely BUILD.md and STATUS.md.
Both 1,808-object original sealed generations passed
full independent GENCHECK; blob-as-directory,
missing path and non-tree intermediate produced
expected RC8/RC4/RC8. Old seq51 recovery, both
invalid fail-closed and restored seq52 succeeded.
Final protected files remained present.

At user request, the *same standard GITRUN.EXEC*
is now M26Q, a one-page **console summary** rather
than six to seven pages of repeated full audits
and tree records. Each native CMS command runs as
`PIPE CMS <command> | STEM out.`, capturing output
in an **in-memory REXX stem**, with no disk output
or modified source generations. The runner verifies
the PIPE return code and specific expected result
markers independently, including both exact
docs-directory entry OIDs. On success, it prints
two headers and around thirteen short PASS lines.
On a failed case, it prints its stage name,
observed and expected RC, missing marker flags
and at most four final diagnostic lines, then stops
with RC12. Tests retain independent two-generation
GENCHECK, selector, normal, negative, fallback,
fail-closed and restored cases plus pre/post
protected-file STATE checks. Intentional absence
of the test manifest is also captured silently.

The output summarization mechanism follows
documented CMS Pipelines REXX STEM behavior.
All source/host CI regression checks passed:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36446263848
The compact PIPE/STEM runner itself still needs
one real CMS run before its output can be called
target-proven. The native GITREC/GITCIDX modules
and original generation files are unchanged.
Future GITRUN suites must remain one page or less.

## September 28 M26Q2 one-page CMS proof; M27 first-parent links

The compact standard `GITRUN M26Q2` itself PASSED
on actual z/VM CMS at 11:05:02, T=195.18/196.47.
It printed only about 15 short lines, not the
previous six or seven pages: both original
GITFIX/M15NEW 1,808-object full audits RC0,
M15NEW seq52 selection, exact docs-directory
two-entry validation, negative wrong-type RC8,
missing-path RC4, non-tree intermediate RC8,
GITFIX seq51 recovery RC0, both manifests
absent RC8, M15NEW restoration RC0 and final
protected-file checks. The real CMS PIPE-to-
in-memory-REXX-STEM capture and concise stage
PASS/FAIL reporting are target-proven. Every
subsequent standard GITRUN target batch must
retain this one-page reporting contract and
last-four-diagnostics-on-failure behavior.

M27 production C89 now includes
`GITREC FIRSTPAR C0NAME C1NAME COMMIT_OID40`.
It fully verifies GEN2, both immutable indexes
and all 1,808 staged objects before selecting
a recovery generation, then independently
authenticates and validates the supplied Git
commit header, decodes its first Git ASCII
parent OID, retrieves and SHA1-verifies the
first-parent commit in that SAME generation,
and validates the parent's complete commit
header before emitting its parent OID and
tree OID. A root commit has no first parent
(RC4), unstaged/missing parent returns RC4,
wrong-type or malformed child or parent
returns RC8, and both-generation failures
remain fail-closed. No missing parent is
silently replaced by an object in a second
generation.

Native strict C89 host tests now exercise
the production two-parent merge, authentic
first-parent traversal, root negative,
missing parent, wrong-type parent, malformed
parent, bad child type, seq51 fallback,
both unavailable fail-closed and seq52
restoration while preserving all existing
host binary blob, CATHEX, TREE, PATHCAT and
LSDIR regressions. GitHub CI passed:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36450050947

The standard `src/GITRUN.EXEC` is now M27's
compact, no-persistent-write CMS target gate,
retaining both independent original 1808-
object audits and original-file integrity
checks. It requires the native first parent
of the historic first commit
00D8D63229305230C8D37F884CE87F9E1A89468C
to verify as
2D5038C551318997B865497E04CF4C037DE4135E,
with parent tree
F3EF36AAD778D5DA84857D8DED46495C75F4CAB0,
independently checked against historical
GitHub commit metadata. It then tests wrong
type RC8, missing commit RC4, seq51 recovery,
both unavailable RC8 and seq52 restoration
using in-memory PIPE capture. M27 itself
requires live CMS execution and is not
yet target-proven.

## M27 target-proven and M28 bounded ancestry

M27 passed real CMS compilation and the
one-page standard `GITRUN M27` on September 28,
at 11:26:34, T=171.82/172.92. Both original
1,808-object sealed generations passed independent
full audits and seq52 M15NEW selection. The
historical first commit's first parent was
independently authenticated within the selected
generation. Wrong-type/missing inputs returned
expected RC8/4, loss of the newer GEN2 recovered
seq51 GITFIX, loss of both failed closed RC8,
restoration recovered M15NEW, and all protected
files passed final STATE. The compact GITRUN
console contract remains actual-CMS proven.

M28 adds `GITREC ANCESTOR C0 C1
COMMIT_OID40 DEPTH`, where DEPTH is a strict
1–16 decimal hop count along first-parent
links. It fully GEN2-authenticates exactly one
selected sealed generation, then rehashes and
validates EVERY intermediate commit and its
Git ASCII parent header, following each hop
within that SAME generation. It prints only the
final verified ancestor's OID and tree OID
together with verified depth; missing, bad,
wrong-type or root-exhausted chains emit no
ancestor success metadata. A strict host
fixture includes a grandchild, a two-parent
merge and a root, checks two-hop success,
depth3 root exhaustion, invalid depth values,
missing and malformed parents and both
manifest recovery states.

The one-page standard `src/GITRUN.EXEC` M28
target batch uses the actual sealed historical
first commit, first parent and second ancestor
to validate depth1 and depth2. The depth2
historical grandparent SHA
C67A53164ADFC6FDEB708F13F1822E2CF24C060C
and tree B8A987847912D6B67C1064D5361F5A9E5868DC18
were independently cross-checked against
historical GitHub commit metadata. Full host
C89 tests and read-only compact GITRUN guards
passed:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36451606606
M28 is not yet proven on CMS.

## M28 target pass and M29 atomic first-parent history

M28 was successfully compiled on live CMS after
fixing the prior over-72-column source truncation
and adding the permanent CMS compiler line-width
CI guard. On September 28, the standard compact
`GITRUN M28` returned full success: both original
1,808-object generations independently verified,
M15NEW seq52 selected, the historical first
and second parent commits authenticated
(ANCESTOR depth1 and depth2 RC0), invalid
depth returned RC4, wrong-type input RC8,
seq51 older-generation fallback RC0, both
manifests missing RC8, seq52 restoration RC0,
and all protected files present. Exact final
target marker:
`GITRUN M28 ALL READ ONLY NATIVE GIT TESTS PASSED`,
T=172.80/173.94. Its output remained one page.

M29 adds `GITREC HISTORY C0NAME C1NAME
COMMIT_OID40 DEPTH`, a bounded read-only
first-parent history listing. DEPTH is the
number of parent hops, strictly 1–16.
This reads and independently SHA1-verifies
each commit's raw Git object in the SAME fully
audited selected generation; it validates
every entire commit header before following
a parent. The implementation stores all
traversed OIDs and tree IDs in fixed C89
arrays, so it prints no history records
until ALL requested hops have verified.
On success it emits framed HISTORY DATA
with one HOP number, OID and tree OID per
commit, including the starting commit.
Root reached early or missing links return
RC4; corrupt or wrong-type links RC8.
No stage, index, manifest, pointer or PACK
is written.

Compiled native C89 host tests include
a synthetic grandchild/merge/root chain;
two-hop byte-exact history, depth bounds,
exhausted root, missing and corrupt
intermediate parents, full seq51 fallback,
both-generations invalid failure and
seq52 restored history, along with all
prior regression coverage. M29's single
standard compact `GITRUN` tests the
actual original first commit and its first
two parents, historic OIDs and tree IDs,
invalid depth RC4, non-commit RC8,
fallback, fail-closed and restoration.
Original full GENCHECK and before/after
protected-file STATE checks are retained,
with only an approximately one-page
PASS/FAIL output. All host CI and the
read-only source guard passed:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36463930319 .
M29 requires a real CMS compile and GITRUN
before target success can be claimed.

## September 28 — M29 live CMS pass and M30 numbered parents

The corrected M29 `GITREC HISTORY` compiled cleanly
on actual CMS and the compact standard `GITRUN M29`
fully passed, T=150.68/151.64 at 13:36:37.
Both original 1,808-object generations completed
their independent audits, seq52 selected, real
two-hop first-parent history passed with complete
separate OID/TREE lines, invalid depth returned
RC4, noncommit input RC8, seq51 recovery RC0,
both missing failed closed RC8, seq52 restoration
RC0, and final protected-file checks passed.
Native atomic history listing and the concise
single-page PIPE-to-STEM console report are
TARGET PROVEN.

M30 introduces read-only
`GITREC PARENT C0NAME C1NAME COMMIT_OID40 N`
with one-based parent ordinal N (1–16).
Unlike FIRSTPAR and HISTORY, this supports
second and later Git merge parents. It
validates the child's entire binary commit
structure, identifies precisely the Nth
ASCII Git parent header, locates, rehashes
and fully validates the referenced parent
commit from the SAME fully GEN2-audited
generation, and only then emits short
`PARENT VERIFIED ORDINAL N`, `PARENT OID`
and `PARENT TREE` records. A missing
ordinal or unstaged parent returns RC4;
incorrect child or parent type, malformed
commit or unavailable verified generations
fail closed RC8. No original files change.

Strict host C89 integration extends the full
sealed generation fixture with a second valid
root commit and a two-parent merge, tests
both merge parent ordinals, missing ordinal,
root with no parent, missing second parent,
wrong-type/malformed parent, invalid ordinals,
seq51 fallback, both unavailable failure
and seq52 restoration. Standard compact
`src/GITRUN.EXEC` M30 uses the existing real
first commit (which has exactly one parent)
for parent ordinal1 success and ordinal2 RC4,
plus bad input RC8, bounds RC4 and all prior
original dual-generation audit and recovery
checks. Full CMS compiler source width <=72
and one-page output requirements remain
mandatory. M30 CMS target pass pending.

## M30 target pass; M31 authenticated complete merge-parent list

M30 compiled on actual z/VM CMS with no flagged
assembler statements; the standard compact
`GITRUN M30` PASSED at 13:49:42 on September 28,
T=172.35/173.54. Both original 1,808-object
generations independently fully audited, seq52
selected, historical parent ordinal1 RC0 with
authenticated parent/tree IDs, absent second
parent RC4, invalid ordinal RC4, noncommit child
RC8, seq51 fallback RC0, both generations
unavailable RC8, restored seq52 RC0, all original
protected files present. Numbered parent
retrieval is now TARGET-PROVEN.

M31 introduces
`GITREC PARENTS C0NAME C1NAME COMMIT_OID40`.
This read-only operation fully audits a
selected GEN2 generation, rehashes and
validates the child Git commit, then collects
up to 16 Git parent OIDs in ordinal order.
It independently rehashes and structurally
validates EVERY parent as a type-1 commit in
that SAME generation before emitting ANY
parent records. On success it emits framed
PARENTS DATA with separate short CMS-safe
OID and TREE lines for each ordinal and an
exact parent count. A root commit returns
count zero. Missing/mis-typed/malformed
parents fail closed with no partial lists;
a limit of 16 parents protects the fixed C89
arrays. There are no persistent CMS writes.

The strict native host fixture now checks
a genuine synthetic two-parent merge with
both complete parent/tree IDs, zero-parent
root, missing second parent, wrong-type and
malformed first parent, invalid child and
seq51 fallback/both-unavailable/seq52
restoration. All earlier production C89
regressions remain passing. The same single
standard compact `GITRUN` is M31, retaining
independent real full original generation
audits, selector and before/after protected
file checks. It tests the historical original
commit's exactly one parent, noncommit and
missing child negatives, fallback, both
unavailable fail-closed and restoration.
Native host regression and read-only guard:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36468308462
M31 is host-proven, not yet target-proven.

## M31 native CMS PASS and M32 parent root-tree verification

M31 compiled on live z/VM CMS on September 28
with no flagged assembler statements. The standard
one-page `GITRUN M31` passed at 13:58:09,
T=172.13/173.25: both 1,808-object original
generations independently audited, seq52
selected, atomic PARENTS list authenticated,
noncommit and missing child rejected, seq51
recovery and both-absent fail-closed succeeded,
seq52 restored, and all protected originals
passed final STATE. M31 is TARGET-PROVEN.

M32 adds
`GITREC PARENTROOTS C0NAME C1NAME COMMIT_OID40`.
It extends target-proven `PARENTS` by verifying
not only ALL parent commit objects, but also
each parent's referenced root tree object. All
objects must be in the SAME selected, fully
audited GEN2 generation. Every parent root
tree is located, required to be a Git tree,
SHA1-verified, and fully structurally parsed.
Only after the entire set passes does the
command print `PARENT ROOT TREES VERIFIED`
and the usual individually CMS-safe PARENTS
framed list with count, parent OIDs and tree
IDs. Missing root tree returns RC4, wrong
object type or malformed root tree RC8,
without emitting partial parent-list results.
Original sealed data remains read-only.

Native strict-C89 host integration tests
both valid roots of a real synthetic merge,
a zero-parent root, an absent parent root
tree, a parent commit referencing a blob,
a structurally malformed parent tree and
missing parent commit. It also tests seq51
fallback, both missing GEN2 manifests
failing closed, and seq52 restoration.
Standard `GITRUN M32` retains the compact
one-page in-memory PIPE-to-STEM reporting,
both independent original 1,808-object
audits and original file STATE checks,
then verifies the historic commit's
single parent's root tree, negative input,
fallback, fail-closed and restoration.
Native CMS M32 target testing is pending.

## M32 live CMS PASS; M33 atomic commit-root graph

On September 28, actual z/VM CMS compiled M32
GITREC PLAIN with no flagged statements
(T=8.71/9.01). The one-page standard GITRUN
M32 passed at 14:20:37 (T=172.79/173.90):
both original independent 1808-object sealed
generation audits, seq52 M15NEW selection,
verified all original first-parent root trees,
noncommit child RC8, missing child RC4,
older seq51 fallback, both unavailable
fail-closed RC8, newer seq52 restoration
and final protected file integrity. M32
PARENTROOTS is TARGET PROVEN.

M33 adds read-only
`GITREC COMMITROOTS C0NAME C1NAME COMMIT_OID40`.
Unlike M32's PARENTROOTS, M33 validates the
specified commit's *own root tree* in addition
to every parent commit and every parent's
root tree, all in the SAME fully audited
selected generation. Every referenced root
must exist as a Git tree object, SHA1-rehash
and pass full binary tree structural parsing.
The PARENTS-framed output and
`COMMIT ROOTS VERIFIED` marker appear ONLY
after all required commit and tree objects
authenticate, with no partial parent listing
on failure. Root commits (zero parents)
still have their own root tree checked.
Missing roots return RC4; wrong-type or
structurally invalid trees return RC8.

Host C89 regression extends the existing
1808-object synthetic sealed fixture, testing
both valid roots of a two-parent merge,
zero-parent commit, absent/wrong-type/
malformed child and parent root trees,
missing parents, invalid child type,
seq51 fallback, both unavailable fail-closed
and restored seq52. Existing PARENTS and
PARENTROOTS behavior is unchanged.
Standard M33 GITRUN preserves the one-page
in-memory PIPE CMS-to-STEM report,
independent complete 1808-object audits
and pre/post original protected-file checks.
Full host CI green:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36472033887 .
Actual target M33 compilation and regression
are still pending. No protected originals
or unchanged GITCIDX/GITSEL sources change.

## M33 native CMS PASS; M34 authenticated direct root entries

M33 successfully compiled on the real z/VM CMS
at 14:48:08 on September 28, with zero flagged
assembler statements. The standard one-page
`GITRUN M33` completed at 14:51:04 with
T=172.95/174.07. The historical commit's
own root and every parent's root tree all
authenticated, both immutable 1808-object
generations passed independent GENCHECK,
seq52 selected, wrong-type and missing child
returned RC8/4, seq51 fallback passed,
both absent failed closed RC8, seq52 restored,
and all original protected files were present.
M33 is actual CMS TARGET-PROVEN.

M34 adds
`GITREC ROOTLINKS C0NAME C1NAME COMMIT_OID40`.
After a full selected GEN2 audit, it validates
the specified child commit, each parent
commit (up to sixteen) and all respective
root-tree objects. It additionally parses
every *direct* entry of the child's and
parents' root trees, locates its referenced
staged object in that SAME sealed generation,
checks the Git mode's expected blob/tree type,
SHA1-authenticates the referenced object, and
structurally parses directly linked subtrees.
Gitlink (160000) entries refer to external
repositories and deliberately do not require
a local object. The check limits direct entries
per root to 256 to bound CMS memory. It is
not a recursive traversal of all nested
subtrees and does not verify external Gitlinks.
No success marker or parent-list data appears
until every required direct link authenticates.

The production C89 host test fixture is still
1808 staged objects, now with 34 unique Git
objects including dedicated malformed-reference
trees and commits. It exercises missing direct
entry RC4, wrong-type direct entry RC8,
malformed direct subtree RC8, missing direct
entry in a merge parent, a zero-parent root,
seq51 fallback, both unavailable fail closed,
and seq52 restoration. All prior native Git
regressions remain enabled. Standard M34
one-page read-only `GITRUN` retains independent
original 1808-object audits, seq52 selection,
actual historic root direct-link checks,
negative wrong-type and missing child checks,
seq51 fallback, both invalid fail-closed,
seq52 restoration and original file
integrity. GitHub native host CI passed:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36475668731 .
M34 remains unproven on actual CMS.

## M34 real CMS PASS; M35 immediate-subtree link authentication

M34 `GITREC ROOTLINKS` compiled cleanly on
actual z/VM CMS on September 28 at 14:59:57
(ASSEMBLER XF, zero flagged statements,
T=9.10/9.42). Its standard single-page
`GITRUN M34` completed at 15:03:06,
T=183.05/184.48, with every stage passing:
independent complete 1808-object audits
of both immutable GITFIX/M15NEW sealed
generations, seq52 selection, all actual
historic child/parent root direct entries
verified RC0, noncommit/missing child
negative RC8/4, older-generation recovery,
both-unavailable fail closed RC8, restored
seq52, and final protected-file presence.
M34 is real CMS TARGET PROVEN.

M35 introduces
`GITREC NESTLINKS C0NAME C1NAME COMMIT_OID40`.
It retains all M34 checks and additionally
opens each immediate subtree linked by the
specified commit's root and every parent
root. Every entry INSIDE each immediate
subtree must resolve to a staged Git object
of the mode-appropriate blob/tree type
and independently SHA1-authenticate.
Nested linked trees must also parse
structurally. External Gitlinks (160000)
are skipped. The traversal is intentionally
bounded to root plus one extra subtree level,
not an unbounded recursive repository scan.
The existing 256 direct-entry limit per
tree and a shared 1024-tree budget bound
resource use on CMS. A failure returns
RC4 for a missing linked object or RC8
for wrong type/structural invalidity.
No partial parent records or success
marker are emitted before all child and
parent root/subtree links pass.

The native C89 host fixture remains 1808
staged objects and now has 41 distinct
objects. M35 tests two valid synthetic
merge parents, a zero-parent root, a
missing nested blob, a wrong-type nested
blob, a missing entry inside a merge
parent's nested tree, seq51 fallback,
both unavailable fail-closed and restored
seq52. It explicitly proves M34 ROOTLINKS
passes the otherwise structurally valid
trees for which M35 NESTLINKS fails.
The standard M35 single-page `GITRUN`
preserves all independent audits,
historical-commit checks, negative child
cases, recovery, both-unavailable RC8,
restoration, final protected originals
and in-memory PIPE CMS-to-STEM capture.
All source lines remain <=72 characters.
Full native host CI PASSED:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36476834575 .
M35 live CMS compilation and gate remain pending.

## M36 and M37: batched depth-verification development

User requested maximum independent engineering per assistant turn.
To minimize real CMS transfer/build/testing overhead, the next
standard target batch combines the previously host-proven but
not yet target-tested M35 with two newly completed milestones.

M36 adds `GITREC DEEPLINKS C0 C1 COMMIT_OID40`.
It generalizes the verified M35 immediate-subtree implementation to
authenticate linked contents through TWO successive subtree levels
under the child and all parents' roots. It first SHA1-verifies and
structurally parses each commit and root, then checks every encountered
mode-appropriate blob or tree. A shared 1024-tree budget and 256
direct-entry-per-tree cap bound CPU and memory. Root/tree graph
traversal stops at the specified depth; it is not an unbounded
recursive validator. Gitlinks (160000) are deliberately external
references and skipped. Output is atomic: no parent-list records
or DEEP ROOT LINKS VERIFIED marker until the entire request passes.

M37 adds the user-selectable command
`GITREC DEPTHLINKS C0 C1 COMMIT_OID40 DEPTH`,
where DEPTH must be exactly one decimal digit in 0..4.
Depth 0 checks the roots and all direct entries, depth 1 also
checks entries of their immediate subtrees (M35), depth 2
adds the next nested level (M36), and 3/4 continue deeper
within the same fixed resource budget. A missing linked
object returns RC4; type/structural mismatch, exceeded
256-entry or 1024-tree budget returns RC8. It emits
LINK DEPTH N VERIFIED and complete short parent OID/tree
records only after all checks pass. Original ROOTLINKS and
NESTLINKS are retained unchanged at depths 0 and 1.

Strict native C89 host tests exercise all five selectable
depths on a synthetic multi-level Git tree, missing and
wrong-type objects that pass shallower depth 0..2 checks
but fail at depth 3, equivalent corruption in the second
parent of a merge, invalid depth strings, missing/noncommit
child, 257-entry root limit, seq51 recovery, two unavailable
generations fail-closed and seq52 restoration. The synthetic
fixture remains 1808 staged objects with 63 unique content
objects; the real CMS originals remain the immutable two
1808-unique-object GITFIX/M15NEW sealed generations.
Every `GITREC.C` source line stays <=72 columns; success
records stay <=80 columns.

The ONE standard compact `GITRUN` is now M37, and its
single actual-CMS run validates all THREE milestones:
M35 NESTLINKS, M36 DEEPLINKS and M37 DEPTHLINKS
depth 2 on the existing historical original commit and
known parent/tree OIDs. It retains both full original
audits, seq52 selection, invalid depth RC4, noncommit
RC8, missing child RC4, seq51 recovery, both-generation
failure RC8, seq52 restoration and original pre/post
protected file STATE. No auxiliary CMS runner, output
files or protected mutations. GitHub C89 native, source
guards and full CI passed:
https://github.com/mostangrymike/ibm-sandbox/actions/runs/36478127516
M35/M36/M37 are HOST-PROVEN but still pending a
single real CMS compile and compact GITRUN.


---

## Original: docs/LIVE_PACK_STORAGE.md (complete original record)

# Live PACK stage and index storage after the full A-disk incident

## Verified 2026-10-08 CMS evidence

The CMS MAINT A minidisk is virtual 0191, MNT191, 175 cylinders, 3390,
4 KiB block size, total 31,500 blocks. The M173 generalized stage file
M173NET STAGE A grew to 1,193,994 records and 19,213 blocks before disk
exhaustion/abend; a separate GITPIMP VERIFY 7736 independently verified
objects 1-2624, then failed at object 2625. This stage was **not** a
verified complete generation and was unsuitable for M174.

After the operator executed the exact-file ERASE M173NET STAGE A, CMS
QUERY DISK reported MNT191 with 298 files, 12,229 used and **19,271
free** blocks. The 75 MiB class failed stage was reclaimed. GITFIX,
M15NEW, historical PACK and the retained M171NET PACK/META were not
targets of this cleanup.

The retained input is M171NET PACK A, 2,171,129 bytes, PACK v2,
7,736 objects, SHA1 A705122BC39A3383BC05ABC6C888A1F788B1D067.
M172's independent target census counted 2,432 ordinary, 5,304 OFS,
and zero REF deltas. No M173 real CMS import pass has yet occurred.

## Target layout and safety

A contains existing EXEC/MODULE code, sealed fixtures, and the
M171NET PACK/META. Do **not** place the new generalized M173 stage
on A. The M173 and M174 generated objects belong on a separately
provisioned persistent writable CMS disk, accessed for example as
filemode G. The generalized stages are named M173NET STAGE G and
M174NET INDEX G. M175 and M176 read those artifacts on G, while
M171NET META A stays on the original A disk.

M173CHK, M174CHK, M175CHK, and M176CHK take a mandatory single
non-A CMS filemode letter as their only argument; the new target
checks refuse A or an omitted/malformed argument. M173CHK uses the
native GITPIMP IMPORT CHECKED with its own OBJOUT FILEDEF; M174CHK
uses native GITPIDX BUILD CHECKED with its own IDXOUT FILEDEF.
Both retain CMS STATE RC28 absence protection.

A new M173 run additionally uses CMS QUERY DISK to validate that
the requested filemode is accessed R/W with at least 180,000
4-KiB blocks free (about 703 MiB). This is a *minimum admission
threshold*, not a guarantee about the final stage size; a fresh
1 GiB (or larger) minidisk is a sensible target if supported by
the actual physical storage. M174 requires at least 4,096 blocks
free when building its index on the same disk. The two read-only
M175/M176 gates accept the same explicit data filemode.

C has only 1,694 free blocks and F only 2,052. Other accessed CMS
disks in the reported inventory are R/O. None is a suitable
target for this stage.

## Disk provisioning boundary

Do not assume free unallocated cylinders exist on M01RES, MNT191,
or any of the other actual volumes; their file sizes and CP MDISK
directory allocations are distinct from the CMS free-block count.
Earlier forensic mapping identified MAINT virtual 0191 as real
Rdev 0123, volume M01RES, start cylinder 494, 175 cylinders,
backed by the running Hercules real 0123 dasd1 image under
/home/admin/vm630. This mapping must not be mistaken for a free
allocation range. The September 27 TRKDE 4 allocation-map error
is still a reason to keep a verified independent backup.

Read-only inventory before disk definition:

    CP QUERY VIRTUAL DASD
    CP QUERY MDISK 191 LOCATION
    QUERY DISK

An administrator must inventory all existing allocations on the
proposed CKD real volume(s), their extents and free capacity;
identify an unused virtual device address, correctly reserve the
minidisk in the CP directory (or via authorized DirMaint AMDISK);
verify the underlying Hercules 3390 image and available host
storage; and take an independent backup/snapshot as appropriate.
Do NOT run FORMAT on any existing or uncertain virtual minidisk.
If a *newly allocated* persistent disk has been verified as safe
to initialize, use the version-appropriate IBM CMS FORMAT and
ACCESS procedures with 4 KiB blocks. Avoid any automatic
formatting of virtual device 192 because CMS has special
auto-access behavior for that address.

After a new disk is mounted as G, verify with:

    QUERY DISK G

It must say G and R/W, with at least 180,000 BLKS LEFT before
M173CHK can proceed.

Once a properly sized G exists, on Mac from ibm-sandbox/src:

    git pull
    ./cms-upload.sh M173CHK.EXEC M174CHK.EXEC
    ./cms-upload.sh M175CHK.EXEC M176CHK.EXEC

On CMS, after QUERY DISK G confirms capacity and read/write mode:

    M173CHK G

If and only if M173 passes and retains M173NET STAGE G, build the
M174 GITPIDX module (CMSCLNK GITPIDX PLAIN) before M174CHK G.
Likewise build GITPCAT and GITPTRE per their own PLAIN build
contracts before M175CHK G and M176CHK G. The source of truth
for native module linkage is CMSCLNK and each milestone doc.

Do not rerun M173CHK with no argument or against A. No new
network PACK download is required.

## Cleanup completion — 2026-10-08 11:10

Operator ran exact targeted erases, all Ready RC0:

    ERASE GITREC LISTING A
    ERASE GITCWALK LISTING A
    ERASE GITCIDX LISTING A

Afterward A reports 295 files, 10,361 blocks used, and
21,139 blocks free (33% used). Free space rose from
19,271 to 21,139 blocks, a gain of **1,868 blocks**
(about 7.30 MiB). Original allocation inventory listed
1,171 + 371 + 321 = 1,863 blocks for these three
listings; the observed 5-block discrepancy is from disk
accounting and has not been further diagnosed. No
reformatting or wholesale clean was done. Additional
generated listings remain but reclaiming them is not a
substitute for a separate larger stage disk.


## Provisioning checkpoint after A cleanup (2026-10-08)

The real CMS A disk is now **212 files, 8659 4 KiB blocks
used, 22841 free**; A has been cleaned but still cannot
hold the generalized M173 output. The detailed and
evidence-gated new persistent disk procedure is in
`docs/M173_PERSISTENT_DISK_RUNBOOK.md`.
The new proposed data disk is 1600 3390 cylinders, subject
to actual volume model/extent checks, with M173 admission
requiring at least 180000 4K blocks free after formatting.

The M173/M174 checker sources now preserve failed
generated STAGE/INDEX output for diagnosis rather
than automatically attempting an ERASE, because
an earlier CMS disk error was associated with an
ERASE operation. If a failed output remains it
intentionally blocks re-running the importer or
indexer by STATE; cleanup must be separately
diagnosed, backed up and explicitly authorized.
Do not confuse passing host CI with a provisioned
physical minidisk.
