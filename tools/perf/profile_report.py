"""Summarise a pc.txt sample file by routine.

usage: profile_report.py pc.txt labels.json [HANGEUL.lst]
Sample addresses are bucketed by the nearest label at or below the address:
new-driver labels (labels.json) first, then the stock listing's named routines.
"""
from __future__ import annotations

import collections
import json
import re
import sys
from pathlib import Path

pc = [int(x, 16) for x in Path(sys.argv[1]).read_text().split() if x]
raw = json.loads(Path(sys.argv[2]).read_text())
used = set(raw.pop("_used", []))
new = {v: k for k, v in raw.items() if v >= 0xD000}
stock: dict[int, str] = {}
lst = Path(sys.argv[3]) if len(sys.argv) > 3 else None   # optional saved listing of the stock Hangeul2; not in this repository
for line in (lst.read_text(encoding="utf-8", errors="replace").splitlines() if lst and lst.exists() else []):
    m = re.match(r"^([0-9A-F]{4}) ([A-Z][A-Z0-9_]+)\b", line)
    if m:
        stock[int(m.group(1), 16)] = m.group(2)


def name(a: int) -> str:
    if a < 0xD000:
        return f"main-RAM ${a:04X}"
    if a in used:
        cands = [(k, v) for k, v in new.items() if k <= a]
        return max(cands)[1] if cands else f"${a:04X}"
    cands = []
    best_new = None
    cands2 = [(k, v) for k, v in stock.items() if k <= a]
    best_stock = max(cands2) if cands2 else None
    best = max([b for b in (best_new, best_stock) if b], default=None)
    if best is None:
        return f"${a:04X}"
    return f"{best[1]} (+{a - best[0]})" if False else best[1]


cnt = collections.Counter(name(a) for a in pc)
total = len(pc)
print(f"{total} samples")
for k, v in cnt.most_common(25):
    print(f"{100 * v / total:5.1f}%  {v:5d}  {k}")
