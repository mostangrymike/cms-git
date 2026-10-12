#!/usr/bin/env python3
"""M199: index-operator-parameterized CMS FSREAD to A-only scratch.

Linux checks IBM assembler form and independent C89 full Git SHA1 parity.
The IBM CMS assembler, FSREAD, FSWRITE and LINERD remain TARGET-ONLY.
"""
from pathlib import Path
import hashlib
import subprocess
import tempfile

root=Path(__file__).resolve().parents[1]
asm=(root/"src/GITBX9.ASSEMBLE").read_text()
rex=(root/"src/GITB9.EXEC").read_text()
sha=(root/"src/GITVO7M.C").read_text()
lines=asm.splitlines()
assert max(map(len,lines))<=72
assert max(map(len,rex.splitlines()))<=80
continuations=[row for row in lines if len(row)==72 and row[71]=="X"]
assert len(continuations)==5,continuations
assert len({row for row in continuations})==4
labels=[]
for i,row in enumerate(lines,1):
    if not row or row[0].isspace() or row.startswith("*"):
        continue
    label=row.split()[0]
    assert len(label)<=8,(i,label)
    assert row[len(label)].isspace(),(i,label)
    labels.append(label)
assert len(labels)==len(set(labels)),labels
code="\n".join(x for x in lines if x and not x.startswith("*"))
assert code.count("LINERD DATA=(INBUF,8),TYPE=STACK")==2
assert code.count("BAL   10,PARSEDEC")==2
assert "PARSEDEC C     0,=F'1'" in code
assert "C     0,=F'8'" in code
assert "C     6,=F'240'" in code and "C     6,=F'249'" in code
assert "S     6,=F'240'" in code and "MH    5,=H'10'" in code
assert "C     5,=F'3864799'" in code
assert "C     5,=F'64'" in code
assert "C     6,=F'3864799'" in code
assert "LA    6,1(5)" in code
assert "C     6,NRECS" in code
assert "C     6,BODYCNT" in code
assert "C     7,=F'64'" in code
assert "C     4,=F'2048'" in code
assert "CLC   RECSET(4),=C'OBJ '" in code
assert "LENSET   DS    65F" in code
assert "RECSET   DS    CL4160" in code
# A 4,160-byte DS moves later labels beyond an S/370 12-bit
# displacement from the single GITBX9 base register. Keep all
# referenced constants, texts and FSCB before RECSET.
huge=code.index("RECSET   DS    CL4160")
assert code.index("OUTFSCB  FSCB")<huge
assert code.index("START    DC")<huge
assert code.index("OCERR    DC")<huge
assert code.index("LENSET   DS    65F")<huge
assert code.index("RECSET   DS    CL4160")<code.index(
    "         END   GITBX9")
assert "FSREAD 'M173NET STAGE G1',BUFFER=(4),BSIZE=64" in code
assert "RECFM=V,RECNO=(5),NOREC=1,FORM=E" in code
assert "FSCLOSE 'M173NET STAGE G1',ERROR=ICLERR" in code
assert "FSOPEN FSCB=OUTFSCB,OPENTYP=NEW" in code
assert "FSWRITE FSCB=OUTFSCB,BUFFER=(4),BSIZE=(5)" in code
assert "FSCLOSE FSCB=OUTFSCB,ERROR=OCLERR" in code
assert "FSCB  'GITR199 DATA A1'" in code
assert code.index("FSCLOSE 'M173NET STAGE G1'") < code.index(
    "FSOPEN FSCB=OUTFSCB,OPENTYP=NEW")
assert code.count("FSREAD 'M173NET STAGE G1'")==1
assert code.count("FSWRITE FSCB=OUTFSCB")==1
for bad in ("FSWRITE 'M173NET", "FSERASE", "FSPOINT",
            "OPENTYP=REPLACE", "OPENTYP=WRITE",
            "FILEDEF STGIN", "FORM=S", "GITVRAW DATA"):
    assert bad not in code,bad
for token in (
    "'STATE M173NET STAGE G'", "'STATE M174NET INDEX G'",
    "'STATE GITR199 DATA A'", "'STATE GITBX9 MODULE A'",
    "'STATE GITVO7M MODULE A'", "'GITBX9'",
    "queue head", "queue count",
    "'PIPE CMS QUERY FILEDEF | STEM f.'",
    "'FILEDEF OBJIN DISK GITR199 DATA A'",
    "'GITVO7M VERIFY' obj oid",
    "'FILEDEF OBJIN CLEAR'",
    "M199 PARAMETERIZED FULL OID PASS G",
    "M199 SCRATCH EXISTS - REFUSE OVERWRITE",
    "M199 LEAVE POSSIBLE PARTIAL SCRATCH UNCHANGED",
):
    assert token in rex,token
assert "head+count>3864799" in rex
assert "count<1 | count>64" in rex
assert not (root/"src/GITBX9.EXEC").exists()
assert not (root/"src/GITB9.ASSEMBLE").exists()
assert 'fopen("dd:OBJIN","r")' in sha

def oid(t,body):
    kind={1:b"commit",2:b"tree",3:b"blob",4:b"tag"}[t]
    return hashlib.sha1(kind+b" "+str(len(body)).encode("ascii")+
                        bytes([0])+body).hexdigest().upper()

def records(t,n,body):
    dig=oid(t,body)
    h="OBJ %d %d %d %s"%(n,t,len(body),dig)
    hx=body.hex().upper()
    return [h]+([hx[x:x+64] for x in range(0,len(hx),64)]
                if hx else [""]),dig

def valid(records,expected):
    n=len(records)-1
    if n<1 or n>64 or not records[0].startswith("OBJ "):
        return False
    total=0
    for i,row in enumerate(records[1:]):
        if not 0<len(row)<=64 or len(row)%2:
            return False
        if i<n-1 and len(row)!=64:
            return False
        if any(c not in "0123456789ABCDEFabcdef" for c in row):
            return False
        total+=len(row)//2
    return total==expected and 0<total<=2048

with tempfile.TemporaryDirectory(prefix="m199-") as dn:
    d=Path(dn)
    native=d/"verify"
    subprocess.run(["gcc","-x","c","-std=c89","-Wall","-Wextra","-Werror",
                    str(root/"src/GITVO7M.C"),"-o",str(native)],
                   check=True)
    src=d/"readonly-stage"
    target=d/"dd:OBJIN"
    tests=[(1,3,1, b"a"),(3868,1,1969357,b"parent "+b"0"*40+b"\n"),
           (7736,2,3864789,bytes((k*19+7)%256 for k in range(291)))]
    tests += [(100+i,3,200000+i*10,bytes((j*13+i)%256
              for j in range(size)))
              for i,size in enumerate((2,31,32,33,63,64,65,289,320,
                                       511,512,1023,1024,2048),1)]
    for number,typ,header,body in tests:
        rows,expected_oid=records(typ,number,body)
        count=len(rows)-1
        assert 1<=header<=3864799 and header+count<=3864799
        assert valid(rows,len(body))
        src.write_text("\n".join(rows)+"\n")
        sha_before=hashlib.sha256(src.read_bytes()).hexdigest()
        assert not target.exists()
        target.write_bytes(src.read_bytes())
        result=subprocess.run([str(native),"VERIFY",str(number),
                               expected_oid],cwd=d,text=True,
                              capture_output=True)
        assert result.returncode==0,(number,result.stdout,result.stderr)
        assert "M197 READ ONLY FULL OBJECT SHA1 PASS" in result.stdout
        assert "M197 VERIFIED OID "+expected_oid in result.stdout
        assert hashlib.sha256(src.read_bytes()).hexdigest()==sha_before
        target.unlink()
        cases=(rows[:-1],
               rows[:1]+[rows[1][:-1]]+rows[2:],
               rows[:1]+["G"+rows[1][1:]]+rows[2:],
               rows+["AA"])
        for bad in cases:
            if bad==rows:continue
            if len(bad)!=len(rows):
                assert not valid(bad,len(body))
            elif bad is not rows and bad[1]!=rows[1]:
                assert not valid(bad,len(body))
    # Bounded record number parse with eight EBCDIC decimal bytes.
    for text in ("1","3864789","3864799","64","00000001","00000064"):
        assert 1<=len(text)<=8
        assert all(0xF0<=c<=0xF9 for c in text.encode("cp037"))
    for text in ("", "123456789", "-1", "12A", "12.0", " "):
        assert not (1<=len(text)<=8 and all(
            0xF0<=c<=0xF9 for c in text.encode("cp037")))
print("M199 HOST STRICT READ ONLY ORIGINAL STAGE MACRO GUARDS PASS")
print("M199 HOST INDEX-SPAN BOUNDS, 65 RECORD SLOTS AND OID SHA PASS")
print("M199 HOST NEGATIVE TRUNCATION/HEX/RECORD COUNT PASS")
print("M199 IBM CMS TARGET ASSEMBLY AND RUNTIME NOT YET VALIDATED")
