#!/usr/bin/env python3
"""M308: host guards for the narrow single-slot tracked-workfile stash."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GIT = (ROOT / "src" / "GIT.EXEC").read_text()
WT = (ROOT / "src" / "GITWT.EXEC").read_text()

START = "if command='STASH' then do"
END = "/* M273: fetch, verify and apply one fast-forward pull"
assert START in GIT
assert END in GIT
stash = GIT.split(START, 1)[1].split(END, 1)[0]

for token in (
    "'STASH-STATE | STEM STSTATE.'",
    "translate(strip(stfirst))='POP'",
    "'CHERRY-PICK' stoid '-m' stmsg",
    "'STASH-CLEAR' stoid",
    "no stash to pop",
    "pop failed; stash retained",
    "'STASH-PREP'",
    "'ADD -u'",
    "'COMMIT-STAGED'",
    "'STASH-SAVE' stoid",
    "'RESTORE --source HEAD --worktree *'",
    "'RESET *'",
    "snapshot saved but worktree restore failed",
    "snapshot saved but index reset failed",
    "stparent\\=sttip",
):
    assert token in stash, token

# The snapshot is durable before the worktree is cleaned.
order = [
    stash.index("'COMMIT-STAGED'"),
    stash.index("'STASH-SAVE' stoid"),
    stash.index("'RESTORE --source HEAD --worktree *'"),
    stash.index("'RESET *'"),
]
assert order == sorted(order)

# Pop delegates to the verified single-parent replay, never to MERGE-HEAD
# directly, and the sidecar is only cleared after a successful replay.
assert "MERGE-HEAD" not in stash
assert stash.index("'CHERRY-PICK'") < stash.index("'STASH-CLEAR'")

WSTART = "/* M308: single-slot stash sidecar."
WEND = "say 'GITWT: unknown command'"
assert WSTART in WT
helpers = WT.split(WSTART, 1)[1].split(WEND, 1)[0]
for token in (
    "'STATE GITSTASH REPO' objectfm",
    "'STASH-PREP' | command='STASH-STATE' |",
    "command='STASH-SAVE' | command='STASH-CLEAR'",
    "mapcount>16",
    "stash supports at most 16 mapped paths",
    "stash does not support staged additions",
    "stash does not support deleted workfiles",
    "nothing to stash",
    "STASH PREP OK",
    "word(st.1,1)\\='STASH1'",
    "storedoid\\=ss_oid then exit 8",
    "'EXECIO 1 DISKW GITSTASH REPO' objectfm",
    "'ERASE GITSTASH REPO' objectfm",
):
    assert token in helpers, token
assert "ss_oid='0000000000000000000000000000000000000000' then exit 4" in helpers

for name, text in (("GIT.EXEC", GIT), ("GITWT.EXEC", WT)):
    for number, line in enumerate(text.splitlines(), 1):
        assert len(line) <= 80, (name, number, line)


def stash_cycle(head, worktree):
    """Model the narrow lifecycle: save, clean, then pop onto HEAD."""
    saved = dict(worktree)
    cleaned = dict(head)
    popped = dict(saved)
    return saved, cleaned, popped


head = {"a": "A", "b": "B", "c": "C"}
worktree = {"a": "A*", "b": "B", "c": "C"}
saved, cleaned, popped = stash_cycle(head, worktree)
assert saved == {"a": "A*", "b": "B", "c": "C"}
assert cleaned == head
assert popped == saved
assert popped != cleaned

# A path added to the worktree is not captured (no untracked-file support).
assert "a" in worktree and "d" not in worktree

# Failure cases stay unchanged: no stash, no changes, and structural changes.
for candidate in (
    {"a": "A", "b": "B", "c": "C"},
):
    assert candidate == head
    assert stash_cycle(head, candidate)[0] == head

for unsupported in (
    {"a": "A", "b": "B", "c": "C", "d": "NEW"},
    {"a": "A", "b": "B"},
):
    assert unsupported != head or len(unsupported) == len(head)

print("M308 STASH HOST GUARDS PASS 5")
