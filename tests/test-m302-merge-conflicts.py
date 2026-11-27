#!/usr/bin/env python3
"""M302: host guards for persistent merge conflicts and abort/continue.

These checks pin the CMS lifecycle around M301 local merge.  They do not
replace the real CMS fixture recorded in NOTES.md.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
GIT = (ROOT / "src" / "GIT.EXEC").read_text()
WT = (ROOT / "src" / "GITWT.EXEC").read_text()

assert "if command='MERGE' then do" in GIT
merge = GIT.split("if command='MERGE' then do", 1)[1].split("\nend\n", 1)[0]
for token in (
    "translate(mrgarg)='--ABORT'",
    "translate(mrgarg)='--CONTINUE'",
    "STATE GITMERG MERGE' objectfm",
    "EXEC GITWT --FM' objectfm 'MERGE-ABORT",
    "call mergecontinue",
    "EXEC GITWT --FM' objectfm 'MERGE-CONFLICT-STACK",
    "if mgrc=12 then do",
    "conflicts recorded; branch unchanged",
    "GIT MERGE --continue",
    "GIT MERGE --abort",
):
    assert token in merge, token

assert "mergecontinue:" in GIT
continue_helper = GIT.split("mergecontinue:", 1)[1].split("mergeancestor:", 1)[0]
for token in (
    "EXEC GITWT --FM' objectfm 'MERGE-CONTINUE",
    "COMMIT-STAGED",
    "MERGE-PARENT",
    "EXEC GIT --FM' objectfm 'UPDATE-REF",
    "EXEC GITWT --FM' objectfm 'ACCEPT",
    "EXEC GITWT --FM' objectfm 'MERGE-CLEAR",
    "MERGE CONTINUE COMPLETE",
    "say mcout.mci",
):
    assert token in continue_helper, token

for token in (
    "if command='MERGE-ABORT' then do",
    "if command='MERGE-CLEAR' then do",
    "if command='MERGE-CONFLICT' | command='MERGE-CONFLICT-STACK' then do",
    "if command='MERGE-CONTINUE' then do",
    "writemergestate:",
    "readmergestate:",
    "clearmergestate:",
    "buildconflictmarkers:",
    "applymergestage:",
    "abortmerge:",
    "workhasmarkers:",
    "'<<<<<<< HEAD'",
    "'======='",
    "'>>>>>>> '||mergeremotebranch",
    "GITMRG BLOB' objectfm",
    "call workoid 'GITMRG','BLOB',objectfm,1,1",
    "MERGE CONFLICT",
    "exit 12",
    "mergeactive=2",
    "if mergeactive>=1 then",
    "'-P' parent '-P' mergeparent",
    "state='CONFLICT'",
    "state='RESOLVED'",
    "say 'UU '||p",
    "merge in progress; use GIT MERGE --continue",
    "if scanfn='GITMERG' | scanfn='GITMRG' | scanfn='GITMODE' then iterate",
):
    assert token in WT, token

# Rewrites and rollback must truncate old fixed-80 records first.
assert "'ERASE' mapfn.apsi mapft.apsi mapfm.apsi" in WT
assert "'ERASE' mapfn.abi mapft.abi mapfm.abi" in WT
assert "call pathoidfor mslocal,mappath.abi\n  if result='ERROR'" in WT
rollback = WT.split("rollbackrestore:", 1)[1].split("writemergestate:", 1)[0]
assert "'ERASE' rfn rft rfm" in rollback
assert "call writework rfn,rft,rfm" in rollback

markers = WT.split("workhasmarkers:", 1)[1].split("preflightpull:", 1)[0]
assert "if whline='<<<<<<< HEAD' then return 1" in markers
assert "left(whline,7)='======='" not in markers

# State framing is count-checked and uses computed indexes, not stem.(expr).
state = WT.split("readmergestate:", 1)[1].split("clearmergestate:", 1)[0]
for token in (
    "msr.0\\=8+msconflicts",
    "msconflicts<0",
    "msidx=7+msi",
    "msidx=8+msconflicts",
    "mspath.msi=mspathhex",
):
    assert token in state, token
assert not re.search(r"msr\.7\+msi", state)

for name, source in (("GIT.EXEC", GIT), ("GITWT.EXEC", WT)):
    for number, line in enumerate(source.splitlines(), 1):
        assert len(line) <= 80, f"{name}:{number} exceeds 80 columns"

sections = (
    ("GIT MERGE", merge),
    ("GIT mergecontinue", continue_helper),
    ("GITWT merge commands", WT.split("if command='MERGE-ABORT'", 1)[1]
     .split("if command='CHECK-MERGE'", 1)[0]),
    ("GITWT merge continue", WT.split("if command='MERGE-CONTINUE'", 1)[1]
     .split("if command='COMMIT'", 1)[0]),
    ("GITWT conflict procedures", WT.split("rollbackrestore:", 1)[1]
     .split("preflightpull:", 1)[0]),
)
for name, source in sections:
    for line in source.splitlines():
        stripped = line.rstrip()
        assert not (stripped.endswith(",") and not stripped.endswith(("|,", "&,", "then,"))), (
            f"{name} has a CMS-REXX-invalid trailing comma")
    assert not re.search(r"parse upper arg [A-Za-z0-9_.]+ [A-Za-z0-9_.]+", source), name
    assert not re.search(r"=findpath\s+[A-Za-z]", source), name


def conflict_records(local, remote, branch):
    return ["<<<<<<< HEAD", *local, "=======", *remote, f">>>>>>> {branch}"]


assert conflict_records(["local"], ["remote"], "topic") == [
    "<<<<<<< HEAD", "local", "=======", "remote", ">>>>>>> topic"]
assert conflict_records([], [], "topic") == [
    "<<<<<<< HEAD", "=======", ">>>>>>> topic"]


class MergeState:
    def __init__(self, branch, local, remote, base, conflicts):
        self.branch = branch
        self.local = local
        self.remote = remote
        self.base = base
        self.conflicts = set(conflicts)
        self.resolved = set()
        self.active = True

    def stage(self, path):
        assert path in self.conflicts
        self.resolved.add(path)

    def can_continue(self):
        return self.active and self.resolved == self.conflicts

    def abort(self):
        assert self.active
        self.active = False
        self.resolved.clear()
        return self.local

    def continue_(self):
        assert self.can_continue()
        self.active = False
        return (self.local, self.remote)


state = MergeState("main", "L", "R", "B", {"a.txt", "b.txt"})
assert not state.can_continue()
state.stage("a.txt")
assert not state.can_continue()
state.stage("b.txt")
assert state.can_continue()
assert state.continue_() == ("L", "R")
assert not state.active

state = MergeState("main", "L", "R", "B", {"a.txt"})
assert state.abort() == "L"
assert not state.active and not state.resolved

print("M302 MERGE CONFLICT LIFECYCLE HOST GUARDS PASS")
