#!/usr/bin/env python3
"""Audit references to archived CMS EXEC entrypoints; no filesystem writes.

Scans complete tracked src/, scripts/, tests/, and workflow source for
literal command references. Reports references to archived names; does not
assume a reference is a runtime dependency or automatically delete code.
"""
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
archives = {}
for p in sorted((ROOT / "archive").glob("*.json")):
    data = json.loads(p.read_text())
    assert data["format"] == "cms-exec-archive-v1", p
    for name, body in data["files"].items():
        assert name not in archives, (p, name)
        assert re.fullmatch(r"[A-Z0-9]{1,8}\.EXEC", name), name
        assert isinstance(body, str) and body, name
        archives[name] = body

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
paths = [ROOT / p.decode() for p in tracked.split(b"\0") if p]
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
