"""Code/data discovery for the NEWHANGEUL binary (one-time use, see disasm.py)."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from opcodes import LEN, OPS  # noqa: E402

LOADER_AT, LOADER_LEN = 0x0F94, 0x6C
LC_AT, LC_LEN = 0xD000, 0x2FF5
BAN_AT, BAN_LEN = 0x1CC0, 768


class Region:
    def __init__(self, name: str, at: int, data: bytes):
        self.name, self.at, self.data = name, at, data
        self.end = at + len(data)
        self.kind: dict[int, str] = {}      # address -> "code" start of instruction
        self.covered: set[int] = set()
        self.refs: set[int] = set()         # addresses referenced from code

    def has(self, a: int) -> bool:
        return self.at <= a < self.end

    def byte(self, a: int) -> int:
        return self.data[a - self.at]

    def decode(self, a: int):
        if not self.has(a):
            return None
        op = self.byte(a)
        if op not in OPS:
            return None
        mn, mode = OPS[op]
        n = LEN[mode]
        if a + n > self.end:
            return None
        b = self.data[a - self.at : a - self.at + n]
        if mode == "rel":
            t = a + 2 + (b[1] - 256 if b[1] >= 128 else b[1])
        elif mode in ("abs", "abx", "aby", "ind"):
            t = b[1] | (b[2] << 8)
        else:
            t = None
        return mn, mode, n, b, t

    def descend(self, seeds: list[int]) -> list[int]:
        bad = []
        work = list(seeds)
        while work:
            a = work.pop()
            while True:
                if a in self.kind:
                    break
                d = self.decode(a)
                if d is None:
                    bad.append(a)
                    break
                mn, mode, n, b, t = d
                if any(x in self.covered for x in range(a, a + n)):
                    bad.append(a)
                    break
                self.kind[a] = "code"
                self.covered.update(range(a, a + n))
                if mode == "rel":
                    work.append(t)
                elif mn in ("JSR", "JMP") and mode == "abs":
                    if self.has(t):
                        work.append(t)
                if mn in ("RTS", "RTI", "BRK") or (mn == "JMP"):
                    break
                a += n
        return bad


def load(binpath=None):
    here = Path(__file__).resolve().parents[2]
    binpath = Path(binpath) if binpath else here / "NEWHANGEUL.bin"
    raw = binpath.read_bytes()
    assert len(raw) == LOADER_LEN + LC_LEN + BAN_LEN, len(raw)
    return (
        Region("loader", LOADER_AT, raw[:LOADER_LEN]),
        Region("lc", LC_AT, raw[LOADER_LEN : LOADER_LEN + LC_LEN]),
        Region("banner", BAN_AT, raw[LOADER_LEN + LC_LEN :]),
    )


def stock_seeds(lc: Region, lst: Path) -> list[int]:
    seeds = []
    for line in lst.read_text(encoding="utf-8", errors="replace").splitlines():
        m = re.match(r"^([0-9A-F]{4}): ([0-9a-f]{2,6})\s+([A-Z]{3})\b", line)
        if m:
            a = int(m.group(1), 16)
            if lc.has(a) and lc.byte(a) == int(m.group(2)[:2], 16):
                seeds.append(a)
    return seeds


if __name__ == "__main__":
    loader, lc, ban = load(sys.argv[1])
    scratch = Path(sys.argv[2])
    labels = json.loads((scratch / "labels.json").read_text())
    blabels = json.loads((scratch / "banner_labels.json").read_text())
    lst = Path(__file__).resolve().parents[3] / "hangeul2" / "HANGEUL.lst"
    data_labels = {"ROWLO", "ROWHI", "MASK", "MUL19", "CLASS", "BELLIMG", "BSRCL", "BSRCH"}
    seeds = [v for k, v in labels.items() if isinstance(v, int) and lc.has(v) and k not in data_labels]
    bad = lc.descend(seeds)
    print("seeds", len(seeds), "bad", [hex(x) for x in bad])
    n0 = len(lc.covered)
    bad = lc.descend(stock_seeds(lc, lst))
    print("after listing seeds: covered", n0, "->", len(lc.covered), "bad", len(bad))
    gaps = []
    a = LC_AT
    while a < lc.end:
        if a in lc.covered:
            a += 1
            continue
        s = a
        while a < lc.end and a not in lc.covered:
            a += 1
        gaps.append((s, a))
    print("gaps", len(gaps), "bytes", sum(e - s for s, e in gaps))
    for s, e in gaps:
        if e - s >= 8:
            print(f"  {s:04X}-{e - 1:04X} ({e - s})")
    lb = Region("banner", BAN_AT, ban.data)
    bs = [v for k, v in blabels.items() if ban.has(v)]
    print("banner bad", [hex(x) for x in lb.descend(bs)], len(lb.covered), "of", BAN_LEN)
    lo = loader
    print("loader bad", [hex(x) for x in lo.descend([LOADER_AT])], len(lo.covered), "of", LOADER_LEN)


def sweep_gaps(r: Region, lo: int, hi: int, runs: dict, min_len: int = 2) -> None:
    """Decode runs in the uncovered bytes of [lo, hi): routine by routine, ending at RTS/JMP/RTI.
    A $00 byte is padding, never code. Each run is remembered so a bad one can be dropped."""
    a = lo
    while a < hi:
        if a in r.covered or r.byte(a) == 0:
            a += 1
            continue
        run = []
        p = a
        ok = True
        while p < hi:
            if p in r.covered:
                break
            d = r.decode(p)
            if d is None or r.byte(p) == 0:
                ok = False
                break
            mn, mode, n, b, t = d
            if any(x in r.covered for x in range(p, p + n)):
                ok = False
                break
            run.append((p, n))
            p += n
            if mn in ("RTS", "RTI", "JMP"):
                break
        if ok and len(run) >= min_len or (ok and run and r.byte(run[-1][0]) in (0x60, 0x40)):
            rid = len(runs)
            runs[rid] = [x for x, _ in run]
            for q, n in run:
                r.kind[q] = "code"
                r.covered.update(range(q, q + n))
            a = run[-1][0] + run[-1][1]
        else:
            a += 1          # data byte: try again one byte later


def drop_run(r: Region, runs: dict, rid: int) -> None:
    for q in runs.pop(rid):
        n = LEN[OPS[r.byte(q)][1]]
        del r.kind[q]
        r.covered.difference_update(range(q, q + n))


def check_targets(r: Region, lo: int, hi: int) -> list[tuple[int, int]]:
    bad = []
    for a in sorted(r.kind):
        d = r.decode(a)
        mn, mode, n, b, t = d
        if t is None or mode in ("abx", "aby", "ind"):
            continue
        if mode == "abs" and mn not in ("JSR", "JMP"):
            continue
        if lo <= t < hi and t not in r.kind:
            bad.append((a, t))
    return bad


def table_seeds(r: Region, lo: int, hi: int, code_lo: int, code_hi: int) -> list[int]:
    """Words in uncovered bytes that point (as address or address-1) into code."""
    out = []
    a = lo
    while a < hi - 1:
        if a in r.covered or a + 1 in r.covered:
            a += 1
            continue
        w = r.byte(a) | (r.byte(a + 1) << 8)
        for t in (w + 1, w):
            if code_lo <= t < code_hi and r.decode(t) is not None and t not in r.covered and r.byte(t) != 0:
                out.append(t)
                break
        a += 1
    return out
