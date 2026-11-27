#!/usr/bin/env python3
"""M304: host guards for fetched-tip merge conflict orchestration."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
GIT = (ROOT / "src" / "GIT.EXEC").read_text()
WT = (ROOT / "src" / "GITWT.EXEC").read_text()

assert "if command='PULL' then do" in GIT
pull = GIT.split("if command='PULL' then do", 1)[1].split(
    "/* M281: push local commits", 1)[0]

for token in (
    "pullconflict=0",
    "pullautomerge=0",
    "pullupdated=0",
    "if mergecheckrc=12 then do",
    "queue currentbranch",
    "queue pullold",
    "queue pullnew",
    "queue pullbase",
    "queue branchfromremote",
    "mergecmd='EXEC GITWT MERGE-CONFLICT-STACK'",
    "if mergeconflictrc=12 then pullconflict=1",
    "else if mergeconflictrc=13 then pullautomerge=1",
    "pulltarget=pullold",
    "if pullconflict=0 & pullautomerge=0 then do",
    "if pulltarget\\=pullold & pullconflict=0 & pullautomerge=0 then do",
    "'EXEC GIT FETCH-TRACK' pullremote branchfromremote pullnew oldtracking",
    "if pullconflict=1 then do",
    "PULL CONFLICTS RECORDED",
    "Resolve and stage conflicts, then run GIT MERGE --continue",
    "Or run GIT MERGE --abort to restore the pre-merge worktree",
    "if pullautomerge=1 then do",
    "call mergecontinue",
    "pulltarget=mccommit",
    "pullupdated=1",
    "if pullupdated=0 then do",
    "'EXEC GITUPD PULL-HEAD' currentbranch pullold pulltarget",
    "PULL COMPLETE",
    "PULL REMOTE TIP",
):
    assert token in pull, token

prepare = pull.split("if mergecheckrc=12 then do", 1)[1].split(
    "else if mergecheckrc", 1)[0]
assert prepare.count("'MAKEBUF'") == 1
assert prepare.count("'DROPBUF' mcbuf") == 1
assert "do while queued()>0" in prepare
assert "mergeconflictrc=rc" in prepare
assert pull.index("'EXEC GIT FETCH-ACTIVATE'") < pull.index(
    "if mergecheckrc=12 then do")
assert pull.index("if mergecheckrc=12 then do") < pull.index(
    "'EXEC GIT FETCH-TRACK'")
clean_commit = pull.split("if pullconflict=0 & pullautomerge=0 then do", 1)[1]
clean_commit = clean_commit.split("if pulltarget\\=pullold", 1)[0]
assert "EXEC GITWT MERGE-COMMIT-STACK" in clean_commit

conflict = pull.split("if pullconflict=1 then do", 1)[1].split(
    "if pullautomerge=1 then do", 1)[0]
assert "exit 8" in conflict
assert "GITUPD PULL-HEAD" not in conflict
assert "call mergecontinue" not in conflict

auto = pull.split("if pullautomerge=1 then do", 1)[1].split(
    "if pullupdated=0 then do", 1)[0]
assert "call mergecontinue" in auto
assert "pulltarget=mccommit" in auto
assert "pullupdated=1" in auto
assert "GITUPD PULL-HEAD" not in auto
assert pull.index("'EXEC GIT FETCH-TRACK'") < pull.index(
    "if pullautomerge=1 then do")

for token in (
    "if command='MERGE-ABORT' then do",
    "if command='MERGE-CONTINUE' then do",
    "writemergestate:",
    "'STATE GITMERG MERGE G'",
):
    assert token in WT, token

for line in pull.splitlines():
    assert len(line) <= 80, line
assert not re.search(r"parse upper arg [A-Za-z0-9_.]+ [A-Za-z0-9_.]+", pull)


class PullMerge:
    def __init__(self, local, remote):
        self.local = local
        self.remote = remote
        self.tracking = local
        self.branch = local
        self.active = False

    def conflict(self):
        self.active = True
        self.tracking = self.remote
        return self.branch

    def abort(self):
        assert self.active
        self.active = False
        self.branch = self.local
        return self.branch

    def auto_continue(self, merge_commit):
        assert self.active
        self.branch = merge_commit
        self.active = False
        return self.branch


state = PullMerge("LOCAL", "REMOTE")
assert state.conflict() == "LOCAL"
assert state.tracking == "REMOTE" and state.active
assert state.abort() == "LOCAL"
assert state.tracking == "REMOTE" and not state.active

state = PullMerge("LOCAL", "REMOTE")
state.conflict()
assert state.auto_continue("MERGE") == "MERGE"
assert state.tracking == "REMOTE" and not state.active

print("M304 PULL CONFLICT ORCHESTRATION HOST GUARDS PASS")
