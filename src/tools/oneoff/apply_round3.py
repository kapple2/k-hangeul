"""One-time edit of driver.s: English font as a file (FONT6X10, 10-line glyphs) loaded into the language card at start-up.

Run once. Kept as a record of the change; driver.s is the source.
"""
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
DRV = HERE.parent / "driver" / "driver.s"
DEFS = HERE.parent / "driver" / "defs.inc"
NL = chr(13) + chr(10)
s = DRV.read_text(encoding="utf-8").replace(NL, chr(10))


def rep(old, new, count=1):
    global s
    n = s.count(old)
    if n != count:
        raise SystemExit(f"expected {count} of {old!r}, found {n}")
    s = s.replace(old, new)


# 1. the old 1024-byte English table is free space now: keep the bytes so nothing moves
rep('ASCIIFONT:\n        .include "asciifont.inc"        ; made from font.json by fontgen.py; edit the glyphs with the font editor\n',
    'FREE_D000:\n        .res 1024                       ; was the English table; the table is ENGFONT now\n')

# 2. code and table in the unused stock data after STATEINIT
a = s.index("        jmp  STOCKINIT\n        .byte $A0,$20,$90")
a_end = a + len("        jmp  STOCKINIT\n")
rows = []
pos = a_end
while True:
    nl = s.index("\n", pos)
    line = s[pos:nl]
    m = re.match(r"^        \.byte (.*?)\s*; ([0-9A-F]{4})$", line)
    if not m:
        break
    rows.append((int(m.group(2), 16), [int(x, 16) for x in re.findall(r"\$([0-9A-F]{2})", m.group(1))], pos, nl + 1))
    pos = nl + 1
first = rows[0][0]
assert first == 0xD810, hex(first)
keep_from = 0xE060
cut_end = None
tail = None
for addr, bs, p0, p1 in rows:
    if addr <= keep_from < addr + len(bs):
        tail = bs[keep_from - addr:]
        cut_end = p1
        tail_addr = keep_from
        break
assert tail is not None
code = '''; ---------------------------------------------------------------------------
; The English font: FONT6X10 is loaded at ENGSRC ($7200) by HELLO and copied here by INIT while the card
; is still writable. 128 glyphs of 16 bytes: the 10 lines of the glyph, then 6 unused bytes (so a glyph
; is found with 4 shifts). The glyph pointer S_07DB/S_07DC starts at ENGFONT (stub block FE31).
; These bytes were stock data for the old Hangul font; zeroing them changed no screen.
; ---------------------------------------------------------------------------
; P0 = P0 + A * 16
ENGPTR:
        sta  P2L
        lsr  a
        lsr  a
        lsr  a
        lsr  a
        sta  P2H
        lda  P2L
        asl  a
        asl  a
        asl  a
        asl  a
        clc
        adc  P0L
        sta  P0L
        lda  P2H
        adc  P0H
        sta  P0H
        rts

; INIT calls this with the card writable: copy FONT6X10 from ENGSRC to ENGFONT, then write protect the card
ENGCOPY:
        lda  #<ENGSRC
        sta  $06
        lda  #>ENGSRC
        sta  $07
        lda  #<ENGFONT
        sta  $08
        lda  #>ENGFONT
        sta  $09
        ldx  #$08                       ; 8 pages
        ldy  #$00
@copy:
        lda  ($06),y
        sta  ($08),y
        iny
        bne  @copy
        inc  $07
        inc  $09
        dex
        bne  @copy
        lda  #$00
        sta  CASEMODE
        lda  LCRAMRD                    ; $C080: RAM read, write protected
        rts
        .res 11                         ; padding up to $D860
ENGFONT:
        .res 2048
.assert ENGFONT = $D860, error, "ENGFONT must be at $D860: the stock data after it starts at $E060"
'''
tailrows = ["        .byte " + ",".join(f"${b:02X}" for b in tail[k:k + 16]) + f"          ; {tail_addr + k:04X}" for k in range(0, len(tail), 16)]
s = s[:a_end] + code + "\n".join(tailrows) + "\n" + s[cut_end:]

# 3. INIT: copy the font (it also clears CASEMODE, as the two instructions it replaces did)
rep("        lda  #$00                   ; D721  A9 00\n        sta  CASEMODE               ; D723  8D BC 1C\n",
    "        jsr  ENGCOPY                ; copies the English font, clears CASEMODE, write protects the card\n        nop\n        nop\n")

# 4. the English draw path: pointer = base + code * 16
rep("        ldy  #$08                   ; F174  A0 08\n        jsr  L_F2DD                 ; F176  20 DD F2\n",
    "        jsr  ENGPTR                 ; P0 = base + code * 16 (was ldy #8 / jsr L_F2DD)\n        nop\n        nop\n")

# 5. ENBLIT: 10 lines, the first two of the 12-line cell are blank
rep("        cpx  #$04                   ; EBAC  E0 04", "        cpx  #$02                   ; EBAC  E0 04")
rep("        sbc  #$04                   ; EBB6  E9 04", "        sbc  #$02                   ; EBB6  E9 04")

# 6. stub block FE31: the glyph pointer starts at ENGFONT
rep("$8D,$80,$C0,$20,$83,$F8,$8D,$82,$C0,$60,$00,$00,$D0,$00,$00,$00; FE31",
    "$8D,$80,$C0,$20,$83,$F8,$8D,$82,$C0,$60,$00,<ENGFONT,>ENGFONT,$00,$00,$00; FE31")

# 7. loader: the card stays writable until INIT has copied the font
rep("        sta  LCRAMRD                ; $C080: language card RAM read, write protected\n        jmp  INIT\n",
    "        lda  LCRAMRW                ; $C083 twice: language card RAM read and write; INIT write protects it\n        lda  LCRAMRW\n        jmp  INIT\n")

DRV.write_text(s.replace(chr(10), NL), encoding="utf-8", newline="")
d = DEFS.read_text(encoding="utf-8")
if "ENGSRC" not in d:
    d = d.rstrip(chr(10)) + chr(10) + "ENGSRC = $7200            ; where HELLO loads FONT6X10, 2048 bytes" + chr(10)
DEFS.write_text(d, encoding="utf-8")
print("done")
