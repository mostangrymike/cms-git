#!/usr/bin/env python3
"""Audit references to archived CMS EXEC entrypoints; no filesystem writes.

Scans complete tracked src/, scripts/, tests/, and workflow source for
literal command references. Reports references to archived names; does not
assume a reference is a runtime dependency or automatically delete code.
"""
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# Reuse the single archive loader and strict inventory contract used by CI.
# Importing the tool does not invoke its write-capable main().
import importlib.util
archive_spec = importlib.util.spec_from_file_location(
    "cms_archive_restore", ROOT / "scripts/restore-cms-exec.py")
archive_tool = importlib.util.module_from_spec(archive_spec)
archive_spec.loader.exec_module(archive_tool)
archives = archive_tool.load()
assert len(archives) == 99, ("ARCHIVE INVENTORY COUNT", len(archives))

# A live CMS source that is also archived must not silently drift.
# GIT9CTX remains a required live dependency of the production PACK walker.
for name, original in sorted(archives.items()):
    live = ROOT / "src" / name
    if live.exists():
        assert live.read_text() == original, ("ARCHIVE DRIFT", name)
required = ROOT / "src/GIT9CTX.EXEC"
assert required.is_file(), "Production GIT9CTX helper missing"
assert "GIT9CTX" in (ROOT / "src/GITP9PWK.EXEC").read_text()
print("LIVE ARCHIVED CMS SOURCE PARITY PASS")

# Historical M6/M7 protocol sources are archived for recovery, not
# automatically eligible for deletion: they may be called dynamically.
protected = ("GITACK.EXEC", "GITADV.EXEC", "GITZLIB.EXEC")
for name in protected:
    assert name in archives, ("MISSING RECOVERY ARCHIVE", name)
    assert (ROOT / "src" / name).is_file(), ("UNREVIEWED DELETION", name)
print("LIVE M6 PROTOCOL HELPER RETENTION PASS")

tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT)
tracked_names = {p.decode() for p in tracked.split(b"\0") if p}
# CI reconstructs historical EXEC files before this audit. An on-disk file
# alone therefore cannot establish that a live production dependency remains
# part of the canonical Git checkout. Keep these original sources tracked.
for name in (*protected, "GIT9CTX.EXEC"):
    assert "src/" + name in tracked_names, ("LIVE SOURCE NOT TRACKED", name)
print("LIVE PRODUCTION HELPER GIT TRACKING PASS")

# Historical native wrappers are reproducible by the guarded generator.
# Keep exactly one maintained source representation, not ten tracked copies.
# The workflow regenerates these before the native host source checks.
import importlib.util
spec = importlib.util.spec_from_file_location(
    "ph_restore", ROOT / "scripts/restore-ph-wrappers.py")
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)
generated = set(generator.SPECS) | set(generator.EXTRA_SPECS) | set(generator.SPECIAL_SPECS)
assert len(generated) == 10, ("WRAPPER INVENTORY CHANGED", len(generated))
for name in sorted(generated):
    assert "src/" + name + ".EXEC" not in tracked_names, (
        "DUPLICATE TRACKED GENERATED EXEC", name)
    original = ROOT / "src" / (name + ".EXEC")
    assert original.is_file(), ("MISSING GENERATED WRAPPER", name)
    assert original.read_text() == generator.generate(name), (
        "GENERATED WRAPPER DRIFT", name)
print("TEN HISTORICAL WRAPPERS SINGLE SOURCE PASS")
paths = [ROOT / p for p in sorted(tracked_names)]
sources = [p for p in paths if p.suffix in
           (".EXEC", ".C", ".ASSEMBLE", ".sh", ".py", ".yml")
           and "archive" not in p.parts]
pattern = re.compile(r"(?<![A-Z0-9])(" +
                     "|".join(re.escape(n[:-5]) for n in sorted(archives,
                                      key=len, reverse=True)) +
                     r")(?![A-Z0-9])")
found = {}
for path in sources:
    content = path.read_text(errors="replace")
    for number, line in enumerate(content.splitlines(), 1):
        for m in pattern.finditer(line.upper()):
            found.setdefault(m.group(1), []).append(
                f"{path.relative_to(ROOT)}:{number}")
for name, references in sorted(found.items()):
    print(name, "REFERENCES", len(references), ", ".join(references[:8]))
print("ARCHIVED CMS EXEC DEPENDENCY AUDIT", len(archives),
      "ARCHIVED", len(found), "REFERENCED", len(sources), "SOURCES")
