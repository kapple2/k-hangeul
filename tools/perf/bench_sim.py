"""Cycle counts for the driver draw paths, measured in py65.

usage: bench_sim.py <snapshot.bin> <K-HANGEUL.bin> <labels.json>
Prints cycles per ASCII character, per Hangul syllable, and per scroll.
"""
from __future__ import annotations

import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from sim6502 import Sim  # noqa: E402
import pack_story as P  # noqa: E402

ASCII_ROW = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrst"


def hangul_row(seed: int) -> bytes:
    syl = "".join(chr(0xAC00 + (seed * 523 + i * 97) % 11172) for i in range(23))
    return P.encode_paragraph(syl).rstrip(b"\x00")


def fresh(snap, drv, lab):
    s = Sim(Path(snap), Path(drv), Path(lab))
    s.mem[0x24] = 0
    s.mem[0x25] = 7
    return s


def per_row(s: Sim, row: list[int]) -> int:
    return sum(s.cout(b | 0x80) for b in row)


def main() -> None:
    snap, drv, lab = sys.argv[1:4]
    a = fresh(snap, drv, lab)
    ascii_cycles = [per_row(a, [ord(c) for c in ASCII_ROW]) for _ in range(8)]
    h = fresh(snap, drv, lab)
    hrows = [hangul_row(i) for i in range(8)]
    hang_cycles = [per_row(h, list(r)) for r in hrows]
    # 100 more rows: the screen scrolls.
    a2 = fresh(snap, drv, lab)
    tot_a = [per_row(a2, [ord(c) for c in ASCII_ROW]) for _ in range(100)]
    h2 = fresh(snap, drv, lab)
    tot_h = [per_row(h2, list(hrows[i % 8])) for i in range(100)]
    sa = sum(tot_a[20:]) / len(tot_a[20:]) - sum(ascii_cycles) / 8
    sh = sum(tot_h[20:]) / len(tot_h[20:]) - sum(hang_cycles) / 8
    print(f"ASCII    {sum(ascii_cycles) / 8 / 46:8.0f} cycles/char   ({sum(ascii_cycles) / 8:9.0f} per row of 46)")
    print(f"Hangul   {sum(hang_cycles) / 8 / 23:8.0f} cycles/syll   ({sum(hang_cycles) / 8:9.0f} per row of 23)")
    print(f"scroll   {sa:8.0f} cycles (ASCII rows)   {sh:8.0f} cycles (Hangul rows)")


if __name__ == "__main__":
    main()
