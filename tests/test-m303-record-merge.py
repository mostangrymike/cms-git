#!/usr/bin/env python3
"""M303: execute the exact CMS record-level three-way merge routines on host."""
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
WT = (ROOT / "src" / "GITWT.EXEC").read_text()
GIT = (ROOT / "src" / "GIT.EXEC").read_text()

for token in (
    "lcsmatches:",
    "appendsegment:",
    "addhunk:",
    "sidehunks:",
    "hoverlap:",
    "samehunk:",
    "appendprojection:",
    "merge3records:",
    "merge3maxrecords=2048",
    "merge3maxcells=65536",
    "horder.ocount=idx",
    "call merge3records",
    "conflictmanual.bci=1",
    "MERGE AUTO-MERGED",
    "exit 13",
):
    assert token in WT, token
assert "if mgrc=13 then do" in GIT
assert "merge changes staged; branch unchanged" in GIT

start = WT.index("lcsmatches:\n")
end = WT.index("buildconflictmarkers:", start)
routines = WT[start:end]
for line in routines.splitlines():
    assert len(line) <= 80, line
    stripped = line.rstrip()
    assert not (stripped.endswith(",") and not stripped.endswith(("|,", "&,", "then,"))), line
assert not re.search(r"parse upper arg [A-Za-z0-9_.]+ [A-Za-z0-9_.]+", routines)
assert not re.search(r"=findpath\s+[A-Za-z]", routines)


def q(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def run_case(base, local, remote, *, limit=None, cells=None):
    lines = [
        f"bcount={len(base)}",
        f"lcount={len(local)}",
        f"rcount={len(remote)}",
        "mergeremotebranch='topic'",
    ]
    for stem, values in (("brec", base), ("lrec", local), ("rrec", remote)):
        for i, value in enumerate(values, 1):
            lines.append(f"{stem}.{i}={q(value)}")
    lines += ["call merge3records", "say 'RC' result 'CONFLICT' merge3conflict"]
    lines += ["do oi=1 to mrec.0", " say mrec.oi", "end", "say 'END'", "exit 0"]
    body = routines
    if limit is not None:
        body = body.replace("merge3maxrecords=2048", f"merge3maxrecords={limit}")
    if cells is not None:
        body = body.replace("merge3maxcells=65536", f"merge3maxcells={cells}")
    source = "\n".join(lines) + "\n" + body + "\n"
    with tempfile.TemporaryDirectory() as td:
        path = Path(td) / "merge3.rexx"
        path.write_text(source)
        subprocess.run(["rexx", "-c", str(path), "/dev/null"], check=True,
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        result = subprocess.run(["rexx", str(path)], check=True,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                text=True)
    output = result.stdout.splitlines()
    assert output[0].startswith("RC OK CONFLICT "), result.stdout
    conflict = int(output[0].rsplit(" ", 1)[1])
    assert output[-1] == "END", result.stdout
    return conflict, output[1:-1]


cases = [
    (
        ["a", "b", "c", "d", "e"],
        ["a", "L", "c", "d", "e"],
        ["a", "b", "c", "R", "e"],
        0,
        ["a", "L", "c", "R", "e"],
    ),
    (
        ["a", "b", "c"],
        ["a", "X", "c"],
        ["a", "X", "c"],
        0,
        ["a", "X", "c"],
    ),
    (
        ["a", "b", "c"],
        ["a", "i", "b", "c"],
        ["a", "b", "C"],
        0,
        ["a", "i", "b", "C"],
    ),
    (
        ["a", "b", "c", "d"],
        ["a", "L", "c", "d"],
        ["a", "b", "R", "d"],
        0,
        ["a", "L", "R", "d"],
    ),
    (
        ["a", "b", "c", "d"],
        ["a", "c", "d"],
        ["a", "b", "R", "d"],
        0,
        ["a", "R", "d"],
    ),
    (
        ["a", "b", "c"],
        ["a", "c"],
        ["a", "B", "c"],
        1,
        ["a", "<<<<<<< HEAD", "=======", "B", ">>>>>>> topic", "c"],
    ),
    (
        ["a", "b", "c", "d", "e"],
        ["a", "L", "c", "d", "e"],
        ["a", "R", "c", "d", "e"],
        1,
        ["a", "<<<<<<< HEAD", "L", "=======", "R", ">>>>>>> topic", "c", "d", "e"],
    ),
    (
        ["a", "b"],
        ["a", "X", "b"],
        ["a", "b", "Y"],
        0,
        ["a", "X", "b", "Y"],
    ),
    (
        ["a", "b"],
        ["a", "X", "b"],
        ["a", "Y", "b"],
        1,
        ["a", "<<<<<<< HEAD", "X", "=======", "Y", ">>>>>>> topic", "b"],
    ),
    (
        ["a", "b", "c"],
        ["a", "c"],
        ["a", "c"],
        0,
        ["a", "c"],
    ),
    (
        [],
        ["L"],
        ["R"],
        1,
        ["<<<<<<< HEAD", "L", "=======", "R", ">>>>>>> topic"],
    ),
    (
        [],
        ["X"],
        ["X"],
        0,
        ["X"],
    ),
    (
        ["a"],
        ["L"],
        ["R"],
        1,
        ["<<<<<<< HEAD", "L", "=======", "R", ">>>>>>> topic"],
    ),
]

for base, local, remote, expected_conflict, expected_records in cases:
    conflict, records = run_case(base, local, remote)
    assert conflict == expected_conflict, (base, local, remote, conflict)
    assert records == expected_records, (records, expected_records)

conflict, records = run_case(["a", "b"], ["L", "b"], ["R", "b"], limit=1)
assert conflict == 1
assert records == ["<<<<<<< HEAD", "L", "b", "=======", "R", "b", ">>>>>>> topic"]

conflict, records = run_case(["a", "b"], ["L", "b"], ["R", "b"], cells=1)
assert conflict == 1
assert records == ["<<<<<<< HEAD", "L", "b", "=======", "R", "b", ">>>>>>> topic"]

print("M303 RECORD-LEVEL THREE-WAY MERGE HOST TESTS PASS", len(cases) + 2)
