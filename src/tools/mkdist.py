"""Assemble DIST, the folder for ordinary users: the finished disk image and the user manual (MANUAL.md, MANUAL_en.md) only.

usage: mkdist.py <project root> [acx.exe] [output folder, default DIST]
Run by the top-level Makefile after the three programs are built. DIST is made again each time.

The disk holds only what a user needs: DOS 3.3 from disk/dos33blank.dsk (a blank DOS 3.3 disk; every file on that
disk is deleted first), then HELLO, K-HANGEUL, FONT12, FONT6X10, TYPE, TYPEC, STYPE, STYPEC, DEMO, the text samples (SAMPLE1, NALGAE1-16),
the BASIC readers (MIXED, STORY) and the &TYPE and &STYPE examples (SAMPLEB, TYPEDEMO, STORYT, STYPEDEMO, STORYS). MANUAL.md at the
docs/ explains them and is copied to DIST. The program files stay in src/*/build and are not copied.
"""
from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(sys.argv[1]).resolve()
ASM = ROOT / "src"
ACX = sys.argv[2] if len(sys.argv) > 2 else "C:/bin/acx.exe"
DIST = Path(sys.argv[3]).resolve() if len(sys.argv) > 3 else ROOT / "DIST"
DSK = DIST / "K-HANGEUL.DSK"

BINARIES = {
    "K-HANGEUL.bin": ASM / "driver" / "build" / "K-HANGEUL.bin",
    "FONT12.bin": ASM / "driver" / "build" / "FONT12.bin",
    "FONT6X10.bin": ASM / "driver" / "build" / "FONT6X10.bin",
    "TYPE.bin": ASM / "type" / "build" / "TYPE.bin",
    "TYPEC.bin": ASM / "typec" / "build" / "TYPEC.bin",
    "STYPE.bin": ASM / "stype" / "build" / "STYPE.bin",
    "STYPEC.bin": ASM / "stypec" / "build" / "STYPEC.bin",
}


def acx(*args: str, data: bytes | None = None, check: bool = True) -> subprocess.CompletedProcess:
    r = subprocess.run([ACX, *args], input=data, capture_output=True)
    if check and r.returncode != 0:
        raise SystemExit(f"acx {' '.join(args)} failed: {r.stderr.decode(errors='replace')}")
    return r


def catalog_names() -> list[str]:
    out = acx("-l", str(DSK)).stdout.decode(errors="replace").splitlines()
    return [line.split(None, 2)[2] for line in out[1:] if len(line.split(None, 2)) == 3]


def put(name: str, kind: str, data: bytes, addr: str | None = None) -> None:
    if kind == "bin":
        acx("-p", str(DSK), name, "bin", addr, data=data)
    elif kind == "txt":
        # a DOS text file: CR becomes LF for acx, which writes it with the high bit set and CR ($8D)
        acx("-pt", str(DSK), name, data=data.rstrip(bytes([0])).replace(bytes([13]), bytes([10])))
    else:
        acx("-bas", str(DSK), name, data=data)


def make_nbyte_samples() -> None:
    """NALGAE1-16 on the disk are N-byte files made from the UTF-8 copies in samples/utf8txt/ (nbyte.py)."""
    sys.path.insert(0, str(ASM / "tools"))
    import nbyte
    for n in range(1, 17):
        text = (ASM / "samples" / "utf8txt" / f"NALGAE{n}.txt").read_text(encoding="utf-8")
        (ASM / "samples" / f"NALGAE{n}.txt").write_bytes(nbyte.encode(text))
    print("NALGAE1-16: N-byte files written from samples/utf8txt/")


def main() -> None:
    make_nbyte_samples()
    for name, path in BINARIES.items():
        if not path.exists():
            raise SystemExit(f"missing {path}: build the programs first")
    DIST.mkdir(parents=True, exist_ok=True)
    for sub in ("docs", "bin"):                  # folders and files an older build put in DIST; DIST holds only the disk and the manuals now
        shutil.rmtree(DIST / sub, ignore_errors=True)
    (DIST / "README.md").unlink(missing_ok=True)
    shutil.copyfile(ROOT / "docs" / "MANUAL.md", DIST / "MANUAL.md")
    shutil.copyfile(ROOT / "docs" / "MANUAL_en.md", DIST / "MANUAL_en.md")
    try:
        shutil.copyfile(ROOT / "disk" / "dos33blank.dsk", DSK)
    except PermissionError:
        raise SystemExit(f"cannot write {DSK}: another program (an emulator?) has it open. Close it and run again.")
    for name in catalog_names():                 # keep DOS, drop every file
        acx("-d", str(DSK), name)
    drv = ASM / "driver"
    put("HELLO", "bas", (drv / "hello.bas").read_bytes())
    put("K-HANGEUL", "bin", BINARIES["K-HANGEUL.bin"].read_bytes(), "0x0F94")
    put("FONT12", "bin", BINARIES["FONT12.bin"].read_bytes(), "0x6000")
    put("FONT6X10", "bin", BINARIES["FONT6X10.bin"].read_bytes(), "0x7200")
    put("TYPE", "bin", BINARIES["TYPE.bin"].read_bytes(), "0x8E00")
    put("TYPEC", "bin", BINARIES["TYPEC.bin"].read_bytes(), "0x8E00")
    put("STYPE", "bin", BINARIES["STYPE.bin"].read_bytes(), "0x8A00")
    put("STYPEC", "bin", BINARIES["STYPEC.bin"].read_bytes(), "0x8A00")
    put("DEMO", "bas", (drv / "demo.bas").read_bytes())
    put("SAMPLE1", "txt", (ASM / "type" / "sampleb.bin").read_bytes())
    smp = ASM / "samples"
    put("MIXED", "bas", (smp / "mixed.bas").read_bytes())
    for n in range(1, 17):                       # the story, as keystroke text files (byte for byte as the driver reads them)
        raw = (smp / f"NALGAE{n}.txt").read_bytes()
        put(f"NALGAE{n}", "txt", raw.replace(bytes([0x8D]), bytes([10])))
    put("STORY", "bas", (smp / "story.bas").read_bytes())
    put("SAMPLEB", "bin", (ASM / "type" / "sampleb.bin").read_bytes(), "0x8000")
    put("TYPEDEMO", "bas", (ASM / "type" / "typedemo.bas").read_bytes())
    put("STORYT", "bas", (ASM / "type" / "storyt.bas").read_bytes())
    put("STYPEDEMO", "bas", (ASM / "stype" / "stypedemo.bas").read_bytes())
    put("STORYS", "bas", (ASM / "stype" / "storys.bas").read_bytes())

    r = subprocess.run([ACX, "-ll", str(DSK)], capture_output=True, text=True)
    print(r.stdout)
    print(f"DIST ready: {DIST}")


if __name__ == "__main__":
    main()
