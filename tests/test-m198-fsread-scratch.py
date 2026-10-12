#!/usr/bin/env python3
"""M198 bounded original-stage FSREAD to NEW scratch safeguards.

Host models staged text copies and M197 full Git SHA parity. This
does not assemble or execute IBM CMS macros; target remains pending.
"""
from pathlib import Path
import hashlib
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[1]
ASM=(ROOT/"src/GITBX8.ASSEMBLE").read_text()
EXEC=(ROOT/"src/GITB8.EXEC").read_text()
SHA=(ROOT/"src/GITVO7M.C").read_text()
L=ASM.splitlines()
assert max(map(len,L))<=72
assert max(map(len,EXEC.splitlines()))<=80
continuations=[row for row in L if len(row)==72 and row[71]=="X"]
assert len(continuations)==3, continuations
assert all(len(row)==72 for row in continuations)
labels=[]
for i,row in enumerate(L,1):
    if not row or row[0].isspace() or row.startswith("*"):
        continue
    name=row.split()[0]
    assert len(name)<=8,(i,name)
    assert row[len(name)].isspace(),(i,name)
    labels.append(name)
assert len(labels)==len(set(labels))
code="\n".join(x for x in L if x and not x.startswith("*"))
for fragment in (
    "M198 LAST 11 STAGE RECORDS VERIFIED",
    "M198 NEW DISPOSABLE OBJECT WRITE PASS",
    "M198 NEW SCRATCH OPEN FAILED",
    "M198 SCRATCH WRITE FAILED",
    "FSREAD 'M173NET STAGE G1',BUFFER=(4),BSIZE=64",
    "RECFM=V,RECNO=(5),NOREC=1,FORM=E,ERROR=RDERR",
    "FSOPEN FSCB=OUTFSCB,OPENTYP=NEW,FORM=E,ERROR=OPENERR",
    "FSWRITE FSCB=OUTFSCB,BUFFER=(4),BSIZE=(5)",
    "RECFM=V,FORM=E,ERROR=WRERR",
    "FSCLOSE 'M173NET STAGE G1',ERROR=ICLERR",
    "FSCLOSE FSCB=OUTFSCB,ERROR=OCLERR",
    "FSCB  'GITVRAW DATA A1',BUFFER=RECSET,BSIZE=64,RECFM=V",
    "LENSET   DS    11F", "RECSET   DS    CL704",
    "C     6,=F'11'", "=F'3864789'",
    "C     4,=F'289'", "C     4,=F'320'",
    "C     7,=F'64'", "ST    0,READLEN",
    "ST    0,0(9)", "N     6,=F'1'",
    "BCT   7,CHECKCHR", "C'OBJ 7736 '",
):
    assert fragment in ASM,fragment
assert code.index("FSCLOSE 'M173NET STAGE G1'")<code.index(
    "FSOPEN FSCB=OUTFSCB,OPENTYP=NEW")
assert code.count("FSREAD 'M173NET STAGE G1'")==1
assert code.count("FSWRITE FSCB=OUTFSCB")==1
for forbidden in ("FSWRITE 'M173NET", "FSERASE", "FSPOINT",
                  "OPENTYP=REPLACE", "OPENTYP=WRITE", "FORM=S",
                  "FILEDEF STGIN", "FSCB  'M173NET"):
    assert forbidden not in code,forbidden
for part in (
    "'STATE M173NET STAGE G'", "'STATE M174NET INDEX G'",
    "'STATE GITBX8 MODULE A'", "'STATE GITVO7M MODULE A'",
    "'STATE GITVO7 EXEC A'", "'STATE GITVRAW DATA A'",
    "if rc\\=28 then do", "M198 GITVRAW DATA A EXISTS",
    "M198 DO NOT TRUST POSSIBLE PARTIAL SCRATCH",
    "'GITBX8'", "'GITVO7 7736' oid",
    "M198 NATIVE FSREAD FULL OID GATE PASS G LAST",
    "'PIPE CMS FILEDEF | STEM f.'",
):
    assert part in EXEC,part
for forbidden in ("ERASE ", "FORMAT ", "FILEDEF STGIN",
                  "FILEDEF IDXIN", "DIRECTXA", "FSWRITE"):
    assert forbidden not in EXEC,forbidden
assert not (ROOT/"src/GITBX8.EXEC").exists()
assert not (ROOT/"src/GITB8.ASSEMBLE").exists()
assert 'fopen("dd:OBJIN","r")' in SHA

def data_records(data):
    hx=data.hex().upper()
    return [hx[i:i+64] for i in range(0,len(hx),64)]

def oid_for(data):
    return hashlib.sha1(
        b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest().upper()

def decode_last(header,body_lines):
    assert header.startswith("OBJ 7736 ")
    assert len(body_lines)==10
    out=bytearray()
    legal=set("0123456789ABCDEFabcdef")
    for i,row in enumerate(body_lines):
        assert 0<len(row)<=64 and len(row)%2==0
        assert i==9 or len(row)==64
        assert all(c in legal for c in row)
        out.extend(bytes.fromhex(row))
    assert 289<=len(out)<=320
    return bytes(out)

with tempfile.TemporaryDirectory(prefix="m198-") as dn:
    d=Path(dn)
    native=d/"gitvo7"
    subprocess.run([
        "gcc","-x","c","-std=c89","-Wall","-Wextra","-Werror",
        str(ROOT/"src/GITVO7M.C"),"-o",str(native)
    ],check=True)
    stage=d/"stage"
    scratch=d/"dd:OBJIN"
    for n in (289,290,300,319,320):
        data=bytes((i*37+n)%256 for i in range(n))
        head="OBJ 7736 3 %d %s"%(n,oid_for(data))
        lines=[head]+data_records(data)
        assert len(lines)==11
        stage.write_text("\n".join(lines)+"\n")
        orig=hashlib.sha256(stage.read_bytes()).hexdigest()
        copied=decode_last(lines[0],lines[1:])
        assert copied==data
        # Host analog of NEW cannot overwrite an existing scratch file.
        assert not scratch.exists()
        scratch.write_text("\n".join(lines)+"\n")
        result=subprocess.run(
            [str(native),"VERIFY","7736",oid_for(data)],
            cwd=d,capture_output=True,text=True)
        assert result.returncode==0,(n,result.stdout,result.stderr)
        assert "M197 READ ONLY FULL OBJECT SHA1 PASS" in result.stdout
        assert hashlib.sha256(stage.read_bytes()).hexdigest()==orig
        result=subprocess.run(
            [str(native),"VERIFY","7736","0"+oid_for(data)[1:]],
            cwd=d,capture_output=True,text=True)
        if oid_for(data)[0]!="0":
            assert result.returncode==8
        # No implicit overwrite: fixture consumer removes ONLY scratch.
        scratch.unlink()
        for badcase in ("short", "odd", "nonhex", "truncated"):
            corrupt=lines[:]
            if badcase=="short": corrupt[1]=corrupt[1][2:]
            elif badcase=="odd": corrupt[-1]=corrupt[-1][:-1]
            elif badcase=="nonhex": corrupt[2]="Z"+corrupt[2][1:]
            elif badcase=="truncated": corrupt=corrupt[:-1]
            try:
                decode_last(corrupt[0],corrupt[1:])
            except AssertionError:
                pass
            else:
                raise AssertionError((n,badcase))
    # M196 actual final object is TYPE 2 TREE / SIZE 291.
    # This synthetic tree's OID is independent of the real-stage OID.
    n=291
    data=bytes((i*29+11)%256 for i in range(n))
    expect=hashlib.sha1(b"tree 291"+bytes([0])+data).hexdigest().upper()
    lines=["OBJ 7736 2 291 "+expect]+data_records(data)
    assert len(lines)==11
    assert decode_last(lines[0],lines[1:])==data
    original=b"\n".join(row.encode("ascii") for row in lines)+b"\n"
    stage.write_bytes(original)
    assert not scratch.exists()
    scratch.write_bytes(original)
    result=subprocess.run(
        [str(native),"VERIFY","7736",expect],
        cwd=d,capture_output=True,text=True)
    assert result.returncode==0,(result.stdout,result.stderr)
    assert "M197 OBJECT 7736 TYPE 2 SIZE 291 BODY RECORDS 10" in result.stdout
    assert "M197 VERIFIED OID "+expect in result.stdout
    assert "M197 READ ONLY FULL OBJECT SHA1 PASS" in result.stdout
    assert stage.read_bytes()==original
    scratch.unlink()
print("M198 SOURCE: NEW-ONLY A SCRATCH AND READ-ONLY G GUARDS PASS")
print("M198 LAST TEN RECORDS HOST BODY/TYPE/OID SHA END TO END PASS")
print("M198 NO IBM CMS FSREAD/FSWRITE ASSEMBLE OR TARGET CLAIM")
