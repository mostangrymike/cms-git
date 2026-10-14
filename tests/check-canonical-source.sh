#!/bin/sh
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
