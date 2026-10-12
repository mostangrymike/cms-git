#!/usr/bin/env python3
"""M206: stratified index samples with full SHA and fail-closed source guards."""
from pathlib import Path
import hashlib
import shutil
import subprocess
import tempfile

root=Path(__file__).resolve().parents[1]
source=(root/"src/GITP26M.C").read_text()
rex=(root/"src/GITC26.EXEC").read_text()
assert max(map(len,source.splitlines()))<=80
assert max(map(len,rex.splitlines()))<=80
assert source.count('fopen("dd:IDXIN","r")')==1
assert 'fopen("dd:STGIN"' not in source
assert 'fwrite(' not in source and 'fseek(' not in source
assert "if(rec-1UL!=expected)" in source
assert "for(n=1;n<=total;n++)" in source
assert "for(k=0;k<count;k++)" in source
assert "picked[k]=0;" in source
assert "if(!picked[k])" in source
assert "M206 NO ELIGIBLE OBJECT IN BAND" in source
assert "picked[32]" in source
assert "num<2UL||num>32UL" in source
assert source.index("if(!picked[k])")<source.index(
    'printf("P201 ')
assert "start=((unsigned long)k*total)/(unsigned long)count+1UL;" in source
assert "end=((unsigned long)(k+1)*total)/(unsigned long)count;" in source
for token in (
    "parse upper arg fm mode max requested extra",
    "if extra\\='' then exit 4",
    "count=requested",
    "if count<2 | count>32 then exit 4",
    "'STATE M173NET STAGE G'",
    "'STATE M174NET INDEX G'",
    "'STATE GITP26M MODULE A'",
    "'STATE GITBX9 MODULE A'",
    "'PIPE CMS FILEDEF | STEM f.'",
    "'FILEDEF IDXIN DISK M174NET INDEX G'",
    "'PIPE CMS GITP26M SAMPLE 3864799' max count '| STEM plan.'",
    "'FILEDEF IDXIN CLEAR'",
    "readrc\\=0 | clearrc\\=0 | plan.0\\=count",
    "low=trunc((i-1)*7736/count)+1",
    "high=trunc(i*7736/count)",
    "if n<low | n>high | hdr<1 | hdr>3864799 then exit 8",
    "if cnt\\=trunc((size+31)/32) then exit 8",
    "'GITB9 G' span.i",
    "M206 SHA FAILED SCRATCH PRESERVED",
    "'GITCLN SCRATCH'",
    "M206 STRATIFIED FULL SHA CLEAN PASS",
):
    assert token in rex,token
assert rex.index("'GITB9 G' span.i")<rex.index("'GITCLN SCRATCH'")
assert rex.index("if authrc\\=0 then do")<rex.index("'GITCLN SCRATCH'")
for token in ("ERASE ", "FSWRITE", "FORMAT ", "PMAINT", "GIT600"):
    assert token not in rex

with tempfile.TemporaryDirectory(prefix="m205-") as name:
    d=Path(name)
    compiler=["gcc","-x","c","-std=c89","-Wall","-Wextra","-Werror"]
    for file,exe in (("GITP26M.C","planner"),
                     ("GITPIDX.C","builder"),
                     ("GITVO7M.C","verify")):
        subprocess.run(compiler+[str(root/"src"/file),"-o",str(d/exe)],
                       check=True)
    rows=[]
    expected={}
    for n in range(1,7737):
        size=1148 if n==3868 else 291 if n==7736 else 33+n%93
        body=n.to_bytes(4,"big")+bytes((n*11+i*23)%256
                                 for i in range(size-4))
        oid=hashlib.sha1(b"blob "+str(size).encode()+
                         b"\0"+body).hexdigest().upper()
        header=len(rows)+1
        count=(size+31)//32
        expected[n]=(header,count,3,size,oid)
        rows.append("OBJ %d 3 %d %s"%(n,size,oid))
        hx=body.hex().upper()
        rows.extend(hx[k:k+64] for k in range(0,len(hx),64))
    stage=d/"dd:STGIN"
    stage.write_text("\n".join(rows)+"\n")
    result=subprocess.run([str(d/"builder"),"BUILD"],cwd=d,
                          capture_output=True,text=True)
    assert result.returncode==0,(result.stdout,result.stderr)
    shutil.copy(d/"dd:IDXOUT",d/"dd:IDXIN")
    stagehash=hashlib.sha256(stage.read_bytes()).hexdigest()
    idxhash=hashlib.sha256((d/"dd:IDXIN").read_bytes()).hexdigest()
    def planner(*argv):
        return subprocess.run([str(d/"planner"),*map(str,argv)],
                              cwd=d,capture_output=True,text=True)
    for groups in (2,3,8,16,32):
        res=planner("SAMPLE",len(rows),64,groups)
        assert res.returncode==0,(groups,res.stdout,res.stderr)
        plans=res.stdout.splitlines()
        assert len(plans)==groups
        chosen=[]
        for i,line in enumerate(plans):
            assert len(line)<=80,(line,len(line))
            tag,n,rec,cnt,typ,size,oid=line.split()
            n,rec,cnt,typ,size=map(int,(n,rec,cnt,typ,size))
            assert tag=="P201"
            lower=i*7736//groups+1
            upper=(i+1)*7736//groups
            assert lower<=n<=upper,(groups,i,n)
            assert (rec,cnt,typ,size,oid)==expected[n]
            chosen.append(n)
            assert 0<size<=2048 and 0<cnt<=64
            # Host stand-in for M199: build scratch from exact stage
            # records, then independently verify using the M197 C89 core.
            scratch=d/"dd:OBJIN"
            subset=rows[rec-1:rec+cnt]
            assert len(subset)==cnt+1
            scratch.write_text("\n".join(subset)+"\n")
            verify=subprocess.run(
                [str(d/"verify"),"VERIFY",str(n),oid],
                cwd=d,text=True,capture_output=True)
            assert verify.returncode==0,(verify.stdout,verify.stderr)
            assert "M197 READ ONLY FULL OBJECT SHA1 PASS" in verify.stdout
            scratch.unlink()
        assert len(set(chosen))==groups
    for argv,rc in (
        (("SAMPLE",len(rows),64,1),4),
        (("SAMPLE",len(rows),64,33),4),
        (("SAMPLE",len(rows),0,8),4),
        (("SAMPLE",len(rows),1,8),8),
        (("SAMPLE",len(rows)+1,64,8),8)
    ):
        result=planner(*argv)
        assert result.returncode==rc,(argv,result.stdout,result.stderr)
        assert not any(x.startswith("P201 ") for x in
                       result.stdout.splitlines())
    # Make the entire first of 32 bands exceed the M199 bounds,
    # while maintaining a complete syntactically valid PIDX1.
    # No individual P201 record may escape after that failure.
    lines=(d/"dd:IDXIN").read_text().splitlines()
    larger=0
    mutated=[]
    for line in lines:
        fields=line.split()
        if len(fields)==6 and fields[0]=="OID":
            ordinal=int(fields[2])
            if 1<=ordinal<=7736//32:
                oldsize=int(fields[4])
                larger+=((2100+31)//32)-((oldsize+31)//32)
                fields[4]="2100"
                line=" ".join(fields)
        mutated.append(line)
    (d/"dd:IDXIN").write_text("\n".join(mutated)+"\n")
    rejected=planner("SAMPLE",len(rows)+larger,64,32)
    assert rejected.returncode==8,(rejected.stdout,rejected.stderr)
    assert "M206 NO ELIGIBLE OBJECT IN BAND" in rejected.stdout
    assert not any(x.startswith("P201 ") for x in
                   rejected.stdout.splitlines())
    shutil.copy(d/"dd:IDXOUT",d/"dd:IDXIN")
    assert hashlib.sha256(stage.read_bytes()).hexdigest()==stagehash
    assert hashlib.sha256((d/"dd:IDXIN").read_bytes()).hexdigest()==idxhash
print("M206 2/3/8/16/32 STRATIFIED INDEX BANDS AND FULL OID SHA PASS")
print("M206 STRICT C89 FAIL-CLOSED EMPTY BAND/RECORD COUNT PASS")
print("M206 PROTECTED G AND SCRATCH OWNERSHIP STATIC GUARDS PASS")
print("M206 CMS TARGET VALIDATION STILL PENDING")
