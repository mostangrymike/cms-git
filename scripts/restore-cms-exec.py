#!/usr/bin/env python3
"""Restore preserved historical CMS EXEC source (never overwrite existing files).

Usage:
  python3 scripts/restore-cms-exec.py M9PCONS.EXEC
  python3 scripts/restore-cms-exec.py ALL
  python3 scripts/restore-cms-exec.py MISSING
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ARCHIVES = ROOT / "archive"

def load():
    files = {}
    for path in sorted(ARCHIVES.glob("*.json")):
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
        raise SystemExit("Usage: python3 scripts/restore-cms-exec.py NAME.EXEC|ALL|MISSING")
    arg = sys.argv[1].upper()
    # The archive inventory must remain complete. A deleted bundle must not
    # silently turn its formerly restorable EXECs into missing coverage.
    expected = {
        "M3-M5_EXEC.json": 15,
        "M6-M9_EXEC.json": 48,
        "M10-M13_EXEC.json": 23,
        "M9_WALKERS.json": 3,
        "M6_PROTOCOL.json": 3,
        "M9-M12_TRANSPORT.json": 7,
    }
    actual = {p.name for p in ARCHIVES.glob("*.json")}
    if actual != set(expected):
        raise SystemExit("Archive inventory mismatch: " + str(sorted(actual)))
    for name, count in expected.items():
        source = json.loads((ARCHIVES / name).read_text(encoding="utf-8"))
        if source.get("format") != "cms-exec-archive-v1" or len(source["files"]) != count:
            raise SystemExit("Archive count or format mismatch: " + name)
    files = load()
    if arg == "MISSING":
        # Validate all existing files before creating any: fail closed on
        # source drift rather than masking changes with archive recovery.
        for name, source in sorted(files.items()):
            dest = ROOT / "src" / name
            if dest.exists() and dest.read_text(encoding="utf-8") != source:
                raise SystemExit("Archive source drift: " + name)
        selected = [n for n in sorted(files) if not (ROOT / "src" / n).exists()]
        for name in selected:
            dest = ROOT / "src" / name
            with dest.open("x", encoding="utf-8", newline="") as fp:
                fp.write(files[name])
            print("Restored", dest.relative_to(ROOT))
        print("ARCHIVE SOURCE PARITY PASS", len(files))
        return
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
