#!/usr/bin/env python3
"""M190 synthetic live-scale Git stage/index: 7736 objects, 280 reached."""
from pathlib import Path
import hashlib
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
NOBJECTS = 7736
REACH_BLOBS = 272
TREES = 8
FILLER_BLOBS = NOBJECTS - REACH_BLOBS - TREES
SOURCES = {
    "M181": "GITPHXM.C",
    "M182": "GITPH2M.C",
    "M183": "GITPH3M.C",
    "M185": "GITPH5M.C",
    "M190": "GITPSKM.C",
}


def oid(kind, data):
    header = (kind + " " + str(len(data))).encode() + b"\0"
    return hashlib.sha1(header + data).hexdigest().upper()


def edge(mode, name, child):
    return (str(mode).encode() + b" " + name + b"\0" +
            bytes.fromhex(child))


def stage_data(objects):
    rows = []
    heads = []
    for num, (kind, typ, data) in enumerate(objects, 1):
        heads.append(len(rows))
        rows.append("OBJ %d %d %d %s" %
                    (num, typ, len(data), oid(kind, data)))
        hexdata = data.hex().upper()
        if hexdata:
            rows.extend(hexdata[i:i + 64]
                        for i in range(0, len(hexdata), 64))
        else:
            rows.append("")
    return rows, heads


def build(source, exe):
    subprocess.run(
        ["gcc", "-x", "c", "-std=c89", "-Wall", "-Wextra",
         "-Werror", str(source), "-o", str(exe)],
        check=True
    )


with tempfile.TemporaryDirectory(prefix="m187-") as temp:
    work = Path(temp)
    binaries = {}
    for key, file in SOURCES.items():
        binaries[key] = work / key.lower()
        build(ROOT / "src" / file, binaries[key])
    indexer = work / "index"
    build(ROOT / "src" / "GITPIDX.C", indexer)

    reachable = [
        ("blob", 3, ("reachable-file-%04d::payload" % i).encode())
        for i in range(REACH_BLOBS)
    ]
    extra = [
        ("blob", 3, ("unrelated-%06d::not-in-root" % i).encode())
        for i in range(FILLER_BLOBS)
    ]
    groups = [[] for _ in range(7)]
    for index, obj in enumerate(reachable):
        groups[index % 7].append((index, obj))
    children = []
    for folder, blobs in enumerate(groups):
        body = b"".join(
            edge(100644, ("f%04d.txt" % n).encode(),
                 oid("blob", obj[2]))
            for n, obj in blobs
        )
        children.append(("tree", 2, body))
    root_body = b"".join(
        edge(40000, ("dir%02d" % i).encode(),
             oid("tree", item[2]))
        for i, item in enumerate(children)
    )
    root = ("tree", 2, root_body)
    root_oid = oid("tree", root_body)
    objects = reachable + extra + children + [root]
    assert len(objects) == NOBJECTS
    assert len(set(oid(k, v) for k, _, v in objects)) == NOBJECTS
    assert sum(len(x) for x in groups) == REACH_BLOBS
    rows, headers = stage_data(objects)
    records = len(rows)
    stage_path = work / "dd:STGIN"
    index_path = work / "dd:IDXIN"
    full = "\n".join(rows) + "\n"
    stage_path.write_text(full)
    index_build = subprocess.run(
        [str(indexer), "BUILD"], cwd=work,
        text=True, capture_output=True
    )
    assert index_build.returncode == 0, (
        index_build.stdout, index_build.stderr)
    shutil.copy(work / "dd:IDXOUT", index_path)
    before = (
        hashlib.sha256(stage_path.read_bytes()).hexdigest(),
        hashlib.sha256(index_path.read_bytes()).hexdigest(),
    )

    def invoke(stage_text):
        stage_path.write_text(stage_text)
        outcomes = {}
        for name, module in binaries.items():
            result = subprocess.run(
                [str(module), "WALK", root_oid], cwd=work,
                capture_output=True, text=True
            )
            outcomes[name] = result
        return outcomes

    valid = invoke(full)
    for name, result in valid.items():
        assert result.returncode == 0, (
            name, result.stdout, result.stderr)
        for marker in (
            "TREE CLOSURE ROOT " + root_oid,
            "TREE CLOSURE TREES 8 BLOBS 272 GITLINKS 0",
            "TREE CLOSURE ENTRIES 279 VERIFIED 280",
            "TREE CLOSURE INDEX TOTAL 7736 UNIQUE 7736",
            "AUTHENTICATED BLOBS 272",

            name + " TREE CLOSURE PASS",
        ):
            assert marker in result.stdout, (name, marker, result.stdout)
        if name == "M190":
            assert "M190 FORWARD SCANS 1 RECORDS 7736 SEEKS 272" \
                in result.stdout
            assert ("M190 STAGE LINES FULL %d READBACK " % records) \
                in result.stdout
            assert "M190 SELECTIVE SEEK VALIDATOR PASS" in result.stdout
            assert "M190 SEEK PREFLIGHT PASS 3" in result.stdout
        else:
            assert (name + " FORWARD SCANS 2 RECORDS 15472 SEEKS 0") \
                in result.stdout
            assert (name +
                    " STAGE LINES PASS1 %d PASS2 %d" %
                    (records, records)) in result.stdout


    # Valid but different unreferenced bytes do not require SHA1.
    unrelated_row = headers[REACH_BLOBS] + 1
    good_lines = rows.copy()
    good_lines[unrelated_row] = (
        "A" if rows[unrelated_row][0] != "A" else "B"
    ) + rows[unrelated_row][1:]
    changed = invoke("\n".join(good_lines) + "\n")
    for name, result in changed.items():
        assert result.returncode == 0, (name, result.stdout)

    # Bad nonhex on an unreferenced blob is rejected even when skipped.
    bad_lines = rows.copy()
    bad_lines[unrelated_row] = "G" + rows[unrelated_row][1:]
    invalid = invoke("\n".join(bad_lines) + "\n")
    for name, result in invalid.items():
        assert result.returncode == 8, (name, result.stdout)
        assert name + " TREE CLOSURE PASS" not in result.stdout

    # A reached blob's valid-hex modification must fail Git SHA1.
    reached_row = headers[0] + 1
    bad_lines = rows.copy()
    bad_lines[reached_row] = (
        "A" if rows[reached_row][0] != "A" else "B"
    ) + rows[reached_row][1:]
    invalid = invoke("\n".join(bad_lines) + "\n")
    for name, result in invalid.items():
        assert result.returncode == 8, (name, result.stdout)
        assert name + " TREE CLOSURE PASS" not in result.stdout

    # Truncated end-of-stage must fail all readers closed.
    truncated = invoke("\n".join(rows[:-1]) + "\n")
    for name, result in truncated.items():
        assert result.returncode == 8, (name, result.stdout)

    stage_path.write_text(full)
    after = (
        hashlib.sha256(stage_path.read_bytes()).hexdigest(),
        hashlib.sha256(index_path.read_bytes()).hexdigest(),
    )
    assert before == after
    print("M190 INDEXED %d UNIQUE %d RECORDS %d" %
          (NOBJECTS, NOBJECTS, records))
    print("M190 REACHABLE TREES 8 BLOBS 272 ENTRIES 279 VERIFIED 280")
    print("M190 ONE SCAN 7736 HEADERS 272 SEEKS; FOUR TWO-SCAN BASELINES PASS")
    print("M190 NEGATIVE CORRUPTION AND IMMUTABILITY PASS")
    print("M190 SYNTHETIC HOST SEEK FIXTURE, NOT REAL CMS VALIDATION")
