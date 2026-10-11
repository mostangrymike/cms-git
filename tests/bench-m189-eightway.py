#!/usr/bin/env python3
"""M189 observational direct-skip native-stage performance comparison (host only)."""
from pathlib import Path
import hashlib
import shutil
import statistics
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
SOURCES = {
    "M181": ("GITPHXM.C", "M181 HEX LOOKUP VALIDATOR PASS"),
    "M182": ("GITPH2M.C", "M182 HEX PAIR VALIDATOR PASS"),
    "M183": ("GITPH3M.C", "M183 UNROLLED HEX VALIDATOR PASS"),
    "M185": ("GITPH5M.C", "M185 DIRECT SKIP VALIDATOR PASS"),
    "M188": ("GITPH8M.C", "M188 FAST EOL VALIDATOR PASS"),
    "M189": ("GITPH9M.C", "M189 EIGHTWAY HEX VALIDATOR PASS"),
}
DATA = bytes(range(256)) * 60000
SMALL = b"Verified native CMS stage benchmark"
RUNS = 7


def oid(typ, body):
    head = (typ + " " + str(len(body))).encode() + b"\0"
    return hashlib.sha1(head + body).hexdigest().upper()


def staged(objs):
    records = []
    for num, (typ, typecode, body) in enumerate(objs, 1):
        records.append(
            "OBJ %d %d %d %s" %
            (num, typecode, len(body), oid(typ, body)))
        digits = body.hex().upper()
        if not digits:
            records.append("")
        else:
            records.extend(digits[i:i + 64]
                           for i in range(0, len(digits), 64))
    return "\n".join(records) + "\n", len(records)


def build(path, target):
    args = ["gcc", "-x", "c", "-std=c89", "-Wall", "-Wextra", "-Werror",
            str(path), "-o", str(target)]
    subprocess.run(args, check=True)


with tempfile.TemporaryDirectory(prefix="m184-") as td:
    work = Path(td)
    out = {}
    for label, (source, _) in SOURCES.items():
        out[label] = work / label.lower()
        build(ROOT / "src" / source, out[label])
    index = work / "native-index"
    build(ROOT / "src" / "GITPIDX.C", index)

    link = (b"100644 note.txt\0" +
            bytes.fromhex(oid("blob", SMALL)))
    root_oid = oid("tree", link)
    objects = [
        ("blob", 3, DATA),     # Deliberately unreachable large blob.
        ("blob", 3, SMALL),    # Reachable; must be SHA1 authenticated.
        ("tree", 2, link),
    ]
    text, records = staged(objects)
    stage = work / "dd:STGIN"
    idxin = work / "dd:IDXIN"
    stage.write_text(text)
    made = subprocess.run([str(index), "BUILD"], cwd=work,
                          capture_output=True, text=True)
    assert made.returncode == 0, made.stdout + made.stderr
    shutil.copy(work / "dd:IDXOUT", idxin)
    before = (hashlib.sha256(stage.read_bytes()).hexdigest(),
              hashlib.sha256(idxin.read_bytes()).hexdigest())

    elapsed = {label: [] for label in SOURCES}
    labels = tuple(SOURCES.keys())
    # One warmup, then seven rotating rounds to reduce noise.
    for iteration in range(RUNS + 1):
        order = labels[iteration % len(labels):]
        order += labels[:iteration % len(labels)]
        for label in order:
            begin = time.perf_counter()
            proc = subprocess.run(
                [str(out[label]), "WALK", root_oid],
                cwd=work, capture_output=True, text=True)
            duration = time.perf_counter() - begin
            assert proc.returncode == 0, (
                label, proc.stdout, proc.stderr)
            for line in (
                "TREE CLOSURE ROOT " + root_oid,
                "TREE CLOSURE TREES 1 BLOBS 1 GITLINKS 0",
                "TREE CLOSURE ENTRIES 1 VERIFIED 2",
                "TREE CLOSURE INDEX TOTAL 3 UNIQUE 3",
                "AUTHENTICATED BLOBS 1",
                "STAGE LINES PASS1 %d PASS2 %d" %
                    (records, records),
                "FORWARD SCANS 2 RECORDS 6 SEEKS 0",
                SOURCES[label][1],
                label + " TREE CLOSURE PASS",
            ):
                assert line in proc.stdout, (label, line, proc.stdout)
            if iteration:
                elapsed[label].append(duration)

    after = (hashlib.sha256(stage.read_bytes()).hexdigest(),
             hashlib.sha256(idxin.read_bytes()).hexdigest())
    assert before == after, "Native host scan mutated input"
    print("M189 FIXTURE: %d bytes unrelated blob, %d stage lines" %
          (len(DATA), records))
    print("M189 REQUIRED: identical authenticated closure, no G writes")
    for label in labels:
        measures = elapsed[label]
        print("%s HOST MEDIAN %.4fs MIN %.4fs MAX %.4fs" %
              (label, statistics.median(measures),
               min(measures), max(measures)))
    print("M189 HOST TIMINGS ARE OBSERVATIONAL ONLY; NOT z/VM DATA")
    print("M189 PARITY AND READ-ONLY BENCHMARK PASS")
