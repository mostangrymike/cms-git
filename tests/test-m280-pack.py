#!/usr/bin/env python3
"""M280: host tests for the C89 Git pack builder (src/GITPMKC.C).

Builds the host pack builder and validates its pack format, object
encoding, SHA-1 trailer, and round-trip through git unpack-objects.  Also
statically checks the CMS REXX pack builder (src/GITPMK.EXEC) for the
corrections that keep it portable and correct.
"""
from pathlib import Path
import hashlib
import subprocess
import sys
import tempfile
import zlib

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "src" / "GITPMKC.C"
REXX = ROOT / "src" / "GITPMK.EXEC"


def gitoid(typ, body):
    name = {1: b"commit", 2: b"tree", 3: b"blob", 4: b"tag"}[typ]
    return hashlib.sha1(name + b" " + str(len(body)).encode() + b"\0" + body).hexdigest().upper()


def stage_lines(typ, body):
    rows = ["OBJ %d %d %s" % (typ, len(body), gitoid(typ, body))]
    hexdata = body.hex().upper()
    if not hexdata:
        rows.append("")
    else:
        rows.extend(hexdata[i:i + 64] for i in range(0, len(hexdata), 64))
    return rows


def parse_varint(buf, pos):
    first = buf[pos]
    typ = (first >> 4) & 7
    size = first & 0x0F
    shift = 4
    pos += 1
    cont = bool(first & 0x80)
    while cont:
        b = buf[pos]
        pos += 1
        size |= (b & 0x7F) << shift
        shift += 7
        cont = bool(b & 0x80)
    return typ, size, pos


with tempfile.TemporaryDirectory(prefix="m280-") as td:
    work = Path(td)
    # Build the host pack builder under strict C89.
    subprocess.run(
        ["gcc", "-x", "c", "-std=c89", "-Wall", "-Wextra", "-Werror",
         str(SOURCE), "-o", str(work / "gitpmk")],
        check=True,
    )

    # Fixture objects: blob, empty blob, tree, commit, tag, and a 70 KB blob.
    small_blob = b"hello\n"
    empty_blob = b""
    tree_body = b"100644 hello.txt\0" + bytes.fromhex(gitoid(3, small_blob))
    commit_body = (b"tree " + gitoid(2, tree_body).encode() +
                   b"\nauthor A <a@b> 1 +0000\ncommitter A <a@b> 1 +0000\n\nmsg\n")
    tag_body = (b"object " + gitoid(1, commit_body).encode() +
                b"\ntype commit\ntag v1\ntagger A <a@b> 1 +0000\n\nrel\n")
    big_blob = bytes((i * 37 + 11) % 256 for i in range(70000))

    objects = [
        (3, small_blob),
        (3, empty_blob),
        (2, tree_body),
        (1, commit_body),
        (4, tag_body),
        (3, big_blob),
    ]

    # Write staging file.
    stage = work / "dd:OBJSTG"
    rows = []
    for typ, body in objects:
        rows.extend(stage_lines(typ, body))
    stage.write_text("\n".join(rows) + "\n")

    # Run builder.
    result = subprocess.run(
        [str(work / "gitpmk"), "BUILD"], cwd=work,
        capture_output=True, text=True)
    assert result.returncode == 0, (result.stdout, result.stderr)
    assert "PACK CREATED OBJECTS 6" in result.stdout
    assert "M280 PACK BUILD PASS" in result.stdout

    pack = (work / "dd:OBJOUT").read_bytes()
    # Basic header.
    assert pack[:4] == b"PACK"
    assert int.from_bytes(pack[4:8], "big") == 2
    assert int.from_bytes(pack[8:12], "big") == 6

    # Parse and validate every object.
    body = pack[:-20]
    trailer = pack[-20:]
    assert hashlib.sha1(body).digest() == trailer, "SHA-1 trailer mismatch"

    pos = 12
    parsed = []
    for index in range(6):
        typ, size, pos = parse_varint(body, pos)
        assert typ == objects[index][0], (index, typ, objects[index][0])
        assert size == len(objects[index][1]), (index, size)
        # zlib body.
        z = zlib.decompressobj()
        inflated = z.decompress(body[pos:])
        assert z.eof, "zlib stream did not end"
        consumed = len(body[pos:]) - len(z.unused_data)
        pos += consumed
        assert inflated == objects[index][1], "inflated body mismatch"
        # zlib wrapper checks.
        zlib_start = pos - consumed
        assert body[zlib_start] == 0x78 and body[zlib_start + 1] == 0x01
        # OID check.
        assert gitoid(typ, inflated) == gitoid(typ, objects[index][1])
        parsed.append((typ, size))

    assert pos == len(body), (pos, len(body))

    # git unpack-objects round trip.
    repo = work / "repo"
    repo.mkdir()
    subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
    subprocess.run(
        ["git", "unpack-objects", "-r"], cwd=repo, input=pack,
        check=True, capture_output=True)
    for typ, body in objects:
        oid = gitoid(typ, body).lower()
        got = subprocess.run(
            ["git", "cat-file", "-t", oid], cwd=repo,
            capture_output=True, text=True)
        assert got.returncode == 0, (oid, got.stderr)
        assert got.stdout.strip() == {1: "commit", 2: "tree", 3: "blob", 4: "tag"}[typ]
        if typ == 3:
            content = subprocess.run(
                ["git", "cat-file", "-p", oid], cwd=repo,
                capture_output=True).stdout
            assert content == body

    # HEX mode: CMS stores packs as uppercase hex text.  The decoded bytes
    # must be identical to the binary output, including the ASCII "PACK"
    # signature (CMS C compiles string literals as EBCDIC).
    hexdir = work / "hexcase"
    hexdir.mkdir()
    (hexdir / "dd:OBJSTG").write_text("\n".join(rows) + "\n")
    r = subprocess.run(
        [str(work / "gitpmk"), "BUILD", "HEX"], cwd=hexdir,
        capture_output=True, text=True)
    assert r.returncode == 0, (r.stdout, r.stderr)
    text = (hexdir / "dd:OBJOUT").read_text()
    for line in text.splitlines():
        assert 0 < len(line) <= 128 and len(line) % 2 == 0, line
        assert line == line.upper()
    decoded = bytes.fromhex("".join(text.split()))
    assert decoded == pack
    assert decoded[:4] == b"PACK"

    # Negative cases.
    def run_builder(cwd, stage_text):
        s = cwd / "dd:OBJSTG"
        s.write_text(stage_text)
        r = subprocess.run(
            [str(work / "gitpmk"), "BUILD"], cwd=cwd,
            capture_output=True, text=True)
        return r

    # Usage.
    r = subprocess.run([str(work / "gitpmk")], cwd=work,
                       capture_output=True, text=True)
    assert r.returncode == 4, (r.stdout, r.stderr)
    assert "Usage: GITPMK BUILD" in r.stderr

    # Bad object type.
    bad_type = "OBJ 9 1 %s\n%s\n" % (gitoid(3, small_blob), small_blob.hex().upper())
    r = run_builder(work, bad_type)
    assert r.returncode == 8, (r.stdout, r.stderr)
    assert "bad OBJ header" in r.stderr

    # Truncated data.
    trunc = "OBJ 3 10 %s\n%s\n" % (gitoid(3, small_blob), small_blob.hex().upper())
    r = run_builder(work, trunc)
    assert r.returncode == 8, (r.stdout, r.stderr)

    # Empty staging.
    empty_dir = work / "emptycase"
    empty_dir.mkdir()
    (empty_dir / "dd:OBJSTG").write_text("")
    r = subprocess.run([str(work / "gitpmk"), "BUILD"], cwd=empty_dir,
                       capture_output=True, text=True)
    assert r.returncode == 8, (r.stdout, r.stderr)
    assert "no objects to pack" in r.stderr

    # CMS REXX pack builder static checks.
    rex = REXX.read_text()
    csrc = SOURCE.read_text()
    assert max(len(line) for line in rex.splitlines()) <= 80
    assert "rexx -c" not in rex
    # Adler-32 is computed over the plain input, not the deflate bytes.
    assert "ad = adler32_num(plain)" in rex
    assert "ad = adler32_num(deflate)" not in rex
    # zlib_wrap receives the plain object data.
    assert "zlib_wrap(deflated, p_data.i)" in rex
    # Named per-object stems avoid REXX's dynamic compound-tail pitfalls.
    assert "p_type.oi = otype" in rex
    assert "p_size.oi = osize" in rex
    assert "p_oid.oi = oid_str" in rex
    assert "p_data.oi = obin" in rex
    assert "p_count = oi" in rex
    assert "objs.oi.otype" not in rex
    # Filemode is accepted as an argument (default A).
    assert "parse arg cmd fm extra" in rex
    assert "if fm='' then fm='A'" in rex
    # The pack is written as uppercase hex text, one 128-column record.
    assert "hxpack = c2x(pack)" in rex
    assert "substr(hxpack,p,128)" in rex
    # SHA-1 state must be initialized before hashing the pack.
    assert "call sha_init" in rex
    assert "h0 = h1 = h2 = h3 = h4 = 0" not in rex
    # The ASCII "PACK" signature is written numerically; CMS C compiles
    # string literals as EBCDIC, which would corrupt the magic.
    assert "head[0]=0x50;head[1]=0x41;head[2]=0x43;head[3]=0x4B;" in csrc
    assert 'memcpy(head,"PACK",4)' not in csrc
    # Optional HEX output for CMS text pack files.
    assert "int hexout=0;" in csrc
    assert 'strcmp(argv[2],"HEX")==0' in csrc
    assert "hline[hk++]=hx[(b>>4)&0x0F];" in csrc
    # Source is accepted by GCCE on CMS (80-column card reader).
    assert max(len(line) for line in csrc.splitlines()) <= 80
    # Stored-block final bit is set.
    assert "out = out || '01'x" in rex
    assert "out = out || '80'x" not in rex
    # num2hex uses integer division, not REXX's wrong % semantics.
    assert "n = n % 16" in rex
    assert "n = n // 16" not in rex
    # SHA-1 length is big-endian.
    assert "tail = tail || '00000000'x||x2c(num2hex(bitlen))" in rex
    # REXX syntax check when a Regina is available.
    import shutil
    if shutil.which("rexx"):
        r = subprocess.run(
            ["rexx", "-c", str(REXX), "/dev/null"],
            capture_output=True, text=True)
        assert r.returncode == 0, (r.stdout, r.stderr)

print("M280 PACK BUILD, ZLIB, SHA-1 TRAILER AND GIT ROUND-TRIP PASS")
print("M280 NEGATIVE CASES PASS")
print("M280 CMS REXX PACK BUILDER STATIC GUARDS PASS")