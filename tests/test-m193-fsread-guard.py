#!/usr/bin/env python3
"""M193 assembler static guardrails and host stage record-number parity.

This does NOT assemble FSREAD macros or prove their operation on CMS.
"""
from pathlib import Path
import hashlib
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
ASM = ROOT / "src/GITFSRD.ASSEMBLE"
REXX = ROOT / "src/GITFSP.EXEC"
IDX = ROOT / "src/GITPIDX.C"
MODEL = ROOT / "src/GITRCNM.C"

asm = ASM.read_text()
ex = REXX.read_text()
lines = asm.splitlines()
assert all(len(row) <= 72 for row in lines)
continuations = [row for row in lines if row.endswith("X")]
assert len(continuations) == 2, continuations
assert all(len(row) == 72 for row in continuations)
for fragment in ("LINERD DATA=(SELECT,8),TYPE=STACK",
                 "FSREAD 'M173NET STAGE G1',BUFFER=RECBUF,BSIZE=64",
                 "RECFM=V,RECNO=(5),NOREC=1,FORM=E,ERROR=RDERR",
                 "FSCLOSE 'M173NET STAGE G1',ERROR=CLERR",
                 "M193 FSREAD RETURNED",
                 "M193 READ ONLY FSREAD PROBE PASS",
                 "CLC   RECBUF(6),=C'OBJ 1 '",
                 "CLC   RECBUF(9),=C'OBJ 3868 '",
                 "CLC   RECBUF(9),=C'OBJ 7736 '"):
    assert fragment in asm, fragment
for forbidden in ("FSWRITE", "FSERASE", "FSPOINT", "OPENTYP=WRITE",
                  "RECFM=F", "FORM=S"):
    assert forbidden not in asm, forbidden
for choice, recno in (("FIRST", 1), ("MID", 1969357),
                      ("LAST", 3864789)):
    assert "=F'%d'" % recno in asm
    assert choice in asm
assert "ST    0,READLEN" in asm
assert "L     0,READLEN" in asm
assert "L     5,=F'1969357'" in asm
assert asm.count("LINEWRT DATA=") >= 9
assert "         END   GITFSRD" in asm
assert not (ROOT / "src/GITFSRD.EXEC").exists()
assert REXX.stem != ASM.stem
assert max(map(len, ex.splitlines())) <= 80
assert "datafm\\='G'" in ex
assert "'STATE GITFSRD MODULE A'" in ex
assert "'GITFSRD'" in ex
assert "'GITFSRD PROBE'" not in ex
assert "queue which" in ex
assert "M193 CMS FSREAD GATE PASS G" in ex
assert "'STATE M173NET STAGE G'" in ex
assert "'STATE M174NET INDEX G'" in ex
assert "'PIPE CMS GITFSRD" not in ex
for forbidden in ("ERASE", "FORMAT ", "FILEDEF STGIN",
                  "FILEDEF IDXIN", "DIRECTXA"):
    assert forbidden not in ex

def oid(body):
    head = ("blob %d" % len(body)).encode() + b"\0"
    return hashlib.sha1(head + body).hexdigest().upper()

def build(path, output):
    subprocess.run(["gcc", "-x", "c", "-std=c89", "-Wall",
                    "-Wextra", "-Werror", str(path), "-o", str(output)],
                   check=True)

with tempfile.TemporaryDirectory(prefix="m193-") as dirname:
    work = Path(dirname)
    idxbin = work / "indexer"
    model = work / "model"
    build(IDX, idxbin)
    build(MODEL, model)
    # Construct 7,736 *unique* Git blobs without huge stage content.
    sizes = []
    rows = []
    recnos = {}
    for i in range(1, 7737):
        n = 0 if i == 1 else 4 + i % 100
        data = (b"" if n == 0 else
                i.to_bytes(4, "big") + bytes([i % 251]) * (n - 4))
        recnos[i] = len(rows) + 1
        sizes.append(n)
        rows.append("OBJ %d 3 %d %s" % (i, n, oid(data)))
        hx = data.hex().upper()
        rows.extend([hx[x:x+64] for x in range(0, len(hx), 64)]
                    if hx else [""])
    stage = work / "dd:STGIN"
    idx = work / "dd:IDXIN"
    stage.write_text("\n".join(rows) + "\n")
    r = subprocess.run([str(idxbin), "BUILD"], cwd=work,
                       text=True, capture_output=True)
    assert r.returncode == 0, r.stdout + r.stderr
    shutil.copy(work / "dd:IDXOUT", idx)
    old = (hashlib.sha256(stage.read_bytes()).hexdigest(),
           hashlib.sha256(idx.read_bytes()).hexdigest())
    r = subprocess.run([str(model), "PLAN", str(len(rows))], cwd=work,
                       text=True, capture_output=True)
    assert r.returncode == 0, r.stdout + r.stderr
    for number in (1, 3868, 7736):
        assert ("M192 RECORD %d RECNO %d OFFSET " %
                (number, recnos[number])) in r.stdout
    assert (hashlib.sha256(stage.read_bytes()).hexdigest(),
            hashlib.sha256(idx.read_bytes()).hexdigest()) == old

print("M193 ASSEMBLER MACRO/REXX STATIC READ-ONLY GUARDS PASS")
print("M193 7736-OBJECT HOST RECORD MODEL INTEGRITY PASS")
print("M193 CMS FSREAD ASSEMBLE/RUNTIME NOT YET VERIFIED")
