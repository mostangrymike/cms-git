#!/bin/sh
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
