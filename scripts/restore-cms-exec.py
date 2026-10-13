#!/usr/bin/env python3
"""Restore preserved historical CMS EXEC source (never overwrite existing files).

Usage:
  python3 scripts/restore-cms-exec.py M9PCONS.EXEC
  python3 scripts/restore-cms-exec.py ALL
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ARCHIVES = ROOT / "archive"

def load():
    files = {}
    for path in sorted(ARCHIVES.glob("*_EXEC.json")):
        archive = json.loads(path.read_text(encoding="utf-8"))
        if archive.get("format") != "cms-exec-archive-v1":
            raise RuntimeError("Unknown format: " + str(path))
        for name, source in archive["files"].items():
            if not re.fullmatch(r"[A-Z0-9]{1,8}[.]EXEC", name):
                raise RuntimeError("Invalid CMS filename: " + name)
            if name in files or not isinstance(source, str) or not source:
                raise RuntimeError("Duplicate or empty EXEC: " + name)
            files[name] = source
    return files

def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python3 scripts/restore-cms-exec.py NAME.EXEC|ALL")
    files = load()
    arg = sys.argv[1].upper()
    selected = sorted(files) if arg == "ALL" else [arg]
    if not selected or any(name not in files for name in selected):
        raise SystemExit("Unknown archived EXEC name: " + arg)
    collisions = [n for n in selected if (ROOT / "src" / n).exists()]
    if collisions:
        raise SystemExit("Refusing to overwrite: " + ", ".join(collisions))
    for name in selected:
        dest = ROOT / "src" / name
        with dest.open("x", encoding="utf-8", newline="") as fp:
            fp.write(files[name])
        print("Restored", dest.relative_to(ROOT))

if __name__ == "__main__":
    main()
