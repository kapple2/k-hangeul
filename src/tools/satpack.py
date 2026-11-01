"""Fold the Saturn patches into K-HANGEUL.bin.

usage: satpack.py <plain build dir> <saturn build dir>
  plain build dir   built with SATURN=0 SATLOAD=1: K-HANGEUL.bin, driver.map
  saturn build dir  built with SATURN=1 SATLOAD=1: K-HANGEUL.bin, driver.map, driver.lbl

The two builds have the same layout; they differ only where the Saturn arrangement differs. This tool compares the driver
image (LCIMG) and the banner image (BANNER) byte by byte and writes the differences as two patch lists into the room at
the end of the plain file (segment SATDATA). The loader applies them when it finds a Saturn card (see driver.s,
SatFinish). Record: offset (2 bytes, low first), length (1-255), the bytes. A list ends with offset $FFFF. After the two
lists comes the offset of the bank digit in the banner text (2 bytes).

The tool checks its own work: it applies the lists to the plain images and compares with the Saturn images. It then
cuts the file after the last used byte (the rest of SATDATA is zeros nobody reads).
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

GAP = 4          # runs closer than this are merged


def segments(mapfile: Path) -> dict[str, tuple[int, int, int]]:
    """segment name -> (start address, end address, size) from the ld65 map"""
    seg = {}
    text = mapfile.read_text()
    block = text.split("Segment list:")[1].split("Exports list")[0]
    for line in block.splitlines():
        m = re.match(r"(\w+)\s+([0-9A-F]{6})\s+([0-9A-F]{6})\s+([0-9A-F]{6})", line)
        if m:
            seg[m.group(1)] = (int(m.group(2), 16), int(m.group(3), 16), int(m.group(4), 16))
    return seg


def load_offsets(mapfile: Path) -> dict[str, int]:
    """file offset of each segment: the order in the file is the order of the linker's load addresses"""
    text = mapfile.read_text()
    exports = {m.group(1): int(m.group(2), 16) for m in re.finditer(r"__(\w+)_LOAD__\s+([0-9A-F]{6})", text)}
    return exports


def diff_runs(a: bytes, b: bytes) -> list[tuple[int, bytes]]:
    assert len(a) == len(b), (len(a), len(b))
    diffs = [i for i in range(len(a)) if a[i] != b[i]]
    runs: list[list[int]] = []
    for i in diffs:
        if runs and i - runs[-1][1] <= GAP:
            runs[-1][1] = i + 1
        else:
            runs.append([i, i + 1])
    out = []
    for s, e in runs:
        while s < e:
            n = min(255, e - s)
            out.append((s, b[s:s + n]))
            s += n
    return out


def encode(runs: list[tuple[int, bytes]]) -> bytes:
    out = bytearray()
    for off, data in runs:
        out += bytes([off & 0xFF, off >> 8, len(data)]) + data
    out += b"\xFF\xFF"
    return bytes(out)


def apply(img: bytes, lst: bytes) -> bytes:
    img = bytearray(img)
    i = 0
    while True:
        off = lst[i] | (lst[i + 1] << 8)
        if off == 0xFFFF:
            return bytes(img)
        n = lst[i + 2]
        img[off:off + n] = lst[i + 3:i + 3 + n]
        i += 3 + n


def main() -> None:
    plain_dir, sat_dir = Path(sys.argv[1]), Path(sys.argv[2])
    pb = (plain_dir / "K-HANGEUL.bin").read_bytes()
    sb = (sat_dir / "K-HANGEUL.bin").read_bytes()
    pm, sm = segments(plain_dir / "driver.map"), segments(sat_dir / "driver.map")
    po = load_offsets(plain_dir / "driver.map")
    for name in ("LCIMG", "BANNER", "SATDATA"):
        assert pm[name][2] == sm[name][2], f"{name} has a different size in the two builds"
    loader_size = pm["LOADER"][2]
    base = 0x0F94
    def file_range(seg: str) -> slice:
        start = po[seg] - base
        return slice(start, start + pm[seg][2])
    l_img, l_ban, l_dat = file_range("LCIMG"), file_range("BANNER"), file_range("SATDATA")
    assert len(pb) == len(sb) and len(pb) >= l_dat.stop - 0, (len(pb), len(sb))
    # the loader code is the same in both builds (SATLOAD = 1); check it
    so = load_offsets(sat_dir / "driver.map")
    assert so == po, "the segments are not at the same file offsets in the two builds"   # the loaders may differ in data (the HAN entry), not in size
    pimg, simg = pb[l_img], sb[l_img]
    pban, sban = pb[l_ban], sb[l_ban]
    r_img, r_ban = diff_runs(pimg, simg), diff_runs(pban, sban)
    digit = None
    lbl = (sat_dir / "driver.lbl").read_text()
    m = re.search(r"al ([0-9A-F]{6}) \.SatBannerDigit", lbl)
    if m:
        digit = int(m.group(1), 16) - sm["BANNER"][0]       # the label is in the Saturn build, whose banner runs at $6000
    assert digit is not None and 0 <= digit < pm["BANNER"][2], "SatBannerDigit is missing from the label file or outside the banner"
    data = encode(r_img) + encode(r_ban) + bytes([digit & 0xFF, digit >> 8])
    room = pm["SATDATA"][2]
    if len(data) > room:
        raise SystemExit(f"the patch lists are {len(data)} bytes; SATDATA has room for {room}. Raise SATDATASIZE in defs.inc.")
    # check
    lst1 = data
    got_img = apply(pimg, lst1)
    n1 = len(encode(r_img))
    got_ban = apply(pban, lst1[n1:])
    # the bank digit is a placeholder in the Saturn banner: it is replaced at load time
    assert got_img == simg, "image patch check failed"
    assert got_ban == sban, "banner patch check failed"
    out = bytearray(pb)
    out[l_dat.start:l_dat.start + len(data)] = data
    out = out[:l_dat.start + len(data)]
    (plain_dir / "K-HANGEUL.bin").write_bytes(bytes(out))
    print(f"satpack: driver patches {len(r_img)} records, {sum(len(d) for _, d in r_img)} bytes changed; "
          f"banner patches {len(r_ban)} records, {sum(len(d) for _, d in r_ban)} bytes; lists {len(data)} of {room} bytes; "
          f"file {len(out)} bytes")


if __name__ == "__main__":
    main()
