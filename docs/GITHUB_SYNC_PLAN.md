# GitHub sync minimum

The minimum remote workflow is `clone`, `pull`, and `push` against GitHub over
HTTPS from z/VM CMS. It builds on the existing CMS TCP client and TLS bridge;
it does not assume native CMS TLS is available.

Status (2026-11-11): `clone`, `pull` and `push` are implemented and validated
on the CMS target, within the bounded envelope described below.

## User-visible contract

- `GIT CLONE <https-url>` creates a repository in an empty CMS file area,
  checks out the advertised default branch, and records its upstream.
- The initial implemented pull entry point is
  `GIT PULL remote bridge port pack index [branch|HEAD]`. It advances only a
  clean, mapped current branch when the selected remote branch is a
  fast-forward.
- `GIT PUSH` publishes the current branch only when the remote still has the
  expected old commit. It reports rejected/non-fast-forward updates without
  changing local refs.
- Push credentials are stored in a CMS credential file and are never printed
  in command output. Public clone/pull do not require a credential. CMS disk
  access controls govern who can read a stored credential.
- Credentials can be imported as an API key/PAT or as a username plus a
  password-field PAT. GitHub no longer accepts account passwords for HTTPS Git
  operations.
- The configured TAP/stunnel gateway is inside the credential trust boundary:
  CMS sends its HTTP request to that gateway, which forwards it to GitHub over
  verified TLS.
- The initial supported checkout is one branch and CMS-compatible mapped text
  files. Binary or otherwise unrepresentable workfiles, unsupported path
  changes, divergent pulls, and unsupported GitHub server responses fail
  before publishing a partial result.

## Implementation order

1. **M262-M268 implemented in source:** add bounded GitHub remote metadata,
   API-key and username/password-field credential imports, and Basic
   authentication for upload-pack discovery/download. Stored credentials are
   sent only to `github.com` and are never printed. M264 resolves `HEAD` from
   the GitHub symref and checks the advertised OIDs. M266's `GIT FETCH-PACK`
   stores the downloaded pack, checks its metadata, and independently verifies
   its checksum. M267 imports that retained pack into a new stage on a
   separately provisioned non-A data disk, then rereads and verifies every
   staged object. M268 verifies the stage again, audits an index, confirms the
   advertised commit's tree closure, then installs loose objects on the
   repository's selected object disk. It does not update refs. CMS target
   validation passed on 2026-10-19 with an isolated three-object fixture; the
   protected M173 stage and M174 index were left intact.
2. **M269 remote-tracking refs implemented and CMS-validated:** `GIT
   FETCH-TRACK` uses `GITUPD` compare-and-swap checks to create or advance
   `refs/remotes/<remote>/<branch>`. `GIT BRANCH -r [remote]` lists those
   records from the CMS REF2 database. On 2026-10-19, CMS created a synthetic
   tracking ref, listed `origin/main`, rejected a repeated create as stale,
   then deleted only that fixture ref with its expected OID. Readback
   confirmed the original local `main` ref was unchanged and no remote test
   ref remained. The unborn-branch initialization path is exercised by the
   M274 clone (2026-11-10). Pull, clone and push now advance
   `refs/remotes/<remote>/<branch>` through `GITUPD` compare-and-swap checks.
3. **M270 REF2 resolution fix implemented and CMS-validated:** `GITVREF`
   preserves the complete ref name while validating each record. CMS now
   lists `* main` and `GITVREF SHOW refs/heads/main` resolves the expected
   commit and verifies its root closure. `GIT BRANCH -r` also returns its
   clean empty result after the fixture ref is removed.
4. **M272 flat-tree checkout implemented and functionally CMS-validated.**
   The bounded implementation maps flat Git filenames to CMS file IDs, refuses
   overwrites/collisions and unsupported tree modes, preflights every text blob,
   then writes the full set and extends the worktree map. A two-file fixture
   checkout and independent workfile hashes passed on CMS; no ref update ran.
5. **M273 fast-forward pull implemented and CMS-validated.** The first
   supported pull is explicit-argument and limited to an unchanged flat set of
   CMS-compatible regular text paths. Measured tip-to-tip runs (including
   `PULL COMPLETE` and `Already up to date`) are recorded in
   `docs/M273-SHALLOW-PULL.md`. No-argument pull reads the first configured
   remote plus an optional `GITBRIDG CONFIG A` endpoint.
5b. **M274 clone CMS-validated (2026-11-10).** `GIT CLONE` validates the URL,
   discovers the advertised default branch, initializes a branch-aware unborn
   repository, runs the pull path, creates the branch ref, and checks out the
   flat worktree in one command. It accepts a dedicated project minidisk
   accessed as `A` and checks free space after the fetch, before import. A
   clean clone of `mostangrymike/cms-git-push-test` (`testmin`, one file)
   completed in about two seconds with a clean `GITWT STATUS`; see the dated
   entry below.
6. **M281 push implemented and CMS-validated (2026-11-10):** outbound
   reachable-object collection and pack writing (`GITPMK`), GitHub
   `receive-pack` negotiation, authenticated push, and server `report-status`
   handling. A fast-forward push to `mostangrymike/cms-git-push-test` returned
   HTTP 200 and the verified remote ref. Force updates, ref deletion, tag
   pushes and multi-ref pushes are unsupported; a rejected update is reported
   without changing local refs.
6b. **M281 push hardening CMS-validated (2026-11-11):** a ref-only update whose
   target commit is already advertised still sends a canonical zero-object
   pack, because GitHub rejects a command pkt with no pack. The receive-pack
   command pkt payload ends with LF so GitHub emits `report-status`, and
   response bodies split across TCP segments are parsed. Pack data is
   coalesced into ~32 KB raw buffers before `Socket('Send')`; per-record sends
   previously cost ~18 ms each and timed out mid-upload. The tracking-ref
   rewrite preserves the existing `HEAD` case and every existing REF OID and
   appends the new canonical `refs/remotes/<remote>/<branch>` record. Every
   advertised remote tip is pruned from the local closure walk, and a
   fast-forward that cannot be proven (for example in a shallow repository)
   is refused rather than guessed. Live CMS pushes of `main`, `probe3`,
   `probe4` and `probe5` to `mostangrymike/cms-git-push-test` returned
   `unpack ok`, `accepted refs/heads/<branch>` and `PUSH COMPLETE`; repeated
   pushes report `Already up to date`; a non-fast-forward update was refused
   with the remote left unchanged.
6c. **Loose-store `GIT LOG` implemented and CMS-validated (2026-11-11):**
   `GIT LOG [-n count] [revision]` previously required the protected native
   GEN2 fixtures. `GITVREF` now prefers a bounded first-parent walk of the
   activated loose store and falls back to the native reader when the starting
   commit is absent there. The loose path re-hashes every commit and tree,
   verifies each referenced blob's recorded OID, type, size and DATA length,
   then emits `LOG LOOSE SNAPSHOTS VERIFIED`, `LOG DATA BEGIN`, node/COMMIT
   records, `LOG NODES` and `LOG DATA END`. It deliberately does not recompute
   blob SHA-1: activation already hashed each blob, and one 900 KB REXX SHA-1
   verification took 176 s on the target. Live CMS `GIT LOG -n 1` and `-n 3`
   on `main` matched the host commit trees, parents and message byte counts;
   `GIT BRANCH` and `GITWT STATUS` were unchanged.
7. Validate each CMS command on the real z/VM target. Host CI alone cannot
   establish CMS runtime behavior. `clone`, `pull` and `push` now have target
   validation; the refusal and recovery paths listed below remain host-only.

## Existing building blocks and gaps

`GITFETCH` discovers GitHub upload-pack refs and `GITPOST` downloads a
single-want upload-pack response. Live CMS-to-GitHub transport through the
TLS bridge is documented in `README.md`. `GITPIMP` validates and imports a
bounded pack into a staging format, while `GITWT` and `GITVREF` provide local
worktree and ref operations.

The data path now has a guarded route from a verified stage to ordinary loose
objects on the repository's selected object disk. Fast-forward pull has a
CMS-validated explicit-argument implementation and a configured no-argument
form; clone is CMS-validated (2026-11-10). Nested trees, path
additions/removals, binary workfiles, and divergent pulls are outside the
initial pull slice; those refusals are host-guarded but have not been exercised
on the target. Push is proven separately by M281.

## M262-M267 command surface

- `GIT REMOTE` lists configured remotes; `-v` prints their HTTPS URLs.
- `GIT REMOTE ADD name https://github.com/owner/repository[.git]` adds one.
- `GIT REMOTE GET name` emits a machine-readable host/repository record.
- `GIT REMOTE REMOVE name` removes one.
- `GIT CREDENTIAL IMPORT github-user` imports a single `TOKEN <value>` record
  or `APIKEY <value>` record from `GHTOKEN REPO A` into `GHCRED REPO A`; the
  temporary input is erased after readback verification.
- `GIT CREDENTIAL IMPORT-USERPASS` imports exactly two records from
  `GHPASS REPO A`: `USER <name>` and `PASSWORD <personal-access-token>`.
  The stored username and password-field token are sent as HTTP Basic
  credentials. GitHub account passwords are unsupported for HTTPS Git; use a
  personal access token in the password field.
- `GITFETCH` and `GITPOST` read `GHCRED REPO A` when it exists and send an
  HTTP Basic Authorization header only to `github.com`. They fail closed if
  the stored credential record is malformed.
- `GIT CREDENTIAL STATUS` reports only the stored account; `REMOVE` deletes
  the stored credential. Tokens are kept as plain CMS records, so access to
  the CMS minidisk controls access to the credential.
- `GIT FETCH-PACK remote bridge port new-file [branch|HEAD]` resolves a
  configured GitHub remote, discovers the requested branch (default `HEAD`),
  downloads the single-want pack to `<new-file> PACK A`, crosschecks its
  metadata, and runs `GITPCHK` to independently verify its checksum. A failed
  post-download check retains the pack for diagnosis. This command does not
  install objects or update refs.
- `GIT FETCH-IMPORT new-file data-filemode` imports the retained pack to a new
  `<new-file> STAGE <data-filemode>`, crosschecks pack/import metadata, and runs
  `GITPIMP VERIFY` against the staged file. The data disk must be a separately
  provisioned non-A read/write 4KB disk with at least 180,000 free blocks;
  follow `docs/M173_PERSISTENT_DISK_RUNBOOK.md` before running it. REF_DELTA
  packs are rejected. The stage is isolated and does not update the active
  object generation or refs. Failed output is retained for diagnosis.
- `GIT INIT data-filemode` selects the dedicated disk for loose Git objects;
  repository metadata and refs remain in the CMS file area.
- `GIT FETCH-ACTIVATE stage-file index-file data-filemode` verifies the staged
  objects and requested commit closure, then installs the commit's required
  loose objects on the selected repository disk. It does not create refs or
  check out workfiles. The stage and index remain available for retry/recovery.

These milestones establish remote configuration, credential storage, verified
pack download/import, and activation into the local object store. They did not
by themselves make `push`, `pull`, or `clone` available; those were added and
validated in M273, M274 and M281 (items 5, 5b and 6 above).

## Initial CMS validation gate — 2026-10-19 (before G attachment)

The live z/VM target reported CMS Level 27, Service Level 1302. A complete,
integrity-verified `QUERY DISK` showed writable A with 22,337 free 4KB blocks
and writable C with 1,502 free 4KB blocks; G was not accessed. `FILEDEF`
reported no user-defined file definitions. `STATE GITMETA REPO A` and
`STATE GITPLOAD MODULE A` both returned CMS RC 28 (file not found). No source
was uploaded, compiled, or run on this target.

At this point M268 was **not validated**. The protected production stage/index
were not a safe activation target. The later G attachment and isolated CMS
validation are recorded below.

### Follow-up: CMS G disk attached — 2026-10-19

After reviewing `docs/M173_DIRECTORY_CHANGE_PLAN.md`, live CP checks confirmed
virtual 0600 maps to MAINT's VMCOM1/RDEV0127 extent at cylinders 6000–7599,
3390, 1,600 cylinders, R/W. `CP QUERY VIRTUAL 0600` matched that mapping;
the active directory query returned RC0. `CP QUERY LINKS 0141` returned
RC40 (`Device 0141 does not exist`). The disk was not already accessed as a
CMS filemode, so `ACCESS 600 G` succeeded with RC0. `QUERY DISK G` then
reported `GIT600`, VDEV 600, R/W, 3390, 4096-byte blocks, 1,600 cylinders,
2 files, 62,526 blocks used and 225,474 free. Read-only `STATE` checks
confirmed the protected `M173NET STAGE G` and `M174NET INDEX G` remain present;
`GITMETA REPO A` remains absent. No files were uploaded or changed.

The first source snapshot attempt failed in the CMS reader helper and left its
capture unresolved (`Ready(00012)` after an HX recovery). At that time, source
replacement, compilation, and M268 execution were still pending. The later
validation below used a different verified transfer path and kept the existing
stage/index intact.

### M268 CMS target pass — 2026-10-19

The active z/VM 6.3 CMS Level 27 SL1302 session used `G` on the attached 0600
minidisk. Before testing, the three existing EXECs were copied to new backup
files on A and verified with `COMPARE`. The remote-fetch activation touched
only newly named `Z268TS*` files and loose test objects on G; it did not rebuild
or overwrite `M173NET STAGE G` or `M174NET INDEX G`.

`GITPLOAD C A` was transferred as 215 fixed 80-byte records and built on CMS
with `CMSCLNK GITPLOAD PLAIN` (RC 0, no statements flagged). The existing
`GITPCAT MODULE A` was also confirmed present. `GIT INIT G` completed at RC 0.
An isolated local one-commit pack was independently checked by Git, uploaded in
the CMS hexadecimal-record format, and imported with `GIT FETCH-IMPORT Z268TS2
G` (RC 0, 3 objects).

The first activation attempt exposed a source bug: M268 passed a commit OID to
`GITPTRE WALK`, which accepts a tree OID. `GITFACT EXEC` now reads the commit
through `GITPCAT INFO`, validates the single root-tree record and pass marker,
then walks that tree. The corrected `GIT FETCH-ACTIVATE Z268TS2 Z268TS3 G`
completed with RC 0: 3 objects installed, 0 already present, 0 tags skipped.
`GIT VERIFY-OBJECT` independently returned `OK` for the test commit. Final
`QUERY DISK G` showed 225,466 free blocks; `STATE` confirmed both protected
M173/M174 files remain present. The exact `Z268TS` test files and loose objects
are retained as CMS validation evidence.

The active Codex CMS tool process still holds its old upload-root argument;
the persistent config now points at `cms-git`. Its temporary detached
transfer worktree at the old path remains available until that process is
restarted.

### M269 remote-tracking refs CMS pass — 2026-10-19

`GIT FETCH-TRACK origin main <fixture-commit>` returned RC 0 and wrote
`refs/remotes/origin/main` alongside the pre-existing local `main` in
`GITREF2 REPO A`. `GIT BRANCH -r` returned RC 0 and listed `origin/main`.
Repeating the create-only update returned RC 8 for a stale compare-and-swap
expectation. A one-use cleanup EXEC then deleted only the synthetic tracking
ref with its exact expected OID (RC 0). Final readback showed the original
local `main` record unchanged, and `GIT BRANCH -r` reported no remote-tracking
branches. `GIT INIT` was also invoked against the existing repository; it
correctly left it unchanged, but the new unborn-repository initialization path
still needs a separate CMS fixture. `M173NET STAGE G` and `M174NET INDEX G`
remain present; `QUERY DISK G` reports 225,466 free blocks.

### M270 REF2 resolution CMS pass — 2026-10-19

Before replacing `GITVREF EXEC A`, it was copied to the new
`GTV270BK EXEC A`; `COMPARE` returned RC 0. The updated EXEC was uploaded and
validated on CMS. `GIT BRANCH` returned `* main` (RC 0), and
`EXEC GITVREF SHOW refs/heads/main` resolved the expected
`00D8D63229305230C8D37F884CE87F9E1A89468C` commit and reported the full root
closure verified (RC 0). `GIT BRANCH -r` returned the clean empty result (RC
0) after M269's fixture cleanup. No object, branch, stage, or index data was
changed by this milestone.

### M271 single-file checkout CMS pass — 2026-10-19

The initial `main` checkout attempt returned RC 8 because `main` points to an
older commit on A1, outside the three-object fixture stored on G. The correct
fixture commit, tree, and blob each returned `OK` from `GIT VERIFY-OBJECT`:
`6ACDD9722B30C35143F267179EC5FC266C3A40B9`,
`B89200E09012ECB9ADDF33211D482C2CA6111A27`, and
`1A9E9EB8561B10E9D146BFE9933974882B74940E` respectively.

Before replacing `GITWT EXEC A`, it was copied to `GTV271BK EXEC A`; CMS
`COMPARE` returned RC 0. The final root-tree fix converts the ASCII object
header through the existing `asciitocms` routine before validating its OID.
The intermediate uploaded candidate was also backed up as `GTV271B2 EXEC A`
and compared with RC 0 before the final upload. Both backups are retained.

With `GITWORK REPO A` and `Z271TS1 TEXT A` confirmed absent (RC 28),
`EXEC GITWT CHECKOUT 6ACDD9722B30C35143F267179EC5FC266C3A40B9 README.txt
Z271TS1 TEXT A` returned CMS RC 0. It reported the expected blob OID and
`FINAL-LF 1`. `TYPE Z271TS1 TEXT A` returned the fixture text, and
`GIT HASH-WORKFILE Z271TS1 TEXT A 1` returned the same blob OID. The worktree
map now exists; no ref was changed.

The upload completed for 2,667 fixed-80 records. A full-file readback of the
large `GITWT EXEC A` exceeded the capture deadline at sequence 810; the guarded
reconnect/HX path stopped that incomplete read, and `cms_restart_runner`
accepted the resulting stable `F 810 ACK` / `Ready(12)` boundary. The runner
was reverified and a read-only CMS-level query passed. The checkout execution
and workfile hash provide CMS validation; full source readback remains
unverified. No multi-file tree materialization was attempted.

A follow-up full readback used the raised 1,800-second download budget and
900-second per-command ceiling. It still stopped at sequence 1,017 of 2,667
records and wrote no snapshot. After guarded HX recovery and reconnecting only
terminal 0200, `GIT HASH-WORKFILE GITWT EXEC A 1` returned CMS RC 0 and blob
OID `B83B122AFA3B804DF05BEAB5AE7D07C89CB92FC5`. This exactly matches local
`git hash-object src/GITWT.EXEC` (`b83b122afa3b804df05beab5ae7d07c89cb92fc5`).
The local source has 2,667 lines, a final LF, no trailing blanks and a maximum
line length of 77, so the CMS workfile hash verifies the uploaded source text
after fixed-80 record padding is ignored. CMS returned to Ready; no source or
repository data was changed by the hash check. A full local CMS snapshot remains
unavailable, and no multi-file tree materialization was attempted.

### M272 flat-tree checkout — implementation uploaded, target run pending

`GITWT CHECKOUT-TREE <commit>` and the `GIT CHECKOUT-TREE` route now support a
root tree of up to 50 regular mode-100644 text files. A flat path `NAME.ext`
maps to `NAME EXT A`; a name without an extension maps to `NAME TEXT A`.
Directories, executable files, symlinks, binary/non-printable content, names
that cannot map to CMS IDs, existing targets and mapping collisions are rejected
before workfiles are written. CMS target files are written only after all entries
pass preflight; the map is then updated, with a saved prior map for recovery if
that write fails. Nested directories and Git mode preservation remain outside
this slice.

Before replacement, `GITWT EXEC A` was copied to `GTV272BK EXEC A` and
`COMPARE` returned RC 0. `GIT EXEC A` was copied to `GTV272G1 EXEC A` and
`COMPARE` returned RC 0. Both updated files were uploaded to A as fixed-80
ASCII records. `GIT HASH-WORKFILE GITWT EXEC A 1` returned
`132738D168F672516B09570F3D7504D18E0B0B2F`, matching local `git hash-object`
for `src/GITWT.EXEC`; `GIT HASH-WORKFILE GIT EXEC A 1` returned
`571F114FA1DEE10F0195A49DB9F480B5A1ABE687`, matching local `git hash-object`
for `src/GIT.EXEC`. `GIT CHECKOUT-TREE` with no argument reached the new CMS
usage output and expected RC 4, which confirms that CMS parsed and routed the
EXECs. The actual checkout has not run.

The two-file fixture source is retained locally as `src/Z272TR.REPO`. Its
intended CMS target `Z272TR REPO A` previously returned STATE RC 28 after a DFT
attempt failed before transfer start; no fixture file was created. On the
resumed run, login reached a z/VM reconnect banner with `RUNNING` and an empty
field, but no visible `Ready;` prompt. The tooling had incorrectly classified
this banner as CMS Ready and offered a reconnect-field blank-Enter startup
path; both were removed. IBM documents `RUNNING` under CMS as ready for a
command ([z/VM V6.4 status notices](https://www.ibm.com/support/pages/zvm/library/640pdfs/64619406.pdf)),
so the command runner now accepts only this exact formatted, empty reconnect
field as an input boundary while retaining `vm_running` as the screen state.
Command completion still requires correlated Ready/RC evidence. Codex CLI has
no top-level `--allow-input` option; it is a Python CMS MCP server argument.
The active M272 registration now includes that server argument under the
operator's standing CMS authorization.

The corrected source-verification receive for `ZMD898D4 EXEC A` again failed
to start within 30 seconds and exposed a formatted `MORE...` page followed by
the current host identifier `TACOTICO`. That host identifier may change and is
not part of the MORE marker.
IBM documents MORE as additional output waiting for a screen advance; Clear or
PA2 requests the next screen, while Enter changes the state to HOLDING ([IBM
z/VM 7.3 documentation](https://www.ibm.com/docs/en/zvm/7.3.0?topic=shell-understanding-3270-screen)).
The scoped tool sent one Clear, then observed an unformatted screen. That was
not a verified next page. Its success check has been tightened to require a
changed, formatted, readable screen; an unformatted buffer is not counted as
successful advancement. The current page-advance tool now waits through a
transient blank screen for a readable next page, but does not send another key.
After re-login, the source receive again timed out and showed `IND$FILE GET
ZMD898D4 EXEC A` above `MORE...`, followed by host identifier `TACOTICO`. The updated page tool sent one Clear
and waited 30 seconds; no formatted next screen appeared, only the unformatted
buffer. A bounded fresh-screen capture did not recover a readable CMS prompt,
so the emulator disconnected from 0200.

IBM's [z/VM CP status-indicator reference](https://www.ibm.com/docs/en/zvm/7.2?topic=console-cp-status-indicators)
describes the automatic MORE advance pause as dependent on terminal settings;
the roughly one-minute pause seen on this target is a local observation, not an
IBM-wide fixed interval. Clear or PA2 advances immediately, and Enter changes
MORE to HOLDING, as documented in [Understanding the 3270 Screen](https://www.ibm.com/docs/en/zvm/7.3.0?topic=shell-understanding-3270-screen).
The stock local s3270 build cancels IND$FILE after 30 seconds, before the
target's observed pause can expire. A local upstream s3270 4.5ga6 build now
uses a 90-second DFT-start window; the prior runner preparation limit was 120
seconds.
On the prior read-only source verification, s3270's Transfer action returned,
but the terminal never returned to a formatted CMS Ready screen. The local
temporary download was removed before comparison, so `ZMD898D4 EXEC A` remains
unverified. Passive screen waits also remained unformatted, and the emulator
was disconnected. No fixture upload, synthetic commit, ref update, or checkout
ran; the existing M272 EXECs and backups remain on A.

On 2026-10-19 the operator gave Codex standing authorization to take any action
on CMS without per-action confirmation and asked that it be retained for future
reference; the authorization is recorded in the tooling repository's
`AGENTS.md`. A fresh 0200 connection and one-shot login reached the z/VM
reconnect display with an empty command field and `RUNNING`. The subsequent
read-only `STATE ZMD898D4 EXEC A` submission showed `MORE...` followed by host
identifier `TACOTICO`, but
neither that output nor the following transfer error established whether the
helper exists. A Clear left an unformatted screen. The first PA2 implementation
reported a page advance before the next snapshot revealed that the buffer was
still unformatted. The paging path now requires stable, formatted, nonblank
output after PA2; `_transfer` similarly requires a stable Ready screen. Both
MORE synchronization and runner preparation now allow up to 90 and 240 seconds,
respectively. Runner preparation now compares a received helper file even if
the terminal fails to restore Ready, reporting `source_verified` separately
from `ready_verified`; this prevents a temporary local transfer file from being
discarded before its bytes can be checked. That preservation path has not
reached comparison: the next receive returned `TRANS14 Error reading file from
host`, so `ZMD898D4 EXEC A` remains unverified. The active registration no
longer pins that runner name, allowing an explicitly requested create-only
helper to use a fresh random name. `cms_prepare_runner(create=true)` selected
`ZM0A62CB` and submitted its exact `STATE` absence check, but the command moved
through `vm_running` to `MORE...` and then an unformatted screen without
correlated Ready/RC evidence. It stopped before any upload; no new runner file
was created. The create path now relies on IND$FILE `Exist=keep` for its random
candidate, which fails rather than replacing an existing destination; the
round-trip source comparison remains required before execution. A manual
read-only CMSLEVEL query exhibited the same MORE behavior.
The operator clarified that `TACOTICO` is only the current z/VM host name and
may change; page detection now depends on the MORE marker and never the suffix.
The refreshed MCP process includes `--allow-input`; the previously running
server had been started before that config update and lacked the flag. Its
stale `cms_send` rejected input. A local client launched from the current
registration connected to 0200 and logged in once. Create-only helper
preparation selected `ZM6D541B EXEC A` but returned `TRANS34 CMS file not
found` during the transfer sequence; no source verification was established.
The configured download helper `ZM02EA0B` also failed round-trip source
verification, so it was not used to inspect the candidate. The exact
`STATE ZM6D541B EXEC A` entered at the reconnect field did not yield correlated
Ready/RC evidence. Do not execute, overwrite, or erase `ZM6D541B EXEC A` until
its presence and contents are resolved.

The revised PA2 handler waited 90 seconds and correctly reported no stable
formatted next page. The DFT `Exist=keep` create attempt then used candidate
`ZM9A512F EXEC A` and returned TRANS14. A subsequent read-only receive of that
exact file also returned TRANS14, so it may be absent or partial; its source is
unverified and it must not be executed, overwritten, or erased until its
contents/state are resolved. The dedicated s3270 process was disconnected after
the failed receive. M272 remains at the tooling/terminal recovery stage: no
fixture upload, synthetic commit, ref update, or checkout has run.

Resume once CMS returns a readable formatted screen: reconnect 0200 and log in
once, inspect `ZM9A512F EXEC A` without replacing or erasing it, and establish a
source-verified runner. If a new helper is needed, use explicit
`cms_prepare_runner(create=true)` with its random name and DFT `Exist=keep`, then
require exact round-trip comparison before executing it. After the runner and
command boundary are verified, upload the retained tree fixture, create a
synthetic commit without changing refs, run
`GIT CHECKOUT-TREE <fixture-commit>`, and verify both workfiles and their hashes.
Do not describe M272 as CMS-functionally validated until that run succeeds.

### M272 flat-tree checkout pass — 2026-10-19

The resumed run established that the active configuration had been updated
with `--allow-input`, while the already-running MCP process still lacked it.
Using the current registration, a fresh create-only runner `ZM581503 EXEC A`
was uploaded with DFT `Exist=keep` and passed exact source round-trip
verification. The stale configured download helper `ZM02EA0B` did not match
the local reader source; it was removed from the active registration rather
than reused.

`STATE Z272A TXT A` and `STATE Z272B TXT A` each returned RC 28 before
checkout. The retained three-record fixture was uploaded as
`Z272TR REPO A`; the upload confirmed target presence. CMS parsed it with
`GIT WRITE-TREE-HEXFILE` and produced tree
`355A1AC5B72FA0AE05848883D7A9C9D5B312975A`; `GIT VERIFY-OBJECT` returned RC 0
for that tree. `GIT COMMIT-TREE` created unattached commit
`3F324CA0CE1685FA1579F9E897DB353DE5DF5DC6` with RC 0. No ref update command
was run.

`GIT CHECKOUT-TREE 3F324CA0CE1685FA1579F9E897DB353DE5DF5DC6` completed with
CMS RC 0. It created and mapped `Z272A TXT A` and `Z272B TXT A`, reporting
blob `1A9E9EB8561B10E9D146BFE9933974882B74940E` and `FINAL-LF 1` for both.
Independent `GIT HASH-WORKFILE` commands for both workfiles also returned RC 0
and that exact blob ID. Thus the flat-tree checkout passed on CMS; the fixture,
two output workfiles, worktree map entry and helper remain on A. The final
read-only `EXEC GITVREF SHOW refs/heads/main` capture timed out without a
complete result, so this run records that no ref update was issued rather than
claiming a separately captured post-run ref value.

During this run, CMS command capture exposed two ACK timing cases: VM READ can
briefly lock the field, and after the final ACK the screen may show the exact
`ZA1 <token> <sequence>` echo above Ready after the `Z DONE` row has cleared.
The bridge now waits for unlock at a verified active ACK boundary and accepts
that correlated ACK echo followed by Ready. Capture recovery likewise retains
in-memory token/Ready evidence after PA2 clears the visible completion row.

The final read-only ref-display capture was recovered without replaying it:
the screen showed failed token `F788EDC4624E2EFA`, sequence 4, followed by
`Ready(00012)`. `cms_restart_runner` marked that capture incomplete; source
verification passed again for `ZM581503 EXEC A`; a fresh `STATE Z272B TXT A`
returned RC 0; then `cms_resolve_failed_capture` resumed command capture. The
failed `GITVREF SHOW` result remains incomplete, and no ref update was issued.

### M273 fast-forward pull — source implemented, CMS validation pending

The initial `GIT PULL remote bridge port pack index [branch|HEAD]` path now
fetches a selected branch from a configured GitHub remote through the existing
TLS bridge, verifies and retains the pack, imports and activates its objects,
checks ancestry, preflights a clean mapped worktree, updates the remote-tracking
ref with compare-and-swap, then applies the branch ref and file updates with
rollback snapshots. The selected remote branch must match the current branch.
The worktree map must cover the same flat set of regular mode-100644,
CMS-compatible text files in both commits. Dirty or incomplete maps, path
additions/removals, nested paths, binary blobs and non-fast-forward updates are
rejected. Pack, stage and index files are retained for recovery. This
historical entry predates the 2026-11-07 CMS pull runs; no-argument pull now
reads the configured remote, and clone is implemented on top of this path.

The four changed REXX EXECs (`GIT`, `GITUPD`, `GITVREF`, and `GITWT`) passed
the local Regina syntax parser. The command-runner boundary in `cms-tooling`
now requires a fresh CMS Ready prompt and rejects the ambiguous reconnect
RUNNING banner; its command and startup tests passed locally.

CMS qualification did not run. On 2026-10-20, terminal 0200 reconnected to a
formatted z/VM guest banner with an empty RUNNING field. One null Enter exposed
MORE; one PA2 then produced an unformatted 24x80 all-asterisk buffer. Fresh
status/output checks did not recover a readable page. Later reconnect attempts
also moved to an unformatted buffer after the null-line probe. The emulator was
disconnected without LOGOFF. A fixed `QUERY CMSLEVEL` was typed in the input
field but never submitted. Those early attempts completed no CMS command or
transfer.

A later 2026-10-20 recovery used a fresh terminal and IBM's documented
`LOGON MAINT HERE` form to reconnect the existing MAINT session. A single null
Enter exposed a formatted CMS `Ready;` prompt. The command runner
`ZM581503 EXEC A` passed fresh source verification. Reading the existing
`GIT EXEC A` for backup then stalled during the read-only download capture:
terminal output remained locked on token `7D3472E4A80B67C7`, sequence 165, with
an incomplete data frame. Reattachment later exposed its final F ACK and
Ready(12), so `cms_restart_runner` marked it incomplete and the command runner
was freshly verified. A second read-only capture for `GITUPD EXEC A` also
failed, token `934A58E998021CC8`, sequence 93; it was similarly recovered.
Short `STATE` and `LISTFILE` commands confirmed `GITUPD EXEC A` exists.

`TYPE GITUPD EXEC A` then exceeded its 120-second capture budget and was
interrupted. The following Ready(12) display showed token `04C3A6DC7840B255`,
sequence 62, but its ACK row had a malformed suffix; `cms_restart_runner`
refused the boundary. No M273 EXEC was uploaded or replaced, and no repository
data changed. The two create-runner download attempts may have left random
reader EXECs on CMS A; their names were omitted by the local MCP client
formatter, so preserve any new ZMxxxxxx EXECs pending inventory. M273 runtime
and end-to-end pull remain unvalidated until the bulk source-capture failure
is diagnosed and the existing EXECs are backed up.

**Superseded 2026-11-07:** the shallow pull path subsequently ran on CMS with
measured `PULL COMPLETE` results; see `docs/M273-SHALLOW-PULL.md`.

### M273/M274 pull and clone target pass — 2026-11-10

The updated `GIT`, `GITUPD`, `GITWT`, `GITFETCH`, `GITVREF`, `GITFIMP` and
`GITFACT` sources were uploaded to CMS A through the FTP staging path and each
one was hash-verified with `GIT HASH-WORKFILE ... 1` before replacing the
previous EXEC. The prior `GITFIMP`/`GITFACT` copies were kept as `GIF273BK`
and `GFA273BK`; the earlier metadata set was moved to type `M273BAK`.

A fresh `GIT CLONE https://github.com/mostangrymike/cms-git-push-test.git A
192.168.200.1 8444` completed in one command:

- discovery resolved `HEAD` to `refs/heads/testmin` (`90095C2B`);
- the depth-1 pack (6 objects after the later advance, 435 bytes) imported,
  verified, and activated on the `A` project minidisk;
- the first pull created `refs/heads/testmin`, wrote
  `refs/remotes/origin/testmin`, and materialized `F TEXT A`;
- `GIT BRANCH` reported `* testmin`, `GIT BRANCH -r` reported
  `origin/testmin`, and `GITWT STATUS` reported one clean tracked path;
- `TYPE F TEXT A` and `GIT HASH-WORKFILE F TEXT A 1` matched the Git blob.

`testmin` was then advanced from the Mac to `8AEEFDF1` (one changed file) and
`GIT PULL` on CMS fetched an incremental 3-object pack, reported
`FAST-FORWARD`, wrote `PULLED WORKTREE FILES 1`, and left `F TEXT A` clean at
the new blob. A second no-argument `GIT PULL` reported
`Already up to date 8AEEFDF1...`.

Three target-only defects surfaced and were fixed in source:

1. `GITFACT` checked for a module named `GITPLOAD`, but the installer module
   it actually invokes is `M274L5`. The dependency list now names `M274L5`.
2. `GITWT`'s REF2 reader required at least three records, so it rejected the
   two-line unborn database (`REF2 1` plus `HEAD`). It now accepts two.
3. Every `call bindnative` site compared the routine's numeric `0`/`8` return
   against `'OK'`, so a successful binding always took the failure path and
   checkout could never run. The sites now test `result\=0`.

The test clone was then erased and the `M273BAK` metadata restored. `GIT
BRANCH`, `EXEC GITVREF HEAD` and `GIT BRANCH -r` again report `* main`,
`refs/heads/main`, `origin/main` and `PUSHTEST/main`, with no clone artifacts
on `A`.
