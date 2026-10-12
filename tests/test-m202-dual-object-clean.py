#!/usr/bin/env python3
"""M202 host guard: strictly two distinct full SHA objects, cleanup after PASS.

The real CMS REXX execution remains a separate target-only gate.
"""
from pathlib import Path
from dataclasses import dataclass

ROOT=Path(__file__).resolve().parents[1]
rex=(ROOT/"src/GITC22.EXEC").read_text()
assert max(map(len,rex.splitlines()))<=80
for token in (
    "parse upper arg fm one two limit mode extra",
    "mode\\='CHECK' & mode\\='RUN'",
    "one=two | limit<1 | limit>64",
    "'STATE GITVRAW DATA A'",
    "M202 OLD M198 SCRATCH EXISTS - REFUSE CLEANUP",
    "'STATE GITR199 DATA A'",
    "M202 OLD M199 SCRATCH EXISTS - REFUSE OVERWRITE",
    "'PIPE CMS FILEDEF | STEM f.'",
    "'GITP21 G' one limit 'CHECK'",
    "'GITP21 G' two limit 'CHECK'",
    "M202 TWO OBJECT INDEX PREFLIGHT PASS",
    "if mode='CHECK' then do",
    "M202 TWO OBJECT CHECK ONLY PASS",
    "M202 TWO OBJECT FULL SHA CLEAN PASS",
    "runone: procedure",
    "'GITP21 G' obj lim",
    "'GITCLN SCRATCH'",
    "M202 SHA FAIL; SCRATCH PRESERVED",
    "M202 SCRATCH CLEAN VERIFIED",
):
    assert token in rex,token
assert rex.count("'GITCLN SCRATCH'")==1
assert rex.count("'GITP21 G' obj lim")==1
assert rex.index("M202 TWO OBJECT CHECK ONLY PASS")<rex.index(
    "M202 FIRST OBJECT AUTH BEGIN")
runone=rex.split("runone: procedure",1)[1]
assert runone.index("'GITP21 G' obj lim")<runone.index(
    "'GITCLN SCRATCH'")
assert runone.index("if objrc\\=0 then do")<runone.index(
    "'GITCLN SCRATCH'")
assert runone.index("if cleanrc\\=0 then do")<runone.index(
    "M202 SCRATCH CLEAN VERIFIED")
assert rex.index("'STATE GITVRAW DATA A'")<rex.index(
    "'GITCLN SCRATCH'")
assert "if rc\\=28 then do" in rex
for forbidden in (
    "ERASE ", "FORMAT ", "FILEDEF * CLEAR", "FILEDEF STGIN",
    "FSWRITE", "FSCLOSE", "GITBX8", "GITFL10",
    "GITFSRD", "GITFRB", "DIRECTXA", "PMAINT",
    "GITVRAW DATA A1", "M173NET STAGE", "M174NET INDEX",
    "GIT600", "PIPE CMS GITP21",
):
    assert forbidden not in rex,forbidden

# Outcome-state model of the REXX sequence. Failing an object's
# full digest MUST NOT erase its diagnostic scratch. A cleanup error
# is also fatal and blocks any subsequent object's authentication.
@dataclass
class Outcome:
    statuses: list
    log: list
    scratch: bool

def model(one,two,checks,results,cleans,mode="RUN"):
    log=[]
    scratch=False
    if not 1<=one<=7736 or not 1<=two<=7736 or one==two:
        return Outcome(["INVALID"],log,scratch)
    log.extend([("CHECK",one),("CHECK",two)])
    if not all(checks):
        return Outcome(["FAIL_PREFLIGHT"],log,scratch)
    if mode=="CHECK":
        return Outcome(["CHECK_ONLY_PASS"],log,scratch)
    for index,obj in enumerate((one,two)):
        log.append(("SHA",obj))
        scratch=True
        if not results[index]:
            return Outcome(["SHA_FAIL"],log,scratch)
        log.append(("CLEAN",obj))
        if not cleans[index]:
            return Outcome(["CLEAN_FAIL"],log,scratch)
        scratch=False
    return Outcome(["FULL_PASS"],log,scratch)

first,second=3868,7736
cases=[
  ((True,True),(True,True),(True,True),
   ["FULL_PASS"],[("CHECK",3868),("CHECK",7736),
                  ("SHA",3868),("CLEAN",3868),
                  ("SHA",7736),("CLEAN",7736)],False),
  ((False,True),(True,True),(True,True),
   ["FAIL_PREFLIGHT"],[("CHECK",3868),("CHECK",7736)],False),
  ((True,True),(False,True),(True,True),
   ["SHA_FAIL"],[("CHECK",3868),("CHECK",7736),
                 ("SHA",3868)],True),
  ((True,True),(True,False),(True,True),
   ["SHA_FAIL"],[("CHECK",3868),("CHECK",7736),
                 ("SHA",3868),("CLEAN",3868),
                 ("SHA",7736)],True),
  ((True,True),(True,True),(False,True),
   ["CLEAN_FAIL"],[("CHECK",3868),("CHECK",7736),
                   ("SHA",3868),("CLEAN",3868)],True),
]
for checks,shas,cleans,expect,events,remaining in cases:
    got=model(first,second,checks,shas,cleans)
    assert (got.statuses,got.log,got.scratch)==(
        expect,events,remaining),got
got=model(first,second,(True,True),(False,False),(True,True),
          mode="CHECK")
assert got.statuses==["CHECK_ONLY_PASS"]
assert all(ev[0]=="CHECK" for ev in got.log)
assert not got.scratch
assert model(3868,3868,(True,True),(True,True),
             (True,True)).statuses==["INVALID"]
print("M202 HOST TWO DISTINCT INDEX-SELECTED OBJECT GUARDS PASS")
print("M202 FULL SHA THEN EXACT SCRATCH CLEANUP ORDER PASS")
print("M202 FAILURE PRESERVES SCRATCH; CHECK MODE NO WRITES PASS")
print("M202 NO REAL CMS TARGET RUN YET")
