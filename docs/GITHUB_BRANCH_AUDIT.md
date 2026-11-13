# Remote branch audit

Generated 2026-11-13 against `origin/main` at
`63d013e4eeda47ecf260c5f56286c368634b55ce`. Every `origin/*` branch was classified by
three independent signals, because this repository squash-merges
pull requests and ancestry alone is not sufficient:

1. the branch tip is an ancestor of `main`;
2. the branch tip SHA is the head of a **merged** pull request;
3. a commit on the branch is linked to a merged pull request.

Branches that satisfy none of these keep their commits and are
listed separately as retained.

- Remote branches inspected: **190**
- Pruned after review: **172**
- Retained (unique commits): **17**
- Default branch `main` is never pruned.

## Pruned branches

### M38

| Branch | Merged via |
| --- | --- |
| `m38-ci-proof` | #10 |

### M39

| Branch | Merged via |
| --- | --- |
| `m39-subtree-once` | #11 |
| `m39-target-batch` | #12 |

### M40

| Branch | Merged via |
| --- | --- |
| `m40-atomic-directory-path` | #13 |

### M41

| Branch | Merged via |
| --- | --- |
| `m41-verified-directory-links` | #14 |

### M42

| Branch | Merged via |
| --- | --- |
| `m42-depth-recovery-proof` | #16 |
| `m42-directory-depth` | #15 |

### M43

| Branch | Merged via |
| --- | --- |
| `m43-gitlink-budget` | #17 |

### M44

| Branch | Merged via |
| --- | --- |
| `m44-closure-budget-proof` | #19 |
| `m44-full-tree-closure` | #18 |

### M45

| Branch | Merged via |
| --- | --- |
| `m45-directory-full-closure` | #20 |
| `m45-full-directory-recovery` | #21 |

### M46

| Branch | Merged via |
| --- | --- |
| `m46-tree-oid-closure` | #22 |
| `m46-tree-recovery-proof` | #23 |

### M47

| Branch | Merged via |
| --- | --- |
| `m47-pathfull-budget-proof` | #26 |
| `m47-pathfull-recovery` | #25 |
| `m47-pathfull-root-closure` | #24 |

### M48

| Branch | Merged via |
| --- | --- |
| `m48-snapshot-verified-blob` | #27 |

### M49

| Branch | Merged via |
| --- | --- |
| `m49-boundary-proof` | #29 |
| `m49-snapshot-directory-listing` | #28 |

### M50

| Branch | Merged via |
| --- | --- |
| `m50-raw-tree-both-commands-recovery` | #31 |
| `m50-tree-path-closure` | #30 |

### M51

| Branch | Merged via |
| --- | --- |
| `m51-raw-tree-path-metadata` | #32 |

### M52

| Branch | Merged via |
| --- | --- |
| `m52-single-selection-native-batch` | #33 |

### M53

| Branch | Merged via |
| --- | --- |
| `m53-collapse-selector-check` | #34 |

### M54

| Branch | Merged via |
| --- | --- |
| `m54-batched-expected-negatives` | #35 |

### M55

| Branch | Merged via |
| --- | --- |
| `m55-extra-boundary-tests` | #37 |
| `m55-regression-speedup` | #36 |

### M56

| Branch | Merged via |
| --- | --- |
| `m56-batch-seek-index-reuse` | #38 |

### M57

| Branch | Merged via |
| --- | --- |
| `m57-history-full-closure` | #39 |

### M58

| Branch | Merged via |
| --- | --- |
| `m58-history-dag-full-closure` | #40 |

### M59

| Branch | Merged via |
| --- | --- |
| `m59-cms-rexx-gate-fix` | #42 |
| `m59-history-dag-path-full` | #41 |

### M60

| Branch | Merged via |
| --- | --- |
| `m60-show-full-snapshot` | #43 |

### M61

| Branch | Merged via |
| --- | --- |
| `m61-log-full-snapshots` | #44 |

### M62

| Branch | Merged via |
| --- | --- |
| `m62-log-dag-full` | #45 |

### M63

| Branch | Merged via |
| --- | --- |
| `m63-verified-ref-resolution` | #46 |

### M64

| Branch | Merged via |
| --- | --- |
| `m64-verified-ref-log` | #47 |

### M65

| Branch | Merged via |
| --- | --- |
| `m65-ref-path-read` | #48 |

### M66

| Branch | Merged via |
| --- | --- |
| `m66-ref-dir-list` | #49 |

### M67

| Branch | Merged via |
| --- | --- |
| `m67-ref-logdag` | #50 |

### M68

| Branch | Merged via |
| --- | --- |
| `m68-history-path-ref` | #51 |

### M69

| Branch | Merged via |
| --- | --- |
| `m69-history-changes-ref` | #52 |

### M70

| Branch | Merged via |
| --- | --- |
| `m70-history-status-ref` | #53 |

### M71

| Branch | Merged via |
| --- | --- |
| `m71-history-version-counts` | #54 |

### M72

| Branch | Merged via |
| --- | --- |
| `m72-fix-depth-parser` | #56 |
| `m72-history-version-depths` | #55 |

### M73

| Branch | Merged via |
| --- | --- |
| `m73-history-version-commit-range` | #57 |

### M74

| Branch | Merged via |
| --- | --- |
| `m74-version-metadata` | #58 |

### M75

| Branch | Merged via |
| --- | --- |
| `m75-version-depth-set` | #59 |

### M76

| Branch | Merged via |
| --- | --- |
| `m76-version-commit-set` | #60 |

### M77

| Branch | Merged via |
| --- | --- |
| `m77-version-commit-depth` | #61 |

### M80

| Branch | Merged via |
| --- | --- |
| `m80-version-snapshot-membership` | #62 |

### M82

| Branch | Merged via |
| --- | --- |
| `m82-path-edge-changes` | #63 |

### M86

| Branch | Merged via |
| --- | --- |
| `m86-fix-node-version` | #65 |
| `m86-history-edges-ref` | #64 |

### M88

| Branch | Merged via |
| --- | --- |
| `m88-summary` | #66 |

### M93

| Branch | Merged via |
| --- | --- |
| `m93-self-contained-diffs` | #67 |

### M94

| Branch | Merged via |
| --- | --- |
| `m94-history-state` | #69 |

### M98

| Branch | Merged via |
| --- | --- |
| `m98-state-summary` | #70 |

### M100

| Branch | Merged via |
| --- | --- |
| `m100-path-change-log` | #72 |

### M101

| Branch | Merged via |
| --- | --- |
| `m101-path-status` | #73 |

### M105

| Branch | Merged via |
| --- | --- |
| `m105-change-bounds` | #74 |

### M110

| Branch | Merged via |
| --- | --- |
| `m110-history-report` | #75 |

### M111

| Branch | Merged via |
| --- | --- |
| `m111-history-bounds` | #76 |

### M112

| Branch | Merged via |
| --- | --- |
| `m112-exec-level` | #77 |

### M113

| Branch | Merged via |
| --- | --- |
| `m113-direct-commit-history` | #78 |

### M120

| Branch | Merged via |
| --- | --- |
| `m120-chronology-summary` | #80 |

### M123

| Branch | Merged via |
| --- | --- |
| `m123-transition-chronology` | #82 |

### M124

| Branch | Merged via |
| --- | --- |
| `m124-rexx-epoch-precision` | #83 |

### M125

| Branch | Merged via |
| --- | --- |
| `m125-authenticated-subject-prefix` | #84 |

### M126

| Branch | Merged via |
| --- | --- |
| `m126-authenticated-identities` | #85 |

### M127

| Branch | Merged via |
| --- | --- |
| `m127-authenticated-history-actors` | #86 |

### M128

| Branch | Merged via |
| --- | --- |
| `m128-authenticated-history-subjects` | #87 |

### M129

| Branch | Merged via |
| --- | --- |
| `m129-history-body-digests` | #88 |

### M130

| Branch | Merged via |
| --- | --- |
| `m130-authenticated-history-topology` | #89 |

### M131

| Branch | Merged via |
| --- | --- |
| `m131-authenticated-parent-order` | #90 |

### M132

| Branch | Merged via |
| --- | --- |
| `m132-authenticated-parent-slots` | #91 |

### M133

| Branch | Merged via |
| --- | --- |
| `m133-authenticated-edge-roles` | #92 |

### M134

| Branch | Merged via |
| --- | --- |
| `m134-authenticated-first-parent` | #93 |

### M135

| Branch | Merged via |
| --- | --- |
| `m135-authenticated-first-changes` | #94 |

### M136

| Branch | Merged via |
| --- | --- |
| `m136-authenticated-first-transitions` | #95 |

### M137

| Branch | Merged via |
| --- | --- |
| `m137-authenticated-first-chronology` | #96 |

### M138

| Branch | Merged via |
| --- | --- |
| `m138-authenticated-first-actors` | #97 |

### M139

| Branch | Merged via |
| --- | --- |
| `m139-authenticated-first-subjects` | #98 |

### M140

| Branch | Merged via |
| --- | --- |
| `m140-first-body-handoffs` | #99 |

### M142

| Branch | Merged via |
| --- | --- |
| `m142-first-log-report` | #100 |

### M146

| Branch | Merged via |
| --- | --- |
| `m146-first-status-bounds` | #102 |

### M148

| Branch | Merged via |
| --- | --- |
| `m148-first-lifetime` | #103 |

### M150

| Branch | Merged via |
| --- | --- |
| `m150-first-current-origin` | #104 |
| `m150-origin-call-fix` | #105 |

### M152

| Branch | Merged via |
| --- | --- |
| `m152-first-presence-origin` | #106 |

### M154

| Branch | Merged via |
| --- | --- |
| `m154-first-presence-events` | #107 |

### M155

| Branch | Merged via |
| --- | --- |
| `m155-compact-presence-check` | #108 |
| `m155-marker-only-gate` | #116 |
| `m155-public-route-fix` | #113 |
| `m155-summary-parse-fix` | #114 |

### M156

| Branch | Merged via |
| --- | --- |
| `m156-presence-duration` | #109 |

### M157

| Branch | Merged via |
| --- | --- |
| `m157-combined-compact-gate` | #112 |
| `m157-compact-level-compat` | #111 |
| `m157-compact-proof-records` | #117 |
| `m157-fix-historydagstate-nested` | #124 |
| `m157-gitvref-stamp-diagnostics` | #118 |
| `m157-native-state-trace` | #125 |
| `m157-parent-path-probe` | #123 |
| `m157-presence-age` | #110 |
| `m157-preserve-path-case-v2` | #121 |
| `m157-stamp-public-wrapper` | #122 |
| `m157-statepath-s3-trace` | #126 |

### M173

| Branch | Merged via |
| --- | --- |
| `m173-0600-virtual-link-20261009` | #138 |
| `m173-g-disk-formatted-20261009` | #139 |
| `m173-gate5c-20261009` | #128 |
| `m173-gate5c-context-20261009` | #129 |
| `m173-gate5d-20261009` | #130 |
| `m173-gate5e-vmudq-20261009` | #131 |
| `m173-gate5f-vmudq-pass-20261009` | #135 |
| `m173-gate6-readonly-pass-20261009` | #136 |
| `m173-pack-stage-target-pass-20261009` | #140 |
| `m173-postactivation-0600-20261009` | #137 |
| `m173-vmudq-asm-pass-c-policy-20261009` | #134 |
| `m173-vmudq-diag-compile-20261009` | #132 |
| `m173-vmudq-page-guard-20261009` | #133 |

### M174

| Branch | Merged via |
| --- | --- |
| `m174-c-source-transfer-20261009` | #141 |
| `m174-gitpidx-target-build-pass-20261009` | #142 |
| `m174-target-index-pass-20261009` | #143 |

### M176

| Branch | Merged via |
| --- | --- |
| `m176-live-tree-closure-20261009` | #144 |

### M177

| Branch | Merged via |
| --- | --- |
| `m177-info-m175-live-pass-20261009` | #147 |
| `m177-readonly-g-pack-view-20261009` | #145 |
| `m177-tree-live-target-pass-20261009` | #146 |

### M178

| Branch | Merged via |
| --- | --- |
| `m178-forward-only-tree-walker-20261009` | #148 |
| `m178-real-cms-pass-20261009` | #150 |
| `m178-save-state-handoff-20261009` | #149 |

### M179

| Branch | Merged via |
| --- | --- |
| `m179-nonmutating-tree-phase-profiler-20261009` | #151 |

### M180

| Branch | Merged via |
| --- | --- |
| `m180-real-cms-pass-20261010` | #153 |
| `m180-single-forward-stage-20261010` | #152 |

### M181

| Branch | Merged via |
| --- | --- |
| `m181-cms-module-exec-name-collision-fix-20261011` | #155 |
| `m181-hex-validation-table-20261010` | #154 |

### M182

| Branch | Merged via |
| --- | --- |
| `m182-native-hex-pair-table-20261011` | #156 |

### M183

| Branch | Merged via |
| --- | --- |
| `m183-skip-body-length-check-20261011` | #157 |

### M184

| Branch | Merged via |
| --- | --- |
| `m184-comparative-native-host-benchmark-20261011` | #158 |

### M185

| Branch | Merged via |
| --- | --- |
| `m185-direct-skipped-record-validation-20261011` | #159 |
| `m185-real-cms-target-proof-20261011` | #162 |

### M186

| Branch | Merged via |
| --- | --- |
| `m186-skip-validator-differential-20261011` | #160 |

### M187

| Branch | Merged via |
| --- | --- |
| `m187-7736-object-native-scale-fixture-20261011` | #161 |

### M188

| Branch | Merged via |
| --- | --- |
| `m188-real-cms-proof-20261011` | #165 |
| `m188-skipline-common-eol-20261011` | #163 |

### M189

| Branch | Merged via |
| --- | --- |
| `m189-eightway-native-hex-check-20261011` | #164 |

### M190

| Branch | Merged via |
| --- | --- |
| `m190-selective-seek-readback-20261011` | #166 |

### M191

| Branch | Merged via |
| --- | --- |
| `m191-cms-real-seek-results-20261011` | #168 |
| `m191-cms-seek-probe-20261011` | #167 |

### M192

| Branch | Merged via |
| --- | --- |
| `m192-cms-record-number-plan-20261011` | #169 |

### M193

| Branch | Merged via |
| --- | --- |
| `m193-mid-target-pass-checkpoint-20261011` | #172 |
| `m193-native-fsread-cms-probe-20261011` | #170 |
| `m193-real-cms-first-proof-20261011` | #171 |

### M194

| Branch | Merged via |
| --- | --- |
| `m194-fsread-object-probe-20261011` | #173 |

### M195

| Branch | Merged via |
| --- | --- |
| `m195-fix-8char-evenchk-cms-20261012` | #177 |
| `m195-last-complete-body-20261011` | #174 |

### M196

| Branch | Merged via |
| --- | --- |
| `m196-index-object-record-plan-20261011` | #175 |

### M197

| Branch | Merged via |
| --- | --- |
| `m197-canonical-ascii-header-20261012` | #179 |
| `m197-native-object-sha-core-20261011` | #176 |

### M198

| Branch | Merged via |
| --- | --- |
| `m198-protected-fsread-to-scratch-20261012` | #178 |

### M199

| Branch | Merged via |
| --- | --- |
| `m199-record-read-20261012` | #180 |

### M200

| Branch | Merged via |
| --- | --- |
| `m200-cms-filedef-cleanup-20261012` | #181 |

### M201

| Branch | Merged via |
| --- | --- |
| `m201-plan-export-20261012` | #182 |

### M202

| Branch | Merged via |
| --- | --- |
| `m202-two-object-clean-gate-20261012` | #183 |

### M203

| Branch | Merged via |
| --- | --- |
| `m203-bounded-batch-20261012` | #184 |

### M204

| Branch | Merged via |
| --- | --- |
| `m204-one-index-batch-20261012` | #185 |

### M205

| Branch | Merged via |
| --- | --- |
| `m205-index-sampled-sha-batch-20261012` | #186 |

### M206

| Branch | Merged via |
| --- | --- |
| `m206-32band-authenticated-sample-20261012` | #187 |

### Non-milestone branches

| Branch | Merged via |
| --- | --- |
| `a-disk-expanded-exact-cleanup-20261013` | #191 |
| `checkpoint-m206-32-and-audit-20261013` | #189 |
| `maintain-a-disk-cleanup-20261013` | #188 |

## Retained branches

These branches have commits that are not reachable from `main`
and no merged pull request. They are kept until reviewed.
Counts are `git cherry main <branch>`: unique patches / total.

| Branch | Unique patches / total | Diff vs merge base |
| --- | --- | --- |
| `m103a-state-transitions` | 1 / 1 | 1 file changed, 6 insertions(+), 2 deletions(-) |
| `m104-state-depth16` | 2 / 2 | 2 files changed, 23 insertions(+), 4 deletions(-) |
| `m106-state-transitions` | 11 / 12 | 3 files changed, 117 insertions(+), 8 deletions(-) |
| `m114-first-parent-state` | 42 / 42 | 1 file changed, 108 insertions(+), 4 deletions(-) |
| `m118-subject-prefix` | 10 / 10 | 5 files changed, 122 insertions(+), 16 deletions(-) |
| `m118-subject-prefix-v2` | 5 / 5 | 5 files changed, 108 insertions(+), 16 deletions(-) |
| `m121-subject` | 8 / 8 | 4 files changed, 101 insertions(+), 17 deletions(-) |
| `m144-first-nearest` | 11 / 14 | 5 files changed, 271 insertions(+), 15 deletions(-) |
| `m155-capture-diagnostics` | 4 / 4 | 4 files changed, 52 insertions(+) |
| `m157-preserve-path-case` | 21 / 21 | 12 files changed, 232 insertions(+), 127 deletions(-) |
| `m157-state-capture-command` | 9 / 9 | 6 files changed, 261 insertions(+), 7 deletions(-) |
| `m165-clean` | 5 / 5 | 8 files changed, 468 insertions(+), 11 deletions(-) |
| `m165-staged-commit` | 18 / 18 | 11 files changed, 902 insertions(+), 7 deletions(-) |
| `m169-ref-probe` | 3 / 3 | 1 file changed, 115 insertions(+) |
| `m169-wire-probe` | 1 / 1 | 1 file changed, 75 insertions(+) |
| `m207-stratified-128-20261013` | 3 / 3 | 3 files changed, 448 insertions(+) |
| `m97-path-state-history` | 14 / 15 | 4 files changed, 487 insertions(+), 68 deletions(-) |

## Method notes

- `git ls-remote --heads origin` fixed the exact branch set and SHAs.
- Merged pull requests were enumerated from the GitHub REST API
  (`state=closed`, paginated) and matched by head SHA.
- No branch was pruned on name pattern alone.
- Deleting a branch removes only the ref. For every pruned
  branch the change content is already on `main` as a merge
  or squash commit.
