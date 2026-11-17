"""One-time edit of driver.s: banner text and sizes by symbol, HAN entry, state fill, K-HANGEUL name.

Run once from asm/tools. Kept as a record of the change; driver.s is the source.
"""
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
DRV = HERE.parent / "driver" / "driver.s"
sys.path.insert(0, str(HERE.parents[1]))
import build_driver as B  # legacy module: only for encode_text

NL = chr(13) + chr(10)
s = DRV.read_text(encoding="utf-8")
s = s.replace(NL, chr(10))


def rep(old, new, count=1):
    global s
    n = s.count(old)
    if n != count:
        raise SystemExit(f"expected {count} of {old!r}, found {n}")
    s = s.replace(old, new)


# 1. imports for the banner image
rep(".import __LCIMG_LOAD__, __LCIMG_SIZE__", ".import __LCIMG_LOAD__, __LCIMG_SIZE__\n.import __BANNER_LOAD__, __BANNER_RUN__, __BANNER_SIZE__")

# 2. INIT: banner copy and DOS patches by symbol
rep("        lda  #$C0                   ; D6C6  A9 C0", "        lda  #<__BANNER_RUN__")
rep("        lda  #$1C                   ; D6CA  A9 1C", "        lda  #>__BANNER_RUN__")
rep("        lda  #$00                   ; D6CE  A9 00\n        sta  $1C80", "        lda  #<__BANNER_SIZE__\n        sta  $1C80")
rep("        lda  #$03                   ; D6D3  A9 03", "        lda  #>__BANNER_SIZE__")
rep("        lda  #$46                   ; D789  A9 46", "        lda  #<CATINIT")
rep("        lda  #$1F                   ; D78E  A9 1F", "        lda  #>CATINIT")
rep("        lda  #$36                   ; D7A0  A9 36", "        lda  #<CATWAIT")
rep("        lda  #$1F                   ; D7A5  A9 1F", "        lda  #>CATWAIT")
rep("BSRCL:\n        .byte $F5                   ; D7AD", "BSRCL:\n        .byte <__BANNER_LOAD__")
rep("BSRCH:\n        .byte $3F                   ; D7AE", "BSRCH:\n        .byte >__BANNER_LOAD__")

# 3. fill the state with spaces first, then the stock init (also the entry of the HAN command)
rep("DPX:\n        jmp  STOCKINIT              ; D7AA  4C DA E3", "DPX:\n        jmp  STATEINIT              ; D7AA  4C DA E3")
i = s.index("        .byte $14,$2A,$00")
j = s.index("\n", s.index("; D80C", i))
rows = s[i:j].split("\n")
assert rows[0].startswith("        .byte $14,$2A") and "; D7FC" in rows[0] and "; D80C" in rows[1], rows
r1 = [int(x, 16) for x in re.findall(r"\$([0-9A-F]{2})", rows[0].split(";")[0])]
r2 = [int(x, 16) for x in re.findall(r"\$([0-9A-F]{2})", rows[1].split(";")[0])]
assert len(r1) == 16 and len(r2) == 16
keep1 = r1[:4]                  # D7FC-D7FF
keep2 = r2[4:]                  # D810-D81B
assert all(b == 0 for b in r1[4:]), r1
new = [
    "        .byte " + ",".join(f"${b:02X}" for b in keep1) + "          ; D7FC",
    "; The state ($9400-$95FF) starts as spaces, as the text page it used to live in was, then the stock init",
    "; copies its six blocks over it. INIT and the HAN command both come here. The 16 bytes were stock data",
    "; for the old Hangul font that no screen uses now.",
    "STATEINIT:",
    "        lda  #$A0",
    "        ldx  #$00",
    "@fill:",
    "        sta  STATEBASE,x",
    "        sta  STATEBASE+$100,x",
    "        inx",
    "        bne  @fill",
    "        jmp  STOCKINIT",
    "        .byte " + ",".join(f"${b:02X}" for b in keep2) + "          ; D810",
]
s = s[:i] + "\n".join(new) + s[j:]

# 4. loader: HAN gets its own entry; the loader keeps jmp INIT
rep("""DosPatch1:
        sta  LCRAMRD                ; $C080: language card RAM read, write protected
        jmp  INIT
""", """        sta  LCRAMRD                ; $C080: language card RAM read, write protected
        jmp  INIT
DosPatch1:                          ; copied into DOS: sta $C080 / jmp STATEINIT (the HAN command)
        .byte $8D,$80,$C0,$4C,<STATEINIT,>STATEINIT
""")

# 5. banner strings as clean data
old_text = "한글2 수정 버전 1.0 (캐플 2026년)"
new_text = "캐플한글 v1.0b 2026년 (한글2 수정버전)"
banner_text = B.BANNER_TEXT.replace(old_text, new_text)


def rows_of(data, per=16):
    out = []
    for k in range(0, len(data), per):
        out.append("        .byte " + ",".join(f"${b:02X}" for b in data[k:k + per]))
    return out


def replace_block(start_label, end_label, data, comment):
    global s
    a = s.index("\n" + start_label + ":\n") + 1
    b = s.index("\n" + end_label + ":\n") + 1
    block = [start_label + ":", "; " + comment] + rows_of(data + bytes([0]))
    s = s[:a] + "\n".join(block) + "\n" + s[b:]


replace_block("BLINES", "BTAIL", B.encode_text(banner_text), "the first three lines of the banner: johab pairs for Hangul, ASCII otherwise, $0D between lines")
replace_block("BTAILS", "BLOM", B.encode_text(B.BANNER_TAIL_TEXT), "after the free-memory number")
replace_block("BLOMS", "BHEX", B.encode_text(B.BANNER_LOMEM_TEXT), "after the HIMEM line")

# 6. name
s = s.replace("NEWHANGEUL", "K-HANGEUL")
DRV.write_text(s.replace(chr(10), NL), encoding="utf-8", newline="")
print("done")
