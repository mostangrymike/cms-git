#!/usr/bin/env python3
"""M196 strict C89 index-to-absolute CMS record plan regression.

This does not call FSREAD. IBM macro and target behavior remain separate.
"""
from pathlib import Path
import hashlib
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
NATIVE = ROOT / "src/GITRP6M.C"
WRAP = ROOT / "src/GITRP6.EXEC"
IDX = ROOT / "src/GITPIDX.C"
src = NATIVE.read_text()
rex = WRAP.read_text()
assert max(map(len, src.splitlines())) <= 80
assert max(map(len, rex.splitlines())) <= 80
assert "fopen(\"dd:IDXIN\",\"r\")" in src
assert "fopen(\"dd:STGIN\"" not in src
assert "fseek(" not in src and "fwrite(" not in src
assert "M196 READ ONLY INDEX OBJECT PLAN PASS" in src
assert "M196 OBJECT EXCEEDS BODY RECORD LIMIT" in src
assert "M196 STAGE RECORD COUNT MISMATCH" in src
assert "M196 INDEX NUMBER OR OFFSET INVALID" in src
for phrase in ("'GITRP6M PLAN 3864799' obj limit",
               "'FILEDEF IDXIN CLEAR'",
               "'STATE M173NET STAGE G'",
               "'STATE M174NET INDEX G'",
               "'STATE GITRP6M MODULE A'",
               "M196 INDEX OBJECT PLAN GATE PASS G"):
    assert phrase in rex, phrase
assert "'PIPE CMS GITRP6M" not in rex
assert "FILEDEF STGIN" not in rex
assert "ERASE " not in rex and "FORMAT " not in rex
assert WRAP.stem != NATIVE.stem
assert not (ROOT / "src/GITRP6M.EXEC").exists()

def compile_c(source, path):
    subprocess.run(["gcc", "-x", "c", "-std=c89", "-Wall",
                    "-Wextra", "-Werror", str(source), "-o", str(path)],
                   check=True)

def run(prog, cwd, *args):
    return subprocess.run([str(prog), *map(str, args)], cwd=cwd,
                          text=True, capture_output=True)

def sha(body):
    return hashlib.sha1(
        b"blob " + str(len(body)).encode("ascii") + b"\0" + body
    ).hexdigest().upper()

with tempfile.TemporaryDirectory(prefix="m196-") as dirname:
    wd = Path(dirname)
    planner, builder = wd / "planner", wd / "builder"
    compile_c(NATIVE, planner)
    compile_c(IDX, builder)
    rows = []
    positions = {}
    expect = {}
    for i in range(1, 7737):
        n = 0 if i == 1 else 4 + (i * 13) % 125
        data = (b"" if n == 0 else
                i.to_bytes(4, "big") + bytes([i % 251]) * (n - 4))
        oid = sha(data)
        positions[i] = len(rows) + 1
        expect[i] = (n, oid, max(1, (n + 31) // 32))
        rows.append("OBJ %d 3 %d %s" % (i, n, oid))
        hx = data.hex().upper()
        rows.extend([hx[j:j+64] for j in range(0, len(hx), 64)]
                    if hx else [""])
    stage, index = wd / "dd:STGIN", wd / "dd:IDXIN"
    stage.write_text("\n".join(rows) + "\n")
    build = run(builder, wd, "BUILD")
    assert build.returncode == 0, build.stdout + build.stderr
    shutil.copy(wd / "dd:IDXOUT", index)
    saved = index.read_text()
    before = (hashlib.sha256(stage.read_bytes()).hexdigest(),
              hashlib.sha256(index.read_bytes()).hexdigest())

    for number in (1, 3868, 7736):
        length, oid, count = expect[number]
        result = run(planner, wd, "PLAN", len(rows), number, 64)
        assert result.returncode == 0, result.stdout + result.stderr
        assert ("M196 OBJECT %d TYPE 3 SIZE %d OID %s OFFSET " %
                (number, length, oid)) in result.stdout
        assert ("M196 RECORDS HEADER %d BODY %d LAST %d COUNT %d" %
                (positions[number], positions[number]+1,
                 positions[number]+count, count)) in result.stdout
        assert "M196 INDEX TOTAL 7736 UNIQUE 7736" in result.stdout
        assert ("M196 STAGE MODEL RECORDS %d EXPECTED %d" %
                (len(rows), len(rows))) in result.stdout
        assert "M196 READ ONLY INDEX OBJECT PLAN PASS" in result.stdout
        if count > 1:
            limited = run(planner, wd, "PLAN", len(rows), number, count-1)
            assert limited.returncode == 8
            assert "M196 OBJECT EXCEEDS BODY RECORD LIMIT" in limited.stdout
            assert "M196 READ ONLY INDEX OBJECT PLAN PASS" not in limited.stdout

    mismatch = run(planner, wd, "PLAN", len(rows)+1, 7736, 64)
    assert mismatch.returncode == 8
    assert "M196 STAGE RECORD COUNT MISMATCH" in mismatch.stdout
    invalid = run(planner, wd, "PLAN", len(rows), 7737, 64)
    assert invalid.returncode == 8
    assert "M196 OBJECT OUT OF RANGE" in invalid.stdout
    for bad in ("0", "-1", "+1", "1.0", "abc", str(2**64)):
        result = run(planner, wd, "PLAN", len(rows), bad, 64)
        assert result.returncode == 4, (bad, result.stdout)
    for lim in ("0", "65", "-1"):
        result = run(planner, wd, "PLAN", len(rows), 7736, lim)
        assert result.returncode == 4

    lines = saved.splitlines()
    at = next(i for i, line in enumerate(lines)
              if line.startswith("OID "))
    parts = lines[at].split()
    for mutation in ("oid", "duplicate", "offset"):
        corrupt = lines[:]
        if mutation == "oid":
            pieces = parts[:]
            pieces[1] = "Z" + pieces[1][1:]
            corrupt[at] = " ".join(pieces)
        elif mutation == "duplicate":
            other = next(i for i in range(at+1, len(corrupt))
                         if corrupt[i].startswith("OID "))
            pieces = corrupt[other].split()
            pieces[2] = parts[2]
            corrupt[other] = " ".join(pieces)
        else:
            pieces = parts[:]
            pieces[5] = "-1"
            corrupt[at] = " ".join(pieces)
        index.write_text("\n".join(corrupt) + "\n")
        failed = run(planner, wd, "PLAN", len(rows), 7736, 64)
        assert failed.returncode == 8, (mutation, failed.stdout)
        assert "M196 INDEX INVALID" in failed.stdout
        index.write_text(saved)
    assert before == (hashlib.sha256(stage.read_bytes()).hexdigest(),
                      hashlib.sha256(index.read_bytes()).hexdigest())
    print("M196 HOST INDEXED 7736 UNIQUE OBJECTS VERIFIED")
    print("M196 FIRST MID LAST OBJECT RECORDS AND OIDS MATCH")
    print("M196 DAMAGED INDEX AND RECORD BOUND FAIL CLOSED")
    print("M196 READ ONLY C89 INDEX PLAN HOST PASS; CMS NOT TESTED")
