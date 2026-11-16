#!/usr/bin/env python3
"""
CMS stress test runner inside cms-git.
Executes a curated set of CMS commands against the live CMS target using
the existing cms_telnet_driver, and records per-command timings, outputs,
and gaps. Commands are allowed to finish; CMS timings over 120s are filed
as GitHub issues, and other command gaps can be posted with CMS_STRESS_ISSUES=1.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path
from typing import List, Dict, Any, NamedTuple

def _find_driver() -> str:
    # Prefer environment override
    env_root = os.environ.get("CMS_TOOLING_ROOT")
    if env_root:
        p = os.path.join(env_root, "cms_telnet_driver.py")
        if os.path.exists(p):
            return p
    # Known locations relative to this repo
    candidates = [
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "cms-tooling", "cms_telnet_driver.py")),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "cms-tooling", "cms_telnet_driver.py")),
    ]
    for cand in candidates:
        if os.path.exists(cand):
            return cand
    # Fallback: search up to a shallow depth in HOME
    home = os.path.expanduser("~")
    max_depth = 3
    for root, dirs, files in os.walk(home):
        if "cms_telnet_driver.py" in files:
            return os.path.join(root, "cms_telnet_driver.py")
        if root[len(home):].count(os.sep) >= max_depth:
            dirs[:] = []
    raise SystemExit("cms_telnet_driver.py not found in known locations")

REPO_ROOT = Path(__file__).resolve().parents[1]
CMS_DRIVER = [sys.executable, _find_driver()]

COMMANDS = [
    # Version identity for the installed runtime overlay.
    "GIT VERSION",
    "GIT LEVEL",
    # Item 1: read-only command/argument coverage.
    "GIT BRANCH --show-current",
    "GIT BRANCH --list",
    "GIT TAG --list",
    "GIT REMOTE",
    "GIT LOG -n 1",
    "GIT LOG --max-count 1",
    "GIT LOG -n 16",
    "GIT LOG -n 1 main",
    "GIT SHOW HEAD",
    "GIT SHOW main",
    "GIT REV-PARSE HEAD",
    "GIT REV-PARSE main",
    "GIT DIFF --name-only",
    "GIT DIFF --cached --name-only",
]

class Result(NamedTuple):
    command: str
    ok: bool
    output: str
    duration: float
    cms_duration: float

def run_cmd(cmd: str) -> Result:
    t0 = time.time()
    # Do not stop a command at the 120-second issue threshold. Let it finish
    # and report its actual runtime; the driver timeout is set far beyond any
    # expected run so the stress script itself can continue and log results.
    proc = subprocess.run(CMS_DRIVER + ["run", cmd, "--timeout", "315360000"],
                          stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT,
                          text=True)
    duration = time.time() - t0
    ready_times = re.findall(r"Ready(?:\([^)]*\))?; T=([0-9.]+)/([0-9.]+)", proc.stdout)
    cms_duration = max(map(float, ready_times[-1])) if ready_times else duration
    return Result(cmd, proc.returncode == 0, proc.stdout, duration, cms_duration)

def post_issue(title: str, body: str) -> bool:
    # Prefer gh on PATH, else fall back to ~/bin/gh if present
    gh_path = shutil.which("gh")
    if gh_path is None:
        alt = os.path.expanduser("~/bin/gh")
        if os.path.exists(alt):
            gh_path = alt
    if not gh_path:
        print("GH CLI not found; skipping GitHub issue creation for stress gaps.", file=sys.stderr)
        return False
    cmd = [gh_path, "issue", "create", "--title", title, "--body", body]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                           text=True, cwd=REPO_ROOT)
    if result.returncode:
        print(f"GitHub issue creation failed: {result.stdout.strip()}", file=sys.stderr)
        return False
    print(result.stdout.strip())
    return True

def main() -> int:
    results: List[Dict[str, Any]] = []
    slow_threshold = 120.0
    gaps: List[str] = []
    auto_issues = os.environ.get("CMS_STRESS_ISSUES", "0") in ("1","true","yes","y")
    created: List[str] = []

    for c in COMMANDS:
        r = run_cmd(c)
        print(f"[CMS-STRESS] {c} -> duration={r.duration:.2f}s, ok={r.ok}")
        results.append({
            "command": c,
            "ok": r.ok,
            "duration_s": round(r.duration, 2),
            "cms_duration_s": round(r.cms_duration, 2),
            "output_snippet": r.output[:500]
        })
        if r.cms_duration > slow_threshold:
            note = f"Slow CMS command: {c} took {r.cms_duration:.1f}s per CMS Ready timing (wall {r.duration:.1f}s)"
            gaps.append(note)
            timestamp = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
            title = f"Slow CMS command over 120 seconds: {c}"
            body = (f"CMS command exceeded the 120-second response threshold.\n\n"
                    f"- Command: `{c}`\n- CMS Ready timing: {r.cms_duration:.2f}s\n"
                    f"- Wall time: {r.duration:.2f}s\n- Observed: {timestamp}\n\n"
                    f"Output excerpt:\n\n```text\n{r.output[-2000:]}\n```\n")
            if post_issue(title, body):
                created.append(title)
        if not r.ok:
            gaps.append(f"CMS command failed: {c} RC != 0; output begins: {r.output[:200]}")

    if auto_issues and gaps:
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
        for idx, note in enumerate(gaps, start=1):
            if note.startswith("Slow CMS command:"):
                continue  # already filed immediately as a dedicated slow issue
            title = f"CMS stress gap #{idx} at {timestamp}"
            body = f"Gap #{idx} (CMS stress run):\n\n{note}\n\nSee stress_cms_results.json for full results."
            if post_issue(title, body):
                created.append(title)
        if created:
            print("Posted stress gaps to GitHub:", ", ".join(created))

    payload = {
        "timestamp": int(time.time()),
        "results": results,
        "gaps": gaps
    }
    (REPO_ROOT / "stress_cms_results.json").write_text(
        json.dumps(payload, indent=2))
    print("CMS stress run complete. See stress_cms_results.json for details.")
    if gaps:
        print("GAPS recorded in stress_cms_results.json.")
        if not auto_issues:
            print("Set CMS_STRESS_ISSUES=1 to file non-slow command gaps; "
                  "commands over 120s are filed automatically.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
