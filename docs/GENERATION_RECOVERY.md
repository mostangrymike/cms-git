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
