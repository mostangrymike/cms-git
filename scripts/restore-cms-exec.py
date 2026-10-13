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
import subprocess
import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ARCHIVES = ROOT / "archive"

def load():
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


def audit():
    """Read-only tracked-source audit; called after CI regeneration."""
    files = load()
    if len(files) != 99:
        raise RuntimeError("Archive count mismatch")
    tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT)
    paths = {p.decode() for p in tracked.split(b"\0") if p}
    for name, source in files.items():
        live = ROOT / "src" / name
        if live.exists() and live.read_text(encoding="utf-8") != source:
            raise RuntimeError("Archive source drift: " + name)
    required = ("GITACK.EXEC", "GITADV.EXEC", "GITZLIB.EXEC",
                "GIT9CTX.EXEC")
    for name in required:
        if "src/" + name not in paths or not (ROOT / "src" / name).is_file():
            raise RuntimeError("Missing tracked production helper: " + name)
    if "GIT9CTX" not in (ROOT / "src/GITP9PWK.EXEC").read_text():
        raise RuntimeError("PACK walker lost GIT9CTX dependency")
    spec = importlib.util.spec_from_file_location(
        "ph_restore", ROOT / "scripts/restore-ph-wrappers.py")
    generator = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(generator)
    names = set(generator.SPECS) | set(generator.EXTRA_SPECS) | set(generator.SPECIAL_SPECS)
    if len(names) != 10:
        raise RuntimeError("Historical wrapper inventory changed")
    for name in names:
        if "src/" + name + ".EXEC" in paths:
            raise RuntimeError("Duplicate tracked wrapper: " + name)
        path = ROOT / "src" / (name + ".EXEC")
        if not path.is_file() or path.read_text() != generator.generate(name):
            raise RuntimeError("Historical wrapper drift: " + name)
    pattern = re.compile(r"(?<![A-Z0-9])(" +
                         "|".join(re.escape(n[:-5]) for n in
                                  sorted(files, key=len, reverse=True)) +
                         r")(?![A-Z0-9])")
    references = {}
    for relative in sorted(paths):
        path = ROOT / relative
        if path.suffix not in (".EXEC", ".C", ".ASSEMBLE",
                               ".sh", ".py", ".yml") or "archive" in path.parts:
            continue
        for lineno, line in enumerate(path.read_text(errors="replace").splitlines(), 1):
            for match in pattern.finditer(line.upper()):
                references.setdefault(match.group(1), []).append(
                    "%s:%d" % (relative, lineno))
    for name, locations in sorted(references.items()):
        print(name, "REFERENCES", len(locations), ", ".join(locations[:8]))
    print("ARCHIVED CMS EXEC DEPENDENCY AUDIT PASS", len(files),
          "ARCHIVED", len(references), "REFERENCED")

def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python3 scripts/restore-cms-exec.py NAME.EXEC|ALL|MISSING|AUDIT")
    arg = sys.argv[1].upper()
    if arg == "AUDIT":
        audit()
        return
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
