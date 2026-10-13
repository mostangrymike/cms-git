#!/usr/bin/env python3
"""Restore exact historical CMS EXECs from a lossless GitHub source archive.

Run from any directory: python3 scripts/restore-cms-exec.py M4TEST.EXEC
Writes src/M4TEST.EXEC without overwriting an existing file.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / "archive" / "M3-M5_EXEC.json"

def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python3 scripts/restore-cms-exec.py NAME.EXEC")
    name = sys.argv[1].upper()
    if not name.endswith(".EXEC") or len(name.split(".", 1)[0]) > 8:
        raise SystemExit("CMS EXEC name must be NAME.EXEC (1..8 characters)")
    data = json.loads(ARCHIVE.read_text(encoding="utf-8"))
    if data.get("format") != "cms-exec-archive-v1" or name not in data["files"]:
        raise SystemExit("No archived EXEC with that name")
    dest = ROOT / "src" / name
    with dest.open("x", encoding="utf-8", newline="") as f:
        f.write(data["files"][name])
    print("Restored", dest.relative_to(ROOT))

if __name__ == "__main__":
    main()
