#!/usr/bin/env python3
"""Guard the M166 CAS gate's explicit candidate commit argument."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = root / "src" / "M166CHK.EXEC"
text = source.read_text()

for required in (
    "parse arg supplied",
    "if supplied\\='' then candidate=translate(strip(supplied))",
    "length(candidate)\\=40",
    "verify(candidate,'0123456789ABCDEF')\\=0",
    "EXEC GIT VERIFY-OBJECT' candidate",
    "refs/heads/m166test",
):
    if required not in text:
        raise SystemExit("M166 candidate argument guard missing: " + required)

validated = text.index("verify(candidate,'0123456789ABCDEF')")
verify_object = text.index("EXEC GIT VERIFY-OBJECT' candidate")
if validated >= verify_object:
    raise SystemExit("M166 must validate its candidate before object lookup")

for number, line in enumerate(text.splitlines(), 1):
    if len(line) > 80:
        raise SystemExit(f"M166 source line {number} exceeds 80 columns")

print("M166 CANDIDATE ARGUMENT SOURCE GUARD PASS")
