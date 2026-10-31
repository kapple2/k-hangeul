"""Exact cycle profile by routine for one ASCII row, one Hangul row, and one scroll."""
from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from sim6502 import Sim, profile_calls  # noqa: E402
import bench_sim as B  # noqa: E402


def names(labels: Path):
    raw = json.loads(labels.read_text())
    used = set(raw.pop("_used", []))
    new = sorted((v, k) for k, v in raw.items() if v >= 0xD000)
    stock = []
    # optional: a saved listing of the stock Hangeul2, named in HANGEUL_LST; it is not in this repository
    lst = Path(os.environ["HANGEUL_LST"]) if os.environ.get("HANGEUL_LST") else None
    for line in (lst.read_text(encoding="utf-8", errors="replace").splitlines() if lst and lst.exists() else []):
        m = re.match(r"^([0-9A-F]{4}) ([A-Z][A-Z0-9_]+)\b", line)
        if m:
            stock.append((int(m.group(1), 16), m.group(2)))
    stock.sort()

    def name(a: int) -> str:
        pool = new if a in used else stock
        best = None
        for v, k in pool:
            if v <= a:
                best = k
            else:
                break
        return best or f"${a:04X}"

    return name


def report(title: str, cyc: dict[int, int], name, top: int = 14) -> None:
    tot = sum(cyc.values())
    agg: dict[str, int] = {}
    for a, c in cyc.items():
        agg[name(a)] = agg.get(name(a), 0) + c
    print(f"-- {title}: {tot} cycles")
    for k, v in sorted(agg.items(), key=lambda kv: -kv[1])[:top]:
        print(f"   {100 * v / tot:5.1f}%  {v:8d}  {k}")


def main() -> None:
    snap, drv, lab = sys.argv[1:4]
    name = names(Path(lab))
    s = B.fresh(snap, drv, lab)
    row = [ord(c) for c in B.ASCII_ROW]
    report("ASCII: one char", profile_calls(s, lambda: s.cout(ord("M") | 0x80)), name)
    s = B.fresh(snap, drv, lab)
    h = list(B.hangul_row(3))
    report("Hangul: one row of 23", profile_calls(s, lambda: [s.cout(b | 0x80) for b in h]), name)
    s = B.fresh(snap, drv, lab)
    for _ in range(12):
        B.per_row(s, row)
    report("scroll: one more ASCII row (draw + scroll)", profile_calls(s, lambda: B.per_row(s, row)), name, 8)


if __name__ == "__main__":
    main()
