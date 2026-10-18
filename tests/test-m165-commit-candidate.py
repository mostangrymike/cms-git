#!/usr/bin/env python3
"""Guard M165's commit OID handoff for the later REF2 CAS test."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = root / "src" / "M165CHK.EXEC"
text = source.read_text()

for required in (
    "commitcount=0",
    "word(co.ci,1)='COMMIT-STAGED'",
    "word(co.ci,2)='COMMIT'",
    "length(commit)\\=40",
    "verify(commit,'0123456789ABCDEF')\\=0",
    "EXEC ZTMCAND1 VERIFY-OBJECT",
    "M165 MULTI COMMIT CANDIDATE",
):
    if required not in text:
        raise SystemExit("M165 commit candidate guard missing: " + required)

verified = text.index("EXEC ZTMCAND1 VERIFY-OBJECT")
reported = text.index("M165 MULTI COMMIT CANDIDATE")
accepted = text.index("EXEC ZTMCAND1 ACCEPT")
if not verified < reported < accepted:
    raise SystemExit("M165 candidate verify/report/accept order changed")

for number, line in enumerate(text.splitlines(), 1):
    if len(line) > 80:
        raise SystemExit(f"M165 source line {number} exceeds 80 columns")

print("M165 COMMIT CANDIDATE HANDOFF SOURCE GUARD PASS")
