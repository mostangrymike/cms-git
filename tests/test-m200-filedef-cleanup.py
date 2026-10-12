#!/usr/bin/env python3
"""M200 CMS filedef syntax and exact-name A1 cleanup safety gate."""
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[1]
source=(ROOT/"src/GITCLN.EXEC").read_text()
assert max(len(s) for s in source.splitlines())<=80
assert "parse upper arg mode extra" in source
assert "mode\\='SCRATCH' & mode\\='RETIRED'" in source
assert "'QUERY DISK A'" in source
assert "'PIPE CMS FILEDEF | STEM defs.'" in source
assert "M200 FILEDEF DISK STILL ACTIVE - REFUSE CLEANUP" in source
assert "word(rec,2)='DISK'" in source
assert "'STATE' filename filetype 'A1'" in source
assert "'ERASE' filename filetype 'A1'" in source
assert "M200 ERASE NOT CONFIRMED" in source
assert "checkrc=28" in source and "afterrc\\=28" in source
assert "M200 CLEANUP PASS" in source
assert "M200 ERASING EXACT" in source

# No broad/wildcard erase or any change to the original G stage,
# index or current active M196/M197/M199 native tools.
for forbidden in (
    "ERASE *", "ERASE G", "ERASE' fn ft 'G",
    "ERASE GIT600", "M173NET", "M174NET", "PMAINT",
    "GITBX9", "GITB9", "GITVO7M", "GITRP6M",
    "FORMAT", "DIRECTXA", "FSWRITE", "FSERASE",
    "FILEDEF * CLEAR", "ACCESS  ERASE", "REPLACE"
):
    assert forbidden not in source, forbidden
candidates=re.findall(
    r"^ call cleaner '([A-Z0-9]+)','([A-Z0-9]+)'$",
    source, flags=re.MULTILINE
)
scratches={("GITVRAW","DATA"),("GITR199","DATA")}
retired={
 ("GITFSRD","MODULE"),("GITFSP","EXEC"),
 ("GITFRB","MODULE"),("GITFRP","EXEC"),
 ("GITFL10","MODULE"),("GITFLP","EXEC"),
 ("GITBX8","MODULE"),("GITB8","EXEC"),
 ("GITFSRD","TEXT"),("GITFRB","TEXT"),
 ("GITFL10","TEXT"),("GITBX8","TEXT"),
 ("GITFSRD","LISTING"),("GITFRB","LISTING"),
 ("GITFL10","LISTING"),("GITBX8","LISTING")
}
assert len(candidates)==len(set(candidates))==len(scratches|retired)
assert set(candidates)==scratches|retired
assert all(len(x)<=8 and len(y)<=8 for x,y in candidates)
# Validate both user-facing modes own exactly their file lists.
scr=source.split("if mode='SCRATCH' then do",1)[1].split(
    "\nend\nelse do",1)[0]
ret=source.split("\nelse do",1)[1].split(
    "\nend\nsay 'M200 CLEANUP PASS'",1)[0]
assert set(re.findall(r"call cleaner '([A-Z0-9]+)','([A-Z0-9]+)'",scr))==scratches
assert set(re.findall(r"call cleaner '([A-Z0-9]+)','([A-Z0-9]+)'",ret))==retired

# Every native wrapper that inspects defined ddnames must invoke
# the CMS FILEDEF listing command, not ambiguous QUERY FILEDEF.
for filename in ("GITRP6.EXEC","GITB8.EXEC","GITB9.EXEC",
                 "GITVO7.EXEC"):
    x=(ROOT/"src"/filename).read_text()
    assert "'PIPE CMS FILEDEF | STEM f.'" in x,filename
    assert "PIPE CMS QUERY FILEDEF" not in x,filename
# Preserve fail-closed native/wrapper success gates and ownership.
p=(ROOT/"src/GITB9.EXEC").read_text()
assert "'FILEDEF OBJIN CLEAR'" in p
assert "'FILEDEF OBJIN DISK GITR199 DATA A'" in p
assert "if hashrc\\=0 | clearrc\\=0 then do" in p
print("M200 CMS FILEDEF NO-OPERAND LISTING GUARD PASS")
print("M200 EXACT A1 SCRATCH FILES AND RETIRED EXEC PROBES WHITELIST PASS")
print("M200 ORIGINAL G AND ACTIVE M196/M197/M199 PROTECTED")
print("M200 CMS CLEANUP STILL REQUIRES TARGET VALIDATION")
