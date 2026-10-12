#!/usr/bin/env python3
"""M204 index-once bounded plan: strict C89 and fail-closed SHA wrapper."""
from pathlib import Path
import hashlib
import subprocess
import tempfile
import shutil

root=Path(__file__).resolve().parents[1]
src=(root/"src/GITP24M.C").read_text()
rex=(root/"src/GITC24.EXEC").read_text()
assert max(map(len,src.splitlines()))<=80
assert max(map(len,rex.splitlines()))<=80
assert src.count('fopen("dd:IDXIN","r")')==1
assert 'fopen("dd:STGIN"' not in src
assert 'fwrite(' not in src
assert "M204 INDEX INVALID" in src
assert "M204 STAGE RECORD COUNT MISMATCH" in src
assert "M204 OBJECT EXCEEDS READER BOUND" in src
assert "if(argc<6||argc>12" in src
assert "allplans(expected,limit,wants,count)" in src
assert src.index("/* All tuples must pass checks")<src.index(
    'printf("P201 ')
for token in (
    "parse upper arg fm mode max objects",
    "count=words(objects)",
    "count<2 | count>8",
    "if obj.i=obj.j then exit 4",
    "'PIPE CMS FILEDEF | STEM f.'",
    "'FILEDEF IDXIN DISK M174NET INDEX G'",
    "'PIPE CMS GITP24M BATCH 3864799' max objects '| STEM plan.'",
    "'FILEDEF IDXIN CLEAR'",
    "readrc\\=0 | clearrc\\=0 | plan.0\\=count",
    "if n\\=obj.i | hdr<1 | hdr>3864799 then exit 8",
    "if cnt\\=trunc((size+31)/32) then exit 8",
    "'GITB9 G' span.i",
    "M204 SHA FAILED SCRATCH PRESERVED",
    "'GITCLN SCRATCH'",
    "M204 ONE INDEX FULL SHA CLEAN PASS",
):
    assert token in rex,token
assert rex.count("'GITCLN SCRATCH'")==1
assert rex.index("'GITB9 G' span.i")<rex.index("'GITCLN SCRATCH'")
assert rex.index("if authrc\\=0 then do")<rex.index("'GITCLN SCRATCH'")
for token in ("ERASE ", "FSWRITE", "FORMAT ", "PMAINT", "GIT600"):
    assert token not in rex

def oid(data):
    return hashlib.sha1(b"blob "+str(len(data)).encode()+
                        b"\0"+data).hexdigest().upper()

with tempfile.TemporaryDirectory(prefix="m204-") as td:
    d=Path(td)
    planner=d/"planner"
    builder=d/"builder"
    for source,binary in ((root/"src/GITP24M.C",planner),
                          (root/"src/GITPIDX.C",builder)):
        subprocess.run(["gcc","-x","c","-std=c89","-Wall",
                        "-Wextra","-Werror",str(source),
                        "-o",str(binary)],check=True)
    rows=[]
    items={}
    for num in range(1,7737):
        size=1148 if num==3868 else 291 if num==7736 else 4+num%93
        blob=(num.to_bytes(4,"big")+
              bytes((num*19+k*37)%256 for k in range(size-4)))
        digest=oid(blob)
        rec=len(rows)+1
        count=(size+31)//32
        items[num]=(rec,count,3,size,digest)
        rows.append("OBJ %d 3 %d %s"%(num,size,digest))
        hx=blob.hex().upper()
        rows.extend(hx[k:k+64] for k in range(0,len(hx),64))
    (d/"dd:STGIN").write_text("\n".join(rows)+"\n")
    build=subprocess.run([str(builder),"BUILD"],cwd=d,
                         capture_output=True,text=True)
    assert build.returncode==0,(build.stdout,build.stderr)
    shutil.copy(d/"dd:IDXOUT",d/"dd:IDXIN")
    original=hashlib.sha256((d/"dd:IDXIN").read_bytes()).hexdigest()
    def run(*args):
        return subprocess.run([str(planner),*map(str,args)],cwd=d,
                              capture_output=True,text=True)
    for chosen in ([3868,7736],[1,3868,7736],list(range(1,9))):
        p=run("BATCH",len(rows),64,*chosen)
        assert p.returncode==0,(p.stdout,p.stderr)
        lines=p.stdout.splitlines()
        assert len(lines)==len(chosen),lines
        for ln,num in zip(lines,chosen):
            assert len(ln)<=80,(ln,len(ln))
            tag,obj,header,count,typ,size,digest=ln.split()
            assert tag=="P201"
            assert (int(obj),int(header),int(count),int(typ),
                    int(size),digest)==(num,*items[num])
    for args,returncode in (
        (("BATCH",len(rows),64,3868,3868),4),
        (("BATCH",len(rows),64,3868),4),
        (("BATCH",len(rows),64,*range(1,10)),4),
        (("BATCH",len(rows),0,3868,7736),4),
        (("BATCH",len(rows)+1,64,3868,7736),8),
        (("BATCH",len(rows),1,3868,7736),8)
    ):
        res=run(*args)
        assert res.returncode==returncode,(args,res.stdout,res.stderr)
        assert not any(line.startswith("P201 ") for line in
                       res.stdout.splitlines())
    assert hashlib.sha256((d/"dd:IDXIN").read_bytes()).hexdigest()==original
print("M204 ONE-INDEX 2/3/8 TUPLE PARITY AND STRICT C89 PASS")
print("M204 INVALID INDEX BOUNDS ALL-OR-NOTHING OUTPUT PASS")
print("M204 CMS WRAPPER AUTH-THEN-CLEAN SOURCE GUARDS PASS")
print("M204 TARGET CMS VALIDATION STILL REQUIRED")
