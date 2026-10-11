#!/usr/bin/env python3
"""M195 full LAST physical-body read model and assembler safety.

Linux cannot assemble IBM CMS macros; target is a separate gate.
"""
from pathlib import Path
import hashlib

ROOT = Path(__file__).resolve().parents[1]
ASM = (ROOT / "src/GITFL10.ASSEMBLE").read_text()
REX = (ROOT / "src/GITFLP.EXEC").read_text()
code = "\n".join(line for line in ASM.splitlines()
                 if line and not line.startswith("*"))
assert max(len(x) for x in ASM.splitlines()) <= 72
assert max(len(x) for x in REX.splitlines()) <= 80
marks = [x for x in ASM.splitlines() if x.endswith("X")]
assert len(marks) == 2 and all(len(x) == 72 for x in marks)
assert code.count("FSREAD 'M173NET STAGE G1'") == 2
assert code.count("RECFM=V,RECNO=(5),NOREC=1,FORM=E") == 2
assert code.count("FSCLOSE 'M173NET STAGE G1'") == 2
for token in (
    "=F'3864789'", "=F'3864790'", "=F'10'", "=F'64'",
    "=F'289'", "=F'320'", "ST    0,BODYLEN", "BODYLOOP",
    "LA    6,1(6)", "ST    6,CURNO", "ST    6,COUNT",
    "N     6,=F'1'", "BCT   7,CHECKCHR",
    "M195 LAST TEN BODY RECORDS HEX PASS",
    "M195 READ ONLY COMPLETE BODY RECORDS PASS",
):
    assert token in ASM, token
for forbidden in ("FSWRITE", "FSERASE", "FSPOINT", "OPENTYP=WRITE",
                  "RECFM=F", "FORM=S", "fseek", "FILEDEF"):
    assert forbidden not in code, forbidden
for token in (
    "'PIPE CMS QUERY DISK G | STEM d.'",
    "'STATE M173NET STAGE G'", "'STATE M174NET INDEX G'",
    "'STATE GITFL10 MODULE A'", "'GITFL10'",
    "M195 COMPLETE BODY GATE PASS G LAST", "probe\\='LAST'"
):
    assert token in REX, token
for forbidden in ("ERASE ", "FORMAT ", "FILEDEF STGIN", "FILEDEF IDXIN",
                  "DIRECTXA", "FSWRITE"):
    assert forbidden not in REX
assert not (ROOT / "src/GITFL10.EXEC").exists()
assert not (ROOT / "src/GITFLP.ASSEMBLE").exists()

digits = set(b"0123456789ABCDEFabcdef")
ebcdic_hex = set(bytes([c]).decode("ascii").encode("cp037")[0]
                  for c in digits)
assert ("a".encode("cp037")[0] < "A".encode("cp037")[0]
        < "0".encode("cp037")[0])
assert "BNL   DIGIT" in ASM and "BNL   UPPER" in ASM

def body_gate(lines):
    """Model exactly the M195 length, parity, and hex checks."""
    if len(lines) != 10:
        return False
    total = 0
    for i, line in enumerate(lines):
        if len(line) > 64 or len(line) % 2:
            return False
        if i != 9 and len(line) != 64:
            return False
        if i == 9 and len(line) == 0:
            return False
        if any(b not in ebcdic_hex for b in line):
            return False
        total += len(line) // 2
    return 289 <= total <= 320

for size in (289, 290, 300, 319, 320):
    data = bytes((i * 17 + size) % 256 for i in range(size))
    hextext = data.hex().upper()
    recs = [hextext[i:i + 64].encode("cp037")
            for i in range(0, len(hextext), 64)]
    assert len(recs) == 10 and body_gate(recs), size
    assert not body_gate(recs[:-1])  # truncated object
    assert not body_gate(recs + [b""])  # extra record
    bad = recs[:]
    bad[0] = bad[0][:62]  # short non-final record
    assert not body_gate(bad)
    bad = recs[:]
    bad[4] = bad[4][:63]  # odd hex
    assert not body_gate(bad)
    bad = recs[:]
    bad[3] = bad[3][:11] + "G".encode("cp037") + bad[3][12:]
    assert not body_gate(bad)
    bad = recs[:]
    bad[5] = bad[5][:11] + b"\x00" + bad[5][12:]
    assert not body_gate(bad)
    bad = recs[:]
    bad[-1] = b""
    assert not body_gate(bad)

# Full 7,736-object synthetic stage and end-model boundary.
# Keep last object 300 bytes => exactly ten 64-hex records.
rows = []
for n in range(1, 7737):
    size = 300 if n == 7736 else ((n * 13) % 67) + 1
    data = bytes([n % 251]) * size
    oid = hashlib.sha1(
        b"blob " + str(size).encode("ascii") + b"\0" + data
    ).hexdigest().upper()
    rows.append("OBJ %d 3 %d %s" % (n, size, oid))
    hx = data.hex().upper()
    rows.extend(hx[i:i+64] for i in range(0, len(hx), 64))
last = next(i for i, value in enumerate(rows)
            if value.startswith("OBJ 7736 "))
assert len(rows) - last - 1 == 10
assert body_gate([record.encode("cp037") for record in rows[last + 1:]])
assert rows[last].startswith("OBJ 7736 3 300 ")
print("M195 STATIC READ ONLY CMS TEN RECORD FSREAD GUARDS PASS")
print("M195 7736 OBJECT LAST COMPLETE BODY HOST MODEL PASS")
print("M195 CMS ASSEMBLE AND LAST BODY TARGET STILL PENDING")
