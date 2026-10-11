#!/usr/bin/env python3
"""M188 fast newline-ending path with original suffix-parity suite."""
from pathlib import Path
import hashlib
import re
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
native = root / "src" / "GITPH8M.C"
wrapper = root / "src" / "GITPH8.EXEC"
base = root / "src" / "GITPFST.C"
index = root / "src" / "GITPIDX.C"

def oid(typ, body):
    header = (typ + " " + str(len(body))).encode() + b"\0"
    return hashlib.sha1(header + body).hexdigest().upper()

def edge(mode, name, child):
    return (str(mode).encode() + b" " + name + b"\0"
            + bytes.fromhex(child))

def stage(objects):
    lines = []
    for number, (typ, code, body) in enumerate(objects, 1):
        lines.append("OBJ %d %d %d %s" %
                     (number, code, len(body), oid(typ, body)))
        hexd = body.hex().upper()
        if not hexd:
            lines.append("")
        else:
            lines += [hexd[i:i + 64] for i in range(0, len(hexd), 64)]
    return "\n".join(lines) + "\n", len(lines)

def run(exe, folder, tree):
    return subprocess.run([str(exe), "WALK", tree], cwd=folder,
                          capture_output=True, text=True)

for path in (native, wrapper):
    assert max(map(len, path.read_text().splitlines())) <= 80, path
code = native.read_text()
rexx = wrapper.read_text()
for required in ("#include <time.h>", "clock()", "cpu_phase(",
                 "M188 STAGE LINES PASS1", "M188 TREE CLOSURE PASS",
                 "validhex[256]", "static int skipline(",
                 "M188 FAST EOL VALIDATOR PASS",
                 "scan(1)", "scan(2)"):
    assert required in code, required
assert "fseek(" not in code

# CMS command lookup collision regression: EXEC must never invoke itself.
assert wrapper.stem == "GITPH8"
assert native.stem == "GITPH8M"
assert wrapper.stem != native.stem
assert "GITPH8 MODULE" not in rexx
assert not (root / "src" / "GITPH8M.EXEC").exists()
assert "'PIPE CMS GITPH8 WALK'" not in rexx
assert "Usage: GITPH8M WALK tree-oid" in code
for forbidden in ("ERASE", "FORMAT ", "DIRECTXA", "GITPIMP IMPORT",
                  "GITPIDX BUILD", "FILEDEF * CLEAR", "FILEDEF OBJOUT",
                  "FILEDEF IDXOUT"):
    assert forbidden not in rexx
for required in ("'STATE GITPH8M MODULE A'",
                 "'PIPE CMS GITPH8M WALK' oid '| STEM o.'",
                 "'PIPE CMS QUERY FILEDEF | STEM f.'",
                 "'FILEDEF IDXIN CLEAR'", "'FILEDEF STGIN CLEAR'",
                 "M188 VERIFIED FAST TREE TARGET GATE PASS"):
    assert required in rexx, required

with tempfile.TemporaryDirectory() as temp:
    folder = Path(temp)
    binaries = {}
    for name, source in (("old", base), ("new", native), ("idx", index)):
        binaries[name] = folder / name
        cmd = ["gcc", "-x", "c", "-std=c89", "-Wall", "-Wextra",
               "-Werror", str(source), "-o", str(binaries[name])]
        subprocess.run(cmd, check=True)
    big = b"ABCdef0123456789" * 4700
    small = b"tiny"
    other = b"not reached" * 5000
    sub = edge(100644, b"part.bin", oid("blob", big))
    rootbody = (edge(40000, b"dir", oid("tree", sub))
                + edge(100644, b"test.txt", oid("blob", small))
                + edge(160000, b"external", "11" * 20))
    unused = edge(100644, b"no", oid("blob", other))
    objects = [("blob", 3, big), ("blob", 3, small),
               ("blob", 3, other), ("tree", 2, sub),
               ("tree", 2, unused), ("tree", 2, rootbody)]
    txt, count = stage(objects)
    (folder / "dd:STGIN").write_text(txt)
    built = subprocess.run([str(binaries["idx"]), "BUILD"], cwd=folder,
                           text=True, capture_output=True)
    assert built.returncode == 0, built.stdout + built.stderr
    shutil.copy(folder / "dd:IDXOUT", folder / "dd:IDXIN")
    originalidx = (folder / "dd:IDXIN").read_text()
    rootoid = oid("tree", rootbody)
    old = run(binaries["old"], folder, rootoid)
    new = run(binaries["new"], folder, rootoid)
    assert old.returncode == 0, old.stdout + old.stderr
    assert new.returncode == 0, new.stdout + new.stderr
    for expected in (f"TREE CLOSURE ROOT {rootoid}",
                     "TREE CLOSURE TREES 2 BLOBS 2 GITLINKS 1",
                     "TREE CLOSURE ENTRIES 4 VERIFIED 4",
                     "TREE CLOSURE MAX OBJECT 75200",
                     "TREE CLOSURE INDEX TOTAL 6 UNIQUE 6"):
        assert expected in old.stdout and expected in new.stdout, expected
    assert f"M188 STAGE LINES PASS1 {count} PASS2 {count}" in new.stdout
    assert "M188 FORWARD SCANS 2 RECORDS 12 SEEKS 0" in new.stdout
    assert "M188 AUTHENTICATED BLOBS 2" in new.stdout
    assert "M188 TREE CLOSURE PASS" in new.stdout
    assert "M188 DIRECT SKIP VALIDATOR PASS" in new.stdout
    for phase in ("INDEX", "TREE_SCAN", "GRAPH", "BLOB_SCAN"):
        match = re.search(r"^M188 CPU " + phase +
                          r" (\d+\.\d+|UNAVAILABLE)$",
                          new.stdout, re.MULTILINE)
        assert match, (phase, new.stdout)
    assert (folder / "dd:STGIN").read_text() == txt
    assert (folder / "dd:IDXIN").read_text() == originalidx

    # Native character-code hex lookup must accept lowercase too.
    lines = txt.splitlines()
    unrelated_pos = next(i for i, line in enumerate(lines)
                         if line.startswith("OBJ 3 ")) + 1
    lines[unrelated_pos] = lines[unrelated_pos].lower()
    (folder / "dd:STGIN").write_text("\n".join(lines) + "\n")
    lowercase = run(binaries["new"], folder, rootoid)
    assert lowercase.returncode == 0, lowercase.stdout + lowercase.stderr
    assert "M188 TREE CLOSURE PASS" in lowercase.stdout
    (folder / "dd:STGIN").write_text(txt)

    malformed = run(binaries["new"], folder, "Z" * 40)
    assert malformed.returncode == 4

    # Authentication failure in reached blob (byte remains valid hex).
    lines = txt.splitlines()
    lines[1] = ("0" if lines[1][0] != "0" else "1") + lines[1][1:]
    (folder / "dd:STGIN").write_text("\n".join(lines) + "\n")
    invalid = run(binaries["new"], folder, rootoid)
    assert invalid.returncode == 8
    assert "M188 OBJECT SHA1 FAIL" in invalid.stdout
    assert "M188 TREE CLOSURE PASS" not in invalid.stdout

    # Stage structure error in otherwise skipped body must fail closed.
    lines = txt.splitlines()
    unrelated_header = next(i for i, line in enumerate(lines)
                            if line.startswith("OBJ 3 "))
    lines[unrelated_header + 1] = "G" + lines[unrelated_header + 1][1:]
    (folder / "dd:STGIN").write_text("\n".join(lines) + "\n")
    invalid = run(binaries["new"], folder, rootoid)
    assert invalid.returncode == 8
    assert "M188 TREE CLOSURE PASS" not in invalid.stdout

    # M188 must preserve M181's exact trimmed line-length rules.
    hdr = next(i for i, line in enumerate(txt.splitlines())
               if line.startswith("OBJ 3 "))
    for transform in (
        lambda row: row[:-2],
        lambda row: row + "AA",
        lambda row: row[:-1] + "G",
        lambda row: row[:63] + "G",
    ):
        lines = txt.splitlines()
        lines[hdr + 1] = transform(lines[hdr + 1])
        (folder / "dd:STGIN").write_text("\n".join(lines) + "\n")
        bad_line = run(binaries["new"], folder, rootoid)
        assert bad_line.returncode == 8, bad_line.stdout
        assert "M188 TREE CLOSURE PASS" not in bad_line.stdout

    # Direct reader must reject truncated and overlong terminated
    # records without requiring a second strlen() on skipped data.
    baseline = folder / "prior-m183"
    subprocess.run(
        ["gcc", "-x", "c", "-std=c89", "-Wall", "-Wextra",
         "-Werror", str(root / "src" / "GITPH3M.C"),
         "-o", str(baseline)],
        check=True
    )
    for mutate in (
        lambda row: row[:16] + "G" + row[17:],
        lambda row: row[:-1],
        lambda row: row + "A",
        lambda row: row[:-1] + " ",
        lambda row: row + "A" * 95,
    ):
        lines = txt.splitlines()
        lines[hdr + 1] = mutate(lines[hdr + 1])
        (folder / "dd:STGIN").write_text("\n".join(lines) + "\n")
        old_check = run(baseline, folder, rootoid)
        new_check = run(binaries["new"], folder, rootoid)
        assert old_check.returncode != 0
        assert new_check.returncode == old_check.returncode, (
            old_check.stdout, new_check.stdout)
        assert "M188 TREE CLOSURE PASS" not in new_check.stdout
    (folder / "dd:STGIN").write_text(txt)

    # Fast LF, CRLF and EOF paths must agree with M185 baseline.
    original_m185 = folder / "prior-m185"
    subprocess.run(
        ["gcc", "-x", "c", "-std=c89", "-Wall", "-Wextra",
         "-Werror", str(root / "src" / "GITPH5M.C"),
         "-o", str(original_m185)], check=True)
    for suffix in ("\r", " ", " \r", " \r ", "\t", "G"):
        stage_lines = txt.split("\n")
        stage_lines[hdr + 1] += suffix
        (folder / "dd:STGIN").write_text(
            "\n".join(stage_lines))
        (folder / "dd:IDXOUT").unlink()
        remake = subprocess.run(
            [str(binaries["idx"]), "BUILD"],
            cwd=folder, capture_output=True, text=True)
        assert remake.returncode == 0, (
            suffix, remake.stdout, remake.stderr)
        shutil.copy(folder / "dd:IDXOUT", folder / "dd:IDXIN")
        old = run(original_m185, folder, rootoid)
        cur = run(binaries["new"], folder, rootoid)
        assert cur.returncode == old.returncode, (
            suffix, old.stdout, cur.stdout)
        assert (cur.returncode == 0) == (
            suffix not in ("\\t", "G")), suffix
    (folder / "dd:STGIN").write_text(txt)
    (folder / "dd:IDXIN").write_text(originalidx)

    # Trailing spaces are accepted by the original M181 linein.
    lines = txt.splitlines()
    lines[hdr + 1] += "  "
    (folder / "dd:STGIN").write_text("\n".join(lines) + "\n")
    # Index offsets change when record width changes; rebuild index
    # only in this disposable host fixture, never on CMS G.
    (folder / "dd:IDXOUT").unlink()
    rebuilt = subprocess.run(
        [str(binaries["idx"]), "BUILD"], cwd=folder,
        capture_output=True, text=True)
    assert rebuilt.returncode == 0, rebuilt.stdout + rebuilt.stderr
    shutil.copy(folder / "dd:IDXOUT", folder / "dd:IDXIN")
    with_spaces = run(binaries["new"], folder, rootoid)
    assert with_spaces.returncode == 0, with_spaces.stdout
    (folder / "dd:STGIN").write_text(txt)
    (folder / "dd:IDXIN").write_text(originalidx)

    (folder / "dd:STGIN").write_text(txt)
    (folder / "dd:IDXIN").write_text(
        "\n".join(originalidx.splitlines()[:-1]) + "\n")
    truncated = run(binaries["new"], folder, rootoid)
    assert truncated.returncode == 8
    assert "M188 TREE CLOSURE PASS" not in truncated.stdout

print("M188 FAST EOL SKIPPED RECORD HOST PARITY PASS")
