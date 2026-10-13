# M155–M163 historical milestone archive

This file preserves verbatim the nine historical milestone documents that previously existed as separate files under `docs/`. The original paths remain available in Git history. This is documentation-only consolidation; target-proven modules, sources, tests, and CMS files are unchanged.

---

## Original: `docs/M155_COMPACT_GATE.md`

# M155 compact CMS acceptance output

M153 and M154 are native CMS target-proven as of 2026-10-05. Future target gates should request only a small acceptance subset from the CMS transcript: the full-snapshot verification marker, the decisive milestone summary counts, any one required transition/status line, DATA END when applicable, and the following Ready line. The full authenticated command output remains diagnostic evidence but does not need to be pasted into chat unless a compact gate fails.

For presence-history gates, a sufficient successful transcript is normally 4-6 lines plus Ready. On failure, capture the complete command output for diagnosis.

---

## Original: `docs/M156_PRESENCE_DURATION.md`

# M156 authenticated closed presence duration

M156 adds:

`GIT HISTORYFIRSTPRESENCEDURATION-REF-FULL <commit|ref> <depth> <path>`

The command reuses the authenticated first-parent presence runs from M151-M154.
It reports duration only for a presence run that is bounded by authenticated
ADDED/DELETED transitions on both sides. Current/open and oldest/truncated runs
are not treated as fully closed durations.

For each closed run, the duration is the signed time difference between the
child commit that begins the run and the newer child commit that ends it.
Author and committer clocks are tracked independently. A PRESENT closed run
must begin at ADDED and end at DELETED; an ABSENT closed run must begin at
DELETED and end at ADDED. Violations fail closed.

## Sealed target fixture

Commit:
`486ADAA5B02080720F4B329C6F68550B13C6AA87`

Depth: 5

Path: `src/GITPBWALK.EXEC`

Expected presence states are ABSENT, PRESENT across four commits, ABSENT.
Therefore there are three presence runs and exactly one closed run:

- run 2 state PRESENT
- begin edge 5 status ADDED
- end edge 1 status DELETED
- author duration 50 seconds
- committer duration 50 seconds

## Compact real-CMS gate

Upload `GITVREF.EXEC`, `GIT.EXEC`, and `M156CHK.EXEC`, then run only:

`M156CHK`

At the current M157 wrapper level, success output is three lines. The checker accepts any synchronized level M156 or newer:

```text
M156 LEVEL PASS M157/M157
M156 DURATION PASS RUN 2 PRESENT 50/50
M156 COMPACT TARGET GATE PASS
```

followed by plain `Ready;`. Full verbose output is needed only if this compact
gate fails.

---

## Original: `docs/M157_PRESENCE_AGE.md`

# M157 authenticated current presence age

M157 adds:

`GIT HISTORYFIRSTPRESENCEAGE-REF-FULL <commit|ref> <depth> <path>`

It reuses the authenticated current-presence origin machinery. If the beginning
of the current presence run is known as an ADDED/DELETED change or repository
root, the command reports complete signed author and committer age from that
beginning to the newest commit. If bounded history is truncated before the
beginning, it reports observed spans rather than claiming a complete age.

## Sealed target fixture

Commit:
`6EF11911449C184457F3958ABE4CA7A0692CE8C9`

Depth: 6

Path: `src/GITPBWALK.EXEC`

Expected result:

- current state ABSENT
- current run nodes 6, exact runs 1
- begin known 1
- begin kind CHANGE
- begin edge 6 status DELETED
- author age 268 seconds
- committer age 268 seconds

## Compact target gate

After transferring the M157 wrappers and `M157CHK.EXEC`, run only:

`M157CHK`

Expected output:

```text
M157 LEVEL PASS M157/M157
M157 AGE PASS ABSENT EDGE 6 DELETED 268/268
M157 COMPACT TARGET GATE PASS
```

followed by plain `Ready;`. The checker accepts any synchronized GIT/GITVREF level M157 or newer.


## Combined compact gate through M157

`M157GATE EXEC` runs M155CHK, M156CHK, and M157CHK internally and suppresses
their successful detail. This is the preferred real-CMS acceptance command.

Expected output:

```text
M157GATE M155 PASS
M157GATE M156 PASS
M157GATE M157 PASS
M157GATE COMBINED TARGET GATE PASS
```

followed by plain `Ready;`. If it fails, run only the named compact checker
reported by the failure line; use a verbose history command only if that compact
checker also fails.

---

## Original: `docs/M158_PRESENCE_TIME.md`

# M158 authenticated first-parent presence time

M158 adds:

`GIT HISTORYFIRSTPRESENCETIME-REF-FULL <commit|ref> <depth> <path>`

It composes the authenticated presence-run, chronology, closed-duration and
current-age machinery into a per-run time ledger. Every run is classified as
CURRENT, CLOSED, ROOT, or TRUNCATED.

Complete runs contribute signed author/committer seconds to PRESENT or ABSENT
totals. A truncated oldest run is explicitly incomplete and contributes only
observed span to its own run record; it is never included in complete-time
totals.

## Sealed target fixture

Commit:

`486ADAA5B02080720F4B329C6F68550B13C6AA87`

Depth: 5

Path: `src/GITPBWALK.EXEC`

Expected accounting:

- presence runs: 3
- complete runs: 2
- incomplete runs: 1
- complete PRESENT runs: 1
- complete ABSENT runs: 1
- complete PRESENT author/committer seconds: 50 / 50
- complete ABSENT author/committer seconds: 0 / 0
- run 1: ABSENT CURRENT complete, 0 / 0 seconds
- run 2: PRESENT CLOSED complete, 50 / 50 seconds
- run 3: ABSENT TRUNCATED incomplete, 0 / 0 observed seconds

Compact proof records:

```text
HFPT P1 S 3 2 1 1 1
HFPT P1 T 50 50 0 0
HFPT P1 R 1 ABSENT CURRENT 1 0 0
HFPT P1 R 2 PRESENT CLOSED 1 50 50
HFPT P1 R 3 ABSENT TRUNCATED 0 0 0
```

## Target gate

Transfer `GIT.EXEC`, `GITVREF.EXEC`, and `M158CHK.EXEC`, then run:

`M158CHK`

The checker intentionally executes the authenticated history command directly,
not as a CMS Pipelines stage. Its full report remains visible so target proof
cannot be distorted by the pipeline-capture behavior isolated during M155-M157.
No GITREC rebuild is required.

---

## Original: `docs/M159_PRESENCE_RATIO.md`

# M159 authenticated first-parent presence ratio

M159 adds:

`GIT HISTORYFIRSTPRESENCERATIO-REF-FULL <commit|ref> <depth> <path>`

It builds on M158 complete-time accounting and reports PRESENT/ABSENT shares
in integer basis points (10000 = 100%). Ratios are emitted only when both
complete-time components are nonnegative and their total is positive.
Otherwise the corresponding AUTHOR/COMMITTER ratio is marked unavailable
instead of inventing a percentage.

## Sealed target fixture

Commit:
`486ADAA5B02080720F4B329C6F68550B13C6AA87`

Depth: 5

Path: `src/GITPBWALK.EXEC`

Expected compact proof:

```text
HFPR P1 S 2 1 1 1
HFPR P1 A 1 50 50 0 10000 0
HFPR P1 C 1 50 50 0 10000 0
```

Meaning:
- complete runs: 2
- incomplete runs: 1
- complete PRESENT runs: 1
- complete ABSENT runs: 1
- author complete total: 50 seconds, all PRESENT
- committer complete total: 50 seconds, all PRESENT
- PRESENT share: 10000 basis points
- ABSENT share: 0 basis points

## Target gate

Transfer `GIT.EXEC`, `GITVREF.EXEC`, and `M159CHK.EXEC`, then run:

`GIT LEVEL`
`M159CHK`

The checker invokes the authenticated history command directly rather than
through a CMS Pipelines command stage. No GITREC rebuild is required.

---

## Original: `docs/M160_PRESENCE_COVERAGE.md`

# M160 authenticated first-parent presence coverage

M160 adds:

`GIT HISTORYFIRSTPRESENCECOVERAGE-REF-FULL <commit|ref> <depth> <path>`

It reports structural completeness of the bounded first-parent presence history
used by M158/M159. Coverage is deliberately based on authenticated run and node
counts, not elapsed time, so commit density is not misrepresented as time
coverage.

The report reconciles:
- complete + incomplete presence runs = all presence runs;
- complete + incomplete first-parent nodes = the chain node count;
- each complete/incomplete basis-point pair sums to 10000.

## Sealed target fixture

Commit:
`486ADAA5B02080720F4B329C6F68550B13C6AA87`

Depth: 5

Path: `src/GITPBWALK.EXEC`

Expected compact proof:

```text
HFPC P1 S 3 2 1 6 5 1
HFPC P1 B 6666 3334 8333 1667
```

Meaning:
- 3 presence runs: 2 complete, 1 incomplete;
- 6 chain nodes: 5 in complete runs, 1 in the truncated run;
- run completeness: 6666 basis points;
- node completeness: 8333 basis points.

## Target gate

Transfer `GIT.EXEC`, `GITVREF.EXEC`, and `M160CHK.EXEC`, then run:

`GIT LEVEL`
`M160CHK`

The checker invokes the authenticated history command directly. No GITREC
rebuild is required.

---

## Original: `docs/M161_PRESENCE_FRONTIER.md`

# M161 authenticated first-parent presence coverage frontier

M161 adds:

`GIT HISTORYFIRSTPRESENCEFRONTIER-REF-FULL <commit|ref> <depth> <path>`

It identifies where M160's incomplete structural coverage begins. When history
is depth-truncated, the report names the oldest incomplete presence run, its
state/kind/node count, its start/end step and depth, and—when a complete region
exists immediately before it—the last complete step plus the authenticated
ADDED/DELETED transition edge at the coverage frontier.

This differs from M152 current-presence origin: M152 locates the beginning of
the current run, while M161 locates the boundary between structurally complete
and incomplete bounded history.

## Sealed target fixture

Commit:
`486ADAA5B02080720F4B329C6F68550B13C6AA87`

Depth: 5

Path: `src/GITPBWALK.EXEC`

Expected compact proof:

```text
HFPF P1 S 1 1 3 ABSENT TRUNCATED 1 6 6
HFPF P1 B 5 4 5 ADDED
```

Meaning:
- history is truncated and has a complete/incomplete frontier;
- incomplete run is run 3, ABSENT, TRUNCATED, one node;
- incomplete run occupies step 6 through step 6;
- last complete step is 5 at depth 4;
- frontier edge is edge 5, authenticated status ADDED.

## Target gate

Transfer `GIT.EXEC`, `GITVREF.EXEC`, and `M161CHK.EXEC`, then run:

`GIT LEVEL`
`M161CHK`

The checker invokes the authenticated history command directly. No GITREC
rebuild is required.

---

## Original: `docs/M162_PRESENCE_FRONTIER_DISTANCE.md`

# M162 authenticated first-parent presence frontier distance

M162 adds:

`GIT HISTORYFIRSTPRESENCEFRONTIERDISTANCE-REF-FULL <commit|ref> <depth> <path>`

It extends M161's structural coverage frontier with distance and chronology.
When a complete/incomplete frontier exists, it reports:
- first-parent step distance from HEAD to the first incomplete node;
- first-parent depth distance;
- author/committer span from HEAD to that incomplete node;
- author/committer delta across the frontier edge itself.

Signed chronology is preserved; unlike the M159 ratio, these values are not
suppressed merely because a clock delta is negative.

## Sealed target fixture

Commit:
`486ADAA5B02080720F4B329C6F68550B13C6AA87`

Depth: 5

Path: `src/GITPBWALK.EXEC`

Expected compact proof:

```text
HFPG P1 S 1 5 5 105 105
HFPG P1 E 5 ADDED 55 55
```

Meaning:
- frontier distance is available;
- incomplete history starts five first-parent steps / five depths from HEAD;
- HEAD-to-frontier author and committer span: 105 / 105 seconds;
- frontier edge 5 is ADDED;
- edge author and committer delta: 55 / 55 seconds.

## Target gate

Transfer `GIT.EXEC`, `GITVREF.EXEC`, and `M162CHK.EXEC`, then run:

`GIT LEVEL`
`M162CHK`

The checker invokes the authenticated history command directly. No GITREC
rebuild is required.

---

## Original: `docs/M163_PRESENCE_HORIZON.md`

# M163 authenticated first-parent complete presence horizon

M163 adds:

`GIT HISTORYFIRSTPRESENCEHORIZON-REF-FULL <commit|ref> <depth> <path>`

It reports the fully complete prefix of the authenticated bounded first-parent
presence history. M161/M162 describe where incomplete history begins; M163
reports how far back from HEAD the history remains structurally complete.

When a complete prefix exists, the report includes:
- complete-through step and depth;
- step and depth distance from HEAD;
- signed author/committer span from HEAD to the last complete node;
- the next incomplete step and authenticated frontier edge when truncation
  follows the complete prefix.

The complete-node count is reconciled with the complete-through step so the
reported horizon cannot silently skip or include incomplete nodes.

## Sealed target fixture

Commit:
`486ADAA5B02080720F4B329C6F68550B13C6AA87`

Depth: 5

Path: `src/GITPBWALK.EXEC`

Expected compact proof:

```text
HFPH P1 S 1 5 4 4 4 50 50
HFPH P1 F 1 6 5 5 ADDED
```

Meaning:
- complete horizon is available;
- complete history runs through step 5 at depth 4;
- complete horizon is 4 first-parent steps / 4 depths from HEAD;
- HEAD-to-horizon author and committer span: 50 / 50 seconds;
- the next node is incomplete step 6 at depth 5;
- frontier edge is edge 5, authenticated status ADDED.

## Target gate

Transfer `GIT.EXEC`, `GITVREF.EXEC`, and `M163CHK.EXEC`, then run:

`GIT LEVEL`
`M163CHK`

The checker invokes the authenticated history command directly. No GITREC
rebuild is required.
