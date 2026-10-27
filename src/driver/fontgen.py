"""Make the font files for the K-HANGEUL driver from font.json.

usage: fontgen.py <font.json> <build dir>
writes  FONT12.bin      the 12x12 glyphs and the shift masks, loaded at $6000 and copied to $0800 by INIT
        jungclass.inc   the 22-byte vowel class table that driver.s includes
        FONT6X10.bin    the English, digit and symbol glyphs: 128 characters of 10 lines, 6 pixels wide, 16 bytes
                        each (10 bytes of lines and 6 zero bytes), 2048 bytes. Loaded at $7200 and copied into
                        the language card by the driver at start-up
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

CHO_BASE = 0x0800
GLYPH = 24
CHO_N, JUNG_N, JONG_N = 6 * 19, 2 * 21, 27
JUNG_BASE = CHO_BASE + CHO_N * GLYPH
JONG_BASE = JUNG_BASE + JUNG_N * GLYPH
ZERO_BASE = JONG_BASE + JONG_N * GLYPH


def shift_masks() -> list[tuple[int, int, int]]:
    """7-bit hi-res masks for a 6-pixel row and a 12-pixel row at bit offsets 0..6."""
    rows = []
    for width in (6, 12):
        for off in range(7):
            bits = 0
            for i in range(width):
                bits |= 1 << (off + i)
            rows.append((bits & 0x7F, (bits >> 7) & 0x7F, (bits >> 14) & 0x7F))
    return rows


def composed(font: dict, c: int, v: int, t: int) -> list[int]:
    cl = font["jungClass"][v + 1] + (3 if t else 0)
    rows = [a | b for a, b in zip(font["cho"][cl][c], font["jung"][1 if t else 0][v])]
    if t:
        rows = [a | b for a, b in zip(rows, font["jong"][t - 1])]
    return rows


def glyph_at(blob: bytes, index: int) -> list[int]:
    off = index * GLYPH
    return [blob[off + 2 * i] | (blob[off + 2 * i + 1] << 8) for i in range(12)]


def composed_blob(blob: bytes, font: dict, c: int, v: int, t: int) -> list[int]:
    cl = font["jungClass"][v + 1] + (3 if t else 0)
    cho = glyph_at(blob, cl * 19 + c)
    jung = glyph_at(blob, CHO_N + (1 if t else 0) * 21 + v)
    rows = [a | b for a, b in zip(cho, jung)]
    if t:
        rows = [a | b for a, b in zip(rows, glyph_at(blob, CHO_N + JUNG_N + (t - 1)))]
    return rows


def pack_font(font: dict) -> bytes:
    if [len(b) for b in font["cho"]] != [19] * 6:
        raise SystemExit("cho banks are not 6 x 19")
    if [len(b) for b in font["jung"]] != [21, 21]:
        raise SystemExit("jung banks are not 2 x 21")
    if len(font["jong"]) != 27 or len(font["jungClass"]) != 22:
        raise SystemExit("jong or jungClass has the wrong length")
    raw = bytearray()

    def add(rows: list[int]) -> None:
        if len(rows) != 12:
            raise SystemExit("glyph is not 12 rows")
        for r in rows:
            if not 0 <= r <= 0xFFF:
                raise SystemExit(f"row {r} does not fit in 12 pixels")
            raw.append(r & 0xFF)
            raw.append((r >> 8) & 0xFF)

    for bank in font["cho"]:
        for glyph in bank:
            add(glyph)
    for bank in font["jung"]:
        for glyph in bank:
            add(glyph)
    for glyph in font["jong"]:
        add(glyph)
    if len(raw) != ZERO_BASE - CHO_BASE:
        raise SystemExit(f"font blob {len(raw)} bytes")
    raw.extend(bytes(GLYPH))
    for c in range(19):
        for v in range(21):
            for t in range(28):
                if composed(font, c, v, t) != composed_blob(raw, font, c, v, t):
                    raise SystemExit(f"pack mismatch {c},{v},{t}")
    return bytes(raw)


def main() -> None:
    font = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    out = Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    blob = pack_font(font)
    masks = bytes(row[col] for col in range(3) for row in shift_masks())
    if len(masks) != 42:
        raise SystemExit("shift masks are not 42 bytes")
    (out / "FONT12.bin").write_bytes(blob + masks)
    (out / "jungclass.inc").write_text(
        "        .byte " + ",".join(f"${b:02X}" for b in font["jungClass"]) + "\n", encoding="ascii")
    ascii_ = font["ascii"]
    if len(ascii_) != 128 or any(len(g) != 10 or any(not 0 <= r <= 0x3F for r in g) for g in ascii_):
        raise SystemExit("ascii must be 128 glyphs of 10 lines of 6 pixels")
    eng = bytearray()
    for g in ascii_:
        eng.extend(g)
        eng.extend(bytes(6))
    (out / "FONT6X10.bin").write_bytes(bytes(eng))
    print(f"FONT12.bin {len(blob) + 42} bytes, jungclass.inc, FONT6X10.bin {len(eng)} bytes")


if __name__ == "__main__":
    main()
