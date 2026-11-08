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
assert "GHCRED REPO A not found" in PUSH
assert "STATE GHCRED REPO A" in PUSH
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

# GITGC pack naming and prune/repack semantics.
assert "PACK'||right(packnum,4,'0')" in GC
assert "if cmd='GC' & prune=1 then do" in GC
assert "isreach=0" in GC
assert "'ERASE' objfn 'GITOBJ' objectfm" in GC
assert "if cmd='REPACK' & repack_delete=1 then do" in GC
assert "'STATE' packfn 'PACK' objectfm" in GC
for line in GC.splitlines():
    if "ERASE" in line and "GITREF" in line:
        raise SystemExit("GITGC must not erase refs: " + line)

# 80-column checks.
for src, name in ((GIT, "GIT.EXEC"), (PUSH, "GITPUSH"), (GC, "GITGC"),
                  (REMOT, "GITREMOT"), (CRED, "GITCRED")):
    for number, line in enumerate(src.splitlines(), 1):
        if len(line) > 80:
            raise SystemExit("%s line %d exceeds 80 columns (%d)" % (name, number, len(line)))

# Credential import surface.
assert "GHCRED" in CRED

print("M281 PUSH AND M282 GC/REPACK HOST SOURCE GUARDS PASS")