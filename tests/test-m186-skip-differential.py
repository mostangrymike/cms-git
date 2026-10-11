#!/usr/bin/env python3
"""M186 deterministic parity and corruption suite for native skip readers."""
from pathlib import Path
import hashlib
import random
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SOURCES = {
    "M181": "GITPHXM.C",
    "M183": "GITPH3M.C",
    "M185": "GITPH5M.C",
}
ALLOWED = "0123456789ABCDEFabcdef"
ILLEGAL = "GXYZgxyz@?_!"
SEED = 186


def oid(kind, data):
    prefix = (kind + " " + str(len(data))).encode() + b"\0"
    return hashlib.sha1(prefix + data).hexdigest().upper()


def make_stage(objects):
    rows = []
    positions = {}
    for n, (kind, typ, data) in enumerate(objects, 1):
        rows.append("OBJ %d %d %d %s" %
                    (n, typ, len(data), oid(kind, data)))
        positions[n] = len(rows)
        digits = data.hex().upper()
        if not digits:
            rows.append("")
        else:
            rows.extend(digits[i:i + 64]
                        for i in range(0, len(digits), 64))
    return rows, positions


def compile_c(source, target):
    subprocess.run(
        ["gcc", "-x", "c", "-std=c89", "-Wall",
         "-Wextra", "-Werror", str(source), "-o", str(target)],
        check=True
    )


with tempfile.TemporaryDirectory(prefix="m186-") as dirname:
    home = Path(dirname)
    modules = {}
    for label, source in SOURCES.items():
        modules[label] = home / label.lower()
        compile_c(ROOT / "src" / source, modules[label])
    indexer = home / "index"
    compile_c(ROOT / "src" / "GITPIDX.C", indexer)

    large = bytes(range(256)) * 8
    reachable = b"real SHA authentication"
    tree = (b"100644 note.txt\0" +
            bytes.fromhex(oid("blob", reachable)))
    root_oid = oid("tree", tree)
    rows, pos = make_stage([
        ("blob", 3, large),      # skipped on both scans
        ("blob", 3, reachable),  # selected only in pass two
        ("blob", 3, b""),        # skipped zero-length body
        ("tree", 2, tree),       # selected only in pass one
    ])
    original = "\n".join(rows) + "\n"
    stage = home / "dd:STGIN"
    idx = home / "dd:IDXIN"
    stage.write_text(original)
    built = subprocess.run(
        [str(indexer), "BUILD"], cwd=home,
        text=True, capture_output=True
    )
    assert built.returncode == 0, built.stdout + built.stderr
    shutil.copy(home / "dd:IDXOUT", idx)
    stagehash = hashlib.sha256(stage.read_bytes()).hexdigest()
    idxhash = hashlib.sha256(idx.read_bytes()).hexdigest()

    def check(candidate, label, expected=None):
        stage.write_text("\n".join(candidate) + "\n")
        outcomes = {}
        for key, module in modules.items():
            p = subprocess.run(
                [str(module), "WALK", root_oid], cwd=home,
                text=True, capture_output=True
            )
            outcomes[key] = p
        baseline = outcomes["M181"]
        result = outcomes["M185"]
        middle = outcomes["M183"]
        if expected is not None:
            assert (baseline.returncode == 0) == expected, (
                label, baseline.stdout, baseline.stderr)
        for name, p in outcomes.items():
            assert p.returncode == baseline.returncode, (
                label, name, baseline.stdout, p.stdout, p.stderr)
            assert p.returncode in (0, 8), (label, name, p.returncode)
            if p.returncode == 0:
                for line in (
                    "TREE CLOSURE ROOT " + root_oid,
                    "TREE CLOSURE TREES 1 BLOBS 1 GITLINKS 0",
                    "TREE CLOSURE ENTRIES 1 VERIFIED 2",
                    "TREE CLOSURE INDEX TOTAL 4 UNIQUE 4",
                    "AUTHENTICATED BLOBS 1",
                    "FORWARD SCANS 2 RECORDS 8 SEEKS 0",
                ):
                    assert line in p.stdout, (label, name, line, p.stdout)
                assert name + " TREE CLOSURE PASS" in p.stdout
            else:
                assert name + " TREE CLOSURE PASS" not in p.stdout
        assert result.returncode == middle.returncode
        assert hashlib.sha256(idx.read_bytes()).hexdigest() == idxhash
        return baseline.returncode == 0

    cases = 0
    valid = 0
    valid += check(rows, "original canonical", True)
    cases += 1

    for code in ("a", "f", "0", "9", "G", "g", "@", "?",
                 " ", "\t", "\r", "\x7f"):
        new = rows.copy()
        new[pos[1]] = code + rows[pos[1]][1:]
        islegal = code in ALLOWED
        valid += check(new, "first hex " + repr(code), islegal)
        cases += 1

    for altered, expected, label in (
        (rows[pos[1]][:-1], False, "short hex body"),
        (rows[pos[1]] + "A", False, "long hex body"),
        (rows[pos[1]][:-1] + " ", False, "space as nibble"),
        (rows[pos[1]][:10] + "G" + rows[pos[1]][11:],
         False, "invalid middle hex"),
    ):
        new = rows.copy()
        new[pos[1]] = altered
        valid += check(new, label, expected)
        cases += 1

    rng = random.Random(SEED)
    body_rows = list(range(pos[1], pos[2] - 1))
    for trial in range(160):
        new = rows.copy()
        row = rng.choice(body_rows)
        char = rng.randrange(len(new[row]))
        mutation = rng.choice(ALLOWED + ILLEGAL)
        new[row] = new[row][:char] + mutation + new[row][char+1:]
        valid += check(new, "seeded %d" % trial,
                       mutation in ALLOWED)
        cases += 1

    # Empty/unreachable blob must have a single EMPTY body record.
    for blank, expected in (("", True), ("X", False),
                            ("0", False), ("G", False)):
        new = rows.copy()
        new[pos[3]] = blank
        if blank == "":
            valid += check(new, "empty blob original", expected)
        else:
            valid += check(new, "empty blob mutation " + blank, False)
        cases += 1

    stage.write_text(original)
    assert hashlib.sha256(stage.read_bytes()).hexdigest() == stagehash
    assert hashlib.sha256(idx.read_bytes()).hexdigest() == idxhash
    print("M186 DETERMINISTIC SEED %d CASES %d ACCEPTED %d" %
          (SEED, cases, valid))
    print("M186 M181 M183 M185 POSITIVE AND NEGATIVE PARITY PASS")
    print("M186 HOST ONLY; NATIVE CMS EXECUTION NOT IMPLIED")
