#!/usr/bin/env python3
"""M203: bounded 2..8-object CMS REXX verification order guard."""
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
code=(ROOT/"src/GITC23.EXEC").read_text()
assert max(map(len,code.splitlines()))<=80
tokens=[
 "parse upper arg fm mode limit members",
 "count=words(members)",
 "count<2 | count>8",
 "objs.i=word(members,i)",
 "objs.i<1 | objs.i>7736",
 "if objs.i=objs.j then do",
 "'STATE GITP21M MODULE A'",
 "'STATE GITBX9 MODULE A'",
 "'STATE GITVO7M MODULE A'",
 "'STATE GITVRAW DATA A'",
 "'STATE GITR199 DATA A'",
 "'PIPE CMS FILEDEF | STEM defs.'",
 "'GITP21 G' objs.i limit 'CHECK'",
 "M203 ALL INDEX CHECKS PASS",
 "M203 CHECK ONLY NO SCRATCH PASS",
 "'GITP21 G' obj limit",
 "M203 SHA GATE FAIL SCRATCH PRESERVED",
 "'GITCLN SCRATCH'",
 "M203 FULL OBJECT SHA VERIFIED",
 "M203 CLEAN VERIFIED",
 "M203 BOUNDED FULL SHA CLEAN PASS"
]
for token in tokens:
    assert token in code,token
assert code.count("'GITCLN SCRATCH'")==1
assert code.count("'GITP21 G' obj limit")==1
assert code.count("'GITP21 G' objs.i limit 'CHECK'")==1
pre,post=code.split("if mode='CHECK' then do",1)
assert "M203 ALL INDEX CHECKS PASS" in pre
assert post.index("'GITP21 G' obj limit")<post.index(
    "'GITCLN SCRATCH'")
assert post.index("if s\\=0 then do")<post.index(
    "'GITCLN SCRATCH'")
for token in ("M173NET", "M174NET", "GIT600",
              "FSWRITE", "FSREAD", "OPENTYP=REPLACE"):
    assert token not in code,token
def valid(items):
    if not 2<=len(items)<=8: return False
    if any(not isinstance(x,int) or isinstance(x,bool) or
           x<1 or x>7736 for x in items): return False
    return len(set(items))==len(items)
for seq in ([3868,7736],[1,3868,7736],list(range(1,9))):
    assert valid(seq)
for seq in ([1],list(range(1,10)),[1,1],[1,7737]):
    assert not valid(seq)
def simulate(items,failcheck=-1,failsha=-1,failclean=-1,
             checking=False):
    if not valid(items):return "BAD",[],False
    events=[]
    scratch=False
    for i,obj in enumerate(items):
        events.append(("CHECK",obj))
        if i==failcheck:return "CHECK_FAIL",events,scratch
    if checking:return "CHECK_PASS",events,scratch
    for i,obj in enumerate(items):
        events.append(("SHA",obj))
        scratch=True
        if i==failsha:return "SHA_FAIL",events,scratch
        events.append(("CLEAN",obj))
        if i==failclean:return "CLEAN_FAIL",events,scratch
        scratch=False
    return "PASS",events,scratch
for seq in ([3868,7736],[1,3868,7736],list(range(1,9))):
    a,e,s=simulate(seq)
    assert a=="PASS" and not s
    assert [x[0] for x in e[:len(seq)]]==["CHECK"]*len(seq)
    a,e,s=simulate(seq,checking=True)
    assert a=="CHECK_PASS" and not s
    assert len(e)==len(seq)
    a,e,s=simulate(seq,failcheck=len(seq)-1)
    assert a=="CHECK_FAIL" and not s
    assert all(x[0]=="CHECK" for x in e)
    a,e,s=simulate(seq,failsha=0)
    assert a=="SHA_FAIL" and s and ("CLEAN",seq[0]) not in e
    a,e,s=simulate(seq,failclean=0)
    assert a=="CLEAN_FAIL" and s and ("SHA",seq[1]) not in e
print("M203 BOUNDED DISTINCT OBJECTS, PREFLIGHT AND SHA HOST PASS")
print("M203 FAILED SHA/CLEANUP PRESERVES SCRATCH AND STOPS")
print("M203 REAL CMS TARGET CHECK/RUN STILL PENDING")
