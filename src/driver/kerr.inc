; Korean Applesoft error messages (plain 16K card build). Included in driver.s in the KERRRES segment: the file carries it
; behind the banner, and KRC copies it to $1CC0 when the start-up banner has run (the banner's place is free after boot).
; The texts and the table KEMT are made by src/tools/genkerr.py (kerr_text.inc).
;
; What the ROM does to print "?UNDEF'D STATEMENT ERROR IN 10" (checked on the Apple II+, II e, IIc ROMs: the same):
;   $D41C "?"                           JSR OUTQUES  (left alone)
;   $D423 the message, one character per JSR OUTDO, X = the offset of that character in the message table at $D260
;   $D431 " ERROR" and the bell         JSR STROUT
;   $D439 " IN " and the line number    JSR $ED19 -> STROUT (only in a program)
; OUTDO's JSR COUT leaves $66 $DB on the stack. KBOUT (the start of COUT) calls KEFILT with the driver's stack as it is
; there: our return, KBOUT's PHA, the return into the output stub $940A, DOS's output hook ($9FAA), then $66 $DB and the
; caller of OUTDO (the message loop, $D425: $25 $D4) or, for STROUT, $4B $DB and STROUT's caller ($D433, $ED1F). Any other
; output has other frames, so it goes on unchanged. No DOS hook in the chain (CSW set to the driver directly) shifts the
; frames: the text then stays English.
; The first character of a message prints the Korean text (looked up by its offset in KEMT); the other characters are
; swallowed. " ERROR" prints " 오류" at its space, " IN " prints " 줄 " at its I; the rest of each is swallowed; the digits
; of the line number are not touched.
KEA = $94F8                         ; the character, X and Y, kept while KEFILT works (the dead glyph buffer, free from $94F8)
KEX = $94F9
KEY = $94FA
KERRBASE:
; KEFILT: A = the character, X and Y as COUT got them. Returns A, X and Y as they were; carry set = the character was
; swallowed (the Korean text, or nothing, was printed in its place).
KEFILT:
        sta  KEA
        stx  KEX
        tsx
        lda  $0108,x                ; $66 $DB: OUTDO's JSR COUT
        cmp  #$66
        bne  @pass
        lda  $0109,x
        cmp  #$DB
        bne  @pass
        lda  $010B,x                ; the caller of OUTDO, high byte
        cmp  #$D4
        bne  @w2
        lda  $010A,x
        cmp  #$25                   ; the message loop at $D425
        bne  @pass
        lda  KEX                    ; the key is the table offset of this character (the carry is set: cmp equal)
        bcs  @look
@w2:    lda  $010D,x                ; STROUT's caller: ED $1F is " IN " (from $ED19), D4 $33 is " ERROR" (from $D431)
        cmp  #$ED
        bne  @d4
        lda  $010C,x
        cmp  #$1F
        bne  @pass
        ldx  #$F1                   ; the key of the text for " IN ", if this is the I
        lda  #$C9
        bne  @t
@d4:    cmp  #$D4
        bne  @pass
        lda  $010C,x
        cmp  #$33
        bne  @pass
        lda  KEA
        cmp  #$87                   ; the bell that follows " ERROR" is the ROM's: it goes on (COUT called from here, with a
        beq  @pass                  ; control character, did not come back)
        ldx  #$F2                   ; the key of the text for " ERROR", if this is the space
        lda  #$A0
@t:     cmp  KEA
        beq  @k
        ldx  #$FF                   ; another character of it: no text, swallow
@k:     txa
@look:  sty  KEY
        ldx  #KEMTEND
@m:     cmp  KEMT,x
        beq  @g
        dex
        dex
        dex
        bpl  @m
        bmi  @sw
@g:     lda  KEMT+1,x
        sta  KPL
        lda  KEMT+2,x
        sta  KPL+1
        jsr  KPUTS
        ldy  KEY
@sw:    sec
        bcs  @x
@pass:  clc
@x:     ldx  KEX
        lda  KEA
        rts
; KPUTS: print the $00 ended text at (KPL): johab pairs and ASCII go to PLOTCH (the plot that PACK ends in; a lead byte waits
; for the byte after it), a byte below $20 (CR, bell) goes to COUT. A, X and Y are not kept.
KPUTS:  ldy  #0
        lda  (KPL),y
        beq  @r
        cmp  #$20
        bcs  @c
        jsr  COUT
        jmp  @i
@c:     sta  CHAR
        jsr  PLOTCH
@i:     inc  KPL
        bne  KPUTS
        inc  KPL+1
        bne  KPUTS
@r:     rts
.include "kerr_text.inc"
KERREND:
