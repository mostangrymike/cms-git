#!/usr/bin/env python3
"""M309: host guards for bounded record-level GIT DIFF content output."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WT = (ROOT / "src" / "GITWT.EXEC").read_text()

assert "/* M309: read a verified blob as CMS record text for content diff. */" in WT
assert "diffblobtorec:" in WT
assert "call readrestoreblob dbr_oid" in WT
assert "call bodyrecords dbrhex" in WT

start = WT.index("if command='DIFF' then do")
end = WT.index("/* M273: apply a clean fast-forward")
diff = WT[start:end]

for token in (
    "--NAME-ONLY' then diffnameonly=1",
    "if diffpaths>16 then do",
    "if diffnameonly=1 then do",
    "M309: bounded record-level content diff against the LCS matcher",
    "call diffblobtorec diffold",
    "call diffblobtorec diffnew",
    "'EXECIO * DISKR' mapfn.i mapft.i mapfm.i '1 (STEM MX. FINIS'",
    "say 'DIFF CONTENT' path diffold diffnew",
    "call lcsmatches mb.0,mx.0",
    "if result='LIMIT' then do",
    "say 'DIFF TOO LARGE' path",
    "say 'DIFF -' doldpos mb.doldpos",
    "say 'DIFF +' dnewpos mx.dnewpos",
    "say 'DIFF END' path",
):
    assert token in diff, token

# Name-only remains the opt-in compact form; content is now the default.
assert "if diffnameonly=0 | diffpaths>16 then" not in diff
assert diff.count("say path") == 1

for number, line in enumerate(WT.splitlines(), 1):
    assert len(line) <= 80, (number, line)


def lcs_match(old, new):
    """Model the REXX lcsmatches mapping: old index -> matching new index."""
    rows = len(old) + 1
    cols = len(new) + 1
    dp = [[0] * cols for _ in range(rows)]
    for i in range(1, rows):
        for j in range(1, cols):
            if old[i - 1] == new[j - 1]:
                dp[i][j] = dp[i - 1][j - 1] + 1
            else:
                dp[i][j] = max(dp[i - 1][j], dp[i][j - 1])
    match = [0] * (rows - 1)
    i, j = rows - 1, cols - 1
    while i > 0 and j > 0:
        if old[i - 1] == new[j - 1]:
            match[i - 1] = j
            i -= 1
            j -= 1
        elif dp[i - 1][j] >= dp[i][j - 1]:
            i -= 1
        else:
            j -= 1
    return match


def diff_lines(old, new):
    """Model the REXX line walk over the LCS match map."""
    match = lcs_match(old, new)
    out = []
    p, q = 1, 1
    while p <= len(old) or q <= len(new):
        if p <= len(old) and q <= len(new) and match[p - 1] == q:
            p += 1
            q += 1
            continue
        if p <= len(old) and match[p - 1] == 0:
            out.append(("-", p, old[p - 1]))
            p += 1
            continue
        if q <= len(new):
            out.append(("+", q, new[q - 1]))
            q += 1
        elif p <= len(old):
            out.append(("-", p, old[p - 1]))
            p += 1
    return out


assert diff_lines(["A", "B", "C"], ["A", "X", "C"]) == [
    ("-", 2, "B"), ("+", 2, "X")]
assert diff_lines(["A"], []) == [("-", 1, "A")]
assert diff_lines([], ["A"]) == [("+", 1, "A")]
assert diff_lines(["A", "B"], ["A", "B"]) == []
assert diff_lines(["A", "B"], ["A", "B", "C"]) == [("+", 3, "C")]
assert diff_lines(["A", "B", "C"], ["A", "C"]) == [("-", 2, "B")]

# The bounded matcher refuses inputs over the existing merge ceilings.
for old_count, new_count in ((2049, 1), (1, 2049)):
    assert old_count > 2048 or new_count > 2048

print("M309 CONTENT DIFF HOST GUARDS PASS 6")
