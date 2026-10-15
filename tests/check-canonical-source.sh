#!/bin/sh
# Guard workflow trigger parity without changing target or native sources.
if [ "${1:-}" = "WORKFLOW" ]; then
    python3 - "$(dirname "$0")/../.github/workflows/native-stage.yml" <<'PY'
import pathlib
import re
import sys

source = pathlib.Path(sys.argv[1]).read_text()
blocks = re.findall(r"(?m)^    paths:\n((?:      - '[^']+'\n)+)", source)
required = (
    'src/**', 'tests/**', 'scripts/**', 'docs/**', 'archive/**',
    '.github/workflows/native-stage.yml',
)
if len(blocks) != 2:
    raise RuntimeError("expected push and pull_request path lists")
entries = []
for block in blocks:
    paths = re.findall(r"(?m)^      - '([^']+)'$", block)
    if not paths or len(paths) != len(set(paths)):
        raise RuntimeError("empty or duplicate watched paths")
    entries.append(paths)

def valid(left, right):
    return left == right and tuple(left) == required

if not valid(*entries):
    raise RuntimeError("CI source-area watch coverage or parity mismatch")

# Negative cases must reject missing entries, duplicates, reordering,
# untracked areas, and losing coverage from either event trigger.
if not valid(entries[0], entries[1]):
    raise RuntimeError("positive workflow fixture rejected")
for bad in (
    entries[0][:-1],
    entries[0][1:],
    entries[0] + [entries[0][0]],
    entries[0][::-1],
    entries[0] + ['unrelated/**'],
    [],
):
    if valid(bad, entries[1]) or valid(entries[0], bad):
        raise RuntimeError("accepted altered workflow trigger fixture")
for item in required:
    reduced = [p for p in entries[0] if p != item]
    if valid(reduced, reduced):
        raise RuntimeError("accepted missing required area")
print("CI PATH PARITY AND NEGATIVE FIXTURES PASS", len(entries[0]))
PY
    exit $?
fi

# Exercise the full LIVEPLAN inventory with a temporary synthetic Git checkout.
# Never touch production src/, disks, or tracked test fixtures.
if [ "${1:-}" = "LIVEPLANFIX" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
mkdir -p "$tmp/scripts" "$tmp/src"
cp "$root/scripts/restore-cms-exec.py" "$tmp/scripts/"
printf 'address cms\nexit 0\n' > "$tmp/src/ALPHA.EXEC"
cp "$tmp/src/ALPHA.EXEC" "$tmp/src/BETA.EXEC"
printf 'address cms\nALPHA\nexit 4\n' > "$tmp/src/GAMMA.EXEC"
(
 cd "$tmp"
 git init -q
 git add src/ALPHA.EXEC src/BETA.EXEC src/GAMMA.EXEC
 python3 scripts/restore-cms-exec.py LIVEPLAN > "$tmp/report"
)
grep -F 'CMS SOURCE CONSOLIDATION INVENTORY 3' "$tmp/report"
grep -F 'EXACT SOURCE DUPLICATE src/ALPHA.EXEC src/BETA.EXEC' "$tmp/report"
grep -F 'EXACT DUPLICATE GROUPS 1 FILES 2' "$tmp/report"
grep -F 'SOURCE_CALLER src/ALPHA.EXEC FROM src/GAMMA.EXEC' "$tmp/report"
digest=$(python3 -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$tmp/src/ALPHA.EXEC")
grep -F "SOURCE src/ALPHA.EXEC FAMILY OTHER TOKEN_CALLERS 1 SIZE_BYTES 19 SHA256 $digest" "$tmp/report"
grep -F "SOURCE src/BETA.EXEC FAMILY OTHER TOKEN_CALLERS 0 SIZE_BYTES 19 SHA256 $digest" "$tmp/report"
grep -F 'CMS SOURCE INVENTORY COMPLETE 3' "$tmp/report"
grep -F 'NOT DELETION AUTHORIZATION' "$tmp/report"
printf '/* same CMS stem, different source type */\n' > "$tmp/src/ALPHA.C"
(
 cd "$tmp"
 git add src/ALPHA.C
 if python3 scripts/restore-cms-exec.py LIVEPLAN > "$tmp/negative" 2>&1; then
  echo 'FAIL: ambiguous CMS source stem accepted' >&2
  exit 1
 fi
)
echo 'LIVEPLAN SYNTHETIC POSITIVE AND NEGATIVE FIXTURES PASS'
)
exit $?
fi

# Independent native C89 staging integration test retained verbatim.
if [ "${1:-}" = "NATIVE" ]; then
(
# Host-only test: does not replace GCCCMS compilation or target tests.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
${CC:-cc} -x c -std=c89 -O2 -Wall -Wextra \
    -o "$tmp/native_stage_host" "$root/tests/native_stage_host.c"
(
 cd "$tmp"
 ./native_stage_host > host.log
)
actual=$(sed -n 's/^HOST ABC OID //p' "$tmp/host.log")
expected=$(printf abc | git hash-object --stdin)
if [ "$actual" != "$expected" ]; then
 echo "Expected Git OID: $expected" >&2
 echo "Native Git OID:   $actual" >&2
 exit 1
fi
${CC:-cc} -x c -std=c89 -O2 -Wall -Wextra -Werror \
    -o "$tmp/native_recovery" "$root/src/GITREC.C"
${CC:-cc} -x c -std=c89 -D_POSIX_C_SOURCE=200809L \
    -O2 -Wall -Wextra -o "$tmp/native_index_host" \
    "$root/tests/native_index_host.c"
(
 cd "$tmp"
 ./native_index_host > index.log 2>&1 || {
  status=$?
  cat index.log
  echo "native_index_host failed RC $status" >&2
  exit "$status"
 }
)
for type in commit tree blob tag; do
 for fixture in ABC EMPTY; do
  actual=$(sed -n "s/^HOST OID $type $fixture //p" "$tmp/host.log")
  if [ "$fixture" = ABC ]; then
   expected=$(printf abc | git hash-object -t "$type" \
     --literally --stdin)
  else
   expected=$(printf '' | git hash-object -t "$type" \
     --literally --stdin)
  fi
  if [ "$actual" != "$expected" ]; then
   echo "OID mismatch: $type $fixture" >&2
   echo "Native: $actual Git: $expected" >&2
   exit 1
  fi
 done
done
# Native full PACK integration (host zlib only, not CMS inflater).
python3 "$root/tests/test-m203-bounded-batch.py" BENCH REFPACK "$tmp" > "$tmp/ref-fixtures.log"
# Independently ask Git to index and reconstruct the same REF PACK.
git init -q "$tmp/forwardrepo"
git -C "$tmp/forwardrepo" index-pack --stdin < "$tmp/FCHAIN.bin" \
    > "$tmp/git-index-forward.log"
for blob in abc abcd abcde; do
 oid=$(printf %s "$blob" | git hash-object --stdin)
 git -C "$tmp/forwardrepo" cat-file blob "$oid" > "$tmp/from-forward"
 printf %s "$blob" | cmp - "$tmp/from-forward"
done
git init -q "$tmp/packrepo"
git -C "$tmp/packrepo" index-pack --stdin < "$tmp/REFPACK.bin" \
    > "$tmp/git-index-ref.log"
for blob in abc abcd abcde; do
 oid=$(printf %s "$blob" | git hash-object --stdin)
 git -C "$tmp/packrepo" cat-file blob "$oid" > "$tmp/from-git"
 printf %s "$blob" | cmp - "$tmp/from-git"
done
${CC:-cc} -x c -std=c89 -O2 -Wall -Wextra \
    -o "$tmp/native_ref_pack_host" \
    -DREF_PACK_HOST "$root/tests/native_stage_host.c" -lz
(
 cd "$tmp"
 cp REFPACK.PACK 'dd:PACKIN'
 ./native_ref_pack_host > ref-positive.log
 ./native_ref_pack_host RAPPLY > ref-apply.log
 grep -q '^REF DELTAS APPLIED 2$' ref-apply.log
 grep -q '^OFS DELTAS APPLIED 0$' ref-apply.log
 grep -q '^PASS 3 OBJECTS NEXT OFFSET ' ref-positive.log
 grep -q '^OFS DELTAS APPLIED 0$' ref-positive.log
 grep -q '^REF DELTAS APPLIED 2$' ref-positive.log
 for entry in 'REFBAD.PACK:2' 'REFFWD.PACK:1'; do
  filename=${entry%%:*}; object=${entry##*:}
  cp "$filename" 'dd:PACKIN'
  if ./native_ref_pack_host > ref-negative.log; then
   echo "Unexpected REF acceptance: $filename" >&2
   exit 1
  fi
  grep -q "^UNRESOLVED REF BASE OBJ $object$" ref-negative.log
 done
 cp REFSIZE.PACK 'dd:PACKIN'
 if ./native_ref_pack_host > ref-negative.log; then
  echo 'Accepted invalid REF base-size declaration' >&2
  exit 1
 fi
 grep -q '^FAIL NATIVE DELTA APPLY$' ref-negative.log
 cp REFSHA.PACK 'dd:PACKIN'
 if ./native_ref_pack_host > ref-negative.log; then
  echo 'Accepted corrupted PACK trailer' >&2
  exit 1
 fi
 grep -q '^FAIL NATIVE PACK SHA1$' ref-negative.log
 cp FCHAIN.PACK 'dd:PACKIN'
 ./native_ref_pack_host FPACK > f-positive.log
 grep -q '^PASS 3 OBJECTS NEXT OFFSET ' f-positive.log
 grep -q '^REF DELTAS APPLIED 2$' f-positive.log
 grep -q '^FORWARD REF OBJ 2 TYPE 3 SIZE 4 OID ' f-positive.log
 grep -q '^FORWARD REF OBJ 1 TYPE 3 SIZE 5 OID ' f-positive.log
 cp REFFWD.PACK 'dd:PACKIN'
 ./native_ref_pack_host FPACK > f-short.log
 grep -q '^REF DELTAS APPLIED 1$' f-short.log
 cp REFBAD.PACK 'dd:PACKIN'
 if ./native_ref_pack_host FPACK > f-negative.log; then
  echo 'Unexpected forward acceptance without required base' >&2
  exit 1
 fi
 grep -q '^UNRESOLVED FORWARD REF COUNT 2$' f-negative.log
 cp XPACK.PACK 'dd:PACKIN'
 cp EXTBASE.DATA 'dd:EXTIN'
 ./native_ref_pack_host XPACK > x-positive.log
 ./native_ref_pack_host XAPPLY > x-apply.log
 grep -q '^EXTERNAL REF BASE VERIFIED TYPE 3 SIZE 3$' x-positive.log
 grep -q '^REF DELTAS APPLIED 1$' x-positive.log
 grep -q '^REF DELTAS APPLIED 1$' x-apply.log
 grep -q '^PASS 1 OBJECTS NEXT OFFSET ' x-positive.log
 cp EXSEEK.DATA 'dd:EXIDX'
 ./native_ref_pack_host XSEEK > xs-positive.log
 ./native_ref_pack_host XSAPPLY > xs-apply.log
 grep -q '^EXTERNAL SEEK VERIFIED TYPE 3 SIZE 3$' xs-positive.log
 grep -q '^REF DELTAS APPLIED 1$' xs-positive.log
 grep -q '^REF DELTAS APPLIED 1$' xs-apply.log
 cp EXWRONG.IDX 'dd:EXIDX'
 if ./native_ref_pack_host XSEEK > xs-negative.log; then
  echo 'Accepted stale external seek cookie' >&2
  exit 1
 fi
 grep -q '^EXTERNAL SEEK STAGE INVALID$' xs-negative.log
 cp EXSHORT.IDX 'dd:EXIDX'
 if ./native_ref_pack_host XSEEK > xs-negative.log; then
  echo 'Accepted incomplete external seek index' >&2
  exit 1
 fi
 grep -q '^EXTERNAL SEEK INDEX INVALID$' xs-negative.log
 cp EXSEEK.DATA 'dd:EXIDX'
 cp EXTBAD.DATA 'dd:EXTIN'
 if ./native_ref_pack_host XSEEK > xs-negative.log; then
  echo 'Accepted corrupt external seek target body' >&2
  exit 1
 fi
 grep -q '^EXTERNAL SEEK STAGE INVALID$' xs-negative.log
 cp EXTBASE.DATA 'dd:EXTIN'
 cp EXTMULT.DATA 'dd:EXTIN'
 ./native_ref_pack_host XPACK > x-mult.log
 cp EXMULT.IDX 'dd:EXIDX'
 ./native_ref_pack_host XSEEK > xs-mult.log
 grep -q '^EXTERNAL SEEK VERIFIED TYPE 3 SIZE 3$' xs-mult.log
 grep -q '^EXTERNAL REF BASE VERIFIED TYPE 3 SIZE 3$' x-mult.log
 cp EXTDUP.DATA 'dd:EXTIN'
 if ./native_ref_pack_host XPACK > x-negative.log; then
  echo 'Accepted duplicate external staged OID' >&2
  exit 1
 fi
 grep -q '^INVALID EXTERNAL STAGE RECORD 2$' x-negative.log
 cp EXTBAD.DATA 'dd:EXTIN'
 if ./native_ref_pack_host XPACK > x-negative.log; then
  echo 'Accepted corrupted external stage base' >&2
  exit 1
 fi
 grep -q '^INVALID EXTERNAL STAGE RECORD 1$' x-negative.log
 cp EXTMISS.DATA 'dd:EXTIN'
 if ./native_ref_pack_host XPACK > x-negative.log; then
  echo 'Accepted absent external stage OID' >&2
  exit 1
 fi
 grep -q '^UNRESOLVED REF BASE OBJ 1$' x-negative.log
 cp EXTBASE.DATA 'dd:EXTIN'
 cp XREAL.PACK 'dd:PACKIN'
 if ./native_ref_pack_host XPACK > x-negative.log; then
  echo 'Accepted real-commit external ref without that commit' >&2
  exit 1
 fi
 grep -q '^UNRESOLVED REF BASE OBJ 1$' x-negative.log
 cp XBAD.PACK 'dd:PACKIN'
 if ./native_ref_pack_host XPACK > x-negative.log; then
  echo 'Accepted unprovided external REF base' >&2
  exit 1
 fi
 grep -q '^UNRESOLVED REF BASE OBJ 1$' x-negative.log
)
for pair in '1:abc' '2:abcd' '3:abcde'; do
 number=${pair%%:*}; body=${pair##*:}
 expected=$(printf %s "$body" | git hash-object --stdin)
 oid=$(sed -n "s/^OID OBJ $number TYPE 3 SIZE [0-9]* //p" \
     "$tmp/ref-positive.log")
 if [ "$(printf %s "$oid" | tr 'A-F' 'a-f')" != "$expected" ]; then
  echo "Native REF OID $number differs from Git" >&2
  exit 1
 fi
done
ref_oid=$(sed -n 's/^REFTEST OID //p' "$tmp/host.log")
expected_ref=$(printf abcde | git hash-object --stdin)
test "$ref_oid" = "$expected_ref"
external_oid=$(sed -n 's/^OID OBJ 1 TYPE 3 SIZE 4 //p' \
    "$tmp/x-positive.log")
expected_external=$(printf abcd | git hash-object --stdin)
test "$(printf %s "$external_oid" | tr 'A-F' 'a-f')" = \
    "$expected_external"
for pair in '1:abcde' '2:abcd'; do
 number=${pair%%:*}; body=${pair##*:}
 expected=$(printf %s "$body" | git hash-object --stdin)
 got=$(sed -n "s/^FORWARD REF OBJ $number TYPE 3 SIZE [0-9]* OID //p" \
     "$tmp/f-positive.log")
 test "$(printf %s "$got" | tr 'A-F' 'a-f')" = "$expected"
done
cat "$tmp/f-positive.log"
echo 'HOST FORWARD SAME-PACK REF CHAIN PASSED'
cat "$tmp/xs-positive.log"
echo 'HOST EXTERNAL REF SEEK POSITIVE AND NEGATIVE GATES PASSED'
cat "$tmp/x-positive.log"
echo 'HOST EXTERNAL REF BASE POSITIVE AND NEGATIVE GATES PASSED'
cat "$tmp/ref-positive.log"
echo 'HOST REF PACK INTEGRATION AND NEGATIVE GATES PASSED'
cat "$tmp/host.log"
cat "$tmp/index.log"
echo 'HOST STAGING, INDEX AND GIT OID TEST PASSED'

)
exit 0
fi
# Fail closed on unknown selector names; never run an unrelated default gate.
if [ "$#" -gt 1 ]; then
  echo "FAIL: expected at most one guard selector" >&2
  exit 2
fi
case "${1:-}" in
  ""|NATIVE|MAP|CONFIG|BACKUP|VREF|M155|M157|READONLY|CMSCLNK) ;;
  *) echo "FAIL: unknown guard selector: $1" >&2; exit 2 ;;
esac
# Original three independent Hercules/DASD safety modes (run with bash).
if [ "${1:-}" = "MAP" ] || [ "${1:-}" = "CONFIG" ] || [ "${1:-}" = "BACKUP" ]; then
(
if [ "${1:-}" = "BACKUP" ]; then
(
# Validate guarded offline DASD backup helper on harmless synthetic data.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
printf 'DASD TEST DATA\000\377\002' > "$tmp/source.ckd"
mkdir "$tmp/snapshots"
if bash "$root/scripts/backup-offline-dasd.sh" \
   "$tmp/source.ckd" "$tmp/snapshots/copy.ckd" > "$tmp/unconfirmed.log" 2>&1; then
  echo "FAIL: allowed backup without explicit offline confirmation" >&2
  exit 1
fi
OFFLINE_CONFIRMED=YES bash "$root/scripts/backup-offline-dasd.sh" \
  "$tmp/source.ckd" "$tmp/snapshots/copy.ckd" > "$tmp/backup.log"
cmp "$tmp/source.ckd" "$tmp/snapshots/copy.ckd"
if OFFLINE_CONFIRMED=YES bash "$root/scripts/backup-offline-dasd.sh" \
   "$tmp/source.ckd" "$tmp/snapshots/copy.ckd" > "$tmp/overwrite.log" 2>&1; then
  echo "FAIL: allowed overwrite of existing backup" >&2
  exit 1
fi
if OFFLINE_CONFIRMED=YES bash "$root/scripts/backup-offline-dasd.sh" \
   "$tmp/missing.ckd" "$tmp/snapshots/missing.ckd" > "$tmp/missing.log" 2>&1; then
  echo "FAIL: allowed nonexistent source" >&2
  exit 1
fi
test ! -e "$tmp/snapshots/missing.ckd"
test -f "$tmp/source.ckd"
ln -s "$tmp/source.ckd" "$tmp/source-symlink.ckd"
if OFFLINE_CONFIRMED=YES bash "$root/scripts/backup-offline-dasd.sh" \
   "$tmp/source-symlink.ckd" "$tmp/snapshots/symlink.ckd" > "$tmp/symlink.log" 2>&1; then
  echo "FAIL: accepted symbolic-link source" >&2
  exit 1
fi
test ! -e "$tmp/snapshots/symlink.ckd"
printf 'DO NOT OVERWRITE' > "$tmp/keep.ckd"
ln -s "$tmp/keep.ckd" "$tmp/snapshots/link.ckd"
if OFFLINE_CONFIRMED=YES bash "$root/scripts/backup-offline-dasd.sh" \
   "$tmp/source.ckd" "$tmp/snapshots/link.ckd" > "$tmp/destlink.log" 2>&1; then
  echo "FAIL: accepted symbolic-link destination" >&2
  exit 1
fi
test "$(cat "$tmp/keep.ckd")" = 'DO NOT OVERWRITE'
test -f "$tmp/source.ckd"
test "$(find "$tmp/snapshots" -type f | wc -l)" -eq 1
grep -q 'OFFLINE COPY AND BYTE COMPARISON PASSED' "$tmp/backup.log"
echo "OFFLINE DASD BACKUP HELPER GUARDS PASSED"

)
exit 0
fi
if [ "${1:-}" = "CONFIG" ]; then
(
# Read-only config parser test on synthetic, harmless fixture.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
cat > "$tmp/example.cnf" <<'EOF'
# A commented out CKD must be ignored:
# 0123 3390 /not/an/image
0123 3390 /synthetic/disks/system.cckd
0A00 CCKD /synthetic/disks/backup.cckd
0A01 3270
CONSOLE 001F
INCLUDE /synthetic/disks/extra.cfg
EOF
bash "$root/scripts/inspect-hercules-config.sh" "$tmp/example.cnf" > "$tmp/result"
grep -q 'CONFIG LINE 3: 0123 3390 /synthetic/disks/system.cckd' "$tmp/result"
grep -q 'CONFIG LINE 4: 0A00 CCKD /synthetic/disks/backup.cckd' "$tmp/result"
! grep -q '/not/an/image' "$tmp/result"
grep -q 'does not establish quiescence' "$tmp/result"
if bash "$root/scripts/inspect-hercules-config.sh" "$tmp/missing.cnf" >/dev/null 2>&1; then
  echo "FAIL: accepted nonexistent configuration" >&2
  exit 1
fi
ln -s "$tmp/example.cnf" "$tmp/link.cnf"
if bash "$root/scripts/inspect-hercules-config.sh" "$tmp/link.cnf" >/dev/null 2>&1; then
  echo "FAIL: accepted symlink configuration" >&2
  exit 1
fi
echo 'HERCULES CONFIG READ-ONLY INVENTORY GUARDS PASSED'

)
exit 0
fi
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/run"
printf 'SYNTHETIC TEST DATA' > "$tmp/run/dasd3"
cat > "$tmp/hercules.cnf" <<'EOF'
# 0125 3390 wrong
0123 3390 dasd1
0124 3390 dasd2
0125 3390 dasd3
0126 3390 dasd4
EOF
bash "$repo/scripts/map-cms-minidisk.sh" 125 "$tmp/hercules.cnf" "$tmp/run" > "$tmp/result"
grep -q 'CP REAL DEVICE: 0125' "$tmp/result"
grep -q "CONFIGURED BASE IMAGE: $tmp/run/dasd3" "$tmp/result"
grep -q 'NOT YET VERIFIED' "$tmp/result"
if bash "$repo/scripts/map-cms-minidisk.sh" 0123 "$tmp/hercules.cnf" "$tmp/run" > /dev/null 2>&1; then
  echo "FAIL: accepted missing backing image" >&2
  exit 1
fi
if bash "$repo/scripts/map-cms-minidisk.sh" not-hex "$tmp/hercules.cnf" "$tmp/run" > /dev/null 2>&1; then
  echo "FAIL: accepted invalid Rdev" >&2
  exit 1
fi
echo '0125 3390 another-disk' >> "$tmp/hercules.cnf"
if bash "$repo/scripts/map-cms-minidisk.sh" 0125 "$tmp/hercules.cnf" "$tmp/run" > /dev/null 2>&1; then
  echo "FAIL: accepted duplicate mapping" >&2
  exit 1
fi
echo 'CP/HERCULES REAL DEVICE READ-ONLY MAPPING GUARDS PASSED'

)
exit 0
fi
# Preserved complete verified-REF host guard as independent CI mode.
if [ "${1:-}" = "VREF" ]; then
(
# M139 authenticated first-parent subject guards.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
v="$root/src/GITVREF.EXEC"
g="$root/src/GIT.EXEC"
r="$root/src/GITREF2.REPO"
rec="$root/src/GITREC.C"
gate="$root/src/M157GATE.EXEC"
m155="$root/src/M155CHK.EXEC"
m156="$root/src/M156CHK.EXEC"
m157="$root/src/M157CHK.EXEC"
test -s "$v"
test -s "$g"
test -s "$r"
test -s "$rec"
test -s "$gate"
test -s "$m155"
test -s "$m156"
test -s "$m157"
grep -Fq "'M155CHK'" "$gate"
grep -Fq "'M156CHK'" "$gate"
grep -Fq "'M157CHK'" "$gate"
if grep -Fq "PIPE " "$gate"; then
  echo "FAIL: M157GATE must not nest compact checkers in pipelines" >&2
  exit 1
fi
grep -Fq "M155 CHRONOLOGY DIRECT RC0" "$m155"
grep -Fq "M155 EVENTS DIRECT RC0" "$m155"
grep -Fq "M156 DURATION DIRECT RC0" "$m156"
grep -Fq "M157 AGE DIRECT RC0" "$m157"
test "$(grep -c '^address command cmd$' "$m155")" -eq 2
test "$(grep -c '^address command cmd$' "$m156")" -eq 1
test "$(grep -c '^address command cmd$' "$m157")" -eq 1
if grep -Fq "| STEM chr." "$m155" || grep -Fq "| STEM evt." "$m155"; then
  echo "FAIL: M155 history commands must execute directly" >&2
  exit 1
fi
if grep -Fq "| STEM out." "$m156" || grep -Fq "| STEM out." "$m157"; then
  echo "FAIL: M156/M157 history commands must execute directly" >&2
  exit 1
fi
grep -Fxq "REF2 1" "$r"
grep -Fxq "HEAD refs/heads/main" "$r"
grep -Fxq "REF refs/heads/main 00D8D63229305230C8D37F884CE87F9E1A89468C" "$r"
grep -Fq "GITREC SHOWFULL GITFIX M15NEW" "$v"
grep -Fq "SHOW FULL ROOT CLOSURE VERIFIED" "$v"
grep -Fq "'FILEDEF SEL0 DISK M15SL0 PTR A'" "$v"
grep -Fq "'FILEDEF SEL1 DISK M15SL1 PTR A'" "$v"
grep -Fq "command = 'VERIFY-REF'" "$g"
grep -Fq "address command 'EXEC GITVREF RESOLVE' rest" "$g"
grep -Fq "command = 'SHOW-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF SHOW' rest" "$g"
grep -Fq "command = 'LOG-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF LOG' rest" "$g"
grep -Fq "command = 'LOGDAG-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF DAG' rest" "$g"
grep -Fq "command = 'HISTORYPATH-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTPATH' rest" "$g"
grep -Fq "command = 'HISTORYCHANGES-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTCHG' rest" "$g"
grep -Fq "command = 'HISTORYEDGES-REF-FULL'" "$g"
grep -Fq "command = 'HISTORYDIFFS-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTDIFF' rest" "$g"
grep -Fq "command = 'HISTORYSTATE-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTSTATE' rest" "$g"
grep -Fq "command = 'HISTORYLOG-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTLOG' rest" "$g"
grep -Fq "command = 'HISTORYSTATUS-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTSTATUS' rest" "$g"
grep -Fq "command = 'HISTORYNEAREST-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTNEAR' rest" "$g"
grep -Fq "command = 'HISTORYTRANSITIONS-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTTRANS' rest" "$g"
grep -Fq "command = 'HISTORYREPORT-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTREPORT' rest" "$g"
grep -Fq "command = 'HISTORYBOUNDS-REF-FULL'" "$g"
grep -Fq "command = 'LEVEL'" "$g"
grep -Fq "command = 'HISTORYCHRONOLOGY-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTCHRON' rest" "$g"
grep -Fq "command = 'HISTORYACTORS-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTACTORS' rest" "$g"
grep -Fq "command = 'HISTORYSUBJECTS-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTSUBJECTS' rest" "$g"
grep -Fq "command = 'HISTORYBODIES-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTBODIES' rest" "$g"
grep -Fq "command = 'HISTORYTOPOLOGY-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTTOPO' rest" "$g"
grep -Fq "command = 'HISTORYPARENTS-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTPARENTS' rest" "$g"
grep -Fq "command = 'HISTORYPARENTSLOTS-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTSLOTS' rest" "$g"
grep -Fq "command = 'HISTORYEDGEROLES-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTROLES' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTPARENT-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFIRST' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTCHANGES-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFCHG' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTTRANSITIONS-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFTRANS' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTCHRONOLOGY-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFCHRON' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTACTORS-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFACTORS' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTSUBJECTS-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFSUBJ' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTBODIES-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFBODY' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTLOG-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFLOG' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTREPORT-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFREPORT' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTDIFFS-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFDIF' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTNEAREST-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFNEAR' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTSTATUS-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFSTAT' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTBOUNDS-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFBOUND' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTVERSIONS-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFVER' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTLIFETIME-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFLIFE' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTCURRENT-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFCUR' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTORIGIN-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFORIG' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTPRESENCE-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFPRES' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTPRESENCEORIGIN-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFPORIG' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTPRESENCECHRONOLOGY-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFPCHR' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTPRESENCEEVENTS-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFPEVT' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTPRESENCEDURATION-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFPDUR' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTPRESENCEAGE-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFPAGE' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTPRESENCETIME-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFPTIME' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTPRESENCERATIO-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFPRATIO' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTPRESENCECOVERAGE-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFPCOV' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTPRESENCEFRONTIER-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFPFRONT' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTPRESENCEFRONTIERDISTANCE-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFPFDIST' rest" "$g"
grep -Fq "command = 'HISTORYFIRSTPRESENCEHORIZON-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF HISTFPHORIZ' rest" "$g"
grep -Fq "GIT EXEC LEVEL M176" "$g"
grep -Fq "GITVREF EXEC LEVEL M176" "$v"
grep -Fq "GIT EXEC STAMP C4" "$g"
grep -Fq "address command 'EXEC GITVREF CASE' rest" "$g"
grep -Fq "GITVREF CASE C6" "$v"
grep -Fq "GITVREF EXEC LEVEL MISMATCH" "$g"
grep -Fxq "numeric digits 20" "$v"
grep -Fq "rawwanted=wanted" "$v"
grep -Fq "length(direct)=40" "$v"
grep -Fq "call directinput command" "$v"
grep -Fq "reskind='COMMIT'" "$v"
grep -Fq "if left(c,4)='HIST' then return 1" "$v"
grep -Fq "VERIFIED COMMIT" "$v"
grep -Fq "else say 'VERIFIED REF' spec oid" "$v"
grep -Fq "rec_ident_when" "$rec"
grep -Fq "rec_commit_times" "$rec"
grep -Fq "HISTORYDAGSTATE AUTHOR TIME %lu TZMIN %d" "$rec"
grep -Fq "HISTORYDAGSTATE COMMITTER TIME %lu TZMIN %d" "$rec"
grep -Fq "HISTORYDAGSTATE AIDENT BYTES %lu PREFIXBYTES %u" "$rec"
grep -Fq "HISTORYDAGSTATE CIDENT BYTES %lu PREFIXBYTES %u" "$rec"
grep -Fq "HISTORYDAGSTATE AIDENTHEX" "$rec"
grep -Fq "HISTORYDAGSTATE CIDENTHEX" "$rec"
grep -Fq "HISTORYDAGSTATE AIDENT BLOBID" "$rec"
grep -Fq "HISTORYDAGSTATE CIDENT BLOBID" "$rec"
grep -Fq "author_ident_prefix_bytes" "$rec"
grep -Fq "commit_ident_prefix_bytes" "$rec"
grep -Fq "saidentbytes.curnode=ib" "$v"
grep -Fq "scidentbytes.curnode=ib" "$v"
grep -Fq "CAIDENTHEX" "$v"
grep -Fq "PCIDENTHEX" "$v"
grep -Fq "CAIDENT BLOBID" "$v"
grep -Fq "PCIDENT BLOBID" "$v"
grep -Fq "stateactors:" "$v"
grep -Fq "HISTORYACTORS FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYACTORS AUTHORS' authors" "$v"
grep -Fq "HISTORYACTORS COMMITTERS' committers" "$v"
grep -Fq "statesubjects:" "$v"
grep -Fq "HISTORYSUBJECTS FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYSUBJECTS SUBJECTS' subjects" "$v"
grep -Fq "CHILDSUBJECT BLOBID" "$v"
grep -Fq "PARENTSUBJECT BLOBID" "$v"
grep -Fq "statebodies:" "$v"
grep -Fq "HISTORYBODIES FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYBODIES BODIES' bodies" "$v"
grep -Fq "CHILDMESSAGE BLOBID" "$v"
grep -Fq "PARENTMESSAGE BLOBID" "$v"
grep -Fq "statetopology:" "$v"
grep -Fq "HISTORYTOPOLOGY FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYTOPOLOGY MAX PARENTS" "$v"
grep -Fq "soutedges.ni\=suniqueparents.ni" "$v"
grep -Fq "stateparents:" "$v"
grep -Fq "HISTORYPARENTS FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYPARENTS FIRST FOLLOWED" "$v"
grep -Fq "firstmatches\=1" "$v"
grep -Fq "stateparentslots:" "$v"
grep -Fq "HISTORYPARENTSLOTS FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYPARENTSLOTS DUPLICATE SLOTS" "$v"
grep -Fq "sslotnodecount.ni\=sparents.ni" "$v"
grep -Fq "sslotdistinct.ni\=suniqueparents.ni" "$v"
grep -Fq "stateedgeroles:" "$v"
grep -Fq "HISTORYEDGEROLES FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYEDGEROLES FIRST EDGES" "$v"
grep -Fq "HISTORYEDGEROLES MERGE EDGES" "$v"
grep -Fq "HISTORYEDGEROLES MULTISLOT EDGES" "$v"
grep -Fq "duplicate\=sslotcount-sedgecount" "$v"
grep -Fq "firstedges\=expectedfirst" "$v"
grep -Fq "if eroleslots.ei<1 then return 8" "$v"
grep -Fq "if erolemin.ei<2 then return 8" "$v"
grep -Fq "'ROLE' role" "$v"
grep -Fq "'MINORDINAL' erolemin.ei 'MAXORDINAL' erolemax.ei" "$v"
grep -Fq "statefirstparent:" "$v"
grep -Fq "HISTORYFIRSTPARENT FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYFIRSTPARENT CHAIN NODES" "$v"
grep -Fq "HISTORYFIRSTPARENT OFFCHAIN EDGES" "$v"
grep -Fq "HISTORYFIRSTPARENT TRUNCATED" "$v"
grep -Fq "buildfirstparent:" "$v"
grep -Fq "if fpseen.next=1 then return 'ERROR'" "$v"
grep -Fq "if edgeok=0 then return 'ERROR'" "$v"
grep -Fq "chainedges=fpcount-1" "$v"
grep -Fq "offedges=sedgecount-chainedges" "$v"
grep -Fq "if sdepth.cur>=depth then do" "$v"
grep -Fq "if sparents.cur>0 then truncated=1" "$v"
grep -Fq "statefirstchanges:" "$v"
grep -Fq "HISTORYFIRSTCHANGES FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYFIRSTCHANGES CHAIN EDGES" "$v"
grep -Fq "HISTORYFIRSTCHANGES CHANGES" "$v"
grep -Fq "HISTORYFIRSTCHANGES DELETED" "$v"
grep -Fq "fstatus.fi='DELETED'" "$v"
grep -Fq "fstatus.fi='MODIFIED'" "$v"
grep -Fq "fstatus.fi='ADDED'" "$v"
grep -Fq "fstatus.fi='UNCHANGED'" "$v"
grep -Fq "fchanged\=fadd+fdelete+fmodify" "$v"
grep -Fq "fadd+fdelete+fmodify+funchanged\=chainedges" "$v"
grep -Fq "'CHILDSTATE' cs" "$v"
grep -Fq "'PARENTSTATE' ps" "$v"
grep -Fq "'CHILDOID' soid.ec" "$v"
grep -Fq "'PARENTOID' soid.ep" "$v"
grep -Fq "statefirsttransitions:" "$v"
grep -Fq "HISTORYFIRSTTRANSITIONS FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYFIRSTTRANSITIONS TRANSITIONS" "$v"
grep -Fq "HISTORYFIRSTTRANSITIONS CHANGED TRANSITIONS" "$v"
grep -Fq "HISTORYFIRSTTRANSITIONS DELETED EDGES" "$v"
grep -Fq "ftstatus.ti='DELETED'" "$v"
grep -Fq "ftstatus.ti='MODIFIED'" "$v"
grep -Fq "ftstatus.ti='ADDED'" "$v"
grep -Fq "ftstatus.ti='UNCHANGED'" "$v"
grep -Fq "fttotal\=chainedges" "$v"
grep -Fq "ftchangededges\=ftadd+ftdelete+ftmodify" "$v"
grep -Fq "call stateversions" "$v"
grep -Fq "call buildfirstparent" "$v"
grep -Fq "HISTORYFIRSTTRANSITIONS STATE 0 ABSENT" "$v"
grep -Fq "'PRESENT OID' sveroid.vi" "$v"
grep -Fq "'CHILDSTATE' cv" "$v"
grep -Fq "'PARENTSTATE' pv 'COUNT' ftcount.ti" "$v"
grep -Fq "'PARENTOID' sveroid.pv" "$v"
grep -Fq "statefirstchron:" "$v"
grep -Fq "HISTORYFIRSTCHRONOLOGY FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYFIRSTCHRONOLOGY AUTHOR POSITIVE EDGES" "$v"
grep -Fq "HISTORYFIRSTCHRONOLOGY COMMITTER POSITIVE EDGES" "$v"
grep -Fq "HISTORYFIRSTCHRONOLOGY LAG ZERO NODES" "$v"
grep -Fq "'AUTHOR DELTA SECONDS' ad" "$v"
grep -Fq "'COMMITTER DELTA SECONDS' cd" "$v"
grep -Fq "'LAG SECONDS' lag" "$v"
grep -Fq "fapos+fazero+faneg\=chainedges" "$v"
grep -Fq "flpos+flzero+flneg\=fpcount" "$v"
grep -Fq "statefirstactors:" "$v"
grep -Fq "HISTORYFIRSTACTORS FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYFIRSTACTORS AUTHOR SAME EDGES" "$v"
grep -Fq "HISTORYFIRSTACTORS AUTHOR CHANGED EDGES" "$v"
grep -Fq "HISTORYFIRSTACTORS COMMITTER SAME EDGES" "$v"
grep -Fq "HISTORYFIRSTACTORS COMMITTER CHANGED EDGES" "$v"
grep -Fq "HISTORYFIRSTACTORS AUTHOR HANDOFFS" "$v"
grep -Fq "HISTORYFIRSTACTORS COMMITTER HANDOFFS" "$v"
grep -Fq "fasame+fachanged\=chainedges" "$v"
grep -Fq "fcsame+fcchanged\=chainedges" "$v"
grep -Fq "'AUTHOR STATUS' ast" "$v"
grep -Fq "'COMMITTER STATUS' cst" "$v"
grep -Fq "'AUTHOR CHILD BLOBID' saidentid.ec" "$v"
grep -Fq "'COMMITTER PARENT BLOBID' scidentid.ep" "$v"
grep -Fq "statefirstsubjects:" "$v"
grep -Fq "HISTORYFIRSTSUBJECTS FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYFIRSTSUBJECTS SAME EDGES" "$v"
grep -Fq "HISTORYFIRSTSUBJECTS CHANGED EDGES" "$v"
grep -Fq "HISTORYFIRSTSUBJECTS HANDOFFS" "$v"
grep -Fq "HISTORYFIRSTSUBJECTS CHANGED HANDOFFS" "$v"
grep -Fq "fssame+fschanged\=chainedges" "$v"
grep -Fq "'CHILD BLOBID' ssubid.ec" "$v"
grep -Fq "'PARENT BLOBID' ssubid.ep" "$v"
grep -Fq "'CHILD BYTES' ssubbytes.ec" "$v"
grep -Fq "'PARENT BYTES' ssubbytes.ep" "$v"
grep -Fq "statefirstbodies:" "$v"
grep -Fq "HISTORYFIRSTBODIES FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYFIRSTBODIES SAME EDGES" "$v"
grep -Fq "HISTORYFIRSTBODIES CHANGED EDGES" "$v"
grep -Fq "HISTORYFIRSTBODIES HANDOFFS" "$v"
grep -Fq "HISTORYFIRSTBODIES CHANGED HANDOFFS" "$v"
grep -Fq "fbsame+fbchanged\=chainedges" "$v"
grep -Fq "'CHILD BLOBID' smsgid.ec" "$v"
grep -Fq "'PARENT BLOBID' smsgid.ep" "$v"
grep -Fq "'CHILD BYTES' smsgbytes.ec" "$v"
grep -Fq "'PARENT BYTES' smsgbytes.ep" "$v"
grep -Fq "'CHILD SUBJECT BLOBID' ssubid.ec" "$v"
grep -Fq "'PARENT SUBJECT BLOBID' ssubid.ep" "$v"
grep -Fq "statefirstlog:" "$v"
grep -Fq "HISTORYFIRSTLOG FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYFIRSTLOG CHAIN NODES" "$v"
grep -Fq "call emitnodechron 'HISTORYFIRSTLOG',ni" "$v"
grep -Fq "HISTORYFIRSTLOG NODE' ni 'STATE'" "$v"
grep -Fq "statefirstreport:" "$v"
grep -Fq "HISTORYFIRSTREPORT FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYFIRSTREPORT DELETED EDGES" "$v"
grep -Fq "HISTORYFIRSTREPORT AUTHOR SAME EDGES" "$v"
grep -Fq "HISTORYFIRSTREPORT COMMITTER SAME EDGES" "$v"
grep -Fq "HISTORYFIRSTREPORT SUBJECT CHANGED EDGES" "$v"
grep -Fq "HISTORYFIRSTREPORT MESSAGE CHANGED EDGES" "$v"
grep -Fq "fradd+frdelete+frmodify+frunchanged\=chainedges" "$v"
grep -Fq "frauthsame+frauthchanged\=chainedges" "$v"
grep -Fq "frcommsame+frcommchanged\=chainedges" "$v"
grep -Fq "frsubsame+frsubchanged\=chainedges" "$v"
grep -Fq "frbodysame+frbodychanged\=chainedges" "$v"
grep -Fq "call emitpairchron 'HISTORYFIRSTREPORT','EDGE',fi,ec,ep" "$v"
grep -Fq "statefirstdiffs:" "$v"
grep -Fq "statefirstnearest:" "$v"
grep -Fq "fdchanged\=fdadd+fddelete+fdmodify" "$v"
grep -Fq "fdchanged+fdunchanged\=chainedges" "$v"
grep -Fq "if match\=fdnear then return 8" "$v"
grep -Fq "HISTORYFIRSTDIFFS FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYFIRSTNEAREST FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "statefirststatus:" "$v"
grep -Fq "HISTORYFIRSTSTATUS FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYFIRSTSTATUS FARTHEST CHANGE DEPTH" "$v"
grep -Fq "statefirstbounds:" "$v"
grep -Fq "HISTORYFIRSTBOUNDS FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYFIRSTBOUNDS BOUNDARY CHANGES" "$v"
grep -Fq "if farcount<1 | farcount>fdchanged then return 8" "$v"
grep -Fq "if boundcount<1 | boundcount>fdchanged then return 8" "$v"
grep -Fq "if match\=boundcount then return 8" "$v"
grep -Fq "preparefirstversions:" "$v"
grep -Fq "statefirstversions:" "$v"
grep -Fq "HISTORYFIRSTVERSIONS FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "if total\=fvpresent then return 'ERROR'" "$v"
grep -Fq "preparefirstruns:" "$v"
grep -Fq "statefirstlifetime:" "$v"
grep -Fq "HISTORYFIRSTLIFETIME FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "if frtrans\=fdchanged then return 'ERROR'" "$v"
grep -Fq "if fdstatus.fi='UNCHANGED' then return 'ERROR'" "$v"
grep -Fq "HISTORYFIRSTLIFETIME TRANSITIONS' frtrans" "$v"
grep -Fq "preparefirstcurrent:" "$v"
grep -Fq "statefirstcurrent:" "$v"
grep -Fq "statefirstorigin:" "$v"
grep -Fq "HISTORYFIRSTCURRENT FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYFIRSTORIGIN FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "if fcnodes\=fcoldstep then return 'ERROR'" "$v"
grep -Fq "if fdstatus.fcbeginedge='UNCHANGED' then return 'ERROR'" "$v"
grep -Fq "if sparents.fcoldnode\=0 then return 'ERROR'" "$v"
grep -Fq "HISTORYFIRSTORIGIN EVENTS 1" "$v"
grep -Fq "call emitfirstchange 'HISTORYFIRSTORIGIN','EVENT',1,fcbeginedge" "$v"
grep -Fq "preparefirstpresence:" "$v"
grep -Fq "statefirstpresence:" "$v"
grep -Fq "preparefirstpresencecurrent:" "$v"
grep -Fq "statefirstpresenceorigin:" "$v"
grep -Fq "HISTORYFIRSTPRESENCE FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYFIRSTPRESENCEORIGIN FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "if exacttotal\=frruns then return 'ERROR'" "$v"
grep -Fq "if prtrans\=prexistchanges then return 'ERROR'" "$v"
grep -Fq "if frruns-prruns\=fdmodify then return 'ERROR'" "$v"
grep -Fq "fdstatus.fi\='ADDED' & fdstatus.fi\='DELETED'" "$v"
grep -Fq "say kind 'PRESENCE TRANSITIONS' prtrans" "$v"
grep -Fq "HISTORYFIRSTPRESENCE RUN' ri 'VERSIONS' prvers.ri" "$v"
grep -Fq "HISTORYFIRSTPRESENCEORIGIN EVENTS 1" "$v"
grep -Fq "call emitfirstchange 'HISTORYFIRSTPRESENCEORIGIN','EVENT',1,pcbeginedge" "$v"
grep -Fq "preparepresencechron:" "$v"
grep -Fq "statefirstpresencechron:" "$v"
grep -Fq "statefirstpresenceevents:" "$v"
grep -Fq "HISTORYFIRSTPRESENCECHRONOLOGY FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYFIRSTPRESENCEEVENTS FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "if prauthpos+prauthzero+prauthneg\=prruns then return 'ERROR'" "$v"
grep -Fq "if prcommpos+prcommzero+prcommneg\=prruns then return 'ERROR'" "$v"
grep -Fq "HISTORYFIRSTPRESENCECHRONOLOGY AUTHOR ZERO RUNS' prauthzero" "$v"
grep -Fq "HISTORYFIRSTPRESENCECHRONOLOGY COMMITTER ZERO RUNS' prcommzero" "$v"
grep -Fq "HISTORYFIRSTPRESENCEEVENTS EVENTS' prtrans" "$v"
grep -Fq "if event\=prtrans then return 8" "$v"
grep -Fq "call emitfirstchange 'HISTORYFIRSTPRESENCEEVENTS','EVENT',event,fi" "$v"
grep -Fq "preparepresenceduration:" "$v"
grep -Fq "statefirstpresenceduration:" "$v"
grep -Fq "if fdstatus.be\\='ADDED' | fdstatus.ee\\='DELETED'" "$v"
grep -Fq "if fdstatus.be\\='DELETED' | fdstatus.ee\\='ADDED'" "$v"
grep -Fq "pdauth.ri=sauthorwhen.en-sauthorwhen.bn" "$v"
grep -Fq "pdcomm.ri=scommitwhen.en-scommitwhen.bn" "$v"
grep -Fq "HISTORYFIRSTPRESENCEDURATION CLOSED RUNS' pdclosed" "$v"
grep -Fq "HISTORYFIRSTPRESENCEDURATION RUN' ri 'BEGIN EDGE'" "$v"
grep -Fq "HISTORYFIRSTPRESENCEDURATION RUN' ri 'END EDGE'" "$v"
grep -Fq "HISTORYFIRSTPRESENCEDURATION DATA END" "$v"
grep -Fq "HISTORYFIRSTPRESENCEDURATION PROOF RUN' ri ps" "$v"
grep -Fq "GITVREF INTERNAL STAMP P2" "$v"
grep -Fq "HFPD P2 S' prruns pdclosed" "$v"
grep -Fq "HFPD P2 R' ri ps" "$v"
grep -Fq "be=pdbegin.ri" "$v"
grep -Fq "ee=pdend.ri" "$v"
grep -Fq "bs=fdstatus.be" "$v"
grep -Fq "es=fdstatus.ee" "$v"
if grep -Fq "fdstatus.pdbegin.ri" "$v" || grep -Fq "fdstatus.pdend.ri" "$v"; then
 echo "FAIL: duration emitter uses non-indirect compound tail" >&2
 exit 1
fi
grep -Fq "HFPA P2 S' prruns pcnodes" "$v"
grep -Fq "HFPA P2 R' ps pcbeginedge" "$v"
grep -Fq "HISTORYFIRSTPRESENCEAGE PROOF' ps pcbeginedge" "$v"
grep -Fq "statefirstpresenceage:" "$v"
grep -Fq "call preparefirstpresencecurrent" "$v"
grep -Fq "HISTORYFIRSTPRESENCEAGE FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYFIRSTPRESENCEAGE BEGIN KNOWN' pcbeginknown" "$v"
grep -Fq "HISTORYFIRSTPRESENCEAGE BEGIN EDGE' pcbeginedge" "$v"
grep -Fq "HISTORYFIRSTPRESENCEAGE AUTHOR SECONDS' pcauthspan" "$v"
grep -Fq "HISTORYFIRSTPRESENCEAGE COMMITTER SECONDS' pccommspan" "$v"
grep -Fq "HISTORYFIRSTPRESENCEAGE DATA END" "$v"
grep -Fq "preparepresencetime:" "$v"
grep -Fq "statefirstpresencetime:" "$v"
grep -Fq "ptcompletecount\=prruns-truncated" "$v"
grep -Fq "ptincomplete\=truncated" "$v"
grep -Fq "HFPT P1 S" "$v"
grep -Fq "HFPT P1 T" "$v"
grep -Fq "HFPT P1 R" "$v"
grep -Fq "preparepresenceratio:" "$v"
grep -Fq "statefirstpresenceratio:" "$v"
grep -Fq "preparepresencecoverage:" "$v"
grep -Fq "statefirstpresencecoverage:" "$v"
grep -Fq "preparepresencefrontier:" "$v"
grep -Fq "statefirstpresencefrontier:" "$v"
grep -Fq "preparepresencefrontierdistance:" "$v"
grep -Fq "statefirstpresencefrontierdistance:" "$v"
grep -Fq "preparepresencehorizon:" "$v"
grep -Fq "statefirstpresencehorizon:" "$v"
grep -Fq "pccnodes\=phstep" "$v"
grep -Fq "phstepdist=phstep-1" "$v"
grep -Fq "phdepthdist=phdepth-sdepth.hn" "$v"
grep -Fq "phauthspan=sauthorwhen.hn-sauthorwhen.cn" "$v"
grep -Fq "HFPH P1 S" "$v"
grep -Fq "HFPH P1 F" "$v"
grep -Fq "pfdstepdist=pfstart-1" "$v"
grep -Fq "pfddepthdist=sdepth.fn-sdepth.hn" "$v"
grep -Fq "pfdauthspan=sauthorwhen.hn-sauthorwhen.fn" "$v"
grep -Fq "pfdauthdelta=sauthorwhen.cn-sauthorwhen.fn" "$v"
grep -Fq "HFPG P1 S" "$v"
grep -Fq "HFPG P1 E" "$v"
grep -Fq "pfincrun=prruns" "$v"
grep -Fq "pfcompletestep=pfstart-1" "$v"
grep -Fq "pffrontieredge=pfcompletestep" "$v"
grep -Fq "pffrontierstatus=fdstatus.fe" "$v"
grep -Fq "HFPF P1 S" "$v"
grep -Fq "HFPF P1 B" "$v"
grep -Fq "pccnodes+pcinodes\=fpcount" "$v"
grep -Fq "pcrunbp=(ptcompletecount*10000)%prruns" "$v"
grep -Fq "pcnodebp=(pccnodes*10000)%fpcount" "$v"
grep -Fq "HFPC P1 S" "$v"
grep -Fq "HFPC P1 B" "$v"
grep -Fq "prauthpbp=(ptpresentauth*10000)%prauthtotal" "$v"
grep -Fq "prcommpbp=(ptpresentcomm*10000)%prcommtotal" "$v"
grep -Fq "HFPR P1 S" "$v"
grep -Fq "HFPR P1 A" "$v"
grep -Fq "HFPR P1 C" "$v"
if grep -Eq '^[[:space:]]*call.*,[[:space:]]*$' "$v"; then
 echo "FAIL: split CALL argument list is unsafe on CMS REXX" >&2
 exit 1
fi
grep -Fq "HISTORYDAGSTATE MESSAGE BYTES %lu" "$rec"
grep -Fq "HISTORYDAGSTATE SUBJECT BYTES %lu PREFIXBYTES %u" "$rec"
grep -Fq "HISTORYDAGSTATE SUBJECTHEX" "$rec"
grep -Fq "HISTORYDAGSTATE SUBJECT BLOBID" "$rec"
grep -Fq "HISTORYDAGSTATE MESSAGE BLOBID" "$rec"
grep -Fq "HISTORYDAGSTATE PARENTS %lu UNIQUE %lu" "$rec"
grep -Fq "HISTORYDAGSTATE FIRSTPARENT" "$rec"
grep -Fq "HISTORYDAGSTATE PARENTSEQ BLOBID" "$rec"
grep -Fq "seq+(*parents)*20UL" "$rec"
grep -Fq "HISTORYDAGSTATE SLOT CHILD %u ORDINAL %u PARENT %u" "$rec"
grep -Fq "HISTORYDAGSTATE SLOTS %u" "$rec"
grep -Fq "parent_slot_node" "$rec"
grep -Fq "subject_prefix_bytes" "$rec"
grep -Fq "ssubbytes.curnode=sb" "$v"
grep -Fq "ssubprefix.curnode=sp" "$v"
grep -Fq "ssubhex.curnode=sh" "$v"
grep -Fq "CHILDSUBJECT BYTES" "$v"
grep -Fq "PARENTSUBJECT BYTES" "$v"
grep -Fq "sauthorwhen.curnode=aw" "$v"
grep -Fq "scommitwhen.curnode=cw" "$v"
grep -Fq "smsgbytes.curnode=mb" "$v"
grep -Fq "emitnodechron:" "$v"
grep -Fq "emitpairchron:" "$v"
grep -Fq "COMMITTER DELTA SECONDS" "$v"
grep -Fq "AUTHOR DELTA SECONDS" "$v"
grep -Fq "AUTHOR TO COMMITTER LAG SECONDS" "$v"
grep -Fq "statechron:" "$v"
grep -Fq "HISTORYCHRONOLOGY FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYCHRONOLOGY AUTHOR NEGATIVE EDGES" "$v"
grep -Fq "HISTORYCHRONOLOGY COMMITTER NEGATIVE EDGES" "$v"
grep -Fq "HISTORYCHRONOLOGY LAG NEGATIVE NODES" "$v"
grep -Fq "if command='LEVEL' then do" "$v"
grep -Fq "address command 'EXEC GITVREF HISTBOUNDS' rest" "$g"
grep -Fq "address command 'EXEC GITVREF HISTEDGE' rest" "$g"
grep -Fq "command='HISTCHG'" "$v"
grep -Fq "HISTORYCHANGES FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYCHANGES DISTINCT PATH OIDS" "$v"
grep -Fq "HISTORYCHANGES STATUS' status" "$v"
grep -Fq "status='UNCHANGED'" "$v"
grep -Fq "status='CHANGED'" "$v"
grep -Fq "HISTORYCHANGES VERSION' vi 'OID' version.vi" "$v"
grep -Fq "'COUNT' freq.vi 'MINDEPTH' mindepth.vi" "$v"
grep -Fq "'MAXDEPTH' maxdepth.vi" "$v"
grep -Fq "curdepth=word(out.ci,5)" "$v"
grep -Fq "mindepth.distinct=curdepth" "$v"
grep -Fq "maxdepth.distinct=curdepth" "$v"
grep -Fq "parsednodes=parsednodes+1" "$v"
grep -Fq "if havepath=1 then return 'ERROR'" "$v"
grep -Fq "if parsednodes\\=nodes then return 'ERROR'" "$v"
grep -Fq "curcommit=translate(word(out.ci,3))" "$v"
grep -Fq "MINDEPTHCOMMIT' mincommit.vi" "$v"
grep -Fq "MAXDEPTHCOMMIT' maxcommit.vi" "$v"
grep -Fq "mincommit.distinct=curcommit" "$v"
grep -Fq "maxcommit.distinct=curcommit" "$v"
grep -Fq "HISTORYCHANGES VERSION' vi 'TYPE' vtype.vi 'SIZE' vsize.vi" "$v"
grep -Fq "curtype=word(out.ci,4)" "$v"
grep -Fq "cursize=word(out.ci,6)" "$v"
grep -Fq "if curtype<1 | curtype>3 then return 'ERROR'" "$v"
grep -Fq "if vtype.vi\\=curtype | vsize.vi\\=cursize then return 'ERROR'" "$v"
grep -Fq "HISTORYCHANGES VERSION' vi 'DEPTHS' depthtext.vi" "$v"
grep -Fq "depthtext.vi=result" "$v"
grep -Fq "vcommit.distinct.1=curcommit" "$v"
grep -Fq "vdepth.distinct.1=curdepth" "$v"
grep -Fq "vcidx=freq.vi" "$v"
grep -Fq "vcommit.vi.vcidx=curcommit" "$v"
grep -Fq "vdepth.vi.vcidx=curdepth" "$v"
grep -Fq "HISTORYCHANGES VERSION' vi 'COMMIT' vcommit.vi.ci" "$v"
grep -Fq "'DEPTH' vdepth.vi.ci" "$v"
grep -Fq "datatype(vdepth.vi.ci,'W')" "$v"
grep -Fq "curnode=word(out.ci,3)" "$v"
grep -Fq "curnode\\=parsednodes | curnode>64" "$v"
grep -Fq "seencommit.curcommit=1" "$v"
grep -Fq "curtree=translate(word(out.ci,3))" "$v"
grep -Fq "havetree=1" "$v"
grep -Fq "vnode.distinct.1=curnode" "$v"
grep -Fq "vtree.distinct.1=curtree" "$v"
grep -Fq "vnode.vi.vcidx=curnode" "$v"
grep -Fq "vtree.vi.vcidx=curtree" "$v"
grep -Fq "members=members+freq.vi" "$v"
grep -Fq "if members\\=nodes then exit 8" "$v"
grep -Fq "verify(vcommit.vi.ci,'0123456789ABCDEF')" "$v"
grep -Fq "verify(vtree.vi.ci,'0123456789ABCDEF')" "$v"
grep -Fq "HISTORYCHANGES VERSION' vi 'NODE' vnode.vi.ci" "$v"
grep -Fq "'TREE' vtree.vi.ci" "$v"
grep -Fq "depthseen.distinct.curdepth=1" "$v"
grep -Fq "depthseen.vi.curdepth=1" "$v"
grep -Fq "depthlist:" "$v"
grep -Fq "version.distinct=poid" "$v"
grep -Fq "vi=distinct" "$v"
grep -Fq "command='HISTPATH' & word(out.i,1)='HISTORYDAGPATH'" "$v"
grep -Fq "(word(out.i,2)='EDGE' | word(out.i,2)='EDGES')" "$v"
grep -Fq "freq.distinct=1" "$v"
grep -Fq "freq.vi=freq.vi+1" "$v"
grep -Fq "pathoids\\=nodes" "$v"
grep -Fq "GITREC HISTORYDAGPATH GITFIX M15NEW" "$v"
grep -Fq "HISTORYDAGPATH FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYDAGPATH EDGE CHILD %u PARENT %u" "$rec"
grep -Fq "HISTORYDAGPATH EDGES %u" "$rec"
grep -Fq "edge[head][pidx]=1" "$rec"
grep -Fq "nodeversion.curnode=vi" "$v"
grep -Fq "edgekey.ec.ep=1" "$v"
grep -Fq "parentseen.ep=1" "$v"
grep -Fq "if parentseen.1=1 then return 'ERROR'" "$v"
grep -Fq "HISTORYCHANGES CHANGED EDGES" "$v"
grep -Fq "HISTORYCHANGES UNCHANGED EDGES" "$v"
grep -Fq "CHILDVERSION' edgecv.ei" "$v"
grep -Fq "PARENTVERSION' edgepv.ei" "$v"
grep -Fq "STATUS' edgestatus.ei" "$v"
grep -Fq "command='HISTCHG' | command='HISTEDGE'" "$v"
grep -Fq "HISTORYEDGES FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYEDGES VERSIONS" "$v"
grep -Fq "HISTORYEDGES VERSION' vi 'OID' version.vi" "$v"
grep -Fq "HISTORYEDGES CHANGED EDGES" "$v"
grep -Fq "HISTORYEDGES UNCHANGED EDGES" "$v"
grep -Fq "HISTORYEDGES EDGE' ei 'CHILDVERSION' edgecv.ei" "$v"
grep -Fq "HISTORYEDGES EDGE' ei 'STATUS' edgestatus.ei" "$v"
grep -Fq "pairchild.pairs=cv" "$v"
grep -Fq "pairparent.pairs=pv" "$v"
grep -Fq "paircount.pairs=1" "$v"
grep -Fq "HISTORYEDGES TRANSITIONS" "$v"
grep -Fq "HISTORYCHANGES TRANSITIONS" "$v"
grep -Fq "GITREC HISTORYDAGSTATE GITFIX M15NEW" "$v"
grep -Fq "HISTORYDAGSTATE FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "address command 'PIPE VAR cmd | COMMAND | STEM out.'" "$v"
grep -Fq "else 'PIPE CMS' cmd '| STEM out.'" "$v"
grep -Fq "HISTORYDAGSTATE PATH PRESENT TYPE %d SIZE %lu" "$rec"
grep -Fq "HISTORYDAGSTATE PATH ABSENT" "$rec"
grep -Fq "rec_root_path_state" "$rec"
grep -Fq "statecheck:" "$v"
grep -Fq "stateemit:" "$v"
grep -Fq "statelog:" "$v"
grep -Fq "snodever.ni=0" "$v"
grep -Fq "snodever.ni=vi" "$v"
grep -Fq "if snodever.ni<0 | snodever.ni>sversions then return 'ERROR'" "$v"
grep -Fq "stateclass:" "$v"
grep -Fq "schangemin=9" "$v"
grep -Fq "schangemax=-1" "$v"
grep -Fq "snearcount=0" "$v"
grep -Fq "if schanged\=sadd+sdelete+smodify then return 'ERROR'" "$v"
grep -Fq "statestatus:" "$v"
grep -Fq "HISTORYSTATUS FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYSTATUS VERSIONS' sversions" "$v"
grep -Fq "HISTORYSTATUS NEAREST CHANGE DEPTH' schangemin" "$v"
grep -Fq "HISTORYSTATUS FARTHEST CHANGE DEPTH' schangemax" "$v"
grep -Fq "HISTORYSTATUS NEAREST CHANGES' snearcount" "$v"
grep -Fq "HISTORYSTATUS PATH STATUS' slifecycle" "$v"
grep -Fq "HISTORYSTATUS ADDED EDGES' sadd" "$v"
grep -Fq "HISTORYSTATUS DELETED EDGES' sdelete" "$v"
grep -Fq "HISTORYSTATUS MODIFIED EDGES' smodify" "$v"
grep -Fq "HISTORYLOG FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYLOG CHANGES' schanged" "$v"
grep -Fq "HISTORYLOG CHANGE' ei 'STATUS' sstatus.ei" "$v"
grep -Fq "HISTORYLOG NEAREST CHANGE DEPTH' schangemin" "$v"
grep -Fq "HISTORYLOG FARTHEST CHANGE DEPTH' schangemax" "$v"
grep -Fq "HISTORYLOG CHANGE' ei 'CHILDCOMMIT' scommit.ec" "$v"
grep -Fq "HISTORYLOG CHANGE' ei 'PARENTCOMMIT' scommit.ep" "$v"
grep -Fq "HISTORYSTATE FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYSTATE STATUS' slifecycle" "$v"
grep -Fq "HISTORYSTATE PRESENT' spresentcount" "$v"
grep -Fq "HISTORYSTATE ABSENT' sabsecount" "$v"
grep -Fq "HISTORYDIFFS PATH STATUS' slifecycle" "$v"
grep -Fq "HISTORYDIFFS PRESENT' spresentcount" "$v"
grep -Fq "HISTORYDIFFS ABSENT' sabsecount" "$v"
grep -Fq "HISTORYSTATE NODE' ni 'STATE' ns" "$v"
grep -Fq "HISTORYSTATE NODE' ni 'OID' soid.ni" "$v"
grep -Fq "HISTORYSTATE EDGE' ei 'CHILD' sedgechild.ei" "$v"
grep -Fq "statediff:" "$v"
grep -Fq "HISTORYDIFFS ADDED EDGES" "$v"
grep -Fq "HISTORYDIFFS DELETED EDGES" "$v"
grep -Fq "HISTORYDIFFS MODIFIED EDGES" "$v"
grep -Fq "HISTORYDIFFS UNCHANGED EDGES" "$v"
grep -Fq "sstatus.ei='ADDED'" "$v"
grep -Fq "sstatus.ei='DELETED'" "$v"
grep -Fq "sstatus.ei='MODIFIED'" "$v"
grep -Fq "HISTORYDIFFS EDGE' ei 'CHILDSTATE' cs" "$v"
grep -Fq "'PARENTSTATE' ps" "$v"
grep -Fq "HISTORYDIFFS FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYDIFFS NEAREST CHANGE DEPTH' schangemin" "$v"
grep -Fq "HISTORYDIFFS FARTHEST CHANGE DEPTH' schangemax" "$v"
grep -Fq "statetrans:" "$v"
grep -Fq "HISTORYTRANSITIONS FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "emittranschron:" "$v"
grep -Fq "AUTHOR MIN DELTA SECONDS" "$v"
grep -Fq "AUTHOR MAX DELTA SECONDS" "$v"
grep -Fq "COMMITTER MIN DELTA SECONDS" "$v"
grep -Fq "COMMITTER MAX DELTA SECONDS" "$v"
grep -Fq "AUTHOR NEGATIVE EDGES" "$v"
grep -Fq "COMMITTER NEGATIVE EDGES" "$v"
grep -Fq "call emittranschron 'HISTORYTRANSITIONS',ti" "$v"
grep -Fq "call emittranschron 'HISTORYREPORT',ti" "$v"
grep -Fq "call emittranschron 'HISTORYDIFFS',ti" "$v"
grep -Fq "statereport:" "$v"
grep -Fq "statebounds:" "$v"
grep -Fq "HISTORYBOUNDS FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYBOUNDS NEAREST DEPTH' schangemin" "$v"
grep -Fq "HISTORYBOUNDS FARTHEST DEPTH' schangemax" "$v"
grep -Fq "HISTORYBOUNDS BOUNDARY CHANGES' boundcount" "$v"
grep -Fq "'BOUND' bound" "$v"
grep -Fq "HISTORYREPORT FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYREPORT TRANSITIONS' trpairs" "$v"
grep -Fq "HISTORYREPORT CHANGE' change 'EDGE' ei" "$v"
grep -Fq "HISTORYREPORT NEAREST CHANGE DEPTH' schangemin" "$v"
grep -Fq "HISTORYTRANSITIONS STATE 0 ABSENT" "$v"
grep -Fq "HISTORYTRANSITIONS TRANSITIONS' trpairs" "$v"
grep -Fq "HISTORYTRANSITIONS CHANGED TRANSITIONS' trchanged" "$v"
grep -Fq "HISTORYTRANSITIONS TRANSITION' ti 'CHILDSTATE' cv" "$v"
grep -Fq "HISTORYTRANSITIONS TRANSITION' ti 'STATUS' trstatus.ti" "$v"
grep -Fq "statenear:" "$v"
grep -Fq "HISTORYNEAREST FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "HISTORYNEAREST DEPTH' schangemin" "$v"
grep -Fq "HISTORYNEAREST MATCHES' snearcount" "$v"
grep -Fq "HISTORYNEAREST CHANGE' match 'EDGE' ei" "$v"
grep -Fq "HISTORYDIFFS CHANGED EDGES" "$v"
grep -Fq "HISTORYDIFFS STATUS" "$v"
grep -Fq "HISTORYEDGES TRANSITION' ti 'CHILDOID' version.cv" "$v"
grep -Fq "HISTORYCHANGES TRANSITION' ti 'PARENTOID' version.pv" "$v"
grep -Fq "if distinct=1 & changededges\\=0 then exit 8" "$v"
grep -Fq "if distinct>1 & changededges=0 then exit 8" "$v"
grep -Fq "GITREC LOGDAGFULL GITFIX M15NEW" "$v"
grep -Fq "LOGDAG FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "GITREC LOGFULL GITFIX M15NEW" "$v"
grep -Fq "LOG FULL SNAPSHOTS VERIFIED" "$v"
grep -Fq "command='READ'" "$v"
grep -Fq "GITREC PATHFULLCAT GITFIX M15NEW" "$v"
grep -Fq "COMMIT ROOT FULL CLOSURE VERIFIED" "$v"
grep -Fq "command = 'READ-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF READ' rest" "$g"
grep -Fq "pathasciihex:" "$v"
grep -Fq "command='DIR'" "$v"
grep -Fq "GITREC PATHFULLDIR GITFIX M15NEW" "$v"
grep -Fq "command = 'DIR-REF-FULL'" "$g"
grep -Fq "address command 'EXEC GITVREF DIR' rest" "$g"
if grep -Eq "^[[:space:]]*'EXEC GITVREF " "$g"; then
 echo "FAIL: GITVREF wrapper route can uppercase case-sensitive args" >&2
 exit 1
fi
if grep -Ei "(DISKW|ERASE|COPYFILE|GENWRITE|SELOUT|IDXOUT|FIDXOUT|GENOUT)" "$v"; then
 echo "FAIL: verified-ref bridge contains persistent write path" >&2
 exit 1
fi
awk 'length($0)>80 {print "FAIL: GITVREF record >80 columns:", NR; bad=1}
     END {exit bad}' "$v"
awk 'length($0)>80 {print "FAIL: GITREF2 record >80 columns:", NR; bad=1}
     END {exit bad}' "$r"
grep -Fq "if command = 'IMPORT-OBJECT' then do" "$g"
grep -Fq "'EXEC GITIMP' rest" "$g"
grep -Fq "if command = 'CHECKOUT-FILE' then do" "$g"
grep -Fq "'EXEC GITWT CHECKOUT' rest" "$g"
grep -Fq "if command = 'STATUS' then do" "$g"
grep -Fq "'EXEC GITWT STATUS' rest" "$g"
grep -Fq "if command = 'ADD' then do" "$g"
grep -Fq "'EXEC GITWT ADD' rest" "$g"
grep -Fq "command = 'HASH-WORKFILE'" "$g"
grep -Fq "command = 'WRITE-WORKFILE'" "$g"
grep -Fq "strip(wline.i,'T')" "$g"
grep -Fq "if final = '1' then hex = hex || '0A'" "$g"
echo "M164 PRACTICAL WORKTREE ROUTE GUARDS PASSED"

)
exit 0
fi
# Independent M155 and M157 source guards retained verbatim.
if [ "${1:-}" = "M155" ] || [ "${1:-}" = "M157" ]; then
  shift
  (
# Preserved standalone M157 assertions, selected independently in CI.
if [ "${1:-}" = "M157" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
x="$root/src/M157GATE.EXEC"
test -s "$x"
grep -Fq "'M155CHK'" "$x"
grep -Fq "'M156CHK'" "$x"
grep -Fq "'M157CHK'" "$x"
grep -Fq "M157GATE M155 FAIL RC" "$x"
grep -Fq "M157GATE M156 FAIL RC" "$x"
grep -Fq "M157GATE M157 FAIL RC" "$x"
grep -Fq "M157GATE COMBINED TARGET GATE PASS" "$x"
if grep -Fq "PIPE " "$x"; then
 echo "FAIL: M157GATE must execute compact checkers directly" >&2
 exit 1
fi
if grep -Ei "(DISKW|ERASE|COPYFILE|GENWRITE|SELOUT|IDXOUT|FIDXOUT|GENOUT)" "$x"; then
 echo "FAIL: M157 combined gate contains persistent write path" >&2
 exit 1
fi
awk 'length($0)>80 {print "FAIL: M157GATE record >80:",NR; bad=1}
     END {exit bad}' "$x"
echo "M157 DIRECT TARGET GATE SOURCE CHECK PASSED"

)
exit 0
fi
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
x="$root/src/M155CHK.EXEC"
test -s "$x"
grep -Fq "EXEC GIT HISTORYFIRSTPRESENCECHRONOLOGY-REF-FULL" "$x"
grep -Fq "EXEC GIT HISTORYFIRSTPRESENCEEVENTS-REF-FULL" "$x"
grep -Fq "M155 CHRONOLOGY DIRECT RC0" "$x"
grep -Fq "M155 EVENTS DIRECT RC0" "$x"
grep -Fq "path='src/GITPBWALK.EXEC'" "$x"
grep -Fq "M155 CHECKER STAMP C4" "$x"
grep -Fq "M155 GIT STAMP PASS C4" "$x"
grep -Fq "M155 GITREC STAMP PASS S2" "$x"
grep -Fq "GITREC STATEPATH S2" "$x"
grep -Fq "M155 CASE PROBE PASS C6" "$x"
grep -Fq "M155 PARENT PATH PASS" "$x"
grep -Fq "M155 CHILD ABSENT PASS RC4" "$x"
grep -Fq "91913EA4028B795707AA67EDB1ED17A74D1B896E" "$x"
grep -Fq "EXEC GIT READ-REF-FULL" "$x"
grep -Fq "GITVREF CASE C6 7372632F474954504257414C4B2E45584543" "$x"
grep -Fq "M155 COMPACT TARGET GATE PASS" "$x"
test "$(grep -c '^address command cmd$' "$x")" -eq 2
if grep -Fq "| STEM chr." "$x" || grep -Fq "| STEM evt." "$x" ||
   grep -Fq "| STEM sta." "$x"; then
 echo "FAIL: M155 history command is still pipeline-captured" >&2
 exit 1
fi
if grep -Ei "(DISKW|ERASE|COPYFILE|GENWRITE|SELOUT|IDXOUT|FIDXOUT|GENOUT)" "$x"; then
 echo "FAIL: M155 compact gate contains persistent write path" >&2
 exit 1
fi
awk 'length($0)>80 {print "FAIL: M155CHK record >80:",NR; bad=1}
     END {exit bad}' "$x"
echo "M155 DIRECT CMS TARGET GATE SOURCE CHECK PASSED"

  )
  exit 0
fi
# Preserved read-only GITRCHK guard in independent mode.
if [ "${1:-}" = "READONLY" ]; then
(
# Protect historical M20 and compact M62 Git CMS regressions.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
f="$root/src/GITRCHK.EXEC"
run="$root/src/GITRUN.EXEC"
test -s "$f"
test -s "$run"
grep -q "^say 'GITRCHK M20 READ-ONLY" "$f"
grep -Fq "'GITREC CATHEX GITFIX M15NEW' oid" "$f"
grep -Fq "'GITREC GET GITFIX M15NEW' oid" "$f"
grep -q "^say 'GITRUN M62 COMPACT REPORT'$" "$run"
grep -Fq "'PIPE CMS' cmd '| STEM out.'" "$run"
grep -Fq "'PIPE CMS STATE M15BAD GEN A | STEM out.'" "$run"
grep -Fq "call gate name 'FULL AUDIT','GITCIDX GENCHECK',0,fast,pair,gen" "$run"
# Every positive original-data feature runs after one selector audit.
grep -Fq "call gate 'M62 ONE SELECTION ALL POSITIVES'," "$run"
grep -Fq "cmd='GITREC RUNBATCH GITFIX M15NEW' commit tree" "$run"
grep -Fq "say 'PASS SELECT SEQ52 FROM VERIFIED BATCH'" "$run"
if grep -Fq "GITREC SELECT GITFIX M15NEW" "$run"; then
 echo "FAIL: separate redundant seq52 full audit" >&2
 exit 1
fi
if grep -Eq "call gate 'M62 (SINGLE|SRC|FULL|TREE|README)" "$run"; then
 echo "FAIL: redundant separate positive full-audit calls" >&2
 exit 1
fi
grep -Fq "call gate 'INVALID DEPTH',cmd,4," "$run"
grep -Fq "BATCH NON COMMIT CHILD RC8 VERIFIED" "$run"
grep -Fq "BATCH MISSING CHILD RC4 VERIFIED" "$run"
grep -Fq "BATCH ROOT CLOSURE REUSES " "$run"
grep -Fq "BATCH SEEK INDEX REUSES " "$run"
grep -Fq "PASS SHARED VERIFIED SEEK INDEX" "$run"
grep -Fq "PASS FULL HISTORY ROOT CLOSURE" "$run"
grep -Fq "PASS FULL ALL-PARENT HISTORY ROOT CLOSURE" "$run"
grep -Fq "PASS FULL ALL-PARENT HISTORY PATH" "$run"
grep -Fq "PASS SHOW FULL SNAPSHOT" "$run"
grep -Fq "PASS LOG FULL SNAPSHOTS" "$run"
grep -Fq "PASS LOGDAG FULL SNAPSHOTS" "$run"
grep -Fq "PASS SHARED VERIFIED ROOT CLOSURE" "$run"
if grep -Eq "call gate '(NON COMMIT CHILD|MISSING CHILD)'" "$run"; then
 echo "FAIL: separate full selector audit for expected negative" >&2
 exit 1
fi
grep -Fq "call gate 'RECOVERED BATCH',cmd,0," "$run"
grep -Fq "call gate 'BOTH INVALID FAIL CLOSED',cmd,8," "$run"
grep -Fq "call gate 'RESTORED BATCH',cmd,0," "$run"
grep -q "^say 'GITRUN M62 ALL READ ONLY NATIVE GIT TESTS PASSED'$" "$run"
awk 'length($0)>80 {print "FAIL: GITRUN record >80 columns:", NR; bad=1}
     END {exit bad}' "$run"
if grep -E '^[[:space:]]*call gate .*,$' "$run"; then
 echo "FAIL: split REXX CALL arguments" >&2
 exit 1
fi
for file in "$f" "$run"; do
 if grep -Ei "^[[:space:]]*'?(ERASE|COPYFILE|GENWRITE|FORMAT|GENMOD|SELOUT|FILEDEF (IDXOUT|FIDXOUT|GENOUT))([[:space:]]|'|$)" "$file"; then
  echo "FAIL: persistent CMS command in read-only gate $file" >&2
  exit 1
 fi
done
echo "READ-ONLY GITRCHK AND COMPACT GITRUN M62 GUARDS PASSED"

)
exit 0
fi
# Independent CMSCLNK guard retained as a selectable host-only mode.
if [ "${1:-}" = "CMSCLNK" ]; then
(
# Static checks only: actual GCCCMS compilation remains a CMS gate.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
file="$root/src/CMSCLNK.EXEC"
test -f "$file"
awk 'length($0)>80 {
 printf "CMSCLNK line %d too long: %d\n",NR,length($0)
 bad=1
} END {exit bad}' "$file"
# CMS GCCCMS compile path truncates long C source records. Host C89
# compilation alone does not reveal this target-specific failure.
awk 'length($0)>72 {
 printf "GITREC.C line %d exceeds 72: %d\\n",NR,length($0)
 bad=1
} END {exit bad}' "$root/src/GITREC.C"
grep -Fq "if mode='' then mode='NAPI'" "$file"
grep -Fq "if mode='NAPI' then do" "$file"
grep -Fq "'ASSEMBLE GITCAPI'" "$file"
grep -Fq "'ASSEMBLE GITINFA'" "$file"
grep -Fq "'GLOBAL TXTLIB PDPCLIB'" "$file"
grep -Fq "'LOAD' name 'GITCAPI GITINFA (NOAUTO NOMAP'" "$file"
grep -Fq "'LOAD' name '(NOAUTO NOMAP'" "$file"
grep -Fq "'GENMOD' name" "$file"
grep -Fq 'COPYFILE CMSCLNK EXEC A CMSCLNK EXEC F' \
 "$root/docs/BUILD.md"
grep -Fq 'QUERY DISK F' "$root/docs/BUILD.md"
echo 'CMSCLNK source and F-disk installation checks passed'

)
exit 0
fi
# Guard against host-only tests missing the CMS EBCDIC hash bug.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
walk="$root/src/GITCWALK.C"
index="$root/src/GITCIDX.C"
for path in "$walk" "$index"; do
 awk 'length($0)>80 {print FNR ": width " length($0);bad=1}
      END {exit bad}' "$path"
 grep -Fq '0x62,0x6c,0x6f,0x62' "$path"
 grep -Fq 'dst[i++]=0x20;' "$path"
 grep -Fq '0x30+rem%10' "$path"
done
grep -Fq 'k=canonical_head(type,n,hashbuf)' "$walk"
grep -Fq 'k=canonical_head(type,n,head)' "$walk"
grep -Fq 'memcmp(objoid[0],shaabc,20)' "$walk"
grep -Fq 'memcmp(missing,shafive,20)' "$walk"
grep -Fq 'head=idx_head(type,n,idx_hashbuf)' "$index"
grep -Fq 'INDEX CANONICAL ASCII ABC PASSED' "$index"
grep -Fq 'sscanf(line,"IDX2 ' "$index"
grep -Fq 'sscanf(line,"SIDX2 ' "$index"
if grep -Eq 'sprintf\(\(char \*\)(hashbuf|head|idx_hashbuf)'    "$walk" "$index"; then
 echo 'CMS-native formatted text in a canonical Git SHA header' >&2
 exit 1
fi
echo 'Canonical ASCII header and CMS C source guards passed'
