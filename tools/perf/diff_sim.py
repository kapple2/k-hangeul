"""Draw the same text with two driver builds in py65 and compare every hi-res byte.

usage: diff_sim.py <snapshot> <baseline dir> <new dir> [quick|full]
Each dir holds K-HANGEUL.bin and labels.json.
Cases: all syllables at all 23 column positions (full) or a sample (quick),
ASCII 32..126 at all 46 columns, inverse video, the cursor, scroll.
"""
from __future__ import annotations

import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from sim6502 import Sim  # noqa: E402
import pack_story as P  # noqa: E402


def make(snap: str, d: str) -> Sim:
    s = Sim(Path(snap), Path(d) / "K-HANGEUL.bin", Path(d) / "labels.json")
    s.mem[0x24] = 0
    s.mem[0x25] = 0
    return s


def put(s: Sim, data: bytes) -> int:
    return sum(s.cout(b | 0x80) for b in data)


def syllable_pages(step: int):
    syl = [chr(0xAC00 + i) for i in range(0, 11172, step)]
    per = 368
    for n in range(0, len(syl), per):
        chunk = syl[n:n + per]
        chunk += ["가"] * (per - len(chunk))
        yield P.encode_paragraph("".join(chunk)).rstrip(b"\x00")


def odd_pages(step: int):
    syl = [chr(0xAC00 + i) for i in range(1, 11172, step)]
    per = 352
    for n in range(0, len(syl), per):
        chunk = syl[n:n + per]
        chunk += ["가"] * (per - len(chunk))
        text = "".join("A" + "".join(chunk[r * 22:(r + 1) * 22]) + "B" for r in range(16))
        yield P.encode_paragraph(text).rstrip(b"\x00")


def ascii_page() -> bytes:
    rows = ["".join(chr(32 + (r * 7 + c) % 95) for c in range(46)) for r in range(15)]
    return P.encode_paragraph("\n".join(rows)).rstrip(b"\x00")


def run_case(snap, d, data: bytes, prelude=None) -> tuple[bytes, int]:
    s = make(snap, d)
    if prelude:
        prelude(s)
    c = put(s, data)
    return s.hgr(), c


def main() -> int:
    snap, base, new = sys.argv[1:4]
    full = len(sys.argv) > 4 and sys.argv[4] == "full"
    step = 1 if full else 37
    cases = []
    cases += [(f"syll{n}", p, None) for n, p in enumerate(syllable_pages(step))]
    cases += [(f"odd{n}", p, None) for n, p in enumerate(odd_pages(step))]
    cases.append(("ascii", ascii_page(), None))

    def inverse(s):
        s.mem[0x32] = 0x3F

    def flash(s):
        s.mem[0x32] = 0x7F

    h = P.encode_paragraph("한글").rstrip(b"\x00")
    cases.append(("inverse", b"ABC " + h + b" xyz", inverse))
    cases.append(("flash", b"ABC " + h + b" xyz", flash))
    bad = 0
    tot = [0, 0]

    def cursor_case(d: str) -> bytes:
        s = make(snap, d)
        put(s, ascii_page())
        put(s, P.encode_paragraph("한글가나다라마바사").rstrip(b"\x00"))
        for col, row in ((0, 0), (1, 3), (5, 7), (22, 15), (44, 14), (45, 9), (3, 15)):
            s.mem[0x24], s.mem[0x25] = col, row
            ptr = 0x1980 + row * 46
            s.mem[0x28], s.mem[0x29] = ptr & 0xFF, ptr >> 8
            s.call(s.labels["CURSOR"])
        return s.hgr()

    def scroll_case(d: str, label: str) -> bytes:
        s = make(snap, d)
        put(s, ascii_page())
        s.mem[0x22], s.mem[0x23] = 0, 16
        s.call(s.labels[label])
        return s.hgr()

    for label in ("HSDN", "HSUP"):
        if scroll_case(base, label) != scroll_case(new, label):
            print("DIFF", label)
            bad += 1

    if cursor_case(base) != cursor_case(new):
        print("DIFF cursor")
        bad += 1
    for name, data, pre in cases:
        a, ca = run_case(snap, base, data, pre)
        b, cb = run_case(snap, new, data, pre)
        tot[0] += ca
        tot[1] += cb
        if a != b:
            diff = [i for i in range(0x2000) if a[i] != b[i]]
            print(f"DIFF {name}: {len(diff)} bytes, first at ${0x2000 + diff[0]:04X}")
            bad += 1
    from sim6502 import RoLC
    print(f"ignored writes into the language card: {RoLC.ignored}")
    print(f"{len(cases)} cases, {bad} differ; cycles baseline {tot[0]:,}  new {tot[1]:,}  ({tot[0] / tot[1]:.2f}x)")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
