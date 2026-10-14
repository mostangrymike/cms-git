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
    if actual != {"HISTORICAL_EXEC.json"}:
        raise SystemExit("Archive inventory mismatch: " + str(sorted(actual)))
    collection = json.loads((ARCHIVES / "HISTORICAL_EXEC.json").read_text(
        encoding="utf-8"))
    if collection.get("format") != "cms-exec-archive-collection-v1":
        raise RuntimeError("Unknown historical collection format")
    bundles = collection.get("bundles")
    if not isinstance(bundles, dict) or set(bundles) != set(expected):
        raise RuntimeError("Historical archive bundle inventory mismatch")
    files = {}
    for name, count in sorted(expected.items()):
        archive = bundles[name]
        if not isinstance(archive, dict) or not isinstance(archive.get("description"), str):
            raise RuntimeError("Historical archive metadata mismatch: " + name)
        entries = archive.get("files")
        if not isinstance(entries, dict) or len(entries) != count:
            raise RuntimeError("Archive count mismatch: " + name)
        for filename, source in entries.items():
            if not re.fullmatch(r"[A-Z0-9]{1,8}[.]EXEC", filename):
                raise RuntimeError("Invalid CMS filename: " + filename)
            if filename in files or not isinstance(source, str) or not source:
                raise RuntimeError("Duplicate or empty EXEC: " + filename)
            files[filename] = source
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


def scan_live_sources():
    """Shared conservative lexical CMS source-reference scan."""
    tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT)
    sources = sorted(p.decode() for p in tracked.split(b"\0")
                     if p.startswith(b"src/") and p.endswith(
                         (b".EXEC", b".C", b".ASSEMBLE", b".REPO", b".sh")))
    stems = {Path(name).stem.upper(): name for name in sources}
    if len(stems) != len(sources):
        raise RuntimeError("Ambiguous CMS source stem; cannot audit safely")
    pattern = re.compile(r"(?<![A-Z0-9])(" +
                         "|".join(re.escape(s) for s in sorted(
                             stems, key=len, reverse=True)) + r")(?![A-Z0-9])")
    callers = {stem: set() for stem in stems}
    for path in sources:
        for line in (ROOT / path).read_text(errors="replace").splitlines():
            for match in pattern.finditer(line.upper()):
                stem = match.group(1)
                if stems[stem] != path:
                    callers[stem].add(path)
    return sources, stems, callers


def live_dependencies():
    """Conservative source-to-source reference inventory; never authorize deletion.

    Token matching is intentionally broad: dynamic REXX command assembly,
    XEDIT/CMS EXEC searches, generated wrappers and external operators can
    escape static analysis. Zero observed callers is NOT proof of dead code.
    """
    sources, stems, callers = scan_live_sources()
    # Hard protect known runtime helpers and the verified indexed/tree path.
    protected = ("GITACK", "GITADV", "GITZLIB", "GIT9CTX",
                 "GITP9PWK", "GITCWALK", "GITCIDX", "GITREC",
                 "GITSEL", "GITPH8M", "GITPSKM", "GITRP6M")
    for stem in protected:
        if stem not in stems or not (ROOT / stems[stem]).is_file():
            raise RuntimeError("Protected source absent: " + stem)
    if "src/GITP9PWK.EXEC" not in callers["GIT9CTX"]:
        raise RuntimeError("Required GIT9CTX caller missing")
    active = sum(bool(value) for value in callers.values())
    print("LIVE SOURCE DEPENDENCY INVENTORY PASS", len(sources),
          "SOURCE PATHS", active, "WITH SOURCE TOKEN CALLERS")
    for stem in protected:
        print("PROTECTED", stems[stem], "SOURCE CALLERS",
              len(callers[stem]))
    print("ZERO OBSERVED SOURCE CALLERS IS NOT DELETION AUTHORIZATION")


def consolidation_inventory():
    """Reproducible source inventory; zero callers never permits deletion."""
    sources, stems, stem_callers = scan_live_sources()
    callers = {path: stem_callers[Path(path).stem.upper()] for path in sources}
    print("CMS SOURCE CONSOLIDATION INVENTORY", len(sources))
    print("NOTE TOKEN CALLERS INCLUDE COMMENTS AND STRING LITERALS")
    print("NOTE DYNAMIC CMS CALLS, OPERATORS AND EXTERNAL MODULES MAY BE INVISIBLE")
    print("NOTE ZERO TOKEN CALLERS NEVER AUTHORIZES DELETION")
    totals = {"MILESTONE": [0, 0], "GIT": [0, 0], "OTHER": [0, 0]}
    unreferenced = 0
    for path in sources:
        relative = Path(path)
        stem = relative.stem.upper()
        family = ("MILESTONE" if re.fullmatch(r"M[0-9]+[A-Z0-9]*", stem)
                  else "GIT" if stem.startswith("GIT") else "OTHER")
        size = (ROOT / path).stat().st_size
        totals[family][0] += 1
        totals[family][1] += size
        unreferenced += not callers[path]
        print("SOURCE", path, "FAMILY", family, "TOKEN_CALLERS",
              len(callers[path]), "SIZE_BYTES", size)
    for family in ("MILESTONE", "GIT", "OTHER"):
        count, size = totals[family]
        print("FAMILY", family, "FILES", count, "BYTES", size)
    print("ZERO OBSERVED TOKEN CALLERS", unreferenced,
          "NOT DELETION AUTHORIZATION")
    if sum(values[0] for values in totals.values()) != len(sources):
        raise RuntimeError("Source family accounting mismatch")
    print("CMS SOURCE INVENTORY COMPLETE", len(sources))

def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python3 scripts/restore-cms-exec.py NAME.EXEC|ALL|MISSING|AUDIT|LIVEDEPS|LIVEPLAN")
    arg = sys.argv[1].upper()
    if arg == "LIVEDEPS":
        live_dependencies()
        return
    if arg == "LIVEPLAN":
        consolidation_inventory()
        return
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
