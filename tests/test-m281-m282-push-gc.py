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
IMP = (ROOT / "src" / "GITIMP.EXEC").read_text()
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

# Advertised remote tips are excluded from the local closure walk so a
# shallow repository never needs objects only reachable through them.
assert "remotehave.0=0" in PUSH
assert "remotehave.remotehavex=rhold" in PUSH
assert "if translate(current)=remotehave.rhi then do" in PUSH
assert PUSH.index("remotehave.0=0") < PUSH.index("call walk_commit localtip")

# Large packs are coalesced before Socket('Send'); a per-record send costs
# minutes on CMS and lets the peer time out mid-upload.
assert "bufhex=bufhex||phrec" in PUSH
assert "length(bufhex)>=65536" in PUSH
assert "call sendpackbuf" in PUSH
assert "sendpackbuf: procedure expose s" in PUSH
assert "boff=boff+bsent" in PUSH
assert "rawrec=x2c(phrec)" not in PUSH

# A ref-only update (target already on the remote under another ref) must
# not be rejected just because the local closure walk found nothing new.
assert "zeroobj=1" in PUSH
assert "no new objects; building empty pack" in PUSH
assert "no objects to push" not in PUSH
assert "if zeroobj=1 then do" in PUSH
# A ref-only update sends the canonical zero-object pack, computed here
# independently so a stale or mistyped trailer cannot pass.
import hashlib
hdr = b"PACK" + (2).to_bytes(4, "big") + (0).to_bytes(4, "big")
expected = (hdr + hashlib.sha1(hdr).digest()).hex().upper()
packed = "".join(
    line.strip().strip("'").strip(",")
    for line in PUSH.splitlines()
    if "5041434B0000000200000000" in line or "029D0882" in line)
assert "5041434B0000000200000000" in PUSH
assert expected[24:] in packed.replace("||", ""), (expected, packed)

# Tracking updates preserve the configured remote spelling and the current
# HEAD; duplicate HEAD records are collapsed instead of appended.
assert "remote=strip(remote)" in PUSH
assert "remote=word(REMOTEREC.ri,2)" in PUSH
assert "newrefs.2='HEAD '||localbranch" not in PUSH
assert "if headwritten=0 then do" in PUSH
assert "REF2 has no HEAD record" in PUSH
assert "newrefs.newrefcount='HEAD '||word(REF2UPD.ri,2)" in PUSH
assert "newrefs.newrefcount='HEAD '||translate" not in PUSH
assert "newrefs.newrefcount='REF ' refname3 ' ' refval3" in PUSH
assert "refval3=translate(word(REF2UPD.ri,3))" in PUSH
assert PUSH.index("refval3=translate") < PUSH.index(
    "newrefs.newrefcount='REF ' refname3")

# Response bodies often arrive in a later TCP segment than the headers;
# the push HTTP feeder must route BODY state to the body parser.
start = PUSH.index("httpfeed_push:")
end = PUSH.index("httpfeed_push_body:", start)
feeder = PUSH[start:end]
assert "if hstate='BODY' then do" in feeder
assert "call httpfeed_push_body hx" in feeder
assert "if hstate\\='BODY' then do" not in feeder
# report-status must be requested with a properly LF-terminated pkt-line.
assert "datahex=datahex||result||'0A'" in PUSH

# A fast-forward proof failure (including a shallow local history that
# cannot reach the remote tip) must refuse, not push optimistically.
assert "cannot prove fast-forward; remote tip is not in" in PUSH
assert "refusing non-fast-forward update" in PUSH
assert "ancestry check failed" not in PUSH

# Credential requirement and no credential echoing.
assert "valid GitHub credential required for push" in PUSH
assert "STATE GHCRED REPO G" in PUSH
assert "STATE GITMETA REPO G" in PUSH
assert "STATE GITREMOT REPO G" in PUSH
assert "DISKR GITREF2 REPO G" in PUSH
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
assert "'STATE' packfn 'PACK' objectfm" in GC
assert "if cmd='GC' & prune=1 & packlimit>0 then do" in GC
assert "LIMIT cannot be combined with --prune=now" in GC
assert "if opt='-D' then do" in GC
assert "-d is disabled; packed objects are not readable yet" in GC
assert "if opt='-A' then do" in GC
assert "-a is not implemented" in GC
assert "if opt='--AGGRESSIVE' then do" in GC
assert "--aggressive is not implemented" in GC
assert "repack_delete" not in GC
assert "repack_all" not in GC
assert "if cmd='REPACK' & repack_delete=1 then do" not in GC
first_repo_read = GC.index("'STATE GITMETA REPO G'")
for guard in (
    "LIMIT cannot be combined with --prune=now",
    "-d is disabled; packed objects are not readable yet",
    "-a is not implemented",
    "--aggressive is not implemented",
):
    assert GC.index(guard) < first_repo_read, guard
assert "deleting packed loose objects" not in GC

# GITIMP must resolve the configured object disk instead of assuming A.
assert "'STATE GITMETA REPO G'" in IMP
assert "objectfm=translate(word(impmeta.mi,2))" in IMP
assert "'STATE' objfn 'GITOBJ' objectfm" in IMP
assert "'DISKW' objfn 'GITOBJ' objectfm" in IMP
assert "'ERASE' objfn 'GITOBJ' objectfm" in IMP
assert "'GITOBJ A'" not in IMP

# Bounded validation: LIMIT=n truncates the reachable closure before packing,
# and cannot enable pruning of objects omitted from that partial pack.
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
assert "'STATE GITPMKC MODULE G'" in GC
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


# M281 pack-build: literal OBJSTG STAGE, numeric type codes, single DISKW.
assert "stagefn='OBJSTG'" in PUSH
assert "if objtype='COMMIT' then objcode=1" in PUSH
assert "else if objtype='TREE' then objcode=2" in PUSH
assert "else if objtype='BLOB' then objcode=3" in PUSH
assert "else if objtype='TAG' then objcode=4" in PUSH
assert "stgout.sn='OBJ' objcode objsize oidcur" in PUSH
assert "'EXECIO' sn 'DISKW' stagefn 'STAGE' objectfm '1 (STEM STGOUT. FINIS'" in PUSH
assert "DISKW' stagefn 'STAGE' objectfm||' 1 (STEM STGOUT. FINIS'" not in PUSH

# M281 pack-build: prefer native GITPMKC HEX, fallback REXX GITPMK BUILD.
assert "'STATE GITPMKC MODULE G'" in PUSH
assert "'GITPMKC BUILD HEX'" in PUSH
assert "(RECFM V LRECL 255" in PUSH
assert "'RENAME OBJOUT STAGE' objectfm pack 'PACK' objectfm" in PUSH

# M281 receive-pack body: pkt framing via toasciihex, report-status,
# Content-Length/User-Agent; pack bytes appended as raw hex (no word(,2),
# no toasciihex of packhex).
assert "report-status" in PUSH
assert "call toasciihex 'Content-Length: '" in PUSH
assert "call toasciihex 'User-Agent: git/cms-git'" in PUSH
assert ("cmdtxt=oldoid||' '||localtip||' '||localbranch" in PUSH or
        "cmdtxt=translate(oldoid" in PUSH)
assert "toasciihex ' report-status" in PUSH or "toasciihex 'report-status'" in PUSH
# pack bytes sent as raw hex from records (streamed), no toasciihex/word(,2)
assert "toasciihex packhex" not in PUSH
assert "word(PACKHEX.pi,2)" not in PUSH
assert "strip(translate(PACKHEX.pi))" in PUSH
assert "x2c(wire)" in PUSH

# M281 response: chunk+pkt reassembly for report-status.
assert "pktfeed_push:" in PUSH
assert "call pktfeed_push cpiece" in PUSH
assert "call pktlen substr(line,1,8)" in PUSH

print("M281 PUSH AND M282 GC/REPACK HOST SOURCE GUARDS PASS")
