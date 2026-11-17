"""One-time: put GalmuriMono9 into font.json as the English glyphs, 128 glyphs of 10 lines, 6 pixels wide.

usage: ascii_from_galmuri.py <font.json> <GalmuriMono9.bdf>
A glyph line has bit 0 at the left. BDF line y (0 = baseline row of the font's box) goes to glyph line 9 - y, so
the bottom of the glyph is the bottom of the 10 lines. Codes outside 33-126 are blank. `orig.ascii` (for Revert)
is set to the same glyphs. The old 6x8 English (with its edits) is lost from font.json; font.before-6x10.json
keeps the file as it was.
"""
import json
import re
import sys
from pathlib import Path

fj, bdf = Path(sys.argv[1]), Path(sys.argv[2])
txt = bdf.read_text(encoding="utf-8", errors="replace")
pat = (r"STARTCHAR [^\n]*\nENCODING (\d+)\nSWIDTH \d+ \d+\nDWIDTH (\d+) \d+\nBBX (-?\d+) (\d+) (-?\d+) (-?\d+)\n"
       r"BITMAP\n((?:[0-9A-Fa-f]+\n)*)ENDCHAR")
glyphs = []
for code in range(128):
    glyphs.append([0] * 10)
for m in re.finditer(pat, txt):
    code = int(m.group(1))
    if not 33 <= code <= 126:
        continue
    w, h, xo, yo = (int(m.group(i)) for i in (3, 4, 5, 6))
    rows = m.group(7).split()
    bits = len(rows[0]) * 4
    g = [0] * 10
    for i, rs in enumerate(rows):
        r = int(rs, 16)
        y = yo + h - 1 - i                  # BDF line of this row
        line = 9 - y
        if not 0 <= line < 10:
            raise SystemExit(f"code {code}: line {line} out of the 10 lines")
        v = 0
        for x in range(w):
            if r >> (bits - 1 - x) & 1:
                if not 0 <= xo + x < 6:
                    raise SystemExit(f"code {code}: pixel {xo + x} out of 6")
                v |= 1 << (xo + x)
        g[line] |= v
    glyphs[code] = g
font = json.loads(fj.read_text(encoding="utf-8"))
font["ascii"] = glyphs
font["orig"]["ascii"] = [g[:] for g in glyphs]
fj.write_text(json.dumps(font, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
dups = {}
for c in range(33, 127):
    dups.setdefault(tuple(glyphs[c]), []).append(chr(c))
print("glyphs", sum(1 for g in glyphs if any(g)), "duplicates:", [v for v in dups.values() if len(v) > 1] or "none")
