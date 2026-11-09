#!/usr/bin/env python3
"""M281/M282: host source guards for GIT PUSH and GIT GC/REPACK.

No live remote is contacted.  These checks verify routing, safety
invariants, and structural properties of the CMS EXEC sources.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
GIT = (ROOT / "src" / "GIT.EXEC").read_text()
PUSH = (ROOT / "src" / "GITPUSH.EXEC").read_text()
GC = (ROOT / "src" / "GITGC.EXEC").read_text()
REMOT = (ROOT / "src" / "GITREMOT.EXEC").read_text()
CRED = (ROOT / "src" / "GITCRED.EXEC").read_text()

# Routing in GIT.EXEC.
assert "if command = 'REMOTE' then do" in GIT
assert "address command 'EXEC GITREMOT' rest" in GIT
assert "if command = 'CREDENTIAL' then do" in GIT
assert "address command 'EXEC GITCRED' rest" in GIT
assert "if command = 'GC' | command = 'REPACK' then do" in GIT
assert "'EXEC GITGC' command rest" in GIT
assert "'EXEC GITPUSH' rest" in GIT

# GITPUSH routes through GITPMK BUILD and git-receive-pack.
assert "EXEC GITPMK BUILD" in PUSH
assert "git-receive-pack" in PUSH
assert "info/refs?service=git-receive-pack" in PUSH

# Credential requirement and no credential echoing.
assert "valid GitHub credential required for push" in PUSH
assert "STATE GHCRED REPO A" in PUSH
assert "Authorization: Basic" in PUSH
assert "Bearer" not in PUSH

# Discovery must be authenticated and use receive-pack advertisement.
assert "call authheader" in PUSH
assert "application/x-git-receive-pack-advertisement" in PUSH
assert "application/x-git-upload-pack-advertisement" not in PUSH
for src, name in ((PUSH, "GITPUSH"), (CRED, "GITCRED")):
    for line in src.splitlines():
        if "say" not in line.lower():
            continue
        stripped = re.sub(r"'[^']*'", "", line)
        low = stripped.lower()
        if any(w in low for w in ("token", "secret", "password", "apikey", "api key")):
            raise SystemExit(name + " echoes a secret: " + line)

# Fast-forward / ancestry refusal.
assert "ANCESTOR YES" in PUSH
assert "not a fast-forward; remote has diverged" in PUSH
assert "GITVREF IS-ANCESTOR" in PUSH

# Reachability walk is defined and invoked.
assert "walk_commit:" in PUSH
assert "walk_tree:" in PUSH
assert "call walk_commit localtip" in PUSH
assert "call walk_tree treeoid" in PUSH
assert "call walk_tree treeoid" in GC

# Commit body parsing decodes the 80-column hex-encoded ASCII OID.
for src, name in ((PUSH, "GITPUSH"), (GC, "GITGC")):
    # Commit OIDs are ASCII hex text; decode via asciitocms (X2C alone
    # yields EBCDIC code points), not bare substring or x2c.
    assert "call asciitocms substr(cdata,treepos+10,80)" in src
    assert "call asciitocms substr(cdata,ppos+14,80)" in src
    assert "treeoid=translate(result)" in src
    assert "poid=translate(result)" in src
    assert "ppos=ppos+96" in src
    assert "translate(x2c(substr(cdata,treepos+10,80)))" not in src
    assert "translate(x2c(substr(cdata,ppos+14,80)))" not in src
    assert "substr(cdata,treepos+10,40)" not in src
    assert "substr(cdata,ppos+14,40)" not in src
    assert "asciitocms: procedure" in src

# REXX resolves stem.stem.0 as a distinct compound variable, not stem.<n>,
# so object queues must index through an explicit counter variable.
FACT = (ROOT / "src" / "GITFACT.EXEC").read_text()
for src, name in ((PUSH, "GITPUSH"), (GC, "GITGC"), (FACT, "GITFACT")):
    bad = re.findall(r"(?m)^[ \t]*([A-Za-z_]\w*)\.\1\.0=", src)
    assert not bad, (name, bad)

# GITGC pack naming and prune/repack semantics.
assert "PACK'||right(packnum,4,'0')" in GC
assert "if cmd='GC' & prune=1 then do" in GC
assert "isreach=0" in GC
assert "'ERASE' objfn 'GITOBJ' objectfm" in GC
assert "if cmd='REPACK' & repack_delete=1 then do" in GC
assert "'STATE' packfn 'PACK' objectfm" in GC

# Bounded validation: LIMIT=n truncates the reachable closure before packing.
assert "if left(opt,6)='LIMIT='" in GC
assert "objlist.0=packlimit" in GC
assert "LIMIT active; packing" in GC

# Pack staging contract: text type codes, OBJSTG handoff, hex OBJOUT
# promoted to PACKnnnn, and staging cleanup.
assert "stagefn='OBJSTG'" in GC
assert "if objtype='COMMIT' then objcode=1" in GC
assert "else if objtype='TREE' then objcode=2" in GC
assert "else if objtype='BLOB' then objcode=3" in GC
assert "else if objtype='TAG' then objcode=4" in GC
assert "stgout.sn='OBJ' objcode objsize oidcur" in GC
assert "'EXEC GITPMK BUILD' objectfm" in GC
assert "'RENAME OBJOUT STAGE' objectfm packfn 'PACK' objectfm" in GC
assert "'ERASE' stagefn 'STAGE' objectfm" in GC

# Prefer the native GITPMKC module when present, falling back to REXX.
assert "'STATE GITPMKC MODULE A'" in GC
assert "nativepmk=(rc=0)" in GC
assert "'GITPMKC BUILD HEX'" in GC
assert "(RECFM V LRECL 255" in GC
for line in GC.splitlines():
    if "ERASE" in line and "GITREF" in line:
        raise SystemExit("GITGC must not erase refs: " + line)

# REF2 header validation must compare a single word to a single word.
assert "word(REF2.1,1)\\='REF2'" in PUSH
assert "word(REF2.1,1)\\='REF2'" in GC
assert "word(REF2.1,2)\\='1'" in PUSH
assert "word(REF2.1,2)\\='1'" in GC
assert "word(REF2.1,1)\\='REF2 1'" not in PUSH
assert "word(REF2.1,1)\\='REF2 1'" not in GC

# 80-column checks.
for src, name in ((GIT, "GIT.EXEC"), (PUSH, "GITPUSH"), (GC, "GITGC"),
                  (REMOT, "GITREMOT"), (CRED, "GITCRED")):
    for number, line in enumerate(src.splitlines(), 1):
        if len(line) > 80:
            raise SystemExit("%s line %d exceeds 80 columns (%d)" % (name, number, len(line)))

# Credential import surface.
assert "GHCRED" in CRED

print("M281 PUSH AND M282 GC/REPACK HOST SOURCE GUARDS PASS")