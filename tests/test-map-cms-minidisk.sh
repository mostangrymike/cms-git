#!/usr/bin/env bash
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
