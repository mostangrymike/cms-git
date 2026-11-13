#!/usr/bin/env python3
"""M273/M274: host source guards for GIT PULL and GIT CLONE.

No live remote or CMS target is contacted.  These checks pin the
usability and safety properties that the clone/pull path relies on:

* clone resolves the remote default branch instead of assuming "main";
* clone and no-argument pull honour a configurable bridge endpoint;
* repository state and fetch artifacts use G, with a post-fetch free-space
  check before importing a pack;
* failed clone setup removes the remote record so a retry is clean.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
GIT = (ROOT / "src" / "GIT.EXEC").read_text()

# Routing.
assert "if command='PULL' then do" in GIT
assert "if command='CLONE' then do" in GIT
assert "if command='PUSH' then do" in GIT

# --- INIT / initrefs: branch-aware unborn repository -------------------
assert "Usage: GIT INIT [object-filemode [branch]]" in GIT
assert "if initbranch='' then initbranch='main'" in GIT
assert "meta.4 = 'HEAD refs/heads/'||initbranch" in GIT
assert "call initrefs initbranch" in GIT
assert "initrefs:\n   parse arg ibranch" in GIT
assert "if ibranch='' then ibranch='main'\n   'STATE GITREF2 REPO G'" in GIT
assert "initial.2\\=('HEAD refs/heads/'||ibranch)" in GIT
assert "initial.2='HEAD refs/heads/'||ibranch" in GIT
assert "if objectfm \\= 'G' then do" in GIT
# The old hardcoded main-only initialisation must be gone.
assert "meta.4 = 'HEAD refs/heads/main'" not in GIT
assert "initial.2='HEAD refs/heads/main'" not in GIT

# --- CLONE: discover the advertised default branch ---------------------
clone = GIT.split("if command='CLONE' then do", 1)[1]
clone = clone.split("\nend\n", 1)[0]
assert "EXEC GITFETCH DISCOVER" in clone
assert "'HEAD'" in clone
assert "word(disco.ci,2)='DEFAULT'" in clone
assert "word(disco.ci,3)='BRANCH'" in clone
assert "clonebranch=substr(branchref,12)" in clone
assert "parsecloneurl:" in GIT
assert "call parsecloneurl cloneurl" in clone
assert "EXEC GIT INIT' clonefm clonebranch" in clone
assert "EXEC GIT PULL origin' clonebridge cloneport" in clone
assert "if clonefm='' then clonefm='G'" in GIT
assert "if clonefm\\='G' then do" in GIT
# No hardcoded bridge endpoint or main branch in the clone command.
assert "192.168.200.1 8443" not in clone
assert "GIT PULL origin 192.168.200.1" not in GIT
assert "call validbranch 'main'" not in clone

# Discovery must not depend on GITREMOT, which requires GITMETA.  The
# remote record is added only after INIT and is rolled back on failure.
assert "EXEC GIT REMOTE ADD origin" in clone
assert clone.find("EXEC GITFETCH DISCOVER") < clone.find("'EXEC GIT INIT'")
assert clone.find("'EXEC GIT REMOTE ADD origin'") > clone.find("'EXEC GIT INIT'")
assert "'ERASE GITMETA REPO G'\n      'ERASE GITREF2 REPO G'" in clone
assert "GIT CLONE: repository already initialized; use GIT PULL to resume" in clone
assert "GIT CLONE: default-branch discovery framing failed" in clone

# --- Configurable bridge ------------------------------------------------
assert "readbridge:" in GIT
# Missing metadata still uses plain STATE: CMS PIPE CMS STATE did not
# propagate RC 28 on the validated target, so absence must use STATE's rc.
assert "'STATE GITMETA REPO G'" in GIT
assert "'PIPE CMS STATE GITMETA REPO G'" not in GIT
assert "STATE GITBRIDG CONFIG G" in GIT
assert "bridgehost='192.168.200.1'" in GIT
assert "bridgeport='8443'" in GIT
assert "parse var bridgeline.1 btag bhost bport bextra" in GIT
# No-argument pull reads the configured endpoint.
noarg = GIT.split("/* No-arg pull:", 1)[1].split("else do", 1)[0]
assert "call readbridge" in noarg
assert "pullbridge=bridgehost" in noarg
assert "pullport=bridgeport" in noarg
assert "pullpack='PULLNX01'" in noarg
assert "pullindex='PULLIX01'" in noarg
assert "pullbridge='192.168.200.1'" not in noarg

# --- Pull object disk: G is required; space is checked after fetch ------
assert "repository must use its dedicated non-A object disk" not in GIT
assert "freespace:" in GIT
assert "call freespace objectfm" in GIT
assert "needblocks=(pullbytes % 4096) * 5 + 1024" in GIT
assert "required for this pull" in GIT

# Import and activation use the selected G project disk.
FIMP = (ROOT / "src" / "GITFIMP.EXEC").read_text()
FACT = (ROOT / "src" / "GITFACT.EXEC").read_text()
for src, name in ((FIMP, "GITFIMP"), (FACT, "GITFACT")):
    assert "verify(datafm,'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" in src
    assert "verify(datafm,'BCDEFGHIJKLMNOPQRSTUVWXYZ')" not in src
# Activation must check the installer module it actually invokes.
assert "module=word('GITPIDX GITPTRE M274L5 GITPCAT',i)" in FACT
assert "GITPLOAD'" not in FACT.split("do i=1 to 4")[1].split("end",1)[0]
assert "needblocks=(pbytes % 4096) * 5 + 1024" in FIMP
assert "has' avail 'free blocks;'" in FIMP
assert "datafm\\='G'" in FIMP

# The free-space check must run before import so a full disk cannot
# produce a partial stage.
pull = GIT.split("if command='PULL' then do", 1)[1]
before_import = pull.split("'EXEC GIT FETCH-IMPORT'", 1)[0]
assert "call freespace objectfm" in before_import

# CMS diagnostics captured by PIPE must not look like worktree changes.
assert "if left(statusout.si,3)='DMS' then iterate" in GIT

# The pull path must clear stale artifacts so a failed pull is retryable.
assert "erased stale" in GIT

# Identical duplicate HEAD records are tolerated; conflicting ones are not.
VREF = (ROOT / "src" / "GITVREF.EXEC").read_text()
assert "if headref='' then headref=word(rr.i,2)" in VREF
assert "else if headref\\=word(rr.i,2) then return 'ERROR'" in VREF
assert "if words(rr.i)\\=2 | headref\\='' then return 'ERROR'" not in VREF

# --- Unborn first pull: create branch, then materialize the worktree -----
UPD = (ROOT / "src" / "GITUPD.EXEC").read_text()
WT = (ROOT / "src" / "GITWT.EXEC").read_text()
assert "if createmode=0 & (slot=0 | localold\\=oldoid) then do" in UPD
assert "if slot=0 & oldoid=zeros then createmode=1" in UPD
assert "refname.refcount=branchref" in UPD
assert "EXEC GITWT CHECKOUT-TREE" in UPD
assert "say 'CREATED' branch newoid" in UPD
assert "if createmode=0 then do\n  drop ancestry." in UPD
# bindnative returns numeric 0/8; call sites must not compare with 'OK'.
assert "call bindnative\n if result\\='OK'" not in WT
assert WT.count("call bindnative\n if result\\=0") >= 5
# An unborn repository is header plus symbolic HEAD; the reader must accept it.
assert "rr.0<2 | rr.1\\='REF2 1'" in WT
# Preflight accepts a create only for the zero old-commit on CHECK-PULL.
assert "if foundref=0 & pullold=zeros & command='CHECK-PULL' then createmode=1" in WT
# Pull turns an empty local tip into the zero old-commit.
assert "if pullold='' then pullold=zeros" in GIT
assert "if pullold\\=zeros then do" in GIT

# --- GITFACT: post-install closure verification -----------------------
# The loose store must be complete for full and incremental activations.
assert FACT.count("call verify_closure treeoid objectfm") == 1
assert "call verify_closure treeoid objectfm\nif result\\='OK' then exit 8" in FACT
assert "if incremental then do" not in FACT
# Verify the recorded metadata, not just tree structure.
assert "if word(tobj.ti,2)\\=current then oidmatch=0" in FACT
assert "if oidcount\\=1 | oidmatch=0 then do" in FACT
assert "if otype\\='COMMIT' & otype\\='TREE' & otype\\='BLOB'" in FACT
assert "if sizecount\\=1 | datatype(osize,'W')\\=1 | osize<0 then do" in FACT
assert "if length(thex)\\=osize*2 then do" in FACT
# The uppercase TYPE must be compared with uppercase TREE.
assert "if otype\\='TREE' then iterate" in FACT
assert "otype\\='tree'" not in FACT
assert "length(thex)%2" not in FACT
# Every non-gitlink child is part of the closure.
assert "if modehex\\='3136303030' then do" in FACT
assert "modehex='3430303030'" not in FACT
assert "if length(modehex)=0 |" in FACT
assert "installed closure incomplete" in FACT

# --- Arbitrary-path worktree: PATH is the identity, file ID is derived -----
# The map holds the full hex path, so nested, long and multi-dot names no
# longer need a flat one-dot CMS envelope.
assert "workpathhexmax=1024" in WT
assert "workdepthmax=32" in WT
assert "workfilemax=50" in WT
assert "treescanmax=4096" in WT
# The commit tree scan is wider than the 50-file mapped-worktree cap.
assert "if ccount>treescanmax then do" in WT
assert "treefiles>workfilemax" in WT
assert "length(pathhex)>60" not in WT
assert WT.count("length(pathhex)>workpathhexmax") >= 5
assert "mapcount<0 | mapcount>workfilemax" in WT
# Recursive checkout and pull share one full-tree collector.
assert "call collecttree treeroot" in WT
assert "call collecttree oldroot" in WT
assert "call collecttree pullroot" in WT
# The recursive collector reads all entries, so an empty target is not MISSING.
assert "call readtree nodeoid,''" in WT
assert "if target='' then return 'OK'" in WT
# Adds are only paths new since the old commit, so partial maps stay partial.
assert "call pathindex 'OLD',oldcount,newpath.ni" in WT
assert "if mode='40000' then do" in WT
assert "else if mode='100644' | mode='100755' then do" in WT
# A natural 8.8 name is preferred; otherwise a stable WT###### GITF name.
assert "call allocatename cpath.ti" in WT
assert "call naturalname aah\n if result='ERROR' then return 'ERROR'" in WT
assert "call naturalname aah\n if result\\='ERROR'" not in WT
assert "candidate='WT'||right(synnext,6,'0')" in WT
assert "allocft='GITF'" in WT
assert "pendingfn.fai=afn & pendingft.fai=aft" in WT
# The map is rebuilt with the original hex PATH, not a decoded name.
assert "mappath.pi=cpath.ti" in WT
assert "mappath.pi=ename.ti" not in WT
# Pull is a three-way keep/update/add/remove with a text preflight.
assert "'PULL PREFLIGHT SAFE ADDED' pulladdcount 'REMOVED' pullremcount" in WT
assert "'CHANGED' pullupdcount 'MAPPED' pullkeepcount" in WT
assert "pullkeepcount=mapcount-pullremcount-pullupdcount" in WT
assert "say 'GITWT: pull path additions or removals are not supported yet'" not in WT
# Apply reserves every new name before mutating, verifies OIDs, then rolls back.
assert "addwritten=0\n pendingcount=0\n synnext=1" in WT
assert "call workoid addfn.ak,addft.ak,'A',pulladdfin.ni,0" in WT
assert "if result\\=newoid.ni then do" in WT
assert "call eraseadditions" in WT
assert "drop restorefn. restoreft. restorefm." in WT
# Rollback falls back to the mapped name when no explicit name is supplied.
assert "if restorefn.restoreback='' then do" in WT
assert "if restorefn.restoreback\\='' then do" not in WT
assert "restorefn.restorearg=''" in WT
# An unset REXX compound variable would otherwise be written as its own name.
assert "drop updnew. updlf.\n do pi=1 to mapcount" in WT
assert "\n  updnew.pi=''\n  updlf.pi=''" in WT
# Removal flags are set by preflight and must survive the map rebuild.
assert "drop updnew. updlf. removepi." not in WT
assert "drop updpi. updo. addix. rempi. removepi." in WT
assert "if removepi.pi=1 then iterate" in WT
assert "if length(mapbase.si)\\=40" in WT
assert "GITWT: invalid worktree map entry" in WT
# Map writes recreate the file so a longer PATH raises the LRECL, and a
# failed rewrite puts the prior map back.
assert "EXECIO * DISKR GITWORK REPO G 1 (STEM SMBAK. FINIS" in WT
assert "EXECIO' smbak.0 'DISKW GITWORK REPO G" in WT
# Every line stays within the CMS 80-column source convention.
for number, line in enumerate(WT.splitlines(), 1):
    if len(line) > 80:
        raise AssertionError(f"GITWT.EXEC line {number} exceeds 80 columns")

print("M273/M274 clone/pull guards PASS")
