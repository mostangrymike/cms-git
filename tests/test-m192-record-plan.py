#!/usr/bin/env python3
"""M192 physical CMS-stage record ordinal arithmetic, host-only C89."""
from pathlib import Path
import hashlib
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
NATIVE = ROOT / "src/GITRCNM.C"
WRAPPER = ROOT / "src/GITRCN.EXEC"
IDX = ROOT / "src/GITPIDX.C"
for path in (NATIVE, WRAPPER):
    assert max(map(len, path.read_text().splitlines())) <= 80
src = NATIVE.read_text()
rexx = WRAPPER.read_text()
for phrase in ('"dd:IDXIN","r"', "M192 STAGE MODEL RECORDS",
               "M192 READ ONLY RECORD PLAN PASS",
               "(bynum[n].size+31UL)/32UL",
               "M192 RECORD MODEL MISMATCH"):
    assert phrase in src, phrase
assert 'fopen("dd:STGIN"' not in src
assert "fseek(" not in src
assert "fwrite(" not in src
for phrase in ("'GITRCNM PLAN' expected",
               "'STATE GITRCNM MODULE A'",
               "'FILEDEF IDXIN CLEAR'",
               "M192 RECORD MODEL GATE PASS"):
    assert phrase in rexx
assert "'PIPE CMS GITRCNM" not in rexx
assert WRAPPER.stem != NATIVE.stem
assert not (ROOT / "src/GITRCNM.EXEC").exists()

def build(source, output):
    subprocess.run(
        ["gcc", "-x", "c", "-std=c89", "-Wall",
         "-Wextra", "-Werror", str(source), "-o", str(output)],
        check=True)

def oid(kind, content):
    return hashlib.sha1(
        (kind + " " + str(len(content))).encode() +
        b"\0" + content).hexdigest().upper()

with tempfile.TemporaryDirectory(prefix="m192-") as dirname:
    work = Path(dirname)
    model = work / "record-model"
    idx_builder = work / "index-builder"
    build(NATIVE, model)
    build(IDX, idx_builder)
    stage = work / "dd:STGIN"
    index = work / "dd:IDXIN"
    rows = []
    nobjects = 7736
    expected_headers = {}
    for num in range(1, nobjects + 1):
        # Includes zero size, partial lines, and 32B/64B boundaries.
        size = 0 if num == 1 else max(4, (num * 13) % 257)
        content = (b"" if size == 0 else
                   num.to_bytes(4, "big") +
                   bytes([num % 251]) * (size - 4))
        expected_headers[num] = len(rows) + 1
        rows.append("OBJ %d 3 %d %s" %
                    (num, size, oid("blob", content)))
        text = content.hex().upper()
        if not text:
            rows.append("")
        else:
            rows.extend(text[i:i + 64] for i in range(0, len(text), 64))
    count = len(rows)
    stage.write_text("\n".join(rows) + "\n")
    generated = subprocess.run(
        [str(idx_builder), "BUILD"],
        cwd=work, capture_output=True, text=True)
    assert generated.returncode == 0, generated.stdout + generated.stderr
    shutil.copy(work / "dd:IDXOUT", index)
    initial_stage = hashlib.sha256(stage.read_bytes()).hexdigest()
    original_index = index.read_text()
    initial_index = hashlib.sha256(index.read_bytes()).hexdigest()
    passed = subprocess.run(
        [str(model), "PLAN", str(count)],
        cwd=work, capture_output=True, text=True)
    assert passed.returncode == 0, passed.stdout + passed.stderr
    assert "M192 INDEX TOTAL 7736 UNIQUE 7736" in passed.stdout
    assert "M192 STAGE MODEL RECORDS %d EXPECTED %d" % (
        count, count) in passed.stdout
    for item in (1, (nobjects + 1) // 2, nobjects):
        match = "M192 RECORD %d RECNO %d OFFSET " % (
            item, expected_headers[item])
        assert match in passed.stdout, (match, passed.stdout)
    assert "M192 READ ONLY RECORD PLAN PASS" in passed.stdout

    mismatch = subprocess.run(
        [str(model), "PLAN", str(count + 1)],
        cwd=work, capture_output=True, text=True)
    assert mismatch.returncode == 8
    assert "M192 RECORD MODEL MISMATCH" in mismatch.stdout
    assert "M192 READ ONLY RECORD PLAN PASS" not in mismatch.stdout

    # A damaged OID or duplicate native object number must fail closed.
    for mutator in ("oid", "duplicate"):
        lines = original_index.splitlines()
        at = next(i for i, row in enumerate(lines)
                  if row.startswith("OID "))
        data = lines[at].split()
        if mutator == "oid":
            data[1] = "G" + data[1][1:]
        else:
            second = next(i for i in range(at + 1, len(lines))
                          if lines[i].startswith("OID "))
            lines[second] = " ".join(
                lines[second].split()[:2] +
                [data[2]] + lines[second].split()[3:])
        if mutator == "oid":
            lines[at] = " ".join(data)
        index.write_text("\n".join(lines) + "\n")
        failed = subprocess.run(
            [str(model), "PLAN", str(count)],
            cwd=work, capture_output=True, text=True)
        assert failed.returncode == 8, (mutator, failed.stdout)
        assert "M192 INDEX INVALID" in failed.stdout
        index.write_text(original_index)
    assert hashlib.sha256(stage.read_bytes()).hexdigest() == initial_stage
    assert hashlib.sha256(index.read_bytes()).hexdigest() == initial_index
    print("M192 SYNTHETIC INDEXED OBJECTS 7736 RECORDS", count)
    print("M192 RECORD POSITION 1 MID LAST HOST MODEL PASS")
    print("M192 INVALID INDEX AND WRONG COUNT FAIL CLOSED")
    print("M192 HOST READ ONLY RECORD PLAN PASS; CMS UNTESTED")
