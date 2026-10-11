#!/usr/bin/env python3
"""M194 static CMS macro safeguards and synthetic adjacent-body model.

Linux cannot expand IBM CMS FSREAD macros. This is NOT a CMS runtime PASS.
"""
from pathlib import Path
import hashlib
import re

ROOT = Path(__file__).resolve().parents[1]
asm = (ROOT / "src/GITFRB.ASSEMBLE").read_text()
rex = (ROOT / "src/GITFRP.EXEC").read_text()
lines = asm.splitlines()
assert all(len(x) <= 72 for x in lines)
assert all(len(x) <= 80 for x in rex.splitlines())
active = "\n".join(x for x in lines if x and not x.startswith("*"))
assert len([x for x in lines if x.endswith("X")]) == 3
assert all(len(x) == 72 for x in lines if x.endswith("X"))
assert active.count("FSREAD 'M173NET STAGE G1'") == 2
assert active.count("RECFM=V,RECNO=(5),NOREC=1,FORM=E") == 2
assert active.count("FSCLOSE 'M173NET STAGE G1'") == 2
assert "         ST    0,HDRLEN" in asm
assert "         ST    0,BODYLEN" in asm
assert "L     5,HEADNO" in asm
assert "L     5,BODYNO" in asm
assert "M194 FSREAD HEADER RETURNED" in asm
assert "M194 FSREAD BODY RETURNED" in asm
assert "M194 FIRST BODY RECORD HEX PASS" in asm
assert "M194 READ ONLY BODY PROBE PASS" in asm
assert "CLC   HDRBUF(6),=C'OBJ 1 '" in asm
assert "CLC   HDRBUF(9),=C'OBJ 3868 '" in asm
assert "CLC   HDRBUF(9),=C'OBJ 7736 '" in asm
assert "LTR   7,7" in asm and "BZ    BODYOK" in asm
assert "N     6,=F'1'" in asm
assert "C     7,=F'64'" in asm
assert "BCT   7,CHECKCHR" in asm
for selector, header in (("FIRST", 1), ("MID", 1969357),
                         ("LAST", 3864789)):
    assert selector in asm
    assert "=F'%s'" % header in asm
    assert "=F'%s'" % (header + 1) in asm
for forbidden in ("FSWRITE", "FSERASE", "FSPOINT", "OPENTYP=WRITE",
                  "RECFM=F", "FORM=S", "FILEDEF", "fseek"):
    assert forbidden not in active, forbidden
for term in ("'STATE M173NET STAGE G'", "'STATE M174NET INDEX G'",
             "'STATE GITFRB MODULE A'", "'GITFRB'", "queue which",
             "M194 BODY PROBE GATE PASS G"):
    assert term in rex, term
assert "datafm\\='G'" in rex
assert "'PIPE CMS GITFRB" not in rex
for term in ("ERASE", "FORMAT ", "FSWRITE", "FILEDEF STGIN",
             "FILEDEF IDXIN", "DIRECTXA"):
    assert term not in rex, term
assert not (ROOT / "src/GITFRB.EXEC").exists()
assert not (ROOT / "src/GITFRP.ASSEMBLE").exists()

# CMS is EBCDIC. Numeric order is a-f, A-F, 0-9, not ASCII order.
okchars = set("0123456789ABCDEFabcdef")
points = {c: c.encode("cp037")[0] for c in okchars}
assert points["a"] < points["A"] < points["0"]
assert "BNL   DIGIT" in asm and "BNL   UPPER" in asm
assert "CLI   0(6),C'a'" in asm
assert "CLI   0(6),C'A'" in asm
assert "CLI   0(6),C'0'" in asm

def valid_ebcdic_body(raw):
    if len(raw) > 64 or len(raw) % 2:
        return False
    return all(byte in points.values() for byte in raw)

for text in ("", "0A", "a1B2", "FF" * 32):
    assert valid_ebcdic_body(text.encode("cp037"))
for text in ("0", "0G", "AB ", "\t0", "FF" * 33):
    assert not valid_ebcdic_body(text.encode("cp037"))
assert not valid_ebcdic_body(bytes([0xFF, 0xC1]))

# A full 7736-object synthetic stage with zero and partial hex records.
# This checks one-based header-to-body adjacency at all three positions.
rows = []
targets = {}
for i in range(1, 7737):
    n = 0 if i == 1 else (i * 13) % 139 + 1
    data = bytes([i % 251]) * n
    targets[i] = len(rows) + 1
    digest = hashlib.sha1(
        b"blob " + str(n).encode() + b"\0" + data).hexdigest().upper()
    rows.append("OBJ %d 3 %d %s" % (i, n, digest))
    hx = data.hex().upper()
    rows.extend([hx[k:k+64] for k in range(0, len(hx), 64)]
                if hx else [""])
assert targets[1] == 1
for i in (1, 3868, 7736):
    at = targets[i] - 1
    assert rows[at].startswith("OBJ %d " % i)
    assert valid_ebcdic_body(rows[at + 1].encode("cp037"))
    if rows[at + 1]:
        assert len(rows[at + 1]) % 2 == 0
    if i < 7736:
        assert targets[i + 1] > targets[i] + 1
assert rows[targets[1]] == ""  # one empty-body record is valid
# Detect synthetic mutation in the next record, not only in header.
bad = rows[targets[3868]].replace("0", "G", 1)
if bad == rows[targets[3868]]:
    bad = "G" + rows[targets[3868]][1:]
assert not valid_ebcdic_body(bad.encode("cp037"))
print("M194 STATIC CMS TWO-FSREAD READ-ONLY GUARDS PASS")
print("M194 7736-OBJECT ADJACENT FIRST-BODY HOST MODEL PASS")
print("M194 IBM CMS ASSEMBLE AND ACTUAL BODY READ STILL PENDING")
