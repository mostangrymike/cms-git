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

# M208 modern REF2 lightweight commit-tag source and REXX syntax gate.
if [ "${1:-}" = "M208" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
for file in GIT.EXEC GITUPD.EXEC GITVREF.EXEC GITWT.EXEC; do
 path="$root/src/$file"
 test -s "$path"
 awk 'length($0)>80 {print FILENAME ":" FNR ":" length($0);bad=1}
      END {exit bad}' "$path"
 rexx -c "$path" /dev/null
done
python3 - "$root" <<'PY'
from pathlib import Path
import sys
root=Path(sys.argv[1])
g=(root/'src/GIT.EXEC').read_text()
u=(root/'src/GITUPD.EXEC').read_text()
v=(root/'src/GITVREF.EXEC').read_text()
w=(root/'src/GITWT.EXEC').read_text()
required={
 'GIT.EXEC': (g, ("if command = 'TAG' then do", "EXEC GITVREF TAGS",
     "verb='-L' | verb='--LIST'",
     "say 'Usage: GIT TAG [-l|--list [pattern]]'",
     "verb='-F' | verb='--FORCE'",
     "say 'Usage: GIT TAG -f|--force name new-oid [expected-old-oid]'",
     'if oldoid=zeros then do',
     "EXEC GIT UPDATE-REF' ref newoid oldoid",
     "verb='-D' | verb='--DELETE'",
     "say '       GIT TAG -d|--delete name [expected-commit-oid]'",
     "ref='refs/tags/'||action", "ref='refs/tags/'||tagname",
     "EXEC GIT UPDATE-REF' ref oid zeros",
     "EXEC GIT UPDATE-REF' ref zeros expectedoid")),
 'GITUPD.EXEC': (u, ("left(vr,11)='refs/heads/'",
     "left(vr,10)='refs/tags/'", "EXEC GIT VERIFY-OBJECT' newoid",
     'current\\=oldoid', 'call restore')),
 'GITVREF.EXEC': (v, ("command='TAGS' then do",
     "left(refname.ti,10)='refs/tags/'", "left(wanted,10)\\='refs/tags/'",
     "wanted='refs/tags/'||shortname",
     'tagcandidate=substr(refname.ti,11)',
     'taglist.tagcount=tagcandidate', 'say taglist.ti',
     'call validref name')),
 'GITWT.EXEC': (w, ('call validref name',
     "left(headref,11)\\='refs/heads/'", "left(wanted,11)\\='refs/heads/'")),
}
for name,(source,tokens) in required.items():
 for token in tokens:
  if token not in source:
   raise SystemExit(f'{name}: missing tag/ref guard {token!r}')
if (root/'src/GITP208M.C').exists() or (root/'src/GITC208.EXEC').exists():
 raise SystemExit('M208 added a numbered CMS program')
print('M208 REF2 lightweight commit-tag source checks PASS')
PY
echo 'M208 REXX syntax and 80-column checks PASS (CMS UNVERIFIED)'
)
exit $?
fi

# Exercise the exact source-derived REXX tag-list matcher on the host.
if [ "${1:-}" = "M210" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M208
python3 - "$root/src/GIT.EXEC" "$root/src/GITVREF.EXEC" <<'PY'
from pathlib import Path
import sys
cli=Path(sys.argv[1]).read_text()
refs=Path(sys.argv[2]).read_text()
for token in ("address command 'EXEC GITVREF TAGS' tagname",):
 if token not in cli:
  raise SystemExit(f'GIT.EXEC missing list-pattern forwarding: {token}')
for token in ("if spec='' then do",
              "tagchars=tagchars||'0123456789._/-*?'",
              'call tagmatch tagpattern, tagcandidate',
              "if tagmatchresult='MATCH' then do",
              'call tagbefore taglist.tj, tagitem',
              'say taglist.ti'):
 if token not in refs:
  raise SystemExit(f'GITVREF.EXEC missing list-pattern behavior: {token}')
print('M210 LIST-PATTERN INTEGRATION GUARDS PASS')
PY
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GITVREF.EXEC" "$tmp/tagmatch.rexx" <<'PY'
from pathlib import Path
import sys
source=Path(sys.argv[1]).read_text()
start=source.index("\ntagmatch:\n")+1
end=source.index("\nbindnative:\n",start)
routine=source[start:end]
Path(sys.argv[2]).write_text(
    "parse arg pattern value\ncall tagmatch pattern, value\nsay result\nexit 0\n"+routine+"\n")
PY
rexx -c "$tmp/tagmatch.rexx" /dev/null
check() {
 expected=$1
 pattern=$2
 value=$3
 actual=$(rexx "$tmp/tagmatch.rexx" "$pattern" "$value")
 if [ "$actual" != "$expected" ]; then
  echo "tag matcher $pattern / $value: expected $expected, got $actual" >&2
  exit 1
 fi
}
check MATCH 'v*' v2.0
check MATCH 'v?.*' v2.0
check MATCH 'v*0' v20
check MATCH 'release/*' release/2026.10
check MATCH '*' plain
check NO 'v?.*' v12.0
check NO 'v*rc' v2.0
check NO 'release/*' release
check MATCH '*' ''
echo 'M210 SOURCE-DERIVED REXX TAG GLOB FIXTURES PASS 9'
)
exit $?
fi

# Run the exact REF2 name validators from each caller under Regina REXX.
if [ "${1:-}" = "M213" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M210
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root" "$tmp" <<'PY'
from pathlib import Path
import sys
root=Path(sys.argv[1]); out=Path(sys.argv[2])
ends={'GITUPD.EXEC':'requirecommit',
      'GITVREF.EXEC':'directinput',
      'GITWT.EXEC':'resolve'}
for filename,endlabel in ends.items():
 source=(root/'src'/filename).read_text()
 start=source.index('\nvalidref:\n')+1
 end=source.index('\n'+endlabel+':\n',start)
 (out/(filename+'.rexx')).write_text(
  'parse arg name\ncall validref name\nsay result\nexit 0\n'+
  source[start:end]+'\n')
PY
longname=refs/tags/abcdefghijklmnopqrstuvwxyz
for file in GITUPD.EXEC GITVREF.EXEC GITWT.EXEC; do
 rexx -c "$tmp/$file.rexx" /dev/null
 for name in refs/tags/v1.2 refs/tags/release/2026.10 \
             refs/tags/with-underscore_1 refs/heads/main \
             refs/heads/feature/x refs/heads/topic-1 \
             refs/heads/under_score; do
  rexx "$tmp/$file.rexx" "$name" > "$tmp/result"
  actual=$(tail -n 1 "$tmp/result")
  if [ "$actual" != OK ]; then
   echo "$file rejected valid ref $name: $actual" >&2
   exit 1
  fi
 done
 for name in refs/tags/.hidden refs/tags/a..b refs/tags/branch.lock \
             'refs/tags/bad*' refs/tags/a//b refs/tags/a/ "$longname" \
             'refs/heads/bad|name' 'refs/heads/bad#name' \
             refs/heads/.hidden refs/heads/a//b refs/heads/a/ \
             refs/heads/main.lock 'refs/heads/bad name' \
             refs/heads/a..b; do
  rexx "$tmp/$file.rexx" "$name" > "$tmp/result"
  actual=$(tail -n 1 "$tmp/result")
  if [ "$actual" != ERROR ]; then
   echo "$file accepted invalid ref $name: $actual" >&2
   exit 1
  fi
 done
done
echo 'M213 SOURCE-DERIVED REF2 VALIDATOR FIXTURES PASS 66'
)
exit $?
fi

# Keep branch-name validation identical across REF2 readers and writers.
if [ "${1:-}" = "M223" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M222
python3 - "$root" <<'PY'
from pathlib import Path
import sys

root=Path(sys.argv[1])
blocks=[]
for filename in ('GITUPD.EXEC','GITVREF.EXEC','GITWT.EXEC'):
 source=(root/'src'/filename).read_text()
 start=source.index("if left(vr,11)='refs/heads/' then do")
 end=source.index("  return 'OK'\n end",start)+len("  return 'OK'\n end")
 block=source[start:end]
 for token in ("verify(name,refchars)\\=0", "pos('//',name)>0",
               "right(part,5)='.lock'", "left(part,1)='.'"):
  if token not in block:
   raise SystemExit(f'{filename}: missing strict branch-ref rule {token!r}')
 blocks.append(block)
if len(set(blocks)) != 1:
 raise SystemExit('branch-name validators differ across REF2 callers')
print('M223 STRICT BRANCH REF VALIDATOR PARITY PASS 3')
PY
)
exit $?
fi

# Validate branch operands before GIT.EXEC interpolates them into CMS commands.
if [ "${1:-}" = "M224" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M223
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GIT.EXEC" "$tmp/validbranch.rexx" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
start=source.index('validbranch: procedure')
end=source.index('resolvestart: procedure',start)
routine=source[start:end]
Path(sys.argv[2]).write_text(
 'parse arg name\ncall validbranch name\nsay result\nexit 0\n'+routine+'\n')
cli=source
guards=(
 ('call validbranch brancharg3', "oldref='refs/heads/'||brancharg2"),
 ('call validbranch brancharg2', "branchref='refs/heads/'||brancharg2"),
 ('call validbranch brancharg1', "branchref='refs/heads/'||brancharg1"),
 ('call validbranch brancharg', "cmd='EXEC GITUPD CREATE-HEAD"),
 ('call validbranch branchname', "cmd='EXEC GITUPD HEAD refs/heads/'||branchname"),
)
for guard, command in guards:
 if cli.index(guard) >= cli.index(command):
  raise SystemExit(f'branch command lacks early operand guard: {guard}')
print('M224 EARLY BRANCH OPERAND GUARDS PASS 5')
PY
rexx -c "$tmp/validbranch.rexx" /dev/null
check() {
 expected=$1
 name=$2
 actual=$(rexx "$tmp/validbranch.rexx" "$name")
 if [ "$actual" != "$expected" ]; then
  echo "branch validator $name: expected $expected, got $actual" >&2
  exit 1
 fi
}
for name in main feature/x topic-1 under_score RC/ARM-64 a.b a; do
 check OK "$name"
done
for name in '' 'bad|name' 'bad#name' 'bad name' .hidden a/.hidden a//b \
            a/ main.lock a..b /main main/ trailing. \
            1234567890123456789012345; do
 check ERROR "$name"
done
echo 'M224 SOURCE-DERIVED BRANCH OPERAND FIXTURES PASS 21'
)
exit $?
fi

# Validate lightweight-tag operands before GIT.EXEC forwards CMS commands.
if [ "${1:-}" = "M225" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M224
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GIT.EXEC" "$tmp/validtag.rexx" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
start=source.index('validtag: procedure')
end=source.index('validbranch: procedure',start)
routine=source[start:end]
Path(sys.argv[2]).write_text(
 'parse arg input\nmode=left(input,1)\nname=substr(input,3)\n' +
 "if mode='P' then mode='PATTERN'\n" +
 'call validtag name, mode\nsay result\nexit 0\n'+
 routine+'\n')
tag=source[source.index("if command = 'TAG' then do"):]
checks=(
 ("if verb='-L'", "call validtag tagname, 'PATTERN'",
  "address command 'EXEC GITVREF TAGS' tagname"),
 ("if verb='-F'", 'call validtag tagname', "ref='refs/tags/'||tagname"),
 ("if verb='-D'", 'call validtag tagname', "ref='refs/tags/'||tagname"),
 ("if action=''", 'call validtag action', "ref='refs/tags/'||action"),
)
for marker, guard, command in checks:
 section=tag[tag.index(marker):]
 if section.index(guard) >= section.index(command):
  raise SystemExit(f'tag command lacks early operand guard: {marker}')
print('M225 EARLY TAG OPERAND GUARDS PASS 4')
PY
rexx -c "$tmp/validtag.rexx" /dev/null
check() {
 expected=$1
 name=$2
 mode=${3:-NAME}
 prefix=N
 if [ "$mode" = PATTERN ]; then prefix=P; fi
 actual=$(rexx "$tmp/validtag.rexx" "$prefix:$name")
 if [ "$actual" != "$expected" ]; then
  echo "tag validator $name ($mode): expected $expected, got $actual" >&2
  exit 1
 fi
}
for name in v1.2 release/2026.10 with-underscore_1 topic-2 a; do
 check OK "$name"
done
for name in 'v*' 'v?.*' 'release/*'; do
 check OK "$name" PATTERN
done
for name in 'bad|name' 'bad#name' 'bad name' .hidden a/.hidden \
            a//b a/ . .. a..b main.lock trailing. /tag \
            12345678901234567890123456; do
 check ERROR "$name"
done
check ERROR 'bad*' NAME
check ERROR 'bad?' NAME
check ERROR 'bad|*' PATTERN
echo 'M225 SOURCE-DERIVED TAG OPERAND FIXTURES PASS 25'
)
exit $?
fi

# Resolve lightweight-tag start points with verified REF2 output.
if [ "${1:-}" = "M226" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M225
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GIT.EXEC" "$tmp/resolvetagtarget.rexx" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
tag_start=source.index('resolvetagtarget: procedure')
start_end=source.index('resolvestart: procedure',tag_start)
res_start=source.index('resolvestart: procedure',start_end)
query_start=source.index('queryref: procedure',res_start)
query_end=source.index('\n',source.index('return \'OK\'',query_start))
helpers=source[tag_start:query_start]
helpers=helpers.replace(
 'resolvetagtarget: procedure expose rs.',
 'resolvetagtarget: procedure expose rs. mode')
program=(
 'parse arg mode wanted\ncall resolvetagtarget wanted\nsay result\nexit 0\n'+
 helpers+
 "queryref: procedure expose rs. mode\n"
 " parse arg qspec\n drop rs.\n"
 " if mode='missing' then do\n  rs.0=0\n  return 'ERROR'\n end\n"
 " rs.0=1\n"
 " if mode='badframe' then rs.1='BROKEN REF ' qspec\n"
 " else if mode='wrongref' then rs.1='VERIFIED REF other AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 " else if mode='badoid' then rs.1='VERIFIED REF ' qspec ' SHORT'\n"
 " else rs.1='VERIFIED REF ' qspec ' AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 " return 'OK'\n")
Path(sys.argv[2]).write_text(program)
tag=source[source.index("if command = 'TAG' then do"):]
create=tag[tag.index("if action='' "):]
for token in ("if tagstart='' then tagstart='HEAD'",
              'call resolvetagtarget tagstart',
              "if result\\='OK' | objtype\\='COMMIT' then do",
              "address command 'EXEC GIT UPDATE-REF' ref oid zeros"):
 if token not in create:
  raise SystemExit(f'M226 tag creation missing {token!r}')
if create.index('call resolvetagtarget tagstart') > create.index("address command 'EXEC GIT VERIFY-OBJECT' oid"):
 raise SystemExit('M226 verifies target before resolving start point')
print('M226 TAG START-POINT DISPATCH GUARDS PASS 5')
PY
rexx -c "$tmp/resolvetagtarget.rexx" /dev/null
check() {
 expected=$1
 mode=$2
 wanted=$3
 actual=$(rexx "$tmp/resolvetagtarget.rexx" "$mode" "$wanted")
 if [ "$actual" != "$expected" ]; then
  echo "tag start resolver $mode / $wanted: expected $expected, got $actual" >&2
  exit 1
 fi
}
oid=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
check "$oid" good HEAD
check "$oid" good main
check "$oid" good refs/tags/v1
check "$oid" good "$oid"
for mode in missing badframe wrongref badoid; do
 check ERROR "$mode" HEAD
done
check ERROR good 'bad|name'
echo 'M226 SOURCE-DERIVED TAG START-POINT FIXTURES PASS 9'
)
exit $?
fi

# Sort modern branch listing with the shared REF2 name ordering.
if [ "${1:-}" = "M227" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M226
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GITVREF.EXEC" "$tmp/branches.rexx" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
start=source.index("if command='BRANCHES' then do")
end=source.index("if command='TAGS' then do",start)
branch_block=source[start:end]
sort_start=source.index('tagbefore:\n')
sort_end=source.index('bindnative:\n',sort_start)
sorter=source[sort_start:sort_end]
fixture=(
 "parse arg\ncommand='BRANCHES'\nspec=''\ndepth=''\nextra=''\n"
 "headref='refs/heads/main'\nrefcount=5\n"
 "refname.1='refs/heads/z'\nrefname.2='refs/heads/2'\n"
 "refname.3='refs/heads/main'\nrefname.4='refs/heads/feature/x'\n"
 "refname.5='refs/heads/10'\n"
 +branch_block+
 "exit 99\nreadrefs:\n return 'OK'\n"+sorter)
Path(sys.argv[2]).write_text(fixture)
if branch_block.index('call tagbefore') > branch_block.index('do bi=1 to branchcount'):
 raise SystemExit('M227 emits branches before sorting')
print('M227 BRANCH LIST SORT SOURCE GUARD PASS')
PY
rexx -c "$tmp/branches.rexx" /dev/null
rexx "$tmp/branches.rexx" > "$tmp/actual"
printf '  10\n  2\n  feature/x\n* main\n  z\n' > "$tmp/expected"
if ! cmp -s "$tmp/expected" "$tmp/actual"; then
 diff -u "$tmp/expected" "$tmp/actual" >&2
 exit 1
fi
echo 'M227 SOURCE-DERIVED BRANCH ORDER FIXTURE PASS 1'
)
exit $?
fi

# Return the verified symbolic HEAD as a short modern branch name.
if [ "${1:-}" = "M228" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M227
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GIT.EXEC" "$tmp/branchname.rexx" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
route=source[source.index("if command = 'BRANCH' then do"):
             source.index("/* M218: change symbolic HEAD")]
start=source.index('branchnamefromhead: procedure')
end=source.index('validtag: procedure',start)
branch_helper=source[start:end]
start=source.index('validbranch: procedure')
end=source.index('resolvetagtarget: procedure',start)
valid_helper=source[start:end]
fixture=(
 'parse arg candidate\ncall branchnamefromhead candidate\n'
 'say result\nexit 0\n'+branch_helper+valid_helper)
Path(sys.argv[2]).write_text(fixture)
start=route.index("if verb='--SHOW-CURRENT' then do")
end=route.index("if brancharg1='-m'",start)
show=route[start:end]
if show.index("Usage: GIT BRANCH --show-current") > show.index('PIPE CMS EXEC GITVREF HEAD'):
 raise SystemExit('M228 queries HEAD before checking command arguments')
for token in ('showhead.0\\=1', 'call branchnamefromhead showhead.1',
              'say result', 'exit 0'):
 if token not in show:
  raise SystemExit(f'M228 route missing {token!r}')
print('M228 BRANCH --SHOW-CURRENT ROUTE GUARDS PASS 4')
PY
rexx -c "$tmp/branchname.rexx" /dev/null
check() {
 expected=$1
 candidate=$2
 actual=$(rexx "$tmp/branchname.rexx" "$candidate")
 if [ "$actual" != "$expected" ]; then
  echo "branch HEAD parser $candidate: expected $expected, got $actual" >&2
  exit 1
 fi
}
check main refs/heads/main
check feature/x ' refs/heads/feature/x '
for candidate in HEAD refs/tags/v1 refs/heads/ refs/heads/bad\|name \
                 refs/heads/.hidden refs/heads/a//b; do
 check ERROR "$candidate"
done
echo 'M228 SOURCE-DERIVED CURRENT BRANCH FIXTURES PASS 8'
)
exit $?
fi

# Filter sorted modern branch listing using the shared wildcard matcher.
if [ "${1:-}" = "M229" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M228
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GIT.EXEC" "$root/src/GITVREF.EXEC" \
 "$tmp/validbranch.rexx" "$tmp/branches.rexx" <<'PY'
from pathlib import Path
import sys

git=Path(sys.argv[1]).read_text()
refs=Path(sys.argv[2]).read_text()
branch_start=refs.index("if command='BRANCHES' then do")
branch_end=refs.index("if command='TAGS' then do",branch_start)
branch_block=refs[branch_start:branch_end]
match_start=refs.index('tagmatch:\n')
match_end=refs.index('bindnative:\n',match_start)
matcher=refs[match_start:match_end]
start=git.index('validbranch: procedure')
end=git.index('resolvetagtarget: procedure',start)
Path(sys.argv[3]).write_text(
 'parse arg name mode\ncall validbranch name, mode\nsay result\nexit 0\n'+
 git[start:end])
branch_route=git[git.index("if command = 'BRANCH' then do"):
                 git.index("/* M218: change symbolic HEAD")]
list_start=branch_route.index("if verb='-L' | verb='--LIST'")
list_end=branch_route.index("if verb='--SHOW-CURRENT'",list_start)
listing=branch_route[list_start:list_end]
if listing.index("call validbranch brancharg2, 'PATTERN'") > listing.index(
        "address command 'EXEC GITVREF BRANCHES' brancharg2"):
 raise SystemExit('M229 forwards branch pattern before validation')
for token in ("branchchars=branchchars||'0123456789._/-*?'",
              'call tagmatch branchpattern, branchcandidate',
              r"if result\='MATCH' then iterate"):
 if token not in refs:
  raise SystemExit(f'M229 GITVREF pattern handling missing {token!r}')
fixture=(
 "parse arg pattern\ncommand='BRANCHES'\nspec=pattern\ndepth=''\nextra=''\n"
 "headref='refs/heads/feature/x'\nrefcount=6\n"
 "refname.1='refs/heads/z'\nrefname.2='refs/heads/2'\n"
 "refname.3='refs/heads/main'\nrefname.4='refs/heads/feature/x'\n"
 "refname.5='refs/heads/feature/a'\nrefname.6='refs/heads/topic/1'\n"
 +branch_block+
 "exit 99\nreadrefs:\n return 'OK'\n"+matcher)
Path(sys.argv[4]).write_text(fixture)
print('M229 BRANCH PATTERN DISPATCH GUARDS PASS 5')
PY
rexx -c "$tmp/validbranch.rexx" /dev/null
rexx -c "$tmp/branches.rexx" /dev/null
for name in main 'feature/*' 'topic/?' '*'; do
 rexx "$tmp/validbranch.rexx" "$name" PATTERN | grep -qx OK
done
for name in 'bad|name' 'bad#name' a//b a/ .hidden a..b main.lock \
            1234567890123456789012345; do
 if rexx "$tmp/validbranch.rexx" "$name" PATTERN | grep -qx OK; then
  echo "unsafe branch pattern accepted: $name" >&2
  exit 1
 fi
done
printf '  feature/a\n* feature/x\n' > "$tmp/expected"
rexx "$tmp/branches.rexx" 'feature/*' > "$tmp/actual"
cmp "$tmp/expected" "$tmp/actual"
printf '  topic/1\n' > "$tmp/expected"
rexx "$tmp/branches.rexx" 'topic/?' > "$tmp/actual"
cmp "$tmp/expected" "$tmp/actual"
if rexx "$tmp/branches.rexx" 'bad|name' > "$tmp/invalid"; then
 echo 'unsafe direct GITVREF branch pattern unexpectedly succeeded' >&2
 exit 1
else
 rc=$?
 [ "$rc" -eq 4 ]
fi
echo 'M229 SOURCE-DERIVED BRANCH PATTERN FIXTURES PASS 15'
)
exit $?
fi

# Create a branch at HEAD or a resolved branch/tag start point.
if [ "${1:-}" = "M230" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M229
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GIT.EXEC" "$tmp/createbranch.rexx" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
route=source[source.index("if command = 'BRANCH' then do"):
             source.index("/* M218: change symbolic HEAD")]
start=route.index("if brancharg1='' | brancharg3\\='' |")
block=route[start:]
command="address command 'EXEC GIT UPDATE-REF' branchref branchoid zeros"
if command not in block:
 raise SystemExit('M230 branch create did not preserve the CAS updater')
block=block.replace(command,
 "rc=0\nsay 'SIMULATED UPDATE-REF' branchref branchoid zeros")
vstart=source.index('validbranch: procedure')
vend=source.index('resolvetagtarget: procedure',vstart)
validator=source[vstart:vend]
fixture=(
 "parse arg brancharg1 brancharg2 brancharg3 brancharg4 brancharg5\n"
 "command='BRANCH'\nif command='BRANCH' then do\n"
 "zeros='0000000000000000000000000000000000000000'\n"+
 block+
 "exit 99\n"
 "resolvetagtarget: procedure\n parse arg wanted\n"
 " if wanted='HEAD' then return 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 " if wanted='main' then return 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'\n"
 " return 'ERROR'\n"+validator)
Path(sys.argv[2]).write_text(fixture)
if block.index("if branchstart='' then branchstart='HEAD'") > block.index(
        'call resolvetagtarget branchstart'):
 raise SystemExit('M230 resolves branch source before applying HEAD default')
if block.index('call validbranch brancharg1') > block.index(
        "branchref='refs/heads/'||brancharg1"):
 raise SystemExit('M230 builds branch ref before validating its name')
print('M230 BRANCH CREATE SOURCE GUARDS PASS 3')
PY
rexx -c "$tmp/createbranch.rexx" /dev/null
head=$(rexx "$tmp/createbranch.rexx" new)
echo "$head" | grep -q 'SIMULATED UPDATE-REF refs/heads/new AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
echo "$head" | grep -q 'BRANCH CREATED new AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
start=$(rexx "$tmp/createbranch.rexx" new main)
echo "$start" | grep -q 'SIMULATED UPDATE-REF refs/heads/new BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
for args in "bad|name" 'new missing' 'new main extra'; do
 if rexx "$tmp/createbranch.rexx" $args > "$tmp/rejected"; then
  echo "invalid branch create unexpectedly succeeded: $args" >&2
  exit 1
 else
  rc=$?
  [ "$rc" -eq 4 ]
 fi
 if grep -q 'SIMULATED UPDATE-REF' "$tmp/rejected"; then
  echo "invalid branch create reached updater: $args" >&2
  exit 1
 fi
done
echo 'M230 SOURCE-DERIVED BRANCH CREATE FIXTURES PASS 5'
)
exit $?
fi

# Alias safe checkout operations to the guarded modern switch implementation.
if [ "${1:-}" = "M231" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M230
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GIT.EXEC" "$tmp/checkout.rexx" \
 "$tmp/legacy.rexx" "$tmp/badrc.rexx" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
start=source.index("if command='CHECKOUT' then do")
end=source.index("if command = 'VERSION' then do",start)
block=source[start:end]
for token in ("if checkoutarg='-B' then do",
              "'STATE GITREF2 REPO A'", 'if checkoutrc=28 then do',
              "if checkoutarg='-b' | checkoutarg='--branch' then",
              "rest='-c'||substr(rest,length(checkoutarg)+1)",
              "command='SWITCH'"):
 if token not in block:
  raise SystemExit(f'M231 checkout alias missing {token!r}')
prefix='parse arg command rest\ncommand=translate(command)\n'
suffix='say command\nsay strip(rest)\n'
state="'STATE GITREF2 REPO A'"
if state not in block:
 raise SystemExit('M231 state probe missing')
for path, result in zip(sys.argv[2:], ('rc=0','rc=28','rc=8')):
 Path(path).write_text(prefix+block.replace(state,result)+suffix)
print('M231 CHECKOUT ALIAS SOURCE GUARDS PASS 6')
PY
rexx -c "$tmp/checkout.rexx" /dev/null
rexx -c "$tmp/legacy.rexx" /dev/null
rexx -c "$tmp/badrc.rexx" /dev/null
check() {
 script=$1
 expected=$2
 shift
 shift
 actual=$(rexx "$script" "$@")
 if [ "$actual" != "$expected" ]; then
  echo "checkout alias $*: expected $expected, got $actual" >&2
  exit 1
 fi
}
check "$tmp/checkout.rexx" "$(printf 'SWITCH\n-c topic main')" CHECKOUT -b topic main
check "$tmp/checkout.rexx" "$(printf 'SWITCH\n-c topic main')" CHECKOUT --branch topic main
check "$tmp/checkout.rexx" "$(printf 'SWITCH\ntopic')" CHECKOUT topic
check "$tmp/legacy.rexx" "$(printf 'CHECKOUT\ntopic')" CHECKOUT topic
if rexx "$tmp/legacy.rexx" CHECKOUT -b topic > "$tmp/legacy-create"; then
 echo 'checkout -b unexpectedly used legacy refs' >&2
 exit 1
else
 rc=$?
 [ "$rc" -eq 8 ]
fi
grep -q 'requires modern REF2' "$tmp/legacy-create"
if rexx "$tmp/badrc.rexx" CHECKOUT topic > "$tmp/badrc"; then
 echo 'checkout ignored REF2 probe error' >&2
 exit 1
else
 rc=$?
 [ "$rc" -eq 8 ]
fi
grep -q 'cannot inspect REF2 RC 8' "$tmp/badrc"
if rexx "$tmp/checkout.rexx" CHECKOUT -B topic > "$tmp/force"; then
 echo 'unsafe force checkout unexpectedly succeeded' >&2
 exit 1
else
 rc=$?
 [ "$rc" -eq 4 ]
fi
grep -q 'GIT CHECKOUT -B is not supported' "$tmp/force"
echo 'M231 SOURCE-DERIVED CHECKOUT FIXTURES PASS 7'
)
exit $?
fi

# Preserve legacy GITHEAD checkout when modern REF2 is absent.
if [ "${1:-}" = "M232" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M231
python3 - "$root/src/GIT.EXEC" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
start=source.index("if command='CHECKOUT' then do")
end=source.index('if command = \'VERSION\' then do',start)
block=source[start:end]
for token in ("'STATE GITREF2 REPO A'", 'checkoutrc=rc',
              'if checkoutrc=28 then do',
              "if checkoutarg='-b' | checkoutarg='--branch' then do",
              "say 'GIT CHECKOUT -b requires modern REF2'",
              "else if checkoutrc=0 then do", "command='SWITCH'"):
 if token not in block:
  raise SystemExit(f'M232 checkout fallback missing {token!r}')
legacy=block[block.index('if checkoutrc=28 then do'):
             block.index('else if checkoutrc=0 then do')]
if "command='SWITCH'" in legacy:
 raise SystemExit('M232 routes legacy checkout to modern REF2 updater')
if block.index("'STATE GITREF2 REPO A'") > block.index("command='SWITCH'"):
 raise SystemExit('M232 selects checkout implementation before checking REF2')
print('M232 LEGACY CHECKOUT FALLBACK GUARDS PASS 8')
PY
echo 'M232 SOURCE-DERIVED LEGACY CHECKOUT FALLBACK PASS 1'
)
exit $?
fi

# Resolve a tag's current OID before compare-and-swap deletion.
if [ "${1:-}" = "M233" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M232
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GIT.EXEC" "$tmp/deletetag.rexx" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
tag=source[source.index("if command = 'TAG' then do"):
           source.index('/* Prefer modern REF2 branches')]
start=tag.index("if verb='-D' | verb='--DELETE' then do")
end=tag.index("if action=''",start)
block=tag[start:end]
command="address command 'EXEC GIT UPDATE-REF' ref zeros expectedoid"
if command not in block:
 raise SystemExit('M233 tag deletion lost its CAS update')
if block.index('call resolvestart ref') > block.index(command):
 raise SystemExit('M233 submits deletion before resolving current tag OID')
block=block.replace(command,
 "rc=0\nsay 'SIMULATED UPDATE-REF' ref zeros expectedoid")
vstart=source.index('validtag: procedure')
vend=source.index('validbranch: procedure',vstart)
validator=source[vstart:vend]
fixture=(
 'parse arg action tagname oid extra fifth\n'
 'verb=translate(action)\n'
 "zeros='0000000000000000000000000000000000000000'\n"+
 block+
 "resolvestart: procedure\n parse arg wanted\n"
 " if wanted='refs/tags/v1' then return 'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'\n"
 " return 'ERROR'\n"+validator)
Path(sys.argv[2]).write_text(fixture)
for token in ("call resolvestart ref", 'expectedoid=result',
              "SIMULATED UPDATE-REF' ref zeros expectedoid"):
 if token not in block:
  raise SystemExit(f'M233 delete path missing {token!r}')
print('M233 TAG DELETE CAS SOURCE GUARDS PASS 4')
PY
rexx -c "$tmp/deletetag.rexx" /dev/null
check() {
 expected_rc=$1
 expected=$2
 shift 2
 if output=$(rexx "$tmp/deletetag.rexx" "$@"); then
  rc=0
 else
  rc=$?
 fi
 if [ "$rc" -ne "$expected_rc" ]; then
  echo "tag delete $*: expected RC $expected_rc, got $rc" >&2
  exit 1
 fi
 if [ "$output" != "$expected" ]; then
  echo "tag delete $*: expected '$expected', got '$output'" >&2
  exit 1
 fi
}
oid=CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
check 0 "$(printf 'SIMULATED UPDATE-REF refs/tags/v1 0000000000000000000000000000000000000000 %s\nTAG DELETED refs/tags/v1 %s' "$oid" "$oid")" -d v1
check 0 "$(printf 'SIMULATED UPDATE-REF refs/tags/v1 0000000000000000000000000000000000000000 %s\nTAG DELETED refs/tags/v1 %s' "$oid" "$oid")" --delete v1 "$oid"
check 8 'GIT: cannot resolve tag refs/tags/missing' -d missing
check 4 'GIT: invalid tag name' -d 'bad|name'
check 4 'GIT: invalid expected tag object-id' -d v1 nope
check 4 'Usage: GIT TAG -d|--delete name [expected-commit-oid]' -d v1 "$oid" extra
echo 'M233 SOURCE-DERIVED TAG DELETE FIXTURES PASS 6'
)
exit $?
fi

# Resolve a branch's current OID before compare-and-swap deletion.
if [ "${1:-}" = "M234" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M233
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GIT.EXEC" "$tmp/deletebranch.rexx" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
route=source[source.index("if command = 'BRANCH' then do"):
             source.index("/* M218: change symbolic HEAD")]
start=route.index("if verb='-D' | verb='--DELETE' then do")
end=route.index("if brancharg1='' | brancharg3",start)
block=route[start:end]
command="address command 'EXEC GIT UPDATE-REF' branchref zeros branchoid"
if command not in block:
 raise SystemExit('M234 branch deletion lost its CAS update')
if block.index('call resolvestart branchref') > block.index(command):
 raise SystemExit('M234 submits deletion before resolving current branch OID')
block=block.replace(command,
 "rc=0\nsay 'SIMULATED UPDATE-REF' branchref zeros branchoid")
vstart=source.index('validbranch: procedure')
vend=source.index('resolvetagtarget: procedure',vstart)
validator=source[vstart:vend]
fixture=(
 "parse arg brancharg1 brancharg2 brancharg3 brancharg4 brancharg5\n"
 "verb=translate(brancharg1)\n"
 "zeros='0000000000000000000000000000000000000000'\n"+
 block+
 "resolvestart: procedure\n parse arg wanted\n"
 " if wanted='refs/heads/main' then return 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'\n"
 " return 'ERROR'\n"+validator)
Path(sys.argv[2]).write_text(fixture)
for token in ('call resolvestart branchref', 'branchoid=result',
              "verify(branchoid,'0123456789ABCDEF')",
              "SIMULATED UPDATE-REF' branchref zeros branchoid"):
 if token not in block:
  raise SystemExit(f'M234 delete path missing {token!r}')
print('M234 BRANCH DELETE CAS SOURCE GUARDS PASS 4')
PY
rexx -c "$tmp/deletebranch.rexx" /dev/null
check() {
 expected_rc=$1
 expected=$2
 shift 2
 if output=$(rexx "$tmp/deletebranch.rexx" "$@"); then
  rc=0
 else
  rc=$?
 fi
 if [ "$rc" -ne "$expected_rc" ]; then
  echo "branch delete $*: expected RC $expected_rc, got $rc" >&2
  exit 1
 fi
 if [ "$output" != "$expected" ]; then
  echo "branch delete $*: expected '$expected', got '$output'" >&2
  exit 1
 fi
}
oid=BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
check 0 "$(printf 'SIMULATED UPDATE-REF refs/heads/main 0000000000000000000000000000000000000000 %s\nBRANCH DELETED main %s' "$oid" "$oid")" -d main
check 0 "$(printf 'SIMULATED UPDATE-REF refs/heads/main 0000000000000000000000000000000000000000 %s\nBRANCH DELETED main %s' "$oid" "$oid")" --delete main "$oid"
check 8 'GIT: cannot resolve branch refs/heads/missing' -d missing
check 4 'GIT: invalid branch name' -d 'bad|name'
check 4 'GIT: invalid expected branch object-id' -d main nope
check 4 'Usage: GIT BRANCH -d|--delete name [expected-old-oid]' -d main "$oid" extra
echo 'M234 SOURCE-DERIVED BRANCH DELETE FIXTURES PASS 6'
)
exit $?
fi

# Expose bounded verified history through the common GIT LOG command.
if [ "${1:-}" = "M235" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M234
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GIT.EXEC" "$tmp/log.rexx" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
start=source.index("if command = 'LOG' then do")
end=source.index("/* Prefer modern REF2 branches",start)
block=source[start:end]
command="address command 'EXEC GITVREF LOG' logoid backenddepth"
resolver='call resolvetagtarget logstart'
if command not in block or resolver not in block:
 raise SystemExit('M235 LOG router lost its resolver/backend')
if block.index(resolver) > block.index(command):
 raise SystemExit('M235 sends LOG before resolving the revision')
block=block.replace(resolver,
 "if logstart='HEAD' then result='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "else if logstart='main' then result='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'\n"
 "else result='ERROR'")
block=block.replace(command,
 "rc=0\nsay 'SIMULATED LOG' logoid backenddepth")
Path(sys.argv[2]).write_text("parse arg rest\ncommand='LOG'\n"+block)
for token in ("logdepth='16'", "call resolvetagtarget logstart",
              "verify(logdepth,'0123456789')",
              'logdepth+0>16', 'if logdepth+0=0 then exit 0',
              'backenddepth=logdepth-1', command):
 if token not in source[start:end]:
  raise SystemExit(f'M235 LOG route missing {token!r}')
print('M235 LOG ROUTE SOURCE GUARDS PASS 5')
PY
rexx -c "$tmp/log.rexx" /dev/null
check() {
 expected_rc=$1
 expected=$2
 shift 2
 if output=$(rexx "$tmp/log.rexx" "$@"); then
  rc=0
 else
  rc=$?
 fi
 if [ "$rc" -ne "$expected_rc" ]; then
  echo "GIT LOG $*: expected RC $expected_rc, got $rc" >&2
  exit 1
 fi
 if [ "$output" != "$expected" ]; then
  echo "GIT LOG $*: expected '$expected', got '$output'" >&2
  exit 1
 fi
}
check 0 'SIMULATED LOG AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 15'
check 0 'SIMULATED LOG BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB 15' main
check 0 'SIMULATED LOG AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 4' --max-count 5
check 0 'SIMULATED LOG BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB 2' -n 3 main
check 0 'SIMULATED LOG BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB 6' --max-count=7 main
check 0 'SIMULATED LOG BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB 4' -n5 main
check 0 '' --max-count 0
check 0 '' --max-count=0 main
check 0 'SIMULATED LOG BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB 0' -n 1 main
check 0 'SIMULATED LOG AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 15' --max-count 16
check 4 'GIT: log count must be between 0 and 16' --max-count=17
check 4 'GIT: log count must be between 0 and 16' -n nope
check 8 'GIT: cannot resolve log revision missing' missing
check 4 'Usage: GIT LOG [-n|--max-count count] [revision]' --max-count 5 main extra
check 4 'Usage: GIT LOG [-n|--max-count count] [revision]' main extra
echo 'M235 SOURCE-DERIVED GIT LOG FIXTURES PASS 15'
)
exit $?
fi

if [ "${1:-}" = "M237" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M235
python3 - "$root/src/GITREC.C" <<'PY'
from pathlib import Path
import sys
source=Path(sys.argv[1]).read_text()
start=source.index('static int rec_logfull(')
end=source.index('\nstatic int ',start+1)
routine=source[start:end]
required=('for(hop=0;hop<=depth;hop++)',
          'for(j=0;j<=depth;j++)',
          'printf("LOG NODES %u\\n",depth+1);')
for token in required:
 if token not in routine:
  raise SystemExit(f'M237 GITREC depth semantics missing {token!r}')
print('M237 GITREC INCLUSIVE DEPTH SOURCE GUARDS PASS 3')
PY
echo 'M237 EXACT MAX-COUNT SEMANTICS PASS'
)
exit $?
fi

# Expose the verified full-object reader through GIT SHOW.
if [ "${1:-}" = "M236" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M235
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GIT.EXEC" "$tmp/show.rexx" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
start=source.index("if command = 'SHOW' then do")
end=source.index("/* Prefer modern REF2 branches",start)
block=source[start:end]
resolver='call resolvetagtarget showstart'
command="address command 'EXEC GITVREF SHOW' showoid"
if resolver not in block or command not in block:
 raise SystemExit('M236 SHOW router lost its resolver/backend')
if block.index(resolver)>block.index(command):
 raise SystemExit('M236 sends SHOW before resolving the revision')
block=block.replace(resolver,
 "if showstart='HEAD' then result='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "else if showstart='main' then result='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'\n"
 "else if length(showstart)=40 then result=translate(showstart)\n"
 "else result='ERROR'")
block=block.replace(command,"rc=0\nsay 'SIMULATED SHOW' showoid")
Path(sys.argv[2]).write_text("parse arg rest\ncommand='SHOW'\n"+block)
for token in ('showstart=\'HEAD\'', resolver,
              "Usage: GIT SHOW [revision]", command):
 if token not in source[start:end]:
  raise SystemExit(f'M236 SHOW route missing {token!r}')
print('M236 SHOW ROUTE SOURCE GUARDS PASS 4')
PY
rexx -c "$tmp/show.rexx" /dev/null
check() {
 expected_rc=$1
 expected=$2
 shift 2
 if output=$(rexx "$tmp/show.rexx" "$@"); then
  rc=0
 else
  rc=$?
 fi
 if [ "$rc" -ne "$expected_rc" ]; then
  echo "GIT SHOW $*: expected RC $expected_rc, got $rc" >&2
  exit 1
 fi
 if [ "$output" != "$expected" ]; then
  echo "GIT SHOW $*: expected '$expected', got '$output'" >&2
  exit 1
 fi
}
check 0 'SIMULATED SHOW AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
check 0 'SIMULATED SHOW BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB' main
oid=CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
check 0 "SIMULATED SHOW $oid" "$oid"
check 8 'GIT: cannot resolve show revision missing' missing
check 8 'GIT: cannot resolve show revision bad|name' 'bad|name'
check 4 'Usage: GIT SHOW [revision]' main extra
echo 'M236 SOURCE-DERIVED GIT SHOW FIXTURES PASS 6'
)
exit $?
fi

# Resolve an existing tag before compare-and-swap force update.
if [ "${1:-}" = "M238" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M237
sh "$0" M236
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GIT.EXEC" "$tmp/forcetag.rexx" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
tag=source[source.index("if command = 'TAG' then do"):
           source.index('/* Bounded porcelain LOG')]
start=tag.index("if verb='-F' | verb='--FORCE' then do")
end=tag.index("if verb='-D' | verb='--DELETE' then do",start)
block=tag[start:end]
resolver='call resolvestart ref'
verify="address command 'EXEC GIT VERIFY-OBJECT' newoid"
update="address command 'EXEC GIT UPDATE-REF' ref newoid oldoid"
readobj='call readobject newoid'
for command in (resolver,verify,readobj,update):
 if command not in block:
  raise SystemExit(f'M238 force-tag path missing {command!r}')
if not (block.index(resolver)<block.index(verify)<block.index(readobj)<block.index(update)):
 raise SystemExit('M238 force-tag path violates resolution/verification/CAS order')
block=block.replace(verify,'rc=0')
block=block.replace(readobj,"result='OK'\nobjtype='COMMIT'")
block=block.replace(update,
 "rc=0\nsay 'SIMULATED UPDATE-REF' ref newoid oldoid")
vstart=source.index('validtag: procedure')
vend=source.index('validbranch: procedure',vstart)
validator=source[vstart:vend]
fixture=(
 "parse arg action tagname oid extra fifth\n"
 "verb=translate(action)\n"+block+
 "resolvestart: procedure\n parse arg wanted\n"
 " if wanted='refs/tags/v1' then return 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'\n"
 " return 'ERROR'\n"+validator)
Path(sys.argv[2]).write_text(fixture)
for token in (resolver, "oldoid=result",
              "verify(newoid,'0123456789ABCDEF')",
              'oldoid=translate(extra)',
              "SIMULATED UPDATE-REF' ref newoid oldoid"):
 if token not in block:
  raise SystemExit(f'M238 force-tag source guard missing {token!r}')
print('M238 TAG FORCE UPDATE SOURCE GUARDS PASS 5')
PY
rexx -c "$tmp/forcetag.rexx" /dev/null
check() {
 expected_rc=$1
 expected=$2
 shift 2
 if output=$(rexx "$tmp/forcetag.rexx" "$@"); then
  rc=0
 else
  rc=$?
 fi
 if [ "$rc" -ne "$expected_rc" ]; then
  echo "tag force update $*: expected RC $expected_rc, got $rc" >&2
  exit 1
 fi
 if [ "$output" != "$expected" ]; then
  echo "tag force update $*: expected '$expected', got '$output'" >&2
  exit 1
 fi
}
new=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
old=BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
zeros=0000000000000000000000000000000000000000
check 0 "$(printf 'SIMULATED UPDATE-REF refs/tags/v1 %s %s\nTAG UPDATED refs/tags/v1 %s %s' "$new" "$old" "$old" "$new")" -f v1 "$new"
check 0 "$(printf 'SIMULATED UPDATE-REF refs/tags/v1 %s %s\nTAG UPDATED refs/tags/v1 %s %s' "$new" "$old" "$old" "$new")" --force v1 "$new" "$old"
check 8 'GIT: cannot resolve existing tag refs/tags/missing' -f missing "$new"
check 4 'GIT: invalid new tag object-id' -f v1 nope
check 4 'GIT: invalid expected tag object-id' -f v1 "$new" nope
check 4 'GIT: force update requires an existing tag OID' -f v1 "$new" "$zeros"
check 4 'GIT: invalid tag name' -f 'bad|name' "$new"
check 4 'Usage: GIT TAG -f|--force name new-oid [expected-old-oid]' --force v1 "$new" "$old" extra
echo 'M238 SOURCE-DERIVED TAG FORCE UPDATE FIXTURES PASS 8'
)
exit $?
fi

# Stage multiple explicitly named mapped CMS workfiles in one map update.
if [ "${1:-}" = "M239" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M238
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GITWT.EXEC" "$tmp/add.rexx" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
start=source.index("if command='ADD' then do")
end=source.index("if command='ACCEPT' then do",start)
block=source[start:end]
block=block[block.index(' addall=0'):]
state="'STATE' mapfn.pi mapft.pi mapfm.pi"
work="call workoid mapfn.pi,mapft.pi,mapfm.pi,maplf.pi,1"
for token in ('if word(rest,1)=\'--\' then do', 'call toasciihex path',
              'call findpath pathhex',state,work,
              'mapstage.pi=addoid.ai','call savemap',"say 'ADDED'"):
 if token not in block:
  raise SystemExit(f'M239 multi-add block missing {token!r}')
if not (block.index('call toasciihex path')<block.index('call findpath pathhex')<
        block.index(state)<block.index(work)<block.index('mapstage.pi=addoid.ai')<
        block.index('call savemap')<block.index("say 'ADDED'")):
 raise SystemExit('M239 add preflight/save/output order changed')
if block.index("if word(rest,1)='--' then do") > block.index('path=word(rest,ai)'):
 raise SystemExit('M241 option separator is not consumed before path validation')
block=block.replace('call loadmap',"result='OK'")
block=block.replace(state,
 "if mapfn.pi='STATEFAIL' then rc=12\nelse rc=0")
block=block.replace(work,
 "if mapfn.pi='HASHFAIL' then result='ERROR'\n"
 "else if pi=1 then result='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "else result='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'")
block=block.replace('call savemap',"result='OK'\nsay 'SIMULATED SAVE'")
fstart=source.index('\nfindpath:\n')+1
fend=source.index('\nfindfile:\n',fstart)
findpath=source[fstart:fend]
fixture=(
 "parse arg rest\ncommand='ADD'\nmapcount=5\n"
 "if command='ADD' then do\n"
 "mapfn.1='ALPHA'\nmapfn.2='BETA'\n"
 "mapfn.3='STATEFAIL'\nmapfn.4='HASHFAIL'\nmapfn.5='DASH'\n"
 "do mi=1 to 5\n mapft.mi='DATA'\n mapfm.mi='A'\n"
 " maplf.mi=1\n mapbase.mi='0000000000000000000000000000000000000000'\n"
 " mapstage.mi=mapbase.mi\nend\n"
 "mappath.1='616C706861'\nmappath.2='62657461'\n"
 "mappath.3='67616D6D61'\nmappath.4='64656C7461'\n"
 "mappath.5='2D64617368'\n"+
 block+findpath+
 "toasciihex:\n parse arg text\n return c2x(text)\n")
Path(sys.argv[2]).write_text(fixture)
print('M239 MULTI-ADD SOURCE GUARDS PASS 8')
PY
rexx -c "$tmp/add.rexx" /dev/null
check() {
 expected_rc=$1
 expected=$2
 shift 2
 if output=$(rexx "$tmp/add.rexx" "$@"); then
  rc=0
 else
  rc=$?
 fi
 if [ "$rc" -ne "$expected_rc" ]; then
  echo "GIT ADD $*: expected RC $expected_rc, got $rc" >&2
  exit 1
 fi
 if [ "$output" != "$expected" ]; then
  echo "GIT ADD $*: expected '$expected', got '$output'" >&2
  exit 1
 fi
}
alpha=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
beta=BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
check 0 "$(printf 'SIMULATED SAVE\nADDED alpha %s\nSTAGE DIFFERS FROM BASE' "$alpha")" alpha
check 0 "$(printf 'SIMULATED SAVE\nADDED alpha %s\nSTAGE DIFFERS FROM BASE\nADDED beta %s\nSTAGE DIFFERS FROM BASE' "$alpha" "$beta")" alpha beta
check 0 "$(printf 'SIMULATED SAVE\nADDED alpha %s\nSTAGE DIFFERS FROM BASE\nADDED beta %s\nSTAGE DIFFERS FROM BASE' "$alpha" "$beta")" -- alpha beta
check 0 "$(printf 'SIMULATED SAVE\nADDED -dash %s\nSTAGE DIFFERS FROM BASE' "$beta")" -- -dash
check 0 "$(printf 'SIMULATED SAVE\nADDED alpha %s\nSTAGE DIFFERS FROM BASE' "$alpha")" alpha alpha
check 4 'GITWT: path is not checked out unknown' unknown
check 4 'GITWT: path is not checked out bad|path' 'bad|path'
check 4 'GITWT: invalid path abcdefghijklmnopqrstuvwxyzabcde1' abcdefghijklmnopqrstuvwxyzabcde1
check 8 'GITWT: cannot inspect mapped CMS file gamma' gamma
check 8 '' delta
many='a a a a a a a a a a a a a a a a a'
check 4 'Usage: GIT ADD path [path ...] (maximum 16 paths)' $many
check 4 'Usage: GIT ADD path [path ...] (maximum 16 paths)' --
check 4 'Usage: GIT ADD path [path ...] (maximum 16 paths)' -- $many
echo 'M239 SOURCE-DERIVED MULTI-PATH ADD FIXTURES PASS 13'
)
exit $?
fi

if [ "${1:-}" = "M241" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M239
grep -Fq "if word(rest,1)='--' then do" "$root/src/GITWT.EXEC"
echo 'M241 GIT ADD OPTION SEPARATOR PASS'
)
exit $?
fi

if [ "${1:-}" = "M242" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M241
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GITWT.EXEC" "$tmp/update.rexx" "$tmp/missing.rexx" "$tmp/hashfail.rexx" "$tmp/empty.rexx" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
start=source.index("if command='ADD' then do")
end=source.index("if command='ACCEPT' then do",start)
block=source[start:end]
block=block[block.index(' addall=0'):]
required=("translate(word(rest,1))='-U'",
          "translate(word(rest,1))='--UPDATE'",
          'if addall=1 then do', 'do ai=1 to mapcount',
          'call asciitocms mappath.ai', "say 'GITWT: no mapped paths to update'",
          'call savemap')
for token in required:
 if token not in block:
  raise SystemExit(f'M242 ADD update source guard missing {token!r}')
if not (block.index("translate(word(rest,1))='-U'")<
        block.index('if addall=0 & (addrequested<1')<
        block.index('call loadmap')<block.index('do ai=1 to addcount')<
        block.index('call savemap')):
 raise SystemExit('M242 ADD update validation or save ordering changed')
state="if mapfn.pi='MISSING' then rc=28\nelse rc=0"
work=("if pi=1 then result='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
      "else result='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'")
hashfailwork=("if pi=1 then result='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
              "else result='ERROR'")
fixture=(
 "parse arg rest\ncommand='ADD'\nmapcount=2\n"
 "if command='ADD' then do\n"
 "mapfn.1='ALPHA'\nmapfn.2='BETA'\n"
 "do mi=1 to 2\n mapft.mi='DATA'\n mapfm.mi='A'\n"
 " maplf.mi=1\n mapbase.mi='0000000000000000000000000000000000000000'\n"
 " mapstage.mi=mapbase.mi\nend\n"
 "mappath.1='616C706861'\nmappath.2='62657461'\n"+
 block.replace('call loadmap',"result='OK'")
      .replace("'STATE' mapfn.pi mapft.pi mapfm.pi",state)
      .replace('call workoid mapfn.pi,mapft.pi,mapfm.pi,maplf.pi,1',work)
      .replace('call savemap',"result='OK'\nsay 'SIMULATED SAVE'")+
 "asciitocms:\n parse arg text\n return x2c(text)\n")
Path(sys.argv[2]).write_text(fixture)
missing=fixture.replace("mapfn.2='BETA'", "mapfn.2='MISSING'")
missing=missing.replace("mappath.1='616C706861'", "mapbase.2='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\nmapstage.2=mapbase.2\nmappath.1='616C706861'")
Path(sys.argv[3]).write_text(missing)
Path(sys.argv[4]).write_text(fixture.replace(work,hashfailwork))
Path(sys.argv[5]).write_text(fixture.replace('mapcount=2','mapcount=0'))
print('M242 GIT ADD UPDATE SOURCE GUARDS PASS 7')
PY
rexx -c "$tmp/update.rexx" /dev/null
check() {
 fixture=$1
 expected_rc=$2
 expected=$3
 shift 3
 if output=$(rexx "$fixture" "$@"); then rc=0; else rc=$?; fi
 if [ "$rc" -ne "$expected_rc" ]; then
  echo "GIT ADD update $*: expected RC $expected_rc, got $rc" >&2
  exit 1
 fi
 if [ "$output" != "$expected" ]; then
  echo "GIT ADD update $*: expected '$expected', got '$output'" >&2
  exit 1
 fi
}
alpha=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
beta=BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
expected=$(printf 'SIMULATED SAVE\nADDED alpha %s\nSTAGE DIFFERS FROM BASE\nADDED beta %s\nSTAGE DIFFERS FROM BASE' "$alpha" "$beta")
check "$tmp/update.rexx" 0 "$expected" -u
check "$tmp/update.rexx" 0 "$expected" --update
expected_missing=$(printf 'SIMULATED SAVE\nADDED alpha %s\nSTAGE DIFFERS FROM BASE\nSTAGED DELETION beta' "$alpha")
check "$tmp/missing.rexx" 0 "$expected_missing" -u
check "$tmp/hashfail.rexx" 8 '' -u
check "$tmp/empty.rexx" 0 'GITWT: no mapped paths to update' -u
check "$tmp/update.rexx" 4 'Usage: GIT ADD [-u|--update] | [--] path [path ...]' -u alpha
echo 'M242 SOURCE-DERIVED GIT ADD UPDATE FIXTURES PASS 6'
)
exit $?
fi

if [ "${1:-}" = "M243" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M242
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GITWT.EXEC" "$tmp/status.rexx" "$tmp/empty.rexx" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
start=source.index("if command='STATUS' then do")
end=source.index('/* Read-only preflight for a branch switch',start)
block=source[start:end]
required=("statusopt=translate(word(rest,si))", "statusopt='--SHORT'",
          "statusopt='--PORCELAIN'", "statusopt='--BRANCH'",
          "if mapbase.i=zeros then x='A'", "if state='DELETED' then y='D'",
          "if state='MODIFIED' | state='STAGED+MODIFIED' then y='M'",
          "if x\\=' ' | y\\=' ' then say x||y||' '||p",
          "if shortstatus=0 then say 'STATUS SUMMARY TRACKED'")
for token in required:
 if token not in block:
  raise SystemExit(f'M243 short status source guard missing {token!r}')
state="if mapfn.i='GONE' | mapfn.i='ADDGONE' then rc=28\nelse rc=0"
work=("if mapfn.i='CLEAN' | mapfn.i='ADD' then\n"
      " result='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
      "else if mapfn.i='STAGED' | mapfn.i='MODIFIED' then\n"
      " result='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'\n"
      "else if mapfn.i='BOTH' then\n"
      " result='CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'\n"
      "else result='ERROR'")
fixture=(
 "parse arg rest\ncommand='STATUS'\nmapcount=7\n"
 "mapfn.1='CLEAN'\nmapfn.2='STAGED'\nmapfn.3='MODIFIED'\n"
 "mapfn.4='BOTH'\nmapfn.5='GONE'\nmapfn.6='ADD'\n"
 "mapfn.7='ADDGONE'\n"
 "do mi=1 to 7\n mapft.mi='DATA'\n mapfm.mi='A'\n maplf.mi=1\nend\n"
 "mapbase.1='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mapstage.1='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mapbase.2='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mapstage.2='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'\n"
 "mapbase.3='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mapstage.3='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mapbase.4='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mapstage.4='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'\n"
 "mapbase.5='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mapstage.5='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mapbase.6='0000000000000000000000000000000000000000'\n"
 "mapstage.6='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mapbase.7='0000000000000000000000000000000000000000'\n"
 "mapstage.7='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mappath.1='636C65616E'\nmappath.2='737461676564'\n"
 "mappath.3='6D6F646966696564'\nmappath.4='626F7468'\n"
 "mappath.5='676F6E65'\nmappath.6='6164646564'\n"
 "mappath.7='616464676F6E65'\n"+
 block.replace('call loadmap',"result='OK'")
      .replace("'STATE' mapfn.i mapft.i mapfm.i",state)
      .replace('call workoid mapfn.i,mapft.i,mapfm.i,maplf.i,0',work)+
 "asciitocms:\n parse arg text\n return x2c(text)\n")
Path(sys.argv[2]).write_text(fixture)
Path(sys.argv[3]).write_text(fixture.replace('mapcount=7','mapcount=0'))
print('M243 SHORT STATUS SOURCE GUARDS PASS 8')
PY
rexx -c "$tmp/status.rexx" /dev/null
check() {
 fixture=$1
 expected_rc=$2
 expected=$3
 shift 3
 if output=$(rexx "$fixture" "$@"); then rc=0; else rc=$?; fi
 if [ "$rc" -ne "$expected_rc" ]; then
  echo "GIT STATUS $*: expected RC $expected_rc, got $rc" >&2
  exit 1
 fi
 if [ "$output" != "$expected" ]; then
  echo "GIT STATUS $*: expected '$expected', got '$output'" >&2
  exit 1
 fi
}
expected=$(printf 'M  staged\n M modified\nMM both\n D gone\nA  added\nAD addgone')
check "$tmp/status.rexx" 0 "$expected" --short
check "$tmp/status.rexx" 0 "$expected" --porcelain
check "$tmp/empty.rexx" 0 '' --short
check "$tmp/status.rexx" 4 'Usage: GIT STATUS [--short|--porcelain] [--branch]' --unknown
echo 'M243 SOURCE-DERIVED SHORT STATUS FIXTURES PASS 4'
)
exit $?
fi

if [ "${1:-}" = "M244" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M243
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GIT.EXEC" "$root/src/GITWT.EXEC" "$tmp/diff.rexx" "$tmp/empty.rexx" <<'PY'
from pathlib import Path
import sys

router=Path(sys.argv[1]).read_text()
if "if command = 'DIFF' then do\n   'EXEC GITWT DIFF' rest\n   exit rc\nend" not in router:
 raise SystemExit('M244 GIT DIFF porcelain route missing')
source=Path(sys.argv[2]).read_text()
start=source.index("if command='DIFF' then do")
end=source.index('/* Read-only preflight for a branch switch',start)
block=source[start:end]
required=("diffarg1='--CACHED'", "diffarg1='--STAGED'",
          r"diffarg1\='--NAME-ONLY'", 'if mapstage.i\\=mapbase.i then changed=1',
          "'STATE' mapfn.i mapft.i mapfm.i", 'if work\\=mapstage.i then changed=1',
          'if changed=1 then do', 'say path')
for token in required:
 if token not in block:
  raise SystemExit(f'M244 diff source guard missing {token!r}')
state="if mapfn.i='GONE' | mapfn.i='ADDGONE' then rc=28\nelse rc=0"
work=("if mapfn.i='CLEAN' | mapfn.i='ADD' then\n"
      " result='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
      "else if mapfn.i='STAGED' | mapfn.i='MODIFIED' then\n"
      " result='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'\n"
      "else if mapfn.i='BOTH' then\n"
      " result='CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'\n"
      "else result='ERROR'")
fixture=(
 "parse arg rest\ncommand='DIFF'\nmapcount=7\n"
 "mapfn.1='CLEAN'\nmapfn.2='STAGED'\nmapfn.3='MODIFIED'\n"
 "mapfn.4='BOTH'\nmapfn.5='GONE'\nmapfn.6='ADD'\n"
 "mapfn.7='ADDGONE'\n"
 "do mi=1 to 7\n mapft.mi='DATA'\n mapfm.mi='A'\n maplf.mi=1\nend\n"
 "mapbase.1='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mapstage.1='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mapbase.2='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mapstage.2='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'\n"
 "mapbase.3='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mapstage.3='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mapbase.4='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mapstage.4='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'\n"
 "mapbase.5='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mapstage.5='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mapbase.6='0000000000000000000000000000000000000000'\n"
 "mapstage.6='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mapbase.7='0000000000000000000000000000000000000000'\n"
 "mapstage.7='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mappath.1='636C65616E'\nmappath.2='737461676564'\n"
 "mappath.3='6D6F646966696564'\nmappath.4='626F7468'\n"
 "mappath.5='676F6E65'\nmappath.6='6164646564'\n"
 "mappath.7='616464676F6E65'\n"+
 block.replace('call loadmap',"result='OK'")
      .replace("'STATE' mapfn.i mapft.i mapfm.i",state)
      .replace('call workoid mapfn.i,mapft.i,mapfm.i,maplf.i,0',work)+
 "asciitocms:\n parse arg text\n return x2c(text)\n")
Path(sys.argv[3]).write_text(fixture)
Path(sys.argv[4]).write_text(fixture.replace('mapcount=7','mapcount=0'))
print('M244 DIFF SOURCE GUARDS PASS 8')
PY
rexx -c "$tmp/diff.rexx" /dev/null
check() {
 fixture=$1
 expected_rc=$2
 expected=$3
 shift 3
 if output=$(rexx "$fixture" "$@"); then rc=0; else rc=$?; fi
 if [ "$rc" -ne "$expected_rc" ]; then
  echo "GIT DIFF $*: expected RC $expected_rc, got $rc" >&2
  exit 1
 fi
 if [ "$output" != "$expected" ]; then
  echo "GIT DIFF $*: expected '$expected', got '$output'" >&2
  exit 1
 fi
}
cached=$(printf 'staged\nboth\nadded\naddgone')
unstaged=$(printf 'modified\nboth\ngone\naddgone')
check "$tmp/diff.rexx" 0 "$cached" --cached --name-only
check "$tmp/diff.rexx" 0 "$cached" --staged --name-only
check "$tmp/diff.rexx" 0 "$unstaged" --name-only
check "$tmp/empty.rexx" 0 '' --name-only
check "$tmp/diff.rexx" 4 'Usage: GIT DIFF [--cached|--staged] --name-only' --cached
check "$tmp/diff.rexx" 4 'Usage: GIT DIFF [--cached|--staged] --name-only' --name-only extra
echo 'M244 SOURCE-DERIVED GIT DIFF NAME-ONLY FIXTURES PASS 6'
)
exit $?
fi

if [ "${1:-}" = "M245" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M244
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GIT.EXEC" "$root/src/GITWT.EXEC" "$tmp/reset.rexx" <<'PY'
from pathlib import Path
import sys

router=Path(sys.argv[1]).read_text()
if "if command = 'RESET' then do\n   'EXEC GITWT RESET' rest\n   exit rc\nend" not in router:
 raise SystemExit('M245 GIT RESET route missing')
source=Path(sys.argv[2]).read_text()
start=source.index("if command='RESET' then do")
end=source.index("if command='ACCEPT' then do",start)
block=source[start:end]
required=('resetrequested=words(rest)', "if word(rest,1)='--' then do",
          'call toasciihex path','call findpath pathhex',
          'resetold.resetcount=mapstage.pi',
          'mapstage.pi=mapbase.pi','call savemap',"say 'UNSTAGED'")
for token in required:
 if token not in block:
  raise SystemExit(f'M245 reset source guard missing {token!r}')
if not (block.index('call findpath pathhex')<block.index('mapstage.pi=mapbase.pi')<
        block.index('call savemap')<block.index("say 'UNSTAGED'")):
 raise SystemExit('M245 RESET mutates before validating all paths or reports early')
state="'STATE' mapfn.pi mapft.pi mapfm.pi"
work="call workoid mapfn.pi,mapft.pi,mapfm.pi,maplf.pi,1"
block=block.replace('call loadmap',"result='OK'")
block=block.replace('call savemap',"result='OK'\nsay 'SIMULATED SAVE'")
fixture=(
 "parse arg rest\ncommand='RESET'\nmapcount=4\n"
 "mapfn.1='ALPHA'\nmapfn.2='BETA'\n"
 "mapfn.3='STATEFAIL'\nmapfn.4='HASHFAIL'\n"
 "do mi=1 to 4\n mapft.mi='DATA'\n mapfm.mi='A'\n"
 " maplf.mi=1\n mapbase.mi='0000000000000000000000000000000000000000'\n"
 " mapstage.mi='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\nend\n"
 "mappath.1='616C706861'\nmappath.2='62657461'\n"
 "mappath.3='67616D6D61'\nmappath.4='64656C7461'\n"+
 block)
fstart=source.index('\nfindpath:\n')+1
fend=source.index('\nfindfile:\n',fstart)
fixture+=source[fstart:fend]+"toasciihex:\n parse arg text\n return c2x(text)\n"
Path(sys.argv[3]).write_text(fixture)
print('M245 GIT RESET SOURCE GUARDS PASS 8')
PY
rexx -c "$tmp/reset.rexx" /dev/null
check() {
 expected_rc=$1
 expected=$2
 shift 2
 if output=$(rexx "$tmp/reset.rexx" "$@"); then rc=0; else rc=$?; fi
 if [ "$rc" -ne "$expected_rc" ]; then
  echo "GIT RESET $*: expected RC $expected_rc, got $rc" >&2
  exit 1
 fi
 if [ "$output" != "$expected" ]; then
  echo "GIT RESET $*: expected '$expected', got '$output'" >&2
  exit 1
 fi
}
check 0 "$(printf 'SIMULATED SAVE\nUNSTAGED alpha\nUNSTAGED beta')" alpha beta
check 0 "$(printf 'SIMULATED SAVE\nUNSTAGED alpha')" alpha alpha
check 0 "$(printf 'SIMULATED SAVE\nUNSTAGED alpha\nUNSTAGED beta')" -- alpha beta
check 4 'GITWT: path is not checked out unknown' alpha unknown
check 4 'Usage: GIT RESET [--] path [path ...] (maximum 16 paths)' --
many='a a a a a a a a a a a a a a a a a'
check 4 'Usage: GIT RESET [--] path [path ...] (maximum 16 paths)' $many
echo 'M245 SOURCE-DERIVED GIT RESET FIXTURES PASS 6'
)
exit $?
fi

if [ "${1:-}" = "M251" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M250
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GIT.EXEC" "$root/src/GITWT.EXEC" "$tmp/router.rexx" "$tmp/parser.rexx" <<'PY'
from pathlib import Path
import sys

git=Path(sys.argv[1]).read_text()
start=git.index("if command = 'COMMIT' then do")
end=git.index("if command = 'COMMIT-STAGED-REF' then do",start)
route=git[start:end]
if "'EXEC GIT COMMIT-CURRENT' rest" not in route:
 raise SystemExit('M251 GIT COMMIT current-branch route missing')
route=route.replace("'EXEC GIT COMMIT-CURRENT' rest",
                    "say 'SIMULATED CURRENT' rest")
Path(sys.argv[3]).write_text(
 "parse arg command rest\ncommand=translate(command)\n"+route)
wt=Path(sys.argv[2]).read_text()
start=wt.index("if command='COMMIT' then do")
end=wt.index("say 'GITWT COMMIT LEVEL M165'",start)
parser=wt[start:end]
for token in ("opt='-M' | opt='--MESSAGE'", 'wordindex(rest,ci+1)',
              "message=substr(message,2,length(message)-2)",
              "if stamp='' | zone='' | message='' then do"):
 if token not in parser:
  raise SystemExit(f'M251 commit message parser guard missing {token!r}')
parser=parser[parser.index(" stamp=''"):]
parser=parser.replace("say 'Usage: GIT COMMIT-STAGED -T seconds -Z zone -M message'",
                      "say 'Usage: GIT COMMIT -T seconds -Z zone -m message'")
Path(sys.argv[4]).write_text(
 "parse arg rest\ncommand='COMMIT'\n"+parser+
 "say 'STAMP' stamp 'ZONE' zone 'MESSAGE' message\nexit 0\n")
print('M251 COMMIT ROUTE/MESSAGE SOURCE GUARDS PASS 5')
PY
rexx -c "$tmp/router.rexx" /dev/null
rexx -c "$tmp/parser.rexx" /dev/null
if [ "$(rexx "$tmp/router.rexx" COMMIT -T 1700 -Z +0000 -m test)" != \
     'SIMULATED CURRENT -T 1700 -Z +0000 -m test' ]; then
 echo 'M251 GIT COMMIT route fixture failed' >&2
 exit 1
fi
expected='STAMP 1700 ZONE +0000 MESSAGE message with spaces'
if [ "$(rexx "$tmp/parser.rexx" '-T 1700 -Z +0000 -m "message with spaces"')" != "$expected" ]; then
 echo 'M251 quoted multiword commit message fixture failed' >&2
 exit 1
fi
if [ "$(rexx "$tmp/parser.rexx" '-T 1700 -Z +0000 --message "message with spaces"')" != "$expected" ]; then
 echo 'M251 long message option fixture failed' >&2
 exit 1
fi
echo 'M251 SOURCE-DERIVED CURRENT COMMIT FIXTURES PASS 3'
)
exit $?
fi

if [ "${1:-}" = "M252" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M251
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GITWT.EXEC" "$tmp" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
out=Path(sys.argv[2])
start=source.index(" if translate(word(rest,1))='--NEW' then do")
end=source.index(' addall=0',start)
block=source[start:end]
for token in ("'GITWT: new path must be 1-30 ASCII bytes with relative components'",
              'call splitpath newhex',
              "call findpath newhex", "call findfile newfn,newft,newfm",
              "'STATE' newfn newft newfm",
              'call workoid newfn,newft,newfm,1,1',
              "mapbase.newindex='0000000000000000000000000000000000000000'",
              'mapstage.newindex=newoid', 'maplf.newindex=1',
              'call savemap', 'if oldmap=1 then call restoremap'):
 if token not in block:
  raise SystemExit(f'M252 new-file ADD source guard missing {token!r}')
if not block.index('call workoid') < block.index('mapfn.newindex=newfn'):
 raise SystemExit('M252 must hash the file before changing the map')
validid=source[source.index('validid:\n'):source.index('validmode:\n')]
validmode=source[source.index('validmode:\n'):source.index('validtext:\n')]
splitpath=source[source.index('splitpath:\n'):source.index('readtree:\n')]
helpers=validid+validmode+"""
toasciihex:
 parse arg text
 return c2x(text)
"""+splitpath
block=block.replace("'STATE' newfn newft newfm",
                    'call cmsstate newfn,newft,newfm')
block=block.replace("'STATE GITWORK REPO A'", 'call mapstate')
block=block.replace("'EXECIO * DISKR GITWORK REPO A 1 (STEM BEFORE. FINIS'",
                    'before.0=1\n rc=0')
block=block.replace("'ERASE GITWORK REPO A'", "say 'SIMULATED ERASE'\n rc=0")
prefix="""parse arg rest
command='ADD'
mockmode='@MODE@'
"""
mocks="""
exit 99
loadmap:
 if mockmode='loadfail' then return 'ERROR'
 if mockmode='full' then mapcount=50
 else mapcount=0
 return 'OK'
findpath:
 if mockmode='pathdup' then return 1
 return 0
findfile:
 if mockmode='filedup' then return 1
 return 0
cmsstate:
 parse arg fn,ft,fm
 say 'SIMULATED STATE' fn ft fm
 if mockmode='missing' then rc=28
 else if mockmode='unreadable' then rc=12
 else rc=0
 return
mapstate:
 if mockmode='savefail' then rc=0
 else rc=28
 return
workoid:
 if mockmode='hashfail' then return 'ERROR'
 return 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
savemap:
 say 'SIMULATED SAVE' mapcount mapfn.mapcount mapfm.mapcount,
  maplf.mapcount mapbase.mapcount mapstage.mapcount mappath.mapcount
 if mockmode='savefail' then return 'ERROR'
 return 'OK'
restoremap:
 say 'SIMULATED RESTORE'
 return 'OK'
"""
for mode in ('ok','pathdup','filedup','missing','unreadable','full',
             'loadfail','hashfail','savefail'):
 (out/f'add-{mode}.rexx').write_text(
  prefix.replace('@MODE@',mode)+block+helpers+mocks)
print('M252 NEW-FILE ADD SOURCE GUARDS PASS 10')
PY
for file in "$tmp"/add-*.rexx; do rexx -c "$file" /dev/null; done
check() {
 mode=$1 expected_rc=$2 expected=$3
 shift 3
 if output=$(rexx "$tmp/add-$mode.rexx" "$*"); then rc=0; else rc=$?; fi
 if [ "$rc" -ne "$expected_rc" ] || [ "$output" != "$expected" ]; then
  echo "M252 $mode fixture mismatch RC $rc: $output" >&2
  exit 1
 fi
}
oid=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
check ok 0 "SIMULATED STATE NEWFILE DATA A
SIMULATED SAVE 1 NEWFILE A 1 0000000000000000000000000000000000000000 $oid 616C706861
ADDED alpha $oid
STAGE DIFFERS FROM BASE" --new alpha NEWFILE DATA
check ok 0 "SIMULATED STATE NEWFILE TEXT B
SIMULATED SAVE 1 NEWFILE B 1 0000000000000000000000000000000000000000 $oid 616C706861
ADDED alpha $oid
STAGE DIFFERS FROM BASE" --new alpha NEWFILE TEXT B
check pathdup 4 'GITWT: path is already mapped alpha' --new alpha NEWFILE DATA
check filedup 4 'GITWT: CMS file is already mapped NEWFILE DATA A' --new alpha NEWFILE DATA
check missing 8 "SIMULATED STATE NEWFILE DATA A
GITWT: new CMS workfile is absent or unreadable NEWFILE DATA A RC 28" --new alpha NEWFILE DATA
check unreadable 8 "SIMULATED STATE NEWFILE DATA A
GITWT: new CMS workfile is absent or unreadable NEWFILE DATA A RC 12" --new alpha NEWFILE DATA
check full 8 'GITWT: worktree map limit reached' --new alpha NEWFILE DATA
check loadfail 8 '' --new alpha NEWFILE DATA
check hashfail 8 'SIMULATED STATE NEWFILE DATA A' --new alpha NEWFILE DATA
check savefail 8 "SIMULATED STATE NEWFILE DATA A
SIMULATED SAVE 1 NEWFILE A 1 0000000000000000000000000000000000000000 $oid 616C706861
SIMULATED RESTORE" --new alpha NEWFILE DATA
check ok 0 "SIMULATED STATE NEWFILE DATA A
SIMULATED SAVE 1 NEWFILE A 1 0000000000000000000000000000000000000000 $oid 6469722F616C706861
ADDED dir/alpha $oid
STAGE DIFFERS FROM BASE" --new dir/alpha NEWFILE DATA
check ok 4 'GITWT: new path must be 1-30 ASCII bytes with relative components' --new abcdefghijklmnopqrstuvwxyzabcde1 NEWFILE DATA
check ok 4 'GITWT: new path must be 1-30 ASCII bytes with relative components' --new ../alpha NEWFILE DATA
check ok 4 'Usage: GIT ADD --new path fn ft [fm]' --new
check ok 4 '' --new alpha BAD-ID DATA
check ok 4 '' --new alpha NEWFILE '%'
echo 'M252/M254 SOURCE-DERIVED NEW-FILE ADD FIXTURES PASS 15'
)
exit $?
fi

if [ "${1:-}" = "M253" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M252
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GITWT.EXEC" "$tmp/insert.rexx" "$tmp/overflow.rexx" "$tmp/branch.rexx" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
commit=source[source.index("if command='COMMIT' then do"):
               source.index("say 'GITWT: unknown command'")]
for token in ('if mapbase.mi=zeros & mapstage.mi\\=zeros then do',
              'if cd=pcnt then do',
              'newrootname.newrootcount=pathcomp.mi.cd',
              'newrootoid.newrootcount=mapstage.mi',
              "address command 'EXEC GIT VERIFY-OBJECT' mapstage.mi",
              'call insertrootadds',
              "if matches=0 then return 'MISSING'",
              "if result\\='OK' & result\\='MISSING' then return 'ERROR'",
              "if nodemode.parentid.nej='40000' then compare=compare||'2F'",
              "if newrootmode.nai='40000' then newcompare=newcompare||'2F'",
              'nodeentrydeleted.parentid.next=nodeentrydeleted.parentid.nej',
              'nodemode.parentid.insertat=newrootmode.nai',
              'if nodeentrydeleted.parentid.lei\\=1 then liveentries=liveentries+1',
              "if liveentries>=256 then return 'ERROR'",
              'nodeentry.nji=nodeentry.nji+1'):
 if token not in source:
  raise SystemExit(f'M253 root-file commit guard missing {token!r}')
if not (commit.index("address command 'EXEC GIT VERIFY-OBJECT' mapstage.mi")<
        commit.index('newrootname.newrootcount=pathcomp.mi.cd')<
        commit.index('call insertrootadds')<commit.index('do level=maxdepth')):
 raise SystemExit('M253 inserts root files after tree rewrite begins')
insert=source[source.index('insertrootadds:\n'):source.index('parsepathout:\n')]
build=source[source.index('buildraw:\n'):source.index('insertrootadds:\n')]
mode=source[source.index('modehex:\n'):source.index('writehex:\n')]
entry_start=commit.index('    if entryindex=0 then do')
entry_end=commit.index('    if cd<pcnt then do',entry_start)
entry=commit[entry_start:entry_end]
entry=entry.replace("address command 'EXEC GIT VERIFY-OBJECT' mapstage.mi",
 "if scenario='VERIFYFAIL' then rc=8\nelse do\n say 'SIMULATED VERIFY'\n rc=0\nend")
prefix="""parse arg scenario
nodecount=1
nodeentries.1=2
nodeisnew.1=0
nodemode.1.1='40000'
nodenamehex.1.1='616C706861'
nodechildoid.1.1='CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'
nodeentrydeleted.1.1=1
nodemode.1.2='100644'
nodenamehex.1.2='62657461'
nodechildoid.1.2='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
nodeentrydeleted.1.2=0
newrootcount=3
newrootparent.1=1
newrootname.1='616172647661726B'
newrootmode.1='100644'
newrootoid.1='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
newrootparent.2=1
newrootname.2='616C7068612E747874'
newrootmode.2='100644'
newrootoid.2='DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD'
newrootparent.3=1
newrootname.3='7A657461'
newrootmode.3='100644'
newrootoid.3='EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE'
"""
main="""
if scenario='OVERFLOW' | scenario='DELETEDCAP' then do
 nodeentries.1=256
 newrootcount=1
 newrootparent.1=1
 do fi=3 to 256
  nodemode.1.fi='100644'
  nodenamehex.1.fi='66'||right(d2x(fi),4,'0')
  nodechildoid.1.fi='FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'
  nodeentrydeleted.1.fi=0
 end
end
if scenario='OVERFLOW' then nodeentrydeleted.1.1=0
if scenario='DELETEDCAP' then nodeentrydeleted.1.1=1
call insertrootadds
if scenario='OVERFLOW' then do
 say result
 if result\\='ERROR' then exit 12
 exit 0
end
if scenario='DELETEDCAP' then do
 if result\\='OK' then exit 12
 call buildraw 1
 if result='ERROR' then exit 12
 say 'COUNT' buildcount
 exit 0
end
if result\\='OK' then exit 12
call buildraw 1
 if result='ERROR' then exit 12
say result
say 'COUNT' buildcount
exit 0
"""
fixture=prefix+main+insert+build+mode
Path(sys.argv[2]).write_text(fixture)
Path(sys.argv[3]).write_text(fixture.replace("parse arg scenario", "parse arg scenario", 1))
branch="""parse arg scenario
pcnt=1
if scenario='NESTED' then pcnt=2
cd=1
currentnode=1
entryindex=0
mi=1
zeros='0000000000000000000000000000000000000000'
nodecount=1
nodeisnew.1=0
newrootcount=0
nodechanged.1=0
nodechanged.2=0
mapbase.1='0000000000000000000000000000000000000000'
if scenario='STALE' then mapbase.1='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
mapstage.1='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
pathcomp.1.1='616C706861'
pathcomp.1.2='66696C65'
do cd=1 to pcnt
"""+entry+"""
end
say 'NEWENTRY' newrootcount newrootparent.1 newrootname.1,
 newrootoid.1 nodechanged.1 nodechanged.2 nodecount
exit 0
"""
Path(sys.argv[4]).write_text(branch)
print('M253 NEW-ROOT TREE SOURCE GUARDS PASS 11')
PY
rexx -c "$tmp/insert.rexx" /dev/null
rexx -c "$tmp/overflow.rexx" /dev/null
rexx -c "$tmp/branch.rexx" /dev/null
expected='31303036343420616172647661726B00AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA31303036343420616C7068612E74787400DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD313030363434206265746100BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB313030363434207A65746100EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE'
if output=$(rexx "$tmp/insert.rexx" NORMAL); then rc=0; else rc=$?; fi
if [ "$rc" -ne 0 ] || [ "$output" != "$(printf '%s\nCOUNT 4' "$expected")" ]; then
 echo "M253 sorted root-tree insertion fixture mismatch RC $rc: $output" >&2
 exit 1
fi
if [ "$(rexx "$tmp/overflow.rexx" OVERFLOW)" != 'ERROR' ]; then
 echo 'M253 root-tree capacity fixture failed' >&2
 exit 1
fi
if [ "$(rexx "$tmp/insert.rexx" DELETEDCAP)" != 'COUNT 256' ]; then
 echo 'M253 deleted-entry capacity fixture failed' >&2
 exit 1
fi
expected_branch=$(printf 'SIMULATED VERIFY\nNEWENTRY 1 1 616C706861 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 1 0 1')
if [ "$(rexx "$tmp/branch.rexx" OK)" != "$expected_branch" ]; then
 echo "M253 new-root commit decision fixture failed: $(rexx "$tmp/branch.rexx" OK)" >&2
 exit 1
fi
expected_nested=$(printf 'SIMULATED VERIFY\nNEWENTRY 1 2 66696C65 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 1 2')
if [ "$(rexx "$tmp/branch.rexx" NESTED)" != "$expected_nested" ]; then
 echo "M254 nested path creation fixture failed: $(rexx "$tmp/branch.rexx" NESTED)" >&2
 exit 1
fi
if output=$(rexx "$tmp/branch.rexx" STALE); then rc=0; else rc=$?; fi
if [ "$rc" -ne 8 ] || [ "$output" != 'GITWT: staged path entry missing 1 1' ]; then
 echo "M253 stale addition rejection mismatch RC $rc: $output" >&2
 exit 1
fi
if output=$(rexx "$tmp/branch.rexx" VERIFYFAIL); then rc=0; else rc=$?; fi
if [ "$rc" -ne 8 ] || [ "$output" != 'GITWT: staged new blob is not verified 1' ]; then
 echo "M253 invalid new blob rejection mismatch RC $rc: $output" >&2
 exit 1
fi
echo 'M253 SOURCE-DERIVED NEW-ROOT TREE FIXTURES PASS 7'
)
exit $?
fi

if [ "${1:-}" = "M254" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M253
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GITWT.EXEC" "$tmp/nested.rexx" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
commit=source[source.index("if command='COMMIT' then do"):
               source.index("say 'GITWT: unknown command'")]
for token in ('call splitpath newhex', 'nodeisnew.childnode=1',
              'newrootparent.newrootcount=currentnode',
              "newrootmode.newrootcount='100644'",
              "if nodeisnew.ni=1 then do", "newrootmode.1='40000'",
              'if newrootmode.nai=\'40000\' then newcompare=newcompare||\'2F\'',
              'nodeentry.nji=nodeentry.nji+1',
              'nodechildoid.parentnode.parententry=treeoid',
              'do lei=1 to nodeentries.parentid'):
 if token not in source:
  raise SystemExit(f'M254 nested-tree guard missing {token!r}')
scan_start=commit.index('    entryindex=0\n')
scan_end=commit.index('    if entryindex=0 then do',scan_start)
scan=commit[scan_start:scan_end]
entry_start=scan_end
entry_end=commit.index('    if cd<pcnt then do',entry_start)
entry=commit[entry_start:entry_end]
entry=entry.replace("address command 'EXEC GIT VERIFY-OBJECT' mapstage.mi",
 "say 'SIMULATED VERIFY' mapstage.mi\nrc=0")
insert=source[source.index('insertrootadds:\n'):source.index('parsepathout:\n')]
build=source[source.index('buildraw:\n'):source.index('insertrootadds:\n')]
mode=source[source.index('modehex:\n'):source.index('writehex:\n')]
prefix="""parse arg scenario
nodecount=3
nodeentries.1=2
nodeisnew.1=0
nodemode.1.1='100644'
nodenamehex.1.1='646F63732E726561646D65'
nodechildoid.1.1='1111111111111111111111111111111111111111'
nodeentrydeleted.1.1=0
nodemode.1.2='40000'
nodenamehex.1.2='737263'
nodechildoid.1.2='2222222222222222222222222222222222222222'
nodeentrydeleted.1.2=0
nodeparent.3=1
nodename.3='737263'
nodeentry.3=2
nodeoid.3='2222222222222222222222222222222222222222'
nodedepth.3=1
nodechanged.3=0
nodeisnew.3=0
nodeentries.3=1
nodemode.3.1='100644'
nodenamehex.3.1='6F6C64'
nodechildoid.3.1='3333333333333333333333333333333333333333'
nodeentrydeleted.3.1=0
nodechanged.1=0
mapcount=2
zeros='0000000000000000000000000000000000000000'
mapbase.1=zeros
mapstage.1='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
pathcomp.1.1='646F6373'
pathcomp.1.2='61'
mapbase.2=zeros
mapstage.2='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
pathcomp.2.1='646F6373'
pathcomp.2.2='62'
newrootcount=0
"""
main="""
do mi=1 to mapcount
 pcnt=2
 currentnode=1
 do cd=1 to pcnt
"""+scan+entry+"""
 end
end
if nodecount\\=4 | newrootcount\\=2 |,
   newrootparent.1\\=4 | newrootparent.2\\=4 then exit 12
call insertrootadds
if result\\='OK' then exit 12
call buildraw 4
if result='ERROR' | buildcount\\=2 then exit 12
say 'FILES' result buildcount
newrootcount=1
newrootparent.1=3
newrootname.1='6E6577'
newrootmode.1='100644'
newrootoid.1='EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE'
call insertrootadds
if result\\='OK' then exit 12
call buildraw 3
if result='ERROR' | buildcount\\=2 then exit 12
say 'EXISTING' result buildcount
newrootcount=1
newrootparent.1=1
newrootname.1='646F6373'
newrootmode.1='40000'
newrootoid.1='CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'
call insertrootadds
if result\\='OK' | nodeentry.3\\=3 then exit 12
parentnode=nodeparent.3
parententry=nodeentry.3
treeoid='FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'
nodechildoid.parentnode.parententry=treeoid
call buildraw 1
if result='ERROR' | buildcount\\=3 then exit 12
say 'ROOT' result 'INDEX' nodeentry.3
nodeentries.4=256
newrootcount=1
newrootparent.1=4
newrootname.1='7A'
newrootmode.1='100644'
newrootoid.1='DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD'
call insertrootadds
say 'CAPACITY' result
exit 0
"""
Path(sys.argv[2]).write_text(prefix+main+insert+build+mode)
print('M254 NESTED TREE SOURCE GUARDS PASS 10')
PY
rexx -c "$tmp/nested.rexx" /dev/null
aa=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
bb=BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
ee=EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
ff=FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
old=1111111111111111111111111111111111111111
expected_files="313030363434206100${aa}313030363434206200${bb}"
expected_existing="313030363434206E657700${ee}313030363434206F6C64003333333333333333333333333333333333333333"
expected_root="31303036343420646F63732E726561646D6500${old}343030303020646F637300CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC34303030302073726300${ff}"
expected=$(printf 'SIMULATED VERIFY AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\nSIMULATED VERIFY BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB\nFILES %s 2\nEXISTING %s 2\nROOT %s INDEX 3\nCAPACITY ERROR' "$expected_files" "$expected_existing" "$expected_root")
if output=$(rexx "$tmp/nested.rexx" NORMAL); then rc=0; else rc=$?; fi
if [ "$rc" -ne 0 ] || [ "$output" != "$expected" ]; then
 echo "M254 nested-tree fixture mismatch RC $rc: $output" >&2
 exit 1
fi
echo 'M254 SOURCE-DERIVED NESTED TREE FIXTURES PASS 4'
)
exit $?
fi

if [ "${1:-}" = "M250" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M249
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GITWT.EXEC" "$tmp/accept.rexx" "$tmp/reappeared.rexx" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
start=source.index("if command='ACCEPT' then do")
end=source.index("if command='COMMIT' then do",start)
block=source[start:end]
for token in ('if mapstage.ai=zeros & mapbase.ai\\=zeros then do',
              'deleteflag.ai=1', 'if deleteflag.ai=1 then iterate',
              'mapcount=keptcount', "'ERASE GITWORK REPO A'", 'call savemap',
              "say 'ACCEPTED WORKTREE DELETED' deletepath.ai"):
 if token not in block:
  raise SystemExit(f'M250 delete acceptance source guard missing {token!r}')
if not block.index("'ERASE GITWORK REPO A'")<block.index('call savemap'):
 raise SystemExit('M250 must erase before shorter map write')
block=block.replace("'EXECIO * DISKR GITWORK REPO A 1 (STEM BEFORE. FINIS'",
                    "before.0=1\nrc=0")
block=block.replace("'STATE' mapfn.ai mapft.ai mapfm.ai",
 "if mapfn.ai='DELETED' then rc=28\nelse rc=0")
block=block.replace('call workoid mapfn.ai,mapft.ai,mapfm.ai,maplf.ai,0',
 "if ai=2 then result='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'\nelse result='CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'")
block=block.replace('call asciitocms mappath.ai',"result='deleted'")
block=block.replace('call loadmap',"result='OK'")
block=block.replace("'ERASE GITWORK REPO A'","say 'SIMULATED ERASE'\nrc=0")
block=block.replace('call savemap',"result='OK'\nsay 'SIMULATED SAVE' mapcount")
block=block.replace('call restoremap',"result='OK'")
verify=("if mapcount\\=2 | mapfn.1\\='STAGED' | mapfn.2\\='CLEAN' then exit 12\n"
        "if mapbase.1\\='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB' then exit 12\n"
        "if mapbase.2\\='CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC' then exit 12\n")
block=block.replace("say 'ACCEPTED WORKTREE DELETIONS' deletecount\n exit 0",
 "say 'ACCEPTED WORKTREE DELETIONS' deletecount\n"+verify+" exit 0")
prefix=("parse arg rest\ncommand='ACCEPT'\nmapcount=3\n"
 "mapfn.1='DELETED'\nmapfn.2='STAGED'\nmapfn.3='CLEAN'\n"
 "do mi=1 to 3\n mapft.mi='DATA'\n mapfm.mi='A'\n maplf.mi=1\nend\n"
 "mapbase.1='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mapstage.1='0000000000000000000000000000000000000000'\n"
 "mapbase.2='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mapstage.2='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'\n"
 "mapbase.3='CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'\n"
 "mapstage.3='CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'\n"
 "mappath.1='64656C65746564'\nmappath.2='737461676564'\n"
 "mappath.3='636C65616E'\n")
Path(sys.argv[2]).write_text(prefix+block)
reappeared=block.replace("if mapfn.ai='DELETED' then rc=28\nelse rc=0",'rc=0')
Path(sys.argv[3]).write_text(prefix+reappeared)
print('M250 WORKTREE MAP ACCEPT SOURCE GUARDS PASS 6')
PY
rexx -c "$tmp/accept.rexx" /dev/null
rexx -c "$tmp/reappeared.rexx" /dev/null
expected=$(printf 'GITWT ACCEPT LEVEL M168\nSIMULATED ERASE\nSIMULATED SAVE 2\nACCEPTED WORKTREE OLD AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\nACCEPTED WORKTREE NEW BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB\nACCEPTED WORKTREE DELETED deleted\nACCEPTED WORKTREE PATHS 2\nACCEPTED WORKTREE DELETIONS 1')
if output=$(rexx "$tmp/accept.rexx"); then rc=0; else rc=$?; fi
if [ "$rc" -ne 0 ] || [ "$output" != "$expected" ]; then
 echo "M250 accept fixture mismatch RC $rc: $output" >&2
 exit 1
fi
if output=$(rexx "$tmp/reappeared.rexx"); then rc=0; else rc=$?; fi
if [ "$rc" -ne 8 ] || [ "$output" != 'GITWT ACCEPT LEVEL M168
GITWT: deleted workfile reappeared before accept DELETED DATA A' ]; then
 echo "M250 reappeared deletion guard mismatch RC $rc: $output" >&2
 exit 1
fi
echo 'M250 SOURCE-DERIVED DELETE ACCEPTANCE FIXTURES PASS 2'
)
exit $?
fi

if [ "${1:-}" = "M249" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M248
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GITWT.EXEC" "$tmp/buildraw.rexx" "$tmp/empty.rexx" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
start=source.index("if command='COMMIT' then do")
end=source.index("say 'GITWT: unknown command'",start)
commit=source[start:end]
for token in ('if mapstage.mi=zeros then do', 'if rc=28 then iterate',
              'nodeentrydeleted.currentnode.entryindex=1',
              'call buildraw ni', 'if buildcount=0 then do',
              'nodeentrydeleted.parentnode.parententry=1',
              'call buildraw 1', 'COMMIT-STAGED ROOT TREE'):
 if token not in commit:
  raise SystemExit(f'M249 commit deletion source guard missing {token!r}')
start=source.index('buildraw:\n')
end=source.index('\nparsepathout:',start)
buildraw=source[start:end]
start=source.index('modehex:\n')
end=source.index('\nwritehex:',start)
modehex=source[start:end]
fixture=(
 "parse arg rest\nnodeentries.1=3\n"
 "nodemode.1.1='100644'\nnodenamehex.1.1='61'\n"
 "nodechildoid.1.1='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "nodemode.1.2='100644'\nnodenamehex.1.2='62'\n"
 "nodechildoid.1.2='CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'\n"
 "nodeentrydeleted.1.2=1\n"
 "nodemode.1.3='100755'\nnodenamehex.1.3='63'\n"
 "nodechildoid.1.3='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'\n"
 "call buildraw 1\nsay 'KEPT' buildcount\nsay result\nexit 0\n"
 + buildraw+modehex)
Path(sys.argv[2]).write_text(fixture)
Path(sys.argv[3]).write_text(fixture.replace("nodeentrydeleted.1.2=1", "nodeentrydeleted.1.2=1\nnodeentrydeleted.1.1=1\nnodeentrydeleted.1.3=1"))
print('M249 COMMIT DELETION SOURCE GUARDS PASS 8')
PY
rexx -c "$tmp/buildraw.rexx" /dev/null
rexx -c "$tmp/empty.rexx" /dev/null
expected='KEPT 2
313030363434206100AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA313030373535206300BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
if [ "$(rexx "$tmp/buildraw.rexx")" != "$expected" ]; then
 echo 'M249 rewritten tree raw bytes mismatch' >&2
 exit 1
fi
if [ "$(rexx "$tmp/empty.rexx")" != 'KEPT 0' ]; then
 echo 'M249 empty subtree fixture mismatch' >&2
 exit 1
fi
echo 'M249 SOURCE-DERIVED TREE DELETION SERIALIZATION FIXTURES PASS 2'
)
exit $?
fi

if [ "${1:-}" = "M248" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M247
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GITWT.EXEC" "$tmp/status.rexx" "$tmp/diff.rexx" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
start=source.index("if command='STATUS' then do")
end=source.index("if command='DIFF' then do",start)
status=source[start:end]
start=end
end=source.index('/* Read-only preflight for a branch switch',start)
diff=source[start:end]
for token in ('if rc=28 then addoid.ai=zeros', "say 'STAGED DELETION'",
              'if mapstage.i=zeros then x=\'D\''):
 if token not in source:
  raise SystemExit(f'M248 deletion staging source guard missing {token!r}')
if 'if mapstage.i\\=zeros then changed=1' not in diff:
 raise SystemExit('M248 unstaged diff does not compare missing workfile to empty staged blob')
state=("if mapfn.i='STAGEDDEL' | mapfn.i='WORKDEL' then rc=28\n"
       "else rc=0")
work=("if mapfn.i='RESTORED' then\n"
      " result='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'\n"
      "else result='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'")
prefix=(
 "parse arg rest\nmapcount=3\n"
 "mapfn.1='STAGEDDEL'\nmapfn.2='WORKDEL'\nmapfn.3='RESTORED'\n"
 "do mi=1 to 3\n mapft.mi='DATA'\n mapfm.mi='A'\n maplf.mi=1\n"
 " mapbase.mi='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\nend\n"
 "mapstage.1='0000000000000000000000000000000000000000'\n"
 "mapstage.2='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mapstage.3='0000000000000000000000000000000000000000'\n"
 "mappath.1='737461676564676F6E65'\n"
 "mappath.2='776F726B676F6E65'\n"
 "mappath.3='726573746F726564'\n")
for command,block,path in (('STATUS',status,sys.argv[2]),('DIFF',diff,sys.argv[3])):
 fixture=(prefix+f"command='{command}'\n"+
  block.replace('call loadmap',"result='OK'")
       .replace("'STATE' mapfn.i mapft.i mapfm.i",state)
       .replace('call workoid mapfn.i,mapft.i,mapfm.i,maplf.i,0',work)+
  "readrefs:\n headref='refs/heads/test'\n return 'OK'\n"
  "asciitocms:\n parse arg text\n return x2c(text)\n")
 Path(path).write_text(fixture)
print('M248 STAGED-DELETION STATUS/DIFF SOURCE GUARDS PASS 4')
PY
rexx -c "$tmp/status.rexx" /dev/null
rexx -c "$tmp/diff.rexx" /dev/null
check() {
 fixture=$1
 expected=$2
 shift 2
 output=$(rexx "$fixture" "$@")
 if [ "$output" != "$expected" ]; then
  echo "M248 $*: expected '$expected', got '$output'" >&2
  exit 1
 fi
}
status=$(printf 'D  stagedgone\n D workgone\nDA restored')
cached=$(printf 'stagedgone\nrestored')
unstaged=$(printf 'workgone\nrestored')
check "$tmp/status.rexx" "$status" --short
check "$tmp/diff.rexx" "$cached" --cached --name-only
check "$tmp/diff.rexx" "$unstaged" --name-only
echo 'M248 SOURCE-DERIVED STAGED DELETION STATUS/DIFF FIXTURES PASS 3'
)
exit $?
fi

if [ "${1:-}" = "M247" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M246
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GITWT.EXEC" "$tmp/status.rexx" "$tmp/empty.rexx" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
start=source.index("if command='STATUS' then do")
end=source.index("if command='DIFF' then do",start)
block=source[start:end]
required=("statusopt='--SHORT'", "statusopt='--PORCELAIN'",
          "statusopt='--BRANCH'", 'call readrefs',
          "say '##' branchname", "say 'On branch' branchname",
          "Usage: GIT STATUS [--short|--porcelain] [--branch]")
for token in required:
 if token not in block:
  raise SystemExit(f'M247 status branch guard missing {token!r}')
fixture=(
 "parse arg rest\ncommand='STATUS'\nmapcount=1\n"
 "mapfn.1='CLEAN'\nmapft.1='DATA'\nmapfm.1='A'\nmaplf.1=1\n"
 "mapbase.1='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mapstage.1='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
 "mappath.1='636C65616E'\n" +
 block.replace('call loadmap',"result='OK'")
      .replace("'STATE' mapfn.i mapft.i mapfm.i",'rc=0')
      .replace('call workoid mapfn.i,mapft.i,mapfm.i,maplf.i,0',
               "result='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'")
 + "readrefs:\n headref='refs/heads/feature/status'\n return 'OK'\n"
   "asciitocms:\n parse arg text\n return x2c(text)\n")
Path(sys.argv[2]).write_text(fixture)
Path(sys.argv[3]).write_text(fixture.replace('mapcount=1','mapcount=0'))
print('M247 GIT STATUS BRANCH SOURCE GUARDS PASS 7')
PY
rexx -c "$tmp/status.rexx" /dev/null
check() {
 fixture=$1
 expected_rc=$2
 expected=$3
 shift 3
 if output=$(rexx "$fixture" "$@" 2>&1); then rc=0; else rc=$?; fi
 if [ "$rc" -ne "$expected_rc" ]; then
  echo "GIT STATUS --branch $*: expected RC $expected_rc, got $rc ($output)" >&2
  exit 1
 fi
 if [ "$output" != "$expected" ]; then
  echo "GIT STATUS --branch $*: output mismatch: '$output'" >&2
  exit 1
 fi
}
expected=$(printf 'On branch feature/status\nSTATUS NO TRACKED FILES')
check "$tmp/empty.rexx" 0 "$expected" --branch
check "$tmp/status.rexx" 0 '## feature/status' --short --branch
check "$tmp/status.rexx" 0 '## feature/status' --branch --porcelain
check "$tmp/status.rexx" 4 'Usage: GIT STATUS [--short|--porcelain] [--branch]' --branch --unknown
echo 'M247 SOURCE-DERIVED STATUS BRANCH FIXTURES PASS 4'
)
exit $?
fi

if [ "${1:-}" = "M246" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M245
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GIT.EXEC" "$tmp/restore.rexx" <<'PY'
from pathlib import Path
import sys

source=Path(sys.argv[1]).read_text()
start=source.index("if command = 'RESTORE' then do")
end=source.index("if command = 'ADD' then do",start)
block=source[start:end]
required=('parse var rest restoreopt restorepaths',
          "translate(restoreopt)\\='--STAGED'",
          "say 'Usage: GIT RESTORE --staged [--] path...'",
          "address command 'EXEC GITWT RESET' restorepaths",
          'exit rc')
for token in required:
 if token not in block:
  raise SystemExit(f'M246 restore source guard missing {token!r}')
block=block.replace("address command 'EXEC GITWT RESET' restorepaths",
                    "say 'SIMULATED RESET' restorepaths\nexit 0")
Path(sys.argv[2]).write_text("parse arg rest\ncommand='RESTORE'\n"+block)
print('M246 GIT RESTORE ROUTE SOURCE GUARDS PASS 5')
PY
rexx -c "$tmp/restore.rexx" /dev/null
check() {
 expected_rc=$1
 expected=$2
 shift 2
 if output=$(rexx "$tmp/restore.rexx" "$@"); then rc=0; else rc=$?; fi
 if [ "$rc" -ne "$expected_rc" ]; then
  echo "GIT RESTORE $*: expected RC $expected_rc, got $rc" >&2
  exit 1
 fi
 if [ "$output" != "$expected" ]; then
  echo "GIT RESTORE $*: expected '$expected', got '$output'" >&2
  exit 1
 fi
}
check 0 'SIMULATED RESET alpha' --staged alpha
check 0 'SIMULATED RESET -- alpha beta' --STAGED -- alpha beta
check 4 'Usage: GIT RESTORE --staged [--] path...' --worktree alpha
check 4 'Usage: GIT RESTORE --staged [--] path...' --staged
echo 'M246 SOURCE-DERIVED RESTORE STAGED FIXTURES PASS 4'
)
exit $?
fi

# A bounded log count must stop cleanly when history reaches a root commit.
if [ "${1:-}" = "M240" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M239
python3 - "$root/src/GITREC.C" <<'PY'
from pathlib import Path
import sys
source=Path(sys.argv[1]).read_text()
start=source.index('static int rec_logfull(')
end=source.index('\nstatic int ',start+1)
routine=source[start:end]
rootcheck='if(sz<=46||!rec_ascii_key(idx_body+46,sz-46,"parent")) {'
if rootcheck not in routine:
 raise SystemExit('M240 LOG root detection missing')
offset=routine.index(rootcheck)
close=routine.index('\n  }',offset)
rootbody=routine[offset:close]
if 'depth=hop;' not in rootbody or 'break;' not in rootbody:
 raise SystemExit('M240 LOG does not clamp depth at the reached root')
if 'return 4;' in rootbody or 'LOG ROOT REACHED' in routine:
 raise SystemExit('M240 LOG still fails when history is shorter than requested')
required=('for(hop=0;hop<=depth;hop++)',
          'for(j=0;j<=depth;j++)',
          'printf("LOG NODES %u\\n",depth+1);')
for token in required:
 if token not in routine:
  raise SystemExit(f'M240 short-history output framing missing {token!r}')
if not (routine.index('depth=hop;')<routine.index('for(j=0;j<=depth;j++)')<
        routine.index('printf("LOG NODES %u\\n",depth+1);')):
 raise SystemExit('M240 LOG does not frame the clamped node count')
print('M240 SHORT-HISTORY LOG SOURCE GUARDS PASS 6')
PY
echo 'M240 BOUNDED LOG ROOT COMPLETION PASS'
)
exit $?
fi

# Isolated M206 explicit-object compatibility route: host source guard only.
if [ "${1:-}" = "M206BRIDGE" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
c="$root/src/GITC26.EXEC"
old="$root/src/GITC23.EXEC"
test -s "$c" && test -s "$old"
grep -Fq "if mode='OBJECTS' | mode='OBJECTSRUN' then do" "$c"
grep -Fq "signal objectpath" "$c"
grep -Fq "objs.i=obj.i" "$c"
grep -Fq "limit=max" "$c"
grep -Fq "objectpath:" "$c"
grep -Fq "'GITP21 G' objs.i limit 'CHECK'" "$c"
grep -Fq "'GITP21 G' obj limit" "$c"
grep -Fq "'GITCLN SCRATCH'" "$c"
if grep -Fq "'GITC23 G " "$c"; then
 echo 'FAIL: M206 retained external M203 dispatch' >&2
 exit 1
fi
grep -Fq "if count<2 | count>8 then exit 4" "$c"
grep -Fq "if obj.i<1 | obj.i>7736 then exit 4" "$c"
grep -Fq "if obj.i=obj.j then exit 4" "$c"
grep -Fq "M206 OBJECTS AUTHENTICATION PASS" "$c"
grep -Fq "if fm\\='G' | (mode\\='CHECK' & mode\\='RUN')" "$c"
grep -Fq "M206 STRATIFIED FULL SHA CLEAN PASS" "$c"
grep -Fq "M203 BOUNDED FULL SHA CLEAN PASS" "$c"
grep -Fq "'GITC26' fm route limit members" "$old"
grep -Fq "if mode='RUN' then route='OBJECTSRUN'" "$old"
python3 - "$c" "$old" <<'PY'
from pathlib import Path
import sys
new = Path(sys.argv[1]).read_text()
legacy = Path(sys.argv[2]).read_text()
worker = new.split("\nobjectpath:\n", 1)[1]
required = [
    "'STATE GITP21 EXEC A'",
    "'STATE GITP21M MODULE A'",
    "'STATE GITR199 DATA A'",
    "'PIPE CMS FILEDEF | STEM defs.'",
    "'GITP21 G' objs.i limit 'CHECK'",
    "M203 ALL INDEX CHECKS PASS",
    "if mode='OBJECTS' then do",
    "'GITP21 G' obj limit",
    "M203 FULL OBJECT SHA VERIFIED",
    "'GITCLN SCRATCH'",
    "M203 CLEAN VERIFIED",
    "M203 BOUNDED FULL SHA CLEAN PASS"
]
offsets = [worker.index(token) for token in required]
if offsets != sorted(offsets):
    raise RuntimeError("M203 preflight/SHA/cleanup ordering drift")
if worker.count("'GITCLN SCRATCH'") != 1:
    raise RuntimeError("unexpected cleanup cardinality")
if "'GITC26' fm route limit members" not in legacy:
    raise RuntimeError("compatibility wrapper not routed to GITC26")
print("M206 EMBEDDED WORKER ORDER AND LEGACY WRAPPER PASS")
PY
awk 'length($0)>80 {bad=1} END {exit bad}' "$c"
echo 'M206 EXPLICIT ROUTE SOURCE GUARDS PASS (CMS UNVERIFIED)'
)
exit $?
fi

# Exercise modern short-name/HEAD resolution against a synthetic REF2 map.
if [ "${1:-}" = "M215" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M213
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GITVREF.EXEC" "$tmp/resolve.rexx" <<'PY'
from pathlib import Path
import sys
source=Path(sys.argv[1]).read_text()
start=source.index('\nresolve:\n')+1
end=source.index('\nvalidref:\n',start)
routine=source[start:end]
prefix="""parse arg command wanted
headref='refs/heads/main'
reskind=''
refcount=4
refname.1='refs/heads/main'
refoid.1='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
refname.2='refs/heads/v1'
refoid.2='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
refname.3='refs/tags/v1'
refoid.3='CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'
refname.4='refs/tags/release/1'
refoid.4='DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD'
call resolve wanted
if result='ERROR' then say 'ERROR'
else say result reskind
exit 0
"""
stub="""
directinput:
 return 0
"""
Path(sys.argv[2]).write_text(prefix+routine+stub)
PY
rexx -c "$tmp/resolve.rexx" /dev/null
check() {
 expected=$1
 command=$2
 wanted=$3
 rexx "$tmp/resolve.rexx" "$command" "$wanted" > "$tmp/result"
 actual=$(tail -n 1 "$tmp/result")
 if [ "$actual" != "$expected" ]; then
  echo "resolve $command $wanted: expected $expected, got $actual" >&2
  exit 1
 fi
}
check 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA REF' RESOLVE HEAD
check 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA REF' RESOLVE main
check 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB REF' RESOLVE v1
check 'DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD REF' RESOLVE release/1
check 'DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD REF' RESOLVE refs/tags/release/1
check ERROR RESOLVE refs/tags/missing
echo 'M215 SOURCE-DERIVED REF2 RESOLUTION FIXTURES PASS 6'
)
exit $?
fi

# Test the source-derived ASCII ref-name ordering comparator.
if [ "${1:-}" = "M216" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M215
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GITVREF.EXEC" "$tmp/tagbefore.rexx" <<'PY'
from pathlib import Path
import sys
source=Path(sys.argv[1]).read_text()
start=source.index('\ntagbefore:\n')+1
end=source.index('\nbindnative:\n',start)
routine=source[start:end]
Path(sys.argv[2]).write_text(
 'parse arg leftname rightname\ncall tagbefore leftname, rightname\n'+
 'say result\nexit 0\n'+routine+'\n')
PY
rexx -c "$tmp/tagbefore.rexx" /dev/null
check() {
 expected=$1
 leftname=$2
 rightname=$3
 rexx "$tmp/tagbefore.rexx" "$leftname" "$rightname" > "$tmp/result"
 actual=$(tail -n 1 "$tmp/result")
 if [ "$actual" != "$expected" ]; then
  echo "tag order $leftname / $rightname: expected $expected, got $actual" >&2
  exit 1
 fi
}
check YES -a .a
check YES .a /a
check YES 9 A
check YES A _
check YES _ a
check YES v10 v2
check YES a a/b
check NO b a
python3 - "$root/src/GITVREF.EXEC" "$tmp/taglist.rexx" <<'PY'
from pathlib import Path
import sys
source=Path(sys.argv[1]).read_text()
start=source.index("if command='TAGS' then do")
end=source.index("if command='CASE' then do",start)
block=source[start:end]
hstart=source.index('\ntagmatch:\n')+1
hend=source.index('\nbindnative:\n',hstart)
helpers=source[hstart:hend]
prefix="""parse arg spec
command='TAGS'
depth=''
extra=''
"""
fixture="""
exit 4
readrefs:
 refcount=6
 refname.1='refs/tags/v2'
 refoid.1='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
 refname.2='refs/heads/main'
 refoid.2='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
 refname.3='refs/tags/v10'
 refoid.3='CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'
 refname.4='refs/tags/alpha'
 refoid.4='DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD'
 refname.5='refs/tags/Alpha'
 refoid.5='EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE'
 refname.6='refs/tags/-tag'
 refoid.6='FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'
 return 'OK'
"""
Path(sys.argv[2]).write_text(prefix+block+fixture+helpers)
PY
rexx -c "$tmp/taglist.rexx" /dev/null
actual=$(rexx "$tmp/taglist.rexx" '')
expected=$(printf '%s\n' '-tag' 'Alpha' 'alpha' 'v10' 'v2')
if [ "$actual" != "$expected" ]; then
 echo "tag list order mismatch: $actual" >&2
 exit 1
fi
actual=$(rexx "$tmp/taglist.rexx" 'v*')
expected=$(printf '%s\n' 'v10' 'v2')
if [ "$actual" != "$expected" ]; then
 echo "tag pattern output mismatch: $actual" >&2
 exit 1
fi
echo 'M216 SOURCE-DERIVED TAG ORDER/LIST FIXTURES PASS 10'
)
exit $?
fi

# Exercise modern branch-list dispatch while preserving the legacy fallback.
if [ "${1:-}" = "M217" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M216
python3 - "$root/src/GIT.EXEC" "$root/src/GITVREF.EXEC" <<'PY'
from pathlib import Path
import sys
git=Path(sys.argv[1]).read_text()
refs=Path(sys.argv[2]).read_text()
for token in ("if command = 'BRANCH' then do", "'STATE GITREF2 REPO A'",
              'if rc=28 then do', "'EXEC GITREF BRANCH' rest",
              "EXEC GITVREF BRANCHES",
              "EXEC GIT UPDATE-REF' branchref branchoid zeros",
              "EXEC GIT UPDATE-REF' branchref zeros branchoid",
              "call resolvestart branchref",
              "verify(branchoid,'0123456789ABCDEF')"):
 if token not in git:
  raise SystemExit(f'GIT.EXEC missing modern branch path: {token}')
if "if command = 'BRANCH' | command = 'SHOW-REF'" in git:
 raise SystemExit('legacy router still captures modern BRANCH command')
for token in ("if command='BRANCHES' then do",
              "left(refname.bi,11)='refs/heads/'",
              "if headref='refs/heads/'||branchname then say",
              "say '*' branchname", 'call tagbefore branchlist.bj'):
 if token not in refs:
  raise SystemExit(f'GITVREF.EXEC missing branch list behavior: {token}')
print('M217 MODERN BRANCH ROUTE/UPDATE GUARDS PASS')
PY
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GITVREF.EXEC" "$tmp/branches.rexx" <<'PY'
from pathlib import Path
import sys
source=Path(sys.argv[1]).read_text()
start=source.index("if command='BRANCHES' then do")
end=source.index("if command='TAGS' then do",start)
block=source[start:end]
sort_start=source.index('tagbefore:\n')
sort_end=source.index('bindnative:\n',sort_start)
sorter=source[sort_start:sort_end]
prefix="""parse arg
command='BRANCHES'
spec=''
depth=''
extra=''
"""
fixture="""exit 4
readrefs:
 headref='refs/heads/main'
 refcount=3
 refname.1='refs/tags/v1'
 refoid.1='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
 refname.2='refs/heads/feature/x'
 refoid.2='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
 refname.3='refs/heads/main'
 refoid.3='CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'
 return 'OK'
"""
Path(sys.argv[2]).write_text(prefix+block+fixture+sorter)
PY
rexx -c "$tmp/branches.rexx" /dev/null
actual=$(rexx "$tmp/branches.rexx")
expected=$(printf '%s\n' '  feature/x' '* main')
if [ "$actual" != "$expected" ]; then
 echo "branch list mismatch: $actual" >&2
 exit 1
fi
echo 'M217 SOURCE-DERIVED REF2 BRANCH LIST FIXTURE PASS 1'
)
exit $?
fi

# Exercise guarded REF2 branch switching and its exact updater decision path.
if [ "${1:-}" = "M218" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M217
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GIT.EXEC" "$root/src/GITUPD.EXEC" \
 "$root/src/GITVREF.EXEC" "$tmp" <<'PY'
from pathlib import Path
import sys
git=Path(sys.argv[1]).read_text()
upd=Path(sys.argv[2]).read_text()
refs=Path(sys.argv[3]).read_text()
tmp=Path(sys.argv[4])
for token in ("if command = 'SWITCH' then do",
              "PIPE CMS EXEC GITVREF HEAD | STEM CURRENTHEAD.",
              "EXEC GITUPD HEAD refs/heads/",
              "if ref='HEAD' then do",
              "if oldoid\\=newoid then do",
              "call checkswitch oldhead,newhead",
              "HEAD switch verification failed",
              "if command='HEAD' then do",
              "say headref"):
    source=git+upd+refs
    if token not in source:
        raise SystemExit(f'M218 source missing guard: {token}')
switch=git[git.index("if command = 'SWITCH' then do"):]
assert switch.index("PIPE CMS EXEC GITVREF HEAD") < switch.index("EXEC GITUPD HEAD")
assert "headref=strip(currenthead.1)" in switch

vstart=refs.index("if command='HEAD' then do")
vend=refs.index("if command='BRANCHES' then do",vstart)
vblock=refs[vstart:vend]
head_test=(
    "parse arg command spec depth extra\n"
    "command='HEAD'\nspec=''\ndepth=''\nextra=''\n"
    +vblock+
    "exit 99\nreadrefs:\n headref='refs/heads/topic'\n"
    " return 'OK'\n"
)
(tmp/'head.rexx').write_text(head_test)

ustart=upd.index("if ref='HEAD' then do")
uend=upd.index("zeros='0000000000000000000000000000000000000000'",ustart)
ublock=upd[ustart:uend]
fixture=(
    "parse arg mode\nreadcalls=0\nref='HEAD'\n"
    "newheadarg='refs/heads/topic'\n"
    "newoid=newheadarg\noldoid='refs/heads/main'\nextra=''\n"
    +ublock+
    "exit 99\n"
    "validref:\n parse arg vr\n"
    " if left(vr,11)='refs/heads/' then return 'OK'\n"
    " return 'ERROR'\n"
    "readrefs:\n"
    " readcalls=readcalls+1\n"
    " if written=1 then headref=storedhead\n"
    " else headref='refs/heads/main'\n"
    " if mode='race' & readcalls>1 then,\n"
    "  headref='refs/heads/other'\n"
    " refcount=2\nrefname.1='refs/heads/main'\n"
    " refname.2='refs/heads/topic'\n"
    " refoid.1='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
    " refoid.2=refoid.1\n"
    " if mode='different' | mode='safe' then,\n"
    "  refoid.2='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'\n"
    " if mode='raceoid' & readcalls>1 then,\n"
    "  refoid.2='DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD'\n"
    " if mode='missing' then refcount=1\n"
    " rr.0=4\nrr.1='REF2 1'\nrr.2='HEAD '||headref\n"
    " rr.3='REF refs/heads/main '||refoid.1\n"
    " rr.4='REF refs/heads/topic '||refoid.2\n"
    " return 'OK'\n"
    "requirecommit:\n return 'OK'\n"
    "checkswitch:\n say 'SIMULATED SWITCH PREFLIGHT'\n"
    " if mode='different' then return 'ERROR'\n"
    " return 'OK'\n"
    "writerefs:\n"
    " if mode='writefail' then return 'ERROR'\n"
    " storedhead=headref\nwritten=1\nsay 'SIMULATED WRITE'\nreturn 'OK'\n"
    "restore:\n storedhead='refs/heads/main'\nwritten=0\n"
    " say 'SIMULATED RESTORE'\nreturn 'OK'\n"
)
(tmp/'switch.rexx').write_text(fixture)
PY
rexx -c "$tmp/head.rexx" /dev/null
head=$(rexx "$tmp/head.rexx")
[ "$head" = 'refs/heads/topic' ]
rexx -c "$tmp/switch.rexx" /dev/null
ok=$(rexx "$tmp/switch.rexx" same)
[ "$?" -eq 0 ]
echo "$ok" | grep -q 'HEAD UPDATED refs/heads/main refs/heads/topic'
echo "$ok" | grep -q 'SIMULATED WRITE'
same=$(rexx "$tmp/switch.rexx" same)
echo "$same" | grep -q 'HEAD UPDATED'
if rexx "$tmp/switch.rexx" different >"$tmp/different"; then
 echo 'different-tip switch unexpectedly succeeded' >&2
 exit 1
else
 rc=$?
 [ "$rc" -eq 8 ]
fi
grep -q 'destination worktree preflight failed' "$tmp/different"
grep -q 'SIMULATED SWITCH PREFLIGHT' "$tmp/different"
safe=$(rexx "$tmp/switch.rexx" safe)
echo "$safe" | grep -q 'HEAD UPDATED refs/heads/main refs/heads/topic'
echo "$safe" | grep -q 'SIMULATED SWITCH PREFLIGHT'
if rexx "$tmp/switch.rexx" missing >"$tmp/missing"; then
 echo 'missing branch switch unexpectedly succeeded' >&2
 exit 1
else
 rc=$?
 [ "$rc" -eq 8 ]
fi
grep -q 'switch branch is missing' "$tmp/missing"
if rexx "$tmp/switch.rexx" writefail >"$tmp/writefail"; then
 echo 'failed HEAD write unexpectedly succeeded' >&2
 exit 1
else
 rc=$?
 [ "$rc" -eq 8 ]
fi
grep -q 'SIMULATED RESTORE' "$tmp/writefail"
if rexx "$tmp/switch.rexx" race >"$tmp/race"; then
 echo 'stale HEAD race unexpectedly succeeded' >&2
 exit 1
else
 rc=$?
 [ "$rc" -eq 8 ]
fi
grep -q 'symbolic HEAD changed during switch preflight' "$tmp/race"
if rexx "$tmp/switch.rexx" raceoid >"$tmp/raceoid"; then
 echo 'stale branch-tip race unexpectedly succeeded' >&2
 exit 1
else
 rc=$?
 [ "$rc" -eq 8 ]
fi
grep -q 'branch tips changed during switch preflight' "$tmp/raceoid"
if grep -q 'SIMULATED WRITE' "$tmp/different" "$tmp/missing" "$tmp/writefail"; then
 echo 'rejected HEAD switch attempted a write' >&2
 exit 1
fi
echo 'M218 SOURCE-DERIVED REF2 SWITCH FIXTURES PASS 8'
)
exit $?
fi

# Execute the exact read-only mapped-worktree preflight used by GITUPD.
if [ "${1:-}" = "M219" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M218
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GIT.EXEC" "$root/src/GITUPD.EXEC" \
 "$root/src/GITWT.EXEC" "$tmp/checkswitch.rexx" <<'PY'
from pathlib import Path
import sys
git=Path(sys.argv[1]).read_text()
upd=Path(sys.argv[2]).read_text()
wt=Path(sys.argv[3]).read_text()
out=Path(sys.argv[4])
for source, token in ((upd,"EXEC GITWT CHECK-SWITCH"),
                      (wt,"if command='CHECK-SWITCH' then do"),
                      (wt,"GITREC PATHFULLCAT GITFIX M15NEW"),
                      (wt,"'STATE' wfn wft wfm"),
                      (wt,"workoid mapfn.mi,mapft.mi,mapfm.mi,maplf.mi,0"),
                      (wt,"destination changes mapped path"),
                      (wt,"staged changes block branch switch")):
    if token not in source:
        raise SystemExit(f'M219 source missing safe-switch check: {token}')
head=upd[upd.index("if ref='HEAD' then do"):upd.index(
    "zeros='0000000000000000000000000000000000000000'")]
assert head.index('call checkswitch oldhead,newhead') < head.index('headref=newhead')
start=wt.index("if command='CHECK-SWITCH' then do")
end=wt.index("if command='ADD' then do",start)
block=wt[start:end]
for forbidden in ('DISKW', 'ERASE', 'WRITE-WORKFILE', 'UPDATE-REF'):
    if forbidden in block:
        raise SystemExit(f'M219 preflight contains a mutating operation: {forbidden}')
fixture=(
    "parse arg mode\ncommand='CHECK-SWITCH'\n"
    "rest='refs/heads/main refs/heads/topic'\n"
    "if mode='oidtarget' then,\n"
    " rest='refs/heads/main CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'\n"
    +block+
    "exit 99\n"
    "validref:\n parse arg vr\n"
    " if left(vr,11)='refs/heads/' then return 'OK'\n"
    " return 'ERROR'\n"
    "readrefs:\n"
    " headref='refs/heads/main'\n"
    " if mode='stale' then headref='refs/heads/other'\n"
    " refcount=2\nrefname.1='refs/heads/main'\n"
    " refoid.1='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'\n"
    " refname.2='refs/heads/topic'\n"
    " refoid.2='CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'\n"
    " return 'OK'\n"
    "resolve:\n parse arg wanted\n"
    " if wanted='refs/heads/main' then return refoid.1\n"
    " if wanted='refs/heads/topic' then return refoid.2\n"
    " return 'ERROR'\n"
    "loadmap:\n"
    " if mode='unmapped' then do\n mapcount=0\n return 'OK'\n end\n"
    " mapcount=1\nmapfn.1='M219TEST'\nmapft.1='DATA'\n"
    " mapfm.1='A'\nmaplf.1='1'\n"
    " mapbase.1='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
    " mapstage.1=mapbase.1\nmappath.1='7372632F66696C65'\n"
    " if mode='staged' then,\n"
    "  mapstage.1='EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE'\n"
    " return 'OK'\n"
    "bindnative:\n return 'OK'\n"
    "checkworkfile:\n"
    " if mode='missingfile' then return 'ERROR'\n"
    " return 'OK'\n"
    "workoid:\n"
    " if mode='dirty' then,\n"
    "  return 'DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD'\n"
    " return 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
    "pathoidfor:\n parse arg pcommit,ppath\n"
    " if mode='missingpath' & pcommit=refoid.2 then,\n"
    "  return 'ERROR'\n"
    " if mode='currentstale' & pcommit=refoid.1 then,\n"
    "  return 'DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD'\n"
    " if mode='changed' & pcommit=refoid.2 then,\n"
    "  return 'DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD'\n"
    " return 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
)
out.write_text(fixture)
pstart=wt.index('\nparsepathout:\n')+1
pend=wt.index('\npathoidfor:\n',pstart)
parser=wt[pstart:pend]
parse_fixture=(
    "parse arg mode\nout.0=5\n"
    "out.1='COMMIT ROOT FULL CLOSURE VERIFIED'\n"
    "out.2='PATH OBJECT TYPE 3 SIZE 3 OID AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
    "out.3='PATH DATA BEGIN'\nout.4='PATH HEX 616263'\n"
    "out.5='PATH DATA END'\n"
    "if mode='bad' then out.2=\"PATH OBJECT TYPE 3 SIZE 4 OID AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\"\n"
    "call parsepathout\n"
    "if result='OK' then say 'OK' pathoid\nelse say 'ERROR'\n"
    "exit 0\n"+parser
)
(out.parent/'parsepath.rexx').write_text(parse_fixture)
PY
rexx -c "$tmp/checkswitch.rexx" /dev/null
rexx -c "$tmp/parsepath.rexx" /dev/null
parsed=$(rexx "$tmp/parsepath.rexx" good)
echo "$parsed" | grep -q '^OK AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA$'
invalid=$(rexx "$tmp/parsepath.rexx" bad)
[ "$invalid" = 'ERROR' ]
safe=$(rexx "$tmp/checkswitch.rexx" clean)
echo "$safe" | grep -q 'SWITCH PREFLIGHT SAFE MAPPED 1'
oidtarget=$(rexx "$tmp/checkswitch.rexx" oidtarget)
echo "$oidtarget" | grep -q 'SWITCH PREFLIGHT SAFE MAPPED 1'
unmapped=$(rexx "$tmp/checkswitch.rexx" unmapped)
echo "$unmapped" | grep -q 'SWITCH PREFLIGHT SAFE UNMAPPED 0'
for mode in staged dirty missingfile currentstale changed missingpath stale; do
 if rexx "$tmp/checkswitch.rexx" "$mode" >"$tmp/$mode"; then
  echo "unsafe switch preflight unexpectedly passed: $mode" >&2
  exit 1
 else
  rc=$?
  [ "$rc" -eq 8 ]
 fi
done
grep -q 'staged changes block branch switch' "$tmp/staged"
grep -q 'modified workfile blocks branch switch' "$tmp/dirty"
grep -q 'missing mapped file blocks branch switch' "$tmp/missingfile"
grep -q 'worktree base is stale against current branch' "$tmp/currentstale"
grep -q 'destination changes mapped path' "$tmp/changed"
grep -q 'destination changes mapped path' "$tmp/missingpath"
grep -q 'symbolic HEAD changed during switch preflight' "$tmp/stale"
echo 'M219 SOURCE-DERIVED WORKTREE SWITCH PREFLIGHT/PATH FIXTURES PASS 12'
)
exit $?
fi

# Test atomic create-and-switch behavior through the exact updater branch.
if [ "${1:-}" = "M220" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M219
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GIT.EXEC" "$root/src/GITUPD.EXEC" \
 "$root/src/GITWT.EXEC" "$tmp/createhead.rexx" <<'PY'
from pathlib import Path
import sys
git=Path(sys.argv[1]).read_text()
upd=Path(sys.argv[2]).read_text()
wt=Path(sys.argv[3]).read_text()
out=Path(sys.argv[4])
switch_at=git.index("if command = 'SWITCH' then do")
route=git[switch_at:git.index("/* M5D integration boundary",switch_at)]
for token in ("switchmode='-C' | switchmode='--CREATE'",
              "Usage: GIT SWITCH -c|--create name [start-point]",
              "if startpoint='' then startpoint='HEAD'",
              "call resolvestart startpoint",
              "EXEC GITUPD CREATE-HEAD refs/heads/"):
    if token not in route:
        raise SystemExit(f'M220 switch router missing {token}')
assert route.index("GITVREF HEAD") < route.index("GITUPD CREATE-HEAD")
ustart=upd.index("if ref='CREATE-HEAD' then do")
uend=upd.index("/* HEAD changes require",ustart)
block=upd[ustart:uend]
for token in ("branch already exists", "call requirecommit targetoid",
              "call checkswitch oldhead,targetoid", "call writerefs",
              "branch creation readback mismatch", "call restore",
              "HEAD CREATED"):
    if token not in block:
        raise SystemExit(f'M220 updater missing atomic guard {token}')
if block.index('call checkswitch oldhead,targetoid') > block.index('call writerefs'):
    raise SystemExit('M220 writes REF2 before destination preflight')
helper=upd[upd.index('checkswitch:\n'):upd.index('validref:\n',upd.index('checkswitch:\n'))]
if 'parse arg csold,csnew' not in helper:
    raise SystemExit('M220 preflight helper may overwrite caller state')
if "length(targetref)=40" not in wt:
    raise SystemExit('GITWT does not accept a pinned destination commit')
fixture=(
    "parse arg mode\nreadcalls=0\nwritten=0\n"
    "ref='CREATE-HEAD'\nnewoid='refs/heads/new/topic'\n"
    "oldoid='refs/heads/main'\nextra='HEAD'\n"
    "if mode='sameoid' then extra='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
    "if mode='different' | mode='unsafe' | mode='race' then,\n"
    " extra='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'\n"
    "if mode='invalid' then extra='short'\n"
    +block+
    "exit 99\n"
    "validref:\n parse arg vr\n"
    " if left(vr,11)='refs/heads/' then return 'OK'\n"
    " return 'ERROR'\n"
    "readrefs:\n"
    " readcalls=readcalls+1\n"
    " headref='refs/heads/main'\n"
    " if mode='stale' then headref='refs/heads/other'\n"
    " if mode='race' & readcalls>1 then headref='refs/heads/other'\n"
    " refcount=1\nrefname.1='refs/heads/main'\n"
    " refoid.1='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
    " if mode='existing' then do\n"
    "  refcount=2\nrefname.2='refs/heads/new/topic'\n"
    "  refoid.2=refoid.1\nend\n"
    " if written=1 then do\n"
    "  refcount=2\nrefname.2='refs/heads/new/topic'\n"
    "  refoid.2=storedtarget\nheadref=storedhead\nend\n"
    " rr.0=3\nrr.1='REF2 1'\nrr.2='HEAD '||headref\n"
    " rr.3='REF refs/heads/main '||refoid.1\n"
    " if refcount=2 then do\nrr.0=4\n"
    "  rr.4='REF refs/heads/new/topic '||refoid.2\nend\n"
    " return 'OK'\n"
    "requirecommit:\n return 'OK'\n"
    "checkswitch:\n say 'SIMULATED SWITCH PREFLIGHT'\n"
    " if mode='unsafe' then return 'ERROR'\nreturn 'OK'\n"
    "writerefs:\n"
    " if mode='writefail' then return 'ERROR'\n"
    " storedhead=headref\nstoredtarget=refoid.refcount\nwritten=1\n"
    " say 'SIMULATED WRITE'\nreturn 'OK'\n"
    "restore:\n written=0\nstoredhead='refs/heads/main'\n"
    " say 'SIMULATED RESTORE'\nreturn 'OK'\n"
)
out.write_text(fixture)
PY
rexx -c "$tmp/createhead.rexx" /dev/null
created=$(rexx "$tmp/createhead.rexx" head)
echo "$created" | grep -q 'HEAD CREATED refs/heads/new/topic AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
if echo "$created" | grep -q 'SIMULATED SWITCH PREFLIGHT'; then
 echo 'same-tip create unexpectedly required a worktree transition' >&2
 exit 1
fi
sameoid=$(rexx "$tmp/createhead.rexx" sameoid)
echo "$sameoid" | grep -q 'HEAD CREATED refs/heads/new/topic AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
different=$(rexx "$tmp/createhead.rexx" different)
echo "$different" | grep -q 'HEAD CREATED refs/heads/new/topic BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
echo "$different" | grep -q 'SIMULATED SWITCH PREFLIGHT'
for mode in unsafe existing stale race writefail invalid; do
 if rexx "$tmp/createhead.rexx" "$mode" >"$tmp/$mode"; then
  echo "unsafe create-and-switch unexpectedly succeeded: $mode" >&2
  exit 1
 else
  rc=$?
  case "$mode" in invalid) [ "$rc" -eq 4 ] ;; *) [ "$rc" -eq 8 ] ;; esac
 fi
done
grep -q 'destination worktree preflight failed' "$tmp/unsafe"
grep -q 'branch already exists' "$tmp/existing"
grep -q 'stale symbolic HEAD for branch creation' "$tmp/stale"
grep -q 'symbolic HEAD changed during branch creation' "$tmp/race"
grep -q 'SIMULATED RESTORE' "$tmp/writefail"
grep -q 'invalid branch start commit OID' "$tmp/invalid"
for mode in unsafe existing stale race writefail; do
 if grep -q 'SIMULATED WRITE' "$tmp/$mode"; then
  echo "rejected create-and-switch wrote REF2: $mode" >&2
  exit 1
 fi
done
echo 'M220 SOURCE-DERIVED CREATE-AND-SWITCH FIXTURES PASS 9'
)
exit $?
fi

# Check safe revision-name resolution for switch -c start points.
if [ "${1:-}" = "M221" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M220
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GIT.EXEC" "$tmp/resolvestart.rexx" <<'PY'
from pathlib import Path
import sys
source=Path(sys.argv[1]).read_text()
start=source.index('resolvestart: procedure expose rs.')
end=source.index('\nqueryref:',start)
routine=source[start:end]
for token in ("if wanted='HEAD'", "length(direct)=40",
              "startchars=startchars||'0123456789._/-'",
              "call queryref wanted"):
    if token not in source:
        raise SystemExit(f'M221 start resolver missing validation: {token}')
assert source.index('verify(wanted,startchars)') < source.index('call queryref wanted')
qstart=source.index('queryref: procedure expose rs.')
qend=source.find('\n',source.index("'PIPE CMS' cmd '| STEM RS.'",qstart))
assert qend>qstart
fixture=(
    "parse arg mode wanted\nrs.0=0\n"
    "call resolvestart wanted\n"
    "if rs.0=0 then say 'RESOLVED' result 'QUERY'\n"
    "else say 'RESOLVED' result 'QUERY' word(rs.1,3)\nexit 0\n"
    +routine+
    "queryref:\n parse arg qspec\ndrop rs.\nrs.0=0\n"
    " if qspec='main' then rs.1='VERIFIED REF main AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
    " else if qspec='release/1' then rs.1='VERIFIED REF release/1 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'\n"
    " else if qspec='refs/tags/v1' then rs.1='VERIFIED REF refs/tags/v1 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'\n"
    " else if qspec='multiple' then rs.1='VERIFIED REF multiple AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
    " else if qspec='badrecord' then rs.1='VERIFIED TAG badrecord CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'\n"
    " else return 'ERROR'\n"
    " if qspec='multiple' then do\nrs.2=rs.1\nrs.0=2\nend\n"
    " else rs.0=1\nreturn 'OK'\n"
)
Path(sys.argv[2]).write_text(fixture)
PY
rexx -c "$tmp/resolvestart.rexx" /dev/null
check() {
 expected=$1
 wanted=$2
 shift 2
 actual=$(rexx "$tmp/resolvestart.rexx" "$@" "$wanted")
 if [ "$actual" != "$expected" ]; then
  echo "start-point $wanted: expected $expected, got $actual" >&2
  exit 1
 fi
}
check 'RESOLVED HEAD QUERY' HEAD clean
check 'RESOLVED CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC QUERY' CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC clean
check 'RESOLVED AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA QUERY main' main clean
check 'RESOLVED BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB QUERY release/1' release/1 clean
check 'RESOLVED BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB QUERY refs/tags/v1' refs/tags/v1 clean
check 'RESOLVED ERROR QUERY' missing clean
check 'RESOLVED ERROR QUERY' 'bad|input' clean
check 'RESOLVED ERROR QUERY badrecord' badrecord badrecord
check 'RESOLVED ERROR QUERY multiple' multiple clean
echo 'M221 SOURCE-DERIVED SWITCH START-POINT RESOLUTION FIXTURES PASS 9'
)
exit $?
fi

# Test compare-and-swap branch rename and current-HEAD preservation/update.
if [ "${1:-}" = "M222" ]; then
(
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$0" M221
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
python3 - "$root/src/GIT.EXEC" "$root/src/GITUPD.EXEC" \
 "$tmp/moveref.rexx" <<'PY'
from pathlib import Path
import sys
git=Path(sys.argv[1]).read_text()
upd=Path(sys.argv[2]).read_text()
route_at=git.index("if command = 'BRANCH' then do")
route=git[route_at:git.index("/* M5D integration boundary",route_at)]
for token in ("if brancharg1='-m' | verb='--MOVE' then do",
              'call resolvestart brancharg2',
              "EXEC GIT UPDATE-REF MOVE-REF' oldref newref expectedoid",
              'brancharg4\\=\'\''):
    if token not in route:
        raise SystemExit(f'M222 branch router missing {token}')
if "brancharg1='-M'" in route:
    raise SystemExit('M222 accidentally enables force rename')
start=upd.index("if ref='MOVE-REF' then do")
end=upd.index("/* Atomically create a branch ref",start)
block=upd[start:end]
for token in ('currentoid\\=expectedoid', 'destination branch already exists',
              'if headref=oldref then headref=newref',
              'branch rename readback mismatch', 'call restore',
              "say 'RENAMED' oldref newref expectedoid"):
    if token not in block:
        raise SystemExit(f'M222 updater missing CAS guard {token}')
block=block.replace(
    " say 'RENAMED' oldref newref expectedoid\n exit 0",
    " say 'RENAMED' oldref newref expectedoid\n"
    " say 'TEST HEAD' headref\n exit 0",
)
fixture=(
    "parse arg mode\nreadcalls=0\nwritten=0\n"
    "ref='MOVE-REF'\nnewoid='refs/heads/topic'\n"
    "oldoid='refs/heads/renamed'\nextra='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'\n"
    +block+
    "exit 99\n"
    "validref:\n parse arg vr\n"
    " if left(vr,11)='refs/heads/' then return 'OK'\n"
    " return 'ERROR'\n"
    "readrefs:\n"
    " readcalls=readcalls+1\n"
    " headref='refs/heads/main'\n"
    " if mode='current' then headref='refs/heads/topic'\n"
    " if written=1 then do\n"
    "  headref=storedhead\nrefcount=2\n"
    "  refname.1='refs/heads/main'\n"
    "  refoid.1='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
    "  refname.2='refs/heads/renamed'\nrefoid.2=storedoid\n"
    " end\nelse do\n"
    "  refcount=2\nrefname.1='refs/heads/main'\n"
    "  refoid.1='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'\n"
    "  refname.2='refs/heads/topic'\n"
    "  refoid.2='BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'\n"
    "  if mode='stale' then,\n"
    "   refoid.2='CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'\n"
    "  if mode='missing' then refcount=1\n"
    "  if mode='exists' then do\nrefcount=3\n"
    "   refname.3='refs/heads/renamed'\n"
    "   refoid.3='CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'\nend\n"
    " end\n"
    " rr.0=2+refcount\nrr.1='REF2 1'\nrr.2='HEAD '||headref\n"
    " do ri=1 to refcount\nrri=ri+2\n"
    "  rr.rri='REF ' refname.ri refoid.ri\nend\n"
    " return 'OK'\n"
    "requirecommit:\n return 'OK'\n"
    "writerefs:\n"
    " if mode='writefail' then return 'ERROR'\n"
    " storedhead=headref\nstoredoid=refoid.oldslot\n"
    " if mode='corrupt' then storedoid='DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD'\n"
    " written=1\nsay 'SIMULATED WRITE'\nreturn 'OK'\n"
    "restore:\n written=0\nsay 'SIMULATED RESTORE'\nreturn 'OK'\n"
)
Path(sys.argv[3]).write_text(fixture)
PY
rexx -c "$tmp/moveref.rexx" /dev/null
noncurrent=$(rexx "$tmp/moveref.rexx" noncurrent)
echo "$noncurrent" | grep -q 'RENAMED refs/heads/topic refs/heads/renamed BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
echo "$noncurrent" | grep -q 'TEST HEAD refs/heads/main'
current=$(rexx "$tmp/moveref.rexx" current)
echo "$current" | grep -q 'TEST HEAD refs/heads/renamed'
for mode in missing stale exists writefail corrupt; do
 if rexx "$tmp/moveref.rexx" "$mode" >"$tmp/$mode"; then
  echo "invalid branch rename unexpectedly succeeded: $mode" >&2
  exit 1
 else
  rc=$?
  [ "$rc" -eq 8 ]
 fi
done
grep -q 'stale or missing branch' "$tmp/missing"
grep -q 'stale or missing branch' "$tmp/stale"
grep -q 'destination branch already exists' "$tmp/exists"
grep -q 'SIMULATED RESTORE' "$tmp/writefail"
grep -q 'branch rename readback mismatch' "$tmp/corrupt"
grep -q 'SIMULATED RESTORE' "$tmp/corrupt"
for mode in missing stale exists writefail; do
 if grep -q 'SIMULATED WRITE' "$tmp/$mode"; then
  echo "rejected branch rename wrote REF2: $mode" >&2
  exit 1
 fi
done
echo 'M222 SOURCE-DERIVED REF2 BRANCH RENAME FIXTURES PASS 7'
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
