"""Draw every modern Hangul syllable (11,172 of them) from font.json, one PNG per initial consonant.

usage: py -3 render_syllables.py [out dir] [label font .ttf]
  out dir      default: ./out/syllables next to this script
  label font   a TrueType font with Hangul, used only for the row and column labels
               (default on Windows: C:\\Windows\\Fonts\\malgun.ttf)

Rows are the 21 vowels, columns are the 28 finals (first column: none). Pixels come from font.json
through hangul_font.py, so the picture is what the driver draws. The script also reports syllables
that share the same bitmap ("identical-bitmap duplicates") and blank ones.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
from hangul_font import CHO, JONG, JUNG, composed, load_font  # noqa: E402

HERE = Path(__file__).resolve().parent
SCALE, PAD, LABEL = 3, 4, 40
DEFAULT_LABEL_FONT = r"C:\Windows\Fonts\malgun.ttf"


def label_font(path: str | None) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    path = path or DEFAULT_LABEL_FONT
    try:
        return ImageFont.truetype(path, 22)
    except OSError:
        print(f"warning: no label font at {path}; labels will not show Hangul. Pass a .ttf path.")
        return ImageFont.load_default(size=22)


def main() -> None:
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE / "out" / "syllables"
    out.mkdir(parents=True, exist_ok=True)
    font = load_font()
    lab = label_font(sys.argv[2] if len(sys.argv) > 2 else None)
    pitch = 12 + PAD
    w = LABEL + 28 * pitch * SCALE
    h = LABEL + 21 * pitch * SCALE
    seen: dict[tuple[int, ...], str] = {}
    blank: list[str] = []
    dup: list[tuple[str, str]] = []
    for c in range(19):
        img = Image.new("L", (w, h), 0)
        px = img.load()
        d = ImageDraw.Draw(img)
        for t in range(28):
            d.text((LABEL + t * pitch * SCALE + 6, 6), JONG[t] or "-", font=lab, fill=160)
        for v in range(21):
            d.text((6, LABEL + v * pitch * SCALE + 4), JUNG[v], font=lab, fill=160)
            for t in range(28):
                rows = composed(font, c, v, t)
                ch = chr(0xAC00 + c * 588 + v * 28 + t)
                if not any(rows):
                    blank.append(ch)
                key = tuple(rows)
                if key in seen:
                    dup.append((seen[key], ch))
                else:
                    seen[key] = ch
                x0 = LABEL + t * pitch * SCALE
                y0 = LABEL + v * pitch * SCALE
                for y, r in enumerate(rows):
                    for x in range(12):
                        if r >> x & 1:
                            for dy in range(SCALE):
                                for dx in range(SCALE):
                                    px[x0 + x * SCALE + dx, y0 + y * SCALE + dy] = 255
        img.save(out / f"cho{c + 1:02d}_{CHO[c]}.png")
    print("syllables", 19 * 21 * 28, "blank", len(blank), "identical-bitmap duplicates", len(dup))
    if blank:
        print("blank:", "".join(blank[:60]))
    if dup:
        print("duplicates (first 30):", " ".join(f"{a}={b}" for a, b in dup[:30]))
    print("wrote", out)


if __name__ == "__main__":
    main()
