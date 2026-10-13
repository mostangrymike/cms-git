#!/usr/bin/env python3
"""Static fail-closed guards for optional destructive CMS A cleanup."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
src = (root / "src" / "ACLEAN.EXEC").read_text()
expected_listings = set("""
CCTEST1 GITCABI GITCINF GITCORE GITCPARS GITCPROB GITC2
GITCAPI GITNCALL GITNDRV GITNHEX GITSEL GITSTRM GIT12Q
HELLO M12ABEG M12BOPN M12TLS2 M12TLS3 M12TLS4
""".split())
expected_experiments = set("""
CCTEST1 HELLO GITCABI GITCINF GITCPARS GITCPROB
GITC2 GIT12Q M12ABEG M12BOPN M12TLS2 M12TLS3 M12TLS4
""".split())
historic = src.split("if batch=\'RECENTGEN\' then do",1)[0]
declarations = re.findall(r"f\.n='([A-Z0-9]+) (LISTING|MODULE|TEXT)'",historic)
assert len(declarations) == 20 + 26
expected_oldtests = set("""
M9JSTRM M9JZLIB M9NSTRM M9O4096 M9PCHAIN M9PCONS M9PCTX
M10AFEED M10BFRAG M10CRESP M10DREAL M10ESTRS
M11ATCP M11BRAW M11CHTTP M11DGIT M11PROBE
M12GDISC M12HADV M12ICHNK M12JPOST M12KPACK M12PRXY
M13NTEST M13POUT M13PREP M13PSTG M13SFAIL M13WALK
""".split())
oldtests = re.findall(r"f\.n='([A-Z0-9]+) EXEC'",src)
assert len(oldtests) == len(expected_oldtests) == 29
assert set(oldtests) == expected_oldtests
archives = {}
for path in sorted((root / "archive").glob("*_EXEC.json")):
    data = json.loads(path.read_text())
    assert data["format"] == "cms-exec-archive-v1"
    for filename, source in data["files"].items():
        assert filename not in archives,filename
        assert filename.endswith(".EXEC") and 1 <= len(filename[:-5]) <= 8
        assert isinstance(source,str) and source
        archives[filename] = source
for name in oldtests:
    filename = name + ".EXEC"
    original = root / "src" / filename
    assert original.is_file() or filename in archives,name
    if original.is_file() and filename in archives:
        assert original.read_text() == archives[filename],name
assert "M13AAREF" not in oldtests and "M13ABREF" not in oldtests
assert "(batch\\='LISTINGS' & batch\\='EXPERIMENTS' &," in src
assert "batch\\='OLDTESTS'" in src

recent_section = src.split("if batch='RECENTGEN' then do",1)[1]
recent_section = recent_section.split("\nend\n",1)[0]
recent_files = re.findall(
    r"f\.n='([A-Z0-9]+) (ASSEMBLE|TEXT|LISTING)'",
    recent_section)
assert len(recent_files) == len(set(recent_files)) == 20
expected_recent_c = set("""
GITRP6M GITVO7M GITP21M GITP24M GITP25M GITP26M
""".split())
assert set(recent_files) == (
    {(n,t) for n in expected_recent_c
     for t in ("ASSEMBLE","TEXT","LISTING")} |
    {("GITBX9","TEXT"),("GITBX9","LISTING")}
)
for n in expected_recent_c:
    assert (root / "src" / (n+".C")).exists(),n
assert (root / "src/GITBX9.ASSEMBLE").exists()
assert "batch\\='RECENTGEN'" in src
assert "if fn='GITBX9' then srcft='ASSEMBLE'" in src
assert "else srcft='C'" in src
assert "'STATE' fn srcft 'A'" in src
assert "'STATE' fn 'MODULE A'" in src
assert "ACLEAN SOURCE NOT VERIFIED" in src
assert "ACLEAN MODULE NOT VERIFIED" in src
assert not any(t in {"EXEC","MODULE","C","PACK","STAGE",
                      "INDEX","SEEK","GEN","PTR","DATA"}
               for n,t in recent_files)

# New named manifests: every target must be an exact known file.
pack_section = src.split("if batch='PACKGEN' then do",1)[1]
pack_section = pack_section.split("\nend\n",1)[0]
pack_items = re.findall(
    r"f\.n='([A-Z0-9]+) (ASSEMBLE|TEXT|LISTING)'",
    pack_section)
expected_pack_names = set("""GITPCENS GITPCHK GITPIMP GITPIDX GITPCAT GITPTRE GITPFST GITPPRF GITPONE GITPHX GITPHXM GITPH5M GITPH8M GITPSKM GITPRBM GITRCNM""".split())
assert len(pack_items) == len(set(pack_items)) == 48
assert set(pack_items) == {
    (n,t) for n in expected_pack_names
    for t in ("ASSEMBLE","TEXT","LISTING")
}
for name in expected_pack_names:
    assert (root / "src" / (name+".C")).is_file(),name
assert not any(n in expected_pack_names for n,t in recent_files)
assert "batch\\='PACKGEN'" in src
assert "batch='RECENTGEN' | batch='PACKGEN'" in src
net_section = src.split("if batch='NETTRACE' then do",1)[1]
net_section = net_section.split("\nend\n",1)[0]
net_items = re.findall(
    r"f\.n='([A-Z0-9]+) (DATA|TCPIP)'",
    net_section)
expected_net = {(n,"DATA") for n in "SSLDBG SSLDB2 SSLDB3 SSLDB4 SSLDB5 SSL1LOG SSL3TRC TCPTRACE TCPTRC2 TCPTRC3".split()}
expected_net.add(("M12TRACE","TCPIP"))
assert len(net_items) == len(set(net_items)) == 11
assert set(net_items) == expected_net
assert not any(n.startswith("SSLPOOL") for n,t in net_items)
assert not any(n in ("SSLTEST","SSLTEST2","TLSQTEST") for n,t in net_items)
assert not any(t in ("MODULE","EXEC","ASSEMBLE","TEXT","LISTING")
               for n,t in net_items)
assert "batch\\='NETTRACE'" in src
assert "if batch='RECENTGEN' | batch='PACKGEN' then do" in src
assert "'STATE' fn srcft 'A'" in src
assert "'STATE' fn 'MODULE A'" in src
assert "'ERASE' fn ft 'A'" in src
# None of the new build cleanup entries touches data or active code.
assert not any(t in ("C","EXEC","MODULE","PACK","STAGE","INDEX",
                     "SEEK","GEN","PTR","REPO","DATA")
               for n,t in pack_items)
assert not set(pack_items).intersection(set(recent_files))

expected_builddeck = set("""
GITCABI GITCINF GITCPARS GITCPROB GITC2
GITREC GITCIDX GITCWALK GITSEL
""".split())
builddeck = re.findall(r"f\.n='([A-Z0-9]+) ASSEMBLE'",historic)
assert len(builddeck) == len(expected_builddeck) == 9
assert set(builddeck) == expected_builddeck
assert "batch\='BUILDDECK'" in src
for name in builddeck:
    assert (root / "src" / (name + ".C")).is_file(),name
for protected in ("M12ATLS","M12TLS2","M12TLS3","M12TLS4",
                  "GITCAPI","GITINFA","GITNCALL","GITNDRV",
                  "GITNHEX","GITCORE","GITSTRM"):
    assert protected not in builddeck
assert len(set(declarations)) == len(declarations)
assert {n for n,t in declarations if t == "LISTING"} == expected_listings
assert {n for n,t in declarations if t == "MODULE"} == expected_experiments
assert {n for n,t in declarations if t == "TEXT"} == expected_experiments
assert all(len(n) <= 8 for n,t in declarations)
assert "parse upper arg verb batch extra" in src
assert "(verb\\='PLAN' & verb\\='APPLY')" in src
assert "if batch='EXPERIMENTS' then do" in src
assert "'STATE' fn ft 'A'" in src
assert "if statecode=28 then iterate" in src
assert "if statecode\\=0 then do" in src
assert "if verb='APPLY' then do" in src
assert "'ERASE' fn ft 'A'" in src
assert "if rc\\=0 then do" in src
assert "QUERY DISK A" in src
assert not re.search(r"f\.n='(?:GITFIX|M15NEW|M171NET|GITPBUF)",src)
assert not any(t in ("ASSEMBLE","C","EXEC","PACK","STAGE","INDEX",
                     "SEEK","GEN","PTR","DATA","REPO") for n,t in declarations)
for lineno,line in enumerate(src.splitlines(),1):
    assert len(line) <= 80,(lineno,len(line))
print("ACLEAN A-DISK WHITELIST SAFETY GATE PASSED")
