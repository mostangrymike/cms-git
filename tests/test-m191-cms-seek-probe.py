#!/usr/bin/env python3
"""M191 read-only direct CMS seek diagnostic regression, C89 host."""
from pathlib import Path
import hashlib
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
NATIVE = ROOT / "src/GITPRBM.C"
WRAPPER = ROOT / "src/GITPRB.EXEC"
IDX = ROOT / "src/GITPIDX.C"
for p in (NATIVE, WRAPPER):
    assert max(map(len, p.read_text().splitlines())) <= 80, p
src = NATIVE.read_text()
rex = WRAPPER.read_text()
for marker in ("M191 INDEX READY", "M191 SEEK BEGIN",
               "M191 SEEK RETURNED", "M191 SEEK HEADER PASS",
               "M191 READ ONLY SEEK PROBE PASS", "fflush(stdout)",
               "fseek(f,e->offset,SEEK_SET)", "ftell(f)!=e->offset"):
    assert marker in src, marker
for marker in ("'STATE GITPRBM MODULE A'",
               "'GITPRBM PROBE' which",
               "'FILEDEF STGIN CLEAR'", "'FILEDEF IDXIN CLEAR'",
               "M191 DIRECT CMS SEEK PROBE BEGIN",
               "M191 CMS SEEK PROBE GATE PASS"):
    assert marker in rex, marker
assert "'PIPE CMS GITPRBM" not in rex
assert "GITPRBM EXEC" not in rex
assert not (ROOT / "src/GITPRBM.EXEC").exists()
assert WRAPPER.stem != NATIVE.stem

def build(srcfile, exe):
    subprocess.run(["gcc", "-x", "c", "-std=c89", "-Wall",
                    "-Wextra", "-Werror", str(srcfile), "-o", str(exe)],
                   check=True)

def oid(kind, body):
    head = (kind + " " + str(len(body))).encode() + b"\0"
    return hashlib.sha1(head + body).hexdigest().upper()

with tempfile.TemporaryDirectory(prefix="m191-") as td:
    work = Path(td)
    native = work / "probe"
    indexer = work / "indexer"
    build(NATIVE, native)
    build(IDX, indexer)
    blobs = (bytes(range(256)) * 150,
             b"short reached text")
    tree = b"100644 readme\0" + bytes.fromhex(oid("blob", blobs[1]))
    objects = [("blob", 3, blobs[0]), ("blob", 3, blobs[1]),
               ("tree", 2, tree)]
    rows = []
    for i, (typ, code, body) in enumerate(objects, 1):
        rows.append("OBJ %d %d %d %s" %
                    (i, code, len(body), oid(typ, body)))
        hexstr = body.hex().upper()
        rows.extend(hexstr[j:j+64] for j in range(0, len(hexstr), 64))
    stage = work / "dd:STGIN"
    idx = work / "dd:IDXIN"
    stage.write_text("\n".join(rows) + "\n")
    result = subprocess.run([str(indexer), "BUILD"], cwd=work,
                            text=True, capture_output=True)
    assert result.returncode == 0, result.stdout + result.stderr
    shutil.copy(work / "dd:IDXOUT", idx)
    oldindex = idx.read_text()
    stagehash = hashlib.sha256(stage.read_bytes()).hexdigest()
    indexhash = hashlib.sha256(idx.read_bytes()).hexdigest()
    for which, record in (("FIRST", 1), ("MID", 2), ("LAST", 3)):
        r = subprocess.run([str(native), "PROBE", which], cwd=work,
                           text=True, capture_output=True)
        assert r.returncode == 0, (which, r.stdout, r.stderr)
        assert "M191 SEEK HEADER PASS %s RECORD %d" % (
            which, record) in r.stdout, r.stdout
        assert "M191 READ ONLY SEEK PROBE PASS" in r.stdout
        assert "M191 SEEK BEGIN " + which in r.stdout
        assert "M191 SEEK RETURNED " + which in r.stdout
    bad = subprocess.run([str(native), "PROBE", "OTHER"], cwd=work,
                         text=True, capture_output=True)
    assert bad.returncode == 4

    # Corrupt only the chosen indexed seek location in disposable data.
    for record, which in ((1, "FIRST"), (2, "MID"), (3, "LAST")):
        lines = oldindex.splitlines()
        for i, line in enumerate(lines):
            if not line.startswith("OID "):
                continue
            parts = line.split()
            if int(parts[2]) == record:
                parts[5] = str(int(parts[5]) + 1)
                lines[i] = " ".join(parts)
                break
        else:
            raise AssertionError("no index entry")
        idx.write_text("\n".join(lines) + "\n")
        response = subprocess.run(
            [str(native), "PROBE", which], cwd=work,
            text=True, capture_output=True)
        assert response.returncode == 8, (which, response.stdout)
        assert "M191 READ ONLY SEEK PROBE FAIL" in response.stdout
        assert "M191 READ ONLY SEEK PROBE PASS" not in response.stdout
        idx.write_text(oldindex)

    assert hashlib.sha256(stage.read_bytes()).hexdigest() == stagehash
    assert hashlib.sha256(idx.read_bytes()).hexdigest() == indexhash
print("M191 DIRECT CMS SEEK PROBE C89/PARITY/FAIL-CLOSED HOST PASS")
print("M191 HOST ONLY; CMS TEXT STREAM SEEK NOT YET VERIFIED")
