#!/usr/bin/env python3
"""M306: one repository per selected CMS minidisk, with runtime on G."""
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
GIT = (ROOT / "src" / "GIT.EXEC").read_text()
WT = (ROOT / "src" / "GITWT.EXEC").read_text()
VREF = (ROOT / "src" / "GITVREF.EXEC").read_text()
UPD = (ROOT / "src" / "GITUPD.EXEC").read_text()
REMOT = (ROOT / "src" / "GITREMOT.EXEC").read_text()
FETCH = (ROOT / "src" / "GITFETCH.EXEC").read_text()
POST = (ROOT / "src" / "GITPOST.EXEC").read_text()
FPACK = (ROOT / "src" / "GITFPACK.EXEC").read_text()
FIMP = (ROOT / "src" / "GITFIMP.EXEC").read_text()
FACT = (ROOT / "src" / "GITFACT.EXEC").read_text()
PUSH = (ROOT / "src" / "GITPUSH.EXEC").read_text()
GC = (ROOT / "src" / "GITGC.EXEC").read_text()

for source in (GIT, WT, VREF, UPD, REMOT, FETCH, POST, FPACK, PUSH, GC):
    assert "objectfm='G'" in source or "objectfm = 'G'" in source
    assert re.search(r"if .*'--FM' then do", source)
    assert "verify(objectfm,'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" in source
    assert "objectfm='D'" in source and "objectfm='S'" in source

for source in (VREF, UPD, REMOT, FETCH, POST, FPACK, PUSH, GC):
    assert "parse arg . objectfm" in source
    assert "parse var rest objectfm" not in source
for source in (FETCH, POST, PUSH):
    assert "authheader: procedure expose objectfm" in source
assert "queryref: procedure expose rs. objectfm" in GIT
assert "EXEC GITUPD'" not in GIT
assert "ll_vcmd='EXEC GIT --FM' ll_ofm 'VERIFY-OBJECT'" in VREF
assert "verifycmd='EXEC GIT --FM' objectfm," in WT

# Repository selection is explicit; clone never guesses production G.
clone = GIT.split("if command='CLONE' then do", 1)[1].split("\nend\n", 1)[0]
assert "if clonefm='' then clonefm='G'" not in clone
assert "call checkrepotarget objectfm" in clone
assert "repository-filemode" in clone
assert "clonetarget=clonebranch" in clone
assert "if clonetarget='' then clonetarget='HEAD'" in clone
assert "   clonebranch=''\n" not in clone
assert "180000 free blocks" in GIT
assert "verify(targetfm,'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" in GIT
assert "targetfm='D'" in GIT and "targetfm='S'" in GIT
for name in (
    "GITMETA REPO", "GITREF2 REPO", "GITREMOT REPO", "GITWORK REPO",
    "GITMERG MERGE", "GITMODE REPO", "GITPACKS REPO", "GITREFS REPO",
    "GHCRED REPO", "GHTOKEN REPO", "GHPASS REPO", "GITTREE REPO",
    "GITMRG BLOB",
):
    assert f"'{name}'" in GIT

# Runtime/application support stays on G; repository data follows objectfm.
assert "'STATE GITBRIDG CONFIG G'" in GIT
assert "'EXECIO * DISKR GITBRIDG CONFIG G 1" in GIT
for source in (FPACK, FIMP, FACT, PUSH, GC):
    assert "MODULE G" in source
for source in (GIT, WT, VREF, UPD, REMOT, POST):
    scanned = source
    if source is GIT:
        scanned = source[:source.index("head_validbranch:")] + source[
            source.index("/* M293: inlined GITCRED"):]
    for pattern in (
        "GITMETA REPO G", "GITREF2 REPO G", "GITREMOT REPO G",
        "GITWORK REPO G", "GITMERG MERGE G", "GITMODE REPO G",
        "GITPACKS REPO G", "GITREFS REPO G", "GHCRED REPO G",
    ):
        assert pattern not in scanned, (pattern, source[:40])

# Non-G repository workfiles stay on their selected disk; legacy G uses A.
assert "if objectfm='G' then workfm='A'" in WT
assert "call writework addfn.ak,addft.ak,workfm" in WT
assert "call workoid addfn.ak,addft.ak,workfm,pulladdfin.ni,0" in WT
assert "mapfm.newindex=workfm" in WT
assert "call findfile afn,aft,workfm" in WT
assert "'STATE' afn aft workfm" in WT

# A non-G repository must never fall back to protected native G fixtures.
assert "if objectfm\\='G' then return 'ERROR'" in VREF
assert "if objectfm\\='G' then return 'ERROR'" in VREF.split("objectdisk:", 1)[1]

# Import/activation accept any valid non-D/S filemode; modules stay on G.
for source in (FIMP, FACT):
    assert "verify(datafm,'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" in source
    assert "datafm='D'" in source and "datafm='S'" in source
assert "'STATE GITPCHK MODULE G'" in FIMP
assert "'STATE GITPIMP MODULE G'" in FIMP
assert "'STATE' module 'MODULE G'" in FACT
assert "M274L5 BATCH' datafm objectcount" in FACT

for name, source in (
    ("GIT.EXEC", GIT), ("GITWT.EXEC", WT), ("GITVREF.EXEC", VREF),
    ("GITUPD.EXEC", UPD), ("GITREMOT.EXEC", REMOT),
    ("GITFETCH.EXEC", FETCH), ("GITPOST.EXEC", POST),
    ("GITFPACK.EXEC", FPACK), ("GITFIMP.EXEC", FIMP),
    ("GITFACT.EXEC", FACT), ("GITPUSH.EXEC", PUSH), ("GITGC.EXEC", GC),
):
    for number, line in enumerate(source.splitlines(), 1):
        assert len(line) <= 80, f"{name}:{number} exceeds 80 columns"
    subprocess.run(["rexx", "-c", str(ROOT / "src" / name), "/dev/null"],
                   check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

print("M306 REPOSITORY FILEMODE HOST GUARDS PASS")
