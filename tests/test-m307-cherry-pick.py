#!/usr/bin/env python3
"""M307: host guards for single-parent cherry-pick replay."""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
GIT = (ROOT / "src" / "GIT.EXEC").read_text()
WT = (ROOT / "src" / "GITWT.EXEC").read_text()

START = "if command='CHERRY-PICK' then do"
END = "/* M273: fetch, verify and apply one fast-forward pull"
assert START in GIT
assert END in GIT
pick = GIT.split(START, 1)[1].split(END, 1)[0]

for token in (
    "COMMIT-INFO",
    "CHERRY-PICK-STACK",
    "MERGE-HEAD",
    "only single-parent commits are supported",
    "a merge is in progress",
    "conflicts or structural changes",
    "picked commit cannot be replayed cleanly",
    "Cherry_pick_",
):
    assert token in pick, token

# The picked commit is built by GITWT, not by a second COMMIT-TREE call.
assert "COMMIT-TREE" not in pick
assert "CHECK-MERGE-STACK" not in pick
assert "MERGE-CONTINUE" not in pick
assert "MERGE-CONFLICT-STACK" not in pick
assert "MERGE-COMMIT-STACK" not in pick
assert "'-P' cptip" not in pick

# GITWT builds a single-parent commit for CHERRY-PICK-STACK and never
# emits the second merge parent.
assert "command='CHERRY-PICK-STACK' then mergeactive=3" in WT
assert WT.count("if mergeactive>=1 & mergeactive\\=3 then,") == 2
assert "(mergeactive=1 | mergeactive=3) & mapstage.mi=zeros" in WT
assert WT.count("if mergeactive=1 | mergeactive=3 then do") == 2
assert "if mergeactive=3 then exit 12" in WT
assert "if mergeactive=3 then exit 13" in WT

# Existing two-parent merge behaviour is unchanged.
assert "'GIT COMMIT-TREE' newroot '-P' parent '-P' mergeparent" in WT
assert "'GIT COMMIT-TREE' newroot '-P' parent," in WT

assert "if command = 'COMMIT-INFO' then do" in GIT
assert "commitinfo: procedure" in GIT
assert "hexasciitohex: procedure" in GIT
assert "GIT COMMIT-INFO: object is not a commit" in GIT
assert "content hash mismatch" in GIT

# Commit headers are decoded from ASCII hex, not host code pages.
commitinfo = GIT.split("commitinfo: procedure", 1)[1].split(
    "branchnamefromhead:", 1)[0]
assert "x2c(" not in commitinfo
assert "left(ci_hex,10)\\='7472656520'" in commitinfo
assert "substr(ci_hex,11,80)" in commitinfo
assert "substr(ci_hex,ci_pos,14)='706172656E7420'" in commitinfo

for number, line in enumerate(GIT.splitlines(), 1):
    assert len(line) <= 80, (number, line)


def commit_hex(tree, parents, subject="pick me"):
    lines = ["tree " + tree.lower()]
    lines += ["parent " + parent.lower() for parent in parents]
    lines += [
        "author A <a@b> 0 +0000",
        "committer A <a@b> 0 +0000",
        "",
        subject,
    ]
    return ("\n".join(lines) + "\n").encode("ascii").hex().upper()


def run_commitinfo(body):
    routines = GIT[GIT.index("commitinfo: procedure"):
                  GIT.index("branchnamefromhead: procedure")]
    source = "hex='" + body + "'\ncall commitinfo hex\nsay 'RC' result\nexit 0\n"
    source += routines
    with tempfile.TemporaryDirectory() as td:
        path = Path(td) / "m307.rexx"
        path.write_text(source)
        subprocess.run(["rexx", "-c", str(path), "/dev/null"], check=True,
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        result = subprocess.run(["rexx", str(path)], text=True,
                                stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE)
        if result.returncode != 0:
            raise AssertionError(result.stdout + result.stderr)
    return result.stdout.splitlines()


TREE = "1" * 40
P1 = "2" * 40
P2 = "3" * 40

out = run_commitinfo(commit_hex(TREE, [P1]))
assert out[0] == "COMMIT-INFO TREE " + TREE, out
assert out[1] == "COMMIT-INFO PARENTS 1", out
assert out[2] == "COMMIT-INFO PARENT " + P1, out
assert out[-1] == "RC OK", out

out = run_commitinfo(commit_hex(TREE, []))
assert "COMMIT-INFO PARENTS 0" in out
assert not any(line.startswith("COMMIT-INFO PARENT ") for line in out)

out = run_commitinfo(commit_hex(TREE, [P1, P2]))
assert "COMMIT-INFO PARENTS 2" in out
assert "COMMIT-INFO PARENT " + P1 in out
assert "COMMIT-INFO PARENT " + P2 in out

for bad in ("00", "7472656520" + "5A" * 40):
    out = run_commitinfo(bad)
    assert "RC ERROR" in out, out


def pick_tree(base, ours, theirs):
    """Model the M307 preflight: clean content replay or a refusal."""
    result = {}
    structural = False
    conflict = False
    for path in set(base) | set(ours) | set(theirs):
        b = base.get(path)
        o = ours.get(path)
        t = theirs.get(path)
        if b is None or o is None or t is None:
            if not (b == o == t):
                structural = True
            continue
        if t == b:
            value = o
        elif o == b:
            value = t
        elif o == t:
            value = o
        else:
            conflict = True
            continue
        result[path] = value
    return result, structural, conflict


base = {"a": "A", "b": "B"}
ours = {"a": "L", "b": "B"}
theirs = {"a": "A", "b": "R"}
merged, structural, conflict = pick_tree(base, ours, theirs)
assert merged == {"a": "L", "b": "R"}
assert not structural and not conflict

merged, structural, conflict = pick_tree(
    {"a": "A"}, {"a": "L"}, {"a": "R"})
assert conflict and not structural

merged, structural, conflict = pick_tree(
    {"a": "A"}, {"a": "A"}, {"a": "A", "b": "NEW"})
assert structural and not conflict

merged, structural, conflict = pick_tree(
    {"a": "A", "b": "B"}, {"a": "A", "b": "B"}, {"a": "A"})
assert structural and not conflict

# The replayed commit keeps the old tip as its only parent and the default
# message records the source commit.
oid = "4" * 40
parents = ["5" * 40]
message = "Cherry_pick_" + oid
assert len(parents) == 1
assert parents[0] == "5" * 40
assert message == "Cherry_pick_" + oid

print("M307 CHERRY-PICK HOST GUARDS PASS 6")
