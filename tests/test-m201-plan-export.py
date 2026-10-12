#!/usr/bin/env python3
"""M201: strict C89 index-to-one-line tuple for automatic M199 use.

Host-only: the CMS PIPE/STEM output capture remains a real-CMS gate.
"""
from pathlib import Path
import hashlib
import re
import shutil
import subprocess
import tempfile

root=Path(__file__).resolve().parents[1]
native=(root/"src/GITP21M.C").read_text()
wrap=(root/"src/GITP21.EXEC").read_text()
assert max(map(len,native.splitlines()))<=80
assert max(map(len,wrap.splitlines()))<=80
assert 'fopen("dd:IDXIN","r")' in native
assert 'fopen("dd:STGIN"' not in native
assert 'fseek(' not in native and 'fwrite(' not in native
assert 'printf("P201 %lu %lu %lu %d %lu "' in native
assert 'putchar(\'\\n\');' in native
assert 'M201 INDEX INVALID' in native
assert 'M201 STAGE RECORD COUNT MISMATCH' in native
assert "M201 OBJECT EXCEEDS BODY RECORD LIMIT" in native
for needed in (
    "'STATE M173NET STAGE G'",
    "'STATE M174NET INDEX G'",
    "'STATE GITP21M MODULE A'",
    "'STATE GITBX9 MODULE A'",
    "'STATE GITVO7M MODULE A'",
    "'STATE GITR199 DATA A'",
    "'PIPE CMS FILEDEF | STEM f.'",
    "'FILEDEF IDXIN DISK M174NET INDEX G'",
    "'PIPE CMS GITP21M PLAN 3864799' obj limit '| STEM p.'",
    "'FILEDEF IDXIN CLEAR'",
    "planrc\\=0 | clearrc\\=0 | p.0\\=1",
    "if tag\\='P201' | trailing\\='' then exit 8",
    "if pn\\=obj | hdr<1 | hdr>3864799 then exit 8",
    "if cnt\\=trunc((size+31)/32) then exit 8",
    "'GITB9 G' pn hdr cnt oid",
    "M201 INDEX AUTOMATED FULL SHA PASS G",
    "M201 INDEX ONLY CHECK PASS G",
    "if mode='CHECK' then do",
    "M201 SCRATCH CREATED DURING PLAN - REFUSE"
):
    assert needed in wrap,needed
for bad in ("ERASE ", "FORMAT ", "FILEDEF STGIN",
            "OPENTYP=REPLACE", "GITVRAW DATA",
            "'GITBX9'", "FSWRITE", "FILEDEF * CLEAR"):
    assert bad not in wrap,bad
assert not (root/"src/GITP21M.EXEC").exists()

def oid(data):
    return hashlib.sha1(
        b"blob "+str(len(data)).encode("ascii")+b"\0"+data
    ).hexdigest().upper()

def call(prog,wd,*args):
    return subprocess.run([str(prog), *map(str,args)],
                          cwd=wd,capture_output=True,text=True)

with tempfile.TemporaryDirectory(prefix="m201-") as folder:
    wd=Path(folder)
    planner,builder=wd/"planner",wd/"builder"
    for src,out in ((root/"src/GITP21M.C",planner),
                    (root/"src/GITPIDX.C",builder)):
        subprocess.run(["gcc","-x","c","-std=c89","-Wall",
                        "-Wextra","-Werror",str(src),"-o",
                        str(out)],check=True)
    stage=wd/"dd:STGIN"
    index=wd/"dd:IDXIN"
    rows=[]
    plans={}
    for number in range(1,7737):
        size=(1148 if number==3868 else
              291 if number==7736 else
              4+(number*17)%84)
        # Every object carries a unique binary number prefix.
        # Otherwise the old periodic fixture produced duplicate
        # OIDs after the LCM of its length and byte-pattern cycles.
        body=(number.to_bytes(4,"big")+
              bytes((number+i*19)%256 for i in range(size-4)))
        plans[number]=(len(rows)+1,(size+31)//32,size,oid(body))
        rows.append("OBJ %d 3 %d %s"%(number,size,oid(body)))
        hx=body.hex().upper()
        rows.extend(hx[x:x+64] for x in range(0,len(hx),64))
    stage.write_text("\n".join(rows)+"\n")
    build=call(builder,wd,"BUILD")
    assert build.returncode==0,build.stdout+build.stderr
    shutil.copy(wd/"dd:IDXOUT",index)
    orig=hashlib.sha256(stage.read_bytes()).hexdigest()
    idxhash=hashlib.sha256(index.read_bytes()).hexdigest()
    # The fixture must satisfy GitPIDX's unique OID requirement.
    assert len(set(plan[3] for plan in plans.values()))==7736
    assert wrap.index("if mode='CHECK' then do") < wrap.index(
        "'GITB9 G' pn hdr cnt oid")
    for number in (1,3868,7736):
        expected_header,expected_count,size,sha=plans[number]
        result=call(planner,wd,"PLAN",len(rows),number,64)
        assert result.returncode==0,(number,result.stdout,result.stderr)
        assert len(result.stdout.splitlines())==1,result.stdout
        record=result.stdout.strip()
        assert len(record)<=80,(number,len(record))
        parts=record.split()
        assert len(parts)==7,parts
        marker,obj,header,count,typ,body_size,digest=parts
        assert marker=="P201"
        assert (int(obj),int(header),int(count),int(typ),
                int(body_size),digest)==(
                    number,expected_header,expected_count,3,size,sha)
        assert re.fullmatch(r"[0-9A-F]{40}",digest)
        if expected_count>1:
            limited=call(planner,wd,"PLAN",len(rows),
                         number,expected_count-1)
            assert limited.returncode==8
            assert "M201 OBJECT EXCEEDS BODY RECORD LIMIT" in limited.stdout
    bad=call(planner,wd,"PLAN",len(rows)+1,7736,64)
    assert bad.returncode==8
    assert "M201 STAGE RECORD COUNT MISMATCH" in bad.stdout
    bad=call(planner,wd,"PLAN",len(rows),7737,64)
    assert bad.returncode==8
    bad=call(planner,wd,"PLAN",len(rows),3868,0)
    assert bad.returncode==4
    damaged=index.read_text().splitlines()
    pos=next(i for i,x in enumerate(damaged) if x.startswith("OID "))
    damaged[pos]=damaged[pos].replace("OID ","OID Z",1)
    index.write_text("\n".join(damaged)+"\n")
    failed=call(planner,wd,"PLAN",len(rows),3868,64)
    assert failed.returncode==8
    assert "M201 INDEX INVALID" in failed.stdout
    assert hashlib.sha256(stage.read_bytes()).hexdigest()==orig
    index.unlink()
    shutil.copy(wd/"dd:IDXOUT",index)
    assert hashlib.sha256(index.read_bytes()).hexdigest()==idxhash
print("M201 7736-OBJECT INDEX PARITY AND COMPACT TUPLE PASS")
print("M201 FIRST MID LAST SHA/OID/RECORD COUNT HOST PASS")
print("M201 FAIL-CLOSED BOUNDS/CORRUPTION AND READ-ONLY G PASS")
print("M201 PIPE/STEM CMS CAPTURE AND FULL RUN NOT YET TARGET-TESTED")
