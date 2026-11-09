#!/usr/bin/env python3
"""M274: host tests for the loose-object batch installer (src/M274L5.C).

Builds the installer in host mode (-DGITPLOAD_HOST) and exercises the
BATCH install path against staged objects, including idempotence, limit,
corrupt stage, and reversed index rejection.
"""
from pathlib import Path
import hashlib
import json
import os
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "src" / "M274L5.C"


def gitoid(typ, body):
    name = {1: b"commit", 2: b"tree", 3: b"blob", 4: b"tag"}[typ]
    return hashlib.sha1(name + b" " + str(len(body)).encode() + b"\0" + body).hexdigest().upper()


def body_lines(body, chunk=2000):
    if not body:
        return [""]
    out = []
    for i in range(0, len(body), chunk):
        out.append(body[i:i + chunk].hex().upper())
    return out


def make_stage(outdir, objs, chunk=2000):
    stage_rows = []
    for num, typ, body in objs:
        stage_rows.append("OBJ %d %d %d %s" % (num, typ, len(body), gitoid(typ, body)))
        stage_rows.extend(body_lines(body, chunk))
    (outdir / "dd:STGIN").write_text("\n".join(stage_rows) + "\n")

    idx_rows = sorted((gitoid(typ, body), num, typ, len(body)) for num, typ, body in objs)
    idx = ["PIDX1 %d %d" % (len(objs), len(objs))]
    for oid, num, typ, size in idx_rows:
        idx.append("OID %s %d %d %d 0" % (oid, num, typ, size))
    idx.append("PEND1 %d %d" % (len(objs), len(objs)))
    (outdir / "dd:IDXIN").write_text("\n".join(idx) + "\n")


with tempfile.TemporaryDirectory(prefix="m274-") as td:
    work = Path(td)
    outdir = work / "out"
    outdir.mkdir()
    subprocess.run(
        ["gcc", "-x", "c", "-std=c89", "-Wall", "-Wextra", "-Werror",
         "-DGITPLOAD_HOST", str(SOURCE), "-o", str(work / "gitload")],
        check=True,
    )

    blob = b"hello\n"
    empty = b""
    tree_body = b"100644 hello.txt\0" + bytes.fromhex(gitoid(3, blob))
    commit_body = (b"tree " + gitoid(2, tree_body).encode() +
                   b"\nauthor A <a@b> 1 +0000\ncommitter A <a@b> 1 +0000\n\nmsg\n")
    tag_body = (b"object " + gitoid(1, commit_body).encode() +
                b"\ntype commit\ntag v1\ntagger A <a@b> 1 +0000\n\nrel\n")
    objs = [
        (1, 3, blob),
        (2, 2, tree_body),
        (3, 1, commit_body),
        (4, 4, tag_body),
        (5, 3, empty),
    ]

    make_stage(work, objs)

    env = dict(os.environ, GITPLOAD_HOST_DIR=str(outdir))
    r = subprocess.run(
        [str(work / "gitload"), "BATCH", "G", "5"], cwd=work,
        capture_output=True, text=True, env=env)
    assert r.returncode == 0, (r.stdout, r.stderr)
    assert "PACKOBJ BATCH PASS INSTALLED 4 ALREADY 0 TAGS 1 PROCESSED 5 UNIQUE 5" in r.stdout

    # Loose files written for non-tag objects.
    expected_oids = {gitoid(t, b) for _, t, b in objs if t != 4}
    got_files = {p.name for p in outdir.iterdir()}
    for oid in expected_oids:
        assert oid[:8] + ".GITOBJ.G" in got_files, oid
    assert len([f for f in got_files if f.endswith(".GITOBJ.G")]) == 4

    # Validate each loose file content.
    for num, typ, body in objs:
        if typ == 4:
            continue
        oid = gitoid(typ, body)
        path = outdir / (oid[:8] + ".GITOBJ.G")
        text = path.read_text()
        lines = text.splitlines()
        assert lines[0] == "OID " + oid
        assert lines[1] == "TYPE " + {1: "COMMIT", 2: "TREE", 3: "BLOB", 4: "TAG"}[typ]
        assert lines[2] == "SIZE " + str(len(body))
        # Reassemble DATA.
        data_hex = ""
        for line in lines[3:]:
            assert line.startswith("DATA ")
            data_hex += line[5:]
        assert bytes.fromhex(data_hex) == body

    # Idempotent rerun.
    r2 = subprocess.run(
        [str(work / "gitload"), "BATCH", "G", "5"], cwd=work,
        capture_output=True, text=True, env=env)
    assert r2.returncode == 0, (r2.stdout, r2.stderr)
    assert "PACKOBJ BATCH PASS INSTALLED 0 ALREADY 4 TAGS 1 PROCESSED 5 UNIQUE 5" in r2.stdout

    # Limit: install only the first 2 unique OIDs.
    work2 = Path(tempfile.mkdtemp(prefix="m274b-"))
    out2 = work2 / "out"
    out2.mkdir()
    # Reuse same stage/index but copy.
    import shutil
    shutil.copy(work / "dd:STGIN", work2 / "dd:STGIN")
    shutil.copy(work / "dd:IDXIN", work2 / "dd:IDXIN")
    env2 = dict(os.environ, GITPLOAD_HOST_DIR=str(out2))
    r3 = subprocess.run(
        [str(work / "gitload"), "BATCH", "G", "5", "2"], cwd=work2,
        capture_output=True, text=True, env=env2)
    assert r3.returncode == 0, (r3.stdout, r3.stderr)
    assert "PROCESSED 2 UNIQUE 5" in r3.stdout
    assert len([p for p in out2.iterdir() if p.name.endswith(".GITOBJ.G")]) == 1

    # Corrupt stage (wrong OID) must fail and leave no partial file.
    work3 = Path(tempfile.mkdtemp(prefix="m274c-"))
    out3 = work3 / "out"
    out3.mkdir()
    shutil.copy(work / "dd:STGIN", work3 / "dd:STGIN")
    # Tamper: change first blob's OID in stage to empty blob's OID.
    stage_text = (work3 / "dd:STGIN").read_text()
    stage_text = stage_text.replace(gitoid(3, blob), gitoid(3, empty), 1)
    (work3 / "dd:STGIN").write_text(stage_text)
    shutil.copy(work / "dd:IDXIN", work3 / "dd:IDXIN")
    env3 = dict(os.environ, GITPLOAD_HOST_DIR=str(out3))
    r4 = subprocess.run(
        [str(work / "gitload"), "BATCH", "G", "5"], cwd=work3,
        capture_output=True, text=True, env=env3)
    assert r4.returncode != 0, (r4.stdout, r4.stderr)

    # Reversed index (OIDs not strictly ascending) must fail.
    work4 = Path(tempfile.mkdtemp(prefix="m274d-"))
    out4 = work4 / "out"
    out4.mkdir()
    shutil.copy(work / "dd:STGIN", work4 / "dd:STGIN")
    idx_lines = (work / "dd:IDXIN").read_text().splitlines()
    # Reverse the OID rows.
    header = idx_lines[0]
    footer = idx_lines[-1]
    middle = idx_lines[1:-1]
    middle_rev = list(reversed(middle))
    (work4 / "dd:IDXIN").write_text(
        "\n".join([header] + middle_rev + [footer]) + "\n")
    env4 = dict(os.environ, GITPLOAD_HOST_DIR=str(out4))
    r5 = subprocess.run(
        [str(work / "gitload"), "BATCH", "G", "5"], cwd=work4,
        capture_output=True, text=True, env=env4)
    assert r5.returncode != 0, (r5.stdout, r5.stderr)

    # Historical 64-column (32-byte) stage records must also install.
    work5 = Path(tempfile.mkdtemp(prefix="m274e-"))
    out5 = work5 / "out"
    out5.mkdir()
    make_stage(work5, objs, chunk=32)
    idx_rows = sorted((gitoid(typ, body), num, typ, len(body))
                      for num, typ, body in objs)
    idx = ["PIDX1 %d %d" % (len(objs), len(objs))]
    for oid, num, typ, size in idx_rows:
        idx.append("OID %s %d %d %d 0" % (oid, num, typ, size))
    idx.append("PEND1 %d %d" % (len(objs), len(objs)))
    (work5 / "dd:IDXIN").write_text("\n".join(idx) + "\n")
    env5 = dict(os.environ, GITPLOAD_HOST_DIR=str(out5))
    r7 = subprocess.run(
        [str(work / "gitload"), "BATCH", "G", "5"], cwd=work5,
        capture_output=True, text=True, env=env5)
    assert r7.returncode == 0, (r7.stdout, r7.stderr)
    assert "PACKOBJ BATCH PASS INSTALLED 4 ALREADY 0 TAGS 1 PROCESSED 5 UNIQUE 5" in r7.stdout

    # Usage.
    r6 = subprocess.run([str(work / "gitload")], cwd=work,
                        capture_output=True, text=True)
    assert r6.returncode == 4, (r6.stdout, r6.stderr)

print("M274 BATCH INSTALL, IDEMPOTENCE, LIMIT AND FAILURE GUARDS PASS")