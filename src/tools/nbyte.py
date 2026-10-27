"""Convert N-byte (keystroke) Hangul text to UTF-8, and back.

N-byte text is what the Apple II keyboard sends for Hangul when the driver is in Hangul mode:
  $8B (Ctrl-K)  starts a Hangul run
  uppercase letters with the high bit set are two-set keys (R = $D2 is ㄱ, K = $CB is ㅏ)
  $AD $BD $AA $BC $BE $BB $AB are the Shift-free tense keys - ㄲ ㄸ ㅃ ㅆ ㅉ ㅒ ㅖ
  $81 (Ctrl-A)  ends the run
  $8D           is a line end (CR)
  everything else is ASCII with the high bit set, as the keyboard sends it.

usage:
  nbyte.py decode <in.txt> <out.txt>   N-byte file -> UTF-8 text (CR becomes a line feed)
  nbyte.py encode <in.txt> <out.txt>   UTF-8 text -> N-byte file (line feed becomes CR)
  nbyte.py check  <in.txt>             decode, encode again, and compare with the original

Only the Python standard library is used. The text is written with LF line ends and no BOM.
"""
from __future__ import annotations

import sys
from pathlib import Path

CTRL_K = 0x8B
CTRL_A = 0x81
CR = 0x8D
ZERO = 0x00

# jamo in Unicode compatibility order, as used to build a syllable (index 0 = no consonant/vowel)
CHO = "ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ"
JUNG = "ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ"
JONG = " ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ"

# the key that types each jamo (two-set layout; tense keys use the symbol keys of the Apple II)
CONSONANT_KEY = {
    "ㄱ": "R", "ㄲ": "-", "ㄴ": "S", "ㄷ": "E", "ㄸ": "=", "ㄹ": "F", "ㅁ": "A", "ㅂ": "Q", "ㅃ": "*",
    "ㅅ": "T", "ㅆ": "<", "ㅇ": "D", "ㅈ": "W", "ㅉ": ">", "ㅊ": "C", "ㅋ": "Z", "ㅌ": "X", "ㅍ": "V", "ㅎ": "G",
}
VOWEL_KEY = {
    "ㅏ": "K", "ㅐ": "O", "ㅑ": "I", "ㅒ": ";", "ㅓ": "J", "ㅔ": "P", "ㅕ": "U", "ㅖ": "+",
    "ㅗ": "H", "ㅛ": "Y", "ㅜ": "N", "ㅠ": "B", "ㅡ": "M", "ㅣ": "L",
}
# a compound vowel or final is typed as its two parts, one after the other
COMPOUND_VOWEL = {"ㅘ": "ㅗㅏ", "ㅙ": "ㅗㅐ", "ㅚ": "ㅗㅣ", "ㅝ": "ㅜㅓ", "ㅞ": "ㅜㅔ", "ㅟ": "ㅜㅣ", "ㅢ": "ㅡㅣ"}
COMPOUND_FINAL = {"ㄳ": "ㄱㅅ", "ㄵ": "ㄴㅈ", "ㄶ": "ㄴㅎ", "ㄺ": "ㄹㄱ", "ㄻ": "ㄹㅁ", "ㄼ": "ㄹㅂ",
                  "ㄽ": "ㄹㅅ", "ㄾ": "ㄹㅌ", "ㄿ": "ㄹㅍ", "ㅀ": "ㄹㅎ", "ㅄ": "ㅂㅅ"}

# reverse lookups for decoding
KEY_CONSONANT = {v: k for k, v in CONSONANT_KEY.items()}
KEY_VOWEL = {v: k for k, v in VOWEL_KEY.items()}
COMBINE_VOWEL = {v: k for k, v in COMPOUND_VOWEL.items()}
COMBINE_FINAL = {v: k for k, v in COMPOUND_FINAL.items()}
FINAL_SINGLE = set(JONG[1:]) - set(COMPOUND_FINAL)


def _to_keys(text_jamo: str) -> list[str]:
    return [CONSONANT_KEY.get(c) or VOWEL_KEY[c] for c in text_jamo]


def _decompose(ch: str) -> tuple[str, str, str]:
    code = ord(ch) - 0xAC00
    cho, rest = divmod(code, 21 * 28)
    jung, jong = divmod(rest, 28)
    return CHO[cho], JUNG[jung], JONG[jong]


def encode_syllable_keys(ch: str) -> list[str]:
    """Keys that type one Hangul syllable (or a standalone jamo)."""
    if 0xAC00 <= ord(ch) <= 0xD7A3:
        cho, jung, jong = _decompose(ch)
        keys = [CONSONANT_KEY[cho]]
        keys += _keys_of_vowel(jung)
        if jong != " ":
            keys += _keys_of_final(jong)
        return keys
    if ch in CONSONANT_KEY:
        return [CONSONANT_KEY[ch]]
    if ch in VOWEL_KEY or ch in COMPOUND_VOWEL:
        return _keys_of_vowel(ch)
    if ch in COMPOUND_FINAL:
        return _keys_of_final(ch)
    raise ValueError(f"not a Hangul syllable or jamo: {ch!r}")


def _keys_of_vowel(v: str) -> list[str]:
    if v in COMPOUND_VOWEL:
        return _to_keys(COMPOUND_VOWEL[v])
    return [VOWEL_KEY[v]]


def _keys_of_final(f: str) -> list[str]:
    if f in COMPOUND_FINAL:
        return _to_keys(COMPOUND_FINAL[f])
    return [CONSONANT_KEY[f]]


class _Builder:
    """Collects one syllable at a time while decoding."""

    def __init__(self) -> None:
        self.out: list[str] = []
        self.cho = self.jung = self.jong = ""

    def flush(self) -> None:
        if self.cho and self.jung:
            ci, vi = CHO.index(self.cho), JUNG.index(self.jung)
            ti = JONG.index(self.jong) if self.jong else 0
            self.out.append(chr(0xAC00 + (ci * 21 + vi) * 28 + ti))
        elif self.cho:
            self.out.append(self.cho)
        elif self.jung:
            self.out.append(self.jung)
        self.cho = self.jung = self.jong = ""

    def consonant(self, c: str) -> None:
        if not self.cho:
            self.flush()
            self.cho = c
        elif not self.jung:
            self.flush()
            self.cho = c
        elif not self.jong:
            if c in FINAL_SINGLE:
                self.jong = c
            else:
                self.flush()
                self.cho = c
        elif self.jong + c in COMBINE_FINAL:
            self.jong = COMBINE_FINAL[self.jong + c]
        else:
            self.flush()
            self.cho = c

    def vowel(self, v: str) -> None:
        if not self.jung:
            self.jung = v
        elif not self.jong:
            if self.cho and self.jung + v in COMBINE_VOWEL:
                self.jung = COMBINE_VOWEL[self.jung + v]
            else:
                self.flush()
                self.jung = v
        else:
            # a final consonant moves to the next syllable when a vowel follows it
            first, second = _split_final(self.jong)
            self.jong = first
            self.flush()
            self.cho = second
            self.jung = v

    def literal(self, ch: str) -> None:
        self.flush()
        self.out.append(ch)


def _split_final(jong: str) -> tuple[str, str]:
    """A final cluster ㄳ gives ㄱ to stay and ㅅ to start the next syllable. A single final gives nothing to stay."""
    if jong in COMPOUND_FINAL:
        a, b = COMPOUND_FINAL[jong][0], COMPOUND_FINAL[jong][1]
        return a, b
    return "", jong


def decode(data: bytes) -> str:
    """N-byte bytes to Unicode text."""
    b = _Builder()
    in_run = False
    for byte in data:
        if byte == ZERO:
            continue
        if byte == CTRL_K:
            b.flush()
            in_run = True
            continue
        if byte == CTRL_A:
            b.flush()
            in_run = False
            continue
        if byte == CR:
            b.flush()
            b.out.append("\n")
            continue
        key = chr(byte & 0x7F)
        if in_run and key in KEY_CONSONANT:
            b.consonant(KEY_CONSONANT[key])
        elif in_run and key in KEY_VOWEL:
            b.vowel(KEY_VOWEL[key])
        elif in_run:
            b.literal(key)
        else:
            b.literal(key)
    b.flush()
    return "".join(b.out)


def encode(text: str) -> bytes:
    """Unicode text to N-byte bytes. Hangul goes inside Ctrl-K ... Ctrl-A runs."""
    out = bytearray()
    in_run = False
    for ch in text:
        if ch == "\n":
            if in_run:
                out.append(CTRL_A)
                in_run = False
            out.append(CR)
            continue
        if ch == "\r":
            continue
        if _is_hangul(ch):
            if not in_run:
                out.append(CTRL_K)
                in_run = True
            for k in encode_syllable_keys(ch):
                out.append(ord(k) | 0x80)
            continue
        if in_run:
            out.append(CTRL_A)
            in_run = False
        if ord(ch) > 0x7F:
            raise ValueError(f"cannot store {ch!r} in N-byte text")
        out.append(ord(ch) | 0x80)
    if in_run:
        out.append(CTRL_A)
    return bytes(out)


def _is_hangul(ch: str) -> bool:
    return (0xAC00 <= ord(ch) <= 0xD7A3) or ch in CONSONANT_KEY or ch in VOWEL_KEY \
        or ch in COMPOUND_VOWEL or ch in COMPOUND_FINAL


def main(argv: list[str]) -> int:
    if len(argv) < 3 or argv[1] not in ("decode", "encode", "check"):
        print(__doc__)
        return 2
    src = Path(argv[2])
    if argv[1] == "decode":
        text = decode(src.read_bytes())
        Path(argv[3]).write_text(text, encoding="utf-8", newline="\n")
        print("wrote", argv[3])
    elif argv[1] == "encode":
        data = encode(src.read_text(encoding="utf-8"))
        Path(argv[3]).write_bytes(data)
        print("wrote", argv[3])
    else:
        original = src.read_bytes().rstrip(bytes([ZERO]))
        again = encode(decode(original))
        if again == original:
            print("OK: round trip is exact")
            return 0
        n = next((i for i, (x, y) in enumerate(zip(original, again)) if x != y), min(len(original), len(again)))
        print(f"DIFFERENT at byte {n}: original {original[n:n+8].hex()} / again {again[n:n+8].hex()}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
