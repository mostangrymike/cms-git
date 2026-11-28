#!/usr/bin/env python3
"""End-to-end CMS gate: one session, measured commands, defect issues.

Runs a curated read-only suite against production G and a disposable write
suite against 0601 B. Every command is timed from the CMS Ready record and
from the wall clock. Any command over 120 seconds is a defect, as is any
unexpected RC or missing expected output. Defects are filed on GitHub; a
known issue number can be supplied so evidence is appended instead of opening
a duplicate issue.

Usage (from the cms-tooling checkout, which owns the REXX driver):

  .venv/bin/python ../cms-git/scripts/e2e_cms.py
"""
from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
TOOLING = REPO.parent / "cms-tooling"
if str(TOOLING) not in sys.path:
    sys.path.insert(0, str(TOOLING))

from cms_telnet_driver import CmsSession, CmsTimeout  # noqa: E402
from cms_ftpput import get_files_on_session  # noqa: E402

SLOW_S = 120.0
CMD_TIMEOUT = 150.0
READY_RE = re.compile(r"Ready(?:\([^)]*\))?;\s*T=([0-9.]+)/([0-9.]+)")
OID_RE = re.compile(r"\b[0-9A-F]{40}\b")
MARKER = "cms-git e2e gate"


def cms_seconds(output: str) -> float:
    matches = READY_RE.findall(output)
    return max((float(pair[1]) for pair in matches), default=0.0)


def gh() -> str | None:
    path = shutil.which("gh") or str(Path.home() / "bin" / "gh")
    return path if Path(path).is_file() else None


def issue_titles() -> set[str]:
    exe = gh()
    if not exe:
        return set()
    proc = subprocess.run(
        [exe, "issue", "list", "--state", "all", "--limit", "200",
         "--json", "title"],
        cwd=REPO, capture_output=True, text=True)
    if proc.returncode:
        return set()
    return {item["title"] for item in json.loads(proc.stdout)}


def post_issue(title: str, body: str, titles: set[str]) -> str | None:
    if title in titles:
        return "duplicate"
    exe = gh()
    if not exe:
        return None
    text = body + f"\n\n<!-- {MARKER} -->\n"
    proc = subprocess.run(
        [exe, "issue", "create", "--title", title, "--body", text],
        cwd=REPO, capture_output=True, text=True)
    if proc.returncode:
        print("issue create failed:", proc.stdout[-400:], file=sys.stderr)
        return None
    titles.add(title)
    return proc.stdout.strip()


def comment_issue(number: int, body: str) -> bool:
    exe = gh()
    if not exe:
        return False
    proc = subprocess.run(
        [exe, "issue", "comment", str(number), "--body", body],
        cwd=REPO, capture_output=True, text=True)
    return proc.returncode == 0


class Runner:
    def __init__(self, session: CmsSession):
        self.session = session
        self.results: list[dict] = []
        self.titles = issue_titles()
        self.defects: list[str] = []

    def run(self, name: str, command: str, *, expect_rc: int | None = 0,
            contains: str | None = None, known_issue: int | None = None,
            phase: str = "suite") -> dict:
        started = time.time()
        out = ""
        rc: int | None = None
        timed_out = False
        try:
            result = self.session.command(command, timeout=CMD_TIMEOUT,
                                          stream=False)
            out, rc = result.output, result.rc
        except CmsTimeout as exc:
            out, timed_out = str(exc), True
        wall = time.time() - started
        cms = cms_seconds(out)
        if timed_out:
            cms = max(cms, CMD_TIMEOUT)
            out += "\n[TIMEOUT] driver gave up after 150s; state must be inspected"
        # CMS prints "Ready;" with no explicit RC on success; the driver
        # reports that as rc=None. Treat it as zero.
        rc_ok = (rc in (None, 0)) if expect_rc == 0 else (rc == expect_rc)
        ok = rc_ok and (contains is None or contains in out) and \
            cms <= SLOW_S and not timed_out
        record = {
            "name": name, "command": command, "phase": phase,
            "rc": rc, "expect_rc": expect_rc, "contains": contains,
            "cms_seconds": round(cms, 2), "wall_seconds": round(wall, 2),
            "ok": ok, "output": out[-3000:],
        }
        self.results.append(record)
        print(f"[E2E] {name}: rc={rc} cms={cms:.1f}s wall={wall:.1f}s "
              f"ok={ok}", flush=True)
        if not ok:
            reasons = []
            if timed_out or cms > SLOW_S:
                reasons.append(f"exceeded {SLOW_S:.0f}s "
                               f"(cms={cms:.1f}s, wall={wall:.1f}s)")
            if not rc_ok:
                reasons.append(f"rc={rc}, expected {expect_rc}")
            if contains is not None and contains not in out:
                reasons.append(f"missing output {contains!r}")
            reason = "; ".join(reasons)
            if known_issue:
                body = (f"End-to-end CMS gate reproduced a known defect.\n\n"
                        f"- Command: `{command}`\n- Finding: {reason}\n\n"
                        f"```text\n{out[-2000:]}\n```")
                comment_issue(known_issue, body)
                self.defects.append(f"#{known_issue}: {name} ({reason})")
            else:
                title = f"CMS end-to-end defect: {name}"
                body = (f"The end-to-end CMS gate found a defect.\n\n"
                        f"- Command: `{command}`\n- Finding: {reason}\n\n"
                        f"```text\n{out[-2000:]}\n```")
                created = post_issue(title, body, self.titles)
                self.defects.append(f"{title} -> {created}")
        return record


def main() -> int:
    with CmsSession() as session:
        session.connect()
        runner = Runner(session)

        runner.run("attach repository disk", "ACCESS 0601 B", phase="setup")

        # Snapshot disposable state before any write test.
        for fn, ft in (("GITREF2", "REPO"), ("GITWORK", "REPO"),
                       ("README", "TXT"), ("SECOND", "TXT")):
            session.command(f"ERASE {fn} M310BK B", timeout=30, stream=False)
            runner.run(f"backup {fn}",
                       f"COPYFILE {fn} {ft} B {fn} M310BK B (NEWFILE",
                       phase="setup")

        # Read-only production suite.
        for name, cmd, needle in (
            ("version", "GIT VERSION", None),
            ("level", "GIT LEVEL", None),
            ("current branch", "GIT BRANCH --show-current", None),
            ("branch list", "GIT BRANCH --list", None),
            ("tag list", "GIT TAG --list", None),
            ("remote list", "GIT REMOTE", None),
            ("status", "GIT STATUS", "STATUS SUMMARY"),
            ("short log", "GIT LOG -n 1", "VERIFIED COMMIT"),
            ("show head", "GIT SHOW HEAD", None),
            ("rev-parse", "GIT REV-PARSE HEAD", None),
            ("name-only diff", "GIT DIFF --name-only", None),
            ("content diff", "GIT DIFF", None),
            ("bounded log", "GIT LOG -n 16", None),
        ):
            known = 215 if name == "bounded log" else None
            runner.run(name, cmd, contains=needle, known_issue=known)

        # Disposable write suite on B.
        payload = Path("/tmp/cmsftp2/e2e-second.txt")
        payload.write_text("M306 incremental pull\nM309 e2e probe\n")
        get_files_on_session(session, [("e2e-second.txt", "SECOND E2E B")],
                             verbose=False)
        runner.run("stage modified workfile",
                   "COPYFILE SECOND E2E B SECOND TXT B (REPlace",
                   phase="write")
        runner.run("status after edit", "GIT --FM B STATUS",
                   contains="MODIFIED", phase="write")
        runner.run("content diff after edit", "GIT --FM B DIFF",
                   contains="DIFF +", phase="write")
        runner.run("stage path", "GIT --FM B ADD second.txt", phase="write")
        rec = runner.run("staged name-only diff",
                         "GIT --FM B DIFF --cached --name-only",
                         contains="second.txt", phase="write")
        runner.run("stash save", "GIT --FM B STASH", phase="write")
        runner.run("clean after stash", "GIT --FM B STATUS",
                   contains="CHANGED 0", phase="write")
        runner.run("stash pop", "GIT --FM B STASH POP", phase="write")
        runner.run("single-parent replay", "GIT --FM B LOG -n 1",
                   contains="COMMIT PARENTS 1", phase="write")
        runner.run("reject bad pick", "GIT --FM B CHERRY-PICK "
                   "0000000000000000000000000000000000000000",
                   expect_rc=8,
                   contains="cannot read picked commit", phase="write")

        # Restore the disposable repository to its pre-test state.
        session.command("ERASE GITSTASH REPO B", timeout=30, stream=False)
        for fn, ft in (("GITREF2", "REPO"), ("GITWORK", "REPO"),
                       ("README", "TXT"), ("SECOND", "TXT")):
            runner.run(f"restore {fn}",
                       f"COPYFILE {fn} M310BK B {fn} {ft} B (REPlace",
                       phase="restore")
        session.command("ERASE SECOND E2E B", timeout=30, stream=False)
        runner.run("restored clean status", "GIT --FM B STATUS",
                   contains="CHANGED 0", phase="restore")

    payload = REPO / "e2e_cms_results.json"
    payload.write_text(json.dumps({
        "timestamp": int(time.time()),
        "slow_threshold_s": SLOW_S,
        "results": runner.results,
        "defects": runner.defects,
    }, indent=2))
    bad = [r for r in runner.results if not r["ok"]]
    print(f"E2E complete: {len(runner.results)} commands, "
          f"{len(bad)} failures, {len(runner.defects)} defect records")
    print("Artifact:", payload)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
