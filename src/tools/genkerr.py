"""Make src/driver/kerr_text.inc: the Korean Applesoft error messages as johab pairs.

usage: py -3 genkerr.py [--show] [out.inc]      (default out: ../driver/kerr_text.inc)

Text is stored the way the driver draws it without the keystroke state machine: a Hangul syllable is two bytes,
LEAD = $80 | cho << 2 | jung >> 3, TRAIL = (jung & 7) << 5 | jong, with the codes of PACKF (engfast.inc), and ASCII is one
byte. A string ends with $00. The strings are printed by KPUTS (driver.s): a byte below $20 goes to COUT, anything else to
PLOTCH, which pairs a lead byte with the byte after it.
"""
from __future__ import annotations

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import nbyte

CHO = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
JUNG = [3, 4, 5, 6, 7, 10, 11, 12, 13, 14, 15, 18, 19, 20, 21, 22, 23, 26, 27, 28, 29]


def jong_code(i: int) -> int:
    # the final consonants as PACKF/PGT (engfast.inc) code them: fill 1, g 2 ... lh 16, m 17, b 19, bs 20, s 21 ... h 29
    # (code 18 is not used; ks X 1001 johab differs from this at m)
    return i + 1 if i <= 16 else i + 2


def johab(text: str) -> bytes:
    out = bytearray()
    for ch in text:
        c = ord(ch)
        if 0xAC00 <= c <= 0xD7A3:
            i = c - 0xAC00
            cho, jung, jong = i // 588, (i % 588) // 28, i % 28
            cc, jc, gc = CHO[cho], JUNG[jung], jong_code(jong)
            out.append(0x80 | cc << 2 | jc >> 3)
            out.append((jc & 7) << 5 | gc)
        elif c < 0x80:
            out.append(c)
        else:
            raise ValueError("not Hangul or ASCII: " + ch)
    return bytes(out)


# Applesoft error messages, in the order of the ROM table at $D260: (offset of the first character, English, Korean)
ROM = [
    (0x00, "NEXT WITHOUT FOR", "FOR 없음"),
    (0x10, "SYNTAX", "문법"),
    (0x16, "RETURN WITHOUT GOSUB", "GOSUB 없음"),
    (0x2A, "OUT OF DATA", "자료 끝"),
    (0x35, "ILLEGAL QUANTITY", "범위"),
    (0x45, "OVERFLOW", "넘침"),
    (0x4D, "OUT OF MEMORY", "메모리 부족"),
    (0x5A, "UNDEF'D STATEMENT", "줄 없음"),
    (0x6B, "BAD SUBSCRIPT", "첨자"),
    (0x78, "REDIM'D ARRAY", "배열 중복"),
    (0x85, "DIVISION BY ZERO", "0으로 나눔"),
    (0x95, "ILLEGAL DIRECT", "직접 불가"),
    (0xA3, "TYPE MISMATCH", "형 다름"),
    (0xB0, "STRING TOO LONG", "문자열 김"),
    (0xBF, "FORMULA TOO COMPLEX", "식 복잡"),
    (0xD2, "CAN'T CONTINUE", "계속 불가"),
    (0xE0, "UNDEF'D FUNCTION", "없는 함수"),
]
ERR = " 오류"    # replaces " ERROR" and the bell that follows it
IN = " 줄 "         # replaces " IN " (the line number follows)


# the Korean DOS error messages (message number -> text); 3 shares the text of 2. 0 is CR, bell, CR.
DOS = {
    1: "언어 없음", 2: "범위 오류", 4: "쓰기 금지됨", 5: "자료 끝", 6: "파일을 찾을 수 없음", 7: "볼륨 번호 다름",
    8: "입출력 오류", 9: "디스크 가득 참", 10: "파일 잠김", 11: "문법 오류", 12: "버퍼 부족", 13: "파일 종류 다름",
    14: "프로그램이 너무 큼", 15: "직접 명령 아님",
}
DOS_EN = {1: "LANGUAGE NOT AVAILABLE", 2: "RANGE ERROR", 4: "WRITE PROTECTED", 5: "END OF DATA", 6: "FILE NOT FOUND",
          7: "VOLUME MISMATCH", 8: "I/O ERROR", 9: "DISK FULL", 10: "FILE LOCKED", 11: "SYNTAX ERROR",
          12: "NO BUFFERS AVAILABLE", 13: "FILE TYPE MISMATCH", 14: "PROGRAM TOO LARGE", 15: "NOT DIRECT COMMAND"}


def dos_lines() -> list[str]:
    """the DOS messages for the 16K card (kdos_msg.inc, KGUARD = 1): one table, offsets KOFF"""
    lines = ["; made by src/tools/genkerr.py: do not edit. Korean DOS error messages as johab pairs ($0D, $07 go to COUT), $00 ended."]
    strings = {0: bytes([0x0D, 0x07, 0x0D])}
    for k, v in DOS.items():
        strings[k] = johab(v)
    strings[3] = strings[2]
    off = 0
    offs = []
    body = []
    done = {}
    for k in range(16):
        s = strings[k]
        if s in done:
            offs.append(done[s])
            continue
        done[s] = off
        offs.append(off)
        txt = "CR BELL CR" if k == 0 else DOS[k]
        body.append("        .byte %s    ; %d %s: %s" % (hexs(s + bytes([0])), k, DOS_EN.get(k, ""), txt))
        off += len(s) + 1
    assert off <= 256
    lines.append("KSTR1:")
    lines += body
    lines.append("KOFF:                           ; start of the text of message 0..15 in KSTR1")
    lines.append("        .byte " + ",".join("$%02X" % o for o in offs))
    lines.append("KDOSTEXT = %d" % off)
    return lines


def hexs(b: bytes) -> str:
    return ",".join("$%02X" % x for x in b)


def k6_lines() -> list[str]:
    """the same texts as Hangul-mode keystrokes for the Saturn card (bank 6 prints through COUT): keys, then the texts in the
    same order, found by counting $00 ends (kerr6.inc)"""
    lines = ["; made by src/tools/genkerr.py: do not edit. Korean Applesoft error messages as keystroke text (Saturn card, bank 6)."]
    keys = [off for off, en, ko in ROM] + [0xF1, 0xF2]
    texts = [ko for off, en, ko in ROM] + [IN, ERR]
    lines.append("KEK:    .byte " + ",".join("$%02X" % k for k in keys))
    lines.append("KEKN = %d" % len(keys))
    lines.append("KET:")
    for k, t in zip(keys, texts):
        b = bytes(nbyte.encode(t)) + bytes([0])
        lines.append("        .byte %s    ; $%02X %s" % (hexs(b), k, t))
    return lines


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    lines = ["; made by src/tools/genkerr.py: do not edit (change the texts there). Korean Applesoft error messages, johab pairs, $00 ended."]
    total = 0
    keys = [off for off, en, ko in ROM] + [0xF1, 0xF2]
    texts = [ko for off, en, ko in ROM] + [IN, ERR]
    lines.append("KEK:    .byte " + ",".join("$%02X" % k for k in keys) + "    ; the key of each text: the ROM offset of the first character of a message; $F1 the I of ' IN '; $F2 the space of ' ERROR'")
    lines.append("KEKN = %d" % len(keys))
    lines.append("KET:                        ; the texts in the order of the keys, each ended by $00")
    for k, t in zip(keys, texts):
        b = johab(t) + bytes([0])
        total += len(b)
        lines.append("        .byte %s    ; $%02X %s" % (hexs(b), k, t))
    if "--show" in sys.argv:
        print("text bytes", total)
        for off, en, ko in ROM:
            print("%-22s %-22s %d" % (en, ko, len(johab(ko)) + 1))
        return
    d = Path(args[0]).parent if args else Path(__file__).resolve().parent.parent / "driver"
    out = Path(args[0]) if args else d / "kerr_text.inc"
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    (d / "kerr6_text.inc").write_text("\n".join(k6_lines()) + "\n", encoding="utf-8")
    dl = dos_lines()
    (d / "kdos_johab.inc").write_text("\n".join(dl) + "\n", encoding="utf-8")
    print("wrote", out, "text", total, "bytes; kdos_johab.inc", dl[-1])


if __name__ == "__main__":
    main()
