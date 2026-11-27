#!/usr/bin/env python3
"""M305: host guards for merge path add/remove and mode changes."""
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
WT = (ROOT / "src" / "GITWT.EXEC").read_text()

for token in (
    "mergepathcount=0",
    "mergestructural=0",
    "mergeaddcount=0",
    "call addmergepath",
    "call setmergemode",
    "call writemergemodes",
    "call readmergemodes",
    "call mergemodefor",
    "call clearmergemodes",
    "GITMODE REPO' objectfm",
    "if mapstage.apsi=zeros then do",
    "if mapbase.abi=zeros then do",
    "if mergeactive=2 then do",
    "msconflicts<0",
    "newrootmode.newrootcount=mergemode",
    "nodemode.currentnode.entryindex=mergemode",
    "mapchanged.mi=1",
    "if mergeactive=0 then mergemodecount=0",
):
    assert token in WT, token

assert "GITWT: merge path additions or removals are unsupported" not in WT
assert "GITWT: merge mode changes are unsupported" not in WT
assert "GITWT: merge add/add or delete/modify conflicts are unsupported" in WT
assert "GITWT: merge mode conflict is unsupported" in WT
assert "GITWT: merge removal is not mapped" in WT

prepare = WT.split("preparemerge:", 1)[1].split("lcsmatches:", 1)[0]
assert "if mergestructural=1 then return 'CONFLICT'" in prepare
assert "if mergeconflictmode=1 & (mergeconflicts>0 | mergestructural=1) then do" in prepare
assert "call allocatename mppath" in prepare
assert "mapbase.newindex=zeros" in prepare

mode_routines = WT.split("writemergemodes:", 1)[1].split("checkmergeworktree:", 1)[0]
for token in ("MODE1", "PATH", "END", "mmout.mmidx='PATH'",
              "mmout.mmidx='END'", "SET CMSTYPE HT", "mmwrite=rc", "mmread=rc",
              "RENAME GITMODE TMP' objectfm 'GITMODE REPO' objectfm"):
    assert token in mode_routines, token
assert "mmout.mmout.0" not in mode_routines

abort = WT.split("abortmerge:", 1)[1].split("workhasmarkers:", 1)[0]
assert "zeros='0000000000000000000000000000000000000000'" in abort
assert "else if rc=28 then do\n    call rollbackrestore\n    return 'ERROR'" not in abort

continue_block = WT.split("if command='MERGE-CONTINUE' then do", 1)[1].split(
    "if command='COMMIT' then do", 1)[0]
assert "zeros='0000000000000000000000000000000000000000'" in continue_block

accept = WT.split("if command='ACCEPT' then do", 1)[1].split(
    "if command='MERGE-ABORT' then do", 1)[0]
assert "if result\\='' then acceptedcount=acceptedcount+1" in accept

commit = WT.split("if command='COMMIT' then do", 1)[1].split("addselected:", 1)[0]
assert "call readmergemodes" in commit
assert "(mergeactive=1 | mergeactive=3) & mapstage.mi=zeros" in commit
assert "if mapstage.mi=zeros then do" in commit
assert "call mergemodefor mappath.mi" in commit
assert "if result\\='' then mapchanged.mi=1" in commit

for line in WT.splitlines():
    assert len(line) <= 80, line
assert not re.search(r"parse upper arg [A-Za-z0-9_.]+ [A-Za-z0-9_.]+", prepare)


def entry(oid, mode="100644"):
    return (oid, mode)


def merge_entry(base, local, remote):
    if local == remote:
        return local
    if local == base:
        return remote
    if remote == base:
        return local
    if base is None or local is None or remote is None:
        raise ValueError("add/add or delete/modify")
    if local[0] == remote[0]:
        if local[1] == remote[1]:
            mode = local[1]
        elif local[1] == base[1]:
            mode = remote[1]
        elif remote[1] == base[1]:
            mode = local[1]
        else:
            raise ValueError("mode")
        return (local[0], mode)
    if local[1] != remote[1]:
        raise ValueError("mode")
    return ("MERGED", local[1])


B = entry("base")
L = entry("local")
R = entry("remote")
assert merge_entry(None, None, R) == R
assert merge_entry(None, L, None) == L
assert merge_entry(B, None, None) is None
assert merge_entry(B, None, B) is None
assert merge_entry(B, B, None) is None
assert merge_entry(B, L, B) == L
assert merge_entry(B, B, R) == R
assert merge_entry(B, entry("same", "100755"), entry("same", "100755")) == entry("same", "100755")
assert merge_entry(B, entry("same", "100755"), B) == entry("same", "100755")
assert merge_entry(B, B, entry("same", "100755")) == entry("same", "100755")
X = entry("base", "100755")
assert merge_entry(X, entry("same", "100644"), X) == entry("same", "100644")
assert merge_entry(X, X, entry("same", "100644")) == entry("same", "100644")
assert merge_entry(B, L, R) == ("MERGED", "100644")
assert merge_entry(B, entry("x", "100755"), entry("x", "100644")) == ("x", "100755")
for base, local, remote in (
    (None, L, R),
    (B, None, R),
    (B, L, None),
):
    try:
        merge_entry(base, local, remote)
    except ValueError:
        pass
    else:
        raise AssertionError((base, local, remote))

def q(value):
    return "'" + value.replace("'", "''") + "'"


def run_prepare(base, local, remote):
    lines = [
        "mergebase='B'",
        "mergeexpected='L'",
        "mergeparent='R'",
        "mergeconflictmode=0",
        f"bcount={len(base)}",
        f"lcount={len(local)}",
        f"rcount={len(remote)}",
    ]
    for stem, values in (("b", base), ("l", local), ("r", remote)):
        for i, (path, (oid, mode)) in enumerate(values.items(), 1):
            lines.append(f"{stem}path.{i}={q(path)}")
            lines.append(f"{stem}oid.{i}={q(oid)}")
            lines.append(f"{stem}mode.{i}={q(mode)}")
    lines.append(f"mapcount={len(local)}")
    for i, (path, (oid, mode)) in enumerate(local.items(), 1):
        lines += [
            f"mapfn.{i}='F{i}'", f"mapft.{i}='TXT'", f"mapfm.{i}='A'",
            f"maplf.{i}=1", f"mapbase.{i}={q(oid)}",
            f"mapstage.{i}={q(oid)}", f"mappath.{i}={q(path)}",
        ]
    lines += [
        "call preparemerge",
        "say 'RC' result 'STRUCT' mergestructural 'CHANGED' mergechanged",
        "say 'CONFLICTS' mergeconflicts 'MAP' mapcount 'MODES' mergemodecount",
        "do i=1 to mapcount",
        " say 'ENTRY' mappath.i mapbase.i mapstage.i",
        "end",
        "do i=1 to mergemodecount",
        " say 'MODE' mergemodepath.i mergemodeval.i",
        "end",
        "say 'END'",
        "exit 0",
    ]
    stubs = """
rootfor:
 parse arg rfoid
 return rfoid
collecttree:
 parse arg ctroot
 if ctroot='B' then ctcount=bcount
 else if ctroot='L' then ctcount=lcount
 else ctcount=rcount
 ccount=ctcount
 do cti=1 to ccount
  if ctroot='B' then do
   cpath.cti=bpath.cti; coid.cti=boid.cti; cmode.cti=bmode.cti
  end
  else if ctroot='L' then do
   cpath.cti=lpath.cti; coid.cti=loid.cti; cmode.cti=lmode.cti
  end
  else do
   cpath.cti=rpath.cti; coid.cti=roid.cti; cmode.cti=rmode.cti
  end
 end
 return 'OK'
findpath:
 parse arg fpwanted
 do fpi=1 to mapcount
  if mappath.fpi=fpwanted then return fpi
 end
 return 0
allocatename:
 allocfn='NEW'||right(synnext,3,'0')
 allocft='GITF'
 synnext=synnext+1
 return 'OK'
readloose:
 readtype='BLOB'
 return 'OK'
bodyrecords:
 rec.0=1
 rec.1='414243'
 final=1
 return 'OK'
stubmodes:
 return 'OK'
"""
    routines = WT[WT.index("addmergepath:\n"):WT.index("lcsmatches:\n")]
    routines = routines.replace("call writemergemodes", "call stubmodes")
    source = "\n".join(lines) + "\n" + stubs + routines
    with tempfile.TemporaryDirectory() as td:
        path = Path(td) / "m305.rexx"
        path.write_text(source)
        Path("/tmp/m305-fail.rexx").write_text(source)
        subprocess.run(["rexx", "-c", str(path), "/dev/null"], check=True,
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        result = subprocess.run(["rexx", str(path)],
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                text=True)
        if result.returncode != 0:
            raise AssertionError(result.stdout + result.stderr)
    lines = result.stdout.splitlines()
    start = next((i for i, line in enumerate(lines) if line.startswith("RC ")), None)
    assert start is not None, result.stdout
    output = lines[start:]
    assert output[-1] == "END", result.stdout
    return output


def prepared(output):
    first = output[0].split()
    second = output[1].split()
    entries = [line.split() for line in output if line.startswith("ENTRY ")]
    modes = [line.split() for line in output if line.startswith("MODE ")]
    return {
        "rc": first[1], "struct": int(first[3]), "changed": int(first[5]),
        "conflicts": int(second[1]), "map": int(second[3]), "modes": int(second[5]),
        "entries": {row[1]: (row[2], row[3]) for row in entries},
        "mode_entries": {row[1]: row[2] for row in modes},
    }


ZERO = "0000000000000000000000000000000000000000"
out = run_prepare({"61": ("A", "100644")},
                  {"61": ("A", "100644")},
                  {"61": ("A", "100644"), "62": ("X", "100644")})
state = prepared(out)
assert state["rc"] == "CONFLICT" and state["struct"] == 1 and state["map"] == 2
assert state["entries"]["62"] == (ZERO, "X")

out = run_prepare({"61": ("A", "100644"), "62": ("B", "100644")},
                  {"61": ("A", "100644"), "62": ("B", "100644")},
                  {"61": ("A", "100644")})
state = prepared(out)
assert state["rc"] == "CONFLICT" and state["struct"] == 1
assert state["entries"]["62"] == ("B", ZERO)

out = run_prepare({"61": ("A", "100644")},
                  {"61": ("A", "100644")},
                  {"61": ("A", "100755")})
state = prepared(out)
assert state["rc"] == "CONFLICT" and state["struct"] == 1
assert state["entries"]["61"] == ("A", "A")
assert state["mode_entries"] == {"61": "100755"}

out = run_prepare(
    {"61": ("A", "100644"), "62": ("B", "100644"), "63": ("C", "100644")},
    {"61": ("A", "100644"), "62": ("B", "100644"), "63": ("C", "100644")},
    {"61": ("A", "100755"), "63": ("C", "100644"), "64": ("D", "100755")},
)
state = prepared(out)
assert state["rc"] == "CONFLICT" and state["struct"] == 1 and state["map"] == 4
assert state["entries"]["62"] == ("B", ZERO)
assert state["entries"]["64"] == (ZERO, "D")
assert state["mode_entries"] == {"61": "100755", "64": "100755"}

out = run_prepare({"61": ("A", "100644")},
                  {"61": ("L", "100644")},
                  {"61": ("R", "100755")})
state = prepared(out)
assert state["rc"] == "CONFLICT" and state["struct"] == 1
assert state["mode_entries"] == {"61": "100755"}

for base, local, remote in (
    ({"61": ("A", "100644")}, {"61": ("L", "100644")}, {}),
    ({}, {"61": ("L", "100644")}, {"61": ("R", "100644")}),
):
    out = run_prepare(base, local, remote)
    state = prepared(out)
    assert state["rc"] == "ERROR", out

print("M305 STRUCTURAL MERGE HOST GUARDS PASS 8")
