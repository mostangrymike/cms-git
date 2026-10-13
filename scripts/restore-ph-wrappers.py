#!/usr/bin/env python3
"""Losslessly regenerate five historical CMS wrapper EXEC files.

Usage: python3 scripts/restore-ph-wrappers.py NAME.EXEC|ALL|CHECK
CHECK compares existing sources with generated originals without writing.
No overwrite in restoration mode; protects changes and working files.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
SPECS = {
  "GITPH2": [
    "M182",
    "/* M182: GITPH2 EXEC calls separate GITPH2M MODULE. */"
  ],
  "GITPH3": [
    "M183",
    "/* M183: GITPH3 wrapper calls separate native GITPH3M. */"
  ],
  "GITPH5": [
    "M185",
    "/* M185: isolated read-only direct record validator. */"
  ],
  "GITPH8": [
    "M188",
    "/* M188: isolated read-only direct record validator. */"
  ],
  "GITPH9": [
    "M189",
    "/* M189: isolated read-only direct record validator. */"
  ]
}
TEMPLATE = "address cms\nparse upper arg datafm oid extra\noid=translate(strip(oid))\nif datafm='' | oid='' | extra\\='' then do\n say 'Usage: @@NAME@@ data-filemode 40-hex-tree-oid'\n exit 4\nend\nif length(datafm)\\=1 |,\n   verify(datafm,'BCDEFGHIJKLMNOPQRSTUVWXYZ')\\=0 then do\n say '@@MILESTONE@@ FILEMODE INVALID'\n exit 4\nend\nif length(oid)\\=40 |,\n   verify(oid,'0123456789ABCDEF')\\=0 then do\n say '@@MILESTONE@@ OID INVALID'\n exit 4\nend\ndrop d.\nd.0=0\n'PIPE CMS QUERY DISK' datafm '| STEM d.'\nif rc\\=0 then do\n say '@@MILESTONE@@ QUERY DISK FAILED'\n exit 8\nend\nmatched=0\ndo i=1 to d.0\n if word(d.i,3)=datafm & word(d.i,7)='4096' then,\n   matched=matched+1\nend\nif matched\\=1 then do\n say '@@MILESTONE@@ DATA DISK NOT ACCESSED 4K' datafm\n exit 8\nend\n'STATE M173NET STAGE' datafm\nif rc\\=0 then do\n say '@@MILESTONE@@ STAGE MISSING' datafm\n exit 8\nend\n'STATE M174NET INDEX' datafm\nif rc\\=0 then do\n say '@@MILESTONE@@ INDEX MISSING' datafm\n exit 8\nend\n'STATE @@NAME@@M MODULE A'\nif rc\\=0 then do\n say '@@MILESTONE@@ MODULE MISSING'\n exit 8\nend\n\n/* An existing caller FILEDEF is never overwritten or cleared. */\ndrop f.\nf.0=0\n'PIPE CMS QUERY FILEDEF | STEM f.'\nif rc\\=0 then do\n say '@@MILESTONE@@ FILEDEF QUERY FAILED'\n exit 8\nend\ndo i=1 to f.0\n dd=translate(word(f.i,1))\n if dd='STGIN' | dd='IDXIN' then do\n  say '@@MILESTONE@@ DD ALREADY DEFINED' dd\n  exit 8\n end\nend\n'FILEDEF STGIN DISK M173NET STAGE' datafm\nif rc\\=0 then do\n say '@@MILESTONE@@ STGIN FILEDEF FAILED'\n exit 8\nend\n'FILEDEF IDXIN DISK M174NET INDEX' datafm\nif rc\\=0 then do\n 'FILEDEF STGIN CLEAR'\n say '@@MILESTONE@@ IDXIN FILEDEF FAILED'\n exit 8\nend\n\ndrop o.\no.0=0\n'PIPE CMS @@NAME@@M WALK' oid '| STEM o.'\nworkrc=rc\n'FILEDEF IDXIN CLEAR'\nidxrc=rc\n'FILEDEF STGIN CLEAR'\nstgrc=rc\ndo i=1 to o.0\n say o.i\nend\nif workrc\\=0 | idxrc\\=0 | stgrc\\=0 then do\n say '@@MILESTONE@@ FAST TREE FAIL RC' workrc idxrc stgrc\n exit 8\nend\n\n/* Cross-check exact requested root, aggregate counts and native PASS. */\npass=0\nfound=0\nscans=0\nstatok=0\ntrees=''\nblobs=''\nentries=''\nverified=''\ndo i=1 to o.0\n if o.i='@@MILESTONE@@ TREE CLOSURE PASS' then pass=pass+1\n if word(o.i,1)='TREE' & word(o.i,2)='CLOSURE' then do\n  if word(o.i,3)='ROOT' & words(o.i)=4 &,\n     word(o.i,4)=oid then found=found+1\n  if word(o.i,3)='TREES' & word(o.i,5)='BLOBS' &,\n     words(o.i)=8 then do\n   trees=word(o.i,4)\n   blobs=word(o.i,6)\n  end\n  if word(o.i,3)='ENTRIES' & word(o.i,5)='VERIFIED' &,\n     words(o.i)=6 then do\n   entries=word(o.i,4)\n   verified=word(o.i,6)\n  end\n end\n if word(o.i,1)='@@MILESTONE@@' & word(o.i,2)='FORWARD' &,\n    word(o.i,3)='SCANS' & word(o.i,4)='2' &,\n    word(o.i,7)='SEEKS' & word(o.i,8)='0' &,\n    words(o.i)=8 then scans=scans+1\n if word(o.i,1)='@@MILESTONE@@' & word(o.i,2)='AUTHENTICATED' &,\n    word(o.i,3)='BLOBS' & words(o.i)=4 &,\n    word(o.i,4)=blobs then statok=statok+1\nend\nif pass\\=1 | found\\=1 | scans\\=1 | statok\\=1 |,\n   datatype(trees,'W')\\=1 | datatype(blobs,'W')\\=1 |,\n   datatype(entries,'W')\\=1 | datatype(verified,'W')\\=1 then do\n say '@@MILESTONE@@ FAST TREE CROSSCHECK FAIL'\n exit 8\nend\nif trees<1 | verified\\=trees+blobs | entries<blobs+trees-1 then do\n say '@@MILESTONE@@ FAST TREE COUNT FAIL'\n exit 8\nend\nsay '@@MILESTONE@@ VERIFIED FAST TREE TARGET GATE PASS' oid datafm\nexit 0\n"

EXTRA_SPECS = {
  "GITPFAST": [
    "M178",
    "GITPFST",
    "/* M178: isolated fast read-only native stage tree verification. */"
  ],
  "GITPPROF": [
    "M179",
    "GITPPRF",
    "/* M179: isolated fast read-only native stage tree verification. */"
  ]
}
EXTRA_TEMPLATE = "address cms\nparse upper arg datafm oid extra\noid=translate(strip(oid))\nif datafm='' | oid='' | extra\\='' then do\n say 'Usage: @@NAME@@ data-filemode 40-hex-tree-oid'\n exit 4\nend\nif length(datafm)\\=1 |,\n   verify(datafm,'BCDEFGHIJKLMNOPQRSTUVWXYZ')\\=0 then do\n say '@@MILESTONE@@ FILEMODE INVALID'\n exit 4\nend\nif length(oid)\\=40 |,\n   verify(oid,'0123456789ABCDEF')\\=0 then do\n say '@@MILESTONE@@ OID INVALID'\n exit 4\nend\ndrop d.\nd.0=0\n'PIPE CMS QUERY DISK' datafm '| STEM d.'\nif rc\\=0 then do\n say '@@MILESTONE@@ QUERY DISK FAILED'\n exit 8\nend\nmatched=0\ndo i=1 to d.0\n if word(d.i,3)=datafm & word(d.i,7)='4096' then,\n   matched=matched+1\nend\nif matched\\=1 then do\n say '@@MILESTONE@@ DATA DISK NOT ACCESSED 4K' datafm\n exit 8\nend\n'STATE M173NET STAGE' datafm\nif rc\\=0 then do\n say '@@MILESTONE@@ STAGE MISSING' datafm\n exit 8\nend\n'STATE M174NET INDEX' datafm\nif rc\\=0 then do\n say '@@MILESTONE@@ INDEX MISSING' datafm\n exit 8\nend\n'STATE @@MOD@@ MODULE A'\nif rc\\=0 then do\n say '@@MILESTONE@@ MODULE MISSING'\n exit 8\nend\n\n/* An existing caller FILEDEF is never overwritten or cleared. */\ndrop f.\nf.0=0\n'PIPE CMS QUERY FILEDEF | STEM f.'\nif rc\\=0 then do\n say '@@MILESTONE@@ FILEDEF QUERY FAILED'\n exit 8\nend\ndo i=1 to f.0\n dd=translate(word(f.i,1))\n if dd='STGIN' | dd='IDXIN' then do\n  say '@@MILESTONE@@ DD ALREADY DEFINED' dd\n  exit 8\n end\nend\n'FILEDEF STGIN DISK M173NET STAGE' datafm\nif rc\\=0 then do\n say '@@MILESTONE@@ STGIN FILEDEF FAILED'\n exit 8\nend\n'FILEDEF IDXIN DISK M174NET INDEX' datafm\nif rc\\=0 then do\n 'FILEDEF STGIN CLEAR'\n say '@@MILESTONE@@ IDXIN FILEDEF FAILED'\n exit 8\nend\n\ndrop o.\no.0=0\n'PIPE CMS @@MOD@@ WALK' oid '| STEM o.'\nworkrc=rc\n'FILEDEF IDXIN CLEAR'\nidxrc=rc\n'FILEDEF STGIN CLEAR'\nstgrc=rc\ndo i=1 to o.0\n say o.i\nend\nif workrc\\=0 | idxrc\\=0 | stgrc\\=0 then do\n say '@@MILESTONE@@ FAST TREE FAIL RC' workrc idxrc stgrc\n exit 8\nend\n\n/* Cross-check exact requested root, aggregate counts and native PASS. */\npass=0\nfound=0\nscans=0\nstatok=0\ntrees=''\nblobs=''\nentries=''\nverified=''\ndo i=1 to o.0\n if o.i='@@MILESTONE@@ TREE CLOSURE PASS' then pass=pass+1\n if word(o.i,1)='TREE' & word(o.i,2)='CLOSURE' then do\n  if word(o.i,3)='ROOT' & words(o.i)=4 &,\n     word(o.i,4)=oid then found=found+1\n  if word(o.i,3)='TREES' & word(o.i,5)='BLOBS' &,\n     words(o.i)=8 then do\n   trees=word(o.i,4)\n   blobs=word(o.i,6)\n  end\n  if word(o.i,3)='ENTRIES' & word(o.i,5)='VERIFIED' &,\n     words(o.i)=6 then do\n   entries=word(o.i,4)\n   verified=word(o.i,6)\n  end\n end\n if word(o.i,1)='@@MILESTONE@@' & word(o.i,2)='FORWARD' &,\n    word(o.i,3)='SCANS' & word(o.i,4)='2' &,\n    word(o.i,7)='SEEKS' & word(o.i,8)='0' &,\n    words(o.i)=8 then scans=scans+1\n if word(o.i,1)='@@MILESTONE@@' & word(o.i,2)='AUTHENTICATED' &,\n    word(o.i,3)='BLOBS' & words(o.i)=4 &,\n    word(o.i,4)=blobs then statok=statok+1\nend\nif pass\\=1 | found\\=1 | scans\\=1 | statok\\=1 |,\n   datatype(trees,'W')\\=1 | datatype(blobs,'W')\\=1 |,\n   datatype(entries,'W')\\=1 | datatype(verified,'W')\\=1 then do\n say '@@MILESTONE@@ FAST TREE CROSSCHECK FAIL'\n exit 8\nend\nif trees<1 | verified\\=trees+blobs | entries<blobs+trees-1 then do\n say '@@MILESTONE@@ FAST TREE COUNT FAIL'\n exit 8\nend\nsay '@@MILESTONE@@ VERIFIED FAST TREE TARGET GATE PASS' oid datafm\nexit 0\n"

def generate(name):
    if name in EXTRA_SPECS:
        milestone, module, comment = EXTRA_SPECS[name]
        text = comment + "\n" + EXTRA_TEMPLATE.replace("@@NAME@@", name).replace("@@MOD@@", module).replace("@@MILESTONE@@", milestone)
        assert all(len(line) <= 80 for line in text.splitlines())
        return text
    milestone, comment = SPECS[name]
    text = comment + "\n" + TEMPLATE.replace("@@NAME@@", name).replace("@@MILESTONE@@", milestone)
    assert all(len(line) <= 80 for line in text.splitlines())
    return text

def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: restore-ph-wrappers.py NAME.EXEC|ALL|CHECK")
    arg = sys.argv[1].upper()
    all_specs = dict(SPECS)
    all_specs.update(EXTRA_SPECS)
    if arg == "CHECK":
        for name in all_specs:
            target = ROOT / "src" / (name + ".EXEC")
            if target.exists():
                assert target.read_text() == generate(name), name
        print("PH WRAPPER GENERATION PARITY PASS")
        return
    if arg == "ALL":
        names = [name for name in sorted(all_specs)
                 if not (ROOT / "src" / (name + ".EXEC")).exists()]
    elif arg.endswith(".EXEC") and arg[:-5] in all_specs:
        names = [arg[:-5]]
    else:
        raise SystemExit("Unknown wrapper " + arg)
    targets = [ROOT / "src" / (name + ".EXEC") for name in names]
    if any(path.exists() for path in targets):
        raise SystemExit("Refusing overwrite of an existing EXEC")
    for name, path in zip(names, targets):
        path.write_text(generate(name))
        print("RESTORED " + path.name)

if __name__ == "__main__":
    main()
