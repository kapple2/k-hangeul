"""Draw the English glyphs at the current 6x10 cell and at taller 6x12 and 6x8 mock-ups, next to Hangul.

usage: py -3 render_english.py [out dir] [label font .ttf]
  out dir      default: ./out/english next to this script
  label font   a TrueType font with Hangul, for the titles (default on Windows: C:\\Windows\\Fonts\\malgun.ttf)

Hangul and English come from font.json. The taller variants only stretch the glyph rows so you can judge
size and balance; they are not real fonts. Draw a real font in the font editor.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
from hangul_font import load_font, syllable_rows  # noqa: E402

HERE = Path(__file__).resolve().parent
S = 3                       # screen pixel -> image pixels
COLS = 46
DEFAULT_LABEL_FONT = r"C:\Windows\Fonts\malgun.ttf"
LINES = [
    "한글2 수정 버전 1.0 (애플 2026년)",
    "HIMEM $9400 (37888) LOMEM $4003",
    "]PRINT \"Hello, World! 0123456789\"",
    "Room 12 ABC xyz 3.14  0O 1lI| g j p q y",
    "시험 1: 가나다라마바사 Apple II+",
    "The quick brown fox jumps over the lazy dog.",
    "THE QUICK BROWN FOX JUMPS OVER 0123456789",
    "한글2 2026 hello 90 {}[]<>~^_`@#%&*;:'?",
    "날개: 박제가 되어 버린 천재를 아시오?",
]
VARIANTS = [(8, "English 8 rows (smaller mock-up)"), (10, "English 10 rows (the current font)"),
            (12, "English 12 rows (taller mock-up, fills the cell)")]


def label_font(path: str | None) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    try:
        return ImageFont.truetype(path or DEFAULT_LABEL_FONT, 22)
    except OSError:
        print("warning: no label font found; titles will not show Hangul. Pass a .ttf path.")
        return ImageFont.load_default(size=22)


def stretch(rows10: list[int], height: int) -> list[int]:
    """Rows of the 6x10 glyph -> `height` rows, repeating some rows. The top bar and the foot stay one row thick."""
    if height == 10:
        return rows10[:]
    src = {
        12: [0, 0, 1, 2, 3, 3, 4, 5, 6, 7, 8, 9],
        8: [0, 1, 3, 4, 5, 6, 8, 9],
    }[height]
    return [rows10[i] if i < len(rows10) else 0 for i in src]


def english_rows(font: dict, ch: str, height: int) -> list[int] | None:
    code = ord(ch)
    if code == 32:
        return [0] * 12
    if not 33 <= code < 127:
        return None
    g = stretch(font["ascii"][code], height)
    return [0] * (12 - len(g)) + g


def screen(font: dict, height: int) -> Image.Image:
    px = Image.new("L", (COLS * 6, 12 * len(LINES)), 0)
    p = px.load()
    for ln, text in enumerate(LINES):
        col = 0
        for ch in text:
            rows = syllable_rows(font, ch)
            w = 12
            if rows is None:
                rows = english_rows(font, ch, height)
                w = 6
                if rows is None:
                    continue
            if (col + w // 6) * 6 > COLS * 6:
                break
            for y, bits in enumerate(rows):
                for x in range(w):
                    if bits >> x & 1:
                        p[col * 6 + x, ln * 12 + y] = 255
            col += w // 6
    return px.resize((px.width * S, px.height * S), Image.NEAREST)


def main() -> None:
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE / "out" / "english"
    out.mkdir(parents=True, exist_ok=True)
    font = load_font()
    lab = label_font(sys.argv[2] if len(sys.argv) > 2 else None)
    shots = []
    for h, title in VARIANTS:
        img = screen(font, h)
        canvas = Image.new("RGB", (img.width + 20, img.height + 60), (24, 24, 28))
        d = ImageDraw.Draw(canvas)
        d.text((10, 12), title, font=lab, fill=(255, 214, 120))
        canvas.paste(Image.merge("RGB", (img, img, img)), (10, 50))
        canvas.save(out / f"english_{h}.png")
        shots.append(canvas)
    both = Image.new("RGB", (shots[0].width, sum(s.height for s in shots) + 10), (24, 24, 28))
    y = 0
    for s in shots:
        both.paste(s, (0, y))
        y += s.height + 10
    both.save(out / "compare.png")
    print("wrote", out)


if __name__ == "__main__":
    main()
