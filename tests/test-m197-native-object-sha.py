#!/usr/bin/env python3
"""M197 strict C89 canonical Git SHA1 validator on disposable OBJIN.

Does NOT read CMS G stage. Does NOT prove target FSREAD integration.
"""
from pathlib import Path
import hashlib
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
NATIVE = ROOT / "src/GITVO7M.C"
WRAPPER = ROOT / "src/GITVO7.EXEC"
src = NATIVE.read_text()
rex = WRAPPER.read_text()
assert max(map(len, src.splitlines())) <= 80
assert max(map(len, rex.splitlines())) <= 80
# Regression for CMS EBCDIC: the canonical bytes hashed by Git are
# ASCII regardless of the compiler's execution character set.
# Host SHA tests alone missed this when native literals were ASCII.
import re
hexblock = src.split("static const unsigned char git_type[5][7]=",1)[1]
hexblock = hexblock.split("};",1)[0]
rows = re.findall(r"\\{([^{}]+)\\}", hexblock)
assert len(rows) == 5, rows
actual = [bytes(int(token.strip(),0) for token in row.split(",")
                if token.strip()) for row in rows]
assert actual == [bytes([0]),
                  b"commit"+bytes([0]),
                  b"tree"+bytes([0,0,0]),
                  b"blob"+bytes([0,0,0]),
                  b"tag"+bytes([0,0,0,0])]
fn = src.split("static int object_sha(",1)[1].split(
     "static int nib(",1)[0]
assert "head[i++]=0x20;" in fn
assert "0x30UL+rem%10UL" in fn
assert "head[i++]=0;" in fn
assert "const char *name" not in fn
assert "kind[type]" not in fn
for name in ("commit","tree","blob","tag"):
    ascii_head = (name+" 291").encode("ascii")+bytes([0])
    native_head = (name+" 291").encode("cp037")+bytes([0])
    assert ascii_head != native_head
assert 'fopen("dd:OBJIN","r")' in src
assert 'fopen("dd:STGIN"' not in src
assert 'fopen("dd:IDXIN"' not in src
for forbidden in ("fseek(", "fwrite(", "remove(", "rename("):
    assert forbidden not in src
for key in ("M197 OBJECT SHA1 MISMATCH",
            "M197 READ ONLY FULL OBJECT SHA1 PASS",
            "sha_parts(", "OBJ %lu %d %lu %40s",
            "memcmp(hash,expected,20)!=0",
            "size>MAXSIZE", "line[0]!=0", "feof(f)"):
    assert key in src, key
for key in ("'STATE GITVRAW DATA A'",
            "'STATE GITVO7M MODULE A'",
            "'FILEDEF OBJIN DISK GITVRAW DATA A'",
            "'FILEDEF OBJIN CLEAR'",
            "'GITVO7M VERIFY' number oid",
            "M197 DISPOSABLE FULL OBJECT GATE PASS"):
    assert key in rex, key
assert "FILEDEF STGIN" not in rex
assert "FILEDEF IDXIN" not in rex
assert "'PIPE CMS GITVO7M" not in rex
assert "ERASE " not in rex and "FORMAT " not in rex
assert WRAPPER.stem != NATIVE.stem
assert not (ROOT / "src/GITVO7M.EXEC").exists()

def oid(kind, data):
    return hashlib.sha1(
        kind.encode("ascii") + b" " + str(len(data)).encode("ascii")
        + b"\0" + data
    ).hexdigest().upper()

def make_rows(num, typ, kind, data):
    lines = ["OBJ %d %d %d %s" % (num, typ, len(data), oid(kind, data))]
    hexdata = data.hex().upper()
    lines.extend([hexdata[i:i+64] for i in range(0, len(hexdata), 64)]
                 if hexdata else [""])
    return lines

with tempfile.TemporaryDirectory(prefix="m197-") as dirname:
    wd = Path(dirname)
    prog = wd / "m197verify"
    subprocess.run(
        ["gcc", "-x", "c", "-std=c89", "-Wall", "-Wextra", "-Werror",
         str(NATIVE), "-o", str(prog)], check=True
    )
    file = wd / "dd:OBJIN"

    def run(num, expected):
        return subprocess.run(
            [str(prog), "VERIFY", str(num), expected],
            text=True, capture_output=True, cwd=wd
        )

    fixtures = [
        (1, 3, "blob", b""),
        (2, 3, "blob", b"a"),
        (3, 3, "blob", bytes(range(32))),
        (4, 3, "blob", bytes(range(33))),
        (5, 3, "blob", bytes(range(64))),
        (6, 3, "blob", bytes(range(65))),
        (7, 3, "blob", (b"0123456789ABCDEF" * 256)),
        (8, 1, "commit", b"tree " + b"a" * 40 + b"\n\nTest\n"),
        (9, 2, "tree", b"100644 foo\x00" + bytes(range(20))),
        (10, 4, "tag", b"object " + b"b" * 40 + b"\n"),
        (11, 2, "tree", bytes((x*37)%256 for x in range(291))),
    ]
    for num, typ, kind, data in fixtures:
        lines = make_rows(num, typ, kind, data)
        file.write_text("\n".join(lines) + "\n")
        before = hashlib.sha256(file.read_bytes()).hexdigest()
        result = run(num, oid(kind, data))
        assert result.returncode == 0, (
            num, result.returncode, result.stdout, result.stderr)
        assert "M197 OBJECT %d TYPE %d SIZE %d BODY RECORDS %d" % (
            num, typ, len(data), max(1, (len(data)+31)//32)) in result.stdout
        assert "M197 VERIFIED OID " + oid(kind, data) in result.stdout
        assert "M197 READ ONLY FULL OBJECT SHA1 PASS" in result.stdout
        assert hashlib.sha256(file.read_bytes()).hexdigest() == before
        wrong_oid = ("0" if oid(kind, data)[0] != "0" else "1") + oid(kind, data)[1:]
        wrong = run(num, wrong_oid)
        assert wrong.returncode == 8
        if data:
            changed = lines[:]
            changed[1] = ("0" if lines[1][0] != "0" else "1") + lines[1][1:]
            file.write_text("\n".join(changed) + "\n")
            result = run(num, oid(kind, data))
            assert result.returncode == 8, (num, result.stdout)
            assert "M197 OBJECT SHA1 MISMATCH" in result.stdout
        file.write_text("\n".join(lines) + "\n")
        short = lines[:-1]
        file.write_text("\n".join(short) + "\n")
        assert run(num, oid(kind, data)).returncode == 8
        file.write_text("\n".join(lines + ["DEAD"]) + "\n")
        assert run(num, oid(kind, data)).returncode == 8

    num, typ, kind, data = (32, 3, "blob", bytes(range(40)))
    valid = make_rows(num, typ, kind, data)
    for change in ("headernum", "headertype", "headersize", "odd",
                   "nonhex", "oversize", "embeddednul", "extraheader"):
        lines = valid[:]
        if change == "headernum":
            lines[0] = lines[0].replace("OBJ 32 ", "OBJ 31 ", 1)
        elif change == "headertype":
            lines[0] = lines[0].replace("OBJ 32 3 ", "OBJ 32 1 ", 1)
        elif change == "headersize":
            lines[0] = lines[0].replace("OBJ 32 3 40 ", "OBJ 32 3 39 ", 1)
        elif change == "odd":
            lines[1] = lines[1][:-1]
        elif change == "nonhex":
            lines[1] = "Z" + lines[1][1:]
        elif change == "oversize":
            lines[1] = "AA" * 41
        elif change == "embeddednul":
            lines[1] = lines[1][:4] + "\0" + lines[1][5:]
        elif change == "extraheader":
            lines[0] += " BAD"
        file.write_bytes(("\n".join(lines) + "\n").encode("ascii"))
        result = run(num, oid(kind, data))
        assert result.returncode == 8, (change, result.stdout)

    for badnum in ("0", "-1", "+1", "1.0", "X", str(2**64)):
        result = run(badnum, "A" * 40)
        assert result.returncode == 4, badnum
    for badoid in ("Z" * 40, "A" * 39, "A" * 41):
        assert run(1, badoid).returncode == 4

print("M197 HOST STRICT C89 FULL CANONICAL GIT OID SHA1 PASS")
print("M197 ZERO SIZE MULTIBLOCK TREE COMMIT TAG BLOB PASS")
print("M197 CORRUPT HEX SIZE TYPE OID TRUNCATION EXTRA FAIL CLOSED")
print("M197 DISPOSABLE OBJIN IS READ ONLY; CMS BRIDGE NOT TESTED")
