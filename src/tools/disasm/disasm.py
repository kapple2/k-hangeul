"""One-time generator: NEWHANGEUL.bin -> ca65 source.

usage: disasm.py <NEWHANGEUL.bin> <scratch dir with labels.json and banner_labels.json> <out dir>

This produced src/driver/driver.s. After that the assembly is the source and this script is
kept only to show how it was made. Bytes that no instruction reaches are written as .byte.
"""
from __future__ import annotations

import json
import pickle
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import analyze as A  # noqa: E402
from analyze import LEN, OPS, Region  # noqa: E402

ZP = {0x20: "WNDLFT", 0x21: "WNDWDTH", 0x22: "WNDTOP", 0x23: "WNDBTM", 0x24: "CH", 0x25: "CV",
      0x28: "BASL", 0x29: "BASH", 0x32: "INVFLG", 0x33: "PROMPTCH", 0x36: "CSWL", 0x37: "CSWH",
      0x38: "KSWL", 0x39: "KSWH", 0x67: "TXTTAB", 0x69: "VARTAB", 0x6F: "FRETOP", 0x73: "HIMEMZ"}
ROM = {0xFD0C: "MON_RDKEY", 0xFDED: "MON_COUT", 0xFDF0: "MON_COUT1", 0xFBDD: "MON_BELL1", 0xFD6A: "MON_GETLN", 0xFD8E: "MON_CROUT",
       0xFC58: "MON_HOME", 0xFD1B: "MON_KEYIN", 0xC000: "KBD", 0xC010: "KBDSTRB", 0xC030: "SPKR", 0xC050: "TXTCLR",
       0xC051: "TXTSET", 0xC052: "MIXCLR", 0xC053: "MIXSET", 0xC054: "LOWSCR", 0xC055: "HISCR",
       0xC056: "LORES", 0xC057: "HIRES", 0xC080: "LCRAMRD", 0xC081: "LCROMWR", 0xC082: "LCROMRD",
       0xC083: "LCRAMRW", 0xC088: "LCRAMRD2", 0xC08B: "LCRAMRW2"}
MAIN = {0x1980: "BUF", 0x1C60: "FLAGS", 0x1CB0: "BELL", 0x1CBA: "MODESAVE", 0x1CBB: "MODECAP",
        0x1CBC: "CASEMODE", 0x0200: "INBUF"}
STOCK_NAMES = {0xD000: "ASCIIFONT", 0xE0DC: "HGRLO", 0xE19C: "HGRHI", 0xE34E: "JUNGOF", 0xE3DA: "STOCKINIT",
               0xE441: "WNDCLAMP", 0xE459: "SETWINDOW", 0xE644: "FETCHLINE", 0xEA37: "CLEARHOME",
               0xEAD3: "KEYREAD", 0xEDF7: "SAVECUR", 0xEE02: "RESTCUR"}
STUB_BLOCKS = ((0xFD69, 0x06A8), (0xFD91, 0x0728), (0xFDB9, 0x07A8), (0xFDE1, 0x0450), (0xFE09, 0x04D0), (0xFE31, 0x07D0))
SECTIONS = {
    "BLIT": "Hi-res drawing: blit a 12x12 glyph, cursor, inverse, scroll, case mode",
    "INIT": "Driver start: banner copy, font relocation, DOS CATALOG patches, then the stock init",
    "ENBLIT": "Stock draw routines, patched to jump to the faster blit above",
    "PSETUP": "Hangul syllable pieces: pick and combine the initial, vowel and final glyphs",
    "STOCKINIT": "Stock Hangeul2 code starts here (init, line editor, scroll, key handling)",
    "COUT": "COUT: the character output routine behind CSW",
}
DATA_LABELS = {"ROWLO", "ROWHI", "MASK", "MUL19", "CLASS", "BELLIMG", "BSRCL", "BSRCH"}
STATE = 0x9400
TP_SEGS = ((0x0450, 0x28, 0x00), (0x04D0, 0x28, 0x28), (0x0550, 0x28, 0x50), (0x05D0, 0x04, 0x78),
           (0x064F, 0x21, 0x7C), (0x06A8, 0x2C, 0x9D), (0x0728, 0xB6, 0xC9))


def old_text_addr(a: int):
    for old, size, off in TP_SEGS:
        n = STATE + off
        if n <= a < n + size:
            return old + a - n
    return None


def main() -> None:
    binpath, scratch, outdir = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
    loader, lc, ban = A.load(binpath)
    labels = json.loads((scratch / "labels.json").read_text())
    blabels = json.loads((scratch / "banner_labels.json").read_text())
    kind, covered = pickle.loads((scratch / "lc_kind.pkl").read_bytes())
    lc.kind, lc.covered = kind, covered
    ban.descend([v for v in blabels.values() if ban.has(v) and v not in (0x1ED8, 0x1ED9, 0x1EDA, 0x1EDF, 0x1EE0, 0x1EE1, 0x1EE2)])
    A.sweep_gaps(ban, 0x1CC0, 0x1CC0 + 768, {})
    loader.descend([0x0F94])
    loader.descend([0x0FE7]) if loader.decode(0x0FE7) else None

    # known names from the generator's own label tables
    names: dict[int, str] = {}
    for k, v in labels.items():
        if isinstance(v, int) and lc.has(v):
            names.setdefault(v, k)
    for m in re.finditer(r"^([0-9A-F]{4}) ([A-Za-z0-9_]+)\s*$", (HERE.parents[2] / "hangeul2" / "HANGEUL.lst").read_text(encoding="utf-8", errors="replace"), re.M):
        names.setdefault(int(m.group(1), 16), m.group(2))
    for a, n in STOCK_NAMES.items():
        names.setdefault(a, n)
    for k, v in blabels.items():
        if isinstance(v, int) and ban.has(v):
            names.setdefault(v, k)
    equ: dict[int, str] = dict(ZP)
    for k, v in {**labels, **blabels}.items():
        if isinstance(v, int) and not lc.has(v) and not ban.has(v) and k != "BANNERSRC":
            equ.setdefault(v, k)
    for a, n in MAIN.items():
        equ.setdefault(a, n)
    equ.update({k: v for k, v in ROM.items()})
    # names for the state bytes, from the old text-page listing
    lst = (HERE.parents[2] / "hangeul2" / "HANGEUL.lst").read_text(encoding="utf-8", errors="replace")
    stock = {}
    for m in re.finditer(r"\$(0[4-7][0-9A-F]{2}) ([A-Z][A-Z0-9]+)\s*$", lst, re.M):
        stock.setdefault(int(m.group(1), 16), m.group(2))

    regions = [("loader", loader), ("lc", lc), ("banner", ban)]
    which = {}
    for nm, r in regions:
        for a in range(r.at, r.end):
            which[a] = r

    def region_of(a: int):
        return which.get(a)

    # references that need labels
    refs: dict[int, str] = {}
    for nm, r in regions:
        for a in sorted(r.kind):
            mn, mode, n, b, t = r.decode(a)
            if t is None:
                continue
            if mode in ("abs", "abx", "aby", "ind", "rel"):
                tr = region_of(t)
                if tr is not None:
                    refs[t] = "code" if mn in ("JSR", "JMP") or mode == "rel" else "data"

    def label_name(a: int, kindhint: str) -> str:
        if a in names:
            return names[a]
        r = region_of(a)
        pref = {"lc": "", "banner": "B_", "loader": "LD_"}[r.name]
        return f"{pref}{'L' if kindhint == 'code' else 'D'}_{a:04X}"

    # data run split points: every referenced address not inside code
    starts: dict[int, str] = {}
    for a, k in refs.items():
        r = region_of(a)
        if a in r.kind:
            starts[a] = k
        elif a not in r.covered:
            starts[a] = k
    for a in names:
        starts[a] = starts.get(a, "data")

    def state_name(a: int):
        old = old_text_addr(a)
        if old is None:
            return None
        return stock.get(old, f"S_{old:04X}")

    used_state: dict[int, str] = {}

    def sym(a: int, allow_state: bool = True) -> str | None:
        r = region_of(a)
        if r is not None:
            if a in starts:
                return starts_name(a)
            # inside an instruction or a data run: base + offset
            base = a
            while base not in starts and base not in r.kind and base > r.at:
                base -= 1
            if base in r.kind:
                n = LEN[OPS[r.byte(base)][1]]
                if a >= base + n:
                    return None
                return f"{starts_name(base)}+{a - base}"
            return f"{starts_name(base)}+{a - base}" if base in starts else None
        if a in equ and a >= 0x100 or (a in ZP and a < 0x100):
            return equ[a]
        if a in equ:
            return equ[a]
        if allow_state:
            n = state_name(a)
            if n:
                used_state[a] = n
                return n
        return None

    kinds = {}

    def starts_name(a: int) -> str:
        return label_name(a, starts.get(a, "data"))

    # make sure every instruction start that is only reached via base+off has a label
    for nm, r in regions:
        for a in sorted(r.kind):
            mn, mode, n, b, t = r.decode(a)
            if t is None or mode not in ("abs", "abx", "aby", "ind", "rel"):
                continue
            tr = region_of(t)
            if tr is None:
                continue
            base = t
            while base not in tr.kind and base not in starts and base > tr.at:
                base -= 1
            if base not in starts:
                starts[base] = "data" if base not in tr.kind else "code"

    def operand(r: Region, a: int, mn: str, mode: str, b: bytes, t) -> str:
        if mode in ("imp",):
            return ""
        if mode == "acc":
            return "a"
        if mode == "imm":
            return f"#${b[1]:02X}"
        if mode == "rel":
            return sym(t) or f"${t:04X}"
        if mode in ("zp", "zpx", "zpy", "izx", "izy"):
            nm = ZP.get(b[1]) or equ.get(b[1])
            v = nm or f"${b[1]:02X}"
            return {"zp": v, "zpx": f"{v},x", "zpy": f"{v},y", "izx": f"({v},x)", "izy": f"({v}),y"}[mode]
        # absolute forms
        nm = sym(t)
        v = nm or f"${t:04X}"
        if t < 0x100:
            v = f"a:{v}"
        return {"abs": v, "abx": f"{v},x", "aby": f"{v},y", "ind": f"({v})"}[mode]

    out = []
    w = out.append

    def names_rev(n: str) -> int:
        return next(a for a, k in names.items() if k == n)

    SECTION_AT = {names_rev(k): v for k, v in SECTIONS.items()}

    def stub_comment(src: int, run_old: int) -> None:
        """A stub block is code for main RAM, copied there by INIT: show it as comments."""
        run = None
        for old, size, off in TP_SEGS:
            if old <= run_old < old + size:
                run = STATE + off + run_old - old
        w(f"; ---- stub block, copied by INIT to ${run:04X} (old text page ${run_old:04X}), 40 bytes ----")
        blk = Region("stub", run, bytes(lc.byte(src + k) for k in range(40)))
        blk.descend([run])
        a = run
        while a < run + 40:
            if a in blk.kind:
                mn, mode, n, b, t = blk.decode(a)
                if mode in ("abs", "abx", "aby", "ind"):
                    tt = sym(t, True) or f"${t:04X}"
                    if t < 0x100:
                        tt = f"${t:04X}"
                    op = {"abs": tt, "abx": tt + ",x", "aby": tt + ",y", "ind": f"({tt})"}[mode]
                elif mode == "rel":
                    op = f"${t:04X}"
                elif mode == "imm":
                    op = f"#${b[1]:02X}"
                elif mode == "imp":
                    op = ""
                elif mode == "acc":
                    op = "a"
                else:
                    nm = ZP.get(b[1]) or f"${b[1]:02X}"
                    op = {"zp": nm, "zpx": nm + ",x", "zpy": nm + ",y", "izx": f"({nm},x)", "izy": f"({nm}),y"}[mode]
                w(f";   {a:04X}  {' '.join(f'{x:02X}' for x in b):9} {mn.lower()} {op}".rstrip())
                a += n
            else:
                a += 1
        w("")

    stub_src = {src: old for src, old in STUB_BLOCKS}
    class_at = names_rev("CLASS")

    def emit_region(r: Region, lo: int, hi: int, width: int = 16, skip_labels: bool = False) -> None:
        a = lo
        while a < hi:
            if r is lc and a in stub_src:
                stub_comment(a, stub_src[a])
            if a in SECTION_AT:
                w("")
                w("; " + "=" * 74)
                w("; " + SECTION_AT[a])
                w("; " + "=" * 74)
            if a in starts and not skip_labels:
                w(f"{starts_name(a)}:")
            if r is lc and a == class_at:
                w('        .include "jungclass.inc"        ; 22 bytes made from font.json')
                a += 22
                continue
            if a in r.kind:
                mn, mode, n, b, t = r.decode(a)
                op = operand(r, a, mn, mode, b, t)
                raw = " ".join(f"{x:02X}" for x in b)
                w(f"        {mn.lower():4} {op}".rstrip().ljust(36) + f"; {a:04X}  {raw}")
                a += n
            else:
                s = a
                rw = 8 if (r is lc and a < 0xD400) else width
                a += 1
                while a < hi and a not in r.kind and a not in starts and a - s < rw and not (r is lc and a in stub_src):
                    a += 1
                row = ",".join(f"${r.byte(x):02X}" for x in range(s, a))
                w(f"        .byte {row}".ljust(36) + f"; {s:04X}")

    text_ranges = {}
    # --- sections
    hdr = [
        "; NEWHANGEUL driver, 12x12 Hangul on hi-res page 1 for the Apple II Plus.",
        "; Generated once from NEWHANGEUL.bin by tools/disasm.py; this file is now the source.",
        "; Labels like L_xxxx and D_xxxx are the address in the language card or main RAM.",
        "; S_xxxx names a byte of driver state; xxxx was its address in the stock text page.",
        "",
        ".include \"defs.inc\"",
        "",
    ]
    out.extend(hdr)
    w('.segment "LOADER"')
    emit_region(loader, loader.at, loader.end)
    w("")
    w('.segment "LCIMG"')
    # stub blocks inside the LC image are emitted as plain bytes with a comment
    emit_region(lc, lc.at, lc.end)
    w("")
    w('.segment "BANNER"')
    emit_region(ban, ban.at, ban.end)
    outdir.mkdir(parents=True, exist_ok=True)
    (outdir / "driver.s").write_text("\n".join(out) + "\n", encoding="utf-8")
    # defs
    d = ["; Names for zero page, I/O, ROM, the driver's main RAM variables and its state.", ""]
    for a in sorted(equ):
        if a < 0x100 or a >= 0x100:
            d.append(f"{equ[a]} = ${a:04X}")
    d.append("")
    d.append(f"STATEBASE = ${STATE:04X}")
    for a in sorted(used_state):
        old = old_text_addr(a)
        d.append(f"{used_state[a]} = ${a:04X}            ; was ${old:04X} in the text page")
    (outdir / "defs.inc").write_text("\n".join(d) + "\n", encoding="utf-8")
    print("lines", len(out), "state names", len(used_state))


if __name__ == "__main__":
    main()
