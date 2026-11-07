#!/usr/bin/env python3
"""Build a CMS ASCII-hex PACK + META for exactly one commit and its tree
closure (all trees and blobs reachable from the commit tree, no parents).

This is the production "shallow" fetch unit: small enough for a single CMS
minidisk and fast enough to import/activate in seconds.
"""
from __future__ import annotations

import os
import subprocess
import sys
import tempfile


def git(*args: str, data: bytes | None = None) -> bytes:
    return subprocess.run(
        ["git", *args],
        input=data,
        check=True,
        stdout=subprocess.PIPE,
    ).stdout


def closure_oids(commit: str) -> list[str]:
    root = git("rev-parse", f"{commit}^{{tree}}").decode().strip()
    listed = git("ls-tree", "-r", "-t", commit).decode()
    oids = [line.split()[2] for line in listed.splitlines() if line.strip()]
    # ls-tree lists entries under the tree but not the root tree itself.
    return [commit, root, *oids]


def main() -> int:
    if len(sys.argv) != 4:
        print("Usage: make-cms-pack.py <commit-oid> <out-prefix> <fmode>", file=sys.stderr)
        return 4
    commit, prefix, fmode = sys.argv[1:4]
    oids = closure_oids(commit)
    # --no-reuse-delta keeps the fixture deterministic and self-contained.
    # --delta-base-offset makes deltas OFS_DELTA (type 6); cms-git does not
    # implement REF_DELTA (type 7).
    pack = git("pack-objects", "--stdout", "--no-reuse-delta",
               "--delta-base-offset",
               data=("\n".join(oids) + "\n").encode())
    count = len(oids)
    version = int.from_bytes(pack[4:8], "big")
    objects = int.from_bytes(pack[8:12], "big")
    if version not in (2, 3) or objects != count:
        print(f"pack header mismatch: version={version} objects={objects} expected={count}",
              file=sys.stderr)
        return 8

    pack_path = f"{prefix}.{fmode}.PACK"
    with open(pack_path, "w", encoding="ascii", newline="\n") as f:
        for i in range(0, len(pack), 32):
            f.write(pack[i:i + 32].hex().upper() + "\n")
    meta_path = f"{prefix}.{fmode}.META"
    with open(meta_path, "w", encoding="ascii", newline="\n") as f:
        f.write(f"META {commit.upper()} {len(pack)} {version} {objects}\n")
    print(f"wrote {pack_path} ({len(pack)} decoded bytes, {count} objects)")
    print(f"wrote {meta_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
