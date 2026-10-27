"""Build the Hangul glyphs from font.json, the same way the driver's font is built.

A syllable is three pieces ORed together: the initial consonant, the vowel, and the final consonant.
font.json has 6 banks of initials, 2 banks of vowels (one for syllables with no final, one for
syllables with a final), 27 finals, and jungClass, which says which initial bank a vowel uses.
The formula is the same as in src/driver/fontgen.py and as the driver's own composed() in the build.
"""
from __future__ import annotations

import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
FONT_JSON = HERE.parents[1] / "fonteditor" / "font.json"

CHO = "ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ"
JUNG = "ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ"
JONG = " ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ"


def load_font(path: Path = FONT_JSON) -> dict:
    return json.loads(Path(path).read_text(encoding="utf-8"))


def composed(font: dict, c: int, v: int, t: int) -> list[int]:
    """12 pixel rows of the syllable with initial c, vowel v and final t (t = 0 for none)."""
    cl = font["jungClass"][v + 1] + (3 if t else 0)
    rows = [a | b for a, b in zip(font["cho"][cl][c], font["jung"][1 if t else 0][v])]
    if t:
        rows = [a | b for a, b in zip(rows, font["jong"][t - 1])]
    return rows


def syllable_rows(font: dict, ch: str) -> list[int] | None:
    """12 pixel rows of a Hangul syllable, or None if ch is not one."""
    n = ord(ch) - 0xAC00
    if not 0 <= n <= 11171:
        return None
    c, v, t = n // 588, (n // 28) % 21, n % 28
    return composed(font, c, v, t)
